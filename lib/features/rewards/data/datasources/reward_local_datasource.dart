import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../shared/data/datasources/local/database_helper.dart';
import '../../domain/entities/entities.dart';
import '../models/models.dart';

/// Local data source for rewards data operations.
/// 
/// This class handles all local storage operations for reward-related data
/// using SQLite database. It provides caching, offline support, and sync queue
/// management for reward entries and categories.
/// 
/// Key features:
/// - Reward entry caching with comprehensive filtering
/// - Category management and caching
/// - Point balance calculation and caching
/// - Sync queue management for offline operations
/// - Efficient pagination and search capabilities
/// - Data model conversion and validation
abstract class RewardLocalDataSource {
  /// Cache a reward entry locally
  /// 
  /// Parameters:
  /// - [rewardEntry]: The reward entry to cache
  /// 
  /// Returns [Either<LocalException, String>]:
  /// - Left: [LocalException] if caching fails
  /// - Right: The ID of the cached entry
  Future<Either<LocalException, String>> cacheRewardEntry(RewardEntryModel rewardEntry);
  
  /// Get cached reward entries with filtering and pagination
  /// 
  /// Parameters:
  /// - [userId]: The user ID to filter by
  /// - [page]: Page number (1-based)
  /// - [limit]: Number of items per page
  /// - [categoryId]: Optional category filter
  /// - [startDate]: Optional start date filter
  /// - [endDate]: Optional end date filter
  /// - [searchQuery]: Optional search query for title/description
  /// 
  /// Returns [Either<LocalException, PaginatedResult<RewardEntryModel>>]:
  /// - Left: [LocalException] if retrieval fails
  /// - Right: Paginated reward entries
  Future<Either<LocalException, PaginatedResult<RewardEntryModel>>> getCachedRewardEntries({
    required String userId,
    int page = 1,
    int limit = 20,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  });
  
  /// Get a specific cached reward entry by ID
  /// 
  /// Parameters:
  /// - [entryId]: The reward entry ID
  /// 
  /// Returns [Either<LocalException, RewardEntryModel>]:
  /// - Left: [LocalException] if entry not found or retrieval fails
  /// - Right: The reward entry
  Future<Either<LocalException, RewardEntryModel>> getCachedRewardEntry(String entryId);
  
  /// Update a cached reward entry
  /// 
  /// Parameters:
  /// - [rewardEntry]: The updated reward entry
  /// 
  /// Returns [Either<LocalException, bool>]:
  /// - Left: [LocalException] if update fails
  /// - Right: true if update succeeds
  Future<Either<LocalException, bool>> updateCachedRewardEntry(RewardEntryModel rewardEntry);
  
  /// Delete a cached reward entry
  /// 
  /// Parameters:
  /// - [entryId]: The reward entry ID to delete
  /// 
  /// Returns [Either<LocalException, bool>]:
  /// - Left: [LocalException] if deletion fails
  /// - Right: true if deletion succeeds
  Future<Either<LocalException, bool>> deleteCachedRewardEntry(String entryId);
  
  /// Get total points for a user from cached data
  /// 
  /// Parameters:
  /// - [userId]: The user ID
  /// 
  /// Returns [Either<LocalException, int>]:
  /// - Left: [LocalException] if calculation fails
  /// - Right: Total points
  Future<Either<LocalException, int>> getCachedTotalPoints(String userId);
  
  /// Cache a category locally
  /// 
  /// Parameters:
  /// - [category]: The category to cache
  /// 
  /// Returns [Either<LocalException, String>]:
  /// - Left: [LocalException] if caching fails
  /// - Right: The ID of the cached category
  Future<Either<LocalException, String>> cacheCategory(CategoryModel category);
  
  /// Get all cached categories
  /// 
  /// Returns [Either<LocalException, List<CategoryModel>>]:
  /// - Left: [LocalException] if retrieval fails
  /// - Right: List of categories
  Future<Either<LocalException, List<CategoryModel>>> getCachedCategories();
  
  /// Get a specific cached category by ID
  /// 
  /// Parameters:
  /// - [categoryId]: The category ID
  /// 
  /// Returns [Either<LocalException, CategoryModel>]:
  /// - Left: [LocalException] if category not found or retrieval fails
  /// - Right: The category
  Future<Either<LocalException, CategoryModel>> getCachedCategory(String categoryId);
  
