import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'package:ai_rewards_system/core/services/task_service.dart';
import 'package:ai_rewards_system/core/models/task_model.dart';
import 'package:ai_rewards_system/core/services/family_service.dart';
import 'package:ai_rewards_system/core/models/user_model.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

// Mock classes
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockFamilyService extends Mock implements FamilyService {}
class UserModelFake extends Fake implements UserModel {}

void main() {
  late TaskService taskService;
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late MockUser user;
  late MockFamilyService familyService;

  const testUserId = 'test-user-id';

  setUp(() async {
    // Ensure mocktail has a fallback value for UserModel used in matchers
    registerFallbackValue(UserModelFake());
    TestWidgetsFlutterBinding.ensureInitialized();

    // Initialize mocks
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth();
    user = MockUser();
    familyService = MockFamilyService();
    
    // Configure mock behavior
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn(testUserId);

    // Register dependencies
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<FamilyService>()) {
      getIt.registerSingleton<FamilyService>(familyService);
    }

    // Configure mock family service behavior
    when(() => familyService.getFamilyById(any())).thenReturn(null);
    when(() => familyService.canManageTasks(any())).thenReturn(true);

    // Create a test user model and update TaskService with mock implementations
    final testUserModel = UserModel.create(
      id: testUserId,
      email: 'test@example.com',
      displayName: 'Test User',
      familyId: 'test-family-id',
    );

    TestWidgetsFlutterBinding.ensureInitialized();
    TaskService.injectDependencies(
      auth: auth,
      firestore: firestore,
      familyService: familyService,
      currentUser: testUserModel,
    );

  // Create TaskService instance
  taskService = TaskService();

  });

  group('Task Management', () {
    test('create task', () async {
      final taskId = await taskService.createTask(
        title: 'Test Task',
        description: 'Test Description',
        category: 'Test',
        pointValue: 10
      );

      expect(taskId, isNotEmpty);

      // Verify task exists
      final task = await taskService.getTask(taskId);
      expect(task, isNotNull);
      expect(task!.title, equals('Test Task'));
      expect(task.description, equals('Test Description'));
      expect(task.category, equals('Test'));
      expect(task.pointValue, equals(10));
      expect(task.assignedToUserId, equals(testUserId));
    });

    test('complete task', () async {
      // Create a task
      final taskId = await taskService.createTask(
        title: 'Test Task',
        description: 'Test Description',
        category: 'Test',
        pointValue: 10
      );

      // Complete the task
      await taskService.completeTask(taskId);

      // Verify status
      final task = await taskService.getTask(taskId);
      expect(task!.status, equals(TaskStatus.completed));
      expect(task.completedAt, isNotNull);
    });

    test('delete pending task', () async {
      // Create a task
      final taskId = await taskService.createTask(
        title: 'Test Task',
        description: 'Test Description',
        category: 'Test',
        pointValue: 10
      );

      // Delete the task
      await taskService.deleteTask(taskId);

      // Verify deletion
      final task = await taskService.getTask(taskId);
      expect(task, isNull);
    });

    test('archive completed task instead of deleting', () async {
      // Create a task
      final taskId = await taskService.createTask(
        title: 'Test Task',
        description: 'Test Description',
        category: 'Test',
        pointValue: 10
      );

      // Complete the task first
      await taskService.completeTask(taskId);

      // Try to delete the completed task
      await taskService.deleteTask(taskId);

  // Verify task was moved into history collection
  final task = await taskService.getTask(taskId);
  // original task should be removed from live collection
  expect(task, isNull);

  final historyDoc = await firestore.collection('task_history').doc(taskId).get();
  expect(historyDoc.exists, isTrue);
  final historyData = historyDoc.data()!;
  expect((historyData['tags'] as List).contains('archived'), isTrue);
  expect(historyData['showInQuickTasks'], equals(false));
    });

    test('update task details', () async {
      // Create a task
      final taskId = await taskService.createTask(
        title: 'Test Task',
        description: 'Test Description',
        category: 'Test',
        pointValue: 10
      );

      // Update task details
      await taskService.updateTask(
        taskId,
        title: 'Updated Task',
        description: 'Updated Description',
        pointValue: 20,
        priority: TaskPriority.high,
      );

      // Verify updates
      final task = await taskService.getTask(taskId);
      expect(task, isNotNull);
      expect(task!.title, equals('Updated Task'));
      expect(task.description, equals('Updated Description'));
      expect(task.pointValue, equals(20));
      expect(task.priority, equals(TaskPriority.high));
    });

    test('get my pending tasks', () async {
      // Create multiple tasks
      final task1Id = await taskService.createTask(
        title: 'Pending Task 1',
        description: 'Test Description 1',
        category: 'Test',
        pointValue: 10
      );

      final task2Id = await taskService.createTask(
        title: 'Pending Task 2',
        description: 'Test Description 2',
        category: 'Test',
        pointValue: 15
      );

      // Complete one task
      await taskService.completeTask(task2Id);

      // Get pending tasks stream
      final pendingTasks = await taskService.getMyPendingTasks().first;

      // Verify only pending task is returned
      expect(pendingTasks.length, equals(1));
      expect(pendingTasks.first.id, equals(task1Id));
      expect(pendingTasks.first.status, equals(TaskStatus.pending));
    });
  });
}