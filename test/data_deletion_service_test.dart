import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ai_rewards_system/core/services/data_deletion_service.dart';
import 'package:ai_rewards_system/core/models/user_model.dart';
import 'package:ai_rewards_system/core/services/auth_service.dart';
import 'package:ai_rewards_system/core/models/account_type.dart';

class MockAuthService extends AuthService {
  static UserModel? _mockUser;
  static set mockUser(UserModel? user) => _mockUser = user;
  static UserModel? get currentUser => _mockUser;
}

void main() {
  group('DataDeletionService', () {
    late FakeFirebaseFirestore firestore;
    late DataDeletionService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    test('deletes all user data for child account', () async {
      // Setup: create user, tasks, history, redemptions
      final userId = 'child1';
      final familyId = 'fam1';
      await firestore.collection('users').doc(userId).set({'id': userId, 'familyId': familyId, 'accountType': 'child'});
      await firestore.collection('tasks').add({'assignedToUserId': userId, 'familyId': familyId});
      await firestore.collection('task_history').add({'ownerId': userId, 'familyId': familyId});
      await firestore.collection('redemptions').add({'ownerId': userId, 'familyId': familyId});

      final testUser = UserModel.create(
        id: userId,
        email: 'child@example.com',
        displayName: 'Child',
        familyId: familyId,
        accountType: AccountType.child,
      );
      final service = DataDeletionService(firestore: firestore, testUser: testUser);
      await service.deleteAllData(includeFamilyIfParent: false);

      expect((await firestore.collection('users').get()).docs, isEmpty);
      expect((await firestore.collection('tasks').get()).docs, isEmpty);
      expect((await firestore.collection('task_history').get()).docs, isEmpty);
      expect((await firestore.collection('redemptions').get()).docs, isEmpty);
    });

    test('deletes all family data for parent account', () async {
      // Setup: create parent, child, family, tasks, history, redemptions
      final parentId = 'parent1';
      final childId = 'child2';
      final familyId = 'fam2';
      await firestore.collection('users').doc(parentId).set({'id': parentId, 'familyId': familyId, 'accountType': 'parent'});
      await firestore.collection('users').doc(childId).set({'id': childId, 'familyId': familyId, 'accountType': 'child'});
      await firestore.collection('families').doc(familyId).set({'id': familyId});
      await firestore.collection('tasks').add({'assignedToUserId': parentId, 'familyId': familyId});
      await firestore.collection('tasks').add({'assignedToUserId': childId, 'familyId': familyId});
      await firestore.collection('task_history').add({'ownerId': parentId, 'familyId': familyId});
      await firestore.collection('task_history').add({'ownerId': childId, 'familyId': familyId});
      await firestore.collection('redemptions').add({'ownerId': parentId, 'familyId': familyId});
      await firestore.collection('redemptions').add({'ownerId': childId, 'familyId': familyId});

      final testUser = UserModel.create(
        id: parentId,
        email: 'parent@example.com',
        displayName: 'Parent',
        familyId: familyId,
        accountType: AccountType.parent,
      );
      final service = DataDeletionService(firestore: firestore, testUser: testUser);
      await service.deleteAllData(includeFamilyIfParent: true);

      expect((await firestore.collection('users').get()).docs, isEmpty);
      expect((await firestore.collection('families').get()).docs, isEmpty);
      expect((await firestore.collection('tasks').get()).docs, isEmpty);
      expect((await firestore.collection('task_history').get()).docs, isEmpty);
      expect((await firestore.collection('redemptions').get()).docs, isEmpty);
    });
  });
}
