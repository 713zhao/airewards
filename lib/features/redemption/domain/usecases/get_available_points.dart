import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../repositories/repositories.dart';

/// Parameters for getting user's available points.
/// 
/// This class encapsulates the user identification for retrieving
/// point balance information.
class GetAvailablePointsParams {
  final String userId;
  final bool includeEarningDetails;

  const GetAvailablePointsParams({
    required this.userId,
    this.includeEarningDetails = false,
  });

  /// Create validated params with user ID validation.
  /// 
  /// Returns [Either<ValidationFailure, GetAvailablePointsParams>]:
  /// - Left: [ValidationFailure] if validation fails
  /// - Right: Valid parameters
  static Either<ValidationFailure, GetAvailablePointsParams> create({
    required String userId,
    bool includeEarningDetails = false,
  }) {
    // Validate user ID
    if (userId.isEmpty) {
      return Either.left(ValidationFailure('User ID cannot be empty'));
    }

    if (userId.length < 3) {
      return Either.left(ValidationFailure('User ID must be at least 3 characters'));
    }

    return Either.right(GetAvailablePointsParams(
      userId: userId,
      includeEarningDetails: includeEarningDetails,
    ));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetAvailablePointsParams &&
           other.userId == userId &&
           other.includeEarningDetails == includeEarningDetails;
  }

  @override
  int get hashCode => Object.hash(userId, includeEarningDetails);

  @override
  String toString() {
    return 'GetAvailablePointsParams(userId: $userId, includeEarningDetails: $includeEarningDetails)';
  }
}

/// Use case for retrieving user's available point balance.
/// 
/// This use case gets the current point balance for a user,
/// which can be used for redemption eligibility checks and display.
/// 
/// Usage:
/// ```dart
/// final result = await getAvailablePoints(GetAvailablePointsParams(
///   userId: 'user123',
/// ));
/// 
/// result.fold(
///   (failure) => print('Error: $failure'),
///   (points) => print('Available points: $points'),
/// );
/// ```
class GetAvailablePoints implements UseCase<int, GetAvailablePointsParams> {
  final RedemptionRepository _repository;

  const GetAvailablePoints(this._repository);

  @override
  Future<Either<Failure, int>> call(GetAvailablePointsParams params) async {
    try {
      // Validate parameters first
      final validationResult = GetAvailablePointsParams.create(
        userId: params.userId,
        includeEarningDetails: params.includeEarningDetails,
      );

      if (validationResult.isLeft) {
        return Either.left(validationResult.left);
      }

      // Get available points from repository
      final pointsResult = await _repository.getAvailablePoints(params.userId);

      return pointsResult.fold(
        (failure) => Either.left(failure),
        (points) => Either.right(points),
      );
    } catch (e) {
      return Either.left(
        CacheFailure('Unexpected error getting available points: ${e.toString()}'),
      );
    }
  }

  /// Gets available points with additional context information.
  /// 
  /// This method provides more detailed information about the user's
  /// point balance, useful for detailed balance screens.
  /// 
  /// Returns a map with point details:
  /// - 'availablePoints': int - Current available balance
  /// - 'canRedeem': bool - Whether user can perform any redemption
  /// - 'minimumRedemption': int - Minimum points needed to redeem (100)
  /// - 'pointsToMinimum': int - Points needed to reach minimum redemption
  Future<Either<Failure, Map<String, dynamic>>> getPointsWithContext(
    GetAvailablePointsParams params,
  ) async {
    try {
      final pointsResult = await call(params);
      
      if (pointsResult.isLeft) {
        return Either.left(pointsResult.left);
      }

      final availablePoints = pointsResult.right;
      const minimumRedemption = 100;
      final canRedeem = availablePoints >= minimumRedemption;
      final pointsToMinimum = canRedeem ? 0 : minimumRedemption - availablePoints;

      return Either.right({
        'availablePoints': availablePoints,
        'canRedeem': canRedeem,
        'minimumRedemption': minimumRedemption,
        'pointsToMinimum': pointsToMinimum,
      });
    } catch (e) {
      return Either.left(
        CacheFailure('Error getting points context: ${e.toString()}'),
      );
    }
  }
}