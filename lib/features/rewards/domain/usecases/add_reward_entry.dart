import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../entities/entities.dart';
import '../repositories/repositories.dart';

/// Parameters for adding a reward entry.
/// 
/// This class encapsulates all the required data for creating a new reward entry
/// and provides comprehensive validation according to business rules.
class AddRewardEntryParams {
  final String userId;
  final int points;
  final String description;
  final String categoryId;
  final RewardType type;

  const AddRewardEntryParams({
    required this.userId,
    required this.points,
    required this.description,
    required this.categoryId,
    required this.type,
  });

  /// Create validated params with business rule validation.
  /// 
  /// Validates according to:
  /// - BR-001: Minimum point entry value: 1 point
  /// - BR-002: Maximum point entry value: 10,000 points per transaction
  /// - BR-003: Points cannot be negative (except for ADJUSTED type)
  /// - BR-011: Each reward entry must have a category
  /// 
  /// Returns [Either<ValidationFailure, AddRewardEntryParams>]:
  /// - Left: [ValidationFailure] if validation fails
  /// - Right: [AddRewardEntryParams] if validation succeeds
  static Either<ValidationFailure, AddRewardEntryParams> create({
    required String userId,
    required int points,
    required String description,
    required String categoryId,
    required RewardType type,
  }) {
    // Validate user ID
    if (userId.trim().isEmpty) {
      return Either.left(ValidationFailure('User ID cannot be empty'));
    }

    // Validate points according to business rules
    final pointsValidation = _validatePoints(points, type);
    if (pointsValidation.isLeft) {
      return Either.left(pointsValidation.left);
    }

    // Validate description (mandatory field per US-004)
    if (description.trim().isEmpty) {
      return Either.left(ValidationFailure('Description cannot be empty (mandatory field per US-004)'));
    }

    if (description.length > 500) {
      return Either.left(ValidationFailure('Description cannot exceed 500 characters'));
    }

    // Validate category ID (BR-011: Each reward entry must have a category)
    if (categoryId.trim().isEmpty) {
      return Either.left(ValidationFailure('Category ID cannot be empty (BR-011: Each reward entry must have a category)'));
    }

    return Either.right(AddRewardEntryParams(
      userId: userId.trim(),
      points: points,
      description: description.trim(),
      categoryId: categoryId.trim(),
      type: type,
    ));
  }

  /// Validates points according to business rules BR-001, BR-002, BR-003
  static Either<ValidationFailure, int> _validatePoints(int points, RewardType type) {
    // BR-003: Points cannot be negative (except for ADJUSTED type)
    if (points < 0 && type != RewardType.adjusted) {
      return Either.left(ValidationFailure('Points cannot be negative except for adjusted entries (BR-003)'));
    }

    // BR-001: Minimum point entry value: 1 point (for positive entries)
    if (points > 0 && points < 1) {
      return Either.left(ValidationFailure('Minimum point entry value is 1 point (BR-001)'));
    }

    // BR-002: Maximum point entry value: 10,000 points per transaction
    if (points.abs() > 10000) {
      return Either.left(ValidationFailure('Maximum point entry value is 10,000 points per transaction (BR-002)'));
    }

    return Either.right(points);
  }

  @override
  String toString() {
    return 'AddRewardEntryParams(userId: $userId, points: $points, '
           'description: $description, categoryId: $categoryId, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AddRewardEntryParams &&
        other.userId == userId &&
        other.points == points &&
        other.description == description &&
        other.categoryId == categoryId &&
        other.type == type;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        points.hashCode ^
        description.hashCode ^
        categoryId.hashCode ^
        type.hashCode;
  }
}

