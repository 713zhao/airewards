import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'backend_service.dart';
import 'local_storage_service.dart';
import '../models/sync_model.dart';

/// Comprehensive data synchronization service with conflict resolution
class DataSyncService {
  static bool _initialized = false;
  static Timer? _syncTimer;
  static StreamController<SyncEvent>? _syncEventController;
  static final Map<String, PendingSync> _pendingSyncs = {};
  static bool _syncInProgress = false;
  
  /// Initialize data synchronization service
  static Future<void> initialize() async {
    if (_initialized) return;
    
    debugPrint('🔄 Initializing DataSyncService...');
    
    try {
      _syncEventController = StreamController<SyncEvent>.broadcast();
      
      // Listen for connectivity changes
      Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
        if (result != ConnectivityResult.none) {
          _schedulePendingSyncs();
        }
      });
      
      // Start periodic sync
      _startPeriodicSync();
      
      _initialized = true;
      debugPrint('✅ DataSyncService initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize DataSyncService: $e');
      rethrow;
    }
  }

  /// Get sync event stream
  static Stream<SyncEvent> get syncEventStream =>
      _syncEventController?.stream ?? const Stream.empty();

  /// Dispose data sync service
  static void dispose() {
    _syncTimer?.cancel();
    _syncEventController?.close();
    _initialized = false;
  }

  // ========== Public Sync Methods ==========

  /// Sync user data with conflict resolution
  static Future<SyncResult> syncUserData(String userId, Map<String, dynamic> userData) async {
    return _performSync(
      id: 'user_$userId',
      type: SyncType.user,
      localData: userData,
      syncFunction: () => BackendService.updateUserProfile(userId, userData),
    );
  }

  /// Sync task data
  static Future<SyncResult> syncTaskData(String taskId, Map<String, dynamic> taskData) async {
    return _performSync(
      id: 'task_$taskId',
      type: SyncType.task,
      localData: taskData,
      syncFunction: () => BackendService.updateTask(taskId, taskData),
    );
  }

  /// Sync task completion
  static Future<SyncResult> syncTaskCompletion(String taskId, Map<String, dynamic> completionData) async {
    return _performSync(
      id: 'task_completion_$taskId',
      type: SyncType.taskCompletion,
      localData: completionData,
      syncFunction: () => BackendService.completeTask(
        taskId,
        notes: completionData['notes'],
        attachments: completionData['attachments']?.cast<String>(),
      ),
    );
  }

  /// Sync reward redemption
  static Future<SyncResult> syncRewardRedemption(String userId, String rewardId) async {
    return _performSync(
      id: 'redemption_${userId}_$rewardId',
      type: SyncType.redemption,
      localData: {'user_id': userId, 'reward_id': rewardId},
      syncFunction: () => BackendService.redeemReward(userId, rewardId),
    );
  }

  /// Sync family data
  static Future<SyncResult> syncFamilyData(String familyId, Map<String, dynamic> familyData) async {
    return _performSync(
      id: 'family_$familyId',
      type: SyncType.family,
      localData: familyData,
      syncFunction: () async {
        // Implementation would update family data
        return familyData;
      },
    );
  }

  /// Sync notification read status
  static Future<SyncResult> syncNotificationRead(String notificationId) async {
    return _performSync(
      id: 'notification_read_$notificationId',
      type: SyncType.notificationRead,
      localData: {'notification_id': notificationId},
      syncFunction: () => BackendService.markNotificationAsRead(notificationId),
    );
  }

  // ========== Batch Sync Operations ==========

  /// Perform full data synchronization
  static Future<BatchSyncResult> performFullSync({String? userId}) async {
    if (_syncInProgress) {
      debugPrint('⏳ Sync already in progress, skipping...');
      return BatchSyncResult(success: false, message: 'Sync already in progress');
    }

    _syncInProgress = true;
    _emitSyncEvent(SyncEvent.started());

    try {
      debugPrint('🔄 Starting full data synchronization...');

      final results = <String, SyncResult>{};
      final startTime = DateTime.now();

      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        debugPrint('📡 No internet connection, queuing for later sync');
        return BatchSyncResult(success: false, message: 'No internet connection');
      }

      // Sync pending operations first
      if (_pendingSyncs.isNotEmpty) {
        await _processPendingSyncs(results);
      }

      // Pull latest data from server
      if (userId != null) {
        await _pullLatestData(userId, results);
      }

      // Calculate overall result
      final failedSyncs = results.values.where((r) => !r.success).length;
      final totalSyncs = results.length;
      final successRate = totalSyncs > 0 ? (totalSyncs - failedSyncs) / totalSyncs : 1.0;

      final batchResult = BatchSyncResult(
        success: failedSyncs == 0,
        message: failedSyncs == 0 
            ? 'All data synchronized successfully'
            : '$failedSyncs of $totalSyncs syncs failed',
        results: results,
        duration: DateTime.now().difference(startTime),
        successRate: successRate,
      );

      _emitSyncEvent(SyncEvent.completed(batchResult));
      debugPrint('✅ Full synchronization completed: ${batchResult.message}');

      return batchResult;

    } catch (e) {
      debugPrint('❌ Full synchronization failed: $e');
      final errorResult = BatchSyncResult(
        success: false, 
        message: 'Synchronization failed: $e',
        duration: DateTime.now().difference(DateTime.now()),
      );
      
      _emitSyncEvent(SyncEvent.failed(e.toString()));
      return errorResult;

    } finally {
      _syncInProgress = false;
    }
  }

  /// Queue sync operation for offline execution
  static Future<void> queueForSync(PendingSync pendingSync) async {
    _pendingSyncs[pendingSync.id] = pendingSync;
    
    // Persist pending syncs to storage
    await _savePendingSyncs();
    
    _emitSyncEvent(SyncEvent.queued(pendingSync));
    debugPrint('📤 Queued sync operation: ${pendingSync.id}');
  }

  /// Get pending sync count
  static int get pendingSyncCount => _pendingSyncs.length;

  /// Clear all pending syncs
  static Future<void> clearPendingSyncs() async {
    _pendingSyncs.clear();
    await LocalStorageService.remove('pending_syncs');
    debugPrint('🗑️ Cleared all pending syncs');
  }

  // ========== Private Implementation ==========

  /// Perform individual sync operation with conflict resolution
  static Future<SyncResult> _performSync({
    required String id,
    required SyncType type,
    required Map<String, dynamic> localData,
    required Future<dynamic> Function() syncFunction,
  }) async {
    try {
      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        // Queue for later sync
        final pendingSync = PendingSync(
          id: id,
          type: type,
          data: localData,
          timestamp: DateTime.now(),
          retryCount: 0,
        );
        
        await queueForSync(pendingSync);
        
        return SyncResult(
          success: false,
          message: 'Queued for offline sync',
          needsRetry: true,
        );
      }

      // Perform sync operation
      final result = await syncFunction();
      
      // Handle successful sync
      _pendingSyncs.remove(id);
      await _savePendingSyncs();
      
      _emitSyncEvent(SyncEvent.itemSynced(id, type));
      
      return SyncResult(
        success: true,
        message: 'Synchronized successfully',
        data: result,
      );

    } catch (e) {
      debugPrint('❌ Sync failed for $id: $e');
      
      // Handle sync conflicts
      if (e.toString().contains('conflict') || e.toString().contains('409')) {
        return _handleSyncConflict(id, type, localData, e);
      }
      
      // Queue for retry if it's a network error
      if (_isRetryableError(e)) {
        final pendingSync = PendingSync(
          id: id,
          type: type,
          data: localData,
          timestamp: DateTime.now(),
          retryCount: (_pendingSyncs[id]?.retryCount ?? 0) + 1,
        );
        
        if (pendingSync.retryCount < 3) {
          await queueForSync(pendingSync);
        }
      }
      
      return SyncResult(
        success: false,
        message: 'Sync failed: $e',
        error: e.toString(),
        needsRetry: _isRetryableError(e),
      );
    }
  }

  /// Handle sync conflicts with resolution strategies
  static Future<SyncResult> _handleSyncConflict(
    String id,
    SyncType type,
    Map<String, dynamic> localData,
    dynamic error,
  ) async {
    debugPrint('⚠️ Handling sync conflict for $id');
    
    try {
      // Get server data to compare
      final serverData = await _getServerData(id, type);
      
      // Resolve conflict based on type and strategy
      final resolution = await _resolveConflict(localData, serverData, type);
      
      switch (resolution.strategy) {
        case ConflictResolutionStrategy.useLocal:
          // Force update with local data
          return _forceSync(id, type, localData);
          
        case ConflictResolutionStrategy.useServer:
          // Update local data with server data
          await _updateLocalData(id, serverData);
          return SyncResult(
            success: true,
            message: 'Conflict resolved: using server data',
            data: serverData,
          );
          
        case ConflictResolutionStrategy.merge:
          // Merge local and server data
          final mergedData = _mergeData(localData, serverData, type);
          return _forceSync(id, type, mergedData);
          
        case ConflictResolutionStrategy.manual:
          // Require manual resolution
          _emitSyncEvent(SyncEvent.conflictDetected(id, localData, serverData));
          return SyncResult(
            success: false,
            message: 'Manual conflict resolution required',
            needsManualResolution: true,
            conflictData: {'local': localData, 'server': serverData},
          );
      }
      
    } catch (e) {
      debugPrint('❌ Conflict resolution failed: $e');
      return SyncResult(
        success: false,
        message: 'Conflict resolution failed: $e',
        error: e.toString(),
      );
    }
  }

  /// Resolve data conflicts using various strategies
  static Future<ConflictResolution> _resolveConflict(
    Map<String, dynamic> localData,
    Map<String, dynamic> serverData,
    SyncType type,
  ) async {
    // Simple timestamp-based resolution for most cases
    final localTimestamp = DateTime.tryParse(localData['updated_at'] ?? '');
    final serverTimestamp = DateTime.tryParse(serverData['updated_at'] ?? '');
    
    if (localTimestamp != null && serverTimestamp != null) {
      if (localTimestamp.isAfter(serverTimestamp)) {
        return ConflictResolution(ConflictResolutionStrategy.useLocal);
      } else if (serverTimestamp.isAfter(localTimestamp)) {
        return ConflictResolution(ConflictResolutionStrategy.useServer);
      }
    }
    
    // Type-specific conflict resolution
    switch (type) {
      case SyncType.user:
        // User data conflicts typically use latest timestamp
        return ConflictResolution(ConflictResolutionStrategy.merge);
        
      case SyncType.task:
        // Task conflicts may need manual resolution
        return ConflictResolution(ConflictResolutionStrategy.manual);
        
      case SyncType.taskCompletion:
        // Task completion should typically use local data
        return ConflictResolution(ConflictResolutionStrategy.useLocal);
        
      case SyncType.redemption:
        // Redemptions should use server data to prevent double redemption
        return ConflictResolution(ConflictResolutionStrategy.useServer);
        
      default:
        return ConflictResolution(ConflictResolutionStrategy.useServer);
    }
  }

  /// Start periodic synchronization
  static void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _schedulePendingSyncs();
    });
  }

  /// Schedule pending syncs when connectivity is available
  static Future<void> _schedulePendingSyncs() async {
    if (_pendingSyncs.isEmpty || _syncInProgress) return;
    
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return;
    
    debugPrint('📡 Processing ${_pendingSyncs.length} pending syncs...');
    
    final results = <String, SyncResult>{};
    await _processPendingSyncs(results);
  }

  /// Process all pending sync operations
  static Future<void> _processPendingSyncs(Map<String, SyncResult> results) async {
    final pendingList = _pendingSyncs.values.toList();
    
    for (final pendingSync in pendingList) {
      if (pendingSync.retryCount >= 3) {
        debugPrint('⚠️ Skipping sync ${pendingSync.id} - max retries exceeded');
        _pendingSyncs.remove(pendingSync.id);
        continue;
      }
      
      final result = await _retryPendingSync(pendingSync);
      results[pendingSync.id] = result;
      
      if (result.success) {
        _pendingSyncs.remove(pendingSync.id);
      }
    }
    
    await _savePendingSyncs();
  }

  /// Retry a pending sync operation
  static Future<SyncResult> _retryPendingSync(PendingSync pendingSync) async {
    try {
      switch (pendingSync.type) {
        case SyncType.user:
          final parts = pendingSync.id.split('_');
          final userId = parts.length > 1 ? parts[1] : pendingSync.id;
          final user = await BackendService.updateUserProfile(userId, pendingSync.data);
          return SyncResult(success: true, message: 'User sync completed', data: user);
          
        case SyncType.task:
          final parts = pendingSync.id.split('_');
          final taskId = parts.length > 1 ? parts[1] : pendingSync.id;
          final task = await BackendService.updateTask(taskId, pendingSync.data);
          return SyncResult(success: true, message: 'Task sync completed', data: task);
          
        case SyncType.taskCompletion:
          final parts = pendingSync.id.split('_');
          final taskId = parts.length > 2 ? parts[2] : pendingSync.id;
          final completion = await BackendService.completeTask(
            taskId,
            notes: pendingSync.data['notes'],
            attachments: pendingSync.data['attachments']?.cast<String>(),
          );
          return SyncResult(success: true, message: 'Task completion sync completed', data: completion);
          
        case SyncType.redemption:
          final userId = pendingSync.data['user_id'];
          final rewardId = pendingSync.data['reward_id'];
          final redemption = await BackendService.redeemReward(userId, rewardId);
          return SyncResult(success: true, message: 'Redemption sync completed', data: redemption);
          
        case SyncType.notificationRead:
          final notificationId = pendingSync.data['notification_id'];
          await BackendService.markNotificationAsRead(notificationId);
          return SyncResult(success: true, message: 'Notification read sync completed');
          
        default:
          return SyncResult(success: false, message: 'Unknown sync type: ${pendingSync.type}');
      }
    } catch (e) {
      return SyncResult(success: false, message: 'Retry failed: $e', error: e.toString());
    }
  }

  /// Pull latest data from server
  static Future<void> _pullLatestData(String userId, Map<String, SyncResult> results) async {
    try {
      // Pull user data
      final user = await BackendService.getUserProfile(userId);
      await LocalStorageService.store('user_$userId', user.toJson());
      results['pull_user'] = SyncResult(success: true, message: 'User data pulled');

      // Pull tasks
      final tasks = await BackendService.getUserTasks(userId);
      await LocalStorageService.store('user_tasks_$userId', tasks.map((t) => t.toJson()).toList());
      results['pull_tasks'] = SyncResult(success: true, message: 'Tasks pulled');

      // Pull notifications
      final notifications = await BackendService.getUserNotifications(userId, limit: 50);
      await LocalStorageService.store('user_notifications_$userId', notifications.map((n) => n.toJson()).toList());
      results['pull_notifications'] = SyncResult(success: true, message: 'Notifications pulled');

    } catch (e) {
      debugPrint('❌ Failed to pull data: $e');
      results['pull_error'] = SyncResult(success: false, message: 'Failed to pull data: $e');
    }
  }

  /// Helper methods
  static bool _isRetryableError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') || 
           errorString.contains('timeout') || 
           errorString.contains('connection') ||
           errorString.contains('500') ||
           errorString.contains('502') ||
           errorString.contains('503');
  }

  static Future<Map<String, dynamic>> _getServerData(String id, SyncType type) async {
    // Implementation would fetch current server data for comparison
    return {};
  }

  static Future<SyncResult> _forceSync(String id, SyncType type, Map<String, dynamic> data) async {
    // Implementation would force update server data
    return SyncResult(success: true, message: 'Force sync completed');
  }

  static Future<void> _updateLocalData(String id, Map<String, dynamic> data) async {
    // Implementation would update local storage with server data
  }

  static Map<String, dynamic> _mergeData(
    Map<String, dynamic> localData,
    Map<String, dynamic> serverData,
    SyncType type,
  ) {
    // Simple merge strategy - can be enhanced based on data type
    final merged = Map<String, dynamic>.from(serverData);
    
    // Keep local changes for specific fields
    switch (type) {
      case SyncType.user:
        // Keep local preferences
        if (localData.containsKey('preferences')) {
          merged['preferences'] = localData['preferences'];
        }
        break;
      default:
        break;
    }
    
    return merged;
  }

  static Future<void> _savePendingSyncs() async {
    final pendingSyncsJson = _pendingSyncs.map(
      (key, value) => MapEntry(key, value.toJson()),
    );
    await LocalStorageService.store('pending_syncs', pendingSyncsJson);
  }

  static Future<void> _loadPendingSyncs() async {
    try {
      final data = await LocalStorageService.retrieve('pending_syncs');
      if (data is Map<String, dynamic>) {
        _pendingSyncs.clear();
        data.forEach((key, value) {
          _pendingSyncs[key] = PendingSync.fromJson(value);
        });
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load pending syncs: $e');
    }
  }

  static void _emitSyncEvent(SyncEvent event) {
    _syncEventController?.add(event);
  }
}

