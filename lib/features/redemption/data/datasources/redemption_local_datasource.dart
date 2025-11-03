import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../shared/data/datasources/local/database_helper.dart';
import '../../domain/entities/entities.dart';
import '../models/models.dart';

/// Local data source for redemption data operations.
/// 
/// This class handles all local storage operations for redemption-related data
/// using SQLite database. It provides caching, offline support, and sync queue
/// management for redemption options and transactions.
/// 
/// Key features:
/// - Redemption option caching with comprehensive filtering
/// - Transaction history management and caching
/// - Point balance validation and tracking
/// - Sync queue management for offline operations
/// - Efficient pagination and search capabilities
/// - Data model conversion and validation
abstract class RedemptionLocalDataSource {
  /// Cache a redemption option locally
  /// 
  /// Parameters:
  /// - [redemptionOption]: The redemption option to cache
  /// 
  /// Returns [Either<LocalException, String>]:
  /// - Left: [LocalException] if caching fails
  /// - Right: The ID of the cached option
  Future<Either<LocalException, String>> cacheRedemptionOption(RedemptionOptionModel redemptionOption);
  
  /// Get cached redemption options with filtering and pagination
  /// 
  /// Parameters:
  /// - [page]: Page number (1-based)
  /// - [limit]: Number of items per page
  /// - [categoryId]: Optional category filter
  /// - [isActive]: Optional active status filter
  /// - [searchQuery]: Optional search query for title/description
  /// - [sortBy]: Sort field (points, title, created_date)
  /// - [sortOrder]: Sort order (asc, desc)
  /// 
  /// Returns [Either<LocalException, PaginatedResult<RedemptionOptionModel>>]:
  /// - Left: [LocalException] if retrieval fails
  /// - Right: Paginated redemption options
  Future<Either<LocalException, PaginatedResult<RedemptionOptionModel>>> getCachedRedemptionOptions({
    int page = 1,
    int limit = 20,
    String? categoryId,
    bool? isActive,
    String? searchQuery,
    String sortBy = 'points',
    String sortOrder = 'asc',
  });
  
  /// Get a specific cached redemption option by ID
  /// 
  /// Parameters:
  /// - [optionId]: The redemption option ID
  /// 
  /// Returns [Either<LocalException, RedemptionOptionModel>]:
  /// - Left: [LocalException] if option not found or retrieval fails
  /// - Right: The redemption option
  Future<Either<LocalException, RedemptionOptionModel>> getCachedRedemptionOption(String optionId);
  
  /// Update a cached redemption option
  /// 
  /// Parameters:
  /// - [redemptionOption]: The updated redemption option
  /// 
  /// Returns [Either<LocalException, bool>]:
  /// - Left: [LocalException] if update fails
  /// - Right: true if update succeeds
  Future<Either<LocalException, bool>> updateCachedRedemptionOption(RedemptionOptionModel redemptionOption);
  
  /// Delete a cached redemption option
  /// 
  /// Parameters:
  /// - [optionId]: The redemption option ID to delete
  /// 
  /// Returns [Either<LocalException, bool>]:
  /// - Left: [LocalException] if deletion fails
  /// - Right: true if deletion succeeds
  Future<Either<LocalException, bool>> deleteCachedRedemptionOption(String optionId);
  
  /// Cache a redemption transaction locally
  /// 
  /// Parameters:
  /// - [transaction]: The redemption transaction to cache
  /// 
  /// Returns [Either<LocalException, String>]:
  /// - Left: [LocalException] if caching fails
  /// - Right: The ID of the cached transaction
  Future<Either<LocalException, String>> cacheRedemptionTransaction(RedemptionTransactionModel transaction);
  
