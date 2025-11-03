import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../repositories/repositories.dart';

/// Parameters for validating a redemption request.
/// 
/// This class encapsulates the data needed to validate whether a user
/// can perform a specific redemption operation.
class ValidateRedemptionParams {
  final String userId;
  final int pointsToRedeem;
  final String? optionId;

  const ValidateRedemptionParams({
    required this.userId,
    required this.pointsToRedeem,
    this.optionId,
  });

  /// Create validated params with business rule validation.
  /// 
  /// Validates parameters according to:
  /// - BR-008: Minimum redemption value: 100 points
  /// - User ID validation
  /// - Points validation (positive number)
  /// 
  /// Returns [Either<ValidationFailure, ValidateRedemptionParams>]:
  /// - Left: [ValidationFailure] if validation fails
  /// - Right: Valid parameters
  static Either<ValidationFailure, ValidateRedemptionParams> create({
    required String userId,
    required int pointsToRedeem,
    String? optionId,
  }) {
    // Validate user ID
    if (userId.isEmpty) {
      return Either.left(ValidationFailure('User ID cannot be empty'));
    }

    // Validate points - BR-008: Minimum redemption value: 100 points
    if (pointsToRedeem < 100) {
      return Either.left(ValidationFailure('Minimum redemption value is 100 points'));
    }

    if (pointsToRedeem <= 0) {
      return Either.left(ValidationFailure('Points to redeem must be positive'));
    }

    return Either.right(ValidateRedemptionParams(
      userId: userId,
      pointsToRedeem: pointsToRedeem,
      optionId: optionId,
    ));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ValidateRedemptionParams &&
           other.userId == userId &&
           other.pointsToRedeem == pointsToRedeem &&
           other.optionId == optionId;
  }

  @override
  int get hashCode => Object.hash(userId, pointsToRedeem, optionId);

  @override
  String toString() {
    return 'ValidateRedemptionParams(userId: $userId, pointsToRedeem: $pointsToRedeem, optionId: $optionId)';
  }
}

/// Use case for validating whether a user can redeem points.
/// 
/// This use case checks if a user has sufficient points and meets
/// all business rule requirements for a redemption operation.
/// 
/// Business Rules Enforced:
/// - BR-006: Users cannot redeem more points than available balance
/// - BR-008: Minimum redemption value: 100 points
/// 
/// Usage:
/// ```dart
/// final result = await validateRedemption(ValidateRedemptionParams(
///   userId: 'user123',
///   pointsToRedeem: 500,
/// ));
/// 
/// result.fold(
///   (failure) => print('Validation failed: $failure'),
///   (canRedeem) => print('Can redeem: $canRedeem'),
/// );
/// ```
class ValidateRedemption implements UseCase<bool, ValidateRedemptionParams> {
  final RedemptionRepository _repository;

  const ValidateRedemption(this._repository);

  @override
  Future<Either<Failure, bool>> call(ValidateRedemptionParams params) async {
    try {
      // Validate parameters first
      final validationResult = ValidateRedemptionParams.create(
        userId: params.userId,
        pointsToRedeem: params.pointsToRedeem,
        optionId: params.optionId,
      );

      if (validationResult.isLeft) {
        return Either.left(validationResult.left);
      }

      // Use repository's canRedeem method which handles business logic
      final canRedeemResult = await _repository.canRedeem(
        params.userId,
        params.pointsToRedeem,
      );

      return canRedeemResult.fold(
        (failure) => Either.left(failure),
        (canRedeem) => Either.right(canRedeem),
      );
    } catch (e) {
      return Either.left(
        ValidationFailure('Unexpected error during redemption validation: ${e.toString()}'),
      );
    }
  }

  /// Validates redemption with detailed feedback.
  /// 
  /// This method provides more detailed information about why
  /// a redemption might fail, useful for user feedback.
  /// 
  /// Returns a map with validation details:
  /// - 'canRedeem': bool - Whether redemption is possible
  /// - 'availablePoints': int - User's current point balance
  /// - 'requiredPoints': int - Points needed for redemption
  /// - 'violations': List<String> - List of business rule violations
  Future<Either<Failure, Map<String, dynamic>>> validateWithDetails(
    ValidateRedemptionParams params,
  ) async {
    try {
      // Get user's available points
      final pointsResult = await _repository.getAvailablePoints(params.userId);
      
      if (pointsResult.isLeft) {
        return Either.left(pointsResult.left);
      }

      final availablePoints = pointsResult.right;
      final violations = <String>[];

      // Check business rules
      if (params.pointsToRedeem < 100) {
        violations.add('Minimum redemption value is 100 points');
      }

      if (availablePoints < params.pointsToRedeem) {
        violations.add('Insufficient points: need ${params.pointsToRedeem}, have $availablePoints');
      }

      // If specific option is provided, validate it exists
      if (params.optionId != null) {
        final optionsResult = await _repository.getRedemptionOptions();
        if (optionsResult.isRight) {
          final options = optionsResult.right;
          final optionExists = options.any((option) => option.id == params.optionId);
          if (!optionExists) {
            violations.add('Redemption option not found or not available');
          }
        }
      }

      final canRedeem = violations.isEmpty;

      return Either.right({
        'canRedeem': canRedeem,
        'availablePoints': availablePoints,
        'requiredPoints': params.pointsToRedeem,
        'violations': violations,
      });
    } catch (e) {
      return Either.left(
        ValidationFailure('Error validating redemption details: ${e.toString()}'),
      );
    }
  }
}