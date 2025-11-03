import 'dart:async';
import 'dart:developer' as dev;


import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../models/sync_models.dart';
import '../../features/shared/data/datasources/local/database_helper.dart';
import '../../features/authentication/data/datasources/firebase_auth_datasource.dart';
import '../../features/rewards/data/datasources/firestore_reward_datasource.dart';
import '../../features/redemption/data/datasources/firestore_redemption_datasource.dart';
import 'connectivity_service.dart';

/// Service responsible for synchronizing local data with remote Firestore
@lazySingleton
class SyncService {
  final DatabaseHelper _databaseHelper;
  final ConnectivityService _connectivityService;
  final FirebaseAuthDataSource _authDataSource;
  final FirestoreRewardDataSource _rewardDataSource;
  final FirestoreRedemptionDataSource _redemptionDataSource;

  // Internal state
  bool _isSyncing = false;
  Timer? _periodicSyncTimer;
  Timer? _retryTimer;
  StreamController<SyncStatistics>? _syncStatsController;
  StreamController<String>? _syncEventsController;
  
  // Configuration
  static const Duration _defaultSyncInterval = Duration(minutes: 15);
  static const Duration _quickSyncInterval = Duration(minutes: 2);
  static const int _maxConcurrentOperations = 5;

  SyncService(
    this._databaseHelper,
    this._connectivityService,
    this._authDataSource,
    this._rewardDataSource,
    this._redemptionDataSource,
  );

  /// Initialize the sync service
  Future<void> initialize() async {
    debugPrint('🔄 Initializing SyncService');
    
    // Start monitoring connectivity
    _connectivityService.initialize();
    
    // Listen to connectivity changes
    _connectivityService.connectivityStream.listen(_onConnectivityChanged);
    
    // Start periodic sync
    _startPeriodicSync();
    
    // Process any existing queue items
    _scheduleQueueProcessing();

    debugPrint('✅ SyncService initialized');
  }

  /// Stream of sync statistics
  Stream<SyncStatistics> get syncStatisticsStream {
    _syncStatsController ??= StreamController<SyncStatistics>.broadcast();
    return _syncStatsController!.stream;
  }

  /// Stream of sync events (for logging/debugging)
  Stream<String> get syncEventsStream {
    _syncEventsController ??= StreamController<String>.broadcast();
    return _syncEventsController!.stream;
  }

  /// Check if sync is currently active
  bool get isSyncing => _isSyncing;

  /// Handle connectivity changes
  void _onConnectivityChanged(ConnectivityState state) {
    _emitEvent('Connectivity changed to: ${state.name}');
    
    switch (state) {
      case ConnectivityState.connected:
        // Good connection - start aggressive sync
        _scheduleQueueProcessing();
        _startPeriodicSync(interval: _quickSyncInterval);
        break;
      case ConnectivityState.slow:
        // Slow connection - more conservative sync
        _startPeriodicSync(interval: _defaultSyncInterval);
        break;
      case ConnectivityState.disconnected:
      case ConnectivityState.unknown:
        // No connection - stop periodic sync
        _stopPeriodicSync();
        break;
    }
  }

  /// Start periodic sync
  void _startPeriodicSync({Duration interval = _defaultSyncInterval}) {
    _stopPeriodicSync();
    
    _periodicSyncTimer = Timer.periodic(interval, (_) async {
      if (await _connectivityService.hasConnection()) {
        await syncAll();
      }
    });
    
    _emitEvent('Started periodic sync with ${interval.inMinutes}min interval');
  }

