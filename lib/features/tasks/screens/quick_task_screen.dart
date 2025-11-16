import 'package:flutter/material.dart';
import '../../../core/services/task_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/task_model.dart';

class QuickTaskScreen extends StatefulWidget {
  const QuickTaskScreen({super.key});

  @override
  State<QuickTaskScreen> createState() => _QuickTaskScreenState();
}

class _QuickTaskScreenState extends State<QuickTaskScreen> {
  final _titleController = TextEditingController();
  final TaskService _taskService = TaskService();
  // Silence all debug prints in this screen
  void print(Object? object) {}
  
  String _selectedCategory = 'General';
  int _selectedPoints = 10;
  bool _isLoading = false;



  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _createQuickTask([QuickTaskPreset? preset]) async {
    final title = preset?.title ?? _titleController.text.trim();
    
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a task title or select a preset'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = AuthService.currentUser;
      if (currentUser == null) {
        throw Exception('Not signed in');
      }

      if (preset != null && preset.isRecurring) {
        // For recurring presets: Create recurring task template AND immediate today's instance
        RecurrenceType recurrenceType;
        switch (preset.recurrenceType) {
          case 'Daily':
            recurrenceType = RecurrenceType.daily;
            break;
          case 'Weekly':
            recurrenceType = RecurrenceType.weekly;
            break;
          case 'Monthly':
            recurrenceType = RecurrenceType.monthly;
            break;
          default:
            recurrenceType = RecurrenceType.daily;
        }

        final recurrencePattern = RecurrencePattern(
          type: recurrenceType,
          interval: 1,
        );

        // Create the recurring template task
        final taskId = await _taskService.createTask(
          title: title,
          description: 'Daily recurring task',
          category: preset.category,
          pointValue: preset.points,
          recurrencePattern: recurrencePattern,
        );

        // Immediately materialize today's instance as one-time task (non-recurring)
  print('[QuickTaskScreen] Creating immediate history entry for recurring preset: $title');
        await _taskService.addQuickTaskInstance(
          templateId: taskId,
          userId: currentUser.id,
          date: DateTime.now(),
        );
      } else {
        // Create regular quick task
        final taskId = await _taskService.createQuickTask(
          title: title,
          category: preset?.category ?? _selectedCategory,
          pointValue: preset?.points ?? _selectedPoints,
        );

        // Materialize the new quick task into today's history so it shows up immediately
        await _taskService.addQuickTaskInstance(
          templateId: taskId,
          userId: currentUser.id,
          date: DateTime.now(),
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task "$title" added to today!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating task: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createTaskFromTemplate(TaskModel template) async {
    // Add a quick-task instance for today using TaskService.addQuickTaskInstance
    // Allows multiple instances per day now
    setState(() {
      _isLoading = true;
    });

    try {
  print('[QuickTaskScreen] Adding quick-task instance from template: ${template.title}');
      final currentUser = AuthService.currentUser;
      if (currentUser == null) throw Exception('Not signed in');

      final instanceId = await _taskService.addQuickTaskInstance(
        templateId: template.id,
        userId: currentUser.id,
        date: DateTime.now(),
      );

  print('[QuickTaskScreen] Created task instance: $instanceId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${template.title}" to today\'s tasks!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
  print('[QuickTaskScreen][ERROR] Error adding quick-task instance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding task: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Task'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.flash_on,
                            size: 48,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Quick Task Creation',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Create a task quickly with preset values',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick Presets Section
                  Text(
                    'Quick Presets',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  FutureBuilder<List<TaskModel>>(
                    future: _taskService.listQuickTaskTemplates(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }

                      final quickTaskTemplates = snapshot.data ?? [];
                      print('[QuickTaskScreen] Found ${quickTaskTemplates.length} quick task templates');

                      if (quickTaskTemplates.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.flash_on,
                                size: 48,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No Quick Tasks Configured',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.outline,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Create tasks below and enable "Show in Quick Tasks" to see them here for quick daily creation.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.5,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: quickTaskTemplates.length,
                        itemBuilder: (context, index) {
                          final task = quickTaskTemplates[index];
                          return _buildTaskPresetCard(task, theme);
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Divider with "OR"
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Custom Task Section
                  Text(
                    'Custom Quick Task',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Task Title Input
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Task Title',
                      hintText: 'Enter a quick task title',
                      prefixIcon: const Icon(Icons.task_alt),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),

                  const SizedBox(height: 16),

                  // Category and Points Row
                  Row(
                    children: [
                      // Category Selection
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            prefixIcon: const Icon(Icons.category),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          ),
                          items: ['Chores', 'Homework', 'Exercise', 'Reading', 'Cleaning', 'Kitchen Help', 'Pet Care', 'Garden Work', 'Organization', 'General']
                              .map((category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                            });
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Points Selection
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _selectedPoints,
                          decoration: InputDecoration(
                            labelText: 'Points',
                            prefixIcon: const Icon(Icons.stars),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          ),
                          items: [5, 10, 15, 20, 25]
                              .map((points) => DropdownMenuItem(
                                    value: points,
                                    child: Text('$points pts'),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedPoints = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Create Custom Task Button
                  ElevatedButton(
                    onPressed: () => _createQuickTask(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Create Quick Task',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // View All Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Manage Tasks',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showAllQuickTasks,
                        icon: const Icon(Icons.list, size: 16),
                        label: const Text('View All Quick Tasks'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTaskPresetCard(TaskModel task, ThemeData theme) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: () => _createTaskFromTemplate(task),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (task.isRecurring)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.repeat,
                              size: 14,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            task.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${task.pointValue}',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    task.category,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Tap to add to today',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }





  Color _getTaskPriorityColor(TaskPriority priority) {
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

  Future<void> _completeTask(TaskModel task) async {
    try {
      await _taskService.updateTaskStatus(task.id, TaskStatus.completed);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task "${task.title}" completed! +${task.pointValue} points'),
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

  void _showAllQuickTasks() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Quick Tasks',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<TaskModel>>(
                  // Show all quick tasks for the current user (including completed)
                  stream: _taskService.getAllMyTasks(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allTasks = snapshot.data ?? [];
                    final allQuickTasks = allTasks.where((task) => task.showInQuickTasks).toList()
                      ..sort((a, b) {
                        // Sort by status first (pending first), then by creation date
                        if (a.status != b.status) {
                          return a.status == TaskStatus.pending ? -1 : 1;
                        }
                        return b.createdAt.compareTo(a.createdAt);
                      });

                    if (allQuickTasks.isEmpty) {
                      return const Center(
                        child: Text('No tasks configured as Quick Tasks'),
                      );
                    }

                    return ListView.builder(
                      itemCount: allQuickTasks.length,
                      itemBuilder: (context, index) {
                        final task = allQuickTasks[index];
                        return _buildAllTasksCard(task);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllTasksCard(TaskModel task) {
    final theme = Theme.of(context);
    final isCompleted = task.status == TaskStatus.completed || task.status == TaskStatus.approved;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCompleted ? Colors.green : _getTaskPriorityColor(task.priority),
          child: Icon(
            isCompleted ? Icons.check : Icons.task,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted ? theme.colorScheme.onSurfaceVariant : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${task.category} • ${task.pointValue} pts'),
            if (task.completedAt != null)
              Text(
                'Completed: ${_formatCompletionDate(task.completedAt!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        trailing: isCompleted 
            ? Icon(Icons.check_circle, color: Colors.green)
            : ElevatedButton(
                onPressed: () => _completeTask(task),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(80, 32),
                ),
                child: const Text('Complete'),
              ),
        isThreeLine: task.completedAt != null,
      ),
    );
  }

  String _formatCompletionDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);
    
    if (taskDate == today) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (taskDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Quick task preset data class
class QuickTaskPreset {
  final String title;
  final String category;
  final int points;
  final bool isRecurring;
  final String? recurrenceType;

  const QuickTaskPreset(
    this.title, 
    this.category, 
    this.points, {
    this.isRecurring = false,
    this.recurrenceType,
  });
}