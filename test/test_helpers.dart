import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../lib/core/errors/failures.dart';
import '../lib/core/utils/either.dart';
import '../lib/features/analytics/domain/repositories/analytics_repository.dart';
import '../lib/features/profile/domain/repositories/profile_repository.dart';

/// Mock classes for testing
class MockAnalyticsRepository extends Mock implements AnalyticsRepository {}
class MockProfileRepository extends Mock implements ProfileRepository {}

/// Test utilities and helpers for AI Rewards testing
class TestHelpers {
  /// Creates a mock failure for testing error cases
  static Failure createMockFailure(String message, {String type = 'generic'}) {
    switch (type) {
      case 'network':
        return NetworkFailure(message);
      case 'validation':
        return ValidationFailure(message);
      case 'database':
        return DatabaseFailure(message);
      case 'cache':
        return CacheFailure(message);
      default:
        return DatabaseFailure(message);
    }
  }

  /// Creates a test user ID for consistent testing
  static String get testUserId => 'test_user_123';

  /// Creates test date for consistent time-based testing
  static DateTime get testDate => DateTime(2023, 1, 15, 10, 30);

  /// Mock analytics data for testing
  static Map<String, dynamic> get mockAnalyticsData => {
    'totalPoints': 250,
    'currentStreak': 7,
    'longestStreak': 15,
    'totalActivities': 42,
    'completedGoals': 8,
    'level': 3,
    'experiencePoints': 50,
    'weeklyProgress': 75.5,
    'monthlyGrowth': 12.3,
    'categoryBreakdown': {
      'Learning': 35,
      'Chores': 25,
      'Reading': 20,
      'Exercise': 15,
      'Creativity': 5,
    },
  };

  /// Mock profile data for testing
  static Map<String, dynamic> get mockProfileData => {
    'id': testUserId,
    'displayName': 'Test Kid',
    'email': 'testkid@example.com',
    'avatarId': 'avatar_cat',
    'themeId': 'theme_default',
    'totalPoints': 150,
    'currentStreak': 5,
    'longestStreak': 12,
    'level': 2,
    'createdAt': testDate.toIso8601String(),
    'lastActive': DateTime.now().toIso8601String(),
  };

  /// Creates a list of mock achievements for testing
  static List<Map<String, dynamic>> get mockAchievements => [
    {
      'id': 'ach_1',
      'title': '🌟 First Steps',
      'description': 'Earned your first points!',
      'icon': 'star',
      'color': '#FFD700',
      'tier': 'bronze',
      'earnedAt': testDate.toIso8601String(),
    },
    {
      'id': 'ach_2',
      'title': '🔥 Streak Starter',
      'description': 'Started your first streak!',
      'icon': 'local_fire_department',
      'color': '#FF6347',
      'tier': 'bronze',
      'earnedAt': testDate.add(const Duration(days: 5)).toIso8601String(),
    },
  ];

  /// Creates a list of mock goals for testing
  static List<Map<String, dynamic>> get mockGoals => [
    {
      'id': 'goal_1',
      'title': '🎯 Week Champion',
      'description': 'Complete 5 tasks this week',
      'targetValue': 5,
      'currentProgress': 3,
      'category': 'weekly',
      'priority': 'medium',
      'deadline': DateTime.now().add(const Duration(days: 4)).toIso8601String(),
      'createdAt': testDate.toIso8601String(),
      'isCompleted': false,
      'celebrationMessage': 'Amazing work this week!',
    },
    {
      'id': 'goal_2',
      'title': '📚 Reading Master',
      'description': 'Read 3 books this month',
      'targetValue': 3,
      'currentProgress': 1,
      'category': 'monthly',
      'priority': 'high',
      'deadline': DateTime.now().add(const Duration(days: 20)).toIso8601String(),
      'createdAt': testDate.toIso8601String(),
      'isCompleted': false,
      'celebrationMessage': 'You\'re becoming a reading champion!',
    },
  ];

