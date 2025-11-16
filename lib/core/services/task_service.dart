import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../services/family_service.dart';
import '../injection/injection.dart';
import 'task_generation_service.dart';

/// Service for managing tasks in Firestore
class TaskService {
  static const String _collection = 'tasks';
  
  static FirebaseFirestore? _testFirestore;
  static FirebaseAuth? _testAuth;
  static FamilyService? _testFamilyService;
  static UserModel? _testCurrentUser;

  // Local print override: silence all verbose prints in this service
  void print(Object? object) {}

  static void injectDependencies({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FamilyService? familyService,
    UserModel? currentUser,
  }) {
    _testFirestore = firestore;
    _testAuth = auth;
    _testFamilyService = familyService;
    _testCurrentUser = currentUser;
  }
  
  FirebaseFirestore get _firestore => _testFirestore ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => _testAuth ?? FirebaseAuth.instance;

  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Get current user's family ID from user profile
  String? get _currentFamilyId {
    final currentUser = _testCurrentUser ?? AuthService.currentUser;
    return currentUser?.familyId;
  }

  /// Check if current user can manage tasks
  Future<bool> _canManageTasks() async {
    final currentUser = _testCurrentUser ?? AuthService.currentUser;
    if (currentUser == null) return false;

    try {
      final familyService = _testFamilyService ?? getIt<FamilyService>();
      return familyService.canManageTasks(currentUser);
    } catch (e) {
      // Fallback to checking account type directly
      return currentUser.hasManagementPermissions;
    }
  }

  /// Check if current user can modify specific task
  Future<bool> _canModifyTask(String taskId) async {
    final canManage = await _canManageTasks();
    
    if (!canManage) {
      // Non-admin users can only modify their own pending tasks
      final task = await getTask(taskId);
      if (task == null) return false;
      
      return task.assignedToUserId == _currentUserId && 
             task.status == TaskStatus.pending;
    }
    
    return true;
  }

  /// Create a new task (system-level, bypasses auth checks for family setup)
  Future<String> createTaskForFamily({
    required String familyId,
    required String parentUserId,
    required String title,
    required String description,
    required String category,
    required int pointValue,
    String? assignedToUserId,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    List<String> tags = const [],
    bool isRecurring = false,
    RecurrencePattern? recurrencePattern,
    String? instructions,
    bool showInQuickTasks = true,
  }) async {
    final targetUserId = assignedToUserId ?? parentUserId;
    debugPrint('🎯 Creating task for family: $familyId, assignedTo: $targetUserId');

    final taskId = _firestore.collection(_collection).doc().id;
    
    final task = TaskModel.create(
      id: taskId,
      title: title,
      description: description,
      category: category,
      pointValue: pointValue,
      assignedToUserId: targetUserId,
      assignedByUserId: parentUserId,
      familyId: familyId,
      priority: priority,
      dueDate: dueDate,
      tags: tags,
      isRecurring: isRecurring,
      recurrencePattern: recurrencePattern,
      instructions: instructions,
      showInQuickTasks: showInQuickTasks,
    );

    await _firestore.collection(_collection).doc(taskId).set(task.toFirestore());
    debugPrint('✅ Created task: $title (ID: $taskId)');
    return taskId;
  }

  /// Create a new task
  Future<String> createTask({
    required String title,
    required String description,
    required String category,
    required int pointValue,
    String? assignedToUserId,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    List<String> tags = const [],
    bool isRecurring = false,
    RecurrencePattern? recurrencePattern,
    String? instructions,
    bool showInQuickTasks = true,
    String? parentTaskId,  // ID of the parent task if this is a copy
  }) async {
    if (_currentUserId == null || _currentFamilyId == null) {
      debugPrint('❌ Create task failed - No user authenticated');
      throw Exception('User not authenticated');
    }

    final targetUserId = assignedToUserId ?? _currentUserId!;
    debugPrint('🎯 Creating task with familyId: $_currentFamilyId, assignedTo: $targetUserId');
    
    // Check permissions - users can create tasks for themselves, or parents can create for children
    final canManage = await _canManageTasks();
    final isCreatingForSelf = targetUserId == _currentUserId;
    
    if (!canManage && !isCreatingForSelf) {
      throw Exception('Insufficient permissions to create tasks for other users');
    }

    final taskId = _firestore.collection(_collection).doc().id;
    
    final task = TaskModel.create(
      id: taskId,
      title: title,
      description: description,
      category: category,
      pointValue: pointValue,
      assignedToUserId: targetUserId,
      assignedByUserId: _currentUserId,
      familyId: _currentFamilyId!,
      priority: priority,
      dueDate: dueDate,
      tags: tags,
      isRecurring: isRecurring,
      recurrencePattern: recurrencePattern,
      instructions: instructions,
      showInQuickTasks: showInQuickTasks,
    );

    await _firestore.collection(_collection).doc(taskId).set(task.toFirestore());
    return taskId;
  }

  /// Create a quick task with preset values
  Future<String> createQuickTask({
    required String title,
    String category = 'General',
    int pointValue = 10,
  }) async {
    return createTask(
      title: title,
      description: 'Quick task: $title',
      category: category,
      pointValue: pointValue,
      priority: TaskPriority.medium,
    );
  }

  /// Get task by ID
  Future<TaskModel?> getTask(String taskId) async {
    final doc = await _firestore.collection(_collection).doc(taskId).get();
    if (!doc.exists) return null;
    return TaskModel.fromFirestore(doc);
  }

