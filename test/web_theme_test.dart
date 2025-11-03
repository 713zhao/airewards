import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/core/theme/app_theme.dart';
import '../lib/core/theme/app_colors.dart';

/// Web-specific theme tests to ensure the theme system works correctly
/// in the web environment with all Material Design 3 components.
void main() {
  group('Web Theme System Tests', () {
    testWidgets('Light theme renders correctly on web', (WidgetTester tester) async {
      // Create a test app with light theme
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const _TestThemeScreen(),
        ),
      );

      // Verify the app renders without errors
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text('Theme Test'), findsOneWidget);
      
      // Verify light theme is applied correctly
      final BuildContext context = tester.element(find.byType(MaterialApp));
      final theme = Theme.of(context);
      
      expect(theme.brightness, Brightness.light);
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    testWidgets('Dark theme configuration is valid', (WidgetTester tester) async {
      // Create a test app with explicit dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const _TestThemeScreen(),
        ),
      );

      // Verify the app renders without errors
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text('Theme Test'), findsOneWidget);
      
      // Verify dark theme configuration exists and is Material 3
      final theme = AppTheme.darkTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme, isNotNull);
    });

    testWidgets('Material Design 3 components render correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const _ComponentTestScreen(),
        ),
      );

      // Verify all components render
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(Chip), findsWidgets);
    });

    testWidgets('Color system works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const _ColorTestScreen(),
        ),
      );

      // Verify color containers render
      expect(find.byKey(const Key('primary_color')), findsOneWidget);
      expect(find.byKey(const Key('secondary_color')), findsOneWidget);
      expect(find.byKey(const Key('success_color')), findsOneWidget);
      expect(find.byKey(const Key('warning_color')), findsOneWidget);
      expect(find.byKey(const Key('info_color')), findsOneWidget);
    });

    test('Color scheme has all required colors', () {
      final lightScheme = AppColors.lightColorScheme;
      final darkScheme = AppColors.darkColorScheme;

      // Verify light scheme completeness
      expect(lightScheme.primary, isNotNull);
      expect(lightScheme.secondary, isNotNull);
      expect(lightScheme.tertiary, isNotNull);
      expect(lightScheme.error, isNotNull);
      expect(lightScheme.background, isNotNull);
      expect(lightScheme.surface, isNotNull);

      // Verify dark scheme completeness
      expect(darkScheme.primary, isNotNull);
      expect(darkScheme.secondary, isNotNull);
      expect(darkScheme.tertiary, isNotNull);
      expect(darkScheme.error, isNotNull);
      expect(darkScheme.background, isNotNull);
      expect(darkScheme.surface, isNotNull);
    });

    test('Reward category colors are available', () {
      // Test light theme category colors
      for (int i = 0; i < 10; i++) {
        final color = AppColors.getRewardCategoryColor(i, false);
        expect(color, isNotNull);
        expect(color.alpha, 255); // Should be fully opaque
      }

      // Test dark theme category colors
      for (int i = 0; i < 10; i++) {
        final color = AppColors.getRewardCategoryColor(i, true);
        expect(color, isNotNull);
        expect(color.alpha, 255); // Should be fully opaque
      }
    });
  });
}

/// Test screen for basic theme validation
class _TestThemeScreen extends StatelessWidget {
  const _TestThemeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Test'),
      ),
      body: const Center(
        child: Text('Theme system test screen'),
      ),
    );
  }
}

/// Test screen for component validation
class _ComponentTestScreen extends StatelessWidget {
  const _ComponentTestScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Component Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {},
              child: const Text('Elevated Button'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {},
              child: const Text('Outlined Button'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {},
              child: const Text('Text Button'),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Card Component'),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Text Field',
                hintText: 'Enter text here',
              ),
            ),
            const SizedBox(height: 16),
            const Wrap(
              spacing: 8,
              children: [
                Chip(label: Text('Chip 1')),
                Chip(label: Text('Chip 2')),
                Chip(label: Text('Chip 3')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Test screen for color validation
class _ColorTestScreen extends StatelessWidget {
  const _ColorTestScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _ColorBox(
              key: const Key('primary_color'),
              color: Theme.of(context).colorScheme.primary,
              name: 'Primary',
            ),
            _ColorBox(
              key: const Key('secondary_color'),
              color: Theme.of(context).colorScheme.secondary,
              name: 'Secondary',
            ),
            _ColorBox(
              key: const Key('success_color'),
              color: AppColors.success,
              name: 'Success',
            ),
            _ColorBox(
              key: const Key('warning_color'),
              color: AppColors.warning,
              name: 'Warning',
            ),
            _ColorBox(
              key: const Key('info_color'),
              color: AppColors.info,
              name: 'Info',
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper widget for color testing
class _ColorBox extends StatelessWidget {
  final Color color;
  final String name;

  const _ColorBox({
    super.key,
    required this.color,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          name,
          style: TextStyle(
            color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}