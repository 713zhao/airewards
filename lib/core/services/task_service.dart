import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';

/// Service for managing tasks in Firestore
class TaskService {
  static const String _collection = 'tasks';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Get current user's family ID (for now, use user ID as family ID)
  String? get _currentFamilyId => _currentUserId;

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
  }) async {
    if (_currentUserId == null || _currentFamilyId == null) {
      throw Exception('User not authenticated');
    }

    final taskId = _firestore.collection(_collection).doc().id;
    
    final task = TaskModel.create(
      id: taskId,
      title: title,
      description: description,
      category: category,
      pointValue: pointValue,
      assignedToUserId: assignedToUserId ?? _currentUserId!,
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
  }) {
    if (_currentFamilyId == null) {
      return Stream.value([]);
    }

    // Use simple query and filter on client side to avoid index requirements
    return _firestore
        .collection(_collection)
        .where('familyId', isEqualTo: _currentFamilyId)
        .snapshots()
        .map((snapshot) {
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
              .toList();

          // Apply client-side filters
          if (assignedToUserId != null) {
            tasks = tasks.where((task) => task.assignedToUserId == assignedToUserId).toList();
          }

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

    // Use a simpler query that only filters by familyId to avoid index requirements
    // Then filter and sort on the client side
    return _firestore
        .collection(_collection)
        .where('familyId', isEqualTo: _currentFamilyId)
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
              .where((task) => task.assignedToUserId == _currentUserId) // Client-side filtering
              .toList();
          
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
    // Get the task first to check if it's recurring
    final task = await getTask(taskId);
    
    await updateTaskStatus(taskId, TaskStatus.completed);
    
    // If it's a recurring task, create the next occurrence
    if (task != null && task.isRecurring) {
      await handleRecurringTask(task);
    }
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
    await _firestore.collection(_collection).doc(taskId).update({
      'status': TaskStatus.pending.name,
      'completedAt': null, // Reset completion time
      'approvedAt': null, // Reset approval time if any
      'approvedByUserId': null, // Reset approver if any
    });
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
    await _firestore.collection(_collection).doc(taskId).delete();
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

  /// Get task statistics for current user
  Future<TaskStats> getMyTaskStats() async {
    if (_currentUserId == null) {
      return TaskStats.empty();
    }

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    final allTasks = await _firestore
        .collection(_collection)
        .where('assignedToUserId', isEqualTo: _currentUserId)
        .where('familyId', isEqualTo: _currentFamilyId)
        .get();

    final tasks = allTasks.docs
        .map((doc) => TaskModel.fromFirestore(doc))
        .toList();

    final pending = tasks.where((t) => t.status == TaskStatus.pending).length;
    final completed = tasks.where((t) => t.status == TaskStatus.completed).length;
    final approved = tasks.where((t) => t.status == TaskStatus.approved).length;

    final thisWeek = tasks
        .where((t) => 
            t.status == TaskStatus.approved && 
            t.approvedAt != null && 
            t.approvedAt!.isAfter(startOfWeek))
        .length;

    final thisMonth = tasks
        .where((t) => 
            t.status == TaskStatus.approved && 
            t.approvedAt != null && 
            t.approvedAt!.isAfter(startOfMonth))
        .length;

    final totalPoints = tasks
        .where((t) => t.status == TaskStatus.approved)
        .fold<int>(0, (sum, task) => sum + task.pointValue);

    return TaskStats(
      pending: pending,
      completed: completed,
      approved: approved,
      completedThisWeek: thisWeek,
      completedThisMonth: thisMonth,
      totalPointsEarned: totalPoints,
    );
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