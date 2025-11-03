import '../../../../core/errors/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/utils/either.dart';
import '../entities/entities.dart';

/// Repository interface for reward-related data operations
/// 
/// This interface defines the contract for all reward data operations,
/// following the Repository pattern from Clean Architecture.
/// Implementations should handle data persistence, caching, and synchronization.
abstract class RewardRepository {
  /// Retrieves paginated reward history for a user with optional filtering
  /// 
  /// Parameters:
  /// - [userId]: The user's unique identifier
  /// - [page]: Page number for pagination (1-based, defaults to 1)
  /// - [limit]: Maximum items per page (defaults to 20)
  /// - [startDate]: Optional start date for filtering entries
  /// - [endDate]: Optional end date for filtering entries  
  /// - [categoryId]: Optional category ID for filtering by category
  /// - [type]: Optional reward type filter (EARNED, ADJUSTED, BONUS)
  /// 
  /// Returns:
  /// - Right: [PaginatedResult<RewardEntry>] with filtered results
  /// - Left: [Failure] if operation fails (network, validation, etc.)
  /// 
  /// Example:
  /// ```dart
  /// final result = await repository.getRewardHistory(
  ///   userId: 'user123',
  ///   page: 1,
  ///   limit: 10,
  ///   categoryId: 'fitness',
  /// );
  /// ```
  Future<Either<Failure, PaginatedResult<RewardEntry>>> getRewardHistory({
    required String userId,
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    RewardType? type,
  });

  /// Adds a new reward entry to the system
  /// 
  /// Validates business rules before persistence:
  /// - BR-001: Minimum 1 point for positive entries
  /// - BR-002: Maximum 10,000 points per transaction  
  /// - BR-003: Negative points only for ADJUSTED type
  /// - BR-011: Mandatory category assignment
  /// 
  /// Parameters:
  /// - [entry]: The reward entry to add
  /// 
  /// Returns:
  /// - Right: [RewardEntry] with server-assigned ID and timestamps
  /// - Left: [ValidationFailure] for business rule violations
  /// - Left: [NetworkFailure] for connectivity issues
  /// 
  /// Example:
  /// ```dart
  /// final entry = RewardEntry.create(
  ///   id: 'temp-id',
  ///   userId: 'user123', 
  ///   points: 100,
  ///   description: 'Completed workout',
  ///   categoryId: 'fitness',
  ///   createdAt: DateTime.now(),
  ///   type: RewardType.earned,
  /// ).right;
  /// 
  /// final result = await repository.addRewardEntry(entry);
  /// ```
  Future<Either<Failure, RewardEntry>> addRewardEntry(RewardEntry entry);

  /// Updates an existing reward entry
  /// 
  /// Business rule validation:
  /// - BR-004: Only entries created within 24 hours can be modified
  /// - All creation validation rules apply to updated content
  /// 
  /// Parameters:
  /// - [entry]: The reward entry with updated values
  /// 
  /// Returns:
  /// - Right: [RewardEntry] with updated timestamp and sync status
  /// - Left: [ValidationFailure] for business rule violations
  /// - Left: [NotFoundFailure] if entry doesn't exist
  /// - Left: [AuthFailure] if user doesn't own the entry
  /// 
  /// Example:
  /// ```dart
  /// final updatedEntry = existingEntry.copyWith(
  ///   description: 'Updated workout description',
  ///   points: 150,
  /// );
  /// 
  /// final result = await repository.updateRewardEntry(updatedEntry);
  /// ```
  Future<Either<Failure, RewardEntry>> updateRewardEntry(RewardEntry entry);

