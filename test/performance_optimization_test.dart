import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../lib/core/services/performance_service.dart';
import '../lib/core/services/memory_management_service.dart';
import '../lib/core/services/animation_optimization_service.dart';
import '../lib/core/services/image_optimization_service.dart';
import '../lib/core/services/data_optimization_service.dart';
import '../lib/core/widgets/optimized_widgets.dart';

void main() {
  group('Performance Optimization Tests', () {
    setUpAll(() async {
      // Initialize services for testing
      await MemoryManagementService.initialize();
      await DataOptimizationService.initialize();
    });

    tearDownAll(() async {
      await MemoryManagementService.dispose();
      await DataOptimizationService.dispose();
    });

    testWidgets('Performance service tracks metrics correctly', (tester) async {
      final performanceService = PerformanceService();
      
      // Test metric tracking
      await performanceService.recordMetric('test_metric', 'value', 100);
      
      final stats = performanceService.getPerformanceStats();
      expect(stats, isNotNull);
      expect(stats['operation_counts'], isA<Map>());
    });

    testWidgets('Memory management tracks objects', (tester) async {
      const testObject = 'test_object';
      
      MemoryManagementService.trackObject(testObject, 'TestCategory');
      
      final metrics = await MemoryManagementService.getMemoryMetrics();
      expect(metrics['trackedObjects'], greaterThan(0));
    });

    testWidgets('Optimized list view renders efficiently', (tester) async {
      final items = List.generate(100, (index) => 'Item $index');
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedListView<String>(
              items: items,
              itemBuilder: (context, item, index) {
                return ListTile(
                  title: Text(item),
                );
              },
            ),
          ),
        ),
      );
      
      expect(find.byType(OptimizedListView), findsOneWidget);
      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('Task card displays correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedTaskCard(
              title: 'Test Task',
              description: 'This is a test task',
              points: 10,
              isCompleted: false,
            ),
          ),
        ),
      );
      
      expect(find.text('Test Task'), findsOneWidget);
      expect(find.text('This is a test task'), findsOneWidget);
      expect(find.text('10 pts'), findsOneWidget);
    });

    testWidgets('Achievement card displays correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedAchievementCard(
              title: 'First Steps',
              description: 'Complete your first task',
              emoji: '🎉',
              isUnlocked: true,
              unlockedAt: DateTime.now(),
            ),
          ),
        ),
      );
      
      expect(find.text('First Steps'), findsOneWidget);
      expect(find.text('Complete your first task'), findsOneWidget);
      expect(find.text('🎉'), findsOneWidget);
      expect(find.text('Unlocked!'), findsOneWidget);
    });

    testWidgets('Grid view renders achievements', (tester) async {
      final achievements = [
        {'title': 'First Steps', 'emoji': '🎉'},
        {'title': 'Super Star', 'emoji': '⭐'},
        {'title': 'Champion', 'emoji': '🏆'},
        {'title': 'Expert', 'emoji': '💎'},
      ];
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedGridView<Map<String, String>>(
              items: achievements,
              crossAxisCount: 2,
              itemBuilder: (context, achievement, index) {
                return OptimizedAchievementCard(
                  title: achievement['title']!,
                  description: 'Achievement description',
                  emoji: achievement['emoji']!,
                  isUnlocked: index % 2 == 0,
                );
              },
            ),
          ),
        ),
      );
      
      expect(find.byType(OptimizedGridView), findsOneWidget);
      expect(find.byType(OptimizedAchievementCard), findsNWidgets(4));
    });

    test('Animation optimization provides smooth transitions', () {
      final stats = AnimationOptimizationService.getPerformanceStats();
      
      expect(stats, isNotNull);
      expect(stats['target_fps'], equals(60));
      expect(stats['frame_budget_ms'], equals(16.67));
    });

    test('Data optimization caches data efficiently', () async {
      // Test data caching
      final testData = {'key': 'value', 'number': 42};
      
      await DataOptimizationService.cacheData('test_key', testData);
      
      final cachedData = await DataOptimizationService.fetchData(
        'test_key',
        () async => testData,
      );
      
      expect(cachedData, equals(testData));
    });

    test('Image optimization builds safe images', () {
      final imageWidget = ImageOptimizationService.buildKidSafeImage(
        imageUrl: 'https://example.com/test.jpg',
        width: 100,
        height: 100,
      );
      
      expect(imageWidget, isNotNull);
      expect(imageWidget, isA<Widget>());
    });

    testWidgets('Memory efficient widgets manage resources', (tester) async {
      const widget = MemoryEfficientListItem(
        child: Text('Test Item'),
      );
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: widget,
          ),
        ),
      );
      
      expect(find.byType(RepaintBoundary), findsOneWidget);
      expect(find.text('Test Item'), findsOneWidget);
    });

    test('Performance metrics are collected properly', () async {
      final metrics = await PerformanceService.getPerformanceMetrics();
      
      expect(metrics, isA<Map<String, dynamic>>());
      expect(metrics.containsKey('frameRate'), isTrue);
      expect(metrics.containsKey('appLaunchTime'), isTrue);
      expect(metrics.containsKey('screenTransitions'), isTrue);
      expect(metrics.containsKey('userActions'), isTrue);
      expect(metrics.containsKey('networkRequests'), isTrue);
    });

    test('Memory metrics are tracked correctly', () async {
      final metrics = await MemoryManagementService.getMemoryMetrics();
      
      expect(metrics, isA<Map<String, dynamic>>());
      expect(metrics.containsKey('usedMemoryMB'), isTrue);
      expect(metrics.containsKey('maxMemoryMB'), isTrue);
      expect(metrics.containsKey('trackedObjects'), isTrue);
      expect(metrics.containsKey('memoryPressure'), isTrue);
    });

    group('Performance Benchmarks', () {
      testWidgets('List scrolling performance', (tester) async {
        final items = List.generate(1000, (index) => 'Item $index');
        
        final stopwatch = Stopwatch()..start();
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OptimizedListView<String>(
                items: items,
                itemBuilder: (context, item, index) {
                  return ListTile(
                    title: Text(item),
                    subtitle: Text('Subtitle for $item'),
                  );
                },
              ),
            ),
          ),
        );
        
        stopwatch.stop();
        
        // Should render quickly (under 100ms for 1000 items)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      testWidgets('Grid scrolling performance', (tester) async {
        final items = List.generate(500, (index) => index);
        
        final stopwatch = Stopwatch()..start();
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OptimizedGridView<int>(
                items: items,
                crossAxisCount: 3,
                itemBuilder: (context, item, index) {
                  return Container(
                    color: Colors.blue,
                    child: Center(
                      child: Text('$item'),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        
        stopwatch.stop();
        
        // Should render quickly (under 150ms for 500 grid items)
        expect(stopwatch.elapsedMilliseconds, lessThan(150));
      });

      test('Memory usage optimization', () async {
        // Track memory before creating objects
        final initialMetrics = await MemoryManagementService.getMemoryMetrics();
        final initialMemory = initialMetrics['usedMemoryMB'] as double;
        
        // Create and track many objects
        final objects = List.generate(100, (index) => 'Object $index');
        for (final obj in objects) {
          MemoryManagementService.trackObject(obj, 'TestObject');
        }
        
        // Force memory pressure handling
        await MemoryManagementService.handleMemoryPressure();
        
        final finalMetrics = await MemoryManagementService.getMemoryMetrics();
        final finalMemory = finalMetrics['usedMemoryMB'] as double;
        
        // Memory should be managed efficiently
        expect(finalMemory - initialMemory, lessThan(50.0)); // Less than 50MB increase
      });

      test('Data caching performance', () async {
        final stopwatch = Stopwatch();
        
        // Test cache miss (first fetch)
        stopwatch.start();
        final data1 = await DataOptimizationService.fetchData(
          'performance_test',
          () async {
            await Future.delayed(const Duration(milliseconds: 100));
            return {'data': 'test_value', 'timestamp': DateTime.now().millisecondsSinceEpoch};
          },
        );
        stopwatch.stop();
        final firstFetchTime = stopwatch.elapsedMilliseconds;
        
        stopwatch.reset();
        
        // Test cache hit (second fetch)
        stopwatch.start();
        final data2 = await DataOptimizationService.fetchData(
          'performance_test',
          () async {
            await Future.delayed(const Duration(milliseconds: 100));
            return {'data': 'test_value', 'timestamp': DateTime.now().millisecondsSinceEpoch};
          },
        );
        stopwatch.stop();
        final secondFetchTime = stopwatch.elapsedMilliseconds;
        
        // Cache hit should be significantly faster
        expect(secondFetchTime, lessThan(firstFetchTime ~/ 2));
        expect(data1['data'], equals(data2['data']));
      });
    });

    group('Error Handling', () {
      test('Performance service handles errors gracefully', () async {
        final performanceService = PerformanceService();
        
        // Test with invalid metric
        expect(
          () => performanceService.recordMetric('', 'invalid', null),
          returnsNormally,
        );
      });

      test('Memory service handles cleanup errors', () async {
        // Should not throw even with invalid objects
        expect(
          () => MemoryManagementService.trackObject(null, 'NullObject'),
          returnsNormally,
        );
        
        expect(
          () => MemoryManagementService.handleMemoryPressure(),
          returnsNormally,
        );
      });

      testWidgets('Widgets handle missing data gracefully', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OptimizedTaskCard(
                title: 'Test Task',
                description: null, // Test null description
                points: 0,
                isCompleted: false,
              ),
            ),
          ),
        );
        
        expect(find.text('Test Task'), findsOneWidget);
        // Should not crash with null description
      });
    });
  });
}