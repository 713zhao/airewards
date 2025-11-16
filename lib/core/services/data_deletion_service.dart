import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

/// Service responsible for permanently deleting all user or family data.
/// Parent accounts trigger family-wide deletion. Child accounts only delete
/// their own records while preserving family structure.
class DataDeletionService {
  final FirebaseFirestore _firestore;
  final dynamic _testUser;
  DataDeletionService({FirebaseFirestore? firestore, dynamic testUser})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _testUser = testUser;

  /// Delete all data for the current user.
  /// If the user is a parent and [includeFamilyIfParent] is true, will remove:
  /// - Family document
  /// - All users in family
  /// - All tasks, task_history, redemptions for family
  /// - Local preferences / caches
  /// Child accounts only remove their own tasks/history/redemptions + user doc.
  Future<void> deleteAllData({bool includeFamilyIfParent = true}) async {
    final currentUser = _testUser ?? AuthService.currentUser;
    if (currentUser == null) {
      throw Exception('No authenticated user');
    }
    final userId = currentUser.id;
    final familyId = currentUser.familyId;

  final isParent = currentUser.accountType.value == 'parent';

    if (isParent && includeFamilyIfParent && familyId != null) {
      await _deleteFamilyScopedData(familyId);
    } else {
      await _deleteUserScopedData(userId, familyId);
    }

    await _clearLocalData();

    // Sign out after deletion (user doc may be gone)
    if (_testUser == null) {
      await AuthService.signOut();
    }
  }

  Future<void> _deleteFamilyScopedData(String familyId) async {
    // Delete tasks
    await _pagedDelete(
      collection: 'tasks',
      queryBuilder: (c) => c.where('familyId', isEqualTo: familyId),
      batchSize: 300,
    );

    // Delete task history
    await _pagedDelete(
      collection: 'task_history',
      queryBuilder: (c) => c.where('familyId', isEqualTo: familyId),
      batchSize: 300,
    );

    // Delete redemptions (if separate collection used)
    await _pagedDelete(
      collection: 'redemptions',
      queryBuilder: (c) => c.where('familyId', isEqualTo: familyId),
      batchSize: 300,
    );

    // Delete all users in family (including parent)
    await _pagedDelete(
      collection: 'users',
      queryBuilder: (c) => c.where('familyId', isEqualTo: familyId),
      batchSize: 300,
    );

    // Delete family document
    await _firestore.collection('families').doc(familyId).delete().catchError((_) {});
  }

  Future<void> _deleteUserScopedData(String userId, String? familyId) async {
    // Tasks assigned to user
    await _pagedDelete(
      collection: 'tasks',
      queryBuilder: (c) => c.where('assignedToUserId', isEqualTo: userId),
    );

    // History owned by user
    await _pagedDelete(
      collection: 'task_history',
      queryBuilder: (c) => c.where('ownerId', isEqualTo: userId),
    );

    // Redemptions by user
    await _pagedDelete(
      collection: 'redemptions',
      queryBuilder: (c) => c.where('ownerId', isEqualTo: userId),
    );

    // Delete user doc
    await _firestore.collection('users').doc(userId).delete().catchError((_) {});
  }

  Future<void> _pagedDelete({
    required String collection,
    required Query Function(Query collectionRef) queryBuilder,
    int batchSize = 200,
  }) async {
    while (true) {
      final query = queryBuilder(_firestore.collection(collection)).limit(batchSize);
      final snap = await query.get();
      if (snap.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      // Continue until no docs remain
    }
  }

  Future<void> _clearLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {
      // Ignore
    }
    // TODO: If Hive boxes are used, clear them here.
  }
}
