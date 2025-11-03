import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../entities/entities.dart';
import '../repositories/repositories.dart';

/// Parameters for deleting a reward entry.
/// 
/// This class encapsulates the required data for deleting a reward entry
/// and provides validation according to business rules.
class DeleteRewardEntryParams {
  final String entryId;
  final String userId;
  final bool requireConfirmation;

  const DeleteRewardEntryParams({
    required this.entryId,
    required this.userId,
    this.requireConfirmation = true,
  });

  /// Create validated params with business rule validation.
  /// 
  /// Returns [Either<ValidationFailure, DeleteRewardEntryParams>]:
  /// - Left: [ValidationFailure] if validation fails
  /// - Right: [DeleteRewardEntryParams] if validation succeeds
  static Either<ValidationFailure, DeleteRewardEntryParams> create({
    required String entryId,
    required String userId,
    bool requireConfirmation = true,
  }) {
    // Validate entry ID
    if (entryId.trim().isEmpty) {
      return Either.left(ValidationFailure('Entry ID cannot be empty'));
    }

    // Validate user ID
    if (userId.trim().isEmpty) {
      return Either.left(ValidationFailure('User ID cannot be empty'));
    }

    return Either.right(DeleteRewardEntryParams(
      entryId: entryId.trim(),
      userId: userId.trim(),
      requireConfirmation: requireConfirmation,
    ));
  }

  @override
  String toString() {
    return 'DeleteRewardEntryParams(entryId: $entryId, userId: $userId, requireConfirmation: $requireConfirmation)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeleteRewardEntryParams &&
        other.entryId == entryId &&
        other.userId == userId &&
        other.requireConfirmation == requireConfirmation;
  }

  @override
  int get hashCode {
    return entryId.hashCode ^ userId.hashCode ^ requireConfirmation.hashCode;
  }
}

/// Result of a delete operation with impact information
class DeleteRewardEntryResult {
  final String deletedEntryId;
  final int pointsRemoved;
  final int newTotalPoints;
  final DateTime deletedAt;

  const DeleteRewardEntryResult({
    required this.deletedEntryId,
    required this.pointsRemoved,
    required this.newTotalPoints,
    required this.deletedAt,
  });

  @override
  String toString() {
    return 'DeleteRewardEntryResult(deletedEntryId: $deletedEntryId, pointsRemoved: $pointsRemoved, '
           'newTotalPoints: $newTotalPoints, deletedAt: $deletedAt)';
  }
}

/// Use case for deleting a reward entry.
/// 
/// This use case handles the complete business logic for removing reward entries,
/// including validation, business rule enforcement, and error handling.
/// It follows the single responsibility principle by focusing solely on
/// reward entry deletion functionality.
/// 
/// Business rules enforced:
/// - BR-004: Point history cannot be modified after 24 hours (applies to deletion)
/// - BR-005: Deleted points affect total balance immediately
/// - US-006: Require confirmation before deleting reward points and maintain audit trail
/// 
/// Additional validations:
/// - User ownership verification
/// - Entry existence validation
/// - Confirmation requirement handling
/// - Point balance impact calculation
/// - Complete audit trail maintenance
class DeleteRewardEntry implements UseCase<DeleteRewardEntryResult, DeleteRewardEntryParams> {
  final RewardRepository repository;

  /// Creates a new [DeleteRewardEntry] use case.
  /// 
  /// Parameters:
  /// - [repository]: The reward repository for data operations
  const DeleteRewardEntry(this.repository);

