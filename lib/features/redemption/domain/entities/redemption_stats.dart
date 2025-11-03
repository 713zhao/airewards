/// Statistics about user's redemption activity
/// 
/// This entity provides comprehensive analytics about a user's
/// redemption behavior, including transaction counts, success rates,
/// and temporal patterns.
class RedemptionStats {
  final int totalTransactions;
  final int completedTransactions;
  final int cancelledTransactions;
  final int totalPointsRedeemed;
  final DateTime? firstRedemptionDate;
  final DateTime? lastRedemptionDate;
  final String? favoriteCategory;

  const RedemptionStats({
    required this.totalTransactions,
    required this.completedTransactions,
    required this.cancelledTransactions,
    required this.totalPointsRedeemed,
    this.firstRedemptionDate,
    this.lastRedemptionDate,
    this.favoriteCategory,
  });

  /// Success rate as a percentage (0-100)
  double get successRate {
    if (totalTransactions == 0) return 0.0;
    return (completedTransactions / totalTransactions) * 100;
  }

  /// Average points per completed redemption
  double get averagePointsPerRedemption {
    if (completedTransactions == 0) return 0.0;
    return totalPointsRedeemed / completedTransactions;
  }

  /// Pending transactions count (calculated)
  int get pendingTransactions {
    return totalTransactions - completedTransactions - cancelledTransactions;
  }

  /// Whether user has any redemption activity
  bool get hasActivity => totalTransactions > 0;

  /// Days between first and last redemption
  int get activitySpanDays {
    if (firstRedemptionDate == null || lastRedemptionDate == null) return 0;
    return lastRedemptionDate!.difference(firstRedemptionDate!).inDays;
  }

  /// Create a copy with updated values
  RedemptionStats copyWith({
    int? totalTransactions,
    int? completedTransactions,
    int? cancelledTransactions,
    int? totalPointsRedeemed,
    DateTime? firstRedemptionDate,
    DateTime? lastRedemptionDate,
    String? favoriteCategory,
  }) {
    return RedemptionStats(
      totalTransactions: totalTransactions ?? this.totalTransactions,
      completedTransactions: completedTransactions ?? this.completedTransactions,
      cancelledTransactions: cancelledTransactions ?? this.cancelledTransactions,
      totalPointsRedeemed: totalPointsRedeemed ?? this.totalPointsRedeemed,
      firstRedemptionDate: firstRedemptionDate ?? this.firstRedemptionDate,
      lastRedemptionDate: lastRedemptionDate ?? this.lastRedemptionDate,
      favoriteCategory: favoriteCategory ?? this.favoriteCategory,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RedemptionStats &&
           other.totalTransactions == totalTransactions &&
           other.completedTransactions == completedTransactions &&
           other.cancelledTransactions == cancelledTransactions &&
           other.totalPointsRedeemed == totalPointsRedeemed &&
           other.firstRedemptionDate == firstRedemptionDate &&
           other.lastRedemptionDate == lastRedemptionDate &&
           other.favoriteCategory == favoriteCategory;
  }

  @override
  int get hashCode => Object.hash(
        totalTransactions,
        completedTransactions,
        cancelledTransactions,
        totalPointsRedeemed,
        firstRedemptionDate,
        lastRedemptionDate,
        favoriteCategory,
      );

  @override
  String toString() {
    return 'RedemptionStats{totalTransactions: $totalTransactions, '
           'completedTransactions: $completedTransactions, '
           'totalPointsRedeemed: $totalPointsRedeemed, '
           'successRate: ${successRate.toStringAsFixed(1)}%}';
  }
}