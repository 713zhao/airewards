import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reward_item.dart';
import '../services/auth_service.dart';
import '../services/family_service.dart';
import '../injection/injection.dart';

class RewardService {
  static final RewardService _instance = RewardService._internal();
  factory RewardService() => _instance;
  RewardService._internal();

  // Suppress all print statements in this class
  void print(Object? object) {}

  static const String _rewardsKey = 'rewards_data';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<RewardItem> _rewards = [];
  final ValueNotifier<List<RewardItem>> _rewardsNotifier = ValueNotifier<List<RewardItem>>([]);

  ValueNotifier<List<RewardItem>> get rewardsStream => _rewardsNotifier;
  List<RewardItem> get rewards => List.unmodifiable(_rewards);

  /// Check if current user can manage rewards
  bool canManageRewards() {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return false;
    
    try {
      final familyService = getIt<FamilyService>();
      return familyService.canManageRewards(currentUser);
    } catch (e) {
      // Fallback to checking account type directly
      return currentUser.hasManagementPermissions;
    }
  }

  Future<void> initialize() async {
    await _loadRewards();
    if (_rewards.isEmpty) {
      await _createDefaultRewards();
    }
  }

  /// Reload rewards from Firestore (useful when child joins family or family data changes)
  Future<void> reloadRewards() async {
    debugPrint('🔄 Reloading rewards from Firestore...');
    await _loadRewards();
    debugPrint('✅ Rewards reloaded: ${_rewards.length} items');
  }

