import 'package:equatable/equatable.dart';

import '../../domain/entities/analytics_entities.dart';

/// Base class for all analytics events
sealed class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load analytics data for a user
class AnalyticsLoadRequested extends AnalyticsEvent {
  final String userId;
  final AnalyticsTimeRange timeRange;
  final bool forceRefresh;

  const AnalyticsLoadRequested({
    required this.userId,
    this.timeRange = AnalyticsTimeRange.week,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [userId, timeRange, forceRefresh];
}

/// Event to refresh current analytics data
class AnalyticsRefreshRequested extends AnalyticsEvent {
  final bool showLoading;

  const AnalyticsRefreshRequested({
    this.showLoading = true,
  });

  @override
  List<Object?> get props => [showLoading];
}

/// Event to start real-time analytics updates
class AnalyticsRealTimeStarted extends AnalyticsEvent {
  const AnalyticsRealTimeStarted();
}

/// Event to stop real-time analytics updates
class AnalyticsRealTimeStopped extends AnalyticsEvent {
  const AnalyticsRealTimeStopped();
}

/// Event when analytics data is updated from real-time stream
class AnalyticsDataUpdated extends AnalyticsEvent {
  final AnalyticsData data;

  const AnalyticsDataUpdated({
    required this.data,
  });

  @override
  List<Object?> get props => [data];
}

/// Event to add a new goal
class AnalyticsGoalAdded extends AnalyticsEvent {
  final Goal goal;

  const AnalyticsGoalAdded({
    required this.goal,
  });

  @override
  List<Object?> get props => [goal];
}

/// Event to update an existing goal
class AnalyticsGoalUpdated extends AnalyticsEvent {
  final Goal goal;

  const AnalyticsGoalUpdated({
    required this.goal,
  });

  @override
  List<Object?> get props => [goal];
}

/// Event to delete a goal
class AnalyticsGoalDeleted extends AnalyticsEvent {
  final String goalId;

  const AnalyticsGoalDeleted({
    required this.goalId,
  });

  @override
  List<Object?> get props => [goalId];
}

/// Event when a goal is completed
class AnalyticsGoalCompleted extends AnalyticsEvent {
  final Goal goal;

  const AnalyticsGoalCompleted({
    required this.goal,
  });

  @override
  List<Object?> get props => [goal];
}

/// Event to trigger celebration animations and messages
class AnalyticsCelebrationTriggered extends AnalyticsEvent {
  final CelebrationType type;
  final String message;
  final Goal? goal;
  final Achievement? achievement;

  const AnalyticsCelebrationTriggered({
    required this.type,
    required this.message,
    this.goal,
    this.achievement,
  });

  @override
  List<Object?> get props => [type, message, goal, achievement];
}

/// Event to change analytics filter
class AnalyticsFilterChanged extends AnalyticsEvent {
  final AnalyticsFilter filter;

  const AnalyticsFilterChanged({
    required this.filter,
  });

  @override
  List<Object?> get props => [filter];
}

/// Event to change time range for analytics
class AnalyticsTimeRangeChanged extends AnalyticsEvent {
  final AnalyticsTimeRange timeRange;

  const AnalyticsTimeRangeChanged({
    required this.timeRange,
  });

  @override
  List<Object?> get props => [timeRange];
}

/// Event to reset analytics state
class AnalyticsResetRequested extends AnalyticsEvent {
  const AnalyticsResetRequested();
}

/// Event to clear error state
class AnalyticsErrorCleared extends AnalyticsEvent {
  const AnalyticsErrorCleared();
}

/// Event to track user interaction for analytics
class AnalyticsInteractionTracked extends AnalyticsEvent {
  final String interactionType;
  final Map<String, dynamic> properties;

  const AnalyticsInteractionTracked({
    required this.interactionType,
    this.properties = const {},
  });

  @override
  List<Object?> get props => [interactionType, properties];
}

/// Event to export analytics data
class AnalyticsExportRequested extends AnalyticsEvent {
  final AnalyticsExportFormat format;
  final AnalyticsTimeRange timeRange;

  const AnalyticsExportRequested({
    required this.format,
    this.timeRange = AnalyticsTimeRange.month,
  });

  @override
  List<Object?> get props => [format, timeRange];
}

/// Event to import analytics data
class AnalyticsImportRequested extends AnalyticsEvent {
  final String filePath;
  final AnalyticsImportFormat format;

  const AnalyticsImportRequested({
    required this.filePath,
    required this.format,
  });

  @override
  List<Object?> get props => [filePath, format];
}