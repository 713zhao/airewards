import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../entities/entities.dart';
import '../repositories/repositories.dart';

/// Parameters for updating a reward entry.
/// 
/// This class encapsulates all the required data for updating an existing reward entry
/// and provides comprehensive validation according to business rules.
class UpdateRewardEntryParams {
  final String entryId;
  final String userId;
  final int? points;
  final String? description;
  final String? categoryId;
  final RewardType? type;

  const UpdateRewardEntryParams({
    required this.entryId,
    required this.userId,
    this.points,
    this.description,
    this.categoryId,
    this.type,
  });

  /// Create validated params with business rule validation.
  /// 
  /// Validates according to:
  /// - BR-001: Minimum point entry value: 1 point
  /// - BR-002: Maximum point entry value: 10,000 points per transaction
  /// - BR-003: Points cannot be negative (except for ADJUSTED type)
  /// - BR-011: Each reward entry must have a category
  /// 
  /// Returns [Either<ValidationFailure, UpdateRewardEntryParams>]:
  /// - Left: [ValidationFailure] if validation fails
  /// - Right: [UpdateRewardEntryParams] if validation succeeds
  static Either<ValidationFailure, UpdateRewardEntryParams> create({
    required String entryId,
    required String userId,
    int? points,
    String? description,
    String? categoryId,
    RewardType? type,
  }) {
    // Validate entry ID
    if (entryId.trim().isEmpty) {
      return Either.left(ValidationFailure('Entry ID cannot be empty'));
    }

    // Validate user ID
    if (userId.trim().isEmpty) {
      return Either.left(ValidationFailure('User ID cannot be empty'));
    }

    // Validate points if provided
    if (points != null) {
      final pointsValidation = _validatePoints(points, type);
      if (pointsValidation.isLeft) {
        return Either.left(pointsValidation.left);
      }
    }

    // Validate description if provided
    if (description != null) {
      if (description.trim().isEmpty) {
        return Either.left(ValidationFailure('Description cannot be empty when provided'));
      }
      if (description.length > 500) {
        return Either.left(ValidationFailure('Description cannot exceed 500 characters'));
      }
    }

    // Validate category ID if provided
    if (categoryId != null && categoryId.trim().isEmpty) {
      return Either.left(ValidationFailure('Category ID cannot be empty when provided'));
    }

    // At least one field must be updated
    if (points == null && description == null && categoryId == null && type == null) {
      return Either.left(ValidationFailure('At least one field must be updated'));
    }

    return Either.right(UpdateRewardEntryParams(
      entryId: entryId.trim(),
      userId: userId.trim(),
      points: points,
      description: description?.trim(),
      categoryId: categoryId?.trim(),
      type: type,
    ));
  }

  /// Validates points according to business rules BR-001, BR-002, BR-003
  static Either<ValidationFailure, int> _validatePoints(int points, RewardType? type) {
    // We need the type to validate negative points, but it might not be provided
    // If type is not provided, we'll be more lenient (assume it might be adjusted)
    
    // BR-002: Maximum point entry value: 10,000 points per transaction
    if (points.abs() > 10000) {
      return Either.left(ValidationFailure('Maximum point entry value is 10,000 points per transaction (BR-002)'));
    }

    // BR-001: Minimum point entry value: 1 point (for positive entries)
    if (points > 0 && points < 1) {
      return Either.left(ValidationFailure('Minimum point entry value is 1 point (BR-001)'));
    }

    // BR-003: Points cannot be negative (except for ADJUSTED type)
    if (points < 0 && type != null && type != RewardType.adjusted) {
      return Either.left(ValidationFailure('Points cannot be negative except for adjusted entries (BR-003)'));
    }

    return Either.right(points);
  }

  @override
  String toString() {
    return 'UpdateRewardEntryParams(entryId: $entryId, userId: $userId, '
           'points: $points, description: $description, categoryId: $categoryId, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpdateRewardEntryParams &&
        other.entryId == entryId &&
        other.userId == userId &&
        other.points == points &&
        other.description == description &&
        other.categoryId == categoryId &&
        other.type == type;
  }

  @override
  int get hashCode {
    return entryId.hashCode ^
        userId.hashCode ^
        points.hashCode ^
        description.hashCode ^
        categoryId.hashCode ^
        type.hashCode;
  }
}

