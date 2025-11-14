import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/family.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/account_type.dart';
import 'user_service.dart';
import 'auth_service.dart';
import 'task_service.dart';
import 'reward_service.dart';
import '../injection/injection.dart';

/// Service for managing family relationships and permissions
class FamilyService extends ChangeNotifier {
  static const String _familyKey = 'current_family';
  static const String _familiesKey = 'families_data';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  SharedPreferences? _prefs;
  Family? _currentFamily;
  List<Family> _families = [];
  bool _initialized = false;
  
  /// Current family for the logged-in user
  Family? get currentFamily => _currentFamily;
  
  /// All families (for testing/admin purposes)
  List<Family> get families => List.unmodifiable(_families);
  
  /// Check if the service is initialized
  bool get isInitialized => _initialized;

  /// Initialize the family service
  Future<void> initialize() async {
    if (_initialized) return;
    
    // Quick probe: verify default_tasks.json is loadable (logs success/failure)
    try {
      final jsonStr = await rootBundle.loadString('assets/config/default_tasks.json');
      final parsed = jsonDecode(jsonStr) as List<dynamic>;
      debugPrint('✅ Startup check: default_tasks.json loaded successfully (${parsed.length} tasks)');
    } catch (e) {
      debugPrint('⚠️ Startup check: Could not load default_tasks.json: $e');
    }

    _prefs = await SharedPreferences.getInstance();
    await _loadFamilyData();
    _initialized = true;
    notifyListeners();
  }

  /// Load family data from local storage and Firestore
  Future<void> _loadFamilyData() async {
    if (_prefs == null) return;
    
    try {
      // Load current family
      final currentFamilyJson = _prefs!.getString(_familyKey);
      if (currentFamilyJson != null) {
        final familyData = jsonDecode(currentFamilyJson);
        _currentFamily = Family.fromJson(familyData);
      }
      
      // Load all families
      final familiesJson = _prefs!.getString(_familiesKey);
      if (familiesJson != null) {
        final familiesList = jsonDecode(familiesJson) as List;
        _families = familiesList.map((json) => Family.fromJson(json)).toList();
      }
      
      // If no local family data, try to load from Firestore
      if (_currentFamily == null) {
        await _loadFamilyFromFirestore();
      }
    } catch (e) {
      debugPrint('Error loading family data: $e');
      // Initialize with empty data on error
      _currentFamily = null;
      _families = [];
    }
  }
  
