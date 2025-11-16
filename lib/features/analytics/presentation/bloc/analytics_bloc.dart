import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/analytics_entities.dart';
import '../../domain/repositories/analytics_repository.dart';
import 'analytics_event.dart';
import 'analytics_state.dart';

/// BLoC for managing analytics data and operations with kid-friendly features.
/// 
/// This BLoC provides comprehensive analytics for children's reward activities,
/// including visual progress tracking, achievement insights, goal management,
/// and trend analysis. All data is presented in an engaging, child-friendly
/// manner with colorful charts and encouraging messages.
/// 
/// Key features:
/// - Real-time analytics updates with smooth animations
/// - Child-friendly progress visualization and celebrations
/// - Goal tracking with motivational feedback
/// - Trend analysis with positive reinforcement
/// - Interactive charts and statistics designed for kids
/// - Encouraging messages and achievement recognition
@injectable
class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final AnalyticsRepository _analyticsRepository;
  
  // Timers and subscriptions for real-time updates
  Timer? _refreshTimer;
  StreamSubscription<AnalyticsData>? _analyticsSubscription;
  
  // Current user context
  String? _currentUserId;
  
  // Constants for kid-friendly features
  static const Duration _refreshInterval = Duration(minutes: 5);
  static const Duration _celebrationDuration = Duration(seconds: 3);
  
  AnalyticsBloc({
    required AnalyticsRepository analyticsRepository,
  })  : _analyticsRepository = analyticsRepository,
        super(const AnalyticsInitial()) {
    
    // Register event handlers with kid-friendly messaging
    on<AnalyticsLoadRequested>(_onAnalyticsLoadRequested);
    on<AnalyticsRefreshRequested>(_onAnalyticsRefreshRequested);
    on<AnalyticsRealTimeStarted>(_onAnalyticsRealTimeStarted);
    on<AnalyticsRealTimeStopped>(_onAnalyticsRealTimeStopped);
    on<AnalyticsDataUpdated>(_onAnalyticsDataUpdated);
    on<AnalyticsGoalAdded>(_onAnalyticsGoalAdded);
    on<AnalyticsGoalUpdated>(_onAnalyticsGoalUpdated);
    on<AnalyticsGoalDeleted>(_onAnalyticsGoalDeleted);
    on<AnalyticsGoalCompleted>(_onAnalyticsGoalCompleted);
    on<AnalyticsCelebrationTriggered>(_onAnalyticsCelebrationTriggered);
    on<AnalyticsFilterChanged>(_onAnalyticsFilterChanged);
    on<AnalyticsTimeRangeChanged>(_onAnalyticsTimeRangeChanged);
    on<AnalyticsResetRequested>(_onAnalyticsResetRequested);
    on<AnalyticsErrorCleared>(_onAnalyticsErrorCleared);
  }

  /// Load analytics data for a user with engaging loading messages
  Future<void> _onAnalyticsLoadRequested(
    AnalyticsLoadRequested event,
    Emitter<AnalyticsState> emit,
  ) async {
    _currentUserId = event.userId;
    
    if (!event.forceRefresh && state is AnalyticsLoaded) {
      return; // Return cached data if available
    }

    emit(const AnalyticsLoading(
      message: '🎯 Loading your awesome progress...',
      loadingType: AnalyticsLoadingType.initialLoad,
    ));

    try {
      // Load all analytics data in parallel for better performance
      final futures = await Future.wait([
        _loadOverviewData(event.userId, event.timeRange),
        _loadProgressData(event.userId, event.timeRange),
        _loadGoalsData(event.userId),
        _loadAchievementsData(event.userId, event.timeRange),
        _loadTrendsData(event.userId, event.timeRange),
      ]);

      final overviewResult = futures[0] as Either<Failure, OverviewData>;
      final progressResult = futures[1] as Either<Failure, ProgressData>;
      final goalsResult = futures[2] as Either<Failure, List<Goal>>;
      final achievementsResult = futures[3] as Either<Failure, List<Achievement>>;
      final trendsResult = futures[4] as Either<Failure, TrendData>;

      // Check for any failures
      final failures = [
        overviewResult.fold((f) => f, (_) => null),
        progressResult.fold((f) => f, (_) => null),
        goalsResult.fold((f) => f, (_) => null),
        achievementsResult.fold((f) => f, (_) => null),
        trendsResult.fold((f) => f, (_) => null),
      ].where((f) => f != null).toList();

      if (failures.isNotEmpty) {
        emit(AnalyticsError(
          message: '😅 Oops! Having trouble loading your data. Let\'s try again!',
          errorType: AnalyticsErrorType.loadError,
          canRetry: true,
        ));
        return;
      }

      // Extract successful results
      final overview = overviewResult.fold((_) => null, (data) => data)!;
      final progress = progressResult.fold((_) => null, (data) => data)!;
      final goals = goalsResult.fold((_) => <Goal>[], (data) => data);
      final achievements = achievementsResult.fold((_) => <Achievement>[], (data) => data);
      final trends = trendsResult.fold((_) => null, (data) => data)!;

      // Create comprehensive analytics data
      final analyticsData = AnalyticsData(
        overview: overview,
        progress: progress,
        goals: goals,
        achievements: achievements,
        trends: trends,
        lastUpdated: DateTime.now(),
      );

      emit(AnalyticsLoaded(
        data: analyticsData,
        timeRange: event.timeRange,
        isRealTimeEnabled: false,
        selectedGoals: goals.where((goal) => goal.isActive).toList(),
      ));

      // Start auto-refresh timer
      _startAutoRefresh();

      // Check for celebrations
      _checkForCelebrations(analyticsData, emit);

    } catch (e) {
      emit(AnalyticsError(
        message: '😓 Something went wrong! Let\'s give it another try.',
        errorType: AnalyticsErrorType.generic,
        canRetry: true,
        details: e.toString(),
      ));
    }
  }

  /// Refresh analytics data with fun loading messages
  Future<void> _onAnalyticsRefreshRequested(
    AnalyticsRefreshRequested event,
    Emitter<AnalyticsState> emit,
  ) async {
    if (state is! AnalyticsLoaded || _currentUserId == null) {
      return;
    }

    final currentState = state as AnalyticsLoaded;
    
    if (event.showLoading) {
      emit(AnalyticsRefreshing(
        currentData: currentState.data,
        message: '🔄 Getting the latest updates...',
      ));
    }

    try {
      // Refresh with current time range
      add(AnalyticsLoadRequested(
        userId: _currentUserId!,
        timeRange: currentState.timeRange,
        forceRefresh: true,
      ));

    } catch (e) {
      emit(AnalyticsError(
        message: '😅 Couldn\'t refresh right now. Don\'t worry, we\'ll try again!',
        errorType: AnalyticsErrorType.refreshError,
        canRetry: true,
      ));
    }
  }

  /// Start real-time analytics updates
  Future<void> _onAnalyticsRealTimeStarted(
    AnalyticsRealTimeStarted event,
    Emitter<AnalyticsState> emit,
  ) async {
    if (state is! AnalyticsLoaded || _currentUserId == null) {
      return;
    }

    try {
      await _analyticsSubscription?.cancel();
      
      _analyticsSubscription = _analyticsRepository
          .watchAnalyticsData(_currentUserId!)
          .listen(
            (data) => add(AnalyticsDataUpdated(data: data)),
            onError: (error) {
              add(AnalyticsErrorCleared());
            },
          );

      final currentState = state as AnalyticsLoaded;
      emit(currentState.copyWith(isRealTimeEnabled: true));

    } catch (e) {
      emit(AnalyticsError(
        message: '😊 Real-time updates aren\'t working right now, but your data is still here!',
        errorType: AnalyticsErrorType.realtimeError,
        canRetry: true,
      ));
    }
  }

  /// Stop real-time analytics updates
  Future<void> _onAnalyticsRealTimeStopped(
    AnalyticsRealTimeStopped event,
    Emitter<AnalyticsState> emit,
  ) async {
    await _analyticsSubscription?.cancel();
    _analyticsSubscription = null;

    if (state is AnalyticsLoaded) {
      final currentState = state as AnalyticsLoaded;
      emit(currentState.copyWith(isRealTimeEnabled: false));
    }
  }

  /// Handle real-time analytics data updates
  void _onAnalyticsDataUpdated(
    AnalyticsDataUpdated event,
    Emitter<AnalyticsState> emit,
  ) {
    if (state is AnalyticsLoaded) {
      final currentState = state as AnalyticsLoaded;
      
      emit(currentState.copyWith(
        data: event.data.copyWith(lastUpdated: DateTime.now()),
      ));

      // Check for new achievements or completed goals
      _checkForCelebrations(event.data, emit);
    }
  }

  /// Add a new goal with encouraging messages
  Future<void> _onAnalyticsGoalAdded(
    AnalyticsGoalAdded event,
    Emitter<AnalyticsState> emit,
  ) async {
    if (state is! AnalyticsLoaded) return;

    final currentState = state as AnalyticsLoaded;
    
    emit(AnalyticsGoalProcessing(
      currentData: currentState.data,
      message: '🎯 Adding your awesome new goal...',
    ));

    try {
      final result = await _analyticsRepository.addGoal(event.goal);

      result.fold(
        (failure) {
          emit(AnalyticsError(
            message: '😅 Couldn\'t add your goal right now. Let\'s try again!',
            errorType: AnalyticsErrorType.goalError,
            canRetry: true,
          ));
        },
        (addedGoal) {
          final updatedGoals = List<Goal>.from(currentState.data.goals)
            ..add(addedGoal);
          
          final updatedData = currentState.data.copyWith(goals: updatedGoals);
          
          emit(currentState.copyWith(data: updatedData));
          
          // Show success celebration
          add(AnalyticsCelebrationTriggered(
            type: CelebrationType.goalAdded,
            message: '🎉 Awesome! Your new goal is ready to achieve!',
            goal: addedGoal,
          ));
        },
      );

    } catch (e) {
      emit(AnalyticsError(
        message: '😓 Oops! Something went wrong adding your goal.',
        errorType: AnalyticsErrorType.generic,
        canRetry: true,
      ));
    }
  }

  /// Update an existing goal
  Future<void> _onAnalyticsGoalUpdated(
    AnalyticsGoalUpdated event,
    Emitter<AnalyticsState> emit,
  ) async {
    if (state is! AnalyticsLoaded) return;

    final currentState = state as AnalyticsLoaded;
    
    emit(AnalyticsGoalProcessing(
      currentData: currentState.data,
      message: '✏️ Updating your goal...',
    ));

    try {
      final result = await _analyticsRepository.updateGoal(event.goal);

      result.fold(
        (failure) {
          emit(AnalyticsError(
            message: '😅 Couldn\'t update your goal right now.',
            errorType: AnalyticsErrorType.goalError,
            canRetry: true,
          ));
        },
        (updatedGoal) {
          final updatedGoals = currentState.data.goals.map((goal) {
            return goal.id == updatedGoal.id ? updatedGoal : goal;
          }).toList();
          
          final updatedData = currentState.data.copyWith(goals: updatedGoals);
          
          emit(currentState.copyWith(data: updatedData));
          
          // Check if goal was completed
          if (updatedGoal.isCompleted && !event.goal.isCompleted) {
            add(AnalyticsGoalCompleted(goal: updatedGoal));
          }
        },
      );

    } catch (e) {
      emit(AnalyticsError(
        message: '😓 Something went wrong updating your goal.',
        errorType: AnalyticsErrorType.generic,
        canRetry: true,
      ));
    }
  }

  /// Delete a goal
  Future<void> _onAnalyticsGoalDeleted(
    AnalyticsGoalDeleted event,
    Emitter<AnalyticsState> emit,
  ) async {
    if (state is! AnalyticsLoaded) return;

    final currentState = state as AnalyticsLoaded;
    
    try {
      final result = await _analyticsRepository.deleteGoal(event.goalId);

      result.fold(
        (failure) {
          emit(AnalyticsError(
            message: '😅 Couldn\'t remove the goal right now.',
            errorType: AnalyticsErrorType.goalError,
            canRetry: true,
          ));
        },
        (_) {
          final updatedGoals = currentState.data.goals
              .where((goal) => goal.id != event.goalId)
              .toList();
          
          final updatedData = currentState.data.copyWith(goals: updatedGoals);
          
          emit(currentState.copyWith(data: updatedData));
        },
      );

    } catch (e) {
      emit(AnalyticsError(
        message: '😓 Something went wrong removing the goal.',
        errorType: AnalyticsErrorType.generic,
        canRetry: true,
      ));
    }
  }

  /// Celebrate goal completion with fun animations
  void _onAnalyticsGoalCompleted(
    AnalyticsGoalCompleted event,
    Emitter<AnalyticsState> emit,
  ) {
    add(AnalyticsCelebrationTriggered(
      type: CelebrationType.goalCompleted,
      message: '🎊 WOW! You completed your goal "${event.goal.title}"! You\'re amazing!',
      goal: event.goal,
    ));
  }

  /// Trigger celebration animations and messages
  void _onAnalyticsCelebrationTriggered(
    AnalyticsCelebrationTriggered event,
    Emitter<AnalyticsState> emit,
  ) {
    if (state is AnalyticsLoaded) {
      final currentState = state as AnalyticsLoaded;
      
      emit(AnalyticsCelebration(
        currentData: currentState.data,
        celebrationType: event.type,
        message: event.message,
        goal: event.goal,
        achievement: event.achievement,
      ));

      // Auto-dismiss celebration after a few seconds
      Timer(_celebrationDuration, () {
        if (state is AnalyticsCelebration) {
          emit(currentState);
        }
      });
    }
  }

  /// Change analytics filter
  void _onAnalyticsFilterChanged(
    AnalyticsFilterChanged event,
    Emitter<AnalyticsState> emit,
  ) {
    if (state is AnalyticsLoaded) {
      final currentState = state as AnalyticsLoaded;
      emit(currentState.copyWith(selectedFilter: event.filter));
    }
  }

  /// Change time range and reload data
  Future<void> _onAnalyticsTimeRangeChanged(
    AnalyticsTimeRangeChanged event,
    Emitter<AnalyticsState> emit,
  ) async {
    if (_currentUserId == null) return;

    if (state is AnalyticsLoaded) {
      final currentState = state as AnalyticsLoaded;
      emit(currentState.copyWith(timeRange: event.timeRange));
    }

    // Reload data with new time range
    add(AnalyticsLoadRequested(
      userId: _currentUserId!,
      timeRange: event.timeRange,
      forceRefresh: true,
    ));
  }

  /// Reset analytics data
  void _onAnalyticsResetRequested(
    AnalyticsResetRequested event,
    Emitter<AnalyticsState> emit,
  ) {
    _stopAllTimers();
    emit(const AnalyticsInitial());
  }

  /// Clear error state and retry
  void _onAnalyticsErrorCleared(
    AnalyticsErrorCleared event,
    Emitter<AnalyticsState> emit,
  ) {
    if (_currentUserId != null) {
      add(AnalyticsLoadRequested(userId: _currentUserId!));
    } else {
      emit(const AnalyticsInitial());
    }
  }

  // Helper methods for data loading

  Future<Either<Failure, OverviewData>> _loadOverviewData(
    String userId, 
    AnalyticsTimeRange timeRange,
  ) async {
    return _analyticsRepository.getOverviewData(userId, timeRange);
  }

  Future<Either<Failure, ProgressData>> _loadProgressData(
    String userId, 
    AnalyticsTimeRange timeRange,
  ) async {
    return _analyticsRepository.getProgressData(userId, timeRange);
  }

  Future<Either<Failure, List<Goal>>> _loadGoalsData(String userId) async {
    return _analyticsRepository.getUserGoals(userId);
  }

  Future<Either<Failure, List<Achievement>>> _loadAchievementsData(
    String userId, 
    AnalyticsTimeRange timeRange,
  ) async {
    return _analyticsRepository.getAchievements(userId, timeRange);
  }

  Future<Either<Failure, TrendData>> _loadTrendsData(
    String userId, 
    AnalyticsTimeRange timeRange,
  ) async {
    return _analyticsRepository.getTrendData(userId, timeRange);
  }

  /// Start automatic refresh timer
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      add(const AnalyticsRefreshRequested(showLoading: false));
    });
  }

  /// Stop all timers and subscriptions
  void _stopAllTimers() {
    _refreshTimer?.cancel();
    _analyticsSubscription?.cancel();
    _refreshTimer = null;
    _analyticsSubscription = null;
  }

  /// Check for achievements and celebrations
  void _checkForCelebrations(AnalyticsData data, Emitter<AnalyticsState> emit) {
    // Check for completed goals
    final newlyCompletedGoals = data.goals
        .where((goal) => goal.isCompleted && goal.completedAt != null)
        .where((goal) {
          final completedRecently = DateTime.now()
              .difference(goal.completedAt!)
              .inMinutes < 5;
          return completedRecently;
        });

    for (final goal in newlyCompletedGoals) {
      add(AnalyticsGoalCompleted(goal: goal));
    }

    // Check for new achievements
    final recentAchievements = data.achievements
        .where((achievement) {
          final earnedRecently = DateTime.now()
              .difference(achievement.earnedAt)
              .inMinutes < 5;
          return earnedRecently;
        });

    for (final achievement in recentAchievements) {
      add(AnalyticsCelebrationTriggered(
        type: CelebrationType.achievementUnlocked,
        message: '🏆 Amazing! You unlocked "${achievement.title}"!',
        achievement: achievement,
      ));
    }

    // Check for milestone celebrations
    _checkMilestoneCelebrations(data, emit);
  }

  /// Check for milestone celebrations (streaks, point milestones, etc.)
  void _checkMilestoneCelebrations(AnalyticsData data, Emitter<AnalyticsState> emit) {
    final overview = data.overview;
    
    // Celebrate streak milestones
    final streak = overview.currentStreak;
    if (streak > 0 && streak % 7 == 0) {
      add(AnalyticsCelebrationTriggered(
        type: CelebrationType.milestoneReached,
        message: '🔥 Incredible! You have a $streak day streak! Keep it up!',
      ));
    }

    // Celebrate point milestones
    final totalPoints = overview.totalPoints;
    final milestones = [100, 250, 500, 1000, 2500, 5000];
    
    for (final milestone in milestones) {
      if (totalPoints >= milestone && totalPoints < milestone + 50) {
        add(AnalyticsCelebrationTriggered(
          type: CelebrationType.milestoneReached,
          message: '⭐ Fantastic! You reached $milestone points! You\'re doing great!',
        ));
        break;
      }
    }
  }

  @override
  Future<void> close() {
    _stopAllTimers();
    return super.close();
  }
}