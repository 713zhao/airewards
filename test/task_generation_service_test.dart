import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_rewards_system/core/services/task_generation_service.dart';
import 'package:ai_rewards_system/core/models/task_model.dart';

void main() {
  group('TaskGenerationService', () {
    late FakeFirebaseFirestore ff;
    late TaskGenerationService gen;

    setUp(() {
      ff = FakeFirebaseFirestore();
      TaskGenerationService.injectDependencies(firestore: ff);
      gen = TaskGenerationService();
    });

    test('generates family recurring tasks for child and is idempotent', () async {
      final today = DateTime.now();
      final familyId = 'fam1';

      // Create a daily recurring template in tasks
      final tmplRef = ff.collection('tasks').doc('tmpl1');
      final tmpl = TaskModel.create(
        id: 'tmpl1',
        title: 'Brush Teeth',
        description: 'Brush twice',
        category: 'Hygiene',
        pointValue: 5,
        assignedToUserId: 'parent1',
        familyId: familyId,
        isRecurring: true,
        recurrencePattern: RecurrencePattern(type: RecurrenceType.daily),
      );

      await tmplRef.set(tmpl.toFirestore());

      // Generate for child
      final created = await gen.generateTasksForUserForDate(userId: 'child1', date: today, familyId: familyId);
      expect(created.length, 1);

      // Re-run generation -> should be idempotent
      final created2 = await gen.generateTasksForUserForDate(userId: 'child1', date: today, familyId: familyId);
      expect(created2.length, 1);
    });

    test('generates one-off template matching dueDate', () async {
      final today = DateTime.now();
      final familyId = 'fam2';

      final tmplRef = ff.collection('tasks').doc('due1');
      final tmpl = TaskModel.create(
        id: 'due1',
        title: 'Doctor Visit',
        description: 'Annual check',
        category: 'Health',
        pointValue: 20,
        assignedToUserId: 'parent2',
        familyId: familyId,
        isRecurring: false,
        dueDate: DateTime(today.year, today.month, today.day),
      );

      await tmplRef.set(tmpl.toFirestore());

      final created = await gen.generateTasksForUserForDate(userId: 'child2', date: today, familyId: familyId);
      expect(created.length, 1);
    });

    test('resolves familyId from user document when not provided', () async {
      final today = DateTime.now();
      const familyId = 'fam-resolve';

      // Create user doc with familyId
      await ff.collection('users').doc('child3').set({
        'familyId': familyId,
        'createdAt': Timestamp.fromDate(today),
        'lastLoginAt': Timestamp.fromDate(today),
      });

      // Template only accessible via family query
      final tmplRef = ff.collection('tasks').doc('family-template');
      final tmpl = TaskModel.create(
        id: 'family-template',
        title: 'Family Chore',
        description: 'Shared chore',
        category: 'Chores',
        pointValue: 10,
        assignedToUserId: 'parent-resolve',
        familyId: familyId,
        isRecurring: true,
        recurrencePattern: RecurrencePattern(type: RecurrenceType.daily),
      );

      await tmplRef.set(tmpl.toFirestore());

      final generated = await gen.generateTasksForUserForDate(
        userId: 'child3',
        date: today,
        familyId: null,
      );

      expect(generated.length, 1);
      expect(generated.first.assignedToUserId, 'child3');
    });
  });
}