  /// Deletes a reward entry by ID
  /// 
  /// Business rule validation:
  /// - BR-004: Only entries created within 24 hours can be deleted
  /// - BR-005: Deleted points affect total balance immediately
  /// - Requires user ownership verification
  /// 
  /// Parameters:
  /// - [entryId]: Unique identifier of the entry to delete
  /// - [userId]: User ID for ownership verification
  /// 
  /// Returns:
  /// - Right: void on successful deletion
  /// - Left: [ValidationFailure] for business rule violations
  /// - Left: [NotFoundFailure] if entry doesn't exist
  /// - Left: [AuthFailure] if user doesn't own the entry
  /// 
  /// Example:
  /// ```dart
  /// final result = await repository.deleteRewardEntry(
  ///   entryId: 'entry123',
  ///   userId: 'user123',
  /// );
  /// ```
  Future<Either<Failure, void>> deleteRewardEntry({
    required String entryId,
    required String userId,
  });

  /// Retrieves the current total points for a user
  /// 
  /// Calculates the sum of all reward entries for the specified user,
  /// including earned points, bonuses, and adjustments.
  /// 
  /// Parameters:
  /// - [userId]: The user's unique identifier
  /// 
  /// Returns:
  /// - Right: [int] total points balance
  /// - Left: [Failure] if operation fails
  /// 
  /// Example:
  /// ```dart
  /// final result = await repository.getTotalPoints('user123');
  /// if (result.isRight) {
  ///   print('Total points: ${result.right}');
  /// }
  /// ```
  Future<Either<Failure, int>> getTotalPoints(String userId);

  /// Watches total points for a user with real-time updates
  /// 
  /// Returns a stream that emits the current total whenever points change.
  /// Useful for real-time UI updates without polling.
  /// 
  /// Parameters:
  /// - [userId]: The user's unique identifier
  /// 
  /// Returns:
  /// - Stream<int> that emits total points on changes
  /// - Stream errors represent failures (network, auth, etc.)
  /// 
  /// Example:
  /// ```dart
  /// repository.watchTotalPoints('user123').listen(
  ///   (totalPoints) => print('Points updated: $totalPoints'),
  ///   onError: (error) => print('Error watching points: $error'),
  /// );
  /// ```
  Stream<int> watchTotalPoints(String userId);

  /// Retrieves available reward categories for the user
  /// 
  /// Returns both default system categories and user-created custom categories.
  /// Categories are used to organize reward entries by activity type.
  /// 
  /// Returns:
  /// - Right: [List<RewardCategory>] sorted by name
  /// - Left: [Failure] if operation fails
  /// 
  /// Example:
  /// ```dart
  /// final result = await repository.getRewardCategories();
  /// if (result.isRight) {
  ///   final categories = result.right;
  ///   print('Available categories: ${categories.length}');
  /// }
  /// ```
  Future<Either<Failure, List<RewardCategory>>> getRewardCategories();

  /// Adds a new custom reward category
  /// 
  /// Business rule validation:
  /// - BR-014: Maximum 20 custom categories per user
  /// - Category name must be unique for the user
  /// - Name validation (length, characters)
  /// 
  /// Parameters:
  /// - [category]: The category to add
  /// 
  /// Returns:
  /// - Right: [RewardCategory] with server-assigned ID
  /// - Left: [ValidationFailure] for business rule violations
  /// 
  /// Example:
  /// ```dart
  /// final category = RewardCategory.create(
  ///   id: 'temp-id',
  ///   name: 'Reading',
  ///   color: Colors.green,
  ///   iconData: Icons.book,
  /// ).right;
  /// 
  /// final result = await repository.addRewardCategory(category);
  /// ```
  Future<Either<Failure, RewardCategory>> addRewardCategory(RewardCategory category);

  /// Updates an existing custom reward category
  /// 
  /// Business rule validation:
  /// - BR-012: Default categories cannot be modified
  /// - Name uniqueness validation
  /// - User ownership verification
  /// 
  /// Parameters:
  /// - [category]: The category with updated values
  /// 
  /// Returns:
  /// - Right: [RewardCategory] with updated values
  /// - Left: [ValidationFailure] for business rule violations
  /// - Left: [NotFoundFailure] if category doesn't exist
  /// 
  /// Example:
  /// ```dart
  /// final updatedCategory = existingCategory.copyWith(
  ///   name: 'Updated Reading',
  ///   color: Colors.blue,
  /// );
  /// 
  /// final result = await repository.updateRewardCategory(updatedCategory);
  /// ```
  Future<Either<Failure, RewardCategory>> updateRewardCategory(RewardCategory category);

