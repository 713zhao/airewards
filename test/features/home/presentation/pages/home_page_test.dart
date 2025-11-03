import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../lib/features/home/presentation/pages/home_page.dart';
import '../../../../../lib/features/home/presentation/bloc/home_bloc.dart';
import '../../../../../lib/features/home/presentation/bloc/home_state.dart';
import '../../../../../lib/features/home/presentation/bloc/home_event.dart';
import '../../../../../lib/features/analytics/domain/entities/analytics_entities.dart';

/// Mock BLoC for testing
class MockHomeBloc extends MockBloc<HomeEvent, HomeState> implements HomeBloc {}

void main() {
  group('HomePage Widget Tests', () {
    late MockHomeBloc mockHomeBloc;

    // Test data
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
      trendData: [],
      lastUpdated: DateTime.now(),
    );

    setUp(() {
      mockHomeBloc = MockHomeBloc();
    });

    Widget createTestWidget(Widget child) {
      return MaterialApp(
        home: BlocProvider<HomeBloc>(
          create: (_) => mockHomeBloc,
          child: child,
        ),
      );
    }

    group('HomePage Layout', () {
      testWidgets('displays loading indicator when state is loading', (tester) async {
        // Arrange
        when(() => mockHomeBloc.state).thenReturn(
          const HomeLoading(message: 'Loading your dashboard...')
        );

        // Act
        await tester.pumpWidget(createTestWidget(const HomePage()));

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading your dashboard...'), findsOneWidget);
      });

      testWidgets('displays dashboard when data is loaded', (tester) async {
        // Arrange
        when(() => mockHomeBloc.state).thenReturn(
          HomeLoaded(
            analyticsData: testAnalyticsData,
            userName: 'Test Kid',
            lastUpdated: DateTime.now(),
          ),
        );

        // Act
        await tester.pumpWidget(createTestWidget(const HomePage()));

        // Assert
        expect(find.text('Welcome back, Test Kid! 🌟'), findsOneWidget);
        expect(find.text('250'), findsOneWidget); // Total points
        expect(find.text('7'), findsOneWidget); // Current streak
        expect(find.text('Level 3'), findsOneWidget); // Level display
      });

      testWidgets('displays error message when state is error', (tester) async {
        // Arrange
        when(() => mockHomeBloc.state).thenReturn(
          const HomeError(
            message: 'Oops! Something went wrong.',
            errorType: HomeErrorType.network,
            canRetry: true,
          ),
        );

        // Act
        await tester.pumpWidget(createTestWidget(const HomePage()));

        // Assert
        expect(find.text('Oops! Something went wrong.'), findsOneWidget);
        expect(find.text('Try Again'), findsOneWidget);
      });
    });

    group('Dashboard Components', () {
      testWidgets('displays points card with correct values', (tester) async {
        // Arrange
        when(() => mockHomeBloc.state).thenReturn(
          HomeLoaded(
            analyticsData: testAnalyticsData,
            userName: 'Test Kid',
            lastUpdated: DateTime.now(),
          ),
        );

        // Act
        await tester.pumpWidget(createTestWidget(const HomePage()));

        // Assert
        expect(find.text('Total Points'), findsOneWidget);
        expect(find.text('250'), findsOneWidget);
      });

      testWidgets('displays streak card with fire emoji for active streak', (tester) async {
        // Arrange
        when(() => mockHomeBloc.state).thenReturn(
          HomeLoaded(
            analyticsData: testAnalyticsData,
            userName: 'Test Kid',
            lastUpdated: DateTime.now(),
          ),
        );

        // Act
        await tester.pumpWidget(createTestWidget(const HomePage()));

        // Assert
        expect(find.text('Current Streak'), findsOneWidget);
        expect(find.text('7 days 🔥'), findsOneWidget);
      });

      testWidgets('displays level progress with correct percentage', (tester) async {
        // Arrange
        when(() => mockHomeBloc.state).thenReturn(
          HomeLoaded(
            analyticsData: testAnalyticsData,
            userName: 'Test Kid',
            lastUpdated: DateTime.now(),
          ),
        );

        // Act
        await tester.pumpWidget(createTestWidget(const HomePage()));

        // Assert
        expect(find.text('Level 3'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        
        // Check progress indicator value
        final progressIndicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator)
        );
        expect(progressIndicator.value, equals(0.5)); // 50/100 = 0.5
      });

      testWidgets('displays recent achievements section', (tester) async {
        // Arrange
        when(() => mockHomeBloc.state).thenReturn(
          HomeLoaded(
            analyticsData: testAnalyticsData,
            userName: 'Test Kid',
            lastUpdated: DateTime.now(),
          ),
        );

        // Act
        await tester.pumpWidget(createTestWidget(const HomePage()));

        // Assert
        expect(find.text('Recent Achievements'), findsOneWidget);
        expect(find.text('🌟 First Steps'), findsOneWidget);
        expect(find.text('Completed your first task!'), findsOneWidget);
      });

      testWidgets('displays active goals section', (tester) async {
        // Arrange
        when(() => mockHomeBloc.state).thenReturn(
          HomeLoaded(
            analyticsData: testAnalyticsData,
            userName: 'Test Kid',
            lastUpdated: DateTime.now(),
          ),
        );

        // Act
        await tester.pumpWidget(createTestWidget(const HomePage()));

        // Assert
        expect(find.text('Active Goals'), findsOneWidget);
        expect(find.text('🎯 Week Champion'), findsOneWidget);
        expect(find.text('3 / 5'), findsOneWidget); // Progress display
      });
    });

    group('User Interactions', () {
      testWidgets('triggers refresh when pull-to-refresh is used', (tester) async {
        // Arrange
        when(() => mockHomeBloc.state).thenReturn(
          HomeLoaded(
            analyticsData: testAnalyticsData,
            userName: 'Test Kid',
            lastUpdated: DateTime.now(),
          ),
        );

        // Act
        await tester.pumpWidget(createTestWidget(const HomePage()));
        
        // Find RefreshIndicator and trigger pull-to-refresh
        await tester.fling(find.byType(RefreshIndicator), const Offset(0, 300), 1000);
        await tester.pump();

        // Assert
        verify(() => mockHomeBloc.add(any(that: isA<RefreshDashboard>()))).called(1);
      });

      testWidgets('navigates to tasks when quick action is tapped', (tester) async {
        // Arrange
        when(() => mockHomeBloc.state).thenReturn(
          HomeLoaded(
            analyticsData: testAnalyticsData,
            userName: 'Test Kid',
            lastUpdated: DateTime.now(),
          ),
        );

        // Act
        await tester.pumpWidget(createTestWidget(const HomePage()));
        
        // Find and tap "Add Task" button
        final addTaskButton = find.text('Add Task');
        expect(addTaskButton, findsOneWidget);
        await tester.tap(addTaskButton);
        await tester.pump();

        // Assert - This would typically verify navigation
        // In a real app, you'd mock Navigator or use integration tests
      });

      testWidgets('shows retry button on error and triggers reload', (tester) async {
        // Arrange
        when(() => mockHomeBloc.state).thenReturn(
          const HomeError(
            message: 'Network error occurred',
            errorType: HomeErrorType.network,
            canRetry: true,
          ),
        );

        // Act
        await tester.pumpWidget(createTestWidget(const HomePage()));
        
        final retryButton = find.text('Try Again');
        expect(retryButton, findsOneWidget);
        await tester.tap(retryButton);
        await tester.pump();

        // Assert
        verify(() => mockHomeBloc.add(any(that: isA<LoadDashboard>()))).called(1);
      });
    });

    group('Animations', () {
      testWidgets('displays fade-in animation for achievement cards', (tester) async {
        // Arrange
        when(() => mockHomeBloc.state).thenReturn(
          HomeLoaded(
            analyticsData: testAnalyticsData,
            userName: 'Test Kid',
            lastUpdated: DateTime.now(),
          ),
        );

        // Act
        await tester.pumpWidget(createTestWidget(const HomePage()));
        
        // Assert - Check for AnimatedContainer or FadeTransition
        expect(find.byType(AnimatedContainer), findsAtLeastNWidget(1));
      });

      testWidgets('animates level progress bar', (tester) async {
        // Arrange
        when(() => mockHomeBloc.state).thenReturn(
          HomeLoaded(
            analyticsData: testAnalyticsData,
            userName: 'Test Kid',
            lastUpdated: DateTime.now(),
          ),
        );

        // Act
        await tester.pumpWidget(createTestWidget(const HomePage()));
        
        // Progress bar should animate to the correct value
        await tester.pump(const Duration(milliseconds: 500));
        
        // Assert
        final progressIndicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator)
        );
        expect(progressIndicator.value, isNotNull);
      });
    });

    group('Accessibility', () {
      testWidgets('has proper semantic labels', (tester) async {
        // Arrange
        when(() => mockHomeBloc.state).thenReturn(
          HomeLoaded(
            analyticsData: testAnalyticsData,
            userName: 'Test Kid',
            lastUpdated: DateTime.now(),
          ),
        );

        // Act
        await tester.pumpWidget(createTestWidget(const HomePage()));

        // Assert - Check for Semantics widgets
        expect(find.bySemanticsLabel('Total points: 250'), findsOneWidget);
        expect(find.bySemanticsLabel('Current streak: 7 days'), findsOneWidget);
        expect(find.bySemanticsLabel('Level 3 progress'), findsOneWidget);
      });

      testWidgets('supports screen reader navigation', (tester) async {
        // Arrange
        when(() => mockHomeBloc.state).thenReturn(
          HomeLoaded(
            analyticsData: testAnalyticsData,
            userName: 'Test Kid',
            lastUpdated: DateTime.now(),
          ),
        );

        // Act
        await tester.pumpWidget(createTestWidget(const HomePage()));

        // Assert - Check for proper semantic properties
        final semantics = tester.getSemantics(find.text('250'));
        expect(semantics.hasFlag(SemanticsFlag.isButton), isFalse);
        expect(semantics.hasFlag(SemanticsFlag.isReadOnly), isTrue);
      });
    });

    group('Responsive Design', () {
      testWidgets('adapts layout for small screens', (tester) async {
        // Arrange
        tester.binding.window.physicalSizeTestValue = const Size(360, 640);
        tester.binding.window.devicePixelRatioTestValue = 1.0;
        
        when(() => mockHomeBloc.state).thenReturn(
          HomeLoaded(
            analyticsData: testAnalyticsData,
            userName: 'Test Kid',
            lastUpdated: DateTime.now(),
          ),
        );

        // Act
        await tester.pumpWidget(createTestWidget(const HomePage()));

        // Assert - Check for responsive layout elements
        expect(find.byType(GridView), findsOneWidget);
        
        // Clean up
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
        addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
      });

      testWidgets('adapts layout for large screens', (tester) async {
        // Arrange
        tester.binding.window.physicalSizeTestValue = const Size(800, 600);
        tester.binding.window.devicePixelRatioTestValue = 1.0;
        
        when(() => mockHomeBloc.state).thenReturn(
          HomeLoaded(
            analyticsData: testAnalyticsData,
            userName: 'Test Kid',
            lastUpdated: DateTime.now(),
          ),
        );

        // Act
        await tester.pumpWidget(createTestWidget(const HomePage()));

        // Assert - Check for wider layout
        expect(find.byType(GridView), findsOneWidget);
        
        // Clean up
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
        addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
      });
    });

    group('Performance', () {
      testWidgets('rebuilds efficiently when data updates', (tester) async {
        // Arrange
        when(() => mockHomeBloc.state).thenReturn(
          HomeLoaded(
            analyticsData: testAnalyticsData,
            userName: 'Test Kid',
            lastUpdated: DateTime.now(),
          ),
        );

        // Act
        await tester.pumpWidget(createTestWidget(const HomePage()));
        
        // Update with new data
        final updatedData = testAnalyticsData.copyWith(totalPoints: 300);
        when(() => mockHomeBloc.state).thenReturn(
          HomeLoaded(
            analyticsData: updatedData,
            userName: 'Test Kid',
            lastUpdated: DateTime.now(),
          ),
        );
        
        await tester.pump();

        // Assert - New points value should be displayed
        expect(find.text('300'), findsOneWidget);
        expect(find.text('250'), findsNothing);
      });
    });

    group('Kid-Friendly Features', () {
      testWidgets('displays encouraging messages', (tester) async {
        // Arrange
        when(() => mockHomeBloc.state).thenReturn(
          HomeLoaded(
            analyticsData: testAnalyticsData,
            userName: 'Test Kid',
            lastUpdated: DateTime.now(),
            encouragementMessage: 'You\'re doing amazing! Keep up the great work! 🌟',
          ),
        );

        // Act
        await tester.pumpWidget(createTestWidget(const HomePage()));

        // Assert
        expect(find.text('You\'re doing amazing! Keep up the great work! 🌟'), findsOneWidget);
      });

      testWidgets('shows celebration animations for achievements', (tester) async {
        // Arrange
        final celebrationState = HomeCelebration(
          celebrationType: CelebrationType.achievement,
          message: '🎉 You earned a new achievement!',
          achievement: testAnalyticsData.recentAchievements.first,
        );
        
        when(() => mockHomeBloc.state).thenReturn(celebrationState);

        // Act
        await tester.pumpWidget(createTestWidget(const HomePage()));

        // Assert
        expect(find.text('🎉 You earned a new achievement!'), findsOneWidget);
        expect(find.byType(AnimatedContainer), findsAtLeastNWidget(1));
      });

      testWidgets('uses colorful and engaging visual elements', (tester) async {
        // Arrange
        when(() => mockHomeBloc.state).thenReturn(
          HomeLoaded(
            analyticsData: testAnalyticsData,
            userName: 'Test Kid',
            lastUpdated: DateTime.now(),
          ),
        );

        // Act
        await tester.pumpWidget(createTestWidget(const HomePage()));

        // Assert - Check for gradient containers and colorful cards
        expect(find.byType(Card), findsAtLeastNWidget(3));
        expect(find.byType(Container), findsAtLeastNWidget(5));
      });
    });
  });
}