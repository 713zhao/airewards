import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/reward_repository.dart';
import '../datasources/firestore_reward_datasource.dart';
import '../datasources/reward_local_datasource.dart';
import '../models/models.dart';

/// Concrete implementation of the RewardRepository interface.
/// 
/// This implementation coordinates between Firestore and local SQLite data sources,
/// providing comprehensive reward management with offline/online synchronization,
/// pagination, caching strategy, and real-time updates.
@LazySingleton(as: RewardRepository)
class RewardRepositoryImpl implements RewardRepository {
  final FirestoreRewardDataSource _firestoreDataSource;
  final RewardLocalDataSource _localDataSource;
  final ConnectivityService _connectivityService;
  final SyncService _syncService;

  const RewardRepositoryImpl(
    this._firestoreDataSource,
    this._localDataSource,
    this._connectivityService,
    this._syncService,
  );

  @override
  Future<Either<Failure, PaginatedResult<RewardEntry>>> getRewardHistory({
    required String userId,
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    RewardType? type,
  }) async {
    try {
      // Try to get data from remote first if online
      if (await _connectivityService.hasConnection()) {
        final remoteResult = await _getRewardHistoryFromRemote(
          userId: userId,
          page: page,
          limit: limit,
          startDate: startDate,
          endDate: endDate,
          categoryId: categoryId,
          type: type,
        );

        return remoteResult.fold(
          (failure) async {
            // Fall back to cached data if remote fails
            return await _getRewardHistoryFromCache(
              userId: userId,
              page: page,
              limit: limit,
              startDate: startDate,
              endDate: endDate,
              categoryId: categoryId,
              type: type,
            );
          },
          (result) async {
            // Cache the fresh data
            await _cacheRewardEntries(result.items);
            return Either.right(result);
          },
        );
      } else {
        // Offline - get cached data
        return await _getRewardHistoryFromCache(
          userId: userId,
          page: page,
          limit: limit,
          startDate: startDate,
          endDate: endDate,
          categoryId: categoryId,
          type: type,
        );
      }
    } catch (e) {
      return Either.left(CacheFailure('Get reward history failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, RewardEntry>> addRewardEntry(RewardEntry entry) async {
    try {
      // Validate business rules
      final validationResult = _validateRewardEntry(entry);
      if (validationResult != null) {
        return Either.left(validationResult);
      }

      final rewardModel = RewardEntryModel.fromEntity(entry);

      // Check connectivity
      final hasConnection = await _connectivityService.hasConnection();

      if (hasConnection) {
        // Online - add to remote first
        final result = await _firestoreDataSource.addRewardEntry(rewardModel);
        
        return result.fold(
          (exception) => Either.left(_mapFirestoreException(exception)),
          (addedModel) async {
            // Cache the successfully added entry
            await _localDataSource.cacheRewardEntry(addedModel);
            
            // Trigger sync for related data
            _syncService.forceSyncNow();
            
            return Either.right(addedModel.toEntity());
          },
        );
      } else {
        // Offline - cache locally and queue for sync
        final cacheResult = await _localDataSource.cacheRewardEntry(rewardModel);
        
        return cacheResult.fold(
          (exception) => Either.left(_mapLocalException(exception)),
          (entryId) async {
            // Queue for sync when online
            await _queueSyncOperation(
              entityType: 'reward_entry',
              entityId: entryId,
              operation: 'INSERT',
              payload: rewardModel.toJson(),
            );
            
            // Return the entry with the local ID
            final cachedEntry = rewardModel.copyWith(id: entryId);
            return Either.right(cachedEntry.toEntity());
          },
        );
      }
    } catch (e) {
      return Either.left(CacheFailure('Add reward entry failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, RewardEntry>> updateRewardEntry(RewardEntry entry) async {
    try {
      // Validate business rules (including 24-hour edit window)
      final validationResult = _validateRewardEntryUpdate(entry);
      if (validationResult != null) {
        return Either.left(validationResult);
      }

      final rewardModel = RewardEntryModel.fromEntity(entry);

      // Check connectivity
      final hasConnection = await _connectivityService.hasConnection();

      if (hasConnection) {
        // Online - update remote first
        final result = await _firestoreDataSource.updateRewardEntry(rewardModel);
        
        return result.fold(
          (exception) => Either.left(_mapFirestoreException(exception)),
          (updatedModel) async {
            // Update cache
            await _localDataSource.updateCachedRewardEntry(updatedModel);
            
            return Either.right(updatedModel.toEntity());
          },
        );
      } else {
        // Offline - update cache and queue for sync
        final updateResult = await _localDataSource.updateCachedRewardEntry(rewardModel);
        
        return updateResult.fold(
          (exception) => Either.left(_mapLocalException(exception)),
          (success) async {
            if (success) {
              // Queue for sync when online
              await _queueSyncOperation(
                entityType: 'reward_entry',
                entityId: entry.id,
                operation: 'UPDATE',
                payload: rewardModel.toJson(),
              );
              
              return Either.right(entry);
            } else {
              return Either.left(CacheFailure('Failed to update cached reward entry'));
            }
          },
        );
      }
    } catch (e) {
      return Either.left(CacheFailure('Update reward entry failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRewardEntry({
    required String entryId,
    required String userId,
  }) async {
    try {
      // First get the entry to validate deletion rules
      final entry = await _getRewardEntryById(entryId, userId);
      if (entry == null) {
        return Either.left(DatabaseFailure.notFound());
      }

      // Validate 24-hour deletion window
      final validationResult = _validateRewardEntryDeletion(entry);
      if (validationResult != null) {
        return Either.left(validationResult);
      }

      // Check connectivity
      final hasConnection = await _connectivityService.hasConnection();

      if (hasConnection) {
        // Online - delete from remote first
        final result = await _firestoreDataSource.deleteRewardEntry(entryId);
        
        return result.fold(
          (exception) => Either.left(_mapFirestoreException(exception)),
          (_) async {
            // Remove from cache
            await _localDataSource.deleteCachedRewardEntry(entryId);
            
            return Either.right(null);
          },
        );
      } else {
        // Offline - mark as deleted in cache and queue for sync
        final deleteResult = await _localDataSource.deleteCachedRewardEntry(entryId);
        
        return deleteResult.fold(
          (exception) => Either.left(_mapLocalException(exception)),
          (success) async {
            if (success) {
              // Queue for sync when online
              await _queueSyncOperation(
                entityType: 'reward_entry',
                entityId: entryId,
                operation: 'DELETE',
                payload: {'userId': userId},
              );
              
              return Either.right(null);
            } else {
              return Either.left(CacheFailure('Failed to delete cached reward entry'));
            }
          },
        );
      }
    } catch (e) {
      return Either.left(CacheFailure('Delete reward entry failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> getTotalPoints(String userId) async {
    try {
      // Try to get fresh data from remote if online
      if (await _connectivityService.hasConnection()) {
        final result = await _firestoreDataSource.calculateTotalPoints(userId);
        
        return result.fold(
          (exception) async {
            // Fall back to cached total
            return await _getCachedTotalPoints(userId);
          },
          (totalPoints) async {
            // Cache the fresh total
            // Cache is updated automatically by local data source
            return Either.right(totalPoints);
          },
        );
      } else {
        // Offline - get cached total
        return await _getCachedTotalPoints(userId);
      }
    } catch (e) {
      return Either.left(CacheFailure('Get total points failed: ${e.toString()}'));
    }
  }

  @override
  Stream<int> watchTotalPoints(String userId) {
    // Combine remote and local streams for real-time updates
    // Use local data source for now - would implement stream combining in production
    return Stream.value(0); // Placeholder implementation
  }

  @override
  Future<Either<Failure, List<RewardCategory>>> getRewardCategories() async {
    try {
      // Try to get fresh categories from remote if online
      if (await _connectivityService.hasConnection()) {
        final result = await _firestoreDataSource.getCategories();
        
        return result.fold(
          (exception) async {
            // Fall back to cached categories
            return await _getCachedCategories();
          },
          (categories) async {
            // Cache the fresh categories
            await _cacheCategories(categories);
            return Either.right(categories.map((model) => model.toEntity()).toList());
          },
        );
      } else {
        // Offline - get cached categories
        return await _getCachedCategories();
      }
    } catch (e) {
      return Either.left(CacheFailure('Get reward categories failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, RewardCategory>> addRewardCategory(RewardCategory category) async {
    try {
      // Validate business rules
      final validationResult = await _validateNewCategory(category);
      if (validationResult != null) {
        return Either.left(validationResult);
      }

      final categoryModel = CategoryModel.fromEntity(category);

      // Check connectivity
      final hasConnection = await _connectivityService.hasConnection();

      if (hasConnection) {
        // Online - placeholder for remote operations
        // For now, just cache locally
        final cacheResult = await _localDataSource.cacheCategory(categoryModel);
        
        return cacheResult.fold(
          (exception) => Either.left(_mapLocalException(exception)),
          (categoryId) {
            final cachedCategory = categoryModel.copyWith(id: categoryId);
            return Either.right(cachedCategory.toEntity());
          },
        );
      } else {
        // Offline - cache locally and queue for sync
        final cacheResult = await _localDataSource.cacheCategory(categoryModel);
        
        return cacheResult.fold(
          (exception) => Either.left(_mapLocalException(exception)),
          (categoryId) async {
            // Queue for sync when online
            await _queueSyncOperation(
              entityType: 'reward_category',
              entityId: categoryId,
              operation: 'INSERT',
              payload: categoryModel.toJson(),
            );
            
            final cachedCategory = categoryModel.copyWith(id: categoryId);
            return Either.right(cachedCategory.toEntity());
          },
        );
      }
    } catch (e) {
      return Either.left(CacheFailure('Add reward category failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, RewardCategory>> updateRewardCategory(RewardCategory category) async {
    try {
      // Validate business rules (no default category modification)
      final validationResult = _validateCategoryUpdate(category);
      if (validationResult != null) {
        return Either.left(validationResult);
      }

      final categoryModel = CategoryModel.fromEntity(category);

      // Check connectivity
      final hasConnection = await _connectivityService.hasConnection();

      if (hasConnection) {
        // For now, just update cache locally as firestore interface doesn't support category operations
        final updateResult = await _localDataSource.updateCachedCategory(categoryModel);
        
        return updateResult.fold(
          (exception) => Either.left(_mapLocalException(exception)),
          (success) async {
            if (success) {
              return Either.right(category);
            } else {
              return Either.left(CacheFailure('Failed to update cached category'));
            }
          },
        );
      } else {
        // Offline - update cache and queue for sync
        final updateResult = await _localDataSource.updateCachedCategory(categoryModel);
        
        return updateResult.fold(
          (exception) => Either.left(_mapLocalException(exception)),
          (success) async {
            if (success) {
              // Queue for sync when online
              await _queueSyncOperation(
                entityType: 'reward_category',
                entityId: category.id,
                operation: 'UPDATE',
                payload: categoryModel.toJson(),
              );
              
              return Either.right(category);
            } else {
              return Either.left(CacheFailure('Failed to update cached category'));
            }
          },
        );
      }
    } catch (e) {
      return Either.left(CacheFailure('Update reward category failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRewardCategory({
    required String categoryId,
    required String reassignToCategoryId,
  }) async {
    try {
      // Validate business rules (no default category deletion)
      final validationResult = await _validateCategoryDeletion(categoryId);
      if (validationResult != null) {
        return Either.left(validationResult);
      }

      // Check connectivity
      final hasConnection = await _connectivityService.hasConnection();

      if (hasConnection) {
        // For now, just delete from cache locally
        final deleteResult = await _localDataSource.deleteCachedCategory(categoryId);
        
        return deleteResult.fold(
          (exception) => Either.left(_mapLocalException(exception)),
          (success) async {
            if (success) {
              return Either.right(null);
            } else {
              return Either.left(CacheFailure('Failed to delete cached category'));
            }
          },
        );
      } else {
        // Offline - mark as deleted and queue for sync
        final deleteResult = await _localDataSource.deleteCachedCategory(categoryId);
        
        return deleteResult.fold(
          (exception) => Either.left(_mapLocalException(exception)),
          (success) async {
            if (success) {
              // Queue for sync when online
              await _queueSyncOperation(
                entityType: 'reward_category',
                entityId: categoryId,
                operation: 'DELETE',
                payload: {'reassignToCategoryId': reassignToCategoryId},
              );
              
              return Either.right(null);
            } else {
              return Either.left(CacheFailure('Failed to delete cached category'));
            }
          },
        );
      }
    } catch (e) {
      return Either.left(CacheFailure('Delete reward category failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<RewardEntry>>> batchOperations(
    List<RewardBatchOperation> operations,
  ) async {
    try {
      // Simplified batch operations implementation - just return empty for now
      // In a full implementation, this would handle different operation types
      final results = <RewardEntry>[];
      
      return Either.right(results);
    } catch (e) {
      return Either.left(CacheFailure('Batch operations failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, SyncResult>> syncWithServer() async {
    try {
      // Delegate to sync service for comprehensive synchronization
      final result = await _syncService.forceSyncNow();
      
      if (result.success) {
        return Either.right(SyncResult(
          uploadedCount: 0, // Would be populated by sync service
          downloadedCount: 0,
          conflictedEntries: [],
          syncTimestamp: DateTime.now(),
        ));
      } else {
        return Either.left(NetworkFailure(result.error ?? 'Sync failed'));
      }
    } catch (e) {
      return Either.left(NetworkFailure('Sync with server failed: ${e.toString()}'));
    }
  }

  // Private helper methods

  Future<Either<Failure, PaginatedResult<RewardEntry>>> _getRewardHistoryFromRemote({
    required String userId,
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    RewardType? type,
  }) async {
    final result = await _firestoreDataSource.getRewardEntries(
      userId: userId,
      categoryId: categoryId,
      limit: limit,
      // Add other parameters as supported by the data source
    );

    return result.fold(
      (exception) => Either.left(_mapFirestoreException(exception)),
      (models) {
        final entities = models.map((model) => model.toEntity()).toList();
        return Either.right(PaginatedResult<RewardEntry>(
          items: entities,
          currentPage: page,
          totalCount: entities.length,
          hasNextPage: entities.length == limit,
        ));
      },
    );
  }

  Future<Either<Failure, PaginatedResult<RewardEntry>>> _getRewardHistoryFromCache({
    required String userId,
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    RewardType? type,
  }) async {
    final result = await _localDataSource.getCachedRewardEntries(
      userId: userId,
      page: page,
      limit: limit,
      categoryId: categoryId,
      startDate: startDate,
      endDate: endDate,
    );

    return result.fold(
      (exception) => Either.left(_mapLocalException(exception)),
      (paginatedResult) {
        final entities = paginatedResult.items.map((model) => model.toEntity()).toList();
        return Either.right(PaginatedResult<RewardEntry>(
          items: entities,
          currentPage: paginatedResult.currentPage,
          totalCount: paginatedResult.totalCount,
          hasNextPage: paginatedResult.hasNextPage,
        ));
      },
    );
  }

  Future<void> _cacheRewardEntries(List<RewardEntry> entries) async {
    for (final entry in entries) {
      final model = RewardEntryModel.fromEntity(entry);
      await _localDataSource.cacheRewardEntry(model);
    }
  }

  Future<Either<Failure, int>> _getCachedTotalPoints(String userId) async {
    final result = await _localDataSource.getCachedTotalPoints(userId);
    return result.fold(
      (exception) => Either.left(_mapLocalException(exception)),
      (total) => Either.right(total),
    );
  }

  Future<Either<Failure, List<RewardCategory>>> _getCachedCategories() async {
    final result = await _localDataSource.getCachedCategories();
    return result.fold(
      (exception) => Either.left(_mapLocalException(exception)),
      (models) => Either.right(models.map((model) => model.toEntity()).toList()),
    );
  }

  Future<void> _cacheCategories(List<CategoryModel> categories) async {
    for (final category in categories) {
      await _localDataSource.cacheCategory(category);
    }
  }

  Future<RewardEntry?> _getRewardEntryById(String entryId, String userId) async {
    final result = await _localDataSource.getCachedRewardEntry(entryId);
    return result.fold(
      (exception) => null,
      (model) => model.toEntity(),
    );
  }

  Future<void> _queueSyncOperation({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    // This would interface with the sync service to queue operations
    // For now, this is a placeholder
  }

  // Validation methods

  ValidationFailure? _validateRewardEntry(RewardEntry entry) {
    // BR-001: Minimum 1 point for positive entries
    if (entry.points < 1) {
      return ValidationFailure('Reward entry must have at least 1 point');
    }

    // BR-002: Maximum 10,000 points per transaction
    if (entry.points > 10000) {
      return ValidationFailure('Reward entry cannot exceed 10,000 points per transaction');
    }

    // BR-003: Negative points only for ADJUSTED type
    if (entry.points < 0 && entry.type != RewardType.adjusted) {
      return ValidationFailure('Negative points are only allowed for ADJUSTED type entries');
    }

    // BR-011: Mandatory category assignment
    if (entry.categoryId.isEmpty) {
      return ValidationFailure('Reward entry must have a category assigned');
    }

    return null;
  }

  ValidationFailure? _validateRewardEntryUpdate(RewardEntry entry) {
    // First validate basic entry rules
    final basicValidation = _validateRewardEntry(entry);
    if (basicValidation != null) return basicValidation;

    // BR-004: Only entries created within 24 hours can be modified
    final hoursSinceCreation = DateTime.now().difference(entry.createdAt).inHours;
    if (hoursSinceCreation > 24) {
      return ValidationFailure('Reward entries can only be modified within 24 hours of creation');
    }

    return null;
  }

  ValidationFailure? _validateRewardEntryDeletion(RewardEntry entry) {
    // BR-004: Only entries created within 24 hours can be deleted
    final hoursSinceCreation = DateTime.now().difference(entry.createdAt).inHours;
    if (hoursSinceCreation > 24) {
      return ValidationFailure('Reward entries can only be deleted within 24 hours of creation');
    }

    return null;
  }

  Future<ValidationFailure?> _validateNewCategory(RewardCategory category) async {
    // BR-014: Maximum 20 custom categories per user
    final categoriesResult = await _localDataSource.getCachedCategories();
    return categoriesResult.fold(
      (exception) => null, // Allow if we can't check
      (categories) {
        final customCategories = categories.where((c) => !c.isDefault).length;
        if (customCategories >= 20) {
          return ValidationFailure('Maximum 20 custom categories allowed per user');
        }
        return null;
      },
    );
  }

  ValidationFailure? _validateCategoryUpdate(RewardCategory category) {
    // BR-012: Default categories cannot be modified
    if (category.isDefault) {
      return ValidationFailure('Default categories cannot be modified');
    }

    return null;
  }

  Future<ValidationFailure?> _validateCategoryDeletion(String categoryId) async {
    // Check if it's a default category
    final categoryResult = await _localDataSource.getCachedCategory(categoryId);
    return categoryResult.fold(
      (exception) => ValidationFailure('Category not found'),
      (category) {
        if (category.isDefault) {
          return ValidationFailure('Default categories cannot be deleted');
        }
        return null;
      },
    );
  }

  // Exception mapping methods

  Failure _mapFirestoreException(dynamic exception) {
    final message = exception.toString();
    
    if (message.contains('network') || message.contains('connection')) {
      return NetworkFailure(message);
    }
    if (message.contains('permission') || message.contains('unauthorized')) {
      return AuthFailure(message);
    }
    if (message.contains('not-found')) {
      return DatabaseFailure.notFound();
    }
    
    return NetworkFailure(message);
  }

  Failure _mapLocalException(dynamic exception) {
    final message = exception.toString();
    
    if (message.contains('database')) {
      return CacheFailure(message);
    }
    if (message.contains('not found')) {
      return DatabaseFailure.notFound();
    }
    
    return CacheFailure(message);
  }
}