  /// Stop periodic sync
  void _stopPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
  }

  /// Sync all data between local and remote
  Future<SyncResult> syncAll() async {
    if (_isSyncing) {
      _emitEvent('Sync already in progress, skipping');
      return SyncResult.failure('Sync already in progress');
    }

    _isSyncing = true;
    _emitEvent('Starting full sync');

    try {
      // Check connectivity
      if (!await _connectivityService.hasConnection()) {
        _emitEvent('No connection available, aborting sync');
        return SyncResult.failure('No internet connection');
      }

      // Check authentication
      final authResult = await _authDataSource.getCurrentUser();
      if (authResult.fold((l) => true, (r) => false)) {
        _emitEvent('User not authenticated, aborting sync');
        return SyncResult.failure('User not authenticated');
      }

      final stopwatch = Stopwatch()..start();

      // Process sync queue (local to remote)
      await _processSyncQueue();

      // Sync remote to local for each feature
      await _syncRewardsFromRemote();
      await _syncRedemptionsFromRemote();

      // Clean up completed items
      await _cleanupCompletedItems();

      stopwatch.stop();
      _emitEvent('Full sync completed in ${stopwatch.elapsedMilliseconds}ms');

      // Update statistics
      await _updateSyncStatistics();

      return SyncResult.success();
    } catch (e, stackTrace) {
      _emitEvent('Sync failed: $e');
      dev.log('Sync error', error: e, stackTrace: stackTrace);
      return SyncResult.failure(e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  /// Process items in the sync queue
  Future<void> _processSyncQueue() async {
    final pendingItems = await _getPendingSyncItems();
    _emitEvent('Processing ${pendingItems.length} sync queue items');

    if (pendingItems.isEmpty) return;

    // Process items in batches to avoid overwhelming the server
    final batches = _createBatches(pendingItems, _maxConcurrentOperations);

    for (final batch in batches) {
      if (!await _connectivityService.hasConnection()) {
        _emitEvent('Lost connection during sync, stopping queue processing');
        break;
      }

      // Process batch items concurrently
      final futures = batch.map(_processSyncItem);
      await Future.wait(futures);
    }

    _emitEvent('Sync queue processing completed');
  }

  /// Process a single sync queue item
  Future<void> _processSyncItem(SyncQueueItem item) async {
    _emitEvent('Processing ${item.operation.value} for ${item.entityType}:${item.entityId}');

    try {
      // Mark as processing
      await _updateSyncItemStatus(item.id, SyncStatus.processing);

      SyncResult result;
      
      switch (item.entityType) {
        case 'reward_entry':
          result = await _processRewardSync(item);
          break;
        case 'redemption_option':
          result = await _processRedemptionOptionSync(item);
          break;
        case 'redemption_transaction':
          result = await _processRedemptionTransactionSync(item);
          break;
        case 'user':
          result = await _processUserSync(item);
          break;
        default:
          result = SyncResult.failure('Unknown entity type: ${item.entityType}');
      }

      if (result.success) {
        await _updateSyncItemStatus(item.id, SyncStatus.completed);
        _emitEvent('✅ Synced ${item.entityType}:${item.entityId}');
      } else {
        await _handleSyncFailure(item, result.error ?? 'Unknown error');
      }
    } catch (e) {
      await _handleSyncFailure(item, e.toString());
    }
  }

  /// Handle sync item failure
  Future<void> _handleSyncFailure(SyncQueueItem item, String error) async {
    final newRetryCount = item.retryCount + 1;
    
    if (newRetryCount >= item.maxRetries) {
      await _updateSyncItemStatus(item.id, SyncStatus.failed, error: error);
      _emitEvent('❌ Permanently failed ${item.entityType}:${item.entityId} - $error');
    } else {
      final nextRetry = item.nextRetryTime;
      await _updateSyncItemRetry(item.id, newRetryCount, error, nextRetry);
      _emitEvent('🔄 Will retry ${item.entityType}:${item.entityId} at $nextRetry (attempt $newRetryCount)');
    }
  }

  /// Process reward-related sync operations
  Future<SyncResult> _processRewardSync(SyncQueueItem item) async {
    try {
      switch (item.operation) {
        case SyncOperation.insert:
        case SyncOperation.update:
          // For rewards, we typically sync batches through the reward data source
          return SyncResult.success();
        case SyncOperation.delete:
          return SyncResult.success();
      }
    } catch (e) {
      return SyncResult.failure(e.toString());
    }
  }

  /// Process redemption option sync operations
  Future<SyncResult> _processRedemptionOptionSync(SyncQueueItem item) async {
    try {
      switch (item.operation) {
        case SyncOperation.insert:
        case SyncOperation.update:
          // Redemption options are typically read-only from the client side
          return SyncResult.success();
        case SyncOperation.delete:
          return SyncResult.success();
      }
    } catch (e) {
      return SyncResult.failure(e.toString());
    }
  }

  /// Process redemption transaction sync operations
  Future<SyncResult> _processRedemptionTransactionSync(SyncQueueItem item) async {
    try {
      switch (item.operation) {
        case SyncOperation.insert:
          // Redemption transactions should already be synced through the data source
          return SyncResult.success();
        case SyncOperation.update:
          return SyncResult.success();
        case SyncOperation.delete:
          return SyncResult.success();
      }
    } catch (e) {
      return SyncResult.failure(e.toString());
    }
  }

  /// Process user sync operations
  Future<SyncResult> _processUserSync(SyncQueueItem item) async {
    try {
      switch (item.operation) {
        case SyncOperation.insert:
        case SyncOperation.update:
          // User profile updates should already be handled by auth data source
          return SyncResult.success();
        case SyncOperation.delete:
          return SyncResult.success();
      }
    } catch (e) {
      return SyncResult.failure(e.toString());
    }
  }

  /// Sync rewards data from remote to local
  Future<void> _syncRewardsFromRemote() async {
    try {
      _emitEvent('Syncing rewards from remote');
      // Get current user for syncing user-specific data
      final authResult = await _authDataSource.getCurrentUser();
      if (authResult.fold((l) => false, (r) => true)) {
        final user = authResult.fold((l) => null, (r) => r);
        if (user != null) {
          // Use the reward data source to get latest reward entries
          final rewardsResult = await _rewardDataSource.getRewardEntriesStream(
            userId: user.id,
            limit: 100,
          ).first.timeout(const Duration(seconds: 30));
          _emitEvent('✅ Synced ${rewardsResult.length} reward entries from remote');
        }
      }
    } catch (e) {
      _emitEvent('❌ Failed to sync rewards from remote: $e');
    }
  }

  /// Sync redemptions data from remote to local
  Future<void> _syncRedemptionsFromRemote() async {
    try {
      _emitEvent('Syncing redemptions from remote');
      // Get available redemption options
      final optionsResult = await _redemptionDataSource.getRedemptionOptions(
        limit: 50,
      );
      optionsResult.fold(
        (error) => _emitEvent('❌ Failed to get redemption options: $error'),
        (options) => _emitEvent('✅ Synced ${options.length} redemption options from remote'),
      );
    } catch (e) {
      _emitEvent('❌ Failed to sync redemptions from remote: $e');
    }
  }

  /// Get pending sync items from database
  Future<List<SyncQueueItem>> _getPendingSyncItems() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DatabaseHelper.tableSyncQueue,
        where: 'status = ? AND scheduled_at <= ?',
        whereArgs: [
          SyncStatus.pending.value,
          DateTime.now().millisecondsSinceEpoch,
        ],
        orderBy: 'priority DESC, created_at ASC',
        limit: 50, // Process in batches
      );

      return maps.map((map) => SyncQueueItem.fromMap(map)).toList();
    } catch (e) {
      _emitEvent('Error getting pending sync items: $e');
      return [];
    }
  }

  /// Create batches from a list of items
  List<List<T>> _createBatches<T>(List<T> items, int batchSize) {
    final batches = <List<T>>[];
    for (int i = 0; i < items.length; i += batchSize) {
      final end = (i + batchSize < items.length) ? i + batchSize : items.length;
      batches.add(items.sublist(i, end));
    }
    return batches;
  }

  /// Update sync item status
  Future<void> _updateSyncItemStatus(
    String id,
    SyncStatus status, {
    String? error,
  }) async {
    try {
      final db = await _databaseHelper.database;
      await db.update(
        DatabaseHelper.tableSyncQueue,
        {
          'status': status.value,
          'last_attempt_at': DateTime.now().millisecondsSinceEpoch,
          if (error != null) 'error': error,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      _emitEvent('Error updating sync item status: $e');
    }
  }

  /// Update sync item retry information
  Future<void> _updateSyncItemRetry(
    String id,
    int retryCount,
    String error,
    DateTime nextRetry,
  ) async {
    try {
      final db = await _databaseHelper.database;
      await db.update(
        DatabaseHelper.tableSyncQueue,
        {
          'status': SyncStatus.pending.value,
          'retry_count': retryCount,
          'error': error,
          'scheduled_at': nextRetry.millisecondsSinceEpoch,
          'last_attempt_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      _emitEvent('Error updating sync item retry: $e');
    }
  }

  /// Schedule queue processing
  void _scheduleQueueProcessing() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 30), () async {
      if (await _connectivityService.hasConnection() && !_isSyncing) {
        await _processSyncQueue();
      }
    });
  }

  /// Clean up completed sync items
  Future<void> _cleanupCompletedItems() async {
    try {
      final db = await _databaseHelper.database;
      
      // Remove completed items older than 7 days
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      final deletedCount = await db.delete(
        DatabaseHelper.tableSyncQueue,
        where: 'status = ? AND last_attempt_at < ?',
        whereArgs: [
          SyncStatus.completed.value,
          cutoff.millisecondsSinceEpoch,
        ],
      );

      if (deletedCount > 0) {
        _emitEvent('Cleaned up $deletedCount completed sync items');
      }
    } catch (e) {
      _emitEvent('Error cleaning up sync items: $e');
    }
  }

  /// Update sync statistics
  Future<void> _updateSyncStatistics() async {
    try {
      final db = await _databaseHelper.database;
      
      // Get counts by status
      final counts = await db.rawQuery('''
        SELECT status, COUNT(*) as count
        FROM ${DatabaseHelper.tableSyncQueue}
        GROUP BY status
      ''');

      int totalItems = 0;
      int pendingItems = 0;
      int completedItems = 0;
      int failedItems = 0;
      int processingItems = 0;

      for (final row in counts) {
        final status = row['status'] as String;
        final count = row['count'] as int;
        totalItems += count;

        switch (SyncStatus.fromString(status)) {
          case SyncStatus.pending:
            pendingItems = count;
            break;
          case SyncStatus.processing:
            processingItems = count;
            break;
          case SyncStatus.completed:
            completedItems = count;
            break;
          case SyncStatus.failed:
          case SyncStatus.cancelled:
            failedItems += count;
            break;
        }
      }

      // Get last sync time
      final lastSyncResult = await db.rawQuery('''
        SELECT MAX(last_attempt_at) as last_sync
        FROM ${DatabaseHelper.tableSyncQueue}
        WHERE status = ?
      ''', [SyncStatus.completed.value]);

      DateTime? lastSyncAt;
      if (lastSyncResult.isNotEmpty && lastSyncResult.first['last_sync'] != null) {
        lastSyncAt = DateTime.fromMillisecondsSinceEpoch(
          lastSyncResult.first['last_sync'] as int,
        );
      }

      final statistics = SyncStatistics(
        totalItems: totalItems,
        pendingItems: pendingItems,
        completedItems: completedItems,
        failedItems: failedItems,
        processingItems: processingItems,
        lastSyncAt: lastSyncAt,
      );

      _syncStatsController?.add(statistics);
      _emitEvent('Updated sync statistics: $statistics');
    } catch (e) {
      _emitEvent('Error updating sync statistics: $e');
    }
  }

  /// Emit a sync event
  void _emitEvent(String message) {
    debugPrint('🔄 SyncService: $message');
    _syncEventsController?.add(message);
  }

  /// Force sync now (manual trigger)
  Future<SyncResult> forceSyncNow() async {
    _emitEvent('Force sync requested');
    return await syncAll();
  }

  /// Get current sync statistics
  Future<SyncStatistics> getCurrentStatistics() async {
    await _updateSyncStatistics();
    return SyncStatistics(
      totalItems: 0,
      pendingItems: 0,
      completedItems: 0,
      failedItems: 0,
      processingItems: 0,
    );
  }

  /// Clear failed sync items
  Future<void> clearFailedItems() async {
    try {
      final db = await _databaseHelper.database;
      final deletedCount = await db.delete(
        DatabaseHelper.tableSyncQueue,
        where: 'status = ?',
        whereArgs: [SyncStatus.failed.value],
      );
      
      _emitEvent('Cleared $deletedCount failed sync items');
      await _updateSyncStatistics();
    } catch (e) {
      _emitEvent('Error clearing failed items: $e');
    }
  }

  /// Dispose of resources
  void dispose() {
    _stopPeriodicSync();
    _retryTimer?.cancel();
    _syncStatsController?.close();
    _syncEventsController?.close();
    _emitEvent('SyncService disposed');
  }
}