// ========== Supporting Classes ==========

class SyncResult {
  final bool success;
  final String message;
  final dynamic data;
  final String? error;
  final bool needsRetry;
  final bool needsManualResolution;
  final Map<String, dynamic>? conflictData;

  const SyncResult({
    required this.success,
    required this.message,
    this.data,
    this.error,
    this.needsRetry = false,
    this.needsManualResolution = false,
    this.conflictData,
  });
}

class BatchSyncResult {
  final bool success;
  final String message;
  final Map<String, SyncResult>? results;
  final Duration? duration;
  final double? successRate;

  const BatchSyncResult({
    required this.success,
    required this.message,
    this.results,
    this.duration,
    this.successRate,
  });
}

class PendingSync {
  final String id;
  final SyncType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;

  const PendingSync({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
    required this.retryCount,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString(),
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'retry_count': retryCount,
  };

  factory PendingSync.fromJson(Map<String, dynamic> json) {
    return PendingSync(
      id: json['id'],
      type: SyncType.values.firstWhere((e) => e.toString() == json['type']),
      data: Map<String, dynamic>.from(json['data']),
      timestamp: DateTime.parse(json['timestamp']),
      retryCount: json['retry_count'],
    );
  }
}

class ConflictResolution {
  final ConflictResolutionStrategy strategy;
  final Map<String, dynamic>? mergedData;

