import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/goal_model.dart';
import '../models/transaction_model.dart';
import '../services/auth_service.dart';

/// Service for managing user goals
class GoalService {
  static const String _collection = 'goals';
  
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  GoalService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Get current user's family ID
  String? get _currentFamilyId => AuthService.currentUser?.familyId;

  /// Create a new goal
  Future<String> createGoal(GoalModel goal) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final docRef = await _firestore.collection(_collection).add(goal.toFirestore());
    return docRef.id;
  }

  /// Get active goal for current user
  Future<GoalModel?> getActiveGoal() async {
    if (_currentUserId == null) return null;

    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: _currentUserId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      return GoalModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      print('Error getting active goal: $e');
      return null;
    }
  }

  /// Get active goal stream for current user
  Stream<GoalModel?> watchActiveGoal() {
    final userId = _currentUserId;
    print('🎯 watchActiveGoal called - userId: $userId');
    
    if (userId == null) {
      print('⚠️ No user authenticated, returning null stream');
      return Stream.value(null);
    }

    print('🔍 Setting up Firestore stream for userId: $userId');
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      print('📊 Goal stream update - docs count: ${snapshot.docs.length}');
      if (snapshot.docs.isEmpty) {
        print('ℹ️ No active goals found');
        return null;
      }
      final goal = GoalModel.fromFirestore(snapshot.docs.first);
      print('✅ Active goal found: ${goal.targetDescription}');
      return goal;
    }).handleError((error) {
      print('❌ Error in goal stream: $error');
      return null;
    });
  }

  /// Update goal
  Future<void> updateGoal(String goalId, Map<String, dynamic> updates) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    await _firestore.collection(_collection).doc(goalId).update(updates);
  }

  /// Mark goal as completed
  Future<void> completeGoal(String goalId) async {
    await updateGoal(goalId, {
      'completedAt': Timestamp.now(),
      'isActive': false,
    });
  }

  /// Delete goal
  Future<void> deleteGoal(String goalId) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    await _firestore.collection(_collection).doc(goalId).delete();
  }

  /// Calculate average points per day from last N days of transactions
  Future<double> calculateAveragePointsPerDay({int days = 5}) async {
    if (_currentUserId == null) return 0;

    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: _currentUserId)
          .where('type', isEqualTo: TransactionType.earned.toString().split('.').last)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate))
          .get();

      if (querySnapshot.docs.isEmpty) return 0;

      // Group transactions by day and sum points
      final Map<String, int> pointsByDay = {};
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        final dateKey = '${createdAt.year}-${createdAt.month}-${createdAt.day}';
        final points = data['points'] as int? ?? 0;
        
        pointsByDay[dateKey] = (pointsByDay[dateKey] ?? 0) + points;
      }

      // Calculate average across actual days with activity
      if (pointsByDay.isEmpty) return 0;
      
      final totalPoints = pointsByDay.values.reduce((a, b) => a + b);
      final activeDays = pointsByDay.length;
      
      return totalPoints / activeDays;
    } catch (e) {
      print('Error calculating average points: $e');
      return 0;
    }
  }

  /// Calculate estimated days to reach goal
  Future<int?> calculateDaysToGoal({
    required int targetPoints,
    required int currentPoints,
    int lookbackDays = 5,
  }) async {
    if (currentPoints >= targetPoints) return 0;

    final avgPointsPerDay = await calculateAveragePointsPerDay(days: lookbackDays);
    
    if (avgPointsPerDay <= 0) return null; // No recent activity

    final pointsNeeded = targetPoints - currentPoints;
    final daysNeeded = (pointsNeeded / avgPointsPerDay).ceil();
    
    return daysNeeded;
  }

  /// Get goal history for current user
  Future<List<GoalModel>> getGoalHistory({int limit = 10}) async {
    if (_currentUserId == null) return [];

    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => GoalModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting goal history: $e');
      return [];
    }
  }

  /// Check if user has an active goal
  Future<bool> hasActiveGoal() async {
    final goal = await getActiveGoal();
    return goal != null;
  }

  /// Check and auto-complete goal if reached
  Future<bool> checkAndCompleteGoal(int currentPoints) async {
    final activeGoal = await getActiveGoal();
    
    if (activeGoal == null || !activeGoal.isActive) return false;
    
    if (activeGoal.isGoalCompleted(currentPoints)) {
      await completeGoal(activeGoal.id);
      return true;
    }
    
    return false;
  }
}
