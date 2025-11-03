import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/analytics_entities.dart';

/// Repository interface for analytics operations with kid-friendly features
/// 
/// This repository provides comprehensive analytics functionality for children's
/// reward tracking, including real-time updates, goal management, achievement
/// tracking, and engaging data visualization support.
abstract class AnalyticsRepository {
  
  // Core analytics data methods
  
  /// Get comprehensive overview data for a user within a time range
  Future<Either<Failure, OverviewData>> getOverviewData(
    String userId, 
    AnalyticsTimeRange timeRange,
  );
  
  /// Get detailed progress data for charts and insights
  Future<Either<Failure, ProgressData>> getProgressData(
    String userId, 
    AnalyticsTimeRange timeRange,
  );
  
  /// Get trend analysis data for predictions and insights
  Future<Either<Failure, TrendData>> getTrendData(
    String userId, 
    AnalyticsTimeRange timeRange,
  );
  
  /// Get user's achievements within a time range
  Future<Either<Failure, List<Achievement>>> getAchievements(
    String userId, 
    AnalyticsTimeRange timeRange,
  );
  
  /// Get comprehensive analytics data (combines all above)
  Future<Either<Failure, AnalyticsData>> getAnalyticsData(
    String userId, 
    AnalyticsTimeRange timeRange,
  );
  
  // Real-time analytics methods
  
  /// Watch analytics data for real-time updates
  Stream<AnalyticsData> watchAnalyticsData(String userId);
  
  /// Watch specific metrics for real-time updates
  Stream<OverviewData> watchOverviewData(String userId);
  
  /// Watch progress data for real-time chart updates
  Stream<ProgressData> watchProgressData(String userId);
  
  // Goal management methods
  
  /// Get all goals for a user
  Future<Either<Failure, List<Goal>>> getUserGoals(String userId);
  
  /// Get active goals for a user
  Future<Either<Failure, List<Goal>>> getActiveGoals(String userId);
  
  /// Get completed goals for a user
  Future<Either<Failure, List<Goal>>> getCompletedGoals(String userId);
  
  /// Add a new goal
  Future<Either<Failure, Goal>> addGoal(Goal goal);
  
  /// Update an existing goal
  Future<Either<Failure, Goal>> updateGoal(Goal goal);
  
  /// Delete a goal
  Future<Either<Failure, void>> deleteGoal(String goalId);
  
  /// Mark a goal as completed
  Future<Either<Failure, Goal>> completeGoal(String goalId);
  
  /// Update goal progress
  Future<Either<Failure, Goal>> updateGoalProgress(String goalId, int progress);
  
  // Achievement methods
  
  /// Get all available achievements
  Future<Either<Failure, List<Achievement>>> getAvailableAchievements();
  
  /// Get earned achievements for a user
  Future<Either<Failure, List<Achievement>>> getEarnedAchievements(String userId);
  
  /// Check for new achievements
  Future<Either<Failure, List<Achievement>>> checkNewAchievements(String userId);
  
  /// Award an achievement to a user
  Future<Either<Failure, Achievement>> awardAchievement(
    String userId, 
    String achievementId,
  );
  
  // Analytics insights and recommendations
  
  /// Get personalized insights for a user
  Future<Either<Failure, List<TrendInsight>>> getInsights(
    String userId, 
    AnalyticsTimeRange timeRange,
  );
  
  /// Get goal recommendations based on user activity
  Future<Either<Failure, List<Goal>>> getGoalRecommendations(String userId);
  
  /// Get achievement recommendations
  Future<Either<Failure, List<Achievement>>> getAchievementRecommendations(String userId);
  
  // Data export and import
  
  /// Export analytics data in specified format
  Future<Either<Failure, String>> exportAnalyticsData(
    String userId,
    AnalyticsExportFormat format,
    AnalyticsTimeRange timeRange,
  );
  
  /// Import analytics data from file
  Future<Either<Failure, AnalyticsImportResult>> importAnalyticsData(
    String userId,
    String filePath,
    AnalyticsImportFormat format,
  );
  
  // Analytics configuration and preferences
  
  /// Get user's analytics preferences
  Future<Either<Failure, AnalyticsPreferences>> getAnalyticsPreferences(String userId);
  
  /// Update user's analytics preferences
  Future<Either<Failure, void>> updateAnalyticsPreferences(
    String userId,
    AnalyticsPreferences preferences,
  );
  
  /// Reset user's analytics data (with confirmation)
  Future<Either<Failure, void>> resetAnalyticsData(String userId);
  
  // Performance and caching methods
  
  /// Refresh analytics cache for a user
  Future<Either<Failure, void>> refreshAnalyticsCache(String userId);
  
  /// Clear analytics cache for a user
  Future<Either<Failure, void>> clearAnalyticsCache(String userId);
  
  /// Preload analytics data for better performance
  Future<Either<Failure, void>> preloadAnalyticsData(
    String userId,
    List<AnalyticsTimeRange> timeRanges,
  );
}

/// Analytics import result with details
class AnalyticsImportResult {
  final int importedGoals;
  final int importedAchievements;
  final int importedActivities;
  final List<String> errors;
  final List<String> warnings;

  const AnalyticsImportResult({
    required this.importedGoals,
    required this.importedAchievements,
    required this.importedActivities,
    this.errors = const [],
    this.warnings = const [],
  });

  bool get isSuccessful => errors.isEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
  int get totalImported => importedGoals + importedAchievements + importedActivities;
}

/// User analytics preferences
class AnalyticsPreferences {
  final bool enableRealTime;
  final bool enableNotifications;
  final bool showCelebrations;
  final AnalyticsTimeRange defaultTimeRange;
  final List<String> favoriteMetrics;
  final bool enableGoalReminders;
  final bool enableStreakReminders;
  final Map<String, bool> chartPreferences;

  const AnalyticsPreferences({
    this.enableRealTime = true,
    this.enableNotifications = true,
    this.showCelebrations = true,
    this.defaultTimeRange = AnalyticsTimeRange.week,
    this.favoriteMetrics = const [],
    this.enableGoalReminders = true,
    this.enableStreakReminders = true,
    this.chartPreferences = const {},
  });

  AnalyticsPreferences copyWith({
    bool? enableRealTime,
    bool? enableNotifications,
    bool? showCelebrations,
    AnalyticsTimeRange? defaultTimeRange,
    List<String>? favoriteMetrics,
    bool? enableGoalReminders,
    bool? enableStreakReminders,
    Map<String, bool>? chartPreferences,
  }) {
    return AnalyticsPreferences(
      enableRealTime: enableRealTime ?? this.enableRealTime,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      showCelebrations: showCelebrations ?? this.showCelebrations,
      defaultTimeRange: defaultTimeRange ?? this.defaultTimeRange,
      favoriteMetrics: favoriteMetrics ?? this.favoriteMetrics,
      enableGoalReminders: enableGoalReminders ?? this.enableGoalReminders,
      enableStreakReminders: enableStreakReminders ?? this.enableStreakReminders,
      chartPreferences: chartPreferences ?? this.chartPreferences,
    );
  }
}