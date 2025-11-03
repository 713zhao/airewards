import 'dart:async';
import 'dart:math' as math;

import '../../domain/entities/analytics_entities.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';

/// Mock data service for analytics with comprehensive kid-friendly data
/// 
/// This service provides realistic mock data for development and testing,
/// including engaging statistics, fun achievements, colorful progress data,
/// and motivational insights designed specifically for children.
class AnalyticsMockDataService {
  static final AnalyticsMockDataService _instance = AnalyticsMockDataService._internal();
  factory AnalyticsMockDataService() => _instance;
  AnalyticsMockDataService._internal();

  final math.Random _random = math.Random();
  
  // Mock data storage
  final Map<String, List<Goal>> _userGoals = {};
  final Map<String, List<Achievement>> _userAchievements = {};
  final Map<String, AnalyticsData> _cachedAnalytics = {};
  
  // Stream controllers for real-time updates
  final Map<String, StreamController<AnalyticsData>> _analyticsStreams = {};

  /// Initialize mock data for a user
  void initializeMockDataForUser(String userId) {
    if (!_userGoals.containsKey(userId)) {
      _userGoals[userId] = _generateMockGoals(userId);
    }
    if (!_userAchievements.containsKey(userId)) {
      _userAchievements[userId] = _generateMockAchievements(userId);
    }
  }

  /// Get comprehensive mock analytics data
  Future<Either<Failure, AnalyticsData>> getAnalyticsData(
    String userId,
    AnalyticsTimeRange timeRange,
  ) async {
    await _simulateNetworkDelay();
    
    initializeMockDataForUser(userId);
    
    try {
      final analyticsData = AnalyticsData(
        overview: _generateMockOverviewData(userId, timeRange),
        progress: _generateMockProgressData(userId, timeRange),
        goals: _userGoals[userId] ?? [],
        achievements: _userAchievements[userId] ?? [],
        trends: _generateMockTrendData(userId, timeRange),
        lastUpdated: DateTime.now(),
      );

      _cachedAnalytics[userId] = analyticsData;
      
      return Right(analyticsData);
    } catch (e) {
      return Left(DatabaseFailure('Failed to generate mock analytics data: $e'));
    }
  }

  /// Get mock overview data with engaging statistics
  Future<Either<Failure, OverviewData>> getOverviewData(
    String userId,
    AnalyticsTimeRange timeRange,
  ) async {
    await _simulateNetworkDelay();
    
    try {
      final overview = _generateMockOverviewData(userId, timeRange);
      return Right(overview);
    } catch (e) {
      return Left(DatabaseFailure('Failed to generate mock overview data: $e'));
    }
  }

  /// Get mock progress data for charts
  Future<Either<Failure, ProgressData>> getProgressData(
    String userId,
    AnalyticsTimeRange timeRange,
  ) async {
    await _simulateNetworkDelay();
    
    try {
      final progress = _generateMockProgressData(userId, timeRange);
      return Right(progress);
    } catch (e) {
      return Left(DatabaseFailure('Failed to generate mock progress data: $e'));
    }
  }

  /// Get mock user goals
  Future<Either<Failure, List<Goal>>> getUserGoals(String userId) async {
    await _simulateNetworkDelay();
    
    initializeMockDataForUser(userId);
    
    try {
      return Right(_userGoals[userId] ?? []);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get mock goals: $e'));
    }
  }

  /// Add a new goal
  Future<Either<Failure, Goal>> addGoal(Goal goal) async {
    await _simulateNetworkDelay();
    
    try {
      final newGoal = goal.copyWith(
        id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
      );
      
      _userGoals[goal.userId] = (_userGoals[goal.userId] ?? [])..add(newGoal);
      
      return Right(newGoal);
    } catch (e) {
      return Left(DatabaseFailure('Failed to add mock goal: $e'));
    }
  }

  /// Update an existing goal
  Future<Either<Failure, Goal>> updateGoal(Goal goal) async {
    await _simulateNetworkDelay();
    
    try {
      final userGoals = _userGoals[goal.userId] ?? [];
      final index = userGoals.indexWhere((g) => g.id == goal.id);
      
      if (index != -1) {
        userGoals[index] = goal;
        return Right(goal);
      } else {
        return Left(DatabaseFailure('Goal not found'));
      }
    } catch (e) {
      return Left(DatabaseFailure('Failed to update mock goal: $e'));
    }
  }

