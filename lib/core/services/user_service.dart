import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

/// User service for managing user data in Firestore
class UserService {
  static const String _collection = 'users';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new user
  Future<void> createUser(UserModel user) async {
    try {
      debugPrint('👤 Creating user: ${user.id}');
      
      await _firestore
          .collection(_collection)
          .doc(user.id)
          .set(user.toFirestore());
      
      debugPrint('✅ User created successfully: ${user.displayName}');
    } catch (e) {
      debugPrint('❌ Failed to create user: $e');
      rethrow;
    }
  }

  /// Get a user by ID
  Future<UserModel?> getUser(String userId) async {
    try {
      debugPrint('👤 Getting user: $userId');
      
      final doc = await _firestore
          .collection(_collection)
          .doc(userId)
          .get();
      
      if (doc.exists) {
        final user = UserModel.fromFirestore(doc);
        debugPrint('✅ User found: ${user.displayName}');
        return user;
      } else {
        debugPrint('⚠️ User not found: $userId');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Failed to get user: $e');
      rethrow;
    }
  }

  /// Update a user
  Future<void> updateUser(UserModel user) async {
    try {
      debugPrint('👤 Updating user: ${user.id}');
      
      await _firestore
          .collection(_collection)
          .doc(user.id)
          .update(user.toFirestore());
      
      debugPrint('✅ User updated successfully: ${user.displayName}');
    } catch (e) {
      debugPrint('❌ Failed to update user: $e');
      rethrow;
    }
  }

  /// Delete a user
  Future<void> deleteUser(String userId) async {
    try {
      debugPrint('👤 Deleting user: $userId');
      
      await _firestore
          .collection(_collection)
          .doc(userId)
          .delete();
      
      debugPrint('✅ User deleted successfully: $userId');
    } catch (e) {
      debugPrint('❌ Failed to delete user: $e');
      rethrow;
    }
  }

  /// Get users by family ID
  Future<List<UserModel>> getUsersByFamily(String familyId) async {
    try {
      debugPrint('👤 Getting users for family: $familyId');
      
      final query = await _firestore
          .collection(_collection)
          .where('familyId', isEqualTo: familyId)
          .where('isActive', isEqualTo: true)
          .get();
      
      final users = query.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
      
      debugPrint('✅ Found ${users.length} users for family: $familyId');
      return users;
    } catch (e) {
      debugPrint('❌ Failed to get users by family: $e');
      rethrow;
    }
  }

  /// Search users by email
  Future<List<UserModel>> searchUsersByEmail(String email) async {
    try {
      debugPrint('👤 Searching users by email: $email');
      
      final query = await _firestore
          .collection(_collection)
          .where('email', isEqualTo: email)
          .where('isActive', isEqualTo: true)
          .limit(10)
          .get();
      
      final users = query.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
      
      debugPrint('✅ Found ${users.length} users with email: $email');
      return users;
    } catch (e) {
      debugPrint('❌ Failed to search users by email: $e');
      rethrow;
    }
  }

  /// Add points to user
  Future<void> addPoints(String userId, int points, String reason) async {
    try {
      debugPrint('👤 Adding $points points to user: $userId');
      
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection(_collection).doc(userId);
        final userDoc = await transaction.get(userRef);
        
        if (!userDoc.exists) {
          throw Exception('User not found');
        }
        
        final user = UserModel.fromFirestore(userDoc);
        final updatedUser = user.addPoints(points);
        
        transaction.update(userRef, updatedUser.toFirestore());
      });
      
      debugPrint('✅ Points added successfully to user: $userId');
    } catch (e) {
      debugPrint('❌ Failed to add points to user: $e');
      rethrow;
    }
  }

  /// Spend points from user
  Future<void> spendPoints(String userId, int points, String reason) async {
    try {
      debugPrint('👤 Spending $points points from user: $userId');
      
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection(_collection).doc(userId);
        final userDoc = await transaction.get(userRef);
        
        if (!userDoc.exists) {
          throw Exception('User not found');
        }
        
        final user = UserModel.fromFirestore(userDoc);
        
        if (!user.hasPoints(points)) {
          throw Exception('Insufficient points');
        }
        
        final updatedUser = user.spendPoints(points);
        transaction.update(userRef, updatedUser.toFirestore());
      });
      
      debugPrint('✅ Points spent successfully from user: $userId');
    } catch (e) {
      debugPrint('❌ Failed to spend points from user: $e');
      rethrow;
    }
  }

  /// Add achievement to user
  Future<void> addAchievement(String userId, String achievement) async {
    try {
      debugPrint('👤 Adding achievement to user: $userId - $achievement');
      
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection(_collection).doc(userId);
        final userDoc = await transaction.get(userRef);
        
        if (!userDoc.exists) {
          throw Exception('User not found');
        }
        
        final user = UserModel.fromFirestore(userDoc);
        final updatedUser = user.addAchievement(achievement);
        
        transaction.update(userRef, updatedUser.toFirestore());
      });
      
      debugPrint('✅ Achievement added successfully to user: $userId');
    } catch (e) {
      debugPrint('❌ Failed to add achievement to user: $e');
      rethrow;
    }
  }

  /// Join family
  Future<void> joinFamily(String userId, String familyId) async {
    try {
      debugPrint('👤 User $userId joining family: $familyId');
      
      final user = await getUser(userId);
      if (user == null) {
        throw Exception('User not found');
      }
      
      final updatedUser = user.copyWith(familyId: familyId);
      await updateUser(updatedUser);
      
      debugPrint('✅ User joined family successfully: $userId');
    } catch (e) {
      debugPrint('❌ Failed to join family: $e');
      rethrow;
    }
  }

  /// Leave family
  Future<void> leaveFamily(String userId) async {
    try {
      debugPrint('👤 User $userId leaving family');
      
      final user = await getUser(userId);
      if (user == null) {
        throw Exception('User not found');
      }
      
      final updatedUser = user.copyWith(familyId: null);
      await updateUser(updatedUser);
      
      debugPrint('✅ User left family successfully: $userId');
    } catch (e) {
      debugPrint('❌ Failed to leave family: $e');
      rethrow;
    }
  }

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      debugPrint('👤 Getting stats for user: $userId');
      
      final user = await getUser(userId);
      if (user == null) {
        throw Exception('User not found');
      }
      
      // Get additional statistics from other collections
      // This would typically involve querying tasks, transactions, etc.
      final stats = {
        'totalPointsEarned': user.totalPointsEarned,
        'totalPointsSpent': user.totalPointsSpent,
        'currentPoints': user.currentPoints,
        'achievementCount': user.achievements.length,
        'memberSince': user.createdAt.toIso8601String(),
        'lastLogin': user.lastLoginAt.toIso8601String(),
      };
      
      debugPrint('✅ User stats retrieved successfully: $userId');
      return stats;
    } catch (e) {
      debugPrint('❌ Failed to get user stats: $e');
      rethrow;
    }
  }

  /// Get user stream for real-time updates
  Stream<UserModel?> getUserStream(String userId) {
    return _firestore
        .collection(_collection)
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return UserModel.fromFirestore(doc);
          }
          return null;
        });
  }

  /// Get family members stream
  Stream<List<UserModel>> getFamilyMembersStream(String familyId) {
    return _firestore
        .collection(_collection)
        .where('familyId', isEqualTo: familyId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((query) {
          return query.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
        });
  }
}