  Future<void> _loadRewards() async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser?.familyId == null) {
        debugPrint('No family ID, loading from local storage');
        await _loadRewardsFromLocal();
        return;
      }

      // Load from Firestore based on familyId
      final querySnapshot = await _firestore
          .collection('rewards')
          .where('familyId', isEqualTo: currentUser!.familyId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        _rewards = querySnapshot.docs
            .map((doc) {
              try {
                final data = doc.data();
                data['id'] = doc.id; // Ensure ID matches document ID
                return RewardItem.fromJson(data);
              } catch (e) {
                debugPrint('Error parsing reward ${doc.id}: $e');
                return null;
              }
            })
            .whereType<RewardItem>()
            .toList();
        
        debugPrint('Loaded ${_rewards.length} rewards from Firestore');
        _rewardsNotifier.value = List<RewardItem>.from(_rewards);
        
        // Also save to local cache
        await _saveRewardsToLocal();
      } else {
        debugPrint('No rewards in Firestore, checking local storage');
        await _loadRewardsFromLocal();
      }
    } catch (e) {
      debugPrint('Error loading rewards from Firestore: $e');
      await _loadRewardsFromLocal();
    }
  }

  Future<void> _loadRewardsFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rewardsJson = prefs.getString(_rewardsKey);
      
      if (rewardsJson != null) {
        final List<dynamic> rewardsList = jsonDecode(rewardsJson);
        _rewards = rewardsList.map((json) => RewardItem.fromJson(json)).toList();
        debugPrint('Loaded ${_rewards.length} rewards from local storage');
      }
      
      _rewardsNotifier.value = List<RewardItem>.from(_rewards);
    } catch (e) {
      debugPrint('Error loading rewards from local storage: $e');
    }
  }

  Future<void> _saveRewards() async {
    try {
      final currentUser = AuthService.currentUser;
      
      // Save to Firestore if user has a family
      if (currentUser?.familyId != null) {
        final batch = _firestore.batch();
        
        for (final reward in _rewards) {
          final docRef = _firestore.collection('rewards').doc(reward.id);
          final rewardWithFamily = reward.copyWith(familyId: currentUser!.familyId);
          batch.set(docRef, rewardWithFamily.toJson(), SetOptions(merge: true));
        }
        
        await batch.commit();
        debugPrint('Saved ${_rewards.length} rewards to Firestore');
      }
      
      // Also save to local cache
      await _saveRewardsToLocal();
      
      // Notify listeners
      _rewardsNotifier.value = List<RewardItem>.from(_rewards);
    } catch (e) {
      debugPrint('Error saving rewards: $e');
    }
  }

  Future<void> _saveRewardsToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rewardsJson = jsonEncode(_rewards.map((r) => r.toJson()).toList());
      await prefs.setString(_rewardsKey, rewardsJson);
    } catch (e) {
      debugPrint('Error saving rewards to local storage: $e');
    }
  }

  /// Create default rewards for a specific family in Firestore
  Future<void> createDefaultRewardsForFamily(String familyId) async {
    try {
      debugPrint('📝 Creating default rewards for family: $familyId');
      
      final defaultRewards = [
        RewardItem(
          id: '${familyId}_1',
          title: 'Movie Night',
          description: 'Choose a family movie for movie night',
          points: 100,
          category: 'Entertainment',
          iconCodePoint: Icons.movie.codePoint,
          colorValue: Colors.blue.value,
          isActive: true,
          familyId: familyId,
          createdAt: DateTime.now(),
        ),
        RewardItem(
          id: '${familyId}_2',
          title: 'Extra Allowance',
          description: 'Get extra pocket money this week',
          points: 200,
          category: 'Money',
          iconCodePoint: Icons.attach_money.codePoint,
          colorValue: Colors.green.value,
          isActive: true,
          familyId: familyId,
          createdAt: DateTime.now(),
        ),
        RewardItem(
          id: '${familyId}_3',
          title: 'Game Time',
          description: 'Extra 30 minutes of game time',
          points: 75,
          category: 'Entertainment',
          iconCodePoint: Icons.games.codePoint,
          colorValue: Colors.orange.value,
          isActive: true,
          familyId: familyId,
          createdAt: DateTime.now(),
        ),
        RewardItem(
          id: '${familyId}_4',
          title: 'Choose Dinner',
          description: 'Pick what we have for dinner tonight',
          points: 150,
          category: 'Food',
          iconCodePoint: Icons.restaurant.codePoint,
          colorValue: Colors.red.value,
          isActive: true,
          familyId: familyId,
          createdAt: DateTime.now(),
        ),
        RewardItem(
          id: '${familyId}_5',
          title: 'New Toy',
          description: 'Pick a new toy from the store',
          points: 300,
          category: 'Shopping',
          iconCodePoint: Icons.toys.codePoint,
          colorValue: Colors.purple.value,
          isActive: true,
          familyId: familyId,
          createdAt: DateTime.now(),
        ),
        RewardItem(
          id: '${familyId}_6',
          title: 'Day Out',
          description: 'Special day trip to somewhere fun',
          points: 500,
          category: 'Activities',
          iconCodePoint: Icons.directions_car.codePoint,
          colorValue: Colors.indigo.value,
          isActive: true,
          familyId: familyId,
          createdAt: DateTime.now(),
        ),
      ];
      
      // Save directly to Firestore
      final batch = _firestore.batch();
      for (final reward in defaultRewards) {
        final docRef = _firestore.collection('rewards').doc(reward.id);
        batch.set(docRef, reward.toJson());
      }
      await batch.commit();
      
      debugPrint('✅ Created ${defaultRewards.length} default rewards for family: $familyId');
    } catch (e) {
      debugPrint('❌ Error creating default rewards for family: $e');
      rethrow;
    }
  }

  Future<void> _createDefaultRewards() async {
    final currentUser = AuthService.currentUser;
    final familyId = currentUser?.familyId;
    
    _rewards = [
      RewardItem(
        id: '1',
        title: 'Movie Night',
        description: 'Choose a family movie for movie night',
        points: 100,
        category: 'Entertainment',
        iconCodePoint: Icons.movie.codePoint,
        colorValue: Colors.blue.value,
        isActive: true,
        familyId: familyId,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      RewardItem(
        id: '2',
        title: 'Extra Allowance',
        description: 'Get extra pocket money this week',
        points: 200,
        category: 'Money',
        iconCodePoint: Icons.attach_money.codePoint,
        colorValue: Colors.green.value,
        isActive: true,
        familyId: familyId,
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      RewardItem(
        id: '3',
        title: 'Game Time',
        description: 'Extra 30 minutes of game time',
        points: 75,
        category: 'Entertainment',
        iconCodePoint: Icons.games.codePoint,
        colorValue: Colors.orange.value,
        isActive: true,
        familyId: familyId,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      RewardItem(
        id: '4',
        title: 'Choose Dinner',
        description: 'Pick what we have for dinner tonight',
        points: 150,
        category: 'Food',
        iconCodePoint: Icons.restaurant.codePoint,
        colorValue: Colors.red.value,
        isActive: true,
        familyId: familyId,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      RewardItem(
        id: '5',
        title: 'New Toy',
        description: 'Pick a new toy from the store',
        points: 300,
        category: 'Shopping',
        iconCodePoint: Icons.toys.codePoint,
        colorValue: Colors.purple.value,
        isActive: true,
        familyId: familyId,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      RewardItem(
        id: '6',
        title: 'Day Out',
        description: 'Special day trip to somewhere fun',
        points: 500,
        category: 'Activities',
        iconCodePoint: Icons.directions_car.codePoint,
        colorValue: Colors.indigo.value,
        isActive: true,
        familyId: familyId,
        createdAt: DateTime.now(),
      ),
    ];
    await _saveRewards();
  }

  Future<String> addReward(RewardItem reward) async {
    if (!canManageRewards()) {
      throw Exception('Insufficient permissions to add rewards');
    }
    
    final newReward = reward.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
    );
    
    _rewards.add(newReward);
    await _saveRewards();
    return newReward.id;
  }

  Future<void> updateReward(RewardItem updatedReward) async {
    if (!canManageRewards()) {
      throw Exception('Insufficient permissions to update rewards');
    }
    
    final index = _rewards.indexWhere((r) => r.id == updatedReward.id);
    if (index != -1) {
      _rewards[index] = updatedReward.copyWith(
        updatedAt: DateTime.now(),
      );
      await _saveRewards();
    }
  }

  Future<void> deleteReward(String id) async {
    if (!canManageRewards()) {
      throw Exception('Insufficient permissions to delete rewards');
    }
    
    _rewards.removeWhere((r) => r.id == id);
    
    // Delete from Firestore
    try {
      await _firestore.collection('rewards').doc(id).delete();
      debugPrint('Deleted reward $id from Firestore');
    } catch (e) {
      debugPrint('Error deleting reward from Firestore: $e');
    }
    
    await _saveRewards();
  }

  Future<void> toggleRewardStatus(String id) async {
    if (!canManageRewards()) {
      throw Exception('Insufficient permissions to modify rewards');
    }
    
    final index = _rewards.indexWhere((r) => r.id == id);
    if (index != -1) {
      _rewards[index] = _rewards[index].copyWith(
        isActive: !_rewards[index].isActive,
        updatedAt: DateTime.now(),
      );
      await _saveRewards();
    }
  }

  List<RewardItem> getActiveRewards() {
    return _rewards.where((r) => r.isActive).toList();
  }

  List<RewardItem> getAvailableRewards(int currentPoints) {
    return getActiveRewards().where((r) => currentPoints >= r.points).toList();
  }

  List<RewardItem> searchRewards(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _rewards.where((r) =>
      r.title.toLowerCase().contains(lowercaseQuery) ||
      r.description.toLowerCase().contains(lowercaseQuery) ||
      r.category.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }
}