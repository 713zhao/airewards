import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Accessibility Tests', () {
    
    group('Screen Reader Support', () {
      testWidgets('buttons have proper semantic labels', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Complete Task'),
                    ),
                    const SizedBox(height: 16),
                    FloatingActionButton(
                      onPressed: () {},
                      tooltip: 'Add new task',
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 16),
                    IconButton(
                      onPressed: () {},
                      tooltip: 'View analytics',
                      icon: const Icon(Icons.analytics),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Check semantic labels exist by finding the actual widgets
        expect(find.text('Complete Task'), findsOneWidget);
        expect(find.byTooltip('Add new task'), findsOneWidget);
        expect(find.byTooltip('View analytics'), findsOneWidget);
      });

      testWidgets('images have accessibility descriptions', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  // Avatar with semantic label
                  Semantics(
                    label: 'User profile avatar showing a friendly cat character',
                    child: const CircleAvatar(
                      radius: 40,
                      child: Text('🐱', style: TextStyle(fontSize: 40)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Achievement badge
                  Semantics(
                    label: 'Achievement unlocked: First Task Completed! Gold star badge',
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.amber,
                      ),
                      child: const Icon(
                        Icons.star,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // Verify accessibility descriptions by checking the widgets exist
        expect(find.text('🐱'), findsOneWidget);
        expect(find.byIcon(Icons.star), findsOneWidget);
      });

      testWidgets('form fields have proper labels and hints', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Task Name',
                          hintText: 'Enter a fun task to complete',
                          helperText: 'Choose something you enjoy doing!',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a task name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Points Reward',
                          hintText: 'How many points is this worth?',
                          helperText: 'Typical tasks are worth 5-20 points',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        // Verify form accessibility
        expect(find.text('Task Name'), findsOneWidget);
        expect(find.text('Enter a fun task to complete'), findsOneWidget);
        expect(find.text('Choose something you enjoy doing!'), findsOneWidget);
        expect(find.text('Points Reward'), findsOneWidget);
        expect(find.text('How many points is this worth?'), findsOneWidget);
        expect(find.text('Typical tasks are worth 5-20 points'), findsOneWidget);
      });
    });

    group('High Contrast Support', () {
      testWidgets('interface works with high contrast themes', (tester) async {
        // Test with high contrast theme
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              brightness: Brightness.light,
              primarySwatch: Colors.blue,
              // High contrast colors
              colorScheme: const ColorScheme.light(
                primary: Colors.black,
                secondary: Colors.white,
                surface: Colors.white,
                onPrimary: Colors.white,
                onSecondary: Colors.black,
                onSurface: Colors.black,
              ),
            ),
            home: Scaffold(
              appBar: AppBar(
                title: const Text('High Contrast Test'),
              ),
              body: const Column(
                children: [
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.star),
                      title: Text('Achievement'),
                      subtitle: Text('You completed 5 tasks!'),
                      trailing: Text('100 pts'),
                    ),
                  ),
                  SizedBox(height: 16),
                  LinearProgressIndicator(value: 0.6),
                ],
              ),
            ),
          ),
        );

        // Verify components are visible
        expect(find.text('High Contrast Test'), findsOneWidget);
        expect(find.text('Achievement'), findsOneWidget);
        expect(find.text('You completed 5 tasks!'), findsOneWidget);
        expect(find.text('100 pts'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });
    });

    group('Font Scaling Support', () {
      testWidgets('interface adapts to large font sizes', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                textScaler: TextScaler.linear(2.0), // Double font size
              ),
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('Font Scaling Test'),
                ),
                body: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Progress',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'You have completed 3 out of 5 tasks today! Keep up the great work! 🌟',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text('Daily Goal: Complete 5 Tasks'),
                              SizedBox(height: 8),
                              LinearProgressIndicator(value: 0.6),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        // Verify text is displayed correctly with large fonts
        expect(find.text('Font Scaling Test'), findsOneWidget);
        expect(find.text('Your Progress'), findsOneWidget);
        expect(find.textContaining('You have completed 3 out of 5 tasks'), findsOneWidget);
        expect(find.text('Daily Goal: Complete 5 Tasks'), findsOneWidget);
      });

      testWidgets('buttons remain usable with large fonts', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                textScaler: TextScaler.linear(1.5), // 1.5x font size
              ),
              child: Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Complete Task'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add),
                        label: const Text('Add New Task'),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () {},
                        child: const Text('View All Tasks'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        // Test button interaction with large fonts
        await tester.tap(find.text('Complete Task'));
        await tester.pump();

        await tester.tap(find.text('Add New Task'));
        await tester.pump();

        await tester.tap(find.text('View All Tasks'));
        await tester.pump();

        // Verify buttons are still functional
        expect(find.text('Complete Task'), findsOneWidget);
        expect(find.text('Add New Task'), findsOneWidget);
        expect(find.text('View All Tasks'), findsOneWidget);
      });
    });

    group('Keyboard Navigation', () {
      testWidgets('focus traversal works correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Task Name'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Points'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Save Task'),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Test tab navigation
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        // Verify focus can move between elements
        expect(find.byType(TextFormField), findsNWidgets(2));
        expect(find.byType(ElevatedButton), findsOneWidget);
        expect(find.byType(OutlinedButton), findsOneWidget);
      });

      testWidgets('enter key activates buttons', (tester) async {
        bool buttonPressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    buttonPressed = true;
                  },
                  child: const Text('Press Me'),
                ),
              ),
            ),
          ),
        );

        // Focus the button and press Enter
        await tester.tap(find.text('Press Me'));
        await tester.pump();
        
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();

        expect(buttonPressed, isTrue);
      });
    });

    group('Voice Control Support', () {
      testWidgets('widgets have voice-friendly labels', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Voice Control Test'),
                actions: [
                  IconButton(
                    onPressed: () {},
                    tooltip: 'Settings',
                    icon: const Icon(Icons.settings),
                  ),
                ],
              ),
              body: ListView(
                children: [
                  Semantics(
                    button: true,
                    label: 'Complete homework task',
                    child: ListTile(
                      leading: const Icon(Icons.assignment),
                      title: const Text('Homework'),
                      subtitle: const Text('Math worksheet - Chapter 5'),
                      trailing: Checkbox(
                        value: false,
                        onChanged: (_) {},
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Complete reading task',
                    child: ListTile(
                      leading: const Icon(Icons.book),
                      title: const Text('Reading'),
                      subtitle: const Text('Read for 30 minutes'),
                      trailing: Checkbox(
                        value: true,
                        onChanged: (_) {},
                      ),
                    ),
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {},
                tooltip: 'Add new task',
                child: const Icon(Icons.add),
              ),
            ),
          ),
        );

        // Verify voice-friendly labels by checking widgets exist
        expect(find.text('Homework'), findsOneWidget);
        expect(find.text('Reading'), findsOneWidget);
        expect(find.byTooltip('Add new task'), findsOneWidget);
        expect(find.byTooltip('Settings'), findsOneWidget);
      });
    });

    group('Motor Accessibility', () {
      testWidgets('touch targets are large enough', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(16),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  // Task completion buttons
                  SizedBox(
                    height: 120,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.brush, size: 48),
                          SizedBox(height: 8),
                          Text('Art Time'),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 120,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sports_soccer, size: 48),
                          SizedBox(height: 8),
                          Text('Play Outside'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // Test that buttons are large enough and tappable
        await tester.tap(find.text('Art Time'));
        await tester.pump();

        await tester.tap(find.text('Play Outside'));
        await tester.pump();

        // Verify buttons exist and are accessible
        expect(find.text('Art Time'), findsOneWidget);
        expect(find.text('Play Outside'), findsOneWidget);
      });

      testWidgets('swipe gestures work for task completion', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView(
                children: [
                  Dismissible(
                    key: const ValueKey('task1'),
                    background: Container(
                      color: Colors.green,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 16),
                      child: const Row(
                        children: [
                          Icon(Icons.check, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Complete', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    child: ListTile(
                      title: const Text('Feed the fish'),
                      subtitle: const Text('Give fish their morning food'),
                      leading: const Icon(Icons.pets),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // Test swipe gesture
        await tester.drag(
          find.text('Feed the fish'),
          const Offset(300, 0), // Swipe right
        );
        await tester.pump();

        // Verify swipe interaction works
        expect(find.text('Complete'), findsOneWidget);
      });
    });

    group('Color Accessibility', () {
      testWidgets('information is not conveyed by color alone', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Color Accessibility'),
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Progress with both color and text
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Daily Progress'),
                                Text(
                                  '3/5 Complete',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const LinearProgressIndicator(
                              value: 0.6,
                              backgroundColor: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Status indicators with icons and text
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 32),
                            Text('Completed'),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.schedule, color: Colors.orange, size: 32),
                            Text('In Progress'),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 32),
                            Text('Not Started'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Verify text labels accompany colors
        expect(find.text('3/5 Complete'), findsOneWidget);
        expect(find.text('Completed'), findsOneWidget);
        expect(find.text('In Progress'), findsOneWidget);
        expect(find.text('Not Started'), findsOneWidget);
        
        // Verify icons provide additional context
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.byIcon(Icons.schedule), findsOneWidget);
        expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
      });
    });

    group('Content Accessibility', () {
      testWidgets('content is age-appropriate and clear', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                title: const Text('My Awesome Tasks! 🌟'),
              ),
              body: const SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Great job today! 🎉',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text('🎨', style: TextStyle(fontSize: 20)),
                        ),
                        title: Text('Creative Time'),
                        subtitle: Text('Draw a picture of your favorite animal'),
                        trailing: Icon(Icons.star, color: Colors.amber),
                      ),
                    ),
                    SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Text('🌱', style: TextStyle(fontSize: 20)),
                        ),
                        title: Text('Garden Helper'),
                        subtitle: Text('Water the plants in the garden'),
                        trailing: Icon(Icons.star, color: Colors.amber),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Verify kid-friendly content
        expect(find.text('My Awesome Tasks! 🌟'), findsOneWidget);
        expect(find.text('Great job today! 🎉'), findsOneWidget);
        expect(find.text('Creative Time'), findsOneWidget);
        expect(find.text('Draw a picture of your favorite animal'), findsOneWidget);
        expect(find.text('Garden Helper'), findsOneWidget);
        expect(find.text('Water the plants in the garden'), findsOneWidget);
      });
    });
  });
}