  /// Get tasks for current family
  Stream<List<TaskModel>> getFamilyTasks({
    TaskStatus? status,
    String? assignedToUserId,
    bool includeCompleted = false,
  }) async* {
    String? effectiveFamilyId = _currentFamilyId;

    // If current user doesn't have a familyId but caller provided an assignedToUserId,
    // try to resolve the familyId from that user (useful when a parent/child context is being inspected).
    if (effectiveFamilyId == null && assignedToUserId != null) {
      try {
        final userDoc = _firestore.collection('users').doc(assignedToUserId).get();
        // not awaiting yet; we'll await below to avoid blocking too early
        effectiveFamilyId = (await userDoc).data()?['familyId'] as String?;
        print('🔍 Resolved familyId from user $assignedToUserId => $effectiveFamilyId');
      } catch (e) {
        print('⚠️ Could not resolve familyId for user $assignedToUserId: $e');
      }
    }

    if (effectiveFamilyId == null) {
      print('📊 getFamilyTasks - No familyId available (current: $_currentFamilyId, resolved: $effectiveFamilyId). Returning empty stream.');
      yield <TaskModel>[];
      return;
    }

  // Build query with proper server-side filters
  var query = _firestore.collection(_collection).where('familyId', isEqualTo: effectiveFamilyId);
    
    // Add assignedToUserId filter on server side if provided
    if (assignedToUserId != null) {
      query = query.where('assignedToUserId', isEqualTo: assignedToUserId);
    }

  // (Server-side tag filtering removed) We'll filter archived/visibility on the client side below.

  yield* query.snapshots().map((snapshot) {
      print('\n📊 Task Query Results:');
      print('  Auth User ID: $_currentUserId');
      print('  Current Family ID (from profile): $_currentFamilyId');
      print('  Effective Family ID (used in query): $effectiveFamilyId');
      print('  AssignedTo filter: ${assignedToUserId ?? '(none)'}');
      print('  Raw Result Count: ${snapshot.docs.length}');
      if (snapshot.docs.isEmpty) {
        print('  ⚠️ Query returned 0 docs. Possible reasons:');
        print('     • Family has no tasks templates');
        print('     • Security rules blocked read');
        print('     • Wrong familyId on user or tasks');
      }
      
      // Group tasks by title to check for duplicates
      final tasksByTitle = <String, List<TaskModel>>{};
      
      var tasks = snapshot.docs.map((doc) {
        try {
          final task = TaskModel.fromFirestore(doc);
          // Extra trace for a few docs
          if (tasksByTitle.length < 3) {
            print('    • Doc ${doc.id}: title="${task.title}", assignedTo=${task.assignedToUserId}, familyId=${task.familyId}, status=${task.status.name}, archived=${task.tags.contains('archived')}');
          }
          if (!tasksByTitle.containsKey(task.title)) {
            tasksByTitle[task.title] = [];
          }
          tasksByTitle[task.title]!.add(task);
          return task;
        } catch (e) {
          print('❌ Error parsing task ${doc.id}: $e');
          return null;
        }
      })
      .where((task) => task != null)
      .cast<TaskModel>()
      .toList();

      // Log any duplicate tasks found
      tasksByTitle.forEach((title, tasks) {
        if (tasks.length > 1) {
          print('\n⚠️ Found ${tasks.length} tasks with title "$title":');
          for (final task in tasks) {
            print('  - Task ID: ${task.id}');
            print('    Assigned to: ${task.assignedToUserId}');
            print('    Status: ${task.status}');
            print('    Created: ${task.createdAt}');
          }
        }
      });

      // Apply status filters
      if (status != null) {
        tasks = tasks.where((task) => task.status == status).toList();
      }

      if (!includeCompleted && status == null) {
        tasks = tasks.where((task) => 
            task.status == TaskStatus.pending || 
            task.status == TaskStatus.inProgress
        ).toList();
      }

      // Sort by creation date
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print('\n📋 Task Summary:');
      print('  Total tasks after filtering: ${tasks.length}');
      print('  Status filter: ${status?.name ?? "none"}');
      print('  Include completed: $includeCompleted');
      if (tasks.isEmpty) {
        print('  ⚠️ After filtering, no tasks remain. Check if all tasks are archived or assigned to other users.');
      }
      print('');
      
      return tasks;
    });
  }

  /// Get tasks assigned to current user
  Stream<List<TaskModel>> getMyTasks({TaskStatus? status}) {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return getFamilyTasks(
      status: status,
      assignedToUserId: _currentUserId,
      includeCompleted: false,
    );
  }

  /// Get all tasks assigned to current user (including completed)
  Stream<List<TaskModel>> getAllMyTasks() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    if (_currentFamilyId == null) {
      // Fallback: Query by user ID only if no family ID
      print('📊 getAllMyTasks - No family ID, using direct user query');
      return _firestore
          .collection(_collection)
          .where('assignedToUserId', isEqualTo: _currentUserId)
          .snapshots()
          .map((snapshot) {
            final tasks = snapshot.docs
                .map((doc) {
                  try {
                    return TaskModel.fromFirestore(doc);
                  } catch (e) {
                    return null;
                  }
                })
                .where((task) => task != null)
                .cast<TaskModel>()
                .where((task) => !task.tags.contains('archived')) // Filter out archived tasks
                .toList();
            
            tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            print('📊 getAllMyTasks - Direct user query found ${tasks.length} tasks');
            return tasks;
          });
    }

