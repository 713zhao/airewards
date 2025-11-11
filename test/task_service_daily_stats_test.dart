import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'package:ai_rewards_system/core/services/task_service.dart';
import 'package:ai_rewards_system/core/services/task_generation_service.dart';
import 'package:ai_rewards_system/core/models/task_model.dart';
import 'package:ai_rewards_system/core/services/family_service.dart';
import 'package:ai_rewards_system/core/models/user_model.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  const testFamilyId = 'test-family-id';

  setUp(() async {
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
    await getIt.reset();
    getIt.registerSingleton<FamilyService>(familyService);

    // Configure mock family service behavior
    when(() => familyService.getFamilyById(any())).thenReturn(null);
    when(() => familyService.canManageTasks(any())).thenReturn(true);

    // Create test user
    final testUserModel = UserModel.create(
      id: testUserId,
      email: 'test@example.com',
      displayName: 'Test User',
      familyId: testFamilyId,
    );

    TaskService.injectDependencies(
      auth: auth,
      firestore: firestore,
      familyService: familyService,
      currentUser: testUserModel,
    );

    TaskGenerationService.injectDependencies(
      firestore: firestore,
    );

    taskService = TaskService();
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  group('Daily Stats with Redemptions', () {
    test('task_history query includes redemptions with generatedForDate', () async {
      final now = DateTime.now();
      final dateKey = '${now.year.toString().padLeft(4,'0')}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';

      // Add a completed task to task_history with generatedForDate
      await firestore.collection('task_history').add({
        'title': 'Complete homework',
        'description': 'Math homework',
        'category': 'Education',
        'pointValue': 10,
        'status': 'completed',
        'ownerId': testUserId,
        'assignedToUserId': testUserId,
        'familyId': testFamilyId,
        'generatedForDate': dateKey,
        'createdAt': Timestamp.fromDate(now),
        'completedAt': Timestamp.fromDate(now),
        'priority': 'medium',
        'tags': [],
        'showInQuickTasks': false,
        'isRecurring': false,
      });

      // Add a reward redemption with generatedForDate (new redemption)
      await firestore.collection('task_history').add({
        'title': 'Ice cream treat',
        'description': 'Chocolate ice cream',
        'category': 'Reward Redemption',
        'pointValue': -5,
        'status': 'completed',
        'ownerId': testUserId,
        'assignedToUserId': testUserId,
        'familyId': testFamilyId,
        'generatedForDate': dateKey,
        'createdAt': Timestamp.fromDate(now),
        'completedAt': Timestamp.fromDate(now),
        'priority': 'medium',
        'tags': [],
        'showInQuickTasks': false,
        'isRecurring': false,
      });

      // Query task_history by generatedForDate (simulating what getTodayHistoryForCurrentUser does)
      final snapshot = await firestore
          .collection('task_history')
          .where('ownerId', isEqualTo: testUserId)
          .where('generatedForDate', isEqualTo: dateKey)
          .get();

      final tasks = snapshot.docs.map((d) => TaskModel.fromFirestore(d)).toList();

      // Should include both task and redemption
      expect(tasks.length, equals(2));
      
      // Verify task
      final regularTasks = tasks.where((t) => t.category != 'Reward Redemption').toList();
      expect(regularTasks.length, equals(1));
      expect(regularTasks.first.title, equals('Complete homework'));
      expect(regularTasks.first.pointValue, equals(10));

      // Verify redemptions
      final redemptions = tasks.where((t) => t.category == 'Reward Redemption').toList();
      expect(redemptions.length, equals(1));
      expect(redemptions.first.title, equals('Ice cream treat'));
      expect(redemptions.first.pointValue, equals(-5));
    });

    test('getNetPointsFromHistory calculates net points correctly', () async {
      final now = DateTime.now();
      final dateKey = '${now.year.toString().padLeft(4,'0')}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';

      // Add multiple completed tasks
      await firestore.collection('task_history').add({
        'title': 'Task 1',
        'description': '',
        'category': 'Chores',
        'pointValue': 15,
        'status': 'completed',
        'ownerId': testUserId,
        'assignedToUserId': testUserId,
        'familyId': testFamilyId,
        'generatedForDate': dateKey,
        'createdAt': Timestamp.fromDate(now),
        'completedAt': Timestamp.fromDate(now),
        'priority': 'medium',
        'tags': [],
        'showInQuickTasks': false,
        'isRecurring': false,
      });

      await firestore.collection('task_history').add({
        'title': 'Task 2',
        'description': '',
        'category': 'Chores',
        'pointValue': 20,
        'status': 'completed',
        'ownerId': testUserId,
        'assignedToUserId': testUserId,
        'familyId': testFamilyId,
        'generatedForDate': dateKey,
        'createdAt': Timestamp.fromDate(now),
        'completedAt': Timestamp.fromDate(now),
        'priority': 'medium',
        'tags': [],
        'showInQuickTasks': false,
        'isRecurring': false,
      });

      // Add reward redemptions (negative points)
      await firestore.collection('task_history').add({
        'title': 'Reward 1',
        'description': '',
        'category': 'Reward Redemption',
        'pointValue': -10,
        'status': 'completed',
        'ownerId': testUserId,
        'assignedToUserId': testUserId,
        'familyId': testFamilyId,
        'generatedForDate': dateKey,
        'createdAt': Timestamp.fromDate(now),
        'completedAt': Timestamp.fromDate(now),
        'priority': 'medium',
        'tags': [],
        'showInQuickTasks': false,
        'isRecurring': false,
      });

      await firestore.collection('task_history').add({
        'title': 'Reward 2',
        'description': '',
        'category': 'Reward Redemption',
        'pointValue': -5,
        'status': 'completed',
        'ownerId': testUserId,
        'assignedToUserId': testUserId,
        'familyId': testFamilyId,
        'generatedForDate': dateKey,
        'createdAt': Timestamp.fromDate(now),
        'completedAt': Timestamp.fromDate(now),
        'priority': 'medium',
        'tags': [],
        'showInQuickTasks': false,
        'isRecurring': false,
      });

      // Calculate net points
      final netPoints = await taskService.getNetPointsFromHistory(userId: testUserId);

      // 15 + 20 - 10 - 5 = 20
      expect(netPoints, equals(20));
    });

    test('legacy redemptions without generatedForDate are filtered by timestamp', () async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final startOfDay = DateTime(now.year, now.month, now.day);
      final midDay = startOfDay.add(const Duration(hours: 14));
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Add a legacy redemption from yesterday (should NOT appear in today's filter)
      await firestore.collection('task_history').add({
        'title': 'Yesterday reward',
        'description': '',
        'category': 'Reward Redemption',
        'pointValue': -20,
        'status': 'completed',
        'ownerId': testUserId,
        'assignedToUserId': testUserId,
        'familyId': testFamilyId,
        // NO generatedForDate
        'createdAt': Timestamp.fromDate(yesterday),
        'completedAt': Timestamp.fromDate(yesterday),
        'priority': 'medium',
        'tags': [],
        'showInQuickTasks': false,
        'isRecurring': false,
      });

      // Add a legacy redemption from today (SHOULD appear)
      await firestore.collection('task_history').add({
        'title': 'Today reward',
        'description': '',
        'category': 'Reward Redemption',
        'pointValue': -7,
        'status': 'completed',
        'ownerId': testUserId,
        'assignedToUserId': testUserId,
        'familyId': testFamilyId,
        // NO generatedForDate
        'createdAt': Timestamp.fromDate(midDay),
        'completedAt': Timestamp.fromDate(midDay),
        'priority': 'medium',
        'tags': [],
        'showInQuickTasks': false,
        'isRecurring': false,
      });

      // Query all redemptions and apply client-side filtering (simulating getTodayHistoryForCurrentUser logic)
      final snapshot = await firestore
          .collection('task_history')
          .where('ownerId', isEqualTo: testUserId)
          .where('category', isEqualTo: 'Reward Redemption')
          .get();

      final allRedemptions = snapshot.docs.map((d) => TaskModel.fromFirestore(d)).toList();
      
      // Apply day filter (client-side)
      final todayRedemptions = allRedemptions.where((t) {
        final ts = t.completedAt ?? t.createdAt;
        return ts.isAfter(startOfDay) && ts.isBefore(endOfDay);
      }).toList();

      // Should only include today's redemption
      expect(todayRedemptions.length, equals(1));
      expect(todayRedemptions.first.title, equals('Today reward'));
      expect(todayRedemptions.first.pointValue, equals(-7));
    });
  });
}