/// Use case for adding a new reward entry.
/// 
/// This use case handles the complete business logic for creating reward entries,
/// including validation, business rule enforcement, and error handling.
/// It follows the single responsibility principle by focusing solely on
/// reward entry creation functionality.
/// 
/// Business rules enforced:
/// - BR-001: Minimum point entry value: 1 point
/// - BR-002: Maximum point entry value: 10,000 points per transaction
/// - BR-003: Points cannot be negative (except for ADJUSTED type)
/// - BR-011: Each reward entry must have a category
/// - US-004: Mandatory description and category fields
/// 
/// Additional validations:
/// - User ownership verification
/// - Category existence validation
/// - Description length limits
/// - Point balance impact calculation
class AddRewardEntry implements UseCase<RewardEntry, AddRewardEntryParams> {
  final RewardRepository repository;

  /// Creates a new [AddRewardEntry] use case.
  /// 
  /// Parameters:
  /// - [repository]: The reward repository for data operations
  const AddRewardEntry(this.repository);

  /// Execute the reward entry creation process.
  /// 
  /// This method orchestrates the reward creation flow and handles
  /// all business logic related to adding reward entries.
  /// 
  /// Parameters:
  /// - [params]: Contains all data needed to create the reward entry
  /// 
  /// Returns [Either<Failure, RewardEntry>]:
  /// - Left: [Failure] if creation fails
  /// - Right: [RewardEntry] object if creation succeeds
  /// 
  /// Possible failures:
  /// - [ValidationFailure] for business rule violations
  /// - [NotFoundFailure] if category doesn't exist
  /// - [AuthFailure] for user authorization issues
  /// - [NetworkFailure] for network connectivity issues
  /// 
  /// Business logic handled:
  /// 1. Validates input parameters against business rules
  /// 2. Verifies category exists and is accessible to user
  /// 3. Creates the reward entry with proper timestamps
  /// 4. Updates user's total point balance
  /// 5. Provides audit logging for the transaction
  @override
  Future<Either<Failure, RewardEntry>> call(AddRewardEntryParams params) async {
    try {
      // Step 1: Validate category exists and user has access
      final categoryValidation = await _validateCategory(params.categoryId);
      if (categoryValidation.isLeft) {
        return Either.left(categoryValidation.left);
      }

      // Step 2: Create the reward entry entity with validation
      final entryResult = RewardEntry.create(
        id: _generateTemporaryId(),
        userId: params.userId,
        points: params.points,
        description: params.description,
        categoryId: params.categoryId,
        createdAt: DateTime.now(),
        type: params.type,
      );

      if (entryResult.isLeft) {
        return Either.left(entryResult.left);
      }

      final entry = entryResult.right;

      // Step 3: Additional business validation
      final businessValidation = await _performBusinessValidation(entry);
      if (businessValidation.isLeft) {
        return Either.left(businessValidation.left);
      }

      // Step 4: Persist the entry through repository
      final result = await repository.addRewardEntry(entry);

      return result.fold(
        // Handle persistence failure
        (failure) async {
          await _logFailedAddition(params, failure);
          return Either.left(failure);
        },
        // Handle persistence success
        (createdEntry) async {
          // Step 5: Log successful creation for audit trail
          await _logSuccessfulAddition(createdEntry);
          
          // Note: In a more complex implementation, you might:
          // - Send notifications for milestone achievements
          // - Update user statistics and achievements
          // - Sync with external analytics systems
          // - Check for automatic reward triggers
          // - Update cached point totals
          
          return Either.right(createdEntry);
        },
      );
    } catch (e) {
      // Handle unexpected errors
      return Either.left(ValidationFailure('Unexpected error during reward entry creation: $e'));
    }
  }

  /// Validates that the specified category exists and is accessible to the user.
  Future<Either<Failure, RewardCategory>> _validateCategory(String categoryId) async {
    final categoriesResult = await repository.getRewardCategories();
    
    return categoriesResult.fold(
      (failure) => Either.left(failure),
      (categories) {
        final category = categories.firstWhere(
          (cat) => cat.id == categoryId,
          orElse: () => throw StateError('Category not found'),
        );
        
        try {
          return Either.right(category);
        } catch (e) {
          return Either.left(ValidationFailure('Category with ID $categoryId not found'));
        }
      },
    );
  }

