import 'package:flutter/material.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/theme/theme_service.dart';
import '../../core/injection/injection.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/task_service.dart';
import '../../core/services/reward_service.dart';
import '../../core/models/task_model.dart';
import '../../core/models/reward_item.dart';
import '../../features/testing/quality_assurance_dashboard.dart';
import '../../shared/widgets/theme_demo_screen.dart';
import '../auth/login_screen.dart';
import '../rewards/presentation/pages/rewards_management_screen.dart';
import '../tasks/screens/add_task_screen.dart';
import '../tasks/screens/quick_task_screen.dart';
import '../tasks/screens/task_list_screen.dart';
import '../tasks/screens/task_management_screen.dart';
import '../testing/firestore_test_screen.dart';

/// Main application home screen with proper navigation to all features
class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  late final ThemeService _themeService;
  final TaskService _taskService = TaskService();
  int _currentIndex = 0;
  int _currentPoints = 0;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _themeService = getIt<ThemeService>();
    _loadUserPoints();
    _initializeRewardService();
  }

  Future<void> _initializeRewardService() async {
    await RewardService().initialize();
  }

  Future<void> _loadUserPoints() async {
    try {
      // Calculate points from all tasks (including negative redemption entries)
      final allTasks = await _taskService.getAllMyTasks().first;
      final points = allTasks
          .where((task) => task.status == TaskStatus.completed || task.status == TaskStatus.approved)
          .fold<int>(0, (sum, task) => sum + task.pointValue);
      
      if (mounted) {
        setState(() {
          _currentPoints = points;
        });
      }
    } catch (e) {
      // Handle error silently or set default points
      if (mounted) {
        setState(() {
          _currentPoints = 0;
        });
      }
    }
  }

  String _getCurrentUserName() {
    final user = AuthService.currentUser;
    return user?.displayName ?? 'User';
  }

  String _getCurrentUserEmail() {
    final user = AuthService.currentUser;
    return user?.email ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Rewards System'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.science),
            onPressed: _openQADashboard,
            tooltip: 'Quality Assurance Dashboard',
          ),
          IconButton(
            icon: const Icon(Icons.palette),
            onPressed: _openThemeDemo,
            tooltip: 'Theme Demo',
          ),
          IconButton(
            icon: Icon(context.isDarkTheme ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => _themeService.toggleTheme(),
            tooltip: 'Toggle theme',
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          _buildTasksTab(),
          _buildRewardsTab(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_outlined),
            selectedIcon: Icon(Icons.task),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.redeem_outlined),
            selectedIcon: Icon(Icons.redeem),
            label: 'Rewards',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0 
          ? FloatingActionButton.extended(
              onPressed: _quickEarnPoints,
              icon: const Icon(Icons.add),
              label: const Text('Quick Task'),
            )
          : _currentIndex == 1
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      onPressed: _addNewTask,
                      heroTag: "add_task",
                      child: const Icon(Icons.add_task),
                      tooltip: 'Add Task',
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton(
                      onPressed: _quickEarnPoints,
                      heroTag: "quick_task",
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      child: const Icon(Icons.flash_on),
                      tooltip: 'Quick Task',
                    ),
                  ],
                )
              : null,
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          _buildWelcomeCard(),
          const SizedBox(height: 16),
          
          // Quick stats
          _buildQuickStats(),
          const SizedBox(height: 16),
          
          // Recent activity
          _buildRecentActivity(),
          const SizedBox(height: 16),
          
          // Quick actions
          _buildQuickActions(),
          const SizedBox(height: 16),
          
          // Featured rewards
          _buildFeaturedRewards(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.person, size: 30, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back!',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        _getCurrentUserName(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Current Points: ${_currentPoints.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Progress',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StreamBuilder<List<TaskModel>>(
                    stream: _taskService.getAllMyTasks(),
                    builder: (context, snapshot) {
                      int completedToday = 0;
                      int totalPendingToday = 0;
                      
                      if (snapshot.hasData) {
                        final today = DateTime.now();
                        final todayStart = DateTime(today.year, today.month, today.day);
                        final todayEnd = todayStart.add(const Duration(days: 1));
                        
                        for (final task in snapshot.data!) {
                          // Skip redemption tasks from task counts
                          if (task.category == 'Reward Redemption') continue;
                          
                          // Count tasks completed today
                          if ((task.status == TaskStatus.completed || task.status == TaskStatus.approved) &&
                              task.completedAt != null &&
                              task.completedAt!.isAfter(todayStart) &&
                              task.completedAt!.isBefore(todayEnd)) {
                            completedToday++;
                          }
                          
                          // Count tasks due today or overdue
                          if (task.status == TaskStatus.pending &&
                              (task.dueDate == null || 
                               task.dueDate!.isBefore(todayEnd))) {
                            totalPendingToday++;
                          }
                        }
                      }
                      
                      return _buildStatItem(
                        'Tasks Done',
                        completedToday.toString(),
                        totalPendingToday > 0 ? '/ ${completedToday + totalPendingToday} today' : 'today',
                        Icons.task_alt,
                        Colors.green,
                      );
                    },
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<TaskModel>>(
                    stream: _taskService.getAllMyTasks(),
                    builder: (context, snapshot) {
                      int todayPoints = 0;
                      if (snapshot.hasData) {
                        final today = DateTime.now();
                        final todayStart = DateTime(today.year, today.month, today.day);
                        final todayEnd = todayStart.add(const Duration(days: 1));
                        
                        todayPoints = snapshot.data!
                            .where((task) => 
                                (task.status == TaskStatus.completed || task.status == TaskStatus.approved) &&
                                task.completedAt != null &&
                                task.completedAt!.isAfter(todayStart) &&
                                task.completedAt!.isBefore(todayEnd))
                            .fold<int>(0, (sum, task) => sum + task.pointValue);
                      }
                      
                      return _buildStatItem(
                        'Points Earned',
                        todayPoints.toString(),
                        'points today',
                        Icons.trending_up,
                        Colors.blue,
                      );
                    },
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Streak',
                    '7',
                    'days',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, String subtitle, IconData icon, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: _viewAllHistory,
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildActivityItem(
              'Completed "Clean Room" task',
              '25 points earned',
              '2 hours ago',
              Icons.check_circle,
              Colors.green,
            ),
            _buildActivityItem(
              'Redeemed "Movie Night" reward',
              '100 points spent',
              '1 day ago',
              Icons.redeem,
              Colors.purple,
            ),
            _buildActivityItem(
              'Completed "Homework" task',
              '30 points earned',
              '2 days ago',
              Icons.school,
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            time,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Add Task',
                    Icons.add_task,
                    Colors.blue,
                    _addNewTask,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Browse Rewards',
                    Icons.shopping_cart,
                    Colors.purple,
                    _browseRewards,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'View History',
                    Icons.history,
                    Colors.green,
                    _viewAllHistory,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'View Tasks',
                    Icons.task_alt,
                    Colors.orange,
                    _viewTasks,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedRewards() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Featured Rewards',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: _browseRewards,
                  child: const Text('See All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildRewardCard('Movie Night', '100 points', Icons.movie),
                  _buildRewardCard('Extra Allowance', '200 points', Icons.attach_money),
                  _buildRewardCard('Game Time', '75 points', Icons.games),
                  _buildRewardCard('Choose Dinner', '150 points', Icons.restaurant),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardCard(String title, String points, IconData icon) {
    final pointCost = int.parse(points.replaceAll(' points', ''));
    final available = _currentPoints >= pointCost;
    
    return Container(
      width: 120,
      height: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        child: InkWell(
          onTap: available ? () => _redeemReward(title, pointCost) : null,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: available 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).disabledColor,
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: available ? null : Theme.of(context).disabledColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  points,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: available 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).disabledColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!available)
                  Text(
                    'Not enough points',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 8,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTasksTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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
                      _getSelectedDateTitle(),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (!_isToday())
                      Text(
                        _formatSelectedDateSubtitle(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _previousDay,
                    icon: const Icon(Icons.chevron_left),
                    tooltip: 'Previous Day',
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    ),
                  ),
                  IconButton(
                    onPressed: _selectDate,
                    icon: Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    tooltip: 'Select Date',
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    ),
                  ),
                  IconButton(
                    onPressed: _nextDay,
                    icon: const Icon(Icons.chevron_right),
                    tooltip: 'Next Day',
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: _showTaskHistory,
                    icon: const Icon(Icons.history),
                    tooltip: '5-Day History',
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: _openTaskManagement,
                    icon: const Icon(Icons.settings),
                    tooltip: 'Manage Tasks',
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _quickEarnPoints,
                icon: const Icon(Icons.flash_on, size: 18),
                label: const Text('Quick Task'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _addNewTask,
                icon: const Icon(Icons.add_task, size: 18),
                label: const Text('Add Task'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTaskList(),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    return StreamBuilder<List<TaskModel>>(
      stream: _taskService.getAllMyTasks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red.withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error loading tasks',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to try again',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final allTasks = snapshot.data ?? [];

        // Filter tasks for selected date
        final selectedStart = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
        final selectedEnd = selectedStart.add(const Duration(days: 1));
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);
        
        List<TaskModel> tasks = [];

        // Include all tasks (including daily tasks) in the Tasks tab
        final filteredTasks = allTasks;

        // First, add all tasks that directly match the selected date
        final directTasks = filteredTasks.where((task) {
          // Show tasks based on selected date
          if (_isToday()) {
            // For today: show all tasks (pending AND completed)
            
            // Always show tasks completed today
            if (task.completedAt != null) {
              final completedDate = DateTime(task.completedAt!.year, task.completedAt!.month, task.completedAt!.day);
              if (completedDate.isAtSameMomentAs(selectedStart)) {
                return true; // Show tasks completed today
              }
            }
            
            // Show pending tasks (due today, overdue, or no due date)
            if (task.status == TaskStatus.pending) {
              if (task.dueDate == null) {
                return true; // Show tasks without due dates only for today
              }
              
              final taskDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
              return taskDate.isBefore(selectedEnd); // Due today or overdue
            }
            
            return false;
          } else {
            // For other dates: show tasks that match the selected date
            
            // Check if task was completed on the selected date
            if (task.completedAt != null) {
              final completedDate = DateTime(task.completedAt!.year, task.completedAt!.month, task.completedAt!.day);
              if (completedDate.isAtSameMomentAs(selectedStart)) {
                return true; // Show tasks completed on selected date
              }
            }
            
            // Check if task is due on the selected date
            if (task.dueDate != null) {
              final taskDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
              if (taskDate.isAtSameMomentAs(selectedStart)) {
                return true; // Show tasks due on selected date
              }
            }
            
            // For future dates, also show undated pending tasks
            if (selectedStart.isAfter(todayStart) && task.dueDate == null && task.status == TaskStatus.pending) {
              return true; // Show undated tasks for future planning
            }
            
            return false;
          }
        }).toList();

        tasks.addAll(directTasks);

        // Second, add virtual recurring task instances for future dates
        if (!_isToday()) {

          
          // Group recurring tasks by title/category to find all instances
          final recurringTaskGroups = <String, List<TaskModel>>{};
          
          final recurringTasks = filteredTasks.where((t) => 
            t.isRecurring && 
            t.recurrencePattern != null
          ).toList();
          
          for (final task in recurringTasks) {
            final key = '${task.title}_${task.category}_${task.assignedToUserId}';
            if (!recurringTaskGroups.containsKey(key)) {
              recurringTaskGroups[key] = [];
            }
            recurringTaskGroups[key]!.add(task);
          }

          // For each recurring task group, find the EARLIEST task to use as the pattern base
          for (final taskGroup in recurringTaskGroups.values) {
            // Sort by due date ASCENDING to get the original task (earliest)
            taskGroup.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
            final originalTask = taskGroup.first; // Use the earliest task as the pattern base
            
            // Check if this target date should show the task based on the original pattern
            if (_shouldShowRecurringTaskForDate(originalTask, selectedStart)) {
              // Check if we already have a real task for this date with same title
              final existingRealTask = tasks.any((t) => 
                !t.id.contains('_virtual_') &&
                t.title == originalTask.title &&
                t.dueDate != null &&
                DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day)
                  .isAtSameMomentAs(selectedStart)
              );
              
              if (!existingRealTask) {
                // Create a virtual task instance for this date using original task as template
                final virtualTask = originalTask.copyWith(
                  id: '${originalTask.id}_virtual_${selectedStart.millisecondsSinceEpoch}',
                  dueDate: selectedStart,
                  status: TaskStatus.pending, // Always pending for future dates
                  completedAt: null, // Not completed yet
                );
                tasks.add(virtualTask);
              }
            }
          }
        }

        if (tasks.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.task_alt,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getEmptyStateTitle(allTasks),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getEmptyStateMessage(allTasks),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _quickEarnPoints,
                        icon: const Icon(Icons.flash_on),
                        label: const Text('Quick Task'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _addNewTask,
                        icon: const Icon(Icons.add_task),
                        label: const Text('Add Task'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        // Separate regular tasks from redemption tasks
        final regularTasks = tasks.where((task) => task.category != 'Reward Redemption').toList();
        final redemptionTasks = allTasks
            .where((task) => task.category == 'Reward Redemption' && task.status == TaskStatus.completed)
            .toList();
        
        // Filter redemptions for selected date
        final selectedRedemptions = redemptionTasks.where((task) {
          if (task.completedAt != null) {
            final completedDate = DateTime(task.completedAt!.year, task.completedAt!.month, task.completedAt!.day);
            return completedDate.isAtSameMomentAs(selectedStart);
          }
          return false;
        }).toList()
        ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Regular Tasks Section
            if (regularTasks.isNotEmpty) ...[
              Text(
                'Tasks',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...regularTasks.map((task) => _buildTaskItemFromModel(task)).toList(),
              const SizedBox(height: 8),
              Card(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.task,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${regularTasks.length} task${regularTasks.length == 1 ? '' : 's'} for ${_isToday() ? 'today' : _formatSelectedDate()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            // Rewards Redemption Section
            if (selectedRedemptions.isNotEmpty) ...[
              if (regularTasks.isNotEmpty) const SizedBox(height: 24),
              Text(
                'Reward Redemptions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...selectedRedemptions.map((redemption) => _buildRedemptionHistoryCard(redemption)).toList(),
              const SizedBox(height: 8),
              Card(
                color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.redeem,
                        size: 16,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${selectedRedemptions.length} redemption${selectedRedemptions.length == 1 ? '' : 's'} for ${_isToday() ? 'today' : _formatSelectedDate()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            // Empty state for no tasks or redemptions
            if (regularTasks.isEmpty && selectedRedemptions.isEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.task_alt,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getEmptyStateTitle(allTasks),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getEmptyStateMessage(allTasks),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _quickEarnPoints,
                            icon: const Icon(Icons.flash_on),
                            label: const Text('Quick Task'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: _addNewTask,
                            icon: const Icon(Icons.add_task),
                            label: const Text('Add Task'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTaskItemFromModel(TaskModel task) {
    final isCompleted = task.status == TaskStatus.completed || task.status == TaskStatus.approved;
    final isRecurring = task.isRecurring;
    final isPending = task.status == TaskStatus.pending;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCompleted ? Colors.green : _getPriorityColor(task.priority),
          child: Icon(
            isCompleted ? Icons.check : (isRecurring ? Icons.repeat : Icons.task),
            color: Colors.white,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  fontWeight: FontWeight.w500,
                  color: isCompleted ? Theme.of(context).colorScheme.onSurfaceVariant : null,
                ),
              ),
            ),
            if (isRecurring)
              Icon(
                Icons.repeat,
                size: 16,
                color: isCompleted ? Colors.green : Theme.of(context).colorScheme.secondary,
              ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    '${task.category} • ${task.pointValue} points',
                    style: TextStyle(
                      color: isCompleted ? Theme.of(context).colorScheme.onSurfaceVariant : null,
                    ),
                  ),
                  if (task.dueDate != null) ...[
                    Text(
                      ' • Due: ${_formatTaskDate(task.dueDate!)}',
                      style: TextStyle(
                        color: isCompleted 
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : (task.isOverdue ? Colors.red : null),
                        fontWeight: task.isOverdue && !isCompleted ? FontWeight.w600 : null,
                      ),
                    ),
                  ],
                  if (task.dueDate == null)
                    Text(
                      ' • Anytime',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  if (isCompleted && task.completedAt != null) ...[
                    Text(
                      ' • Completed: ${_formatTaskDate(task.completedAt!)}',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        trailing: isCompleted
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          Text(
                            '+${task.pointValue}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 60,
                        height: 28,
                        child: OutlinedButton(
                          onPressed: () => _showUndoConfirmation(task),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            side: const BorderSide(color: Colors.orange, width: 1),
                            foregroundColor: Colors.orange,
                          ),
                          child: const Text('Undo', style: TextStyle(fontSize: 10)),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : isPending
                ? SizedBox(
                    width: 80,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () => _showCompleteConfirmation(task),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        backgroundColor: _getPriorityColor(task.priority),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Done', style: TextStyle(fontSize: 12)),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      task.status.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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

  String _formatTaskDate(DateTime date) {
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

  Widget _buildRewardsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reward Store',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              ElevatedButton.icon(
                onPressed: _openRewardsManagement,
                icon: const Icon(Icons.settings, size: 18),
                label: const Text('Manage'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRewardGrid(),
          const SizedBox(height: 32),
          _buildTodayRewardHistory(),
        ],
      ),
    );
  }

  Widget _buildTodayRewardHistory() {
    return FutureBuilder<List<TaskModel>>(
      future: _getTodayRedemptions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final todayRedemptions = snapshot.data ?? [];
        
        if (todayRedemptions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Redemptions',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  '${todayRedemptions.length} reward${todayRedemptions.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...todayRedemptions.map((redemption) => _buildRedemptionHistoryCard(redemption)),
          ],
        );
      },
    );
  }

  Widget _buildRewardGrid() {
    return ValueListenableBuilder<List<RewardItem>>(
      valueListenable: RewardService().rewardsStream,
      builder: (context, allRewards, child) {
        final activeRewards = allRewards.where((r) => r.isActive).toList();
        
        if (activeRewards.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No rewards available',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add some rewards to get started!',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _openRewardsManagement,
                      child: const Text('Manage Rewards'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Column(
          children: [
            for (int i = 0; i < activeRewards.length; i += 2)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(child: _buildRewardGridItem(activeRewards[i])),
                    const SizedBox(width: 12),
                    if (i + 1 < activeRewards.length)
                      Expanded(child: _buildRewardGridItem(activeRewards[i + 1]))
                    else
                      const Expanded(child: SizedBox()),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
  
  Widget _buildRewardGridItem(RewardItem reward) {
    final available = _currentPoints >= reward.points;
    final icon = IconData(reward.iconCodePoint, fontFamily: 'MaterialIcons');
    final color = Color(reward.colorValue);
    
    return Card(
      child: InkWell(
        onTap: available ? () => _redeemReward(reward.title, reward.points) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: available ? color : Colors.grey.shade300,
                radius: 24,
                child: Icon(
                  icon,
                  size: 24,
                  color: available ? Colors.white : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                reward.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: available ? null : Theme.of(context).disabledColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: available 
                      ? color.withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${reward.points} pts',
                  style: TextStyle(
                    color: available ? color : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              if (!available) ...[
                const SizedBox(height: 4),
                Text(
                  'Need ${reward.points - _currentPoints} more',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          _buildProfileCard(),
          const SizedBox(height: 16),
          _buildProfileStats(),
          const SizedBox(height: 16),
          _buildProfileActions(),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              _getCurrentUserName(),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              _getCurrentUserEmail(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Member since October 2024',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildProfileStat('Total Points', '2,450'),
                _buildProfileStat('Tasks Done', '47'),
                _buildProfileStat('Rewards', '8'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildProfileStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Achievements',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildAchievementItem('First Task', 'Complete your first task', true),
            _buildAchievementItem('Week Streak', 'Complete tasks for 7 days', true),
            _buildAchievementItem('Point Collector', 'Earn 1000 points', true),
            _buildAchievementItem('Task Master', 'Complete 50 tasks', false),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementItem(String title, String description, bool earned) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: earned ? Colors.yellow : Colors.grey.shade300,
            child: Icon(
              Icons.emoji_events,
              color: earned ? Colors.orange : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: earned ? null : Theme.of(context).disabledColor,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: earned ? null : Theme.of(context).disabledColor,
                  ),
                ),
              ],
            ),
          ),
          if (earned)
            const Icon(Icons.check_circle, color: Colors.green),
        ],
      ),
    );
  }

  Widget _buildProfileActions() {
    return Column(
      children: [
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openSettings,
              ),
              ListTile(
                leading: const Icon(Icons.family_restroom),
                title: const Text('Family Management'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openFamilySettings,
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Transaction History'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _viewAllHistory,
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openHelp,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _logout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              padding: const EdgeInsets.all(16),
            ),
            child: const Text('Logout'),
          ),
        ),
      ],
    );
  }

  // Action methods
  void _openQADashboard() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QualityAssuranceDashboard(),
      ),
    );
  }

  void _openThemeDemo() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ThemeDemoScreen(),
      ),
    );
  }

  void _quickEarnPoints() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QuickTaskScreen(),
      ),
    );
  }

  void _addNewTask() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddTaskScreen(),
      ),
    );
  }

  void _browseRewards() {
    setState(() {
      _currentIndex = 2; // Switch to rewards tab
    });
  }

  void _viewAllHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FirestoreTestScreen(),
      ),
    );
  }

  void _openRewardsManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RewardsManagementScreen(),
      ),
    );
  }

  void _viewTasks() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TaskListScreen(),
      ),
    );
  }

  void _openFamilySettings() {
    _showSnackBar('Family settings feature coming soon!');
  }

  void _redeemReward(String rewardName, int pointCost) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Redeem $rewardName'),
        content: Text('Are you sure you want to redeem this reward for $pointCost points?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                // Create a negative reward entry to track the redemption and complete it immediately
                final redemptionTaskId = await _taskService.createTask(
                  title: 'Reward: $rewardName',
                  description: 'Redeemed reward: $rewardName (-$pointCost points)',
                  category: 'Reward Redemption',
                  pointValue: -pointCost, // Negative points for redemption
                  priority: TaskPriority.medium,
                );
                
                // Mark the redemption task as completed immediately
                await _taskService.completeTask(redemptionTaskId);
                
                // Update local state immediately
                setState(() {
                  _currentPoints -= pointCost;
                });
                
                _showSnackBar('$rewardName redeemed successfully! -$pointCost points');
                
                // Reload points to ensure accuracy with database
                _loadUserPoints();
              } catch (e) {
                _showSnackBar('Error redeeming reward: $e');
              }
            },
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
  }

  /// Show confirmation dialog before completing a task
  Future<void> _showCompleteConfirmation(TaskModel task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Task'),
        content: Text('Are you sure you want to mark "${task.title}" as completed?\n\nYou will earn ${task.pointValue} points.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getPriorityColor(task.priority),
              foregroundColor: Colors.white,
            ),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _completeTaskFromModel(task);
    }
  }

  /// Show confirmation dialog before undoing a completed task
  Future<void> _showUndoConfirmation(TaskModel task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Undo Task Completion'),
        content: Text('Are you sure you want to undo the completion of "${task.title}"?\n\nYou will lose ${task.pointValue} points.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Undo'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _undoTaskCompletion(task);
    }
  }

  /// Complete a task with confirmation
  Future<void> _completeTaskFromModel(TaskModel task) async {
    try {
      String taskId = task.id;
      
      // Check if this is a virtual recurring task
      if (task.id.contains('_virtual_')) {
        // Create a real task instance for this date
        final realTaskId = await _taskService.createTask(
          title: task.title,
          description: task.description,
          category: task.category,
          pointValue: task.pointValue,
          assignedToUserId: task.assignedToUserId,
          priority: task.priority,
          dueDate: task.dueDate,
          tags: task.tags,
          isRecurring: false, // This instance is not recurring
          instructions: task.instructions,
        );
        taskId = realTaskId;
      }
      
      await _taskService.completeTask(taskId);
      
      if (mounted) {
        // Update points immediately
        setState(() {
          _currentPoints += task.pointValue;
        });
        
        _showSnackBar('${task.title} completed! +${task.pointValue} points');
        
        // If it's a recurring task, show additional message
        if (task.isRecurring && !task.id.contains('_virtual_')) {
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              _showSnackBar('✨ Next occurrence of "${task.title}" has been created!');
            }
          });
        }
        
        // Reload points from database to ensure accuracy
        _loadUserPoints();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error completing task: $e');
      }
    }
  }

  /// Undo task completion with confirmation
  Future<void> _undoTaskCompletion(TaskModel task) async {
    try {
      await _taskService.undoTaskCompletion(task.id);
      
      if (mounted) {
        // Deduct points immediately
        setState(() {
          _currentPoints -= task.pointValue;
        });
        
        _showSnackBar('${task.title} completion undone! -${task.pointValue} points');
        
        // Reload points from database to ensure accuracy
        _loadUserPoints();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error undoing task completion: $e');
      }
    }
  }

  void _openSettings() {
    _showSnackBar('Settings feature coming soon!');
  }

  void _openHelp() {
    _showSnackBar('Help & support feature coming soon!');
  }

  Future<List<TaskModel>> _getTodayRedemptions() async {
    try {
      final allTasks = await _taskService.getAllMyTasks().first;
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      return allTasks
          .where((task) => 
            task.category == 'Reward Redemption' && 
            task.status == TaskStatus.completed &&
            task.createdAt.isAfter(todayStart) && 
            task.createdAt.isBefore(todayEnd))
          .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Most recent first
    } catch (e) {
      return [];
    }
  }

  Widget _buildRedemptionHistoryCard(TaskModel redemption) {
    final rewardName = redemption.title.replaceFirst('Reward: ', '');
    final pointsCost = -redemption.pointValue; // Convert negative back to positive for display
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.error,
          child: const Icon(Icons.redeem, color: Colors.white),
        ),
        title: Text(rewardName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(redemption.description),
            Text(
              'Redeemed at ${_formatTime(redemption.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '-$pointsCost pts',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _undoRedemption(redemption),
              icon: const Icon(Icons.undo),
              tooltip: 'Undo Redemption',
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $ampm';
  }

  Future<void> _undoRedemption(TaskModel redemption) async {
    final rewardName = redemption.title.replaceFirst('Reward: ', '');
    final pointsCost = -redemption.pointValue;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Undo Redemption'),
        content: Text('Are you sure you want to undo the redemption of "$rewardName"?\n\nThis will refund $pointsCost points.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Undo'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Delete the redemption task to undo it
        await _taskService.deleteTask(redemption.id);
        
        // Update local state immediately
        setState(() {
          _currentPoints += pointsCost;
        });
        
        _showSnackBar('Redemption undone! +$pointsCost points refunded');
        
        // Reload points to ensure accuracy
        _loadUserPoints();
      } catch (e) {
        _showSnackBar('Error undoing redemption: $e');
      }
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performLogout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Perform logout
      await AuthService.signOut();

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
        
        // Navigate to login screen and clear all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Logout failed: ${e.toString()}');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Date selection and formatting methods
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  bool _isToday() {
    final today = DateTime.now();
    return _selectedDate.year == today.year &&
           _selectedDate.month == today.month &&
           _selectedDate.day == today.day;
  }

  String _getSelectedDateTitle() {
    if (_isToday()) {
      return 'Today\'s Tasks';
    } else {
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));
      final yesterday = today.subtract(const Duration(days: 1));
      
      if (_selectedDate.year == tomorrow.year &&
          _selectedDate.month == tomorrow.month &&
          _selectedDate.day == tomorrow.day) {
        return 'Tomorrow\'s Tasks';
      } else if (_selectedDate.year == yesterday.year &&
                 _selectedDate.month == yesterday.month &&
                 _selectedDate.day == yesterday.day) {
        return 'Yesterday\'s Tasks';
      } else {
        return 'Tasks';
      }
    }
  }

  String _formatSelectedDateSubtitle() {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${months[_selectedDate.month - 1]} ${_selectedDate.day}, ${_selectedDate.year}';
  }

  String _formatSelectedDate() {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${months[_selectedDate.month - 1]} ${_selectedDate.day}';
  }

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
  }

  String _getEmptyStateTitle(List<TaskModel> allTasks) {
    if (allTasks.isEmpty) {
      return 'No tasks yet';
    }
    
    if (_isToday()) {
      return 'No tasks for today';
    } else {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final selectedStart = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      
      if (selectedStart.isBefore(todayStart)) {
        return 'No tasks for this past date';
      } else {
        return 'No tasks scheduled for this date';
      }
    }
  }

  String _getEmptyStateMessage(List<TaskModel> allTasks) {
    if (allTasks.isEmpty) {
      return 'Create your first task to get started!';
    }
    
    if (_isToday()) {
      return 'All your tasks are scheduled for other days or already completed! 🎉';
    } else {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final selectedStart = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      
      if (selectedStart.isBefore(todayStart)) {
        return 'No tasks were due or completed on this date.';
      } else {
        return 'No tasks scheduled for this future date yet.';
      }
    }
  }

  void _showTaskHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TaskHistoryScreen(taskService: _taskService),
      ),
    );
  }

  void _openTaskManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TaskManagementScreen(),
      ),
    );
  }

  /// Check if a recurring task should be shown for a specific date
  /// This works regardless of the original task's completion status
  bool _shouldShowRecurringTaskForDate(TaskModel task, DateTime targetDate) {
    if (!task.isRecurring || task.recurrencePattern == null) {
      return false;
    }

    final pattern = task.recurrencePattern!;
    
    // If task has no due date, use today as the start date for the pattern
    final taskDue = task.dueDate ?? DateTime.now();
    
    // Check if the pattern has ended
    if (pattern.endDate != null && targetDate.isAfter(pattern.endDate!)) {
      return false;
    }
    
    // Use the task's due date as the pattern start date (this should be the original/earliest)
    final patternStartDate = DateTime(taskDue.year, taskDue.month, taskDue.day);
    final targetDateOnly = DateTime(targetDate.year, targetDate.month, targetDate.day);
    
    // Check if target date is at least on or after the start date
    if (targetDateOnly.isBefore(patternStartDate)) {
      return false;
    }
    
    // Calculate if the target date matches the recurrence pattern
    switch (pattern.type) {
      case RecurrenceType.daily:
        final daysDiff = targetDateOnly.difference(patternStartDate).inDays;
        return daysDiff >= 0 && daysDiff % pattern.interval == 0;
        
      case RecurrenceType.weekly:
        final daysDiff = targetDateOnly.difference(patternStartDate).inDays;
        return daysDiff >= 0 && daysDiff % (7 * pattern.interval) == 0;
        
      case RecurrenceType.monthly:
        // Check if it's the same day of month with the right interval
        final monthsDiff = (targetDateOnly.year - patternStartDate.year) * 12 + 
                          (targetDateOnly.month - patternStartDate.month);
        return monthsDiff >= 0 && 
               monthsDiff % pattern.interval == 0 && 
               targetDateOnly.day == patternStartDate.day;
        
      case RecurrenceType.yearly:
        final yearsDiff = targetDateOnly.year - patternStartDate.year;
        return yearsDiff >= 0 && 
               yearsDiff % pattern.interval == 0 && 
               targetDateOnly.month == patternStartDate.month && 
               targetDateOnly.day == patternStartDate.day;
    }
  }


}

