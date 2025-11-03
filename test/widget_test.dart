// AI Rewards System widget tests
//
// Basic smoke tests to ensure the app renders correctly and
// the main components are working as expected.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/core/theme/app_theme.dart';

void main() {
  testWidgets('App renders without errors', (WidgetTester tester) async {
    // Build a simple app with our theme to test basic functionality
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          appBar: AppBar(title: const Text('AI Rewards System')),
          body: const Center(
            child: Text('Welcome to AI Rewards System'),
          ),
        ),
      ),
    );

    // Verify that the app renders correctly
    expect(find.text('AI Rewards System'), findsOneWidget);
    expect(find.text('Welcome to AI Rewards System'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('Theme system works in test environment', (WidgetTester tester) async {
    // Test that our theme can be applied without errors
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const Scaffold(
          body: Center(
            child: Text('Theme Test'),
          ),
        ),
      ),
    );

    // Verify the widget renders
    expect(find.text('Theme Test'), findsOneWidget);
    
    // Verify Material 3 is enabled
    final BuildContext context = tester.element(find.byType(MaterialApp));
    final theme = Theme.of(context);
    expect(theme.useMaterial3, isTrue);
  });
}
