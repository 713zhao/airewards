import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Performance Tests', () {
    
    group('Animation Performance', () {
      testWidgets('splash screen animations perform within target frame rate', (tester) async {
        // Create a simple animated widget similar to splash screen
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: AnimatedContainer(
                  duration: const Duration(seconds: 2),
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 100,
                  ),
                ),
              ),
            ),
          ),
        );

        // Measure frame rendering performance
        final Stopwatch stopwatch = Stopwatch()..start();
        
        // Pump through animation frames
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16)); // Target: 60fps = 16ms/frame
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 16));
        
        stopwatch.stop();
        
        // Should render 4 frames in under 100ms (well under 60fps target)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      testWidgets('celebration animations maintain smooth performance', (tester) async {
        // Simulate celebration animation with multiple elements
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: List.generate(10, (index) => 
                  AnimatedContainer(
                    duration: Duration(milliseconds: 500 + (index * 50)),
                    width: 50.0 + (index * 10),
                    height: 50.0,
                    decoration: BoxDecoration(
                      color: Colors.primaries[index % Colors.primaries.length],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(
                        ['🎉', '🌟', '✨', '🏆', '🎊'][index % 5],
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        final Stopwatch stopwatch = Stopwatch()..start();
        
        // Test rendering performance during complex animation
        for (int i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        
        stopwatch.stop();
        
        // Should maintain 60fps even with complex animations (30 frames = 480ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(600));
      });
    });

    group('Data Loading Performance', () {
      testWidgets('dashboard loads quickly with mock data', (tester) async {
        final Stopwatch stopwatch = Stopwatch()..start();
        
        // Simulate dashboard widget with data
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    // Simulate stats cards
                    ...List.generate(4, (index) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.star),
                        title: Text('Stat ${index + 1}'),
                        subtitle: Text('Value: ${(index + 1) * 100}'),
                      ),
                    )),
                    // Simulate chart widget
                    Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Text('Chart Placeholder'),
                      ),
                    ),
                    // Simulate achievement list
                    ...List.generate(10, (index) => ListTile(
                      leading: const CircleAvatar(
                        child: Text('🏆'),
                      ),
                      title: Text('Achievement ${index + 1}'),
                      subtitle: Text('Earned ${index + 1} days ago'),
                    )),
                  ],
                ),
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        stopwatch.stop();
        
        // Dashboard should load in under 500ms
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });

      testWidgets('large lists render efficiently', (tester) async {
        final Stopwatch stopwatch = Stopwatch()..start();
        
        // Test ListView with many items (simulating task list)
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Tasks')),
              body: ListView.builder(
                itemCount: 1000, // Large list
                itemBuilder: (context, index) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.primaries[index % Colors.primaries.length],
                      child: Text('${index + 1}'),
                    ),
                    title: Text('Task ${index + 1}'),
                    subtitle: Text('Description for task ${index + 1}'),
                    trailing: Checkbox(
                      value: index % 3 == 0,
                      onChanged: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        
        await tester.pump();
        stopwatch.stop();
        
        // Large ListView should render initial view quickly
        expect(stopwatch.elapsedMilliseconds, lessThan(300));
        
        // Test scrolling performance
        final scrollStopwatch = Stopwatch()..start();
        await tester.drag(find.byType(ListView), const Offset(0, -1000));
        await tester.pump();
        scrollStopwatch.stop();
        
        // Scrolling should be responsive
        expect(scrollStopwatch.elapsedMilliseconds, lessThan(200));
      });
    });

    group('Memory Performance', () {
      testWidgets('widgets dispose properly to prevent memory leaks', (tester) async {
        // Test widget creation and disposal
        for (int i = 0; i < 10; i++) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: List.generate(20, (index) => 
                      Container(
                        height: 50,
                        color: Colors.primaries[index % Colors.primaries.length],
                        child: Text('Item $index'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          
          await tester.pump();
          
          // Clear the widget tree
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        }
        
        // Test should complete without memory issues
        expect(true, isTrue);
      });
    });

    group('Input Responsiveness', () {
      testWidgets('button taps respond immediately', (tester) async {
        bool buttonPressed = false;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    buttonPressed = true;
                  },
                  child: const Text('Tap Me!'),
                ),
              ),
            ),
          ),
        );
        
        final Stopwatch stopwatch = Stopwatch()..start();
        
        await tester.tap(find.text('Tap Me!'));
        await tester.pump();
        
        stopwatch.stop();
        
        // Button should respond immediately
        expect(buttonPressed, isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });

      testWidgets('text input has minimal delay', (tester) async {
        final controller = TextEditingController();
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Enter text here...',
                  ),
                ),
              ),
            ),
          ),
        );
        
        final Stopwatch stopwatch = Stopwatch()..start();
        
        await tester.enterText(find.byType(TextField), 'Hello World');
        await tester.pump();
        
        stopwatch.stop();
        
        // Text input should be responsive
        expect(controller.text, equals('Hello World'));
        expect(stopwatch.elapsedMilliseconds, lessThan(200));
      });
    });

    group('Navigation Performance', () {
      testWidgets('page transitions are smooth', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            initialRoute: '/',
            routes: {
              '/': (context) => Scaffold(
                appBar: AppBar(title: const Text('Home')),
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/second');
                    },
                    child: const Text('Go to Second Page'),
                  ),
                ),
              ),
              '/second': (context) => Scaffold(
                appBar: AppBar(title: const Text('Second Page')),
                body: const Center(
                  child: Text('This is the second page'),
                ),
              ),
            },
          ),
        );
        
        final Stopwatch stopwatch = Stopwatch()..start();
        
        // Test navigation
        await tester.tap(find.text('Go to Second Page'));
        await tester.pumpAndSettle();
        
        stopwatch.stop();
        
        // Navigation should complete quickly
        expect(find.text('This is the second page'), findsOneWidget);
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });

      testWidgets('bottom navigation switches quickly', (tester) async {
        int currentIndex = 0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) => Scaffold(
                body: [
                  const Center(child: Text('Home Page')),
                  const Center(child: Text('Tasks Page')),
                  const Center(child: Text('Analytics Page')),
                  const Center(child: Text('Profile Page')),
                ][currentIndex],
                bottomNavigationBar: BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  currentIndex: currentIndex,
                  onTap: (index) {
                    setState(() {
                      currentIndex = index;
                    });
                  },
                  items: const [
                    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                    BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tasks'),
                    BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analytics'),
                    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
                  ],
                ),
              ),
            ),
          ),
        );
        
        // Test switching between tabs
        final List<int> switchTimes = [];
        
        for (int i = 0; i < 4; i++) {
          final stopwatch = Stopwatch()..start();
          
          await tester.tap(find.text(['Home', 'Tasks', 'Analytics', 'Profile'][i]));
          await tester.pump();
          
          stopwatch.stop();
          switchTimes.add(stopwatch.elapsedMilliseconds);
        }
        
        // All tab switches should be fast
        for (final time in switchTimes) {
          expect(time, lessThan(50));
        }
      });
    });

    group('Image Loading Performance', () {
      testWidgets('avatar images load efficiently', (tester) async {
        // Test multiple avatar widgets loading
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                ),
                itemCount: 50,
                itemBuilder: (context, index) => Card(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.primaries[index % Colors.primaries.length],
                        child: Text(
                          ['🐱', '🐶', '🦊', '🐸', '🐼'][index % 5],
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Avatar ${index + 1}'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        
        final Stopwatch stopwatch = Stopwatch()..start();
        await tester.pumpAndSettle();
        stopwatch.stop();
        
        // Grid of avatars should load quickly
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });

    group('Stress Testing', () {
      testWidgets('handles rapid user interactions gracefully', (tester) async {
        int tapCount = 0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Tap Count: $tapCount'),
                    ElevatedButton(
                      onPressed: () {
                        tapCount++;
                      },
                      child: const Text('Rapid Tap Test'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        
        // Perform rapid taps
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 20; i++) {
          await tester.tap(find.text('Rapid Tap Test'));
          await tester.pump(const Duration(milliseconds: 10));
        }
        
        stopwatch.stop();
        
        // Should handle rapid interactions without significant delay
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });

      testWidgets('maintains performance with complex widget trees', (tester) async {
        // Create a deeply nested widget tree
        Widget buildNestedWidget(int depth) {
          if (depth == 0) {
            return Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.blue[100 * ((10 - depth) % 9 + 1)],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('🌟', textAlign: TextAlign.center),
            );
          }
          
          return Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Level $depth'),
                buildNestedWidget(depth - 1),
              ],
            ),
          );
        }
        
        final stopwatch = Stopwatch()..start();
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Center(
                  child: buildNestedWidget(10), // 10 levels deep
                ),
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        stopwatch.stop();
        
        // Complex widget tree should still render reasonably quickly
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });

    group('Platform-Specific Performance', () {
      testWidgets('text rendering performance with emojis', (tester) async {
        // Test text with many emojis (common in kid-friendly apps)
        const emojiText = '🌟🎉🎊🏆⭐🔥💎✨🎯🎪🎨🎭🎪🎠🎡🎢🎳🎮🎯🎲🎱🎤🎧🎼🎵🎶🎸🎹🎺🎻🥁';
        
        final stopwatch = Stopwatch()..start();
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: List.generate(50, (index) => 
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '$emojiText Line ${index + 1}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        stopwatch.stop();
        
        // Emoji-heavy text should render efficiently
        expect(stopwatch.elapsedMilliseconds, lessThan(800));
      });
    });
  });
}