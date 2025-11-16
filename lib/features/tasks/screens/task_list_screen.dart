import 'package:flutter/material.dart';
import '../../../core/services/task_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/task_model.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TaskService _taskService = TaskService();
  bool _isChildLinkedToParent = false;
  final bool _isSyncing = false;
  
  // Single stream subscription to prevent multiple rebuilds
  late final Stream<List<TaskModel>> _tasksStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Use today's materialized history as the source of truth for today's view
    _tasksStream = _taskService.getTodayHistoryForCurrentUser();
    _checkChildParentStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending', icon: Icon(Icons.pending)),
            Tab(text: 'Completed', icon: Icon(Icons.check_circle)),
            Tab(text: 'All Tasks', icon: Icon(Icons.list)),
          ],
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      body: StreamBuilder<List<TaskModel>>(
        stream: _tasksStream,
        builder: (context, snapshot) {
          return TabBarView(
            controller: _tabController,
            children: [
              // Pending Tasks
              Builder(
                builder: (context) {
                  if (snapshot.hasData) {
                    final pendingTasks = snapshot.data!.where((task) => task.status == TaskStatus.pending).toList();
                    final pendingSnapshot = AsyncSnapshot.withData(ConnectionState.active, pendingTasks);
                    return _buildTaskList(pendingSnapshot, 'No pending tasks');
                  }
                  return _buildTaskList(snapshot, 'No pending tasks');
                },
              ),

              // Completed Tasks
              Builder(
                builder: (context) {
                  if (snapshot.hasData) {
                    final completedTasks = snapshot.data!.where((task) => task.status == TaskStatus.completed).toList();
                    final completedSnapshot = AsyncSnapshot.withData(ConnectionState.active, completedTasks);
                    return _buildTaskList(completedSnapshot, 'No completed tasks');
                  }
                  return _buildTaskList(snapshot, 'No completed tasks');
                },
              ),

              // All Tasks
              Builder(
                builder: (context) {
                  return _buildTaskList(snapshot, 'No tasks found');
                },
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildTaskList(AsyncSnapshot<List<TaskModel>> snapshot, String emptyMessage) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (snapshot.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading tasks',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              snapshot.error.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final tasks = snapshot.data ?? [];

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildTaskCard(task);
      },
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and points
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.stars,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${task.pointValue}',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Description
            if (task.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  task.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

            // Category and Priority Row
            Row(
              children: [
                // Category
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.category,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Priority
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(task.priority).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getPriorityColor(task.priority),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.priority.displayName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getPriorityColor(task.priority),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Status
                _buildStatusChip(task.status, theme),
              ],
            ),

            // Due date and created date
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  if (task.dueDate != null) ...[
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: task.isOverdue ? Colors.red : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${_formatDate(task.dueDate!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: task.isOverdue ? Colors.red : theme.colorScheme.onSurfaceVariant,
                        fontWeight: task.isOverdue ? FontWeight.w600 : null,
                      ),
                    ),
                  ],
                  if (task.dueDate != null)
                    const SizedBox(width: 16),
                  // createdAt is non-nullable on TaskModel, always show it
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Created: ${_formatDate(task.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  // Quick Task toggle
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: () => _toggleQuickTask(task),
                      icon: Icon(
                        task.showInQuickTasks ? Icons.flash_on : Icons.flash_off,
                        size: 16,
                      ),
                      label: Text(
                        task.showInQuickTasks ? 'Remove from Quick Tasks' : 'Add to Quick Tasks',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: task.showInQuickTasks 
                            ? Colors.orange 
                            : theme.colorScheme.primary,
                        side: BorderSide(
                          color: task.showInQuickTasks 
                              ? Colors.orange 
                              : theme.colorScheme.primary,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  
                  if (task.status == TaskStatus.pending) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _completeTask(task),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Complete', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(TaskStatus status, ThemeData theme) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case TaskStatus.pending:
        backgroundColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orange;
        icon = Icons.pending;
        break;
      case TaskStatus.inProgress:
        backgroundColor = Colors.blue.withOpacity(0.2);
        textColor = Colors.blue;
        icon = Icons.play_arrow;
        break;
      case TaskStatus.completed:
        backgroundColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case TaskStatus.approved:
        backgroundColor = Colors.purple.withOpacity(0.2);
        textColor = Colors.purple;
        icon = Icons.verified;
        break;
      case TaskStatus.rejected:
        backgroundColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red;
        icon = Icons.cancel;
        break;
      case TaskStatus.cancelled:
        backgroundColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.grey;
        icon = Icons.block;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.urgent:
        return Colors.purple;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    
    if (targetDate == today) {
      return 'Today';
    } else if (targetDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (targetDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}';
    }
  }

  Future<void> _completeTask(TaskModel task) async {
    try {
      await _taskService.completeTask(task.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task "${task.title}" marked as completed!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing task: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _toggleQuickTask(TaskModel task) async {
    try {
      final newValue = !task.showInQuickTasks;
      await _taskService.updateTask(
        task.id,
        showInQuickTasks: newValue,
      );
      
      if (mounted) {
        final action = newValue ? 'added to' : 'removed from';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task "${task.title}" $action Quick Tasks!'),
            backgroundColor: newValue ? Colors.orange : Colors.blue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating task: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Check if current user is a child linked to a parent
  Future<void> _checkChildParentStatus() async {
    final isLinked = await _taskService.isChildLinkedToParent();
    if (mounted) {
      setState(() {
        _isChildLinkedToParent = isLinked;
      });
    }
  }

  // Task sync removed: parent->child sync is no longer supported in the UI.

  /// Build floating action buttons based on user type
  Widget? _buildFloatingActionButtons() {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return null;

    // Show Quick Task button for all users
    if (currentUser.accountType.isChild && _isChildLinkedToParent) {
      // Child linked to parent: show Add Task and Quick Task (no sync)
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Add Task button
          FloatingActionButton(
            heroTag: "add_task_fab",
            onPressed: () => Navigator.pushNamed(context, '/create-task'),
            backgroundColor: Colors.green,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          // Quick Task button
          FloatingActionButton(
            heroTag: "quick_task_fab",
            onPressed: () => Navigator.pushNamed(context, '/quick-tasks'),
            backgroundColor: Colors.orange,
            child: const Icon(Icons.flash_on),
          ),
        ],
      );
    } else if (currentUser.accountType.isChild) {
      // Child not linked to parent: Show both Add Task and Quick Task buttons
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Add Task button
          FloatingActionButton(
            heroTag: "add_task_fab",
            onPressed: () => Navigator.pushNamed(context, '/create-task'),
            backgroundColor: Colors.green,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          // Quick Task button
          FloatingActionButton(
            heroTag: "quick_task_fab",
            onPressed: () => Navigator.pushNamed(context, '/quick-tasks'),
            backgroundColor: Colors.orange,
            child: const Icon(Icons.flash_on),
          ),
        ],
      );
    } else {
      // Parent account: Show both buttons
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Add Task button
          FloatingActionButton(
            heroTag: "add_task_fab",
            onPressed: () => Navigator.pushNamed(context, '/create-task'),
            backgroundColor: Colors.green,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          // Quick Task button
          FloatingActionButton(
            heroTag: "quick_task_fab",
            onPressed: () => Navigator.pushNamed(context, '/quick-tasks'),
            backgroundColor: Colors.orange,
            child: const Icon(Icons.flash_on),
          ),
        ],
      );
    }
  }
}