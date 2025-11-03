import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../lib/core/errors/failures.dart';
import '../../../../../lib/core/utils/either.dart';
import '../../../../../lib/features/analytics/domain/entities/analytics_entities.dart';
import '../../../../../lib/features/analytics/domain/repositories/analytics_repository.dart';
import '../../../../../lib/features/analytics/presentation/bloc/analytics_bloc.dart';
import '../../../../../lib/features/analytics/presentation/bloc/analytics_event.dart';
import '../../../../../lib/features/analytics/presentation/bloc/analytics_state.dart';

/// Mock repository for testing
class MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

void main() {
  group('AnalyticsBloc', () {
    late AnalyticsBloc analyticsBloc;
    late MockAnalyticsRepository mockRepository;

    // Test data
    final testUserId = 'test_user_123';
    final testAnalyticsData = AnalyticsData(
      totalPoints: 250,
      currentStreak: 7,
      longestStreak: 15,
      totalActivities: 42,
      completedGoals: 8,
      level: 3,
      experiencePoints: 50,
      weeklyProgress: 75.5,
      monthlyGrowth: 12.3,
      categoryBreakdown: {
        'Learning': 35,
        'Chores': 25,
        'Reading': 20,
        'Exercise': 15,
        'Creativity': 5,
      },
      recentAchievements: [
        Achievement(
          id: 'ach_1',
          title: '🌟 First Steps',
          description: 'Completed your first task!',
          icon: 'star',
          color: '#FFD700',
          unlockedAt: DateTime.now().subtract(const Duration(days: 1)),
          category: 'milestone',
          tier: AchievementTier.bronze,
          points: 10,
          isNew: false,
        ),
      ],
      activeGoals: [
        Goal(
          id: 'goal_1',
          title: '🎯 Week Champion',
          description: 'Complete 5 tasks this week',
          targetValue: 5,
          currentProgress: 3,
          category: 'weekly',
          priority: GoalPriority.medium,
          deadline: DateTime.now().add(const Duration(days: 4)),
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          isCompleted: false,
          celebrationMessage: 'Amazing work this week!',
        ),
      ],
      trendData: [
        TrendData(
          date: DateTime.now().subtract(const Duration(days: 6)),
          value: 20,
          category: 'points',
        ),
        TrendData(
          date: DateTime.now().subtract(const Duration(days: 5)),
          value: 35,
          category: 'points',
        ),
        TrendData(
          date: DateTime.now().subtract(const Duration(days: 4)),
          value: 42,
          category: 'points',
        ),
      ],
      lastUpdated: DateTime.now(),
    );

    final testGoal = Goal(
      id: 'new_goal_123',
      title: '🏃‍♀️ Daily Runner',
      description: 'Exercise for 30 minutes',
      targetValue: 1,
      currentProgress: 0,
      category: 'daily',
      priority: GoalPriority.high,
      deadline: DateTime.now().add(const Duration(hours: 12)),
      createdAt: DateTime.now(),
      isCompleted: false,
      celebrationMessage: 'You\'re a fitness superstar!',
    );

    setUp(() {
      mockRepository = MockAnalyticsRepository();
      analyticsBloc = AnalyticsBloc(mockRepository);
    });

    tearDown(() {
      analyticsBloc.close();
    });

    test('initial state is AnalyticsInitial', () {
      expect(analyticsBloc.state, equals(const AnalyticsInitial()));
    });

    group('LoadAnalyticsData', () {
      blocTest<AnalyticsBloc, AnalyticsState>(
        'emits [loading, loaded] when data is loaded successfully',
        build: () {
          when(() => mockRepository.getAnalyticsData(any(), any()))
              .thenAnswer((_) async => Right(testAnalyticsData));
          return analyticsBloc;
        },
        act: (bloc) => bloc.add(LoadAnalyticsData(
          userId: testUserId,
          timeRange: TimeRange.week,
        )),
        expect: () => [
          const AnalyticsLoading(
            message: '📊 Loading your awesome progress...',
            loadingType: AnalyticsLoadingType.dataLoad,
          ),
          AnalyticsLoaded(
            data: testAnalyticsData,
            timeRange: TimeRange.week,
            lastUpdated: DateTime.now(),
            insights: isA<List<AnalyticsInsight>>(),
          ),
        ],
      );

      blocTest<AnalyticsBloc, AnalyticsState>(
        'emits [loading, error] when data loading fails',
        build: () {
          when(() => mockRepository.getAnalyticsData(any(), any()))
              .thenAnswer((_) async => Left(NetworkFailure('Connection failed')));
          return analyticsBloc;
        },
        act: (bloc) => bloc.add(LoadAnalyticsData(
          userId: testUserId,
          timeRange: TimeRange.week,
        )),
        expect: () => [
          const AnalyticsLoading(
            message: '📊 Loading your awesome progress...',
            loadingType: AnalyticsLoadingType.dataLoad,
          ),
          const AnalyticsError(
            message: '🌐 Oops! Having trouble connecting. Let\'s try again in a moment!',
            errorType: AnalyticsErrorType.network,
            canRetry: true,
          ),
        ],
      );
    });

    group('RefreshAnalytics', () {
      blocTest<AnalyticsBloc, AnalyticsState>(
        'refreshes data when already loaded',
        build: () {
          when(() => mockRepository.getAnalyticsData(any(), any()))
              .thenAnswer((_) async => Right(testAnalyticsData));
          return analyticsBloc;
        },
        seed: () => AnalyticsLoaded(
          data: testAnalyticsData,
          timeRange: TimeRange.week,
          lastUpdated: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        act: (bloc) => bloc.add(RefreshAnalytics(userId: testUserId)),
        expect: () => [
          AnalyticsRefreshing(
            currentData: testAnalyticsData,
            message: '🔄 Updating your latest achievements...',
          ),
          AnalyticsLoaded(
            data: testAnalyticsData,
            timeRange: TimeRange.week,
            lastUpdated: isA<DateTime>(),
            insights: isA<List<AnalyticsInsight>>(),
          ),
        ],
      );
    });

    group('CreateGoal', () {
      blocTest<AnalyticsBloc, AnalyticsState>(
        'emits [goalCreating, goalCreated] when goal is created successfully',
        build: () {
          when(() => mockRepository.createGoal(any(), any()))
              .thenAnswer((_) async => Right(testGoal));
          return analyticsBloc;
        },
        act: (bloc) => bloc.add(CreateGoal(
          userId: testUserId,
          goalData: {
            'title': testGoal.title,
            'description': testGoal.description,
            'category': testGoal.category,
            'targetValue': testGoal.targetValue,
            'priority': testGoal.priority.name,
            'deadline': testGoal.deadline.toIso8601String(),
          },
        )),
        expect: () => [
          const GoalCreating(
            message: '🎯 Creating your awesome new goal...',
          ),
          GoalCreated(
            goal: testGoal,
            celebrationMessage: '🎉 Amazing! Your new goal "${testGoal.title}" is ready!',
          ),
        ],
      );

      blocTest<AnalyticsBloc, AnalyticsState>(
        'emits [goalCreating, error] when goal creation fails with validation error',
        build: () {
          when(() => mockRepository.createGoal(any(), any()))
              .thenAnswer((_) async => Left(ValidationFailure('Title is required')));
          return analyticsBloc;
        },
        act: (bloc) => bloc.add(CreateGoal(
          userId: testUserId,
          goalData: {
            'title': '',
            'description': 'Empty title test',
          },
        )),
        expect: () => [
          const GoalCreating(
            message: '🎯 Creating your awesome new goal...',
          ),
          const AnalyticsError(
            message: '📝 Hmm, something needs to be fixed before we can continue.',
            errorType: AnalyticsErrorType.validation,
            canRetry: false,
            details: 'Title is required',
          ),
        ],
      );
    });

    group('UpdateGoalProgress', () {
      blocTest<AnalyticsBloc, AnalyticsState>(
        'emits celebration when goal is completed',
        build: () {
          final completedGoal = testGoal.copyWith(
            currentProgress: testGoal.targetValue,
            isCompleted: true,
          );
          when(() => mockRepository.updateGoalProgress(any(), any(), any()))
              .thenAnswer((_) async => Right(completedGoal));
          return analyticsBloc;
        },
        act: (bloc) => bloc.add(UpdateGoalProgress(
          userId: testUserId,
          goalId: testGoal.id,
          newProgress: testGoal.targetValue,
        )),
        expect: () => [
          const GoalUpdating(
            message: '📈 Updating your amazing progress...',
          ),
          GoalCompleted(
            goal: testGoal.copyWith(
              currentProgress: testGoal.targetValue,
              isCompleted: true,
            ),
            celebrationMessage: '🎉 Incredible! You completed "${testGoal.title}"!',
            pointsEarned: 50,
            newAchievements: const [],
          ),
        ],
      );

      blocTest<AnalyticsBloc, AnalyticsState>(
        'emits progress update for partial completion',
        build: () {
          final updatedGoal = testGoal.copyWith(currentProgress: 2);
          when(() => mockRepository.updateGoalProgress(any(), any(), any()))
              .thenAnswer((_) async => Right(updatedGoal));
          return analyticsBloc;
        },
        act: (bloc) => bloc.add(UpdateGoalProgress(
          userId: testUserId,
          goalId: testGoal.id,
          newProgress: 2,
        )),
        expect: () => [
          const GoalUpdating(
            message: '📈 Updating your amazing progress...',
          ),
          GoalProgressUpdated(
            goal: testGoal.copyWith(currentProgress: 2),
            progressMessage: '🌟 Great job! You\'re making awesome progress!',
          ),
        ],
      );
    });

    group('ExportAnalyticsData', () {
      blocTest<AnalyticsBloc, AnalyticsState>(
        'emits [exporting, exportReady] when export is successful',
        build: () {
          when(() => mockRepository.exportData(any(), any()))
              .thenAnswer((_) async => const Right('analytics_export.json'));
          return analyticsBloc;
        },
        act: (bloc) => bloc.add(ExportAnalyticsData(
          userId: testUserId,
          format: ExportFormat.json,
        )),
        expect: () => [
          const DataExporting(
            format: ExportFormat.json,
            progress: 0,
            message: '📦 Preparing your data for download...',
          ),
          const DataExportReady(
            filePath: 'analytics_export.json',
            format: ExportFormat.json,
            message: '✅ Your data is ready! Check your downloads.',
          ),
        ],
      );
    });

    group('TimeRange Changes', () {
      blocTest<AnalyticsBloc, AnalyticsState>(
        'updates time range and reloads data',
        build: () {
          when(() => mockRepository.getAnalyticsData(any(), any()))
              .thenAnswer((_) async => Right(testAnalyticsData));
          return analyticsBloc;
        },
        seed: () => AnalyticsLoaded(
          data: testAnalyticsData,
          timeRange: TimeRange.week,
          lastUpdated: DateTime.now(),
        ),
        act: (bloc) => bloc.add(ChangeTimeRange(
          userId: testUserId,
          newTimeRange: TimeRange.month,
        )),
        expect: () => [
          const AnalyticsLoading(
            message: '📊 Loading monthly view...',
            loadingType: AnalyticsLoadingType.timeRangeChange,
          ),
          AnalyticsLoaded(
            data: testAnalyticsData,
            timeRange: TimeRange.month,
            lastUpdated: isA<DateTime>(),
            insights: isA<List<AnalyticsInsight>>(),
          ),
        ],
      );
    });

    group('Achievement Processing', () {
      blocTest<AnalyticsBloc, AnalyticsState>(
        'processes new achievements with celebration',
        build: () => analyticsBloc,
        act: (bloc) {
          final newAchievement = Achievement(
            id: 'ach_new',
            title: '🔥 Streak Master',
            description: 'Maintained a 7-day streak!',
            icon: 'local_fire_department',
            color: '#FF6347',
            unlockedAt: DateTime.now(),
            category: 'streak',
            tier: AchievementTier.silver,
            points: 25,
            isNew: true,
          );
          bloc.add(ProcessNewAchievement(achievement: newAchievement));
        },
        expect: () => [
          isA<AchievementUnlocked>()
              .having((state) => state.achievement.title, 'title', '🔥 Streak Master')
              .having((state) => state.celebrationMessage, 'message', 
                      contains('Congratulations! You unlocked')),
        ],
      );
    });

    group('Error Handling', () {
      blocTest<AnalyticsBloc, AnalyticsState>(
        'maps different failures to appropriate error states',
        build: () {
          when(() => mockRepository.getAnalyticsData(any(), any()))
              .thenAnswer((_) async => Left(DatabaseFailure('DB error')));
          return analyticsBloc;
        },
        act: (bloc) => bloc.add(LoadAnalyticsData(
          userId: testUserId,
          timeRange: TimeRange.week,
        )),
        expect: () => [
          const AnalyticsLoading(
            message: '📊 Loading your awesome progress...',
            loadingType: AnalyticsLoadingType.dataLoad,
          ),
          const AnalyticsError(
            message: '😅 Something unexpected happened. Don\'t worry, we\'ll figure it out!',
            errorType: AnalyticsErrorType.generic,
            canRetry: true,
            details: 'DB error',
          ),
        ],
      );
    });

    group('Real-time Updates', () {
      blocTest<AnalyticsBloc, AnalyticsState>(
        'handles real-time data updates',
        build: () => analyticsBloc,
        seed: () => AnalyticsLoaded(
          data: testAnalyticsData,
          timeRange: TimeRange.week,
          lastUpdated: DateTime.now(),
        ),
        act: (bloc) {
          final updatedData = testAnalyticsData.copyWith(
            totalPoints: testAnalyticsData.totalPoints + 50,
            currentStreak: testAnalyticsData.currentStreak + 1,
          );
          bloc.add(AnalyticsDataUpdated(data: updatedData));
        },
        expect: () => [
          isA<AnalyticsLoaded>()
              .having((state) => state.data.totalPoints, 'points', 300)
              .having((state) => state.data.currentStreak, 'streak', 8),
        ],
      );
    });

    group('Cache Management', () {
      blocTest<AnalyticsBloc, AnalyticsState>(
        'clears cache and reloads data',
        build: () {
          when(() => mockRepository.clearCache())
              .thenAnswer((_) async => const Right(null));
          when(() => mockRepository.getAnalyticsData(any(), any()))
              .thenAnswer((_) async => Right(testAnalyticsData));
          return analyticsBloc;
        },
        act: (bloc) => bloc.add(ClearAnalyticsCache(userId: testUserId)),
        expect: () => [
          const AnalyticsLoading(
            message: '🧹 Clearing cache and refreshing...',
            loadingType: AnalyticsLoadingType.cacheRefresh,
          ),
          AnalyticsLoaded(
            data: testAnalyticsData,
            timeRange: TimeRange.week,
            lastUpdated: isA<DateTime>(),
            insights: isA<List<AnalyticsInsight>>(),
          ),
        ],
      );
    });
  });
}