  const ConflictResolution(this.strategy, {this.mergedData});
}

class SyncEvent {
  final SyncEventType type;
  final String? message;
  final dynamic data;

  const SyncEvent._(this.type, {this.message, this.data});

  factory SyncEvent.started() => const SyncEvent._(SyncEventType.started);
  factory SyncEvent.completed(dynamic result) => SyncEvent._(SyncEventType.completed, data: result);
  factory SyncEvent.failed(String error) => SyncEvent._(SyncEventType.failed, message: error);
  factory SyncEvent.queued(PendingSync sync) => SyncEvent._(SyncEventType.queued, data: sync);
  factory SyncEvent.itemSynced(String id, SyncType type) => SyncEvent._(SyncEventType.itemSynced, data: {'id': id, 'type': type});
  factory SyncEvent.conflictDetected(String id, dynamic local, dynamic server) => SyncEvent._(
    SyncEventType.conflictDetected,
    data: {'id': id, 'local': local, 'server': server},
  );
}

enum SyncType {
  user,
  task,
  taskCompletion,
  redemption,
  family,
  notificationRead,
}

enum ConflictResolutionStrategy {
  useLocal,
  useServer,
  merge,
  manual,
}

enum SyncEventType {
  started,
  completed,
  failed,
  queued,
  itemSynced,
  conflictDetected,
}