  /// Get cached redemption transactions with filtering and pagination
  /// 
  /// Parameters:
  /// - [userId]: The user ID to filter by
  /// - [page]: Page number (1-based)
  /// - [limit]: Number of items per page
  /// - [status]: Optional status filter
  /// - [startDate]: Optional start date filter
  /// - [endDate]: Optional end date filter
  /// 
  /// Returns [Either<LocalException, PaginatedResult<RedemptionTransactionModel>>]:
  /// - Left: [LocalException] if retrieval fails
  /// - Right: Paginated redemption transactions
  Future<Either<LocalException, PaginatedResult<RedemptionTransactionModel>>> getCachedRedemptionTransactions({
    required String userId,
    int page = 1,
    int limit = 20,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  /// Get a specific cached redemption transaction by ID
  /// 
  /// Parameters:
  /// - [transactionId]: The redemption transaction ID
  /// 
  /// Returns [Either<LocalException, RedemptionTransactionModel>]:
  /// - Left: [LocalException] if transaction not found or retrieval fails
  /// - Right: The redemption transaction
  Future<Either<LocalException, RedemptionTransactionModel>> getCachedRedemptionTransaction(String transactionId);
  
  /// Update a cached redemption transaction
  /// 
  /// Parameters:
  /// - [transaction]: The updated redemption transaction
  /// 
  /// Returns [Either<LocalException, bool>]:
  /// - Left: [LocalException] if update fails
  /// - Right: true if update succeeds
  Future<Either<LocalException, bool>> updateCachedRedemptionTransaction(RedemptionTransactionModel transaction);
  
  /// Get total redeemed points for a user from cached data
  /// 
  /// Parameters:
  /// - [userId]: The user ID
  /// - [status]: Optional status filter (completed, pending)
  /// 
  /// Returns [Either<LocalException, int>]:
  /// - Left: [LocalException] if calculation fails
  /// - Right: Total redeemed points
  Future<Either<LocalException, int>> getCachedRedeemedPoints(String userId, {String? status});
  
  /// Add redemption operation to sync queue
  /// 
  /// Parameters:
  /// - [operation]: The sync operation type
  /// - [entityType]: The entity type ('redemption_option' or 'redemption_transaction')
  /// - [entityId]: The entity ID
  /// - [data]: The operation data
  /// 
  /// Returns [Either<LocalException, bool>]:
  /// - Left: [LocalException] if queuing fails
  /// - Right: true if queuing succeeds
  Future<Either<LocalException, bool>> queueSyncOperation({
    required String operation,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
  });
  
  /// Get pending sync operations for redemptions
  /// 
  /// Returns [Either<LocalException, List<Map<String, dynamic>>>]:
  /// - Left: [LocalException] if retrieval fails
  /// - Right: List of pending operations
  Future<Either<LocalException, List<Map<String, dynamic>>>> getPendingSyncOperations();
  
  /// Remove sync operation from queue
  /// 
  /// Parameters:
  /// - [operationId]: The operation ID to remove
  /// 
  /// Returns [Either<LocalException, bool>]:
  /// - Left: [LocalException] if removal fails
  /// - Right: true if removal succeeds
  Future<Either<LocalException, bool>> removeSyncOperation(int operationId);
  
  /// Clear all cached redemption data for a user
  /// 
  /// Parameters:
  /// - [userId]: The user ID to clear data for
  /// 
  /// Returns [Either<LocalException, bool>]:
  /// - Left: [LocalException] if clearing fails
  /// - Right: true if clearing succeeds
  Future<Either<LocalException, bool>> clearUserRedemptionCache(String userId);
  
  /// Clear all cached redemption options
  /// 
  /// Returns [Either<LocalException, bool>]:
  /// - Left: [LocalException] if clearing fails
  /// - Right: true if clearing succeeds
  Future<Either<LocalException, bool>> clearRedemptionOptionsCache();
}

/// Implementation of [RedemptionLocalDataSource] using SQLite database.
@LazySingleton()
class RedemptionLocalDataSourceImpl implements RedemptionLocalDataSource {
  final DatabaseHelper _databaseHelper;
  
  const RedemptionLocalDataSourceImpl(this._databaseHelper);
  
  @override
  Future<Either<LocalException, String>> cacheRedemptionOption(RedemptionOptionModel redemptionOption) async {
    try {
      final optionData = {
        'id': redemptionOption.id,
        'title': redemptionOption.title,
        'description': redemptionOption.description,
        'required_points': redemptionOption.requiredPoints,
        'category_id': redemptionOption.categoryId,
        'image_url': redemptionOption.imageUrl,
        'is_active': redemptionOption.isActive ? 1 : 0,
        'terms_conditions': null, // Field doesn't exist in domain model
        'expiry_date': redemptionOption.expiryDate?.millisecondsSinceEpoch,
        'created_at': redemptionOption.createdAt.millisecondsSinceEpoch,
        'updated_at': redemptionOption.updatedAt?.millisecondsSinceEpoch ?? redemptionOption.createdAt.millisecondsSinceEpoch,
        'sync_status': 1, // Synced
        'version': redemptionOption.version,
      };
      
      await _databaseHelper.insertRecord(
        DatabaseHelper.tableRedemptionOptions,
        optionData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      return Either.right(redemptionOption.id);
    } catch (e) {
      return Either.left(LocalException('Failed to cache redemption option: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, PaginatedResult<RedemptionOptionModel>>> getCachedRedemptionOptions({
    int page = 1,
    int limit = 20,
    String? categoryId,
    bool? isActive,
    String? searchQuery,
    String sortBy = 'points',
    String sortOrder = 'asc',
  }) async {
    try {
      // Build where clause dynamically
      final whereConditions = <String>[];
      final whereArgs = <dynamic>[];
      
      if (categoryId != null) {
        whereConditions.add('category_id = ?');
        whereArgs.add(categoryId);
      }
      
      if (isActive != null) {
        whereConditions.add('is_active = ?');
        whereArgs.add(isActive ? 1 : 0);
      }
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        whereConditions.add('(title LIKE ? OR description LIKE ?)');
        whereArgs.add('%$searchQuery%');
        whereArgs.add('%$searchQuery%');
      }
      
      final whereClause = whereConditions.isNotEmpty ? whereConditions.join(' AND ') : null;
      
      // Validate sort parameters
      final validSortFields = ['points', 'title', 'created_date'];
      final sortField = validSortFields.contains(sortBy) ? 
        (sortBy == 'points' ? 'required_points' : 
         sortBy == 'created_date' ? 'created_at' : sortBy) : 'required_points';
      final order = sortOrder.toLowerCase() == 'desc' ? 'DESC' : 'ASC';
      
      // Get total count
      final countQuery = whereClause != null 
        ? 'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableRedemptionOptions} WHERE $whereClause'
        : 'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableRedemptionOptions}';
      final countResult = await _databaseHelper.rawQuery(countQuery, whereArgs);
      final totalCount = countResult.first['count'] as int;
      
      // Get paginated results
      final offset = (page - 1) * limit;
      final results = await _databaseHelper.queryRecords(
        DatabaseHelper.tableRedemptionOptions,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: '$sortField $order',
        limit: limit,
        offset: offset,
      );
      
      final redemptionOptions = results.map(_mapToRedemptionOptionModel).toList();
      
      final paginatedResult = PaginatedResult<RedemptionOptionModel>(
        items: redemptionOptions,
        totalCount: totalCount,
        currentPage: page,
        hasNextPage: (page * limit) < totalCount,
      );
      
      return Either.right(paginatedResult);
    } catch (e) {
      return Either.left(LocalException('Failed to get cached redemption options: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, RedemptionOptionModel>> getCachedRedemptionOption(String optionId) async {
    try {
      final results = await _databaseHelper.queryRecords(
        DatabaseHelper.tableRedemptionOptions,
        where: 'id = ?',
        whereArgs: [optionId],
        limit: 1,
      );
      
      if (results.isEmpty) {
        return Either.left(LocalException('Redemption option not found in cache'));
      }
      
      final redemptionOption = _mapToRedemptionOptionModel(results.first);
      return Either.right(redemptionOption);
    } catch (e) {
      return Either.left(LocalException('Failed to get cached redemption option: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, bool>> updateCachedRedemptionOption(RedemptionOptionModel redemptionOption) async {
    try {
      final optionData = {
        'title': redemptionOption.title,
        'description': redemptionOption.description,
        'required_points': redemptionOption.requiredPoints,
        'category_id': redemptionOption.categoryId,
        'image_url': redemptionOption.imageUrl,
        'is_active': redemptionOption.isActive ? 1 : 0,
        'terms_conditions': null, // Field doesn't exist in domain model
        'expiry_date': redemptionOption.expiryDate?.millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'sync_status': 0, // Needs sync
        'version': redemptionOption.version,
      };
      
      final result = await _databaseHelper.updateRecord(
        DatabaseHelper.tableRedemptionOptions,
        optionData,
        where: 'id = ?',
        whereArgs: [redemptionOption.id],
      );
      
      return Either.right(result > 0);
    } catch (e) {
      return Either.left(LocalException('Failed to update cached redemption option: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, bool>> deleteCachedRedemptionOption(String optionId) async {
    try {
      final result = await _databaseHelper.deleteRecord(
        DatabaseHelper.tableRedemptionOptions,
        where: 'id = ?',
        whereArgs: [optionId],
      );
      
      return Either.right(result > 0);
    } catch (e) {
      return Either.left(LocalException('Failed to delete cached redemption option: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, String>> cacheRedemptionTransaction(RedemptionTransactionModel transaction) async {
    try {
      final transactionData = {
        'id': transaction.id,
        'user_id': transaction.userId,
        'option_id': transaction.optionId,
        'points_used': transaction.pointsUsed,
        'status': transaction.status.value,
        'created_at': transaction.createdAt.millisecondsSinceEpoch,
        'completed_at': transaction.completedAt?.millisecondsSinceEpoch,
        'notes': transaction.notes,
        'sync_status': 1, // Synced
        'version': transaction.version,
      };
      
      await _databaseHelper.insertRecord(
        DatabaseHelper.tableRedemptionTransactions,
        transactionData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      return Either.right(transaction.id);
    } catch (e) {
      return Either.left(LocalException('Failed to cache redemption transaction: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, PaginatedResult<RedemptionTransactionModel>>> getCachedRedemptionTransactions({
    required String userId,
    int page = 1,
    int limit = 20,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Build where clause dynamically
      final whereConditions = <String>['user_id = ?'];
      final whereArgs = <dynamic>[userId];
      
      if (status != null) {
        whereConditions.add('status = ?');
        whereArgs.add(status);
      }
      
      if (startDate != null) {
        whereConditions.add('created_at >= ?');
        whereArgs.add(startDate.millisecondsSinceEpoch);
      }
      
      if (endDate != null) {
        whereConditions.add('created_at <= ?');
        whereArgs.add(endDate.millisecondsSinceEpoch);
      }
      
      final whereClause = whereConditions.join(' AND ');
      
      // Get total count
      final countResult = await _databaseHelper.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableRedemptionTransactions} WHERE $whereClause',
        whereArgs,
      );
      final totalCount = countResult.first['count'] as int;
      
      // Get paginated results
      final offset = (page - 1) * limit;
      final results = await _databaseHelper.queryRecords(
        DatabaseHelper.tableRedemptionTransactions,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'created_at DESC',
        limit: limit,
        offset: offset,
      );
      
      final redemptionTransactions = results.map(_mapToRedemptionTransactionModel).toList();
      
      final paginatedResult = PaginatedResult<RedemptionTransactionModel>(
        items: redemptionTransactions,
        totalCount: totalCount,
        currentPage: page,
        hasNextPage: (page * limit) < totalCount,
      );
      
      return Either.right(paginatedResult);
    } catch (e) {
      return Either.left(LocalException('Failed to get cached redemption transactions: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, RedemptionTransactionModel>> getCachedRedemptionTransaction(String transactionId) async {
    try {
      final results = await _databaseHelper.queryRecords(
        DatabaseHelper.tableRedemptionTransactions,
        where: 'id = ?',
        whereArgs: [transactionId],
        limit: 1,
      );
      
      if (results.isEmpty) {
        return Either.left(LocalException('Redemption transaction not found in cache'));
      }
      
      final redemptionTransaction = _mapToRedemptionTransactionModel(results.first);
      return Either.right(redemptionTransaction);
    } catch (e) {
      return Either.left(LocalException('Failed to get cached redemption transaction: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, bool>> updateCachedRedemptionTransaction(RedemptionTransactionModel transaction) async {
    try {
      final transactionData = {
        'status': transaction.status.value,
        'completed_at': transaction.completedAt?.millisecondsSinceEpoch,
        'notes': transaction.notes,
        'sync_status': 0, // Needs sync
        'version': transaction.version,
      };
      
      final result = await _databaseHelper.updateRecord(
        DatabaseHelper.tableRedemptionTransactions,
        transactionData,
        where: 'id = ?',
        whereArgs: [transaction.id],
      );
      
      return Either.right(result > 0);
    } catch (e) {
      return Either.left(LocalException('Failed to update cached redemption transaction: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, int>> getCachedRedeemedPoints(String userId, {String? status}) async {
    try {
      final whereConditions = ['user_id = ?'];
      final whereArgs = [userId];
      
      if (status != null) {
        whereConditions.add('status = ?');
        whereArgs.add(status);
      }
      
      final whereClause = whereConditions.join(' AND ');
      
      final result = await _databaseHelper.rawQuery(
        'SELECT SUM(points_used) as total FROM ${DatabaseHelper.tableRedemptionTransactions} WHERE $whereClause',
        whereArgs,
      );
      
      final total = result.first['total'] as int? ?? 0;
      return Either.right(total);
    } catch (e) {
      return Either.left(LocalException('Failed to calculate redeemed points: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, bool>> queueSyncOperation({
    required String operation,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final queueData = {
        'entity_type': entityType,
        'entity_id': entityId,
        'operation_type': operation,
        'data_json': jsonEncode(data),
        'priority': _getOperationPriority(operation),
        'retry_count': 0,
        'max_retries': 3,
        'created_at': now,
        'scheduled_at': now,
      };
      
      final result = await _databaseHelper.insertRecord(
        DatabaseHelper.tableSyncQueue,
        queueData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      return Either.right(result > 0);
    } catch (e) {
      return Either.left(LocalException('Failed to queue sync operation: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, List<Map<String, dynamic>>>> getPendingSyncOperations() async {
    try {
      final results = await _databaseHelper.queryRecords(
        DatabaseHelper.tableSyncQueue,
        where: 'entity_type IN (?, ?) AND retry_count < max_retries',
        whereArgs: ['redemption_option', 'redemption_transaction'],
        orderBy: 'priority DESC, created_at ASC',
      );
      
      return Either.right(results);
    } catch (e) {
      return Either.left(LocalException('Failed to get pending sync operations: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, bool>> removeSyncOperation(int operationId) async {
    try {
      final result = await _databaseHelper.deleteRecord(
        DatabaseHelper.tableSyncQueue,
        where: 'id = ?',
        whereArgs: [operationId],
      );
      
      return Either.right(result > 0);
    } catch (e) {
      return Either.left(LocalException('Failed to remove sync operation: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, bool>> clearUserRedemptionCache(String userId) async {
    try {
      await _databaseHelper.deleteRecord(
        DatabaseHelper.tableRedemptionTransactions,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      
      return Either.right(true);
    } catch (e) {
      return Either.left(LocalException('Failed to clear user redemption cache: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, bool>> clearRedemptionOptionsCache() async {
    try {
      await _databaseHelper.deleteRecord(
        DatabaseHelper.tableRedemptionOptions,
      );
      
      return Either.right(true);
    } catch (e) {
      return Either.left(LocalException('Failed to clear redemption options cache: ${e.toString()}'));
    }
  }
  
  /// Maps database row to RedemptionOptionModel
  RedemptionOptionModel _mapToRedemptionOptionModel(Map<String, dynamic> row) {
    return RedemptionOptionModel(
      id: row['id'] as String,
      title: row['title'] as String,
      description: row['description'] as String,
      requiredPoints: row['required_points'] as int,
      categoryId: row['category_id'] as String,
      imageUrl: row['image_url'] as String?,
      isActive: (row['is_active'] as int) == 1,
      expiryDate: row['expiry_date'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(row['expiry_date'] as int)
        : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
      version: row['version'] as int,
    );
  }
  
  /// Maps database row to RedemptionTransactionModel
  RedemptionTransactionModel _mapToRedemptionTransactionModel(Map<String, dynamic> row) {
    return RedemptionTransactionModel(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      optionId: row['option_id'] as String,
      pointsUsed: row['points_used'] as int,
      redeemedAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int), // Use created_at as redeemed_at
      status: RedemptionStatus.fromString(row['status'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      completedAt: row['completed_at'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(row['completed_at'] as int)
        : null,
      notes: row['notes'] as String?,
      version: row['version'] as int,
    );
  }
  
  /// Gets operation priority for sync queue ordering
  int _getOperationPriority(String operation) {
    switch (operation.toLowerCase()) {
      case 'create':
        return 10;
      case 'update':
        return 8;
      case 'delete':
        return 6;
      case 'sync':
        return 5;
      default:
        return 1;
    }
  }
  
  /// Gets cache statistics for monitoring
  Future<Either<LocalException, Map<String, dynamic>>> getCacheStats(String userId) async {
    try {
      final totalOptions = await _databaseHelper.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableRedemptionOptions}',
      );
      
      final totalTransactions = await _databaseHelper.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableRedemptionTransactions} WHERE user_id = ?',
        [userId],
      );
      
      final totalRedeemed = await _databaseHelper.rawQuery(
        'SELECT SUM(points_used) as total FROM ${DatabaseHelper.tableRedemptionTransactions} WHERE user_id = ? AND status = ?',
        [userId, 'completed'],
      );
      
      final pendingTransactions = await _databaseHelper.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableRedemptionTransactions} WHERE user_id = ? AND status = ?',
        [userId, 'pending'],
      );
      
      final pendingSync = await _databaseHelper.rawQuery(
        '''SELECT COUNT(*) as count 
           FROM ${DatabaseHelper.tableSyncQueue} 
           WHERE entity_type IN ("redemption_option", "redemption_transaction")''',
      );
      
      final lastTransaction = await _databaseHelper.rawQuery(
        '''SELECT MAX(created_at) as last_transaction 
           FROM ${DatabaseHelper.tableRedemptionTransactions} 
           WHERE user_id = ?''',
        [userId],
      );
      
      return Either.right({
        'total_options': totalOptions.first['count'],
        'total_transactions': totalTransactions.first['count'],
        'total_redeemed_points': totalRedeemed.first['total'] ?? 0,
        'pending_transactions': pendingTransactions.first['count'],
        'pending_sync_operations': pendingSync.first['count'],
        'last_transaction_date': lastTransaction.first['last_transaction'],
      });
    } catch (e) {
      return Either.left(LocalException('Failed to get cache stats: ${e.toString()}'));
    }
  }
}