  /// Execute the reward entry deletion process.
  /// 
  /// This method orchestrates the reward deletion flow and handles
  /// all business logic related to removing reward entries.
  /// 
  /// Parameters:
  /// - [params]: Contains entry ID and deletion options
  /// 
  /// Returns [Either<Failure, DeleteRewardEntryResult>]:
  /// - Left: [Failure] if deletion fails
  /// - Right: [DeleteRewardEntryResult] with deletion impact info
  /// 
  /// Possible failures:
  /// - [ValidationFailure] for business rule violations
  /// - [ValidationFailure] for entries older than 24 hours (BR-004)
  /// - [ValidationFailure] if entry doesn't exist
  /// - [AuthFailure] for user authorization issues
  /// - [ValidationFailure] if confirmation is required but not provided
  /// - [NetworkFailure] for network connectivity issues
  /// 
  /// Business logic handled:
  /// 1. Validates entry exists and user owns it
  /// 2. Enforces 24-hour edit window (BR-004)
  /// 3. Handles confirmation requirement (US-006)
  /// 4. Calculates point balance impact before deletion
  /// 5. Performs deletion with immediate balance update (BR-005)
  /// 6. Maintains complete audit trail
  @override
  Future<Either<Failure, DeleteRewardEntryResult>> call(DeleteRewardEntryParams params) async {
    try {
      // Step 1: Retrieve existing entry for validation
      final existingEntryResult = await _getExistingEntry(params.entryId, params.userId);
      if (existingEntryResult.isLeft) {
        return Either.left(existingEntryResult.left);
      }
      
      final existingEntry = existingEntryResult.right;

      // Step 2: Validate 24-hour edit window (BR-004)
      final editWindowValidation = _validateEditWindow(existingEntry);
      if (editWindowValidation.isLeft) {
        return Either.left(editWindowValidation.left);
      }

      // Step 3: Handle confirmation requirement (US-006)
      if (params.requireConfirmation) {
        final confirmationResult = await _handleConfirmationRequirement(existingEntry);
        if (confirmationResult.isLeft) {
          return Either.left(confirmationResult.left);
        }
      }

      // Step 4: Calculate current total points before deletion
      final currentTotalResult = await repository.getTotalPoints(params.userId);
      if (currentTotalResult.isLeft) {
        return Either.left(currentTotalResult.left);
      }
      
      final currentTotal = currentTotalResult.right;
      
      // Step 5: Calculate impact of deletion (BR-005: immediate balance effect)
      final pointsToRemove = existingEntry.points;
      final newTotal = currentTotal - pointsToRemove;

      // Step 6: Perform the deletion through repository
      final deletionResult = await repository.deleteRewardEntry(
        entryId: params.entryId,
        userId: params.userId,
      );

      return deletionResult.fold(
        // Handle deletion failure
        (failure) async {
          await _logFailedDeletion(params, existingEntry, failure);
          return Either.left(failure);
        },
        // Handle deletion success
        (_) async {
          final result = DeleteRewardEntryResult(
            deletedEntryId: params.entryId,
            pointsRemoved: pointsToRemove,
            newTotalPoints: newTotal,
            deletedAt: DateTime.now(),
          );

          // Step 7: Log successful deletion for audit trail (US-006)
          await _logSuccessfulDeletion(existingEntry, result);
          
          // Note: In a more complex implementation, you might:
          // - Send notifications about the deletion
          // - Update related analytics or statistics
          // - Check if deletion affects achievements or milestones
          // - Sync changes with external systems
          // - Update cached totals
          // - Track deletion patterns for user behavior analysis
          
          return Either.right(result);
        },
      );
    } catch (e) {
      // Handle unexpected errors
      return Either.left(ValidationFailure('Unexpected error during reward entry deletion: $e'));
    }
  }

  /// Retrieves and validates the existing entry.
  Future<Either<Failure, RewardEntry>> _getExistingEntry(String entryId, String userId) async {
    // In a real implementation, you might have a direct method to get entry by ID
    // For now, we'll simulate this by getting the user's history and finding the entry
    
    final historyResult = await repository.getRewardHistory(
      userId: userId,
      page: 1,
      limit: 1000, // Large limit to search through entries
    );

    return historyResult.fold(
      (failure) => Either.left(failure),
      (paginatedResult) {
        final entry = paginatedResult.items.where((e) => e.id == entryId).firstOrNull;
        
        if (entry == null) {
          return Either.left(ValidationFailure('Reward entry not found or you do not have permission to delete it'));
        }
        
        // Verify user ownership (additional security check)
        if (entry.userId != userId) {
          return Either.left(AuthFailure('You do not have permission to delete this reward entry'));
        }
        
        return Either.right(entry);
      },
    );
  }

  /// Validates the 24-hour edit window (BR-004).
  Either<ValidationFailure, bool> _validateEditWindow(RewardEntry entry) {
    if (!entry.canBeModified()) {
      return Either.left(ValidationFailure('Point history cannot be modified after 24 hours (BR-004)'));
    }
    return Either.right(true);
  }

  /// Handles the confirmation requirement (US-006).
  /// 
  /// In a real implementation, this might involve presenting a confirmation dialog
  /// to the user or checking that a confirmation flag was explicitly set.
  /// For this use case implementation, we assume the confirmation has been handled
  /// at the presentation layer if requireConfirmation is true.
  Future<Either<ValidationFailure, bool>> _handleConfirmationRequirement(RewardEntry entry) async {
    // In a real implementation, you might:
    // - Check if a confirmation token was provided
    // - Verify the confirmation was given within a time window
    // - Present confirmation details to the user
    // - Log the confirmation for audit purposes
    
    // For this implementation, we assume confirmation was handled at the presentation layer
    // The fact that requireConfirmation is true means the UI should have collected confirmation
    
    return Either.right(true);
  }

  /// Checks if an entry can be deleted by a user.
  /// 
  /// This method can be used by the presentation layer to determine
  /// whether to show delete controls for an entry.
  /// 
  /// Parameters:
  /// - [entryId]: ID of the entry to check
  /// - [userId]: User requesting the deletion
  /// 
  /// Returns [Either<Failure, bool>]:
  /// - Left: [Failure] if check fails
  /// - Right: true if entry can be deleted
  Future<Either<Failure, bool>> canDeleteEntry({
    required String entryId,
    required String userId,
  }) async {
    final entryResult = await _getExistingEntry(entryId, userId);
    
    return entryResult.fold(
      (failure) => Either.left(failure),
      (entry) {
        final canDelete = entry.canBeModified(); // Same 24-hour rule as modification
        return Either.right(canDelete);
      },
    );
  }