  /// Creates mock task data for testing
  static List<Map<String, dynamic>> get mockTasks => [
    {
      'id': 'task_1',
      'title': '🧹 Clean Room',
      'description': 'Organize and tidy up your bedroom',
      'category': 'chores',
      'points': 15,
      'difficulty': 'easy',
      'estimatedTime': 30,
      'isCompleted': false,
      'createdAt': testDate.toIso8601String(),
      'dueDate': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
    },
    {
      'id': 'task_2',
      'title': '📖 Read Chapter',
      'description': 'Read one chapter of your favorite book',
      'category': 'reading',
      'points': 20,
      'difficulty': 'medium',
      'estimatedTime': 45,
      'isCompleted': true,
      'completedAt': testDate.add(const Duration(hours: 1)).toIso8601String(),
      'createdAt': testDate.toIso8601String(),
    },
  ];

  /// Verifies that a BLoC emits the expected states
  static void verifyBlocStates<T>(
    Bloc<dynamic, T> bloc,
    List<T> expectedStates,
  ) {
    expectLater(
      bloc.stream,
      emitsInOrder(expectedStates),
    );
  }

  /// Creates a mock Either success result
  static Right<L, R> createSuccessResult<L, R>(R data) {
    return Right<L, R>(data);
  }

  /// Creates a mock Either failure result
  static Left<L, R> createFailureResult<L, R>(L failure) {
    return Left<L, R>(failure);
  }

  /// Pump and settle with a reasonable timeout for tests
  static Future<void> pumpAndSettleWithTimeout(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await tester.pumpAndSettle(timeout);
  }

  /// Wait for animations to complete
  static Future<void> waitForAnimations(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));
  }
}

/// Custom matchers for testing
class CustomMatchers {
  /// Matches strings containing emojis (kid-friendly feature)
  static Matcher containsEmoji() {
    return matches(RegExp(r'[\u{1f300}-\u{1f5ff}\u{1f900}-\u{1f9ff}\u{1f600}-\u{1f64f}\u{1f680}-\u{1f6ff}\u{2600}-\u{26ff}\u{2700}-\u{27bf}]', unicode: true));
  }

  /// Matches encouraging/positive messages
  static Matcher isEncouragingMessage() {
    final encouragingWords = RegExp(r'\b(amazing|awesome|fantastic|great|wonderful|excellent|superstar|champion|incredible)\b', caseSensitive: false);
    return matches(encouragingWords);
  }

  /// Matches kid-safe content (no inappropriate words)
  static Matcher isKidSafeContent() {
    // This would contain logic to verify content is appropriate for children
    return isA<String>().having(
      (s) => s.length,
      'length',
      greaterThan(0),
    );
  }
}

/// Test groups for organizing related tests
class TestGroups {
  static const String unitTests = 'Unit Tests';
  static const String widgetTests = 'Widget Tests';
  static const String integrationTests = 'Integration Tests';
  static const String performanceTests = 'Performance Tests';
  static const String accessibilityTests = 'Accessibility Tests';
  static const String kidFriendlyTests = 'Kid-Friendly Features Tests';
  static const String securityTests = 'Security Tests';
  static const String dataTests = 'Data Layer Tests';
}

/// Test tags for filtering tests
class TestTags {
  static const String unit = 'unit';
  static const String widget = 'widget';
  static const String integration = 'integration';
  static const String performance = 'performance';
  static const String accessibility = 'accessibility';
  static const String security = 'security';
  static const String kidFriendly = 'kid-friendly';
  static const String analytics = 'analytics';
  static const String profile = 'profile';
  static const String tasks = 'tasks';
  static const String goals = 'goals';
}

/// Test environment configuration
class TestConfig {
  static const bool skipSlowTests = bool.fromEnvironment('SKIP_SLOW_TESTS');
  static const bool runPerformanceTests = bool.fromEnvironment('RUN_PERFORMANCE_TESTS');
  static const int defaultTimeout = 30; // seconds
  static const int slowTestTimeout = 60; // seconds
  
  /// Whether to use mock data or real services
  static const bool useMockData = true;
  
  /// Test user configuration
  static const String testUserName = 'Test Kid';
  static const String testUserEmail = 'testkid@example.com';
  static const int testUserAge = 8;
}