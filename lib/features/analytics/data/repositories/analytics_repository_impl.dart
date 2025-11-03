import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/analytics_entities.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../services/analytics_mock_data_service.dart';

/// Implementation of AnalyticsRepository using mock data service
/// 
/// This implementation provides a complete analytics data layer using
/// realistic mock data designed for children's reward tracking. Perfect
/// for development, testing, and offline-first user experience.
@LazySingleton(as: AnalyticsRepository)
class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final AnalyticsMockDataService _mockDataService;

  AnalyticsRepositoryImpl({
    AnalyticsMockDataService? mockDataService,
  }) : _mockDataService = mockDataService ?? AnalyticsMockDataService();

  @override
  Future<Either<Failure, OverviewData>> getOverviewData(
    String userId,
    AnalyticsTimeRange timeRange,
  ) async {
    try {
      return await _mockDataService.getOverviewData(userId, timeRange);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get overview data: $e'));
    }
  }

  @override
  Future<Either<Failure, ProgressData>> getProgressData(
    String userId,
    AnalyticsTimeRange timeRange,
  ) async {
    try {
      return await _mockDataService.getProgressData(userId, timeRange);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get progress data: $e'));
    }
  }

  @override
  Future<Either<Failure, TrendData>> getTrendData(
    String userId,
    AnalyticsTimeRange timeRange,
  ) async {
    try {
      return await _mockDataService.getTrendData(userId, timeRange);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get trend data: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Achievement>>> getAchievements(
    String userId,
    AnalyticsTimeRange timeRange,
  ) async {
    try {
      return await _mockDataService.getAchievements(userId, timeRange);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get achievements: $e'));
    }
  }

  @override
  Future<Either<Failure, AnalyticsData>> getAnalyticsData(
    String userId,
    AnalyticsTimeRange timeRange,
  ) async {
    try {
      return await _mockDataService.getAnalyticsData(userId, timeRange);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get analytics data: $e'));
    }
  }

  @override
  Stream<AnalyticsData> watchAnalyticsData(String userId) {
    try {
      return _mockDataService.watchAnalyticsData(userId);
    } catch (e) {
      return Stream.error(DatabaseFailure('Failed to watch analytics data: $e'));
    }
  }

  @override
  Stream<OverviewData> watchOverviewData(String userId) {
    // For mock implementation, we'll simulate overview updates
    return watchAnalyticsData(userId).map((data) => data.overview);
  }

  @override
  Stream<ProgressData> watchProgressData(String userId) {
    // For mock implementation, we'll simulate progress updates
    return watchAnalyticsData(userId).map((data) => data.progress);
  }

  @override
  Future<Either<Failure, List<Goal>>> getUserGoals(String userId) async {
    try {
      return await _mockDataService.getUserGoals(userId);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get user goals: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Goal>>> getActiveGoals(String userId) async {
    try {
      final result = await _mockDataService.getUserGoals(userId);
      return result.fold(
        (failure) => Left(failure),
        (goals) => Right(goals.where((goal) => goal.isActive).toList()),
      );
    } catch (e) {
      return Left(DatabaseFailure('Failed to get active goals: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Goal>>> getCompletedGoals(String userId) async {
    try {
      final result = await _mockDataService.getUserGoals(userId);
      return result.fold(
        (failure) => Left(failure),
        (goals) => Right(goals.where((goal) => goal.isCompleted).toList()),
      );
    } catch (e) {
      return Left(DatabaseFailure('Failed to get completed goals: $e'));
    }
  }

  @override
  Future<Either<Failure, Goal>> addGoal(Goal goal) async {
    try {
      return await _mockDataService.addGoal(goal);
    } catch (e) {
      return Left(DatabaseFailure('Failed to add goal: $e'));
    }
  }

  @override
  Future<Either<Failure, Goal>> updateGoal(Goal goal) async {
    try {
      return await _mockDataService.updateGoal(goal);
    } catch (e) {
      return Left(DatabaseFailure('Failed to update goal: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteGoal(String goalId) async {
    try {
      return await _mockDataService.deleteGoal(goalId);
    } catch (e) {
      return Left(DatabaseFailure('Failed to delete goal: $e'));
    }
  }

  @override
  Future<Either<Failure, Goal>> completeGoal(String goalId) async {
    try {
      // For mock implementation, we'll simulate goal completion
      // In a real implementation, this would mark the goal as completed
      return Left(DatabaseFailure('Goal completion not implemented in mock'));
    } catch (e) {
      return Left(DatabaseFailure('Failed to complete goal: $e'));
    }
  }

  @override
  Future<Either<Failure, Goal>> updateGoalProgress(String goalId, int progress) async {
    try {
      // For mock implementation, we'll simulate progress update
      // In a real implementation, this would update the goal's current value
      return Left(DatabaseFailure('Goal progress update not implemented in mock'));
    } catch (e) {
      return Left(DatabaseFailure('Failed to update goal progress: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Achievement>>> getAvailableAchievements() async {
    try {
      // Mock available achievements
      final achievements = [
        Achievement(
          id: 'available_1',
          title: '🌟 First Steps',
          description: 'Earn your first points!',
          icon: 'star',
          color: '#FFD700',
          tier: AchievementTier.bronze,
          pointsRequired: 10,
          earnedAt: DateTime.now(),
        ),
        Achievement(
          id: 'available_2',
          title: '🔥 Streak Starter',
          description: 'Start your first streak!',
          icon: 'local_fire_department',
          color: '#FF6347',
          tier: AchievementTier.bronze,
          pointsRequired: 25,
          earnedAt: DateTime.now(),
        ),
        Achievement(
          id: 'available_3',
          title: '💎 Point Collector',
          description: 'Collect 100 points!',
          icon: 'diamond',
          color: '#87CEEB',
          tier: AchievementTier.silver,
          pointsRequired: 100,
          earnedAt: DateTime.now(),
        ),
      ];
      
      return Right(achievements);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get available achievements: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Achievement>>> getEarnedAchievements(String userId) async {
    try {
      return await getAchievements(userId, AnalyticsTimeRange.all);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get earned achievements: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Achievement>>> checkNewAchievements(String userId) async {
    try {
      // Mock new achievements check
      // In a real implementation, this would check if user has earned new achievements
      return const Right([]);
    } catch (e) {
      return Left(DatabaseFailure('Failed to check new achievements: $e'));
    }
  }

  @override
  Future<Either<Failure, Achievement>> awardAchievement(
    String userId,
    String achievementId,
  ) async {
    try {
      // Mock achievement awarding
      final achievement = Achievement(
        id: achievementId,
        title: '🎉 New Achievement',
        description: 'Congratulations on your achievement!',
        icon: 'emoji_events',
        color: '#FFD700',
        tier: AchievementTier.gold,
        pointsRequired: 100,
        earnedAt: DateTime.now(),
      );
      
      return Right(achievement);
    } catch (e) {
      return Left(DatabaseFailure('Failed to award achievement: $e'));
    }
  }

  @override
  Future<Either<Failure, List<TrendInsight>>> getInsights(
    String userId,
    AnalyticsTimeRange timeRange,
  ) async {
    try {
      final trendResult = await getTrendData(userId, timeRange);
      return trendResult.fold(
        (failure) => Left(failure),
        (trendData) {
          final insights = [
            const TrendInsight(
              message: '🌟 You\'re doing amazing! Keep up the great work!',
              type: TrendInsightType.positive,
              confidence: 0.95,
            ),
            const TrendInsight(
              message: '📈 Your progress is trending upward!',
              type: TrendInsightType.positive,
              confidence: 0.87,
            ),
            const TrendInsight(
              message: '🎯 Try setting a new goal to keep growing!',
              type: TrendInsightType.suggestion,
              confidence: 0.82,
            ),
          ];
          return Right(insights);
        },
      );
    } catch (e) {
      return Left(DatabaseFailure('Failed to get insights: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Goal>>> getGoalRecommendations(String userId) async {
    try {
      // Mock goal recommendations based on user activity
      final recommendations = [
        Goal(
          id: 'rec_goal_1',
          userId: userId,
          title: '🌟 Daily Champion',
          description: 'Earn points every day this week!',
          targetValue: 7,
          currentValue: 0,
          type: GoalType.streak,
          category: 'daily',
          createdAt: DateTime.now(),
          targetDate: DateTime.now().add(const Duration(days: 7)),
          color: '#FF6B6B',
          icon: 'local_fire_department',
        ),
        Goal(
          id: 'rec_goal_2',
          userId: userId,
          title: '📚 Reading Star',
          description: 'Complete 10 reading activities!',
          targetValue: 10,
          currentValue: 0,
          type: GoalType.category,
          category: 'reading',
          createdAt: DateTime.now(),
          targetDate: DateTime.now().add(const Duration(days: 14)),
          color: '#4ECDC4',
          icon: 'menu_book',
        ),
      ];
      
      return Right(recommendations);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get goal recommendations: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Achievement>>> getAchievementRecommendations(String userId) async {
    try {
      // Mock achievement recommendations
      final recommendations = [
        Achievement(
          id: 'rec_achievement_1',
          title: '🏆 Super Achiever',
          description: 'Complete 3 goals in one week!',
          icon: 'emoji_events',
          color: '#FFD700',
          tier: AchievementTier.gold,
          pointsRequired: 200,
          earnedAt: DateTime.now(),
        ),
        Achievement(
          id: 'rec_achievement_2',
          title: '💪 Consistency King',
          description: 'Maintain a 14-day streak!',
          icon: 'fitness_center',
          color: '#FF6347',
          tier: AchievementTier.platinum,
          pointsRequired: 350,
          earnedAt: DateTime.now(),
        ),
      ];
      
      return Right(recommendations);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get achievement recommendations: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> exportAnalyticsData(
    String userId,
    AnalyticsExportFormat format,
    AnalyticsTimeRange timeRange,
  ) async {
    try {
      // Mock export functionality
      await Future.delayed(const Duration(seconds: 2)); // Simulate export time
      
      final filename = 'analytics_${userId}_${format.name}_${DateTime.now().millisecondsSinceEpoch}';
      final mockPath = '/mock/exports/$filename';
      
      return Right(mockPath);
    } catch (e) {
      return Left(DatabaseFailure('Failed to export analytics data: $e'));
    }
  }

  @override
  Future<Either<Failure, AnalyticsImportResult>> importAnalyticsData(
    String userId,
    String filePath,
    AnalyticsImportFormat format,
  ) async {
    try {
      // Mock import functionality
      await Future.delayed(const Duration(seconds: 3)); // Simulate import time
      
      final importResult = AnalyticsImportResult(
        importedGoals: 3,
        importedAchievements: 5,
        importedActivities: 12,
        errors: [],
        warnings: ['Some data was already present and was skipped'],
      );
      
      return Right(importResult);
    } catch (e) {
      return Left(DatabaseFailure('Failed to import analytics data: $e'));
    }
  }

  @override
  Future<Either<Failure, AnalyticsPreferences>> getAnalyticsPreferences(String userId) async {
    try {
      // Mock user preferences
      const preferences = AnalyticsPreferences(
        enableRealTime: true,
        enableNotifications: true,
        showCelebrations: true,
        defaultTimeRange: AnalyticsTimeRange.week,
        favoriteMetrics: ['points', 'streaks', 'goals'],
        enableGoalReminders: true,
        enableStreakReminders: true,
        chartPreferences: {
          'showAnimations': true,
          'colorfulTheme': true,
          'simplifiedCharts': false,
        },
      );
      
      return const Right(preferences);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get analytics preferences: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateAnalyticsPreferences(
    String userId,
    AnalyticsPreferences preferences,
  ) async {
    try {
      // Mock preferences update
      await Future.delayed(const Duration(milliseconds: 200));
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to update analytics preferences: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> resetAnalyticsData(String userId) async {
    try {
      // Mock data reset - requires parental confirmation in real implementation
      await Future.delayed(const Duration(seconds: 1));
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to reset analytics data: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> refreshAnalyticsCache(String userId) async {
    try {
      // Mock cache refresh
      await Future.delayed(const Duration(milliseconds: 500));
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to refresh analytics cache: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearAnalyticsCache(String userId) async {
    try {
      // Mock cache clear
      await Future.delayed(const Duration(milliseconds: 100));
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to clear analytics cache: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> preloadAnalyticsData(
    String userId,
    List<AnalyticsTimeRange> timeRanges,
  ) async {
    try {
      // Mock data preloading for better performance
      for (final timeRange in timeRanges) {
        await getAnalyticsData(userId, timeRange);
      }
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to preload analytics data: $e'));
    }
  }
}