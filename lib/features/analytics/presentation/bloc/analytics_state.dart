import 'package:equatable/equatable.dart';

import '../../domain/entities/analytics_entities.dart';

/// Base class for all analytics states with kid-friendly messaging
sealed class AnalyticsState extends Equatable {
  const AnalyticsState();

  @override
  List<Object?> get props => [];

  /// Helper to check if analytics are loading
  bool get isLoading => this is AnalyticsLoading || this is AnalyticsRefreshing;

  /// Helper to check if there's an error
  bool get hasError => this is AnalyticsError;

  /// Helper to get current analytics data if available
  AnalyticsData? get data {
    if (this is AnalyticsLoaded) {
      return (this as AnalyticsLoaded).data;
    } else if (this is AnalyticsRefreshing) {
      return (this as AnalyticsRefreshing).currentData;
    } else if (this is AnalyticsCelebration) {
      return (this as AnalyticsCelebration).currentData;
    } else if (this is AnalyticsGoalProcessing) {
      return (this as AnalyticsGoalProcessing).currentData;
    }
    return null;
  }

  /// Helper to check if real-time updates are enabled
  bool get isRealTimeEnabled {
    return this is AnalyticsLoaded && (this as AnalyticsLoaded).isRealTimeEnabled;
  }
}

/// Initial analytics state before any operations
class AnalyticsInitial extends AnalyticsState {
  const AnalyticsInitial();
}

/// State when analytics operations are in progress with engaging messages
class AnalyticsLoading extends AnalyticsState {
  final String message;
  final AnalyticsLoadingType loadingType;
  final double? progress;

  const AnalyticsLoading({
    required this.message,
    required this.loadingType,
    this.progress,
  });

  @override
  List<Object?> get props => [message, loadingType, progress];
}

/// State when analytics data is successfully loaded
class AnalyticsLoaded extends AnalyticsState {
  final AnalyticsData data;
  final AnalyticsTimeRange timeRange;
  final bool isRealTimeEnabled;
  final List<Goal> selectedGoals;
  final AnalyticsFilter? selectedFilter;
  final DateTime lastInteraction;

  const AnalyticsLoaded({
    required this.data,
    required this.timeRange,
    required this.isRealTimeEnabled,
    this.selectedGoals = const [],
    this.selectedFilter,
    DateTime? lastInteraction,
  }) : lastInteraction = lastInteraction ?? DateTime.fromMillisecondsSinceEpoch(0);

  @override
  List<Object?> get props => [
        data,
        timeRange,
        isRealTimeEnabled,
        selectedGoals,
        selectedFilter,
        lastInteraction,
      ];

  /// Create a copy with updated properties
  AnalyticsLoaded copyWith({
    AnalyticsData? data,
    AnalyticsTimeRange? timeRange,
    bool? isRealTimeEnabled,
    List<Goal>? selectedGoals,
    AnalyticsFilter? selectedFilter,
    DateTime? lastInteraction,
  }) {
    return AnalyticsLoaded(
      data: data ?? this.data,
      timeRange: timeRange ?? this.timeRange,
      isRealTimeEnabled: isRealTimeEnabled ?? this.isRealTimeEnabled,
      selectedGoals: selectedGoals ?? this.selectedGoals,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      lastInteraction: lastInteraction ?? DateTime.now(),
    );
  }

  /// Get active goals from the data
  List<Goal> get activeGoals => data.goals.where((goal) => goal.isActive).toList();

  /// Get completed goals from the data
  List<Goal> get completedGoals => data.goals.where((goal) => goal.isCompleted).toList();

  /// Get recent achievements (last 7 days)
  List<Achievement> get recentAchievements {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return data.achievements.where((achievement) => achievement.earnedAt.isAfter(weekAgo)).toList();
  }

  /// Get progress percentage for current goals
  double get overallGoalProgress {
    final activeGoals = this.activeGoals;
    if (activeGoals.isEmpty) return 1.0;
    
    final totalProgress = activeGoals.map((goal) => goal.progressPercentage).reduce((a, b) => a + b);
    return totalProgress / activeGoals.length;
  }
}

/// State when refreshing analytics data while keeping current data visible
class AnalyticsRefreshing extends AnalyticsState {
  final AnalyticsData currentData;
  final String message;