  /// Update a cached category
  /// 
  /// Parameters:
  /// - [category]: The updated category
  /// 
  /// Returns [Either<LocalException, bool>]:
  /// - Left: [LocalException] if update fails
  /// - Right: true if update succeeds
  Future<Either<LocalException, bool>> updateCachedCategory(CategoryModel category);
  
  /// Delete a cached category
  /// 
  /// Parameters:
  /// - [categoryId]: The category ID to delete
  /// 
  /// Returns [Either<LocalException, bool>]:
  /// - Left: [LocalException] if deletion fails
  /// - Right: true if deletion succeeds
  Future<Either<LocalException, bool>> deleteCachedCategory(String categoryId);
  
  /// Check if category is used by any reward entries
  /// 
  /// Parameters:
  /// - [categoryId]: The category ID to check
  /// 
  /// Returns [Either<LocalException, bool>]:
  /// - Left: [LocalException] if check fails
  /// - Right: true if category is used
  Future<Either<LocalException, bool>> isCategoryInUse(String categoryId);
  
  /// Add reward operation to sync queue
  /// 
  /// Parameters:
  /// - [operation]: The sync operation type
  /// - [entityType]: The entity type ('reward_entry' or 'category')
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
  
  /// Get pending sync operations for rewards
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
  
  /// Clear all cached reward data for a user
  /// 
  /// Parameters:
  /// - [userId]: The user ID to clear data for
  /// 
  /// Returns [Either<LocalException, bool>]:
  /// - Left: [LocalException] if clearing fails
  /// - Right: true if clearing succeeds
  Future<Either<LocalException, bool>> clearUserRewardCache(String userId);
  
  /// Clear all cached categories (except defaults)
  /// 
  /// Returns [Either<LocalException, bool>]:
  /// - Left: [LocalException] if clearing fails
  /// - Right: true if clearing succeeds
  Future<Either<LocalException, bool>> clearCategoryCache();
}

/// Implementation of [RewardLocalDataSource] using SQLite database.
@LazySingleton(as: RewardLocalDataSource)
class RewardLocalDataSourceImpl implements RewardLocalDataSource {
  final DatabaseHelper _databaseHelper;
  
  const RewardLocalDataSourceImpl(this._databaseHelper);
  