  /// Delete a goal
  Future<Either<Failure, void>> deleteGoal(String goalId) async {
    await _simulateNetworkDelay();
    
    try {
      for (final userId in _userGoals.keys) {
        _userGoals[userId]?.removeWhere((goal) => goal.id == goalId);
      }
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to delete mock goal: $e'));
    }
  }

  /// Get mock achievements
  Future<Either<Failure, List<Achievement>>> getAchievements(
    String userId,
    AnalyticsTimeRange timeRange,
  ) async {
    await _simulateNetworkDelay();
    
    initializeMockDataForUser(userId);
    
    try {
      final achievements = _userAchievements[userId] ?? [];
      final cutoffDate = _getCutoffDate(timeRange);
      
      final filteredAchievements = achievements
          .where((achievement) => achievement.earnedAt.isAfter(cutoffDate))
          .toList();
      
      return Right(filteredAchievements);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get mock achievements: $e'));
    }
  }

  /// Get mock trend data
  Future<Either<Failure, TrendData>> getTrendData(
    String userId,
    AnalyticsTimeRange timeRange,
  ) async {
    await _simulateNetworkDelay();
    
    try {
      final trends = _generateMockTrendData(userId, timeRange);
      return Right(trends);
    } catch (e) {
      return Left(DatabaseFailure('Failed to generate mock trend data: $e'));
    }
  }

  /// Watch analytics data for real-time updates
  Stream<AnalyticsData> watchAnalyticsData(String userId) {
    initializeMockDataForUser(userId);
    
    if (!_analyticsStreams.containsKey(userId)) {
      _analyticsStreams[userId] = StreamController<AnalyticsData>.broadcast();
      
      // Simulate periodic updates
      Timer.periodic(const Duration(seconds: 30), (timer) {
        if (_analyticsStreams.containsKey(userId)) {
          final data = _cachedAnalytics[userId];
          if (data != null) {
            _analyticsStreams[userId]?.add(data);
          }
        } else {
          timer.cancel();
        }
      });
    }
    
    return _analyticsStreams[userId]!.stream;
  }

  /// Generate mock overview data
  OverviewData _generateMockOverviewData(String userId, AnalyticsTimeRange timeRange) {
    final multiplier = _getTimeRangeMultiplier(timeRange);
    
    return OverviewData(
      totalPoints: (150 * multiplier + _random.nextInt(100)).toInt(),
      currentStreak: _random.nextInt(15) + 1,
      longestStreak: _random.nextInt(30) + 10,
      totalRewards: (8 * multiplier + _random.nextInt(5)).toInt(),
      completedGoals: _random.nextInt(6) + 1,
      activeGoals: _random.nextInt(4) + 2,
      averagePointsPerDay: 12.5 + _random.nextDouble() * 5,
      categoryBreakdown: _generateCategoryBreakdown(),
      recentActivities: _generateRecentActivities(),
    );
  }

  /// Generate mock progress data
  ProgressData _generateMockProgressData(String userId, AnalyticsTimeRange timeRange) {
    return ProgressData(
      dailyProgress: _generateDailyProgress(timeRange),
      weeklyProgress: _generateWeeklyProgress(timeRange),
      monthlyProgress: _generateMonthlyProgress(timeRange),
      categoryProgress: _generateCategoryProgressMap(),
      streakAnalysis: _generateStreakAnalysis(),
      insights: _generateTrendInsights(),
    );
  }

  /// Generate mock trend data
  TrendData _generateMockTrendData(String userId, AnalyticsTimeRange timeRange) {
    final points = _generateTrendPoints(timeRange);
    
    return TrendData(
      pointsTrend: points,
      activityTrend: _generateActivityTrend(timeRange),
      categoryTrend: _generateCategoryTrend(timeRange),
      overallDirection: TrendDirection.values[_random.nextInt(TrendDirection.values.length)],
      trendStrength: _random.nextDouble(),
      insights: _generateMotivationalInsights(),
      predictions: _generateTrendPredictions(),
    );
  }