/// Task History Screen showing completed tasks from last 5 days
class TaskHistoryScreen extends StatefulWidget {
  final TaskService taskService;

  const TaskHistoryScreen({super.key, required this.taskService});

  @override
  State<TaskHistoryScreen> createState() => _TaskHistoryScreenState();
}

class _TaskHistoryScreenState extends State<TaskHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task History'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: StreamBuilder<List<TaskModel>>(
        stream: widget.taskService.getAllMyTasks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('Error loading history', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString(), style: theme.textTheme.bodySmall),
                ],
              ),
            );
          }

          final allTasks = snapshot.data ?? [];
          final historyData = _processTaskHistory(allTasks);

          if (historyData.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('No completed tasks yet', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Complete some tasks to see your history!', style: theme.textTheme.bodyMedium),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverallSummary(historyData, theme),
                const SizedBox(height: 24),
                ...historyData.map((dayData) => _buildDaySection(dayData, theme)).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  List<DayHistoryData> _processTaskHistory(List<TaskModel> allTasks) {
    final now = DateTime.now();
    final historyData = <DayHistoryData>[];

    // Process last 5 days
    for (int i = 0; i < 5; i++) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final completedTasks = allTasks.where((task) {
        return (task.status == TaskStatus.completed || task.status == TaskStatus.approved) &&
               task.completedAt != null &&
               task.completedAt!.isAfter(dayStart) &&
               task.completedAt!.isBefore(dayEnd);
      }).toList();

      if (completedTasks.isNotEmpty || i == 0) { // Always show today even if empty
        final totalPoints = completedTasks.fold<int>(0, (sum, task) => sum + task.pointValue);
        historyData.add(DayHistoryData(
          date: dayStart,
          tasks: completedTasks,
          totalTasks: completedTasks.length,
          totalPoints: totalPoints,
        ));
      }
    }

    return historyData;
  }

  Widget _buildOverallSummary(List<DayHistoryData> historyData, ThemeData theme) {
    final totalTasks = historyData.fold<int>(0, (sum, day) => sum + day.totalTasks);
    final totalPoints = historyData.fold<int>(0, (sum, day) => sum + day.totalPoints);
    final activeDays = historyData.where((day) => day.totalTasks > 0).length;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('5-Day Summary', style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                )),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildSummaryItem('Total Tasks', totalTasks.toString(), Icons.task_alt, Colors.blue, theme)),
                Expanded(child: _buildSummaryItem('Total Points', totalPoints.toString(), Icons.stars, Colors.orange, theme)),
                Expanded(child: _buildSummaryItem('Active Days', activeDays.toString(), Icons.calendar_today, Colors.green, theme)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color, ThemeData theme) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(value, style: theme.textTheme.headlineMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        )),
        Text(title, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildDaySection(DayHistoryData dayData, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formatDayTitle(dayData.date), style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
                      Text(_formatFullDate(dayData.date), style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.task_alt, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text('${dayData.totalTasks}', style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      )),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text('${dayData.totalPoints}', style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      )),
                    ],
                  ),
                ),
              ],
            ),
            
            if (dayData.tasks.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Text('No tasks completed', style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  )),
                ),
              )
            else ...[
              const SizedBox(height: 12),
              ...dayData.tasks.map((task) => _buildHistoryTaskItem(task, theme)).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTaskItem(TaskModel task, ThemeData theme) {
    final isRecurring = task.isRecurring;
    final isRedemption = task.category == 'Reward Redemption';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRedemption 
            ? Colors.red.withOpacity(0.05)
            : theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            width: 4,
            color: isRedemption ? Colors.red : _getPriorityColor(task.priority),
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isRedemption 
                ? Colors.red.withOpacity(0.1) 
                : Colors.green.withOpacity(0.1),
            child: Icon(
              isRedemption 
                  ? Icons.shopping_cart 
                  : (isRecurring ? Icons.repeat : Icons.check),
              size: 16,
              color: isRedemption ? Colors.red : Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title, 
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isRedemption ? Colors.red : null,
                        )
                      ),
                    ),
                    if (isRecurring && !isRedemption)
                      Icon(Icons.repeat, size: 16, color: theme.colorScheme.secondary),
                  ],
                ),
                Text(
                  isRedemption 
                      ? 'Redemption • Redeemed ${_formatTime(task.completedAt!)}'
                      : '${task.category} • Completed ${_formatTime(task.completedAt!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isRedemption 
                        ? Colors.red.withOpacity(0.7)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isRedemption 
                  ? Colors.red.withOpacity(0.1) 
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isRedemption ? '-${task.pointValue}' : '+${task.pointValue}', 
              style: TextStyle(
                color: isRedemption ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              )
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

  String _formatDayTitle(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (targetDate.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    } else {
      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return weekdays[date.weekday - 1];
    }
  }

  String _formatFullDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    
    return '${displayHour}:${minute.toString().padLeft(2, '0')} $period';
  }
}

/// Data class for organizing daily task history
class DayHistoryData {
  final DateTime date;
  final List<TaskModel> tasks;
  final int totalTasks;
  final int totalPoints;

  const DayHistoryData({
    required this.date,
    required this.tasks,
    required this.totalTasks,
    required this.totalPoints,
  });
}