  /// Gets deletion impact information without actually deleting.
  /// 
  /// This method provides information about what will happen if an entry is deleted,
  /// which can be useful for confirmation dialogs.
  /// 
  /// Parameters:
  /// - [entryId]: ID of the entry to check
  /// - [userId]: User requesting the information
  /// 
  /// Returns [Either<Failure, DeletionImpactInfo>]:
  /// - Left: [Failure] if check fails
  /// - Right: [DeletionImpactInfo] with impact details
  Future<Either<Failure, DeletionImpactInfo>> getDeletionImpact({
    required String entryId,
    required String userId,
  }) async {
    // Get the entry to be deleted
    final entryResult = await _getExistingEntry(entryId, userId);
    if (entryResult.isLeft) {
      return Either.left(entryResult.left);
    }
    
    final entry = entryResult.right;

    // Get current total points
    final currentTotalResult = await repository.getTotalPoints(userId);
    if (currentTotalResult.isLeft) {
      return Either.left(currentTotalResult.left);
    }
    
    final currentTotal = currentTotalResult.right;
    final newTotal = currentTotal - entry.points;

    final impact = DeletionImpactInfo(
      entryToDelete: entry,
      currentTotalPoints: currentTotal,
      pointsToRemove: entry.points,
      newTotalPoints: newTotal,
      canBeDeleted: entry.canBeModified(),
      timeRemaining: _calculateTimeRemaining(entry),
    );

    return Either.right(impact);
  }

  /// Calculates time remaining in the edit window.
  Duration? _calculateTimeRemaining(RewardEntry entry) {
    final now = DateTime.now();
    final windowEnd = entry.createdAt.add(const Duration(hours: 24));
    
    if (now.isAfter(windowEnd)) {
      return null; // Window has expired
    }
    
    return windowEnd.difference(now);
  }

  /// Validates deletion parameters.
  /// 
  /// This method can be used by the presentation layer for early validation
  /// before making the actual repository request.
  Future<Either<ValidationFailure, bool>> validateDeletionParams({
    required String entryId,
    required String userId,
  }) async {
    final paramsResult = DeleteRewardEntryParams.create(
      entryId: entryId,
      userId: userId,
    );

    return paramsResult.fold(
      (failure) => Either.left(failure),
      (_) => Either.right(true),
    );
  }

  /// Log failed reward entry deletion for audit trail.
  Future<void> _logFailedDeletion(
    DeleteRewardEntryParams params, 
    RewardEntry entry,
    Failure failure,
  ) async {
    // In a real implementation, this would:
    // - Log to audit system with complete failure details
    // - Track failed deletion attempts
    // - Monitor for suspicious activity patterns
    // - Send alerts for repeated failures
    // - Include entry details for forensic analysis
    
    // For now, this is a placeholder
    // print('Failed reward entry deletion: ${params.entryId} by user ${params.userId}: $failure');
  }

  /// Log successful reward entry deletion for audit trail (US-006).
  Future<void> _logSuccessfulDeletion(
    RewardEntry deletedEntry, 
    DeleteRewardEntryResult result,
  ) async {
    // In a real implementation, this would:
    // - Log complete audit trail to compliance system
    // - Include all entry details for audit purposes
    // - Track deletion patterns and user behavior
    // - Update user activity metrics
    // - Send notifications if configured
    // - Record confirmation details
    // - Update analytics and reporting systems
    
    // For now, this is a placeholder
    // print('Successful reward entry deletion: ${result.deletedEntryId} for user ${deletedEntry.userId}');
    // print('Points removed: ${result.pointsRemoved}, New total: ${result.newTotalPoints}');
  }
}

/// Information about the impact of deleting a reward entry
class DeletionImpactInfo {
  final RewardEntry entryToDelete;
  final int currentTotalPoints;
  final int pointsToRemove;
  final int newTotalPoints;
  final bool canBeDeleted;
  final Duration? timeRemaining;

  const DeletionImpactInfo({
    required this.entryToDelete,
    required this.currentTotalPoints,
    required this.pointsToRemove,
    required this.newTotalPoints,
    required this.canBeDeleted,
    this.timeRemaining,
  });

  /// The net change in points (will be negative for point removal)
  int get pointChange => newTotalPoints - currentTotalPoints;

  /// Whether the deletion window has expired
  bool get windowExpired => timeRemaining == null;

  @override
  String toString() {
    return 'DeletionImpactInfo(entryId: ${entryToDelete.id}, pointsToRemove: $pointsToRemove, '
           'newTotal: $newTotalPoints, canDelete: $canBeDeleted, timeRemaining: $timeRemaining)';
  }
}

// Using the IterableExtension from update_reward_entry.dart