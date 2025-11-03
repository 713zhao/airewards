import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/either.dart';
import '../../../shared/data/datasources/local/database_helper.dart';
import '../../domain/entities/entities.dart';
import '../models/user_model.dart';

/// Local data source for authentication data operations.
/// 
/// This class handles all local storage operations for authentication-related data
/// using SQLite database. It provides caching, offline support, and sync queue
/// management for authentication data persistence.
/// 
/// Key features:
/// - User profile caching for offline access
/// - Authentication session persistence
/// - Sync queue management for offline operations
/// - Data model conversion between domain and storage formats
/// - Cache invalidation and refresh strategies
/// - Comprehensive error handling for local operations
abstract class AuthLocalDataSource {
  /// Cache a user profile locally for offline access
  /// 
  /// Parameters:
  /// - [user]: The user model to cache
  /// 
  /// Returns [Either<LocalException, bool>]:
  /// - Left: [LocalException] if caching fails
  /// - Right: true if caching succeeds
  Future<Either<LocalException, bool>> cacheUser(UserModel user);
  
  /// Get cached user profile by ID
  /// 
  /// Parameters:
  /// - [userId]: The user ID to retrieve
  /// 
  /// Returns [Either<LocalException, UserModel>]:
  /// - Left: [LocalException] if user not found or retrieval fails
  /// - Right: [UserModel] if user is found
  Future<Either<LocalException, UserModel>> getCachedUser(String userId);
  
  /// Get cached user profile by email
  /// 
  /// Parameters:
  /// - [email]: The user email to search for
  /// 
  /// Returns [Either<LocalException, UserModel>]:
  /// - Left: [LocalException] if user not found or retrieval fails
  /// - Right: [UserModel] if user is found
  Future<Either<LocalException, UserModel>> getCachedUserByEmail(String email);
  
  /// Update cached user profile
  /// 
  /// Parameters:
  /// - [user]: The updated user model
  /// 
  /// Returns [Either<LocalException, bool>]:
  /// - Left: [LocalException] if update fails
  /// - Right: true if update succeeds
  Future<Either<LocalException, bool>> updateCachedUser(UserModel user);
  
  /// Remove cached user profile
  /// 
  /// Parameters:
  /// - [userId]: The user ID to remove
  /// 
  /// Returns [Either<LocalException, bool>]:
  /// - Left: [LocalException] if removal fails
  /// - Right: true if removal succeeds
  Future<Either<LocalException, bool>> removeCachedUser(String userId);
  
  /// Check if user is cached locally
  /// 
  /// Parameters:
  /// - [userId]: The user ID to check
  /// 
  /// Returns [Either<LocalException, bool>]:
  /// - Left: [LocalException] if check fails
  /// - Right: true if user is cached, false otherwise
  Future<Either<LocalException, bool>> isUserCached(String userId);
  
  /// Get the last active user (for auto-login functionality)
  /// 
  /// Returns [Either<LocalException, UserModel?>]:
  /// - Left: [LocalException] if retrieval fails
  /// - Right: [UserModel?] where null means no last active user
  Future<Either<LocalException, UserModel?>> getLastActiveUser();
  
  /// Set the last active user
  /// 
  /// Parameters:
  /// - [userId]: The user ID to set as last active
  /// 
  /// Returns [Either<LocalException, bool>]:
  /// - Left: [LocalException] if setting fails
  /// - Right: true if setting succeeds
  Future<Either<LocalException, bool>> setLastActiveUser(String userId);
  
  /// Clear all cached authentication data
  /// 
  /// Returns [Either<LocalException, bool>]:
  /// - Left: [LocalException] if clearing fails
  /// - Right: true if clearing succeeds
  Future<Either<LocalException, bool>> clearCache();
  
  /// Add authentication operation to sync queue
  /// 
  /// Parameters:
  /// - [operation]: The sync operation type
  /// - [data]: The operation data
  /// - [userId]: The user ID for the operation
  /// 
  /// Returns [Either<LocalException, bool>]:
  /// - Left: [LocalException] if queuing fails
  /// - Right: true if queuing succeeds
  Future<Either<LocalException, bool>> queueSyncOperation({
    required String operation,
    required Map<String, dynamic> data,
    required String userId,
  });
  