/// Use case for updating an existing reward entry.
/// 
/// This use case handles the complete business logic for modifying reward entries,
/// including validation, business rule enforcement, and error handling.
/// It follows the single responsibility principle by focusing solely on
/// reward entry modification functionality.
/// 
/// Business rules enforced:
/// - BR-004: Point history cannot be modified after 24 hours
/// - BR-001: Minimum point entry value: 1 point
/// - BR-002: Maximum point entry value: 10,000 points per transaction
/// - BR-003: Points cannot be negative (except for ADJUSTED type)
/// - BR-011: Each reward entry must have a category
/// - US-005: Allow editing of reward points within 24 hours of creation
/// 
/// Additional validations:
/// - User ownership verification
/// - Entry existence validation
/// - Category existence validation (if changed)
/// - Partial update support (only specified fields are updated)
class UpdateRewardEntry implements UseCase<RewardEntry, UpdateRewardEntryParams> {
  final RewardRepository repository;

  /// Creates a new [UpdateRewardEntry] use case.
  /// 
  /// Parameters:
  /// - [repository]: The reward repository for data operations
  const UpdateRewardEntry(this.repository);

  /// Execute the reward entry update process.
  /// 
  /// This method orchestrates the reward update flow and handles
  /// all business logic related to modifying reward entries.
  /// 
  /// Parameters:
  /// - [params]: Contains entry ID and fields to update
  /// 
  /// Returns [Either<Failure, RewardEntry>]:
  /// - Left: [Failure] if update fails
  /// - Right: [RewardEntry] object if update succeeds
  /// 
  /// Possible failures:
  /// - [ValidationFailure] for business rule violations
  /// - [ValidationFailure] for entries older than 24 hours (BR-004)
  /// - [ValidationFailure] if entry doesn't exist
  /// - [AuthFailure] for user authorization issues
  /// - [NetworkFailure] for network connectivity issues
  /// 
  /// Business logic handled:
  /// 1. Validates entry exists and user owns it
  /// 2. Enforces 24-hour edit window (BR-004)
  /// 3. Validates new values against business rules
  /// 4. Updates only specified fields (partial update)
  /// 5. Maintains audit trail with update timestamps
  @override
  Future<Either<Failure, RewardEntry>> call(UpdateRewardEntryParams params) async {
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

      // Step 3: Validate category exists if being changed
      if (params.categoryId != null) {
        final categoryValidation = await _validateCategory(params.categoryId!);
        if (categoryValidation.isLeft) {
          return Either.left(categoryValidation.left);
        }
      }

      // Step 4: Create updated entry with new values
      final updatedEntry = _createUpdatedEntry(existingEntry, params);

      // Step 5: Validate the complete updated entry
      final entryValidation = _validateUpdatedEntry(updatedEntry);
      if (entryValidation.isLeft) {
        return Either.left(entryValidation.left);
      }

      // Step 6: Persist the updated entry through repository
      final result = await repository.updateRewardEntry(updatedEntry);

      return result.fold(
        // Handle update failure
        (failure) async {
          await _logFailedUpdate(params, failure);
          return Either.left(failure);
        },
        // Handle update success
        (updatedEntry) async {
          // Step 7: Log successful update for audit trail
          await _logSuccessfulUpdate(existingEntry, updatedEntry);
          
          // Note: In a more complex implementation, you might:
          // - Send notifications about the change
          // - Update related analytics or statistics
          // - Sync changes with external systems
          // - Update cached totals
          // - Track update frequency for user behavior analysis
          
          return Either.right(updatedEntry);
        },
      );
    } catch (e) {
      // Handle unexpected errors
      return Either.left(ValidationFailure('Unexpected error during reward entry update: $e'));
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
          return Either.left(ValidationFailure('Reward entry not found or you do not have permission to update it'));
        }
        