  @override
  Future<Either<LocalException, String>> cacheRewardEntry(RewardEntryModel rewardEntry) async {
    try {
      final entryData = {
        'id': rewardEntry.id,
        'user_id': rewardEntry.userId,
        'description': rewardEntry.description,
        'points': rewardEntry.points,
        'category_id': rewardEntry.categoryId,
        'reward_type': rewardEntry.type.value,
        'created_at': rewardEntry.createdAt.millisecondsSinceEpoch,
        'updated_at': rewardEntry.updatedAt?.millisecondsSinceEpoch ?? rewardEntry.createdAt.millisecondsSinceEpoch,
        'sync_status': rewardEntry.isSynced ? 1 : 0,
        'version': rewardEntry.version,
      };
      
      await _databaseHelper.insertRecord(
        DatabaseHelper.tableRewardEntries,
        entryData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      return Either.right(rewardEntry.id);
    } catch (e) {
      return Either.left(LocalException('Failed to cache reward entry: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, PaginatedResult<RewardEntryModel>>> getCachedRewardEntries({
    required String userId,
    int page = 1,
    int limit = 20,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) async {
    try {
      // Build where clause dynamically
      final whereConditions = <String>['user_id = ?'];
      final whereArgs = <dynamic>[userId];
      
      if (categoryId != null) {
        whereConditions.add('category_id = ?');
        whereArgs.add(categoryId);
      }
      
      if (startDate != null) {
        whereConditions.add('earned_date >= ?');
        whereArgs.add(startDate.millisecondsSinceEpoch);
      }
      
      if (endDate != null) {
        whereConditions.add('earned_date <= ?');
        whereArgs.add(endDate.millisecondsSinceEpoch);
      }
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        whereConditions.add('(title LIKE ? OR description LIKE ?)');
        whereArgs.add('%$searchQuery%');
        whereArgs.add('%$searchQuery%');
      }
      
      final whereClause = whereConditions.join(' AND ');
      
      // Get total count
      final countResult = await _databaseHelper.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableRewardEntries} WHERE $whereClause',
        whereArgs,
      );
      final totalCount = countResult.first['count'] as int;
      
      // Get paginated results
      final offset = (page - 1) * limit;
      final results = await _databaseHelper.queryRecords(
        DatabaseHelper.tableRewardEntries,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'earned_date DESC, created_at DESC',
        limit: limit,
        offset: offset,
      );
      
      final rewardEntries = results.map(_mapToRewardEntryModel).toList();
      
      final paginatedResult = PaginatedResult<RewardEntryModel>(
        items: rewardEntries,
        totalCount: totalCount,
        currentPage: page,
        hasNextPage: (page * limit) < totalCount,
      );
      
      return Either.right(paginatedResult);
    } catch (e) {
      return Either.left(LocalException('Failed to get cached reward entries: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, RewardEntryModel>> getCachedRewardEntry(String entryId) async {
    try {
      final results = await _databaseHelper.queryRecords(
        DatabaseHelper.tableRewardEntries,
        where: 'id = ?',
        whereArgs: [entryId],
        limit: 1,
      );
      
      if (results.isEmpty) {
        return Either.left(LocalException('Reward entry not found in cache'));
      }
      
      final rewardEntry = _mapToRewardEntryModel(results.first);
      return Either.right(rewardEntry);
    } catch (e) {
      return Either.left(LocalException('Failed to get cached reward entry: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, bool>> updateCachedRewardEntry(RewardEntryModel rewardEntry) async {
    try {
      final entryData = {
        'description': rewardEntry.description,
        'points': rewardEntry.points,
        'category_id': rewardEntry.categoryId,
        'reward_type': rewardEntry.type.value,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'sync_status': 0, // Needs sync
        'version': rewardEntry.version,
      };
      
      final result = await _databaseHelper.updateRecord(
        DatabaseHelper.tableRewardEntries,
        entryData,
        where: 'id = ?',
        whereArgs: [rewardEntry.id],
      );
      
      return Either.right(result > 0);
    } catch (e) {
      return Either.left(LocalException('Failed to update cached reward entry: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, bool>> deleteCachedRewardEntry(String entryId) async {
    try {
      final result = await _databaseHelper.deleteRecord(
        DatabaseHelper.tableRewardEntries,
        where: 'id = ?',
        whereArgs: [entryId],
      );
      
      return Either.right(result > 0);
    } catch (e) {
      return Either.left(LocalException('Failed to delete cached reward entry: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, int>> getCachedTotalPoints(String userId) async {
    try {
      final result = await _databaseHelper.rawQuery(
        'SELECT SUM(points) as total FROM ${DatabaseHelper.tableRewardEntries} WHERE user_id = ?',
        [userId],
      );
      
      final total = result.first['total'] as int? ?? 0;
      return Either.right(total);
    } catch (e) {
      return Either.left(LocalException('Failed to calculate total points: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, String>> cacheCategory(CategoryModel category) async {
    try {
      final categoryData = {
        'id': category.id,
        'name': category.name,
        'description': category.description,
        'color_value': category.color.value,
        'icon_code_point': category.iconData.codePoint,
        'icon_font_family': category.iconData.fontFamily ?? 'MaterialIcons',
        'is_default': category.isDefault ? 1 : 0,
        'created_at': category.createdAt.millisecondsSinceEpoch,
        'updated_at': category.updatedAt.millisecondsSinceEpoch,
        'sync_status': 1, // Synced
        'version': category.version,
      };
      
      await _databaseHelper.insertRecord(
        DatabaseHelper.tableCategories,
        categoryData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      return Either.right(category.id);
    } catch (e) {
      return Either.left(LocalException('Failed to cache category: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, List<CategoryModel>>> getCachedCategories() async {
    try {
      final results = await _databaseHelper.queryRecords(
        DatabaseHelper.tableCategories,
        orderBy: 'is_default DESC, name ASC',
      );
      
      final categories = results.map(_mapToCategoryModel).toList();
      return Either.right(categories);
    } catch (e) {
      return Either.left(LocalException('Failed to get cached categories: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, CategoryModel>> getCachedCategory(String categoryId) async {
    try {
      final results = await _databaseHelper.queryRecords(
        DatabaseHelper.tableCategories,
        where: 'id = ?',
        whereArgs: [categoryId],
        limit: 1,
      );
      
      if (results.isEmpty) {
        return Either.left(LocalException('Category not found in cache'));
      }
      
      final category = _mapToCategoryModel(results.first);
      return Either.right(category);
    } catch (e) {
      return Either.left(LocalException('Failed to get cached category: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, bool>> updateCachedCategory(CategoryModel category) async {
    try {
      final categoryData = {
        'name': category.name,
        'description': category.description,
        'color_value': category.color.value,
        'icon_code_point': category.iconData.codePoint,
        'icon_font_family': category.iconData.fontFamily ?? 'MaterialIcons',
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'sync_status': 0, // Needs sync
        'version': category.version,
      };
      
      final result = await _databaseHelper.updateRecord(
        DatabaseHelper.tableCategories,
        categoryData,
        where: 'id = ? AND is_default = 0', // Don't update default categories
        whereArgs: [category.id],
      );
      
      return Either.right(result > 0);
    } catch (e) {
      return Either.left(LocalException('Failed to update cached category: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, bool>> deleteCachedCategory(String categoryId) async {
    try {
      final result = await _databaseHelper.deleteRecord(
        DatabaseHelper.tableCategories,
        where: 'id = ? AND is_default = 0', // Don't delete default categories
        whereArgs: [categoryId],
      );
      
      return Either.right(result > 0);
    } catch (e) {
      return Either.left(LocalException('Failed to delete cached category: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, bool>> isCategoryInUse(String categoryId) async {
    try {
      final result = await _databaseHelper.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableRewardEntries} WHERE category_id = ?',
        [categoryId],
      );
      
      final count = result.first['count'] as int;
      return Either.right(count > 0);
    } catch (e) {
      return Either.left(LocalException('Failed to check category usage: ${e.toString()}'));
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
        whereArgs: ['reward_entry', 'category'],
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
  Future<Either<LocalException, bool>> clearUserRewardCache(String userId) async {
    try {
      await _databaseHelper.deleteRecord(
        DatabaseHelper.tableRewardEntries,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      
      return Either.right(true);
    } catch (e) {
      return Either.left(LocalException('Failed to clear user reward cache: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, bool>> clearCategoryCache() async {
    try {
      await _databaseHelper.deleteRecord(
        DatabaseHelper.tableCategories,
        where: 'is_default = 0', // Only clear non-default categories
      );
      
      return Either.right(true);
    } catch (e) {
      return Either.left(LocalException('Failed to clear category cache: ${e.toString()}'));
    }
  }
  
  /// Maps database row to RewardEntryModel
  RewardEntryModel _mapToRewardEntryModel(Map<String, dynamic> row) {
    return RewardEntryModel(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      description: (row['description'] as String?) ?? '',
      points: row['points'] as int,
      categoryId: row['category_id'] as String,
      type: RewardType.fromString(row['reward_type'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: row['updated_at'] != null ? DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int) : null,
      isSynced: (row['sync_status'] as int) == 1,
      version: row['version'] as int,
    );
  }
  
  /// Maps database row to CategoryModel
  CategoryModel _mapToCategoryModel(Map<String, dynamic> row) {
    return CategoryModel(
      id: row['id'] as String,
      name: row['name'] as String,
      description: row['description'] as String?,
      color: Color(row['color_value'] as int),
      iconData: IconData(
        row['icon_code_point'] as int,
        fontFamily: row['icon_font_family'] as String,
      ),
      isDefault: (row['is_default'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
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
      final totalEntries = await _databaseHelper.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableRewardEntries} WHERE user_id = ?',
        [userId],
      );
      
      final totalPoints = await _databaseHelper.rawQuery(
        'SELECT SUM(points) as total FROM ${DatabaseHelper.tableRewardEntries} WHERE user_id = ?',
        [userId],
      );
      
      final categoriesUsed = await _databaseHelper.rawQuery(
        '''SELECT COUNT(DISTINCT category_id) as count 
           FROM ${DatabaseHelper.tableRewardEntries} 
           WHERE user_id = ?''',
        [userId],
      );
      
      final pendingSync = await _databaseHelper.rawQuery(
        '''SELECT COUNT(*) as count 
           FROM ${DatabaseHelper.tableSyncQueue} 
           WHERE entity_type IN ("reward_entry", "category")''',
      );
      
      final lastUpdate = await _databaseHelper.rawQuery(
        '''SELECT MAX(updated_at) as last_update 
           FROM ${DatabaseHelper.tableRewardEntries} 
           WHERE user_id = ?''',
        [userId],
      );
      
      return Either.right({
        'total_entries': totalEntries.first['count'],
        'total_points': totalPoints.first['total'] ?? 0,
        'categories_used': categoriesUsed.first['count'],
        'pending_sync_operations': pendingSync.first['count'],
        'last_cache_update': lastUpdate.first['last_update'],
      });
    } catch (e) {
      return Either.left(LocalException('Failed to get cache stats: ${e.toString()}'));
    }
  }
}