  /// Generate mock goals for a user
  List<Goal> _generateMockGoals(String userId) {
    final goalTemplates = [
      {'title': '🌟 Earn 100 Points', 'description': 'Collect 100 awesome points!', 'target': 100, 'type': GoalType.points, 'color': '#FF6B6B'},
      {'title': '🔥 7-Day Streak', 'description': 'Keep your streak going for 7 days!', 'target': 7, 'type': GoalType.streak, 'color': '#4ECDC4'},
      {'title': '🎯 Complete 5 Tasks', 'description': 'Finish 5 fun activities!', 'target': 5, 'type': GoalType.activities, 'color': '#45B7D1'},
      {'title': '📚 Reading Champion', 'description': 'Read for 10 sessions!', 'target': 10, 'type': GoalType.category, 'color': '#96CEB4'},
      {'title': '🎨 Creative Master', 'description': 'Complete 8 art activities!', 'target': 8, 'type': GoalType.category, 'color': '#FFEAA7'},
    ];

    return goalTemplates.asMap().entries.map((entry) {
      final template = entry.value;
      final progress = _random.nextInt(template['target'] as int);
      
      return Goal(
        id: 'mock_goal_${entry.key}',
        userId: userId,
        title: template['title'] as String,
        description: template['description'] as String,
        targetValue: template['target'] as int,
        currentValue: progress,
        type: template['type'] as GoalType,
        category: 'mock_category',
        createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(30))),
        targetDate: DateTime.now().add(Duration(days: _random.nextInt(14) + 7)),
        isActive: _random.nextBool() || progress < (template['target'] as int),
        priority: _random.nextInt(3) + 1,
        color: template['color'] as String,
        icon: _getGoalIcon(template['type'] as GoalType),
      );
    }).toList();
  }

  /// Generate mock achievements
  List<Achievement> _generateMockAchievements(String userId) {
    final achievementTemplates = [
      {'title': '🌟 First Steps', 'description': 'Earned your first points!', 'tier': AchievementTier.bronze, 'points': 10},
      {'title': '🔥 Streak Starter', 'description': 'Started your first streak!', 'tier': AchievementTier.bronze, 'points': 25},
      {'title': '💎 Point Collector', 'description': 'Collected 100 points!', 'tier': AchievementTier.silver, 'points': 100},
      {'title': '🏆 Goal Getter', 'description': 'Completed your first goal!', 'tier': AchievementTier.silver, 'points': 150},
      {'title': '👑 Superstar', 'description': 'Earned 500 points total!', 'tier': AchievementTier.gold, 'points': 500},
      {'title': '🚀 Amazing Achiever', 'description': 'Completed 5 goals!', 'tier': AchievementTier.platinum, 'points': 750},
    ];

    return achievementTemplates.asMap().entries.map((entry) {
      final template = entry.value;
      final earnedDate = DateTime.now().subtract(Duration(days: _random.nextInt(60)));
      
      return Achievement(
        id: 'mock_achievement_${entry.key}',
        title: template['title'] as String,
        description: template['description'] as String,
        icon: _getAchievementIcon(template['tier'] as AchievementTier),
        color: (template['tier'] as AchievementTier).color,
        tier: template['tier'] as AchievementTier,
        pointsRequired: template['points'] as int,
        earnedAt: earnedDate,
        metadata: {'category': 'general', 'rarity': 'common'},
      );
    }).where((achievement) => _random.nextDouble() > 0.3).toList(); // Only show some achievements as earned
  }

  /// Helper methods for mock data generation

  Map<String, int> _generateCategoryBreakdown() {
    return {
      'Learning': 45 + _random.nextInt(20),
      'Chores': 30 + _random.nextInt(15),
      'Reading': 25 + _random.nextInt(10),
      'Exercise': 20 + _random.nextInt(10),
      'Creativity': 15 + _random.nextInt(10),
    };
  }

  List<RecentActivity> _generateRecentActivities() {
    final activities = [
      'Completed homework perfectly! 📝',
      'Helped with dishes 🍽️',
      'Read for 20 minutes 📖',
      'Practiced piano 🎹',
      'Cleaned room 🧹',
      'Drew a beautiful picture 🎨',
      'Helped a friend 🤝',
      'Did morning exercises 🤸‍♀️',
    ];

    return List.generate(5, (index) {
      return RecentActivity(
        id: 'activity_$index',
        type: 'reward',
        description: activities[_random.nextInt(activities.length)],
        points: (_random.nextInt(4) + 1) * 5,
        timestamp: DateTime.now().subtract(Duration(hours: index + 1)),
        category: 'general',
        icon: 'star',
      );
    });
  }

  List<DailyProgress> _generateDailyProgress(AnalyticsTimeRange timeRange) {
    final days = _getDaysForTimeRange(timeRange);
    return List.generate(days, (index) {
      final date = DateTime.now().subtract(Duration(days: days - index - 1));
      return DailyProgress(
        date: date,
        points: _random.nextInt(25) + 5,
        activities: _random.nextInt(5) + 1,
        hasStreak: _random.nextDouble() > 0.2,
      );
    });
  }

  List<WeeklyProgress> _generateWeeklyProgress(AnalyticsTimeRange timeRange) {
    final weeks = timeRange == AnalyticsTimeRange.month ? 4 : 
                  timeRange == AnalyticsTimeRange.quarter ? 12 : 8;
    
    return List.generate(weeks, (index) {
      final weekStart = DateTime.now().subtract(Duration(days: (weeks - index) * 7));
      final totalPoints = _random.nextInt(150) + 50;
      
      return WeeklyProgress(
        weekStart: weekStart,
        totalPoints: totalPoints,
        totalActivities: _random.nextInt(20) + 10,
        streakDays: _random.nextInt(7) + 1,
        averageDaily: totalPoints / 7.0,
      );
    });
  }

  List<MonthlyProgress> _generateMonthlyProgress(AnalyticsTimeRange timeRange) {
    final months = timeRange == AnalyticsTimeRange.year ? 12 : 6;
    
    return List.generate(months, (index) {
      return MonthlyProgress(
        month: DateTime.now().subtract(Duration(days: (months - index) * 30)),
        totalPoints: _random.nextInt(500) + 200,
        totalActivities: _random.nextInt(80) + 40,
        completedGoals: _random.nextInt(3) + 1,
        newAchievements: _random.nextInt(2),
      );
    });
  }

  Map<String, List<CategoryProgress>> _generateCategoryProgressMap() {
    final categories = ['Learning', 'Chores', 'Reading', 'Exercise', 'Creativity'];
    
    return {
      'current': categories.map((category) {
        final points = _random.nextInt(50) + 10;
        return CategoryProgress(
          category: category,
          points: points,
          count: _random.nextInt(10) + 2,
          percentage: points / 200.0,
        );
      }).toList(),
    };
  }

  StreakAnalysis _generateStreakAnalysis() {
    return StreakAnalysis(
      currentStreak: _random.nextInt(15) + 1,
      longestStreak: _random.nextInt(30) + 10,
      streakHistory: List.generate(3, (index) {
        final start = DateTime.now().subtract(Duration(days: (index + 2) * 10));
        final days = _random.nextInt(8) + 3;
        return StreakPeriod(
          startDate: start,
          endDate: start.add(Duration(days: days)),
          days: days,
        );
      }),
      streakConsistency: 0.7 + _random.nextDouble() * 0.25,
      streakBreaks: [],
    );
  }

  List<TrendInsight> _generateTrendInsights() {
    final insights = [
      'You\'re doing amazing! Keep up the great work! 🌟',
      'Your reading time has improved this week! 📚',
      'You\'ve been super consistent with chores! 🧹',
      'Your creativity points are growing fast! 🎨',
      'Exercise activities are trending up! 💪',
    ];

    return insights.map((message) => TrendInsight(
      message: message,
      type: TrendInsightType.positive,
      confidence: 0.8 + _random.nextDouble() * 0.2,
    )).toList();
  }

  List<TrendPoint> _generateTrendPoints(AnalyticsTimeRange timeRange) {
    final days = _getDaysForTimeRange(timeRange);
    var currentValue = 50.0 + _random.nextDouble() * 50;
    
    return List.generate(days, (index) {
      currentValue += (_random.nextDouble() - 0.4) * 10;
      currentValue = math.max(0, currentValue);
      
      return TrendPoint(
        date: DateTime.now().subtract(Duration(days: days - index - 1)),
        value: currentValue,
      );
    });
  }

  List<TrendPoint> _generateActivityTrend(AnalyticsTimeRange timeRange) {
    final days = _getDaysForTimeRange(timeRange);
    
    return List.generate(days, (index) {
      return TrendPoint(
        date: DateTime.now().subtract(Duration(days: days - index - 1)),
        value: _random.nextInt(8) + 2.0,
      );
    });
  }

  List<TrendPoint> _generateCategoryTrend(AnalyticsTimeRange timeRange) {
    return _generateTrendPoints(timeRange);
  }

  List<String> _generateMotivationalInsights() {
    return [
      '🌟 You\'re a superstar! Keep shining bright!',
      '🚀 Your progress is out of this world!',
      '💎 You\'re more precious than diamonds!',
      '🏆 Champion level achieved! You rock!',
      '🌈 You make every day more colorful!',
    ];
  }

  Map<String, TrendPrediction> _generateTrendPredictions() {
    return {
      'points': TrendPrediction(
        predictedValue: _random.nextDouble() * 100 + 150,
        confidence: 0.85,
        targetDate: DateTime.now().add(const Duration(days: 7)),
      ),
      'activities': TrendPrediction(
        predictedValue: _random.nextDouble() * 20 + 30,
        confidence: 0.78,
        targetDate: DateTime.now().add(const Duration(days: 7)),
      ),
    };
  }

  /// Utility methods

  DateTime _getCutoffDate(AnalyticsTimeRange timeRange) {
    switch (timeRange) {
      case AnalyticsTimeRange.day:
        return DateTime.now().subtract(const Duration(days: 1));
      case AnalyticsTimeRange.week:
        return DateTime.now().subtract(const Duration(days: 7));
      case AnalyticsTimeRange.month:
        return DateTime.now().subtract(const Duration(days: 30));
      case AnalyticsTimeRange.quarter:
        return DateTime.now().subtract(const Duration(days: 90));
      case AnalyticsTimeRange.year:
        return DateTime.now().subtract(const Duration(days: 365));
      case AnalyticsTimeRange.all:
        return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  double _getTimeRangeMultiplier(AnalyticsTimeRange timeRange) {
    switch (timeRange) {
      case AnalyticsTimeRange.day:
        return 0.1;
      case AnalyticsTimeRange.week:
        return 1.0;
      case AnalyticsTimeRange.month:
        return 4.0;
      case AnalyticsTimeRange.quarter:
        return 12.0;
      case AnalyticsTimeRange.year:
        return 52.0;
      case AnalyticsTimeRange.all:
        return 100.0;
    }
  }

  int _getDaysForTimeRange(AnalyticsTimeRange timeRange) {
    switch (timeRange) {
      case AnalyticsTimeRange.day:
        return 1;
      case AnalyticsTimeRange.week:
        return 7;
      case AnalyticsTimeRange.month:
        return 30;
      case AnalyticsTimeRange.quarter:
        return 90;
      case AnalyticsTimeRange.year:
        return 365;
      case AnalyticsTimeRange.all:
        return 730; // 2 years max for performance
    }
  }

  String _getGoalIcon(GoalType type) {
    switch (type) {
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

  String _getAchievementIcon(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return 'workspace_premium';
      case AchievementTier.silver:
        return 'military_tech';
      case AchievementTier.gold:
        return 'emoji_events';
      case AchievementTier.platinum:
        return 'diamond';
      case AchievementTier.diamond:
        return 'auto_awesome';
    }
  }

  /// Simulate network delay for realistic behavior
  Future<void> _simulateNetworkDelay() async {
    await Future.delayed(Duration(milliseconds: 100 + _random.nextInt(300)));
  }

  /// Dispose of resources
  void dispose() {
    for (final controller in _analyticsStreams.values) {
      controller.close();
    }
    _analyticsStreams.clear();
  }
}