  /// Get pending sync operations for authentication
  /// 
  /// Returns [Either<LocalException, List<Map<String, dynamic>>>]:
  /// - Left: [LocalException] if retrieval fails
  /// - Right: [List<Map<String, dynamic>>] with pending operations
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
}

/// Implementation of [AuthLocalDataSource] using SQLite database.
@LazySingleton(as: AuthLocalDataSource)
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final DatabaseHelper _databaseHelper;
  
  const AuthLocalDataSourceImpl(this._databaseHelper);
  
  @override
  Future<Either<LocalException, bool>> cacheUser(UserModel user) async {
    try {
      final userData = {
        'id': user.id,
        'email': user.email,
        'display_name': user.displayName,
        'photo_url': user.photoUrl,
        'provider': user.provider.name,
        'created_at': user.createdAt.millisecondsSinceEpoch,
        'last_login_at': user.lastLoginAt.millisecondsSinceEpoch,
        'is_active': user.isActive ? 1 : 0,
        'total_points': user.totalPoints,
        'sync_status': 1, // Synced
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'version': user.version,
      };
      
      final result = await _databaseHelper.insertRecord(
        DatabaseHelper.tableUsers,
        userData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      return Either.right(result > 0);
    } catch (e) {
      return Either.left(LocalException('Failed to cache user: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, UserModel>> getCachedUser(String userId) async {
    try {
      final results = await _databaseHelper.queryRecords(
        DatabaseHelper.tableUsers,
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );
      
      if (results.isEmpty) {
        return Either.left(LocalException('User not found in cache'));
      }
      
      final user = _mapToUserModel(results.first);
      return Either.right(user);
    } catch (e) {
      return Either.left(LocalException('Failed to get cached user: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, UserModel>> getCachedUserByEmail(String email) async {
    try {
      final results = await _databaseHelper.queryRecords(
        DatabaseHelper.tableUsers,
        where: 'email = ?',
        whereArgs: [email],
        limit: 1,
      );
      
      if (results.isEmpty) {
        return Either.left(LocalException('User not found in cache'));
      }
      
      final user = _mapToUserModel(results.first);
      return Either.right(user);
    } catch (e) {
      return Either.left(LocalException('Failed to get cached user by email: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, bool>> updateCachedUser(UserModel user) async {
    try {
      final userData = {
        'display_name': user.displayName,
        'photo_url': user.photoUrl,
        'last_login_at': user.lastLoginAt.millisecondsSinceEpoch,
        'is_active': user.isActive ? 1 : 0,
        'total_points': user.totalPoints,
        'sync_status': 0, // Needs sync
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'version': user.version,
      };
      
      final result = await _databaseHelper.updateRecord(
        DatabaseHelper.tableUsers,
        userData,
        where: 'id = ?',
        whereArgs: [user.id],
      );
      
      return Either.right(result > 0);
    } catch (e) {
      return Either.left(LocalException('Failed to update cached user: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, bool>> removeCachedUser(String userId) async {
    try {
      final result = await _databaseHelper.deleteRecord(
        DatabaseHelper.tableUsers,
        where: 'id = ?',
        whereArgs: [userId],
      );
      
      return Either.right(result > 0);
    } catch (e) {
      return Either.left(LocalException('Failed to remove cached user: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, bool>> isUserCached(String userId) async {
    try {
      final results = await _databaseHelper.queryRecords(
        DatabaseHelper.tableUsers,
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );
      
      return Either.right(results.isNotEmpty);
    } catch (e) {
      return Either.left(LocalException('Failed to check user cache: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, UserModel?>> getLastActiveUser() async {
    try {
      // Get the most recently logged in active user
      final results = await _databaseHelper.queryRecords(
        DatabaseHelper.tableUsers,
        where: 'is_active = 1 AND last_login_at IS NOT NULL',
        orderBy: 'last_login_at DESC',
        limit: 1,
      );
      
      if (results.isEmpty) {
        return Either.right(null);
      }
      
      final user = _mapToUserModel(results.first);
      return Either.right(user);
    } catch (e) {
      return Either.left(LocalException('Failed to get last active user: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, bool>> setLastActiveUser(String userId) async {
    try {
      // Update the user's last login time
      final now = DateTime.now().millisecondsSinceEpoch;
      final result = await _databaseHelper.updateRecord(
        DatabaseHelper.tableUsers,
        {
          'last_login_at': now,
          'is_active': 1,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [userId],
      );
      
      return Either.right(result > 0);
    } catch (e) {
      return Either.left(LocalException('Failed to set last active user: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, bool>> clearCache() async {
    try {
      await _databaseHelper.deleteRecord(DatabaseHelper.tableUsers);
      return Either.right(true);
    } catch (e) {
      return Either.left(LocalException('Failed to clear cache: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<LocalException, bool>> queueSyncOperation({
    required String operation,
    required Map<String, dynamic> data,
    required String userId,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final queueData = {
        'entity_type': 'user',
        'entity_id': userId,
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
        where: 'entity_type = ? AND retry_count < max_retries',
        whereArgs: ['user'],
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
  
  /// Maps database row to UserModel
  UserModel _mapToUserModel(Map<String, dynamic> row) {
    return UserModel(
      id: row['id'] as String,
      email: row['email'] as String,
      displayName: row['display_name'] as String?,
      photoUrl: row['photo_url'] as String?,
      provider: AuthProvider.values.firstWhere(
        (p) => p.name == row['provider'],
        orElse: () => AuthProvider.email,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      lastLoginAt: row['last_login_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['last_login_at'] as int)
          : DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int), // Use createdAt as fallback
      isActive: (row['is_active'] as int) == 1,
      totalPoints: row['total_points'] as int,
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
  
  /// Gets cached users with pagination support
  Future<Either<LocalException, List<UserModel>>> getCachedUsers({
    int limit = 20,
    int offset = 0,
    String? searchQuery,
  }) async {
    try {
      String? whereClause;
      List<dynamic>? whereArgs;
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        whereClause = 'display_name LIKE ? OR email LIKE ?';
        whereArgs = ['%$searchQuery%', '%$searchQuery%'];
      }
      
      final results = await _databaseHelper.queryRecords(
        DatabaseHelper.tableUsers,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'last_login_at DESC, display_name ASC',
        limit: limit,
        offset: offset,
      );
      
      final users = results.map(_mapToUserModel).toList();
      return Either.right(users);
    } catch (e) {
      return Either.left(LocalException('Failed to get cached users: ${e.toString()}'));
    }
  }
  
  /// Gets cache statistics for monitoring
  Future<Either<LocalException, Map<String, dynamic>>> getCacheStats() async {
    try {
      final totalUsers = await _databaseHelper.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableUsers}',
      );
      
      final activeUsers = await _databaseHelper.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableUsers} WHERE is_active = 1',
      );
      
      final pendingSync = await _databaseHelper.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableSyncQueue} WHERE entity_type = "user"',
      );
      
      final lastCacheUpdate = await _databaseHelper.rawQuery(
        'SELECT MAX(updated_at) as last_update FROM ${DatabaseHelper.tableUsers}',
      );
      
      return Either.right({
        'total_users': totalUsers.first['count'],
        'active_users': activeUsers.first['count'],
        'pending_sync_operations': pendingSync.first['count'],
        'last_cache_update': lastCacheUpdate.first['last_update'],
      });
    } catch (e) {
      return Either.left(LocalException('Failed to get cache stats: ${e.toString()}'));
    }
  }
  
  /// Cleans up old sync operations that have exceeded retry limits
  Future<Either<LocalException, int>> cleanupFailedSyncOperations() async {
    try {
      final result = await _databaseHelper.deleteRecord(
        DatabaseHelper.tableSyncQueue,
        where: 'entity_type = "user" AND retry_count >= max_retries',
      );
      
      return Either.right(result);
    } catch (e) {
      return Either.left(LocalException('Failed to cleanup failed sync operations: ${e.toString()}'));
    }
  }
  
  /// Updates sync operation retry count and error message
  Future<Either<LocalException, bool>> updateSyncOperationError({
    required int operationId,
    required String error,
  }) async {
    try {
      final result = await _databaseHelper.rawExecute(
        '''
        UPDATE ${DatabaseHelper.tableSyncQueue} 
        SET retry_count = retry_count + 1, 
            last_error = ?,
            scheduled_at = ?
        WHERE id = ?
        ''',
        [error, DateTime.now().millisecondsSinceEpoch, operationId],
      );
      
      return Either.right(result > 0);
    } catch (e) {
      return Either.left(LocalException('Failed to update sync operation error: ${e.toString()}'));
    }
  }
}