        // Verify user ownership (additional security check)
        if (entry.userId != userId) {
          return Either.left(AuthFailure('You do not have permission to update this reward entry'));
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

  /// Validates that the specified category exists and is accessible to the user.
  Future<Either<Failure, RewardCategory>> _validateCategory(String categoryId) async {
    final categoriesResult = await repository.getRewardCategories();
    
    return categoriesResult.fold(
      (failure) => Either.left(failure),
      (categories) {
        final category = categories.where((cat) => cat.id == categoryId).firstOrNull;
        
        if (category == null) {
          return Either.left(ValidationFailure('Category with ID $categoryId not found'));
        }
        
        return Either.right(category);
      },
    );
  }

  /// Creates an updated entry with the new values.
  RewardEntry _createUpdatedEntry(RewardEntry existingEntry, UpdateRewardEntryParams params) {
    return existingEntry.copyWith(
      points: params.points,
      description: params.description,
      categoryId: params.categoryId,
      type: params.type,
      // updatedAt and isSynced are handled automatically by copyWith
    );
  }

  /// Validates the complete updated entry for business rule compliance.
  Either<ValidationFailure, bool> _validateUpdatedEntry(RewardEntry entry) {
    // Additional validation that might depend on the complete entry
    // Most validation is already done by RewardEntry.create and copyWith
    
    if (entry.points == 0) {
      return Either.left(ValidationFailure('Point entries cannot have zero value'));
    }

    return Either.right(true);
  }

  /// Checks if an entry can be modified by a user.
  /// 
  /// This method can be used by the presentation layer to determine
  /// whether to show edit controls for an entry.
  /// 
  /// Parameters:
  /// - [entryId]: ID of the entry to check
  /// - [userId]: User requesting the modification
  /// 
  /// Returns [Either<Failure, bool>]:
  /// - Left: [Failure] if check fails
  /// - Right: true if entry can be modified
  Future<Either<Failure, bool>> canModifyEntry({
    required String entryId,
    required String userId,
  }) async {
    final entryResult = await _getExistingEntry(entryId, userId);
    
    return entryResult.fold(
      (failure) => Either.left(failure),
      (entry) {
        final canModify = entry.canBeModified();
        return Either.right(canModify);
      },
    );
  }

  /// Gets the time remaining in the edit window for an entry.
  /// 
  /// This method provides information about how much time is left
  /// for editing an entry before the 24-hour window expires.
  /// 
  /// Parameters:
  /// - [entryId]: ID of the entry to check
  /// - [userId]: User requesting the information
  /// 
  /// Returns [Either<Failure, Duration?>]:
  /// - Left: [Failure] if check fails
  /// - Right: [Duration] remaining, or null if window has expired
  Future<Either<Failure, Duration?>> getEditTimeRemaining({
    required String entryId,
    required String userId,
  }) async {
    final entryResult = await _getExistingEntry(entryId, userId);
    
    return entryResult.fold(
      (failure) => Either.left(failure),
      (entry) {
        final now = DateTime.now();
        final createdAt = entry.createdAt;
        final windowEnd = createdAt.add(const Duration(hours: 24));
        
        if (now.isAfter(windowEnd)) {
          return Either.right(null); // Window has expired
        }
        
        final remaining = windowEnd.difference(now);
        return Either.right(remaining);
      },
    );
  }

  /// Validates update parameters.
  /// 
  /// This method can be used by the presentation layer for early validation
  /// before making the actual repository request.
  Future<Either<ValidationFailure, bool>> validateUpdateParams({
    required String entryId,
    required String userId,
    int? points,
    String? description,
    String? categoryId,
    RewardType? type,
  }) async {
    final paramsResult = UpdateRewardEntryParams.create(
      entryId: entryId,
      userId: userId,
      points: points,
      description: description,
      categoryId: categoryId,
      type: type,
    );

    return paramsResult.fold(
      (failure) => Either.left(failure),
      (_) => Either.right(true),
    );
  }

  /// Log failed reward entry update for audit trail.
  Future<void> _logFailedUpdate(UpdateRewardEntryParams params, Failure failure) async {
    // In a real implementation, this would:
    // - Log to audit system
    // - Track failed update attempts
    // - Monitor for suspicious activity
    // - Send alerts for repeated failures
    
    // For now, this is a placeholder
    // print('Failed reward entry update for entry ${params.entryId} by user ${params.userId}: $failure');
  }

  /// Log successful reward entry update for audit trail.
  Future<void> _logSuccessfulUpdate(RewardEntry originalEntry, RewardEntry updatedEntry) async {
    // In a real implementation, this would:
    // - Log detailed change history to audit system
    // - Track what fields were changed
    // - Update user activity metrics
    // - Send notifications if configured
    
    // For now, this is a placeholder
    // print('Successful reward entry update: ${updatedEntry.id} for user ${updatedEntry.userId}');
  }
}

/// Extension to add firstOrNull functionality for Dart versions that don't have it
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}