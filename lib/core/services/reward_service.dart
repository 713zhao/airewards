import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reward_item.dart';
import '../models/user_model.dart';
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

  Future<void> _loadRewards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rewardsJson = prefs.getString(_rewardsKey);
      
      if (rewardsJson != null) {
        final List<dynamic> rewardsList = jsonDecode(rewardsJson);
        _rewards = rewardsList.map((json) => RewardItem.fromJson(json)).toList();
      }
      
      // Create a new list to trigger ValueListenableBuilder
      _rewardsNotifier.value = List<RewardItem>.from(_rewards);
    } catch (e) {
      debugPrint('Error loading rewards: $e');
      await _createDefaultRewards();
    }
  }

  Future<void> _saveRewards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rewardsJson = jsonEncode(_rewards.map((r) => r.toJson()).toList());
      await prefs.setString(_rewardsKey, rewardsJson);
      // Create a new list to trigger ValueListenableBuilder
      _rewardsNotifier.value = List<RewardItem>.from(_rewards);
    } catch (e) {
      debugPrint('Error saving rewards: $e');
    }
  }

  Future<void> _createDefaultRewards() async {
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