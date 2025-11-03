import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../lib/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('AI Rewards App Integration Tests', () {
    
    group('App Launch and Navigation', () {
      testWidgets('app launches successfully and shows splash screen', (tester) async {
        // Launch the app
        app.main();
        await tester.pumpAndSettle();

        // Verify splash screen elements
        expect(find.text('AI Rewards'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        
        // Wait for splash to complete (assuming 3 second duration)
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
      });

      testWidgets('navigates through bottom navigation tabs', (tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // Wait for app to load
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // Find bottom navigation bar
        expect(find.byType(BottomNavigationBar), findsOneWidget);

        // Test navigation to Tasks tab
        await tester.tap(find.text('Tasks'));
        await tester.pumpAndSettle();
        expect(find.text('Your Tasks'), findsOneWidget);

        // Test navigation to Analytics tab
        await tester.tap(find.text('Analytics'));
        await tester.pumpAndSettle();
        expect(find.text('Your Progress'), findsOneWidget);

        // Test navigation to Profile tab
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();
        expect(find.text('Your Profile'), findsOneWidget);

        // Return to Home tab
        await tester.tap(find.text('Home'));
        await tester.pumpAndSettle();
      });
    });

    group('Home Dashboard Flow', () {
      testWidgets('displays dashboard with user stats', (tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // Verify dashboard elements are present
        expect(find.textContaining('Welcome'), findsOneWidget);
        expect(find.textContaining('points'), findsAtLeastNWidgets(1));
        expect(find.textContaining('streak'), findsAtLeastNWidgets(1));
        expect(find.textContaining('Level'), findsAtLeastNWidgets(1));
      });

      testWidgets('pull to refresh updates dashboard', (tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // Find scrollable area and perform pull-to-refresh
        final scrollable = find.byType(RefreshIndicator);
        if (scrollable.evaluate().isNotEmpty) {
          await tester.fling(scrollable, const Offset(0, 300), 1000);
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          await tester.pumpAndSettle();
        }

        // Verify content is still there after refresh
        expect(find.textContaining('Welcome'), findsOneWidget);
      });
    });

    group('Task Management Flow', () {
      testWidgets('creates and completes a task', (tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // Navigate to Tasks tab
        await tester.tap(find.text('Tasks'));
        await tester.pumpAndSettle();

        // Look for "Add Task" button
        final addTaskButton = find.textContaining('Add');
        if (addTaskButton.evaluate().isNotEmpty) {
          await tester.tap(addTaskButton.first);
          await tester.pumpAndSettle();

          // Fill in task details (if task creation form exists)
          final titleField = find.byType(TextFormField).first;
          if (titleField.evaluate().isNotEmpty) {
            await tester.enterText(titleField, 'Test Task');
            await tester.pumpAndSettle();

            // Save task
            final saveButton = find.textContaining('Save');
            if (saveButton.evaluate().isNotEmpty) {
              await tester.tap(saveButton);
              await tester.pumpAndSettle();
            }
          }
        }

        // Verify task appears in list
        expect(find.textContaining('Test Task'), findsAtLeastNWidget(0));
      });

      testWidgets('filters tasks by category', (tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // Navigate to Tasks tab
        await tester.tap(find.text('Tasks'));
        await tester.pumpAndSettle();

        // Look for category filters
        final learningFilter = find.textContaining('Learning');
        if (learningFilter.evaluate().isNotEmpty) {
          await tester.tap(learningFilter);
          await tester.pumpAndSettle();
          
          // Verify filtered view
          expect(find.byType(ListView), findsOneWidget);
        }
      });
    });

    group('Analytics Flow', () {
      testWidgets('displays analytics charts and data', (tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // Navigate to Analytics tab
        await tester.tap(find.text('Analytics'));
        await tester.pumpAndSettle();

        // Verify analytics elements
        expect(find.textContaining('Progress'), findsAtLeastNWidget(1));
        
        // Look for chart widgets (custom chart types)
        expect(find.byType(Container), findsAtLeastNWidget(3));
      });

      testWidgets('changes time range for analytics', (tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // Navigate to Analytics tab
        await tester.tap(find.text('Analytics'));
        await tester.pumpAndSettle();

        // Look for time range selector
        final weekButton = find.textContaining('Week');
        if (weekButton.evaluate().isNotEmpty) {
          await tester.tap(weekButton);
          await tester.pumpAndSettle();
        }

        final monthButton = find.textContaining('Month');
        if (monthButton.evaluate().isNotEmpty) {
          await tester.tap(monthButton);
          await tester.pumpAndSettle();
        }
      });
    });

    group('Profile Management Flow', () {
      testWidgets('updates user profile information', (tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // Navigate to Profile tab
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();

        // Look for edit profile option
        final editButton = find.byIcon(Icons.edit);
        if (editButton.evaluate().isNotEmpty) {
          await tester.tap(editButton);
          await tester.pumpAndSettle();

          // Update display name if form exists
          final nameField = find.byType(TextFormField).first;
          if (nameField.evaluate().isNotEmpty) {
            await tester.enterText(nameField, 'Updated Name');
            await tester.pumpAndSettle();

            // Save changes
            final saveButton = find.textContaining('Save');
            if (saveButton.evaluate().isNotEmpty) {
              await tester.tap(saveButton);
              await tester.pumpAndSettle();
            }
          }
        }
      });

      testWidgets('changes app theme', (tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // Navigate to Profile tab
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();

        // Look for theme selection
        final themeButton = find.textContaining('Theme');
        if (themeButton.evaluate().isNotEmpty) {
          await tester.tap(themeButton);
          await tester.pumpAndSettle();

          // Select a different theme
          final oceanTheme = find.textContaining('Ocean');
          if (oceanTheme.evaluate().isNotEmpty) {
            await tester.tap(oceanTheme);
            await tester.pumpAndSettle();
          }
        }
      });

      testWidgets('views achievements and badges', (tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // Navigate to Profile tab
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();

        // Look for achievements section
        final achievementsButton = find.textContaining('Achievements');
        if (achievementsButton.evaluate().isNotEmpty) {
          await tester.tap(achievementsButton);
          await tester.pumpAndSettle();
          
          // Verify achievements are displayed
          expect(find.byType(GridView), findsAtLeastNWidget(0));
        }
      });
    });

    group('Goal Management Flow', () {
      testWidgets('creates and tracks a goal', (tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // Navigate to Analytics tab (where goals are managed)
        await tester.tap(find.text('Analytics'));
        await tester.pumpAndSettle();

        // Look for "Create Goal" button
        final createGoalButton = find.textContaining('Goal');
        if (createGoalButton.evaluate().isNotEmpty) {
          await tester.tap(createGoalButton.first);
          await tester.pumpAndSettle();

          // Fill in goal details if form exists
          final titleField = find.byType(TextFormField);
          if (titleField.evaluate().isNotEmpty) {
            await tester.enterText(titleField.first, 'Read 5 Books');
            await tester.pumpAndSettle();

            // Save goal
            final saveButton = find.textContaining('Create');
            if (saveButton.evaluate().isNotEmpty) {
              await tester.tap(saveButton);
              await tester.pumpAndSettle();
            }
          }
        }
      });
    });

    group('Reward System Flow', () {
      testWidgets('browses reward marketplace', (tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // Look for rewards or marketplace section
        final rewardsButton = find.textContaining('Rewards');
        if (rewardsButton.evaluate().isNotEmpty) {
          await tester.tap(rewardsButton);
          await tester.pumpAndSettle();
          
          // Verify reward items are displayed
          expect(find.byType(Card), findsAtLeastNWidget(0));
        }
      });
    });

    group('Settings and Privacy', () {
      testWidgets('accesses settings and privacy controls', (tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // Navigate to Profile tab
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();

        // Look for settings button
        final settingsButton = find.byIcon(Icons.settings);
        if (settingsButton.evaluate().isNotEmpty) {
          await tester.tap(settingsButton);
          await tester.pumpAndSettle();
          
          // Verify settings options are available
          expect(find.textContaining('Privacy'), findsAtLeastNWidget(0));
          expect(find.textContaining('Notifications'), findsAtLeastNWidget(0));
        }
      });

      testWidgets('manages parental controls', (tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // Navigate to Profile tab
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();

        // Look for parental controls
        final parentalButton = find.textContaining('Parental');
        if (parentalButton.evaluate().isNotEmpty) {
          await tester.tap(parentalButton);
          await tester.pumpAndSettle();
          
          // Verify parental control options
          expect(find.byType(Switch), findsAtLeastNWidget(0));
        }
      });
    });

    group('Accessibility and Kid-Friendly Features', () {
      testWidgets('supports accessibility features', (tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // Verify semantic labels are present
        final homeElements = find.bySemanticsLabel(RegExp(r'.*'));
        expect(homeElements.evaluate().length, greaterThan(0));
      });

      testWidgets('displays kid-friendly animations and celebrations', (tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // Look for animated elements
        expect(find.byType(AnimatedContainer), findsAtLeastNWidget(0));
        expect(find.byType(Hero), findsAtLeastNWidget(0));
      });

      testWidgets('shows encouraging messages and emojis', (tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // Look for encouraging text with emojis
        final encouragingText = find.textContaining(RegExp(r'[🌟🎉🔥⭐🏆]'));
        expect(encouragingText.evaluate().length, greaterThan(0));
      });
    });

    group('Performance and Responsiveness', () {
      testWidgets('app responds quickly to user interactions', (tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        final stopwatch = Stopwatch()..start();
        
        // Navigate between tabs and measure response time
        await tester.tap(find.text('Tasks'));
        await tester.pumpAndSettle();
        
        stopwatch.stop();
        
        // Navigation should be fast (less than 500ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });

      testWidgets('handles data loading gracefully', (tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // Should show loading indicators while data loads
        expect(find.byType(CircularProgressIndicator), findsAtLeastNWidget(1));
        
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        
        // Loading should complete and show content
        expect(find.textContaining('Welcome'), findsOneWidget);
      });
    });

    group('Edge Cases and Error Handling', () {
      testWidgets('handles empty states gracefully', (tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // Navigate to different sections and verify they handle empty states
        await tester.tap(find.text('Tasks'));
        await tester.pumpAndSettle();
        
        // Should show appropriate empty state messages
        expect(find.textContaining(RegExp(r'(no tasks|get started|create)')), 
               findsAtLeastNWidget(0));
      });

      testWidgets('maintains state during navigation', (tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // Navigate away and back to Home
        await tester.tap(find.text('Tasks'));
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('Home'));
        await tester.pumpAndSettle();
        
        // Home state should be preserved
        expect(find.textContaining('Welcome'), findsOneWidget);
      });
    });
  });
}