  /// Deletes a custom reward category
  /// 
  /// Business rule validation:
  /// - BR-012: Default categories cannot be deleted
  /// - BR-013: Category deletion requires reassignment of existing entries
  /// - User ownership verification
  /// 
  /// Parameters:
  /// - [categoryId]: ID of the category to delete
  /// - [reassignToCategoryId]: ID of category to reassign existing entries to
  /// 
  /// Returns:
  /// - Right: void on successful deletion and reassignment
  /// - Left: [ValidationFailure] for business rule violations
  /// - Left: [NotFoundFailure] if category doesn't exist
  /// 
  /// Example:
  /// ```dart
  /// final result = await repository.deleteRewardCategory(
  ///   categoryId: 'custom-category-id',
  ///   reassignToCategoryId: 'general-category-id',
  /// );
  /// ```
  Future<Either<Failure, void>> deleteRewardCategory({
    required String categoryId,
    required String reassignToCategoryId,
  });

  /// Performs batch operations for offline sync
  /// 
  /// Processes multiple reward operations atomically to ensure data consistency
  /// during offline synchronization. All operations succeed or all fail.
  /// 
  /// Parameters:
  /// - [operations]: List of operations to perform
  /// 
  /// Returns:
  /// - Right: [List<RewardEntry>] results of all operations
  /// - Left: [Failure] if any operation fails (all operations rolled back)
  /// 
  /// Example:
  /// ```dart
  /// final operations = [
  ///   RewardBatchOperation.add(entry1),
  ///   RewardBatchOperation.update(entry2),
  ///   RewardBatchOperation.delete(entry3.id, userId),
  /// ];
  /// 
  /// final result = await repository.batchOperations(operations);
  /// ```
  Future<Either<Failure, List<RewardEntry>>> batchOperations(
    List<RewardBatchOperation> operations,
  );

  /// Syncs local changes with remote server
  /// 
  /// Uploads pending local changes and downloads remote updates.
  /// Handles conflict resolution for concurrent edits.
  /// 
  /// Returns:
  /// - Right: [SyncResult] with statistics and conflicts
  /// - Left: [NetworkFailure] if sync fails
  /// 
  /// Example:
  /// ```dart
  /// final result = await repository.syncWithServer();
  /// if (result.isRight) {
  ///   final syncResult = result.right;
  ///   print('Synced ${syncResult.uploadedCount} entries');
  /// }
  /// ```
  Future<Either<Failure, SyncResult>> syncWithServer();
}

/// Represents a batch operation for reward entries
abstract class RewardBatchOperation {
  const RewardBatchOperation();

  /// Creates an add operation
  const factory RewardBatchOperation.add(RewardEntry entry) = _AddOperation;
  
  /// Creates an update operation  
  const factory RewardBatchOperation.update(RewardEntry entry) = _UpdateOperation;
  
  /// Creates a delete operation
  const factory RewardBatchOperation.delete(String entryId, String userId) = _DeleteOperation;
}

class _AddOperation extends RewardBatchOperation {
  final RewardEntry entry;
  const _AddOperation(this.entry);
}

class _UpdateOperation extends RewardBatchOperation {
  final RewardEntry entry;  
  const _UpdateOperation(this.entry);
}

class _DeleteOperation extends RewardBatchOperation {
  final String entryId;
  final String userId;
  const _DeleteOperation(this.entryId, this.userId);
}

/// Result of a synchronization operation
class SyncResult {
  final int uploadedCount;
  final int downloadedCount; 
  final List<String> conflictedEntries;
  final DateTime syncTimestamp;

  const SyncResult({
    required this.uploadedCount,
    required this.downloadedCount,
    required this.conflictedEntries,
    required this.syncTimestamp,
  });
}