  /// Load family data from Firestore based on user's family ID
  Future<void> _loadFamilyFromFirestore() async {
    try {
      // Get current user from AuthService
      final currentUser = AuthService.currentUser;
      
      if (currentUser?.id == null) return;
      
      // Get user's current family ID
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.id)
          .get();
      
      if (!userDoc.exists) return;
      
      final userData = userDoc.data()!;
      final familyId = userData['familyId'] as String?;
      
      if (familyId == null) return;
      
      // Load family from Firestore
      final familyDoc = await FirebaseFirestore.instance
          .collection('families')
          .doc(familyId)
          .get();
      
      if (familyDoc.exists) {
        final family = Family.fromFirestore(familyDoc);
        
        _currentFamily = family;
        _families = [family];
        
        // Save to local storage
        await _saveFamilyData();
        
        debugPrint('✅ Family loaded from Firestore: ${family.id}');
      }
    } catch (e) {
      debugPrint('❌ Error loading family from Firestore: $e');
    }
  }

  /// Save family data to local storage
  Future<void> _saveFamilyData() async {
    if (_prefs == null || !_initialized) return;
    
    try {
      // Save current family
      if (_currentFamily != null) {
        await _prefs!.setString(_familyKey, jsonEncode(_currentFamily!.toJson()));
      } else {
        await _prefs!.remove(_familyKey);
      }
      
      // Save all families
      final familiesJson = _families.map((family) => family.toJson()).toList();
      await _prefs!.setString(_familiesKey, jsonEncode(familiesJson));
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving family data: $e');
    }
  }

  /// Create a new family with the current user as parent
  Future<Family> createFamily({
    required String name,
    required String parentId,
    String? description,
  }) async {
    final now = DateTime.now();
    final family = Family(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      parentId: parentId,
      childrenIds: [],
      createdAt: now,
      updatedAt: now,
      description: description,
    );
    
    _families.add(family);
    _currentFamily = family;
    
    // Save family to Firestore
    try {
      await FirebaseFirestore.instance
          .collection('families')
          .doc(family.id)
          .set(family.toJson());
      
      debugPrint('✅ Family saved to Firestore: ${family.id}');
    } catch (e) {
      debugPrint('❌ Failed to save family to Firestore: $e');
    }
    
    // Update the parent user's family ID
    await _updateUserFamilyId(parentId, family.id);
    
    // Create default tasks and rewards for the new family
    await _createDefaultFamilyItems(family.id, parentId);
    
    await _saveFamilyData();
    return family;
  }

  /// Public method to create default tasks and rewards (used by settings restore)
  Future<void> createDefaultTasksAndRewards(String familyId, String parentId) async {
    debugPrint('🎯 createDefaultTasksAndRewards - familyId: $familyId, parentId: $parentId');
    await _createDefaultFamilyItems(familyId, parentId);
    debugPrint('✅ createDefaultTasksAndRewards completed');
  }

  /// Create default tasks and rewards for a new family
  Future<void> _createDefaultFamilyItems(String familyId, String parentId) async {
    try {
      debugPrint('🎯 Creating default items for new family: $familyId');
      
      // Ensure parent starts with zero points (new user setup)
      await _resetUserPoints(parentId);
      
      // Create default tasks (templates in tasks collection)
      await _createDefaultTasks(familyId, parentId);
      
      // Generate task_history entries for the parent from the templates
      try {
        debugPrint('📋 Generating initial tasks for parent: $parentId');
        final taskService = TaskService();
        await taskService.assignExistingTasksToNewChild(
          childUserId: parentId,
          familyId: familyId,
        );
        debugPrint('✅ Parent tasks generated successfully');
      } catch (e) {
        debugPrint('⚠️ Error generating parent tasks: $e');
      }
      
      // Create default rewards
      await _createDefaultRewards();
      
      debugPrint('✅ Successfully created default items for family: $familyId');
    } catch (e) {
      debugPrint('❌ Error creating default items for family $familyId: $e');
      // Don't fail family creation if default items fail
    }
  }

  /// Reset user points to zero (for new users or restore operations)
  Future<void> _resetUserPoints(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
            'currentPoints': 0,
            'totalPointsEarned': 0,
            'totalPointsSpent': 0,
            'achievements': [],
          });
      
      debugPrint('🔄 Reset points to 0 for user: $userId');
    } catch (e) {
      debugPrint('❌ Error resetting user points: $e');
    }
  }

  /// Ensure all required task categories are available
  Future<void> _ensureTaskCategoriesExist() async {
    try {
      // Get the predefined categories from TaskService
      final predefinedCategories = TaskService.getTaskCategories();
      
      // In the current implementation, categories are just strings stored with tasks
      // The TaskService.getTaskCategories() provides the available categories
      // No additional setup is needed since categories are created when tasks are created
      
      debugPrint('📂 Available task categories: ${predefinedCategories.join(', ')}');
    } catch (e) {
      debugPrint('❌ Error checking task categories: $e');
    }
  }

  /// Create default tasks for the family
  Future<void> _createDefaultTasks(String familyId, String parentId) async {
    try {
      // Import TaskService here to avoid circular dependencies
      final taskService = TaskService();
      
      // Ensure all required categories exist first
      await _ensureTaskCategoriesExist();
      
  // When restoring settings, we only want to create tasks for the parent
  // (no need to track allFamilyMemberIds here)
      
      debugPrint('📋 Creating default tasks for parent account');
      
      // First, clean up any existing tasks
      final existingTasks = await _firestore
          .collection('tasks')
          .where('familyId', isEqualTo: familyId)
          .get();
          
      if (existingTasks.docs.isNotEmpty) {
        debugPrint('🧹 Cleaning up ${existingTasks.docs.length} existing tasks');
        final batch = _firestore.batch();
        for (final doc in existingTasks.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
      
      // Try to load default tasks from JSON asset first (editable by non-devs)
      List<Map<String, dynamic>> defaultTasks = [];
      try {
        final jsonStr = await rootBundle.loadString('assets/config/default_tasks.json');
        final parsed = jsonDecode(jsonStr) as List<dynamic>;
        defaultTasks = parsed.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        debugPrint('✅ Loaded ${defaultTasks.length} default tasks from assets/config/default_tasks.json');
      } catch (e) {
        debugPrint('⚠️ Could not load default tasks from asset, using built-in defaults: $e');

        // Built-in fallback defaults
          defaultTasks = [
          // Daily Chores
          {
            'title': 'Make Your Bed after you get up',
            'description': 'Make your bed neatly every morning',
            'category': 'Chores',
            'points': 10,
            // per-task recurrence config
            'isRecurring': true,
            'recurrencePattern': {
              'type': 'daily',
              'interval': 1,
            },
            'showInQuickTasks': true,
          },
          {
            'title': 'Take Out Trash',
            'description': 'Take the trash bins to the curb',
            'category': 'Chores',
            'points': 15,
            'isRecurring': true,
            'recurrencePattern': {
              'type': 'daily',
              'interval': 1,
            },
            'showInQuickTasks': true,
          },
          {
            'title': 'Help with Dishes',
            'description': 'Help wash, dry, or put away dishes',
            'category': 'Kitchen Help',
            'points': 15,
            'isRecurring': true,
            'recurrencePattern': {
              'type': 'weekly',
              'interval': 1,
              'daysOfWeek': [1, 2],
            },
            'showInQuickTasks': true,
          },
          // Homework and Learning
          {
            'title': 'Complete Homework',
            'description': 'Finish all assigned homework completely',
            'category': 'Homework',
            'points': 20,
            'isRecurring': true,
            'recurrencePattern': {
              'type': 'daily',
              'interval': 1,
            },
            'showInQuickTasks': false,
          },
          {
            'title': 'Read English Book for 30 Minutes',
            'description': 'Read an English book, magazine, or educational material',
            'category': 'Reading',
            'points': 25,
            'isRecurring': true,
            'recurrencePattern': {
              'type': 'daily',
              'interval': 1,
            },
            'showInQuickTasks': false,
          },
          {
            'title': 'Read Chinese Book for 15 Minutes',
            'description': 'Read Chinese books, stories, or practice Chinese characters',
            'category': 'Reading',
            'points': 20,
            'isRecurring': true,
            'recurrencePattern': {
              'type': 'daily',
              'interval': 1,
            },
            'showInQuickTasks': false,
          },
          // Cleaning and Organization
          {
            'title': 'Clean Your Room',
            'description': 'Organize and clean your bedroom thoroughly',
            'category': 'Cleaning',
            'points': 30,
            'isRecurring': true,
            'recurrencePattern': {
              'type': 'daily',
              'interval': 1,
            },
            'showInQuickTasks': false,
          },
          {
            'title': 'Organize School Supplies',
            'description': 'Keep your school bag and study area organized',
            'category': 'Organization',
            'points': 15,
            'isRecurring': true,
            'recurrencePattern': {
              'type': 'daily',
              'interval': 1,
            },
            'showInQuickTasks': true,
          },
          // Exercise and Health
          {
            'title': 'Exercise for 20 Minutes',
            'description': 'Do physical exercise, sports, or outdoor activities',
            'category': 'Exercise',
            'points': 25,
            'isRecurring': true,
            'recurrencePattern': {
              'type': 'daily',
              'interval': 1,
            },
            'showInQuickTasks': true,
          },
          // Pet Care
          {
            'title': 'Feed Pet',
            'description': 'Feed your pet and provide fresh water',
            'category': 'Pet Care',
            'points': 10,
            'isRecurring': true,
            'recurrencePattern': {
              'type': 'daily',
              'interval': 1,
            },
            'showInQuickTasks': true,
          },
        ];
      }

      // Create tasks only for the parent account
      debugPrint('📋 Creating tasks for parent: $parentId');
      
      // First, clean up any existing tasks
      try {
        final existingTasks = await _firestore
            .collection('tasks')
            .where('assignedToUserId', isEqualTo: parentId)
            .get();
            
        if (existingTasks.docs.isNotEmpty) {
          debugPrint('🧹 Cleaning up ${existingTasks.docs.length} existing tasks');
          final batch = _firestore.batch();
          for (final doc in existingTasks.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        }
      } catch (e) {
        debugPrint('⚠️ Error cleaning up existing tasks: $e');
      }

      // Now create fresh tasks from the JSON
      int createdCount = 0;
      for (final taskData in defaultTasks) {
        try {
          // Add original tag to mark this as a template task
          if (taskData['tags'] == null) {
            taskData['tags'] = [];
          }
          taskData['tags'].add('original');
          // Build recurrence pattern from the taskData if provided (recurrencePattern is now required for recurring tasks).
          RecurrencePattern? recurrence;
          final recPattern = taskData['recurrencePattern'];
          if (recPattern != null && recPattern is Map) {
            recurrence = RecurrencePattern.fromMap(Map<String, dynamic>.from(recPattern));
          }

            debugPrint('📝 Creating family template task: ${taskData['title']} for familyId: $familyId');
            // Create family-wide template (assigned to parent initially, but available for all family members)
            await taskService.createTaskForFamily(
              familyId: familyId,
              parentUserId: parentId,
              title: taskData['title'] as String,
              description: taskData['description'] as String,
              category: taskData['category'] as String,
              pointValue: taskData['points'] as int,
              assignedToUserId: parentId, // Assign to parent as template owner
              // If a recurrence pattern was provided, ensure the stored template is marked recurring.
              isRecurring: recurrence != null ? true : (taskData['isRecurring'] as bool),
              recurrencePattern: recurrence,
              showInQuickTasks: taskData['showInQuickTasks'] as bool,
              tags: ['original', 'parent-template'],  // Mark as original parent task
            );
          createdCount++;
          debugPrint('✅ Created default task: ${taskData['title']}');
        } catch (e) {
          debugPrint('❌ Failed to create task ${taskData['title']}: $e');
        }
      }
      debugPrint('🎉 Successfully created $createdCount default tasks for parent account');
    } catch (e) {
      debugPrint('❌ Error creating default tasks: $e');
    }
  }

  /// Create default rewards for the family
  Future<void> _createDefaultRewards() async {
    try {
      // The RewardService already has a _createDefaultRewards method
      // We'll call the RewardService initialization which creates defaults
      final rewardService = RewardService();
      await rewardService.initialize();
      
      debugPrint('✅ Default rewards initialized via RewardService');
    } catch (e) {
      debugPrint('❌ Error creating default rewards: $e');
    }
  }

  /// Assign default tasks to existing children (utility method for fixing missing tasks)
  Future<void> assignDefaultTasksToExistingChildren() async {
    if (_currentFamily == null) {
      debugPrint('❌ No current family found');
      return;
    }
    
    try {
      debugPrint('🔧 Assigning default tasks to existing children...');
      
      // Get all children in the current family
      final children = await getCurrentFamilyChildren();
      debugPrint('👶 Found ${children.length} children to assign tasks to');
      
      for (final child in children) {
        debugPrint('🎯 Assigning tasks to child: ${child.displayName} (${child.id})');
        
        // Use TaskService to assign existing tasks to this child
        final taskService = TaskService();
        await taskService.assignExistingTasksToNewChild(
          childUserId: child.id,
          familyId: _currentFamily!.id,
        );
        
        debugPrint('✅ Tasks assigned to ${child.displayName}');
      }
      
      debugPrint('🎉 Task assignment completed for all children');
    } catch (e) {
      debugPrint('❌ Error assigning tasks to existing children: $e');
    }
  }

  /// Add a child to the current family
  Future<bool> addChildToFamily({
    required String childId,
    String? familyId,
  }) async {
    final targetFamily = familyId != null 
        ? _families.firstWhere((f) => f.id == familyId, orElse: () => throw Exception('Family not found'))
        : _currentFamily;
    
    if (targetFamily == null) {
      debugPrint('No family found to add child to');
      return false;
    }
    
    // Check if child already exists in any family
    if (_isChildInAnyFamily(childId)) {
      debugPrint('Child is already in a family');
      return false;
    }
    
    // Add child to family
    final updatedFamily = targetFamily.addChild(childId);
    _updateFamilyInList(updatedFamily);
    
    if (_currentFamily?.id == updatedFamily.id) {
      _currentFamily = updatedFamily;
    }
    
    // Update family in Firestore
    try {
      await FirebaseFirestore.instance
          .collection('families')
          .doc(updatedFamily.id)
          .update(updatedFamily.toJson());
      
      debugPrint('✅ Family updated in Firestore: ${updatedFamily.id}');
    } catch (e) {
      debugPrint('❌ Failed to update family in Firestore: $e');
    }
    
    // Update child user's family ID and account type
    await _updateUserFamilyId(childId, updatedFamily.id);
    await _updateUserAccountType(childId, AccountType.child);
    
    // Reset points for new child (fresh start)
    await _resetUserPoints(childId);
    
    // Assign existing family tasks to the new child
    try {
      debugPrint('🎯 Assigning existing tasks to new child: $childId');
      final taskService = TaskService();
      await taskService.assignExistingTasksToNewChild(
        childUserId: childId,
        familyId: updatedFamily.id,
      );
      debugPrint('✅ Tasks assigned successfully to child: $childId');
    } catch (e) {
      debugPrint('⚠️ Error assigning tasks to new child: $e');
      // Don't fail the add process if task assignment fails
    }
    
    await _saveFamilyData();
    return true;
  }

  /// Permanently delete a family and all family-scoped templates and associations.
  /// This will:
  /// - Delete tasks, task_history, redemptions, and rewards belonging to the family
  /// - Delete task generation markers for all family members
  /// - Delete all user documents in the family (including parent and children)
  /// - Delete the family document
  /// - Remove local cached family data
  Future<bool> deleteFamily(String familyId) async {
    try {
      debugPrint('Deleting family: $familyId');

      // 1) Find all users with this familyId and collect their IDs
      final usersQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('familyId', isEqualTo: familyId)
          .get();

      // Separate parent and children
      String? parentId;
      final List<String> childIds = [];
      for (final doc in usersQuery.docs) {
        final data = doc.data();
        if (data['accountType'] == 'parent') {
          parentId = doc.id;
        } else {
          childIds.add(doc.id);
        }
      }
      debugPrint('Found ${childIds.length} children and parent: $parentId');

      // 2) Delete task generation markers for all children
      if (childIds.isNotEmpty) {
        try {
          debugPrint('Deleting task generation markers for ${childIds.length} children');
          int markerCount = 0;
          // Delete markers in batches
          for (final userId in childIds) {
            try {
              final userMarkersQuery = await FirebaseFirestore.instance
                  .collection('task_generation_markers')
                  .where('userId', isEqualTo: userId)
                  .get();
              if (userMarkersQuery.docs.isNotEmpty) {
                final batch = FirebaseFirestore.instance.batch();
                for (final markerDoc in userMarkersQuery.docs) {
                  batch.delete(markerDoc.reference);
                  markerCount++;
                }
                await batch.commit();
                debugPrint('  Deleted ${userMarkersQuery.docs.length} markers for child: $userId');
              }
            } catch (userMarkerError) {
              debugPrint('WARNING: Failed to delete markers for child $userId: $userMarkerError');
            }
          }
          if (markerCount > 0) {
            debugPrint('SUCCESS: Deleted total $markerCount task generation markers');
          }
        } catch (e) {
          debugPrint('WARNING: Failed to delete task generation markers: $e');
          // Continue with deletion even if marker cleanup fails
        }
      }

      // 3) Delete family-scoped collections using paging
      Future<void> _pagedDelete(String collection, {int batchSize = 300}) async {
        debugPrint('Deleting from collection: $collection (familyId: $familyId)');
        int totalDeleted = 0;
        while (true) {
          final snap = await FirebaseFirestore.instance
              .collection(collection)
              .where('familyId', isEqualTo: familyId)
              .limit(batchSize)
              .get();
          if (snap.docs.isEmpty) break;
          
          debugPrint('  Deleting ${snap.docs.length} documents from $collection');
          final batch = FirebaseFirestore.instance.batch();
          for (final d in snap.docs) {
            batch.delete(d.reference);
          }
          await batch.commit();
          totalDeleted += snap.docs.length;
        }
        if (totalDeleted > 0) {
          debugPrint('SUCCESS: Deleted $totalDeleted total documents from $collection');
        }
      }

      debugPrint('Starting deletion of family-scoped collections...');
      await _pagedDelete('tasks');
      await _pagedDelete('task_history');
      await _pagedDelete('redemptions');
      await _pagedDelete('rewards');

      // 4) Delete all child user documents in the family
      debugPrint('Deleting ${childIds.length} child user documents');
      if (childIds.isNotEmpty) {
        // Delete children in batches to avoid exceeding Firestore batch size limits
        const userBatchSize = 400; // Leave room for other operations
        for (int i = 0; i < childIds.length; i += userBatchSize) {
          final batch = FirebaseFirestore.instance.batch();
          final endIndex = (i + userBatchSize < childIds.length) ? i + userBatchSize : childIds.length;
          for (int j = i; j < endIndex; j++) {
            final userId = childIds[j];
            batch.delete(FirebaseFirestore.instance.collection('users').doc(userId));
          }
          await batch.commit();
          debugPrint('  Deleted children ${i + 1} to $endIndex');
        }
        debugPrint('SUCCESS: Deleted all ${childIds.length} child user documents');
      }

      // 5) Update parent user document to remove familyId and related fields
      if (parentId != null) {
        await FirebaseFirestore.instance.collection('users').doc(parentId).update({
          'familyId': null,
          'role': 'parent',
          'accountType': 'parent',
          'childrenIds': [],
          // Add any other family-related fields to clear
        });
        debugPrint('Parent user $parentId updated to remove family association');
      }

      // 5) Delete the family document
      await FirebaseFirestore.instance.collection('families').doc(familyId).delete().catchError((e) {
        debugPrint('WARNING: Deleting family doc error: $e');
      });

      // 6) Remove from local cache
      _families.removeWhere((f) => f.id == familyId);
      if (_currentFamily?.id == familyId) {
        _currentFamily = null;
        await _saveFamilyData();
      }

      debugPrint('SUCCESS: Family deleted successfully: $familyId');
      return true;
    } catch (e) {
      debugPrint('ERROR: deleteFamily failed: $e');
      return false;
    }
  }

  /// Remove a child from the family
  Future<bool> removeChildFromFamily(String childId) async {
    if (_currentFamily == null) return false;
    
    final updatedFamily = _currentFamily!.removeChild(childId);
    _currentFamily = updatedFamily;
    _updateFamilyInList(updatedFamily);
    
    // Remove family ID from child user
    await _updateUserFamilyId(childId, null);
    
    await _saveFamilyData();
    return true;
  }

  /// Get family by ID
  Family? getFamilyById(String familyId) {
    try {
      return _families.firstWhere((f) => f.id == familyId);
    } catch (e) {
      return null;
    }
  }

  /// Get family for a specific user
  Family? getFamilyForUser(String userId) {
    return _families.where((f) => f.isMember(userId)).firstOrNull;
  }

  /// Check if user is parent of current family
  bool isParentOfCurrentFamily(String userId) {
    return _currentFamily?.isParent(userId) ?? false;
  }

  /// Check if user is child in current family
  bool isChildInCurrentFamily(String userId) {
    return _currentFamily?.isChild(userId) ?? false;
  }

  /// Get all children in current family
  Future<List<UserModel>> getCurrentFamilyChildren() async {
    if (_currentFamily == null) return [];
    
    final userService = getIt<UserService>();
    final children = <UserModel>[];
    
    for (final childId in _currentFamily!.childrenIds) {
      final child = await userService.getUser(childId);
      if (child != null) {
        children.add(child);
      }
    }
    
    return children;
  }

  /// Get parent of current family
  Future<UserModel?> getCurrentFamilyParent() async {
    if (_currentFamily == null) return null;
    
    final userService = getIt<UserService>();
    return await userService.getUser(_currentFamily!.parentId);
  }

  /// Switch to a different family (for parents who might manage multiple families)
  Future<void> switchToFamily(String familyId) async {
    final family = getFamilyById(familyId);
    if (family != null) {
      _currentFamily = family;
      await _saveFamilyData();
    }
  }

  /// Generate invitation code for family
  String generateInvitationCode() {
    if (_currentFamily == null) return '';
    
    // Simple invitation code - in production, this would be more secure
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${_currentFamily!.id}-$timestamp'.substring(0, 8).toUpperCase();
  }

  /// Join family using invitation code
  /// Returns the familyId if successful, null otherwise
  Future<String?> joinFamilyWithCode({
    required String invitationCode,
    required String userId,
  }) async {
    // Simple code validation - in production, this would involve server validation
    try {
      final parts = invitationCode.toLowerCase().split('-');
      if (parts.isEmpty) return null;
      
      // Find family (simplified - in production, use proper invitation system)
      final family = _families.firstWhere((f) => f.id.startsWith(parts.first), orElse: () => throw Exception());
      
      final success = await addChildToFamily(childId: userId, familyId: family.id);
      return success ? family.id : null;
    } catch (e) {
      debugPrint('Invalid invitation code: $e');
      return null;
    }
  }

  /// Update a family in the families list
  void _updateFamilyInList(Family updatedFamily) {
    final index = _families.indexWhere((f) => f.id == updatedFamily.id);
    if (index != -1) {
      _families[index] = updatedFamily;
    }
  }

  /// Check if child is already in any family
  bool _isChildInAnyFamily(String childId) {
    return _families.any((f) => f.isChild(childId));
  }

  /// Helper method to update user's family ID
  Future<void> _updateUserFamilyId(String userId, String? familyId) async {
    try {
      final userService = getIt<UserService>();
      final user = await userService.getUser(userId);
      if (user != null) {
        final updatedUser = user.copyWith(familyId: familyId);
        await userService.updateUser(updatedUser);
      }
    } catch (e) {
      debugPrint('Error updating user family ID: $e');
    }
  }

  /// Helper method to update user's account type
  Future<void> _updateUserAccountType(String userId, AccountType accountType) async {
    try {
      final userService = getIt<UserService>();
      final user = await userService.getUser(userId);
      if (user != null) {
        final updatedUser = user.copyWith(accountType: accountType);
        await userService.updateUser(updatedUser);
      }
    } catch (e) {
      debugPrint('Error updating user account type: $e');
    }
  }

  /// Clear all family data (for testing/logout)
  Future<void> clearFamilyData() async {
    _currentFamily = null;
    _families.clear();
    
    if (_prefs != null) {
      await _prefs!.remove(_familyKey);
      await _prefs!.remove(_familiesKey);
    }
    
    notifyListeners();
  }

  /// Check if current user has permission to manage family
  bool canManageFamily(UserModel user) {
    return user.hasManagementPermissions && isParentOfCurrentFamily(user.id);
  }

  /// Check if user can manage tasks
  bool canManageTasks(UserModel user) {
    return user.hasManagementPermissions;
  }

  /// Check if user can manage rewards
  bool canManageRewards(UserModel user) {
    return user.hasManagementPermissions;
  }

  /// Get family statistics
  Map<String, dynamic> getFamilyStatistics() {
    if (_currentFamily == null) return {};
    
    return {
      'familyName': _currentFamily!.name,
      'childrenCount': _currentFamily!.childrenCount,
      'createdAt': _currentFamily!.createdAt,
      'hasChildren': _currentFamily!.hasChildren,
    };
  }

  /// Check if a family has an active parent
  Future<bool> hasActiveParent(String familyId) async {
    try {
      final family = getFamilyById(familyId);
      if (family == null) return false;

      final parent = await getCurrentFamilyParent();
      return parent != null && parent.accountType.isParent;
    } catch (e) {
      debugPrint('❌ Error checking for active parent: $e');
      return false;
    }
  }
}

/// Extension to add firstOrNull method (if not available)
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    return isEmpty ? null : first;
  }
}