  const AnalyticsRefreshing({
    required this.currentData,
    required this.message,
  });

  @override
  List<Object?> get props => [currentData, message];
}

/// State when an analytics error occurs with kid-friendly messages
class AnalyticsError extends AnalyticsState {
  final String message;
  final AnalyticsErrorType errorType;
  final bool canRetry;
  final String? details;

  const AnalyticsError({
    required this.message,
    required this.errorType,
    this.canRetry = true,
    this.details,
  });

  @override
  List<Object?> get props => [message, errorType, canRetry, details];

  /// Get user-friendly error message with emoji
  String get friendlyMessage {
    switch (errorType) {
      case AnalyticsErrorType.networkError:
        return '🌐 Can\'t connect right now. Check your internet!';
      case AnalyticsErrorType.loadError:
        return '📊 Having trouble loading your data. Let\'s try again!';
      case AnalyticsErrorType.goalError:
        return '🎯 Oops! Something went wrong with your goals.';
      case AnalyticsErrorType.achievementError:
        return '🏆 Can\'t load achievements right now. Don\'t worry, they\'re still yours!';
      case AnalyticsErrorType.realtimeError:
        return '⚡ Real-time updates are taking a break. Your data is still safe!';
      case AnalyticsErrorType.exportError:
        return '💾 Can\'t export your data right now. Try again later!';
      case AnalyticsErrorType.importError:
        return '📤 Having trouble importing. Check your file and try again!';
      case AnalyticsErrorType.generic:
        return '😅 Something went wrong. Don\'t worry, let\'s try again!';
    }
  }
}

/// State when celebrating achievements, goals, or milestones
class AnalyticsCelebration extends AnalyticsState {
  final AnalyticsData currentData;
  final CelebrationType celebrationType;
  final String message;
  final Goal? goal;
  final Achievement? achievement;
  final Map<String, dynamic>? celebrationData;

  const AnalyticsCelebration({
    required this.currentData,
    required this.celebrationType,
    required this.message,
    this.goal,
    this.achievement,
    this.celebrationData,
  });

  @override
  List<Object?> get props => [
        currentData,
        celebrationType,
        message,
        goal,
        achievement,
        celebrationData,
      ];

  /// Get celebration emoji based on type
  String get celebrationEmoji {
    switch (celebrationType) {
      case CelebrationType.goalCompleted:
        return '🎉🎯';
      case CelebrationType.goalAdded:
        return '✨🎯';
      case CelebrationType.achievementUnlocked:
        return '🏆⭐';
      case CelebrationType.streakMilestone:
        return '🔥💪';
      case CelebrationType.milestoneReached:
        return '🎊🌟';
      case CelebrationType.perfectWeek:
        return '👑✨';
    }
  }

  /// Get celebration color based on type
  String get celebrationColor {
    switch (celebrationType) {
      case CelebrationType.goalCompleted:
        return '#4CAF50'; // Green
      case CelebrationType.goalAdded:
        return '#2196F3'; // Blue
      case CelebrationType.achievementUnlocked:
        return '#FF9800'; // Orange
      case CelebrationType.streakMilestone:
        return '#F44336'; // Red
      case CelebrationType.milestoneReached:
        return '#9C27B0'; // Purple
      case CelebrationType.perfectWeek:
        return '#FFD700'; // Gold
    }
  }
}

/// State when processing goal operations
class AnalyticsGoalProcessing extends AnalyticsState {
  final AnalyticsData currentData;
  final String message;
  final GoalOperationType operationType;

  const AnalyticsGoalProcessing({
    required this.currentData,
    required this.message,
    required this.operationType,
  });

  @override
  List<Object?> get props => [currentData, message, operationType];
}

/// State for export operations
class AnalyticsExportInProgress extends AnalyticsState {
  final AnalyticsExportFormat format;
  final int progress;
  final String? statusMessage;

  const AnalyticsExportInProgress({
    required this.format,
    required this.progress,
    this.statusMessage,
  });

  @override
  List<Object?> get props => [format, progress, statusMessage];
}

/// State when export is completed
class AnalyticsExportCompleted extends AnalyticsState {
  final String filePath;
  final AnalyticsExportFormat format;
  final int dataPoints;

