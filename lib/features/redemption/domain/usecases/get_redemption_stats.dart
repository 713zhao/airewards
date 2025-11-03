import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../entities/entities.dart';
import '../repositories/repositories.dart';

/// Parameters for getting redemption statistics.
/// 
/// This class encapsulates filtering options for retrieving
/// user's redemption statistics and analytics data.
class GetRedemptionStatsParams {
  final String userId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool includeProjections;

  const GetRedemptionStatsParams({
    required this.userId,
    this.startDate,
    this.endDate,
    this.includeProjections = false,
  });

  /// Create validated params with business rule validation.
  /// 
  /// Validates date ranges and user identification.
  /// 
  /// Returns [Either<ValidationFailure, GetRedemptionStatsParams>]:
  /// - Left: [ValidationFailure] if validation fails
  /// - Right: Valid parameters
  static Either<ValidationFailure, GetRedemptionStatsParams> create({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    bool includeProjections = false,
  }) {
    // Validate user ID
    if (userId.isEmpty) {
      return Either.left(ValidationFailure('User ID cannot be empty'));
    }

    // Validate date range
    if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
      return Either.left(ValidationFailure('Start date must be before end date'));
    }

    // Validate dates are not in the future
    final now = DateTime.now();
    if (startDate != null && startDate.isAfter(now)) {
      return Either.left(ValidationFailure('Start date cannot be in the future'));
    }

    if (endDate != null && endDate.isAfter(now)) {
      return Either.left(ValidationFailure('End date cannot be in the future'));
    }

    return Either.right(GetRedemptionStatsParams(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      includeProjections: includeProjections,
    ));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetRedemptionStatsParams &&
           other.userId == userId &&
           other.startDate == startDate &&
           other.endDate == endDate &&
           other.includeProjections == includeProjections;
  }

  @override
  int get hashCode => Object.hash(userId, startDate, endDate, includeProjections);

  @override
  String toString() {
    return 'GetRedemptionStatsParams(userId: $userId, startDate: $startDate, endDate: $endDate, includeProjections: $includeProjections)';
  }
}

/// Use case for retrieving user's redemption statistics and analytics.
/// 
/// This use case provides comprehensive statistics about a user's
/// redemption activity, including totals, trends, and preferences.
/// 
/// Usage:
/// ```dart
/// final result = await getRedemptionStats(GetRedemptionStatsParams(
///   userId: 'user123',
///   startDate: DateTime(2023, 1, 1),
///   endDate: DateTime(2023, 12, 31),
/// ));
/// 
/// result.fold(
///   (failure) => print('Error: $failure'),
///   (stats) => print('Total redemptions: ${stats.totalTransactions}'),
/// );
/// ```
class GetRedemptionStats implements UseCase<RedemptionStats, GetRedemptionStatsParams> {
  final RedemptionRepository _repository;

  const GetRedemptionStats(this._repository);

  @override
  Future<Either<Failure, RedemptionStats>> call(GetRedemptionStatsParams params) async {
    try {
      // Validate parameters first
      final validationResult = GetRedemptionStatsParams.create(
        userId: params.userId,
        startDate: params.startDate,
        endDate: params.endDate,
        includeProjections: params.includeProjections,
      );

      if (validationResult.isLeft) {
        return Either.left(validationResult.left);
      }

      // Get statistics from repository
      final statsResult = await _repository.getRedemptionStats(
        userId: params.userId,
        startDate: params.startDate,
        endDate: params.endDate,
      );

      return statsResult.fold(
        (failure) => Either.left(failure),
        (stats) => Either.right(stats),
      );
    } catch (e) {
      return Either.left(
        CacheFailure('Unexpected error getting redemption statistics: ${e.toString()}'),
      );
    }
  }

  /// Gets redemption statistics with enhanced analytics.
  /// 
  /// This method provides additional calculated metrics beyond
  /// the basic statistics, useful for detailed analytics screens.
  /// 
  /// Returns a map with enhanced statistics:
  /// - Basic stats from RedemptionStats entity
  /// - 'averageRedemptionValue': double - Average points per redemption
  /// - 'redemptionFrequency': String - How often user redeems (daily, weekly, etc.)
  /// - 'preferredTimeframe': String - When user typically redeems
  /// - 'efficiencyScore': double - How efficiently user redeems points
  Future<Either<Failure, Map<String, dynamic>>> getEnhancedStats(
    GetRedemptionStatsParams params,
  ) async {
    try {
      final statsResult = await call(params);
      
      if (statsResult.isLeft) {
        return Either.left(statsResult.left);
      }

      final stats = statsResult.right;

      // Calculate enhanced metrics
      final averageRedemptionValue = stats.totalTransactions > 0
          ? stats.totalPointsRedeemed / stats.totalTransactions.toDouble()
          : 0.0;

      // Calculate redemption frequency
      String redemptionFrequency = 'Unknown';
      if (stats.firstRedemptionDate != null && stats.lastRedemptionDate != null) {
        final daysBetween = stats.lastRedemptionDate!
            .difference(stats.firstRedemptionDate!)
            .inDays;
        
        if (daysBetween > 0 && stats.totalTransactions > 1) {
          final averageDaysBetweenRedemptions = daysBetween / (stats.totalTransactions - 1);
          
          if (averageDaysBetweenRedemptions <= 1) {
            redemptionFrequency = 'Daily';
          } else if (averageDaysBetweenRedemptions <= 7) {
            redemptionFrequency = 'Weekly';
          } else if (averageDaysBetweenRedemptions <= 30) {
            redemptionFrequency = 'Monthly';
          } else {
            redemptionFrequency = 'Occasional';
          }
        }
      }

      // Calculate efficiency score (completed vs total redemptions)
      final efficiencyScore = stats.totalTransactions > 0
          ? stats.completedTransactions / stats.totalTransactions.toDouble()
          : 0.0;

      return Either.right({
        'totalTransactions': stats.totalTransactions,
        'completedTransactions': stats.completedTransactions,
        'cancelledTransactions': stats.cancelledTransactions,
        'totalPointsRedeemed': stats.totalPointsRedeemed,
        'firstRedemptionDate': stats.firstRedemptionDate,
        'lastRedemptionDate': stats.lastRedemptionDate,
        'favoriteCategory': stats.favoriteCategory,
        'averageRedemptionValue': averageRedemptionValue,
        'redemptionFrequency': redemptionFrequency,
        'efficiencyScore': efficiencyScore,
      });
    } catch (e) {
      return Either.left(
        CacheFailure('Error calculating enhanced statistics: ${e.toString()}'),
      );
    }
  }

  /// Gets quick summary statistics for dashboard display.
  /// 
  /// Returns essential stats in a format optimized for quick loading
  /// and dashboard widgets.
  Future<Either<Failure, Map<String, dynamic>>> getQuickSummary(
    GetRedemptionStatsParams params,
  ) async {
    try {
      final statsResult = await call(params);
      
      if (statsResult.isLeft) {
        return Either.left(statsResult.left);
      }

      final stats = statsResult.right;

      return Either.right({
        'totalRedemptions': stats.totalTransactions,
        'totalPointsSpent': stats.totalPointsRedeemed,
        'successRate': stats.totalTransactions > 0
            ? (stats.completedTransactions / stats.totalTransactions.toDouble() * 100).round()
            : 0,
        'favoriteCategory': stats.favoriteCategory ?? 'None',
        'hasActivity': stats.totalTransactions > 0,
      });
    } catch (e) {
      return Either.left(
        CacheFailure('Error getting quick summary: ${e.toString()}'),
      );
    }
  }
}