import 'package:equatable/equatable.dart';

/// Comprehensive analytics data model for kid-friendly reward tracking
class AnalyticsData extends Equatable {
  final OverviewData overview;
  final ProgressData progress;
  final List<Goal> goals;
  final List<Achievement> achievements;
  final TrendData trends;
  final DateTime lastUpdated;

  const AnalyticsData({
    required this.overview,
    required this.progress,
    required this.goals,
    required this.achievements,
    required this.trends,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [
        overview,
        progress,
        goals,
        achievements,
        trends,
        lastUpdated,
      ];

  AnalyticsData copyWith({
    OverviewData? overview,
    ProgressData? progress,
    List<Goal>? goals,
    List<Achievement>? achievements,
    TrendData? trends,
    DateTime? lastUpdated,
  }) {
    return AnalyticsData(
      overview: overview ?? this.overview,
      progress: progress ?? this.progress,
      goals: goals ?? this.goals,
      achievements: achievements ?? this.achievements,
      trends: trends ?? this.trends,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Overview statistics for the analytics dashboard
class OverviewData extends Equatable {
  final int totalPoints;
  final int currentStreak;
  final int longestStreak;
  final int totalRewards;
  final int completedGoals;
  final int activeGoals;
  final double averagePointsPerDay;
  final Map<String, int> categoryBreakdown;
  final List<RecentActivity> recentActivities;

  const OverviewData({
    required this.totalPoints,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalRewards,
    required this.completedGoals,
    required this.activeGoals,
    required this.averagePointsPerDay,
    required this.categoryBreakdown,
    required this.recentActivities,
  });

  @override
  List<Object?> get props => [
        totalPoints,
        currentStreak,
        longestStreak,
        totalRewards,
        completedGoals,
        activeGoals,
        averagePointsPerDay,
        categoryBreakdown,
        recentActivities,
      ];
}

/// Progress tracking data for charts and insights
class ProgressData extends Equatable {
  final List<DailyProgress> dailyProgress;
  final List<WeeklyProgress> weeklyProgress;
  final List<MonthlyProgress> monthlyProgress;
  final Map<String, List<CategoryProgress>> categoryProgress;
  final StreakAnalysis streakAnalysis;
  final List<TrendInsight> insights;

  const ProgressData({
    required this.dailyProgress,
    required this.weeklyProgress,
    required this.monthlyProgress,
    required this.categoryProgress,
    required this.streakAnalysis,
    required this.insights,
  });

  @override
  List<Object?> get props => [
        dailyProgress,
        weeklyProgress,
        monthlyProgress,
        categoryProgress,
        streakAnalysis,
        insights,
      ];
}

/// User goal entity for tracking objectives
class Goal extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String description;
  final int targetValue;
  final int currentValue;
  final GoalType type;
  final String category;
  final DateTime createdAt;
  final DateTime? targetDate;
  final DateTime? completedAt;
  final bool isActive;
  final int priority;
  final String color;
  final String icon;

  const Goal({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.currentValue,
    required this.type,
    required this.category,
    required this.createdAt,
    this.targetDate,
    this.completedAt,
    this.isActive = true,
    this.priority = 1,
    this.color = '#FF6B6B',
    this.icon = 'star',
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        targetValue,
        currentValue,
        type,
        category,
        createdAt,
        targetDate,
        completedAt,
        isActive,
        priority,
        color,
        icon,
      ];

  /// Calculate progress percentage
  double get progressPercentage {
    if (targetValue <= 0) return 0.0;
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  /// Check if goal is completed
  bool get isCompleted => currentValue >= targetValue;

  /// Check if goal is overdue
  bool get isOverdue {
    if (targetDate == null || isCompleted) return false;
    return DateTime.now().isAfter(targetDate!);
  }

  /// Get days remaining until target date
  int? get daysRemaining {
    if (targetDate == null) return null;
    return targetDate!.difference(DateTime.now()).inDays;
  }

  Goal copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    int? targetValue,
    int? currentValue,
    GoalType? type,
    String? category,
    DateTime? createdAt,
    DateTime? targetDate,
    DateTime? completedAt,
    bool? isActive,
    int? priority,
    String? color,
    String? icon,
  }) {
    return Goal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      type: type ?? this.type,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      targetDate: targetDate ?? this.targetDate,
      completedAt: completedAt ?? this.completedAt,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }
}

/// Achievement entity for recognizing milestones
class Achievement extends Equatable {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String color;
  final AchievementTier tier;
  final int pointsRequired;
  final DateTime earnedAt;
  final Map<String, dynamic> metadata;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.tier,
    required this.pointsRequired,
    required this.earnedAt,
    this.metadata = const {},
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        icon,
        color,
        tier,
        pointsRequired,
        earnedAt,
        metadata,
      ];
}

/// Trend analysis data for insights
class TrendData extends Equatable {
  final List<TrendPoint> pointsTrend;
  final List<TrendPoint> activityTrend;
  final List<TrendPoint> categoryTrend;
  final TrendDirection overallDirection;
  final double trendStrength;
  final List<String> insights;
  final Map<String, TrendPrediction> predictions;

  const TrendData({
    required this.pointsTrend,
    required this.activityTrend,
    required this.categoryTrend,
    required this.overallDirection,
    required this.trendStrength,
    required this.insights,
    required this.predictions,
  });

  @override
  List<Object?> get props => [
        pointsTrend,
        activityTrend,
        categoryTrend,
        overallDirection,
        trendStrength,
        insights,
        predictions,
      ];
}

/// Supporting classes for analytics data

class RecentActivity extends Equatable {
  final String id;
  final String type;
  final String description;
  final int points;
  final DateTime timestamp;
  final String category;
  final String icon;

  const RecentActivity({
    required this.id,
    required this.type,
    required this.description,
    required this.points,
    required this.timestamp,
    required this.category,
    required this.icon,
  });

  @override
  List<Object?> get props => [id, type, description, points, timestamp, category, icon];
}

class DailyProgress extends Equatable {
  final DateTime date;
  final int points;
  final int activities;
  final bool hasStreak;

  const DailyProgress({
    required this.date,
    required this.points,
    required this.activities,
    required this.hasStreak,
  });

  @override
  List<Object?> get props => [date, points, activities, hasStreak];
}

class WeeklyProgress extends Equatable {
  final DateTime weekStart;
  final int totalPoints;
  final int totalActivities;
  final int streakDays;
  final double averageDaily;

  const WeeklyProgress({
    required this.weekStart,
    required this.totalPoints,
    required this.totalActivities,
    required this.streakDays,
    required this.averageDaily,
  });

  @override
  List<Object?> get props => [weekStart, totalPoints, totalActivities, streakDays, averageDaily];
}

class MonthlyProgress extends Equatable {
  final DateTime month;
  final int totalPoints;
  final int totalActivities;
  final int completedGoals;
  final int newAchievements;

  const MonthlyProgress({
    required this.month,
    required this.totalPoints,
    required this.totalActivities,
    required this.completedGoals,
    required this.newAchievements,
  });

  @override
  List<Object?> get props => [month, totalPoints, totalActivities, completedGoals, newAchievements];
}

class CategoryProgress extends Equatable {
  final String category;
  final int points;
  final int count;
  final double percentage;

  const CategoryProgress({
    required this.category,
    required this.points,
    required this.count,
    required this.percentage,
  });

  @override
  List<Object?> get props => [category, points, count, percentage];
}

class StreakAnalysis extends Equatable {
  final int currentStreak;
  final int longestStreak;
  final List<StreakPeriod> streakHistory;
  final double streakConsistency;
  final List<DateTime> streakBreaks;

  const StreakAnalysis({
    required this.currentStreak,
    required this.longestStreak,
    required this.streakHistory,
    required this.streakConsistency,
    required this.streakBreaks,
  });

  @override
  List<Object?> get props => [currentStreak, longestStreak, streakHistory, streakConsistency, streakBreaks];
}

class StreakPeriod extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final int days;

  const StreakPeriod({
    required this.startDate,
    required this.endDate,
    required this.days,
  });

  @override
  List<Object?> get props => [startDate, endDate, days];
}

class TrendInsight extends Equatable {
  final String message;
  final TrendInsightType type;
  final double confidence;
  final Map<String, dynamic> data;

  const TrendInsight({
    required this.message,
    required this.type,
    required this.confidence,
    this.data = const {},
  });

  @override
  List<Object?> get props => [message, type, confidence, data];
}

class TrendPoint extends Equatable {
  final DateTime date;
  final double value;
  final Map<String, dynamic> metadata;

  const TrendPoint({
    required this.date,
    required this.value,
    this.metadata = const {},
  });

  @override
  List<Object?> get props => [date, value, metadata];
}

class TrendPrediction extends Equatable {
  final double predictedValue;
  final double confidence;
  final DateTime targetDate;

  const TrendPrediction({
    required this.predictedValue,
    required this.confidence,
    required this.targetDate,
  });

  @override
  List<Object?> get props => [predictedValue, confidence, targetDate];
}

// Enums for analytics

enum AnalyticsTimeRange {
  day,
  week,
  month,
  quarter,
  year,
  all,
}

enum GoalType {
  points,
  streak,
  activities,
  category,
  custom,
}

enum AchievementTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
}

enum TrendDirection {
  up,
  down,
  stable,
}

enum TrendInsightType {
  positive,
  warning,
  suggestion,
  celebration,
}

enum CelebrationType {
  goalCompleted,
  goalAdded,
  achievementUnlocked,
  streakMilestone,
  milestoneReached,
  perfectWeek,
}

enum AnalyticsFilter {
  all,
  points,
  streaks,
  goals,
  achievements,
  categories,
}

enum AnalyticsExportFormat {
  pdf,
  csv,
  json,
  image,
}

enum AnalyticsImportFormat {
  csv,
  json,
}

// Extension methods for better usability

extension AnalyticsTimeRangeExtension on AnalyticsTimeRange {
  String get displayName {
    switch (this) {
      case AnalyticsTimeRange.day:
        return 'Today';
      case AnalyticsTimeRange.week:
        return 'This Week';
      case AnalyticsTimeRange.month:
        return 'This Month';
      case AnalyticsTimeRange.quarter:
        return 'This Quarter';
      case AnalyticsTimeRange.year:
        return 'This Year';
      case AnalyticsTimeRange.all:
        return 'All Time';
    }
  }