  const AnalyticsExportCompleted({
    required this.filePath,
    required this.format,
    required this.dataPoints,
  });

  @override
  List<Object?> get props => [filePath, format, dataPoints];
}

/// State for import operations
class AnalyticsImportInProgress extends AnalyticsState {
  final AnalyticsImportFormat format;
  final int progress;
  final String? statusMessage;

  const AnalyticsImportInProgress({
    required this.format,
    required this.progress,
    this.statusMessage,
  });

  @override
  List<Object?> get props => [format, progress, statusMessage];
}

/// State when import is completed
class AnalyticsImportCompleted extends AnalyticsState {
  final AnalyticsImportFormat format;
  final int importedItems;
  final List<String> errors;

  const AnalyticsImportCompleted({
    required this.format,
    required this.importedItems,
    this.errors = const [],
  });

  @override
  List<Object?> get props => [format, importedItems, errors];

  bool get hasErrors => errors.isNotEmpty;
}

// Enums for analytics states

/// Enum for different types of analytics loading operations
enum AnalyticsLoadingType {
  initialLoad,
  refresh,
  goalOperation,
  export,
  import,
  realtimeSetup,
}

/// Enum for different types of analytics errors
enum AnalyticsErrorType {
  networkError,
  loadError,
  goalError,
  achievementError,
  realtimeError,
  exportError,
  importError,
  generic,
}

/// Enum for goal operation types
enum GoalOperationType {
  add,
  update,
  delete,
  complete,
}

// Extension methods for better usability

extension AnalyticsLoadingTypeExtension on AnalyticsLoadingType {
  String get displayName {
    switch (this) {
      case AnalyticsLoadingType.initialLoad:
        return 'Loading Analytics';
      case AnalyticsLoadingType.refresh:
        return 'Refreshing Data';
      case AnalyticsLoadingType.goalOperation:
        return 'Managing Goals';
      case AnalyticsLoadingType.export:
        return 'Exporting Data';
      case AnalyticsLoadingType.import:
        return 'Importing Data';
      case AnalyticsLoadingType.realtimeSetup:
        return 'Setting up Real-time';
    }
  }

  String get kidFriendlyMessage {
    switch (this) {
      case AnalyticsLoadingType.initialLoad:
        return '🎯 Loading your awesome progress...';
      case AnalyticsLoadingType.refresh:
        return '🔄 Getting the latest updates...';
      case AnalyticsLoadingType.goalOperation:
        return '⭐ Working on your goals...';
      case AnalyticsLoadingType.export:
        return '💾 Preparing your data...';
      case AnalyticsLoadingType.import:
        return '📤 Bringing in your data...';
      case AnalyticsLoadingType.realtimeSetup:
        return '⚡ Setting up live updates...';
    }
  }
}

extension AnalyticsErrorTypeExtension on AnalyticsErrorType {
  /// Check if error is recoverable
  bool get isRecoverable {
    switch (this) {
      case AnalyticsErrorType.networkError:
      case AnalyticsErrorType.loadError:
      case AnalyticsErrorType.realtimeError:
      case AnalyticsErrorType.generic:
        return true;
      case AnalyticsErrorType.goalError:
      case AnalyticsErrorType.achievementError:
      case AnalyticsErrorType.exportError:
      case AnalyticsErrorType.importError:
        return true;
    }
  }

  /// Get suggested action for users
  String get suggestedAction {
    switch (this) {
      case AnalyticsErrorType.networkError:
        return 'Check your internet connection and try again';
      case AnalyticsErrorType.loadError:
        return 'Tap retry to reload your data';
      case AnalyticsErrorType.goalError:
        return 'Try creating or updating your goal again';
      case AnalyticsErrorType.achievementError:
        return 'Your achievements are safe, just refresh to see them';
      case AnalyticsErrorType.realtimeError:
        return 'Real-time updates will resume automatically';
      case AnalyticsErrorType.exportError:
        return 'Try exporting again or choose a different format';
      case AnalyticsErrorType.importError:
        return 'Check your file and try importing again';
      case AnalyticsErrorType.generic:
        return 'Something went wrong, but we can fix it together!';
    }
  }
}