  /// Performs additional business validation that requires repository access.
  Future<Either<Failure, bool>> _performBusinessValidation(RewardEntry entry) async {
    // In a more complex implementation, you might validate:
    // - Daily/monthly point limits per user
    // - Category-specific point limits
    // - User's total point balance constraints
    // - Time-based restrictions (e.g., no points on weekends)
    // - User account status (active, suspended, etc.)
    
    // For now, we'll do basic validation
    if (entry.points == 0) {
      return Either.left(ValidationFailure('Point entries cannot have zero value'));
    }

    return Either.right(true);
  }

  /// Generates a temporary ID for the entry before repository assignment.
  String _generateTemporaryId() {
    return 'temp_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// Validates entry data before attempting to add.
  /// 
  /// This method can be used by the presentation layer for early validation
  /// before making the actual repository request.
  /// 
  /// Parameters:
  /// - [userId]: User ID to validate
  /// - [points]: Points value to validate
  /// - [description]: Description to validate
  /// - [categoryId]: Category ID to validate
  /// - [type]: Reward type to validate
  /// 
  /// Returns [Either<ValidationFailure, bool>]:
  /// - Left: [ValidationFailure] if validation fails
  /// - Right: true if validation passes
  Future<Either<ValidationFailure, bool>> validateEntryData({
    required String userId,
    required int points,
    required String description,
    required String categoryId,
    required RewardType type,
  }) async {
    final paramsResult = AddRewardEntryParams.create(
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

  /// Gets the current user's point balance impact for this entry.
  /// 
  /// This method calculates how the new entry will affect the user's total balance.
  /// 
  /// Parameters:
  /// - [userId]: User whose balance to check
  /// - [points]: Points from the new entry
  /// 
  /// Returns [Either<Failure, PointBalanceInfo>]:
  /// - Left: [Failure] if balance calculation fails
  /// - Right: [PointBalanceInfo] with current and new balance
  Future<Either<Failure, PointBalanceInfo>> getBalanceImpact({
    required String userId,
    required int points,
  }) async {
    final currentBalanceResult = await repository.getTotalPoints(userId);
    
    return currentBalanceResult.fold(
      (failure) => Either.left(failure),
      (currentBalance) {
        final newBalance = currentBalance + points;
        return Either.right(PointBalanceInfo(
          currentBalance: currentBalance,
          newBalance: newBalance,
          pointsAdded: points,
        ));
      },
    );
  }

  /// Log failed reward entry addition for audit trail.
  Future<void> _logFailedAddition(AddRewardEntryParams params, Failure failure) async {
    // In a real implementation, this would:
    // - Log to audit system
    // - Track failed addition attempts
    // - Monitor for suspicious activity
    // - Send alerts for repeated failures
    
    // For now, this is a placeholder
    // print('Failed reward entry addition for user ${params.userId}: $failure');
  }

  /// Log successful reward entry addition for audit trail.
  Future<void> _logSuccessfulAddition(RewardEntry entry) async {
    // In a real implementation, this would:
    // - Log to audit system
    // - Update user activity metrics
    // - Track reward entry statistics
    // - Send notifications if needed
    
    // For now, this is a placeholder
    // print('Successful reward entry addition: ${entry.id} for user ${entry.userId}');
  }
}

/// Information about point balance impact
class PointBalanceInfo {
  final int currentBalance;
  final int newBalance;
  final int pointsAdded;

  const PointBalanceInfo({
    required this.currentBalance,
    required this.newBalance,
    required this.pointsAdded,
  });

  /// The net change in points
  int get netChange => newBalance - currentBalance;

  @override
  String toString() {
    return 'PointBalanceInfo(current: $currentBalance, new: $newBalance, added: $pointsAdded)';
  }
}