    // Try family-based query first, with fallback to direct query if needed
    return _firestore
        .collection(_collection)
        .where('familyId', isEqualTo: _currentFamilyId)
        .snapshots()
        .asyncMap((snapshot) async {
          var tasks = snapshot.docs
              .map((doc) {
                try {
                  return TaskModel.fromFirestore(doc);
                } catch (e) {
                  return null;
                }
              })
              .where((task) => task != null)
              .cast<TaskModel>()
              .where((task) => task.assignedToUserId == _currentUserId)
              .where((task) => !task.tags.contains('archived')) // Filter out archived tasks
              .toList();
          
          print('📊 getAllMyTasks - Family query found ${tasks.length} tasks for user $_currentUserId');
          
          // If no tasks found with family query, try direct query
          if (tasks.isEmpty) {
            print('📊 getAllMyTasks - Family query returned 0 tasks, trying direct query');
            try {
              final directQuery = await _firestore
                  .collection(_collection)
                  .where('assignedToUserId', isEqualTo: _currentUserId)
                  .get();
              
              tasks = directQuery.docs
                  .map((doc) {
                    try {
                      return TaskModel.fromFirestore(doc);
                    } catch (e) {
                      return null;
                    }
                  })
                  .where((task) => task != null)
                  .cast<TaskModel>()
                  .where((task) => !task.tags.contains('archived')) // Filter out archived tasks
                  .toList();
              
              print('📊 getAllMyTasks - Direct query found ${tasks.length} tasks');
            } catch (e) {
              print('❌ getAllMyTasks - Direct query failed: $e');
            }
          }
          
          // Sort on client side
          tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return tasks;
        });
  }

  /// Get pending tasks for current user
  Stream<List<TaskModel>> getMyPendingTasks() {
    return getMyTasks(status: TaskStatus.pending);
  }

  /// Get completed tasks awaiting approval
  Stream<List<TaskModel>> getTasksAwaitingApproval() {
    return getFamilyTasks(status: TaskStatus.completed);
  }

  /// Stream the most recent [days] days of completed history entries for the
  /// current user from the `task_history` collection.
  Stream<List<TaskModel>> getRecentHistoryForCurrentUser({int days = 5}) {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final rangeStart = startOfToday.subtract(Duration(days: days - 1));

    return _firestore
        .collection('task_history')
        .where('ownerId', isEqualTo: _currentUserId)
        .snapshots()
        .map((snapshot) {
          final tasks = snapshot.docs
              .map((doc) {
                try {
                  return TaskModel.fromFirestore(doc);
                } catch (e) {
                  return null;
                }
              })
              .where((task) => task != null)
              .cast<TaskModel>()
              .where((task) {
                final completedAt = task.completedAt;
                if (completedAt == null) {
                  return false;
                }
                return !completedAt.isBefore(rangeStart);
              })
              .toList();

          tasks.sort((a, b) {
            final aMoment = a.completedAt ?? a.dueDate ?? a.createdAt;
            final bMoment = b.completedAt ?? b.dueDate ?? b.createdAt;
            return bMoment.compareTo(aMoment);
          });

          return tasks;
        });
  }

  /// Update task status
  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    final updates = <String, dynamic>{
      'status': status.name,
    };

    if (status == TaskStatus.completed) {
      updates['completedAt'] = Timestamp.now();
    } else if (status == TaskStatus.approved) {
      updates['approvedAt'] = Timestamp.now();
      updates['approvedByUserId'] = _currentUserId;
    }

    await _firestore.collection(_collection).doc(taskId).update(updates);
  }

  /// Mark task as completed
  Future<void> completeTask(String taskId) async {
    // First, try to fetch the live task. Sometimes the UI may pass an
    // id that points to a history document (ids generated by templates
    // are written to `task_history` and include a date suffix). If the
    // doc does not exist in the live `tasks` collection, fall back to
    // updating the `task_history` document instead.
    final taskDoc = await _firestore.collection(_collection).doc(taskId).get();

    if (!taskDoc.exists) {
      // Likely a history entry — update the task_history document if it exists.
      final historyRef = _firestore.collection('task_history').doc(taskId);
      final historyDoc = await historyRef.get();
      if (!historyDoc.exists) {
        // Nothing to update — surface a clearer error to the caller
        throw Exception('Task not found in tasks or task_history: $taskId');
      }

      await historyRef.update({
        'status': TaskStatus.completed.name,
        'completedAt': Timestamp.now(),
      });

      return;
    }

    // Live task exists — proceed with normal completion flow.
    final task = TaskModel.fromFirestore(taskDoc);

    // Use batch to avoid multiple stream rebuilds (prevents flickering)
    final batch = _firestore.batch();

    // Update current task status
    final taskRef = _firestore.collection(_collection).doc(taskId);
    batch.update(taskRef, {
      'status': TaskStatus.completed.name,
      'completedAt': Timestamp.now(),
    });

    // If it's a recurring task, create the next occurrence in the same batch
  if (task.isRecurring && task.recurrencePattern != null && task.dueDate != null) {
      final nextDueDate = task.recurrencePattern!.getNextDueDate(task.dueDate!);

      // Check if we should continue recurring (end date check)
      if (task.recurrencePattern!.endDate == null || 
          !nextDueDate.isAfter(task.recurrencePattern!.endDate!)) {

        // Create next recurring task in the same batch
        final newTaskRef = _firestore.collection(_collection).doc();
        final newTask = TaskModel.create(
          id: newTaskRef.id,
          title: task.title,
          description: task.description,
          category: task.category,
          pointValue: task.pointValue,
          assignedToUserId: task.assignedToUserId,
          assignedByUserId: task.assignedByUserId,
          familyId: task.familyId,
          priority: task.priority,
          dueDate: nextDueDate,
          tags: task.tags,
          isRecurring: true,
          recurrencePattern: task.recurrencePattern,
          instructions: task.instructions,
          showInQuickTasks: task.showInQuickTasks,
        );

        batch.set(newTaskRef, newTask.toFirestore());
      }
    }

    // Commit all changes in a single atomic operation
    await batch.commit();
  }

  /// Mark task as approved (usually by parent)
  Future<void> approveTask(String taskId) async {
    await updateTaskStatus(taskId, TaskStatus.approved);
  }

  /// Mark task as rejected
  Future<void> rejectTask(String taskId) async {
    await _firestore.collection(_collection).doc(taskId).update({
      'status': TaskStatus.rejected.name,
      'completedAt': null, // Reset completion time
    });
  }

  /// Undo task completion - mark as pending again
  Future<void> undoTaskCompletion(String taskId) async {
    final liveTaskRef = _firestore.collection(_collection).doc(taskId);
    final liveTaskDoc = await liveTaskRef.get();

    if (liveTaskDoc.exists) {
      await liveTaskRef.update({
        'status': TaskStatus.pending.name,
        'completedAt': null,
        'approvedAt': null,
        'approvedByUserId': null,
      });
      return;
    }

    final historyRef = _firestore.collection('task_history').doc(taskId);
    final historyDoc = await historyRef.get();

    if (historyDoc.exists) {
      await historyRef.update({
        'status': TaskStatus.pending.name,
        'completedAt': null,
        'approvedAt': null,
        'approvedByUserId': null,
      });
      return;
    }

    throw Exception('Task not found in tasks or task_history: $taskId');
  }

  /// Undo a reward redemption by deleting the redemption entry from tasks/history.
  Future<void> undoRewardRedemption(String taskId) async {
    final currentUserId = _currentUserId;
    final canManage = await _canManageTasks();

    if (currentUserId == null && !canManage) {
      throw Exception('User not authenticated');
    }

    TaskModel? redemption;

    Future<void> deleteIfAllowed(
      DocumentReference<Map<String, dynamic>> ref,
      DocumentSnapshot<Map<String, dynamic>> doc,
    ) async {
      final task = TaskModel.fromFirestore(doc);
      if (task.category != 'Reward Redemption') {
        throw Exception('Task is not a reward redemption');
      }
      final isOwner = currentUserId != null &&
          task.assignedToUserId == currentUserId;
      if (!canManage && !isOwner) {
        throw Exception('Insufficient permissions to undo redemption');
      }
      await ref.delete();
      redemption ??= task;
    }

    final liveRef = _firestore.collection(_collection).doc(taskId);
    final liveDoc = await liveRef.get();
    if (liveDoc.exists) {
      await deleteIfAllowed(liveRef, liveDoc);
    }

    final historyRef = _firestore.collection('task_history').doc(taskId);
    final historyDoc = await historyRef.get();
    if (historyDoc.exists) {
      await deleteIfAllowed(historyRef, historyDoc);
    }

    if (redemption == null) {
      throw Exception('Redemption not found: $taskId');
    }
  }

  /// Record a reward redemption directly in the history collection.
  Future<String> recordRewardRedemption({
    required String rewardName,
    required int pointCost,
  }) async {
    final currentUser = _testCurrentUser ?? AuthService.currentUser;
    final userId = _currentUserId;
    final familyId = _currentFamilyId ?? currentUser?.familyId;

    if (currentUser == null || userId == null) {
      throw Exception('User not authenticated');
    }

    if (familyId == null) {
      throw Exception('Cannot record redemption without family context');
    }

    final now = DateTime.now();
    final historyRef = _firestore.collection('task_history').doc();
  final dateKey = '${now.year.toString().padLeft(4,'0')}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';

    final redemptionTask = TaskModel(
      id: historyRef.id,
      title: 'Reward: $rewardName',
      description: 'Redeemed reward: $rewardName (-$pointCost points)',
      category: 'Reward Redemption',
      pointValue: -pointCost,
      status: TaskStatus.completed,
      priority: TaskPriority.medium,
      assignedToUserId: userId,
      assignedByUserId: currentUser.id,
      familyId: familyId,
      createdAt: now,
      dueDate: null,
      completedAt: now,
      approvedAt: null,
      approvedByUserId: null,
      tags: const ['reward_redemption'],
      metadata: {
        'rewardName': rewardName,
        'pointCost': pointCost,
        'recordedAt': now.toIso8601String(),
      },
      isRecurring: false,
      recurrencePattern: null,
      instructions: null,
      attachments: const [],
      showInQuickTasks: false,
    );

    final data = redemptionTask.toFirestore();
    data['ownerId'] = userId;
    data['source'] = 'reward_redemption';
  data['generatedForDate'] = dateKey;

    await historyRef.set(data);
    return historyRef.id;
  }

  /// Fetch reward redemptions for the current or specified user from history.
  Future<List<TaskModel>> getRewardRedemptions({
    String? userId,
    DateTime? start,
    DateTime? end,
  }) async {
    final targetUserId = userId ?? _currentUserId;
    if (targetUserId == null) {
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection('task_history')
          .where('ownerId', isEqualTo: targetUserId)
          .get();

      final redemptions = <TaskModel>[];

      for (final doc in snapshot.docs) {
        try {
          final task = TaskModel.fromFirestore(doc);
          if (task.category != 'Reward Redemption') {
            continue;
          }

          final moment = task.completedAt ?? task.createdAt;

          if (start != null && moment.isBefore(start)) {
            continue;
          }

          if (end != null && !moment.isBefore(end)) {
            continue;
          }

          redemptions.add(task);
        } catch (e) {
          debugPrint('❌ Error parsing redemption ${doc.id}: $e');
        }
      }

      redemptions.sort((a, b) {
        final aMoment = a.completedAt ?? a.createdAt;
        final bMoment = b.completedAt ?? b.createdAt;
        return bMoment.compareTo(aMoment);
      });

      return redemptions;
    } catch (e) {
      debugPrint('❌ Error fetching reward redemptions: $e');
      return [];
    }
  }

  /// Calculate net points (earned minus redeemed) from history for a user.
  Future<int> getNetPointsFromHistory({String? userId}) async {
    final targetUserId = userId ?? _currentUserId;
    if (targetUserId == null) {
      return 0;
    }

    try {
      final snapshot = await _firestore
          .collection('task_history')
          .where('ownerId', isEqualTo: targetUserId)
          .get();

      var total = 0;

      for (final doc in snapshot.docs) {
        try {
          final task = TaskModel.fromFirestore(doc);
          if (task.status == TaskStatus.completed ||
              task.status == TaskStatus.approved) {
            total += task.pointValue;
          }
        } catch (e) {
          debugPrint('❌ Error parsing history entry ${doc.id}: $e');
        }
      }

      return total;
    } catch (e) {
      debugPrint('❌ Error calculating net points from history: $e');
      return 0;
    }
  }

  /// Update task details
  Future<void> updateTask(String taskId, {
    String? title,
    String? description,
    String? category,
    int? pointValue,
    TaskPriority? priority,
    DateTime? dueDate,
    List<String>? tags,
    String? instructions,
    bool? showInQuickTasks,
    bool? isRecurring,
    RecurrencePattern? recurrencePattern,
  }) async {
    // Check permissions
    if (!(await _canModifyTask(taskId))) {
      throw Exception('Insufficient permissions to update task');
    }
    
    final updates = <String, dynamic>{};

    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (category != null) updates['category'] = category;
    if (pointValue != null) updates['pointValue'] = pointValue;
    if (priority != null) updates['priority'] = priority.name;
    if (dueDate != null) updates['dueDate'] = Timestamp.fromDate(dueDate);
    if (tags != null) updates['tags'] = tags;
    if (instructions != null) updates['instructions'] = instructions;
    if (showInQuickTasks != null) updates['showInQuickTasks'] = showInQuickTasks;
    if (isRecurring != null) updates['isRecurring'] = isRecurring;
    
    // Always update recurrence fields when isRecurring is provided
    if (isRecurring != null) {
      if (isRecurring == false) {
        // Task is being set to non-recurring, clear the pattern
        updates['recurrencePattern'] = null;
      } else if (recurrencePattern != null) {
        // Task is recurring and has a pattern
        updates['recurrencePattern'] = recurrencePattern.toJson();
      }
    } else if (recurrencePattern != null) {
      // Only pattern provided, use it
      updates['recurrencePattern'] = recurrencePattern.toJson();
    }

    if (updates.isNotEmpty) {
      await _firestore.collection(_collection).doc(taskId).update(updates);
    }
  }

  /// Delete task
  Future<void> deleteTask(String taskId) async {
    // Check permissions
    if (!(await _canModifyTask(taskId))) {
      throw Exception('Insufficient permissions to delete task');
    }
    
    // Get the task to check its status
    final taskDoc = await _firestore.collection(_collection).doc(taskId).get();
    if (!taskDoc.exists) {
      throw Exception('Task not found');
    }
    
    final task = TaskModel.fromFirestore(taskDoc);
    
    // Never delete completed or approved tasks - always archive them
    if (task.status == TaskStatus.completed || task.status == TaskStatus.approved) {
      await _archiveTask(taskId, task);
      debugPrint('🔒 Task preserved as history: ${task.title} (${task.id})');
      return;
    }
    
    // For pending tasks, check if there's a completed version in history
    final completedVersionQuery = await _firestore
        .collection(_collection)
        .where('title', isEqualTo: task.title)
        .where('assignedToUserId', isEqualTo: task.assignedToUserId)
        .where('tags', arrayContains: 'archived')
        .get();
        
    if (completedVersionQuery.docs.isNotEmpty) {
      // There's a completed version in history - only delete this pending instance
      await _firestore.collection(_collection).doc(taskId).delete();
      debugPrint('✅ Deleted pending task while preserving completed history: ${task.title}');
    } else {
      // No completed version exists - safe to delete
      await _firestore.collection(_collection).doc(taskId).delete();
      debugPrint('🗑️ Deleted task with no history: ${task.title}');
    }
  }
  
  /// Archive a completed task instead of deleting it to preserve history
  Future<void> _archiveTask(String taskId, TaskModel task) async {
    try {
      // Create archived version with special tag and metadata
      final archivedTask = TaskModel(
        id: task.id,
        title: task.title,
        description: task.description,
        category: task.category,
        pointValue: task.pointValue,
        status: task.status,
        createdAt: task.createdAt,
        dueDate: task.dueDate,
        completedAt: task.completedAt,
        approvedAt: task.approvedAt,
        approvedByUserId: task.approvedByUserId,
        assignedToUserId: task.assignedToUserId,
        assignedByUserId: task.assignedByUserId,
        familyId: task.familyId,
        priority: task.priority,
        tags: [...task.tags, 'archived', 'deleted-by-admin'],
        metadata: {...task.metadata, 'archivedAt': DateTime.now().toIso8601String()},
        isRecurring: task.isRecurring,
        recurrencePattern: task.recurrencePattern,
        instructions: task.instructions,
        attachments: task.attachments,
        showInQuickTasks: false, // Hide archived tasks from quick tasks
      );

      // Move archived task into a separate history collection and remove the live task
      final historyRef = _firestore.collection('task_history').doc(taskId);
      await historyRef.set(archivedTask.toFirestore());
      await _firestore.collection(_collection).doc(taskId).delete();

      print('📦 Moved archived task to task_history: ${task.title} (preserved points history)');
    } catch (e) {
      print('❌ Error archiving task to history: $e');
      // If archiving fails, fall back to deletion
      await _firestore.collection(_collection).doc(taskId).delete();
    }
  }

  /// Get task categories (predefined list for now)
  static List<String> getTaskCategories() {
    return [
      'Chores',
      'Homework',
      'Exercise',
      'Reading',
      'Cleaning',
      'Kitchen Help',
      'Pet Care',
      'Garden Work',
      'Organization',
      'General',
    ];
  }

  /// List quick-task templates visible to the current user.
  /// For family accounts this returns family templates with `showInQuickTasks == true`.
  Future<List<TaskModel>> listQuickTaskTemplates() async {
    if (_currentUserId == null) return [];

    Query query;
    // Resolve effective familyId if current user doesn't have it set yet
    String? effectiveFamilyId = _currentFamilyId;
    if (effectiveFamilyId == null) {
      try {
        final userDoc = await _firestore.collection('users').doc(_currentUserId).get();
        effectiveFamilyId = userDoc.data()?['familyId'] as String?;
        print('🔍 listQuickTaskTemplates: resolved familyId from user doc: $effectiveFamilyId');
      } catch (e) {
        print('⚠️ listQuickTaskTemplates: failed to resolve familyId: $e');
      }
    }

    Query baseQuery = _firestore.collection(_collection).where('showInQuickTasks', isEqualTo: true);

    if (effectiveFamilyId != null) {
      query = baseQuery.where('familyId', isEqualTo: effectiveFamilyId).where('enabled', isEqualTo: true);
      print('🔍 listQuickTaskTemplates: querying family templates for familyId=$effectiveFamilyId');
    } else {
      query = baseQuery.where('assignedToUserId', isEqualTo: _currentUserId).where('enabled', isEqualTo: true);
      print('🔍 listQuickTaskTemplates: querying personal templates for user=$_currentUserId');
    }

    var snap = await query.get();

    // Fallback: if no enabled templates found, try without the enabled filter (handles older docs)
    if (snap.docs.isEmpty) {
      print('⚠️ listQuickTaskTemplates: no templates found with enabled==true, retrying without enabled filter');
      if (effectiveFamilyId != null) {
        snap = await baseQuery.where('familyId', isEqualTo: effectiveFamilyId).get();
      } else {
        snap = await baseQuery.where('assignedToUserId', isEqualTo: _currentUserId).get();
      }
    }

    print('🔎 listQuickTaskTemplates: found ${snap.docs.length} templates');
    return snap.docs.map((d) => TaskModel.fromFirestore(d)).toList();
  }

  /// Add a quick task instance for [userId] for [date] (defaults to today) from a template.
  /// Allows multiple instances per day - checks for existing generated instance and uses timestamp for extras.
  Future<String> addQuickTaskInstance({
    required String templateId,
    required String userId,
    DateTime? date,
  }) async {
    final tmplDoc = await _firestore.collection(_collection).doc(templateId).get();
    if (!tmplDoc.exists) throw Exception('Template not found');

    final tmpl = TaskModel.fromFirestore(tmplDoc);
    final d = date ?? DateTime.now();
    final dateKey = '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
    
    // Check if primary instance (without timestamp) exists
    final primaryId = '${templateId}_${userId}_$dateKey';
    final primaryRef = _firestore.collection('task_history').doc(primaryId);
    final primaryExists = await primaryRef.get();
    
    // If primary doesn't exist, use it; otherwise create new instance with timestamp
    String id;
    DocumentReference ref;
    if (!primaryExists.exists) {
      id = primaryId;
      ref = primaryRef;
      print('✨ Creating primary quick task instance: $id');
    } else {
      // Primary exists, create additional instance with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      id = '${templateId}_${userId}_${dateKey}_$timestamp';
      ref = _firestore.collection('task_history').doc(id);
      print('✨ Creating additional quick task instance: $id (duplicate allowed)');
    }

    final historyData = tmpl.copyWith(
      id: id,
      assignedToUserId: userId,
      assignedByUserId: tmpl.assignedByUserId,
      familyId: tmpl.familyId,
      createdAt: DateTime.now(),
      dueDate: DateTime(d.year, d.month, d.day),
      isRecurring: false, // Make instance non-recurring
      recurrencePattern: null, // Clear recurrence pattern for instance
    ).toFirestore();

    historyData['templateId'] = tmpl.id;
    historyData['ownerId'] = userId;
    historyData['generatedForDate'] = dateKey;
    historyData['createdFromTemplate'] = true;

    await ref.set(historyData);
    return id;
  }

  /// Ensure today's tasks are generated and return a stream of today's history for the current user.
  Stream<List<TaskModel>> getTodayHistoryForCurrentUser() {
    // This function returns a stream but will also trigger generation once when first subscribed.
  // Use a broadcast controller so multiple UI consumers (e.g. multiple
  // StreamBuilders) can listen to the same stream without causing
  // 'Stream has already been listened to' errors.
  final controller = StreamController<List<TaskModel>>.broadcast();

    () async {
      try {
        final userId = _currentUserId;
        if (userId == null) {
          controller.add([]);
          controller.close();
          return;
        }

        final today = DateTime.now();
        final familyId = _currentFamilyId;

        // Trigger generation (idempotent)
        final gen = TaskGenerationService();
        await gen.generateTasksForUserForDate(userId: userId, date: today, familyId: familyId);

        final dateKey = '${today.year.toString().padLeft(4,'0')}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';

        // We'll merge two query streams:
        // 1. Regular generated tasks for today (must have generatedForDate == dateKey)
        // 2. Legacy reward redemptions created/completed today that may lack generatedForDate
        final List<TaskModel> generatedTasks = [];
        final List<TaskModel> redemptionTasks = [];

        void emitCombined() {
          final map = <String, TaskModel>{};
          for (final t in generatedTasks) {
            map[t.id] = t;
          }
            // Ensure we don't lose updated versions of redemption tasks
          for (final r in redemptionTasks) {
            map[r.id] = r;
          }
          controller.add(map.values.toList());
        }

        // Listener 1: Generated tasks
        _firestore.collection('task_history')
          .where('ownerId', isEqualTo: userId)
          .where('generatedForDate', isEqualTo: dateKey)
          .snapshots()
          .listen((snap) {
            generatedTasks
              ..clear()
              ..addAll(snap.docs.map((d) {
                try { return TaskModel.fromFirestore(d); } catch (_) { return null; }
              }).where((t) => t != null).cast<TaskModel>());
            emitCombined();
          }, onError: (e) => controller.addError(e));

        // Listener 2: Reward redemptions completed today (handles legacy entries missing generatedForDate)
        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        _firestore.collection('task_history')
          .where('ownerId', isEqualTo: userId)
          .where('category', isEqualTo: 'Reward Redemption')
          .snapshots()
          .listen((snap) {
            final all = snap.docs.map((d) {
              try { return TaskModel.fromFirestore(d); } catch (_) { return null; }
            }).where((t) => t != null).cast<TaskModel>();
            redemptionTasks
              ..clear()
              ..addAll(all.where((t) {
                final ts = t.completedAt ?? t.createdAt;
                return ts.isAfter(startOfDay) && ts.isBefore(endOfDay);
              }));
            emitCombined();
          }, onError: (e) => controller.addError(e));
      } catch (e, st) {
        controller.addError(e, st);
      }
    }();

    return controller.stream;
  }

  /// Return a stream of history entries for the current user for [date].
  /// This does NOT trigger generation; use for past dates where the history
  /// should already exist. Date is interpreted as local date (year-month-day).
  Stream<List<TaskModel>> getHistoryForDateForCurrentUser(DateTime date) {
  // Use a broadcast controller so multiple UI consumers (e.g. multiple
  // StreamBuilders) can listen to the same stream without causing
  // 'Stream has already been listened to' errors.
  final controller = StreamController<List<TaskModel>>.broadcast();

    () async {
      try {
        final userId = _currentUserId;
        if (userId == null) {
          controller.add([]);
          controller.close();
          return;
        }

        final d = DateTime(date.year, date.month, date.day);
        final dateKey = '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

        _firestore
            .collection('task_history')
            .where('ownerId', isEqualTo: userId)
            .where('generatedForDate', isEqualTo: dateKey)
            .snapshots()
            .listen((snap) {
              final tasks = snap.docs.map((d) {
                try {
                  return TaskModel.fromFirestore(d);
                } catch (_) {
                  return null;
                }
              }).where((t) => t != null).cast<TaskModel>().toList();

              controller.add(tasks);
            }, onError: (e) {
              controller.addError(e);
            });
      } catch (e, st) {
        controller.addError(e, st);
      }
    }();

    return controller.stream;
  }

  /// Get task statistics for current user
  Future<TaskStats> getMyTaskStats() async {
    print('📊 getMyTaskStats - userId: $_currentUserId, familyId: $_currentFamilyId');
    
    if (_currentUserId == null) {
      print('❌ getMyTaskStats - No current user ID');
      return TaskStats.empty();
    }

    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);

      QuerySnapshot? allTasks;
      List<TaskModel> tasks = [];
      
      if (_currentFamilyId != null) {
        // Try family-based query first
        print('📊 getMyTaskStats - Querying with familyId: $_currentFamilyId');
        allTasks = await _firestore
            .collection(_collection)
            .where('assignedToUserId', isEqualTo: _currentUserId)
            .where('familyId', isEqualTo: _currentFamilyId)
            .get();
        
        tasks = allTasks.docs
            .map((doc) => TaskModel.fromFirestore(doc))
            .toList();
        
        print('📊 getMyTaskStats - Family query found ${tasks.length} tasks');
        
        // If no tasks found with family query, try direct query (same as family dashboard)
        if (tasks.isEmpty) {
          print('📊 getMyTaskStats - Family query returned 0 tasks, trying direct query');
          allTasks = await _firestore
              .collection(_collection)
              .where('assignedToUserId', isEqualTo: _currentUserId)
              .get();
          
          tasks = allTasks.docs
              .map((doc) => TaskModel.fromFirestore(doc))
              .toList();
          
          print('📊 getMyTaskStats - Direct query found ${tasks.length} tasks');
        }
      } else {
        // Fallback: Query by user ID only (for cases where family ID is not available)
        print('📊 getMyTaskStats - Querying without familyId (fallback)');
        allTasks = await _firestore
            .collection(_collection)
            .where('assignedToUserId', isEqualTo: _currentUserId)
            .get();
        
        tasks = allTasks.docs
            .map((doc) => TaskModel.fromFirestore(doc))
            .toList();
      }

    print('📊 getMyTaskStats - Found ${tasks.length} tasks total (including archived)');

    // Pull historical completions from task_history so stats/points stay in sync with Rewards tab
    List<TaskModel> historyTasks = [];
    try {
      final historySnap = await _firestore
          .collection('task_history')
          .where('ownerId', isEqualTo: _currentUserId)
          .get();

      historyTasks = historySnap.docs
          .map((doc) {
            try {
              return TaskModel.fromFirestore(doc);
            } catch (e) {
              print('❌ getMyTaskStats - Error parsing history doc ${doc.id}: $e');
              return null;
            }
          })
          .where((t) => t != null)
          .cast<TaskModel>()
          .toList();

      print('📜 getMyTaskStats - Loaded ${historyTasks.length} history entries');
    } catch (e) {
      print('❌ getMyTaskStats - Failed to load task_history: $e');
    }

    // For stats calculation, exclude archived tasks from pending count, but include them in completed/approved counts for points
    final activeTasks = tasks.where((t) => !t.tags.contains('archived')).toList();
    final archivedCompletedTasks = tasks.where((t) => 
        t.tags.contains('archived') && 
        (t.status == TaskStatus.completed || t.status == TaskStatus.approved)
    ).toList();

    final historyCompleted = historyTasks.where((t) => t.status == TaskStatus.completed).toList();
    final historyApproved = historyTasks.where((t) => t.status == TaskStatus.approved).toList();

    final pending = activeTasks.where((t) => t.status == TaskStatus.pending).length;
    final completed = activeTasks.where((t) => t.status == TaskStatus.completed).length +
        archivedCompletedTasks.where((t) => t.status == TaskStatus.completed).length +
        historyCompleted.length;
    final approved = activeTasks.where((t) => t.status == TaskStatus.approved).length +
        archivedCompletedTasks.where((t) => t.status == TaskStatus.approved).length +
        historyApproved.length;

    print('📊 getMyTaskStats - Stats: $pending pending, $completed completed, $approved approved');

    final thisWeek = [
      ...tasks,
      ...historyTasks,
    ]
        .where((t) => 
            t.status == TaskStatus.approved && 
            t.approvedAt != null && 
            t.approvedAt!.isAfter(startOfWeek))
        .length;

    final thisMonth = [
      ...tasks,
      ...historyTasks,
    ]
        .where((t) => 
            t.status == TaskStatus.approved && 
            t.approvedAt != null && 
            t.approvedAt!.isAfter(startOfMonth))
        .length;

    // Include both approved and completed tasks in points calculation
    // Consider history entries too so rewards/points stay accurate
    final totalPoints = [
      ...tasks,
      ...historyTasks,
    ]
        .where((t) => t.status == TaskStatus.approved || t.status == TaskStatus.completed)
        .fold<int>(0, (sum, task) => sum + task.pointValue);

    return TaskStats(
      pending: pending,
      completed: completed,
      approved: approved,
      completedThisWeek: thisWeek,
      completedThisMonth: thisMonth,
      totalPointsEarned: totalPoints,
    );
    } catch (e) {
      print('❌ getMyTaskStats error: $e');
      return TaskStats.empty();
    }
  }

  /// Handle recurring tasks (create next occurrence)
  Future<void> handleRecurringTask(TaskModel task) async {
    if (!task.isRecurring || task.recurrencePattern == null || task.dueDate == null) {
      return;
    }

    final nextDueDate = task.recurrencePattern!.getNextDueDate(task.dueDate!);
    
    // Check if we should continue recurring (end date check)
    if (task.recurrencePattern!.endDate != null && 
        nextDueDate.isAfter(task.recurrencePattern!.endDate!)) {
      return;
    }

    await createTask(
      title: task.title,
      description: task.description,
      category: task.category,
      pointValue: task.pointValue,
      assignedToUserId: task.assignedToUserId,
      priority: task.priority,
      dueDate: nextDueDate,
      tags: task.tags,
      isRecurring: true,
      recurrencePattern: task.recurrencePattern,
      instructions: task.instructions,
    );
  }

  /// Assign existing family tasks to a new child
  Future<void> assignExistingTasksToNewChild({
    required String childUserId,
    required String familyId,
  }) async {
    try {
      debugPrint('🎯 Generating tasks for new child: $childUserId in family: $familyId');
      
      // First, verify that family templates exist
      final templateQuery = await _firestore
          .collection('tasks')
          .where('familyId', isEqualTo: familyId)
          .get();
      debugPrint('📋 Found ${templateQuery.docs.length} family template tasks');
      
      if (templateQuery.docs.isEmpty) {
        debugPrint('⚠️ No family templates found for familyId: $familyId');
        debugPrint('   This might be because templates were not created when the family was set up.');
        return;
      }
      
      // Clear any existing generation marker so we can regenerate with the new familyId
      final generationService = TaskGenerationService();
      await generationService.clearGenerationMarker(
        userId: childUserId,
        date: DateTime.now(),
      );
      debugPrint('🧹 Cleared generation marker for child: $childUserId');
      
      // Use TaskGenerationService to materialize templates into task_history
      final generated = await generationService.generateTasksForUserForDate(
        userId: childUserId,
        date: DateTime.now(),
        familyId: familyId,
      );
      
      debugPrint('✅ Generated ${generated.length} tasks in task_history for child $childUserId');
      
      if (generated.isEmpty && templateQuery.docs.isNotEmpty) {
        debugPrint('⚠️ Warning: Templates exist but no tasks were generated. Check template configuration.');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error generating tasks for new child: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Check if current user is a child linked to a parent
  Future<bool> isChildLinkedToParent() async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null || !currentUser.accountType.isChild) {
      print('👤 User is not a child account');
      return false;
    }

    // Check if child has a familyId
    if (currentUser.familyId == null) {
      print('👤 Child has no family ID');
      return false;
    }

    try {
      // Look for parent in the same family
      print('🔍 Looking for parent in family: ${currentUser.familyId}');
      final familyService = getIt<FamilyService>();
      return await familyService.hasActiveParent(currentUser.familyId!);
    } catch (e) {
      print('❌ Error checking parent link: $e');
      return false;
    }
  }
}

/// Task statistics data class
class TaskStats {
  final int pending;
  final int completed;
  final int approved;
  final int completedThisWeek;
  final int completedThisMonth;
  final int totalPointsEarned;

  const TaskStats({
    required this.pending,
    required this.completed,
    required this.approved,
    required this.completedThisWeek,
    required this.completedThisMonth,
    required this.totalPointsEarned,
  });

  factory TaskStats.empty() => const TaskStats(
    pending: 0,
    completed: 0,
    approved: 0,
    completedThisWeek: 0,
    completedThisMonth: 0,
    totalPointsEarned: 0,
  );

  int get total => pending + completed + approved;
}