  Duration get duration {
    switch (this) {
      case AnalyticsTimeRange.day:
        return const Duration(days: 1);
      case AnalyticsTimeRange.week:
        return const Duration(days: 7);
      case AnalyticsTimeRange.month:
        return const Duration(days: 30);
      case AnalyticsTimeRange.quarter:
        return const Duration(days: 90);
      case AnalyticsTimeRange.year:
        return const Duration(days: 365);
      case AnalyticsTimeRange.all:
        return const Duration(days: 3650); // 10 years
    }
  }
}

extension GoalTypeExtension on GoalType {
  String get displayName {
    switch (this) {
      case GoalType.points:
        return 'Points Goal';
      case GoalType.streak:
        return 'Streak Goal';
      case GoalType.activities:
        return 'Activities Goal';
      case GoalType.category:
        return 'Category Goal';
      case GoalType.custom:
        return 'Custom Goal';
    }
  }

  String get icon {
    switch (this) {
      case GoalType.points:
        return 'stars';
      case GoalType.streak:
        return 'local_fire_department';
      case GoalType.activities:
        return 'assignment_turned_in';
      case GoalType.category:
        return 'category';
      case GoalType.custom:
        return 'flag';
    }
  }
}

extension AchievementTierExtension on AchievementTier {
  String get displayName {
    switch (this) {
      case AchievementTier.bronze:
        return 'Bronze';
      case AchievementTier.silver:
        return 'Silver';
      case AchievementTier.gold:
        return 'Gold';
      case AchievementTier.platinum:
        return 'Platinum';
      case AchievementTier.diamond:
        return 'Diamond';
    }
  }

  String get color {
    switch (this) {
      case AchievementTier.bronze:
        return '#CD7F32';
      case AchievementTier.silver:
        return '#C0C0C0';
      case AchievementTier.gold:
        return '#FFD700';
      case AchievementTier.platinum:
        return '#E5E4E2';
      case AchievementTier.diamond:
        return '#B9F2FF';
    }
  }
}