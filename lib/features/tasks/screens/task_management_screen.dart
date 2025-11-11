import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/injection/injection.dart';
import '../../../core/models/task_model.dart';
import '../../../core/services/task_service.dart';
import '../widgets/task_form_dialog.dart';

class TaskManagementScreen extends StatefulWidget {
  const TaskManagementScreen({super.key});

  @override
  State<TaskManagementScreen> createState() => _TaskManagementScreenState();
}

class _TaskManagementScreenState extends State<TaskManagementScreen>
    with TickerProviderStateMixin {
  final TaskService _taskService = getIt<TaskService>();
  late TabController _tabController;
  late final Stream<List<TaskModel>> _tasksStream;
  
  final List<String> _categories = [
    'All',
    ...TaskService.getTaskCategories()
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    // Convert to broadcast so multiple tabs can listen without throwing.
    _tasksStream =
        _taskService.getFamilyTasks(includeCompleted: true).asBroadcastStream();
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
        title: const Text('Task Management'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _categories.map((category) => Tab(text: category)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _categories.map((category) {
          return _buildCategoryView(category);
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryView(String category) {
    return StreamBuilder<List<TaskModel>>(
      stream: _tasksStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final allTasks = snapshot.data ?? [];
        
        // Filter out daily tasks and redemption tasks from task management
        final managementTasks = allTasks.where((task) => 
          task.category != "Daily Tasks" && 
          task.category != "Reward Redemption" &&
          !task.tags.contains("daily-task")
        ).toList();
        
        final filteredTasks = category == 'All' 
            ? managementTasks 
            : managementTasks.where((task) => task.category == category).toList();

        if (filteredTasks.isEmpty) {
          return _buildEmptyState(category);
        }

        return _buildTaskList(filteredTasks);
      },
    );
  }

  Widget _buildEmptyState(String category) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            category == 'All' 
                ? 'No tasks yet' 
                : 'No $category tasks',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first task',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<TaskModel> tasks) {
    // Group tasks by status
    final pendingTasks = tasks.where((task) => !task.isCompleted).toList();
    final completedTasks = tasks.where((task) => task.isCompleted).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pendingTasks.isNotEmpty) ...[
          _buildSectionHeader('Pending Tasks', pendingTasks.length),
          const SizedBox(height: 8),
          ...pendingTasks.map((task) => _buildTaskCard(task)),
          const SizedBox(height: 24),
        ],
        if (completedTasks.isNotEmpty) ...[
          _buildSectionHeader('Completed Tasks', completedTasks.length),
          const SizedBox(height: 8),
          ...completedTasks.map((task) => _buildTaskCard(task)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: task.isCompleted ? 1 : 2,
      child: InkWell(
        onTap: () => _showTaskDetails(task),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(
                width: 4,
                color: _getPriorityColor(task.priority, theme),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            decoration: task.isCompleted 
                                ? TextDecoration.lineThrough 
                                : null,
                            color: task.isCompleted 
                                ? theme.colorScheme.outline 
                                : null,
                          ),
                        ),
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: task.isCompleted 
                                  ? theme.colorScheme.outline 
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _handleTaskAction('edit', task),
                        icon: const Icon(Icons.edit),
                        tooltip: 'Edit',
                        iconSize: 20,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () => _handleTaskAction('delete', task),
                        icon: const Icon(Icons.delete),
                        tooltip: 'Delete',
                        iconSize: 20,
                        color: Colors.red,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.category,
                    task.category,
                    theme.colorScheme.secondaryContainer,
                    theme.colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.flag,
                    _getPriorityText(task.priority),
                    _getPriorityColor(task.priority, theme).withOpacity(0.2),
                    _getPriorityColor(task.priority, theme),
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.stars,
                    '${task.pointValue} pts',
                    theme.colorScheme.tertiaryContainer,
                    theme.colorScheme.onTertiaryContainer,
                  ),
                  if (task.isRecurring && task.recurrencePattern != null) ...[
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      Icons.repeat,
                      _getRecurrenceText(task.recurrencePattern!.type),
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.onPrimaryContainer,
                    ),
                  ],
                ],
              ),
              if (task.dueDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: _getDueDateColor(task.dueDate!, theme),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${_formatDueDate(task.dueDate!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getDueDateColor(task.dueDate!, theme),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority, ThemeData theme) {
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

  String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }

  String _getRecurrenceText(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
      case RecurrenceType.yearly:
        return 'Yearly';
    }
  }

  Color _getDueDateColor(DateTime dueDate, ThemeData theme) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    
    if (due.isBefore(today)) {
      return Colors.red;
    } else if (due.isAtSameMomentAs(today)) {
      return Colors.orange;
    } else {
      return theme.colorScheme.onSurfaceVariant;
    }
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    
    if (due.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (due.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow';
    } else if (due.isBefore(today)) {
      final daysDiff = today.difference(due).inDays;
      return '$daysDiff day${daysDiff == 1 ? '' : 's'} ago';
    } else {
      final daysDiff = due.difference(today).inDays;
      if (daysDiff <= 7) {
        return 'In $daysDiff day${daysDiff == 1 ? '' : 's'}';
      } else {
        return '${dueDate.day}/${dueDate.month}/${dueDate.year}';
      }
    }
  }

  void _showTaskDetails(TaskModel task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty) ...[
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(task.description),
              const SizedBox(height: 16),
            ],
            _buildDetailRow('Category', task.category),
            _buildDetailRow('Priority', _getPriorityText(task.priority)),
            _buildDetailRow('Points', '${task.pointValue}'),
            if (task.isRecurring && task.recurrencePattern != null)
              _buildDetailRow('Recurrence', _getRecurrenceText(task.recurrencePattern!.type)),
            if (task.dueDate != null)
              _buildDetailRow('Due Date', _formatDueDate(task.dueDate!)),
            _buildDetailRow('Status', task.isCompleted ? 'Completed' : 'Pending'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditTaskDialog(context, task);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _handleTaskAction(String action, TaskModel task) async {
    switch (action) {
      case 'edit':
        _showEditTaskDialog(context, task);
        break;
      case 'delete':
        _showDeleteConfirmation(task);
        break;
    }
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => TaskFormDialog(
        onTaskCreated: (task) async {
          await _taskService.createTask(
            title: task.title,
            description: task.description,
            category: task.category,
            pointValue: task.pointValue,
            priority: task.priority,
            dueDate: task.dueDate,
            isRecurring: task.isRecurring,
            recurrencePattern: task.recurrencePattern,
            showInQuickTasks: task.showInQuickTasks,
          );
        },
      ),
    );
  }

  void _showEditTaskDialog(BuildContext context, TaskModel task) {
    showDialog(
      context: context,
      builder: (context) => TaskFormDialog(
        task: task,
        onTaskCreated: (updatedTask) async {
          await _taskService.updateTask(
            updatedTask.id,
            title: updatedTask.title,
            description: updatedTask.description,
            category: updatedTask.category,
            pointValue: updatedTask.pointValue,
            priority: updatedTask.priority,
            dueDate: updatedTask.dueDate,
            showInQuickTasks: updatedTask.showInQuickTasks,
            isRecurring: updatedTask.isRecurring,
            recurrencePattern: updatedTask.recurrencePattern,
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(TaskModel task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _taskService.deleteTask(task.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Task deleted')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}