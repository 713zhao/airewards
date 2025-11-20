import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/injection/injection.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/reward_item.dart';
import '../../core/models/task_model.dart';
import '../../core/models/user_model.dart';
import '../../core/models/goal_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/family_service.dart';
import '../../core/services/reward_service.dart';
import '../../core/services/task_generation_service.dart';
import '../../core/services/task_service.dart';
import '../../core/services/user_service.dart';
import '../../core/services/goal_service.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/theme/theme_service.dart';
import '../../features/testing/quality_assurance_dashboard.dart';
import '../../shared/widgets/theme_demo_screen.dart';
import '../../shared/widgets/banner_ad_widget.dart';
import '../../shared/widgets/goal_progress_card.dart';
import '../auth/login_screen.dart';
import '../rewards/presentation/widgets/set_goal_dialog.dart';
import '../family/family_dashboard_screen.dart';
import '../family/join_family_screen.dart';
import '../rewards/presentation/pages/add_edit_reward_screen.dart';
import '../rewards/presentation/pages/rewards_management_screen.dart';
import '../settings/settings_screen.dart';
import '../tasks/screens/add_task_screen.dart';
import '../tasks/screens/quick_task_screen.dart';
import '../tasks/screens/task_management_screen.dart';
import 'transaction_history_screen.dart';

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  late final ThemeService _themeService;
  final TaskService _taskService = TaskService();
  final RewardService _rewardService = RewardService();
  final TaskGenerationService _taskGenerationService = TaskGenerationService();
  final GoalService _goalService = GoalService();

  // Local print override: silence all verbose prints in this screen
  void print(Object? object) {}

  Stream<List<TaskModel>>? _tasksStream;
  StreamSubscription<List<TaskModel>>? _allTasksSubscription;
  StreamSubscription<UserModel?>? _userSubscription; // reacts when auth user loads
  List<TaskModel> _allMyTasks = [];

  int _currentIndex = 0;
  int _currentPoints = 0;
  int _totalTasksDone = 0;
  int _totalRewards = 0;

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _themeService = getIt<ThemeService>();
    _tasksStream = _createTasksStreamForDate(_selectedDate);
    _allTasksSubscription = _tasksStream?.listen((tasks) {
      final user = AuthService.currentUser;
      print('🧭 Tasks stream update (Tasks Tab) for user=${user?.id} (${user?.accountType.name}), familyId=${user?.familyId}');
      print('   • Received ${tasks.length} live tasks from TaskService.getAllMyTasks');
      if (tasks.isEmpty) {
        print('   ⚠️ Live tasks list is empty. If you expect generated daily tasks, remember those are in task_history, not tasks.');
      } else {
        for (var i = 0; i < (tasks.length > 3 ? 3 : tasks.length); i++) {
          final t = tasks[i];
          print('   • [${i+1}] ${t.title} | assignedTo=${t.assignedToUserId} | familyId=${t.familyId} | status=${t.status.name} | archived=${t.tags.contains('archived')}');
        }
      }
      _allMyTasks = tasks;
      _recalculatePointsFromLiveTasks();
    });
    // When auth user becomes available (async init), load points
    _userSubscription = AuthService.userStream.listen((user) {
      if (user != null) {
        print('👂 Auth user stream -> user loaded (${user.id}), triggering points/stat refresh');
        _loadUserPoints();
      }
    });
    _initializeRewardService();
    _refreshRewardSummaries();
    _loadUserPoints();
  }

  // Create a merged stream for the Tasks tab: live tasks + today's generated history
  Stream<List<TaskModel>> _createTasksStreamForDate(DateTime date) {
    // Show task_history for the selected date (works for today, past, and future dates)
    // This ensures users see their materialized task instances for any date
    return _taskService.getHistoryForDateForCurrentUser(date);
  }

  Future<void> _refreshRewardSummaries() async {
    try {
      final currentUser = AuthService.currentUser;

      if (currentUser?.id == null) {
        if (mounted) {
          setState(() {
            _totalRewards = 0;
          });
        }
        return;
      }

      final redemptions = await _taskService.getRewardRedemptions(
        userId: currentUser!.id,
      );

      if (mounted) {
        setState(() {
          _totalRewards = redemptions.length;
        });
      }
    } catch (e) {
      debugPrint('❌ Failed to refresh reward summaries: $e');
    }
  }

  Future<void> _initializeRewardService() async {
    await _rewardService.initialize();
  }

  @override
  void dispose() {
    _allTasksSubscription?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserPoints() async {
    await _loadProfileStats();
  }

  /// Load all profile statistics for consistent display
  Future<void> _loadProfileStats() async {
    try {
      final currentUser = AuthService.currentUser;
      print(
        '🔍 _loadProfileStats - Current user: ${currentUser?.id}, familyId: ${currentUser?.familyId}',
      );

      final userId = currentUser?.id;
      if (userId == null) {
        await _refreshRewardSummaries();
        return;
      }

      final redemptionHistory = await _taskService.getRewardRedemptions(
        userId: userId,
      );
      final netPoints = await _taskService.getNetPointsFromHistory(
        userId: userId,
      );
      // If history based total is 0 but we have completed/approved tasks in live memory, use live fallback
      final liveFallback = _computeLiveNetPoints();
      final effectivePoints = (netPoints == 0 && liveFallback != 0) ? liveFallback : netPoints;

      print('📊 Loading task stats...');
      TaskStats? taskStats;
      try {
        taskStats = await _taskService.getMyTaskStats();
        print(
          '📊 Task stats loaded: ${taskStats.approved} approved, ${taskStats.completed} completed, ${taskStats.pending} pending',
        );
      } catch (e) {
        print('⚠️ Failed to load task stats via getMyTaskStats: $e');
        taskStats = null;
      }

      int tasksDone = 0;
      if (taskStats != null) {
        tasksDone = taskStats.approved + taskStats.completed;
      } else {
        final fallbackTasks = _allMyTasks.where((task) {
          if (task.category == 'Reward Redemption') {
            return false;
          }
          return task.status == TaskStatus.completed ||
              task.status == TaskStatus.approved;
        }).length;
        tasksDone = fallbackTasks;
      }

  final rewards = _rewardService.getAvailableRewards(effectivePoints);
      print('🎁 Rewards loaded: ${rewards.length} available');

      if (mounted) {
        setState(() {
          _currentPoints = effectivePoints;
          _totalTasksDone = tasksDone;
          _totalRewards = redemptionHistory.length;
        });
        
        print('💰 _currentPoints set to: $_currentPoints');
        
        // Check if any active goal is completed
        _checkGoalCompletion();
      }

      print(
        '✅ Top section stats updated: $effectivePoints points (history=$netPoints live=$liveFallback), $tasksDone tasks, ${redemptionHistory.length} rewards redeemed',
      );
    } catch (e) {
      print('❌ Error in _loadProfileStats: $e');
      if (mounted) {
        setState(() {
          _currentPoints = 0;
          _totalTasksDone = 0;
          _totalRewards = 0;
        });
      }
    }
  }

  // Compute net points (completed + approved, including negative redemption entries) from current live tasks list
  int _computeLiveNetPoints() {
    if (_allMyTasks.isEmpty) return 0;
    var total = 0;
    for (final t in _allMyTasks) {
      if (t.status == TaskStatus.completed || t.status == TaskStatus.approved) {
        total += t.pointValue; // negative values reduce total automatically
      }
    }
    return total;
  }

  void _recalculatePointsFromLiveTasks() {
    final live = _computeLiveNetPoints();
    if (!mounted) return;
    if (live != _currentPoints) {
      setState(() => _currentPoints = live);
      print('🔄 Live points updated from tasks stream: $live');
    }
  }

  void _updateTasksStreamForSelectedDate() {
    // Recreate the tasks stream so the StreamBuilder refreshes for the new date selection.
    _allTasksSubscription?.cancel();
    _tasksStream = _createTasksStreamForDate(_selectedDate);
    _allTasksSubscription = _tasksStream?.listen((tasks) {
      final user = AuthService.currentUser;
      print('🧭 [Date change] Tasks stream update for ${_selectedDate.toIso8601String()} user=${user?.id}');
      _allMyTasks = tasks;
    });
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
            icon: Icon(
              context.isDarkTheme ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () => _themeService.toggleTheme(),
            tooltip: 'Toggle theme',
          ),
        ],
      ),
      body: Column(
        children: [
          const BannerAdWidget(),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _buildHomeTab(),
                _buildTasksTab(),
                _buildRewardsTab(),
                _buildFamilyTab(),
                _buildProfileTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });

          // Refresh profile stats when profile tab is selected
          if (index == 4) {
            _loadProfileStats();
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: AppLocalizations.of(context).home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.task_outlined),
            selectedIcon: const Icon(Icons.task),
            label: AppLocalizations.of(context).tasks,
          ),
          NavigationDestination(
            icon: const Icon(Icons.redeem_outlined),
            selectedIcon: const Icon(Icons.redeem),
            label: AppLocalizations.of(context).rewards,
          ),
          NavigationDestination(
            icon: const Icon(Icons.family_restroom_outlined),
            selectedIcon: const Icon(Icons.family_restroom),
            label: AppLocalizations.of(context).translate('family'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: AppLocalizations.of(context).profile,
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _quickEarnPoints,
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context).translate('quick_task')),
            )
          : _currentIndex == 1
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_shouldShowAddTaskButton()) ...[
                  FloatingActionButton(
                    onPressed: _addNewTask,
                    heroTag: "add_task",
                    tooltip: 'Add Task',
                    child: const Icon(Icons.add_task),
                  ),
                  const SizedBox(height: 8),
                ],
                FloatingActionButton(
                  onPressed: _quickEarnPoints,
                  heroTag: "quick_task",
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  tooltip: 'Quick Task',
                  child: const Icon(Icons.flash_on),
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

          // Active Goal
          StreamBuilder<GoalModel?>(
            stream: _goalService.watchActiveGoal(),
            builder: (context, snapshot) {
              print('🏠 Home tab goal StreamBuilder - connectionState: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, hasError: ${snapshot.hasError}');
              if (snapshot.hasError) {
                print('❌ Home tab goal error: ${snapshot.error}');
              }
              if (snapshot.hasData && snapshot.data != null) {
                print('✅ Home tab showing goal card with currentPoints: $_currentPoints');
                return Column(
                  children: [
                    GoalProgressCard(
                      goal: snapshot.data!,
                      currentPoints: _currentPoints,
                      onDelete: () => _deleteGoal(snapshot.data!.id),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }
              print('ℹ️ Home tab not showing goal (no data or null)');
              return const SizedBox.shrink();
            },
          ),

          // Quick stats
          _buildQuickStats(),
          const SizedBox(height: 16),

          // Family activity overview
          _buildFamilyActivity(),
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
                  child: const Icon(
                    Icons.person,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).translate('welcome_back'),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        _getCurrentUserName(),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
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
                    '${AppLocalizations.of(context).translate('current_points')}: ${_currentPoints.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
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
              AppLocalizations.of(context).translate('todays_progress'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<TaskModel>>(
              stream: _tasksStream,
              builder: (context, snapshot) {
                final today = DateTime.now();
                final todayStart = DateTime(today.year, today.month, today.day);
                final todayEnd = todayStart.add(const Duration(days: 1));

                int completedToday = 0;
                int totalPendingToday = 0;
                int todayPoints = 0;

                if (snapshot.hasData) {
                  for (final task in snapshot.data!) {
                    if (task.category == 'Reward Redemption') {
                      continue;
                    }

                    if ((task.status == TaskStatus.completed ||
                            task.status == TaskStatus.approved) &&
                        task.completedAt != null &&
                        !task.completedAt!.isBefore(todayStart) &&
                        task.completedAt!.isBefore(todayEnd)) {
                      completedToday++;
                      todayPoints += task.pointValue;
                    }

                    if (task.status == TaskStatus.pending &&
                        (task.dueDate == null ||
                            task.dueDate!.isBefore(todayEnd))) {
                      totalPendingToday++;
                    }
                  }
                }

                int redemptionsToday = 0;
                int redemptionPointsSpentToday = 0;

                for (final task in _allMyTasks) {
                  if (task.category != 'Reward Redemption') {
                    continue;
                  }

                  if (task.status != TaskStatus.completed &&
                      task.status != TaskStatus.approved) {
                    continue;
                  }

                  final completionMoment =
                      task.completedAt ?? task.approvedAt ?? task.createdAt;
                  if (completionMoment.isBefore(todayStart) ||
                      !completionMoment.isBefore(todayEnd)) {
                    continue;
                  }

                  redemptionsToday++;
                  redemptionPointsSpentToday += task.pointValue.abs();
                }

                final l10n = AppLocalizations.of(context);
                final pointsSubtitle = l10n.translate('today');
                final redemptionDetail = redemptionPointsSpentToday > 0
                    ? ' (-$redemptionPointsSpentToday ${redemptionPointsSpentToday == 1 ? l10n.translate('point') : l10n.translate('points')})'
                    : '';
                final rewardsSubtitle = redemptionsToday > 0
                    ? '$redemptionsToday ${redemptionsToday == 1 ? l10n.translate('reward') : l10n.translate('rewards')} ${l10n.translate('redeemed_lower')}$redemptionDetail'
                    : l10n.translate('no_redeemed');

                return Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        l10n.translate('tasks_done'),
                        completedToday.toString(),
                        totalPendingToday > 0
                            ? '/ ${completedToday + totalPendingToday} ${l10n.translate('today')}'
                            : l10n.translate('today'),
                        Icons.task_alt,
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        l10n.translate('points_earned'),
                        todayPoints.toString(),
                        pointsSubtitle,
                        Icons.trending_up,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        l10n.translate('rewards_redeemed'),
                        redemptionsToday.toString(),
                        rewardsSubtitle,
                        Icons.redeem,
                        Colors.orange,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
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
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildFamilyActivity() {
    return StreamBuilder<UserModel?>(
      stream: AuthService.userStream,
      initialData: AuthService.currentUser,
      builder: (context, userSnapshot) {
        final currentUser = userSnapshot.data;
        final isInFamily = currentUser?.familyId != null;

        if (!isInFamily) {
          return _buildPersonalProgressCard();
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _loadFamilyMembersData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Loading family data...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              print('Error loading family data: ${snapshot.error}');
              return _buildPersonalProgressCard();
            }

            final members = snapshot.data ?? [];

            if (members.isEmpty) {
              return _buildPersonalProgressCard();
            }

            members.sort((a, b) {
              final aPoints = a['todayPointsEarned'] as int? ?? 0;
              final bPoints = b['todayPointsEarned'] as int? ?? 0;
              return bPoints.compareTo(aPoints);
            });

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.groups,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context).translate('family_progress'),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context).translate('todays_leaderboard'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...members.asMap().entries.map((entry) {
                      final rank = entry.key + 1;
                      return _buildMemberSummaryCard(entry.value, rank);
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _medalColorForRank(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  Widget _buildMemberSummaryCard(Map<String, dynamic> member, int rank) {
    final theme = Theme.of(context);
    final name = (member['name'] as String?)?.trim().isNotEmpty == true
        ? member['name'] as String
        : 'Member';
    final isCurrentUser = member['isCurrentUser'] as bool? ?? false;
    final displayName = isCurrentUser ? '$name (${AppLocalizations.of(context).translate('you')})' : name;
    final currentPoints =
        member['currentPoints'] as int? ??
        member['lifetimeNetPoints'] as int? ??
        0;
    final completedToday = member['todayCompleted'] as int? ?? 0;
    final pointsEarnedToday = member['todayPointsEarned'] as int? ?? 0;
    final redemptionsToday = member['todayRedemptions'] as int? ?? 0;
    final pointsSpentToday = member['todayPointsSpent'] as int? ?? 0;
    final lifetimeRedemptions =
        member['lifetimeRedemptions'] as int? ?? redemptionsToday;
    final lifetimePointsSpent =
        member['lifetimePointsSpent'] as int? ?? pointsSpentToday;
    final lifetimePointsEarned =
        member['lifetimePointsEarned'] as int? ?? pointsEarnedToday;
    final lifetimeCompleted =
        member['lifetimeCompleted'] as int? ?? completedToday;

    final backgroundColor = isCurrentUser
        ? theme.colorScheme.primaryContainer.withOpacity(0.35)
        : theme.colorScheme.surfaceContainerHighest.withOpacity(0.4);
    final borderColor = isCurrentUser
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '#$rank',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (rank <= 3) ...[
                Icon(
                  Icons.emoji_events,
                  color: _medalColorForRank(rank),
                  size: 22,
                ),
                const SizedBox(width: 8),
              ],
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${AppLocalizations.of(context).translate('current_points_label')}: ${_formatNumber(currentPoints)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildSummaryPill(
                Icons.task_alt,
                '$completedToday ${AppLocalizations.of(context).translate('completed_today_label')}',
                theme.colorScheme.primary,
              ),
              _buildSummaryPill(
                Icons.trending_up,
                '${pointsEarnedToday > 0 ? '+' : ''}${_formatNumber(pointsEarnedToday)} ${AppLocalizations.of(context).translate('pts_today')}',
                Colors.green,
              ),
              if (pointsSpentToday > 0 || redemptionsToday > 0)
                _buildSummaryPill(
                  Icons.remove_circle,
                  redemptionsToday > 0
                      ? '$redemptionsToday ${AppLocalizations.of(context).translate('redeemed_today')} (-${_formatNumber(pointsSpentToday)} ${AppLocalizations.of(context).translate('pts')})'
                      : '-${_formatNumber(pointsSpentToday)} ${AppLocalizations.of(context).translate('pts_spent_today')}',
                  Colors.redAccent,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildSummaryPill(
                Icons.redeem,
                lifetimeRedemptions > 0
                    ? '$lifetimeRedemptions ${AppLocalizations.of(context).translate('total_redeems')}${lifetimePointsSpent > 0 ? ' (-${_formatNumber(lifetimePointsSpent)} ${AppLocalizations.of(context).translate('pts')})' : ''}'
                    : AppLocalizations.of(context).translate('no_redemptions_yet'),
                Colors.orange,
              ),
              if (lifetimePointsEarned > 0)
                _buildSummaryPill(
                  Icons.trending_up_rounded,
                  '${_formatNumber(lifetimePointsEarned)} ${AppLocalizations.of(context).translate('pts_earned_lifetime')}',
                  Colors.blue,
                ),
              if (lifetimePointsSpent > 0)
                _buildSummaryPill(
                  Icons.money_off,
                  '-${_formatNumber(lifetimePointsSpent)} ${AppLocalizations.of(context).translate('pts_spent_lifetime')}',
                  Colors.deepOrange,
                ),
              if (lifetimeCompleted > 0)
                _buildSummaryPill(
                  Icons.checklist_rtl,
                  '$lifetimeCompleted ${AppLocalizations.of(context).translate('tasks_lifetime')}',
                  theme.colorScheme.tertiary,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPill(IconData icon, String label, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalProgressCard() {
    final currentUser = AuthService.currentUser;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'My Progress',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, int>>(
              future: _loadUserTodayData(currentUser?.id ?? '', DateTime.now()),
              builder: (context, snapshot) {
                final data =
                    snapshot.data ??
                    {
                      'completed': 0,
                      'points': 0,
                      'redemptions': 0,
                      'pointsEarned': 0,
                      'pointsSpent': 0,
                    };
                return _buildProgressSummary(
                  currentUser?.displayName ?? 'You',
                  data['completed']!,
                  data['points']!,
                  isCurrentUser: true,
                  extraData: data,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSummary(
    String title,
    int completedTasks,
    int points, {
    bool isCurrentUser = false,
    Map<String, int>? extraData,
  }) {
    final redemptions = extraData?['redemptions'] ?? 0;
    final pointsEarned = extraData?['pointsEarned'] ?? 0;
    final pointsSpent = extraData?['pointsSpent'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$completedTasks tasks',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$points points',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        if (redemptions > 0 || pointsEarned > 0 || pointsSpent > 0) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              if (redemptions > 0) ...[
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.redeem, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$redemptions redeems',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
              if (pointsEarned > 0) ...[
                Row(
                  children: [
                    Icon(Icons.add_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '+$pointsEarned',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              if (pointsSpent > 0) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.remove_circle,
                        color: Colors.redAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '-$pointsSpent',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _loadFamilyMembersData() async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser?.familyId == null) {
        return [];
      }

      final familyService = FamilyService();
      await familyService.initialize();

      // Check if family exists locally first
      var family = familyService.getFamilyById(currentUser!.familyId!);

      if (family != null) {
        print(
          '✅ Found existing family locally with ${family.childrenIds.length} children',
        );
        // Only refresh to check for new members, don't rebuild from scratch
        await _refreshFamilyDataFromFirestore(
          familyService,
          currentUser.familyId!,
        );
        // Get updated family after refresh
        family = familyService.getFamilyById(currentUser.familyId!);
      } else {
        print('⚠️ No local family found for ${currentUser.familyId}');
        // TEMPORARILY DISABLED TO STOP AUTO-CREATION LOOP
        // await _simpleCreateFamily(familyService, currentUser);
        // Get family after creation
        // family = familyService.currentFamily;
      }

      if (family == null) {
        print('❌ Still no family data after refresh/recovery');
        return [];
      }

      if (family.childrenIds.isEmpty) {
        print('ℹ️ Family has no children to display in leaderboard');
        return [];
      }

      final List<Map<String, dynamic>> membersData = [];
      final userService = UserService();
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      // Load only child data for ranking/summary (parents are excluded by design)
      for (final childId in family.childrenIds) {
        try {
          final childData = await _loadUserTodayData(childId, startOfDay);
          final lifetimeData = await _loadUserLifetimeStats(childId);
          final childUser = await userService
              .getUser(childId)
              .catchError((_) => null);

          final fallbackId = childId.length >= 8
              ? childId.substring(0, 8)
              : childId;
          final childName = childUser?.displayName ?? 'Child $fallbackId';
          final completedToday = childData['completed'] ?? 0;
          final pointsEarnedToday = childData['pointsEarned'] ?? 0;
          final redemptionsToday = childData['redemptions'] ?? 0;
          final pointsSpentToday = childData['pointsSpent'] ?? 0;

          final int? storedPoints = childUser?.currentPoints;
          final int? calculatedPoints =
              lifetimeData['netPoints'] ?? lifetimeData['totalPoints'];
          int currentPoints;
          if (calculatedPoints != null) {
            if (storedPoints != null && storedPoints != calculatedPoints) {
              print(
                '📊 Using calculated points ($calculatedPoints) instead of stored points ($storedPoints) for $childId',
              );
            }
            currentPoints = calculatedPoints;
          } else if (storedPoints != null) {
            currentPoints = storedPoints;
          } else {
            currentPoints = 0;
          }

          final lifetimeNetPoints =
              calculatedPoints ?? storedPoints ?? currentPoints;
          final lifetimeRedemptions = lifetimeData['redemptions'] ?? 0;
          final lifetimePointsSpent = lifetimeData['pointsSpent'] ?? 0;
          final lifetimePointsEarned = lifetimeData['pointsEarned'] ?? 0;
          final lifetimeCompleted = lifetimeData['completed'] ?? 0;

          membersData.add({
            'id': childId,
            'name': childName,
            'isCurrentUser': childId == currentUser.id,
            'todayCompleted': completedToday,
            'todayPointsEarned': pointsEarnedToday,
            'todayRedemptions': redemptionsToday,
            'todayPointsSpent': pointsSpentToday,
            'currentPoints': currentPoints,
            'lifetimeNetPoints': lifetimeNetPoints,
            'lifetimeRedemptions': lifetimeRedemptions,
            'lifetimePointsSpent': lifetimePointsSpent,
            'lifetimePointsEarned': lifetimePointsEarned,
            'lifetimeCompleted': lifetimeCompleted,
          });
        } catch (childError) {
          print('❌ Error loading data for child $childId: $childError');
        }
      }

      return membersData;
    } catch (e) {
      print('Error loading family members data: $e');
      return [];
    }
  }

  Future<void> _refreshFamilyDataFromFirestore(
    FamilyService familyService,
    String familyId,
  ) async {
    try {
      // Query Firestore to get the latest family data
      print('🔍 Checking Firestore for new family members: $familyId');

      // First, let's debug what users actually exist
      print('🔍 DEBUG: Querying all users to see family relationships...');
      final allUsersQuery = await FirebaseFirestore.instance
          .collection('users')
          .get();

      print('📋 DEBUG: Found ${allUsersQuery.docs.length} total users:');
      for (final doc in allUsersQuery.docs) {
        final data = doc.data();
        final userFamilyId = data['familyId'] as String?;
        final accountType = data['accountType'] as String?;
        final displayName = data['displayName'] as String?;
        print(
          '  👤 ${doc.id} ($displayName): familyId=$userFamilyId, accountType=$accountType',
        );
      }

      final usersQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('familyId', isEqualTo: familyId)
          .where('accountType', isEqualTo: 'child') // Only look for children
          .get();

      if (usersQuery.docs.isEmpty) {
        print('ℹ️ No children found in Firestore for family $familyId');
        return;
      }

      print('📋 Found ${usersQuery.docs.length} children in Firestore');

      final currentFamily = familyService.getFamilyById(familyId);
      if (currentFamily == null) {
        print('⚠️ Current family not found locally');
        return;
      }

      // Check for new children that aren't in the local family yet
      final currentChildrenIds = currentFamily.childrenIds.toSet();
      final firestoreChildrenIds = usersQuery.docs.map((doc) => doc.id).toSet();
      final newChildrenIds = firestoreChildrenIds.difference(
        currentChildrenIds,
      );

      print('👶 Current children: ${currentChildrenIds.length}');
      print('🔍 Firestore children: ${firestoreChildrenIds.length}');
      print('🆕 New children to add: ${newChildrenIds.length}');

      // Also check for children with wrong familyId that need to be fixed
      await _fixChildrenFamilyIds(familyService, familyId);

      // Add any new children found in Firestore
      for (final newChildId in newChildrenIds) {
        try {
          print('➕ Adding new child: $newChildId');
          await familyService.addChildToFamily(
            childId: newChildId,
            familyId: familyId,
          );
        } catch (e) {
          print('❌ Error adding child $newChildId: $e');
        }
      }

      if (newChildrenIds.isNotEmpty) {
        print(
          '✅ Successfully added ${newChildrenIds.length} new children to family',
        );
      }
    } catch (e) {
      print('❌ Error refreshing family data: $e');
    }
  }

  // ignore: unused_element
  Future<void> _simpleCreateFamily(
    FamilyService familyService,
    UserModel currentUser,
  ) async {
    try {
      print('🔨 Simple family creation for user: ${currentUser.displayName}');

      if (currentUser.accountType.name == 'parent') {
        // Current user is parent - create family and find children
        print('👨‍👩‍👧‍👦 Creating family with current user as parent');

        final family = await familyService.createFamily(
          name: '${currentUser.displayName}\'s Family',
          parentId: currentUser.id,
          description:
              'Family created on ${DateTime.now().toString().split(' ')[0]}',
        );

        print('✅ Family created: ${family.id}');

        // Find and add any children with the same original familyId
        final childrenQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('familyId', isEqualTo: currentUser.familyId)
            .where('accountType', isEqualTo: 'child')
            .get();

        for (final doc in childrenQuery.docs) {
          try {
            await familyService.addChildToFamily(childId: doc.id);
            print('👶 Added child: ${doc.id}');
          } catch (e) {
            print('❌ Error adding child ${doc.id}: $e');
          }
        }
      } else {
        print('👶 Current user is child - looking for parent to join family');

        // Current user is child - find parent and join their family
        final parentQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('familyId', isEqualTo: currentUser.familyId)
            .where('accountType', isEqualTo: 'parent')
            .limit(1)
            .get();

        if (parentQuery.docs.isNotEmpty) {
          final parentId = parentQuery.docs.first.id;
          print('👨‍👩‍👧‍👦 Found parent: $parentId');

          // Parent should have created the family, try to find it
          final parentFamily = familyService.getFamilyForUser(parentId);
          if (parentFamily != null) {
            await familyService.addChildToFamily(
              childId: currentUser.id,
              familyId: parentFamily.id,
            );
            print('✅ Joined existing family: ${parentFamily.id}');
          }
        }
      }
    } catch (e) {
      print('❌ Error in simple family creation: $e');
    }
  }

  Future<void> _fixChildrenFamilyIds(
    FamilyService familyService,
    String parentFamilyId,
  ) async {
    try {
      print('🔧 Checking for family ID mismatch...');

      // Look for children that might belong to this parent but have different familyId
      final childrenFamilyId =
          '1762219752591'; // The familyId the children currently have

      print('🔍 Looking for children with familyId: $childrenFamilyId');

      final childrenQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('familyId', isEqualTo: childrenFamilyId)
          .where('accountType', isEqualTo: 'child')
          .get();

      print(
        '📋 Found ${childrenQuery.docs.length} children with familyId: $childrenFamilyId',
      );

      if (childrenQuery.docs.isNotEmpty) {
        // Children exist with a different familyId - let's fix the parent instead
        final currentUser = AuthService.currentUser;
        if (currentUser != null && currentUser.accountType.name == 'parent') {
          print(
            '🔧 Updating parent familyId from $parentFamilyId to $childrenFamilyId to match children',
          );

          // Update parent's familyId in Firestore to match children
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.id)
              .update({'familyId': childrenFamilyId});

          // Clear and recreate the local family with correct ID
          await familyService.clearFamilyData();

          // Create family with the children's familyId
          await familyService.createFamily(
            name: '${currentUser.displayName}\'s Family',
            parentId: currentUser.id,
            description: 'Family reunited with correct ID',
          );

          // Add all the children to the family
          for (final doc in childrenQuery.docs) {
            try {
              final childData = doc.data();
              final childName =
                  childData['displayName'] as String? ?? 'Unknown';
              await familyService.addChildToFamily(childId: doc.id);
              print('👶 Added child to family: $childName');
            } catch (e) {
              print('❌ Error adding child ${doc.id}: $e');
            }
          }

          print('✅ Successfully unified family with ID: $childrenFamilyId');
        }
      }
    } catch (e) {
      print('❌ Error fixing family IDs: $e');
    }
  }

  // ignore: unused_element
  Future<void> _recoverFamilyFromFirestore(
    FamilyService familyService,
    String familyId,
  ) async {
    try {
      print('🔧 Attempting to recover family data from Firestore...');

      // Query all users with this familyId
      final usersQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('familyId', isEqualTo: familyId)
          .get();

      if (usersQuery.docs.isEmpty) {
        print('❌ No users found with familyId: $familyId');
        return;
      }

      print('📋 Found ${usersQuery.docs.length} users to recover family from');

      String? parentId;
      List<String> childrenIds = [];

      for (final doc in usersQuery.docs) {
        final data = doc.data();
        final accountType = data['accountType'] as String?;
        final displayName = data['displayName'] as String?;
        final email = data['email'] as String?;
        final userId = doc.id;

        print(
          '👤 User $userId ($displayName, $email): accountType = $accountType',
        );

        if (accountType == 'parent') {
          parentId = userId;
        } else if (accountType == 'child') {
          childrenIds.add(userId);
        }
      }

      if (parentId == null) {
        print('❌ No parent found in family data');
        return;
      }

      print(
        '🔧 Recreating family: parent=$parentId, children=${childrenIds.length}',
      );

      // Create the family with the correct family ID
      final newFamily = await familyService.createFamily(
        name: 'My Family',
        parentId: parentId,
        description: 'Recovered family data',
      );

      print('✅ Created family with ID: ${newFamily.id}');

      // If the familyId doesn't match the created family, we need to update users
      if (newFamily.id != familyId) {
        print('🔄 Updating users to use correct familyId: ${newFamily.id}');

        // Update parent's familyId
        final userService = UserService();
        final parentUser = await userService.getUser(parentId);
        if (parentUser != null) {
          await userService.updateUser(
            parentUser.copyWith(familyId: newFamily.id),
          );
        }

        // Update all children's familyId
        for (final childId in childrenIds) {
          final childUser = await userService.getUser(childId);
          if (childUser != null) {
            await userService.updateUser(
              childUser.copyWith(familyId: newFamily.id),
            );
          }
        }
      }

      // Add all children to the new family
      for (final childId in childrenIds) {
        await familyService.addChildToFamily(childId: childId);
      }

      print('✅ Family recovery completed successfully');
    } catch (e) {
      print('❌ Error recovering family data: $e');
    }
  }

  Future<Map<String, int>> _loadUserTodayData(
    String userId,
    DateTime date,
  ) async {
    if (userId.isEmpty) {
      return {'completed': 0, 'points': 0};
    }

    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final dateKey =
          '${startOfDay.year.toString().padLeft(4, '0')}-${startOfDay.month.toString().padLeft(2, '0')}-${startOfDay.day.toString().padLeft(2, '0')}';

      String? familyId;
      String? accountType;

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        if (userDoc.exists) {
          final data = userDoc.data();
          if (data != null) {
            familyId = data['familyId'] as String?;
            accountType = data['accountType'] as String?;
          }
        }
      } catch (userLoadError) {
        print('⚠️ Unable to load user $userId while preparing generation: $userLoadError');
      }

      try {
        print('🔧 Ensuring generation for $userId on $dateKey (familyId=$familyId)');
        final generated = await _taskGenerationService.generateTasksForUserForDate(
          userId: userId,
          date: startOfDay,
          familyId: familyId,
        );
        print('🔁 Generation complete: ${generated.length} history entries for $userId on $dateKey (accountType=$accountType)');
        if (generated.isNotEmpty) {
          for (var i = 0; i < (generated.length > 3 ? 3 : generated.length); i++) {
            final g = generated[i];
            print('   • [${i+1}] ${g.title} | template? ${g.metadata['createdFromTemplate'] ?? true} | due=${g.dueDate}');
          }
        }
      } catch (generationError) {
        print('⚠️ Failed to generate tasks for $userId on $dateKey: $generationError');
      }

      print('🔍 Loading today data (history) for user: $userId');
      print('  📅 Date range: $startOfDay to $endOfDay');

      final processedIds = <String>{};
      final tasks = <TaskModel>[];

      TaskModel? parseTask(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
        try {
          return TaskModel.fromFirestore(doc);
        } catch (e) {
          print('❌ Error parsing task ${doc.id}: $e');
          return null;
        }
      }

      void addTask(TaskModel? task, {String source = 'unknown'}) {
        if (task == null) {
          return;
        }
        if (processedIds.add(task.id)) {
          tasks.add(task);
        } else {
          print('ℹ️ Skipping duplicate task ${task.id} from $source');
        }
      }

      final historySnapshot = await FirebaseFirestore.instance
          .collection('task_history')
          .where('ownerId', isEqualTo: userId)
          .where('generatedForDate', isEqualTo: dateKey)
          .get();

      for (final doc in historySnapshot.docs) {
        addTask(parseTask(doc), source: 'history:generatedForDate');
      }

      // Fallback: load all history for owner and filter locally so no composite index needed
      if (tasks.isEmpty) {
        print(
          'ℹ️ No generated history found, loading owner history and filtering locally',
        );
        final rangeSnapshot = await FirebaseFirestore.instance
            .collection('task_history')
            .where('ownerId', isEqualTo: userId)
            .get();
        for (final doc in rangeSnapshot.docs) {
          addTask(parseTask(doc), source: 'history:fallback');
        }
      }

      // Include tasks still in active collection to capture redemptions and recent completions
      final activeTasksSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedToUserId', isEqualTo: userId)
          .get();
      for (final doc in activeTasksSnapshot.docs) {
        addTask(parseTask(doc), source: 'tasks');
      }

      print('📋 Aggregated ${tasks.length} tasks for $userId across sources');

      int completedTasks = 0;
      int redemptions = 0;
      int pointsEarned = 0;
      int pointsSpent = 0;

      for (final task in tasks) {
        final completionMoment =
            task.completedAt ?? task.approvedAt ?? task.createdAt;
        final withinRange =
            !completionMoment.isBefore(startOfDay) &&
            completionMoment.isBefore(endOfDay);

        if (!withinRange) {
          continue;
        }

        final isCompleted =
            task.status == TaskStatus.completed ||
            task.status == TaskStatus.approved;
        if (!isCompleted) {
          continue;
        }

        final isRedemption = task.category == 'Reward Redemption';
        if (isRedemption) {
          redemptions++;
          pointsSpent += task.pointValue.abs();
        } else {
          completedTasks++;
          pointsEarned += task.pointValue;
        }
      }

      final totalPoints = pointsEarned - pointsSpent;
      print(
        '💰 History totals for $userId: $completedTasks tasks (+$pointsEarned), $redemptions redemptions (-$pointsSpent), net: $totalPoints',
      );

      return {
        'completed': completedTasks,
        'points': totalPoints,
        'pointsEarned': pointsEarned,
        'pointsSpent': pointsSpent,
        'redemptions': redemptions,
      };
    } catch (e) {
      print('❌ Error loading history for $userId: $e');
      return {'completed': 0, 'points': 0};
    }
  }

  Future<Map<String, int>> _loadUserLifetimeStats(String userId) async {
    if (userId.isEmpty) {
      return {};
    }

    try {
      final processedIds = <String>{};
      final tasks = <TaskModel>[];

      TaskModel? parseTask(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
        try {
          return TaskModel.fromFirestore(doc);
        } catch (e) {
          print('❌ Error parsing lifetime task ${doc.id}: $e');
          return null;
        }
      }

      void addTask(TaskModel? task, {String source = 'unknown'}) {
        if (task == null) {
          return;
        }
        if (processedIds.add(task.id)) {
          tasks.add(task);
        }
      }

      final historySnapshot = await FirebaseFirestore.instance
          .collection('task_history')
          .where('ownerId', isEqualTo: userId)
          .get();
      for (final doc in historySnapshot.docs) {
        addTask(parseTask(doc), source: 'history');
      }

      final activeTasksSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedToUserId', isEqualTo: userId)
          .get();
      for (final doc in activeTasksSnapshot.docs) {
        addTask(parseTask(doc), source: 'tasks');
      }

      int completedTasks = 0;
      int pointsEarned = 0;
      int redemptions = 0;
      int pointsSpent = 0;

      for (final task in tasks) {
        final isCompleted =
            task.status == TaskStatus.completed ||
            task.status == TaskStatus.approved;
        if (!isCompleted) {
          continue;
        }

        if (task.category == 'Reward Redemption') {
          redemptions++;
          pointsSpent += task.pointValue.abs();
        } else {
          completedTasks++;
          pointsEarned += task.pointValue;
        }
      }

      final totalPoints = pointsEarned - pointsSpent;

      return {
        'completed': completedTasks,
        'pointsEarned': pointsEarned,
        'redemptions': redemptions,
        'pointsSpent': pointsSpent,
        'totalPoints': totalPoints,
        'netPoints': totalPoints,
      };
    } catch (e) {
      print('❌ Error loading lifetime stats for $userId: $e');
      return {};
    }
  }

  Widget _buildTasksTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _previousDay,
                    icon: const Icon(Icons.chevron_left),
                    tooltip: 'Previous Day',
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
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
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withOpacity(0.3),
                    ),
                  ),
                  IconButton(
                    onPressed: _isToday() ? null : _nextDay,
                    icon: const Icon(Icons.chevron_right),
                    tooltip: 'Next Day',
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: _showTaskHistory,
                    icon: const Icon(Icons.history),
                    tooltip: '5-Day History',
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.secondaryContainer.withOpacity(0.3),
                    ),
                  ),
                  if (_shouldShowManageTasksButton()) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: _openTaskManagement,
                      icon: const Icon(Icons.settings),
                      tooltip: 'Manage Tasks',
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.tertiaryContainer.withOpacity(0.3),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
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
          const SizedBox(height: 16),
          _buildTaskList(),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    return StreamBuilder<List<TaskModel>>(
      stream: _tasksStream,
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
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.red),
                  ),
                ],
              ),
            ),
          );
        }

        final allTasks = snapshot.data ?? [];

        // Filter tasks for selected date
        final selectedStart = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        );
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
              final completedDate = DateTime(
                task.completedAt!.year,
                task.completedAt!.month,
                task.completedAt!.day,
              );
              if (completedDate.isAtSameMomentAs(selectedStart)) {
                return true; // Show tasks completed today
              }
            }

            // Show pending tasks (due today, overdue, or no due date)
            if (task.status == TaskStatus.pending) {
              if (task.dueDate == null) {
                // For tasks without due dates: only show recurring tasks for today
                // One-time tasks without due dates should only appear when specifically created
                if (task.isRecurring) {
                  return true; // Show recurring tasks without due dates for today
                } else {
                  // For one-time tasks without due dates, only show if created today
                  final createdDate = DateTime(
                    task.createdAt.year,
                    task.createdAt.month,
                    task.createdAt.day,
                  );
                  return createdDate.isAtSameMomentAs(selectedStart);
                }
              }

              final taskDate = DateTime(
                task.dueDate!.year,
                task.dueDate!.month,
                task.dueDate!.day,
              );
              return taskDate.isBefore(selectedEnd); // Due today or overdue
            }

            return false;
          } else {
            // For other dates: show tasks that match the selected date
            final isPastDate = selectedStart.isBefore(todayStart);

            // Check if task was completed on the selected date
            if (task.completedAt != null) {
              final completedDate = DateTime(
                task.completedAt!.year,
                task.completedAt!.month,
                task.completedAt!.day,
              );
              if (completedDate.isAtSameMomentAs(selectedStart)) {
                return true; // Show tasks completed on selected date
              }
            }

            // For past dates, ONLY show completed tasks (skip pending/due tasks)
            if (isPastDate) {
              return false;
            }

            // For future dates: show tasks due on the selected date
            if (task.dueDate != null) {
              final taskDate = DateTime(
                task.dueDate!.year,
                task.dueDate!.month,
                task.dueDate!.day,
              );
              if (taskDate.isAtSameMomentAs(selectedStart)) {
                return true; // Show tasks due on selected date
              }
            }

            // For future dates, also show undated pending tasks
            if (selectedStart.isAfter(todayStart) &&
                task.dueDate == null &&
                task.status == TaskStatus.pending) {
              // Only show recurring tasks for future planning, not one-time tasks
              if (task.isRecurring) {
                return true; // Show recurring undated tasks for future planning
              }
            }

            return false;
          }
        }).toList();

        tasks.addAll(directTasks);

        // Second, add virtual recurring task instances for future dates
        if (!_isToday()) {
          // Group recurring tasks by title/category to find all instances
          final recurringTaskGroups = <String, List<TaskModel>>{};

          final recurringTasks = filteredTasks
              .where((t) => t.isRecurring && t.recurrencePattern != null)
              .toList();

          for (final task in recurringTasks) {
            final key =
                '${task.title}_${task.category}_${task.assignedToUserId}';
            if (!recurringTaskGroups.containsKey(key)) {
              recurringTaskGroups[key] = [];
            }
            recurringTaskGroups[key]!.add(task);
          }

          // For each recurring task group, find the EARLIEST task to use as the pattern base
          for (final taskGroup in recurringTaskGroups.values) {
            // Sort by due date ASCENDING to get the original task (earliest)
            taskGroup.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
            final originalTask =
                taskGroup.first; // Use the earliest task as the pattern base

            // Check if this target date should show the task based on the original pattern
            if (_shouldShowRecurringTaskForDate(originalTask, selectedStart)) {
              // Check if we already have a real task for this date with same title
              final existingRealTask = tasks.any(
                (t) =>
                    !t.id.contains('_virtual_') &&
                    t.title == originalTask.title &&
                    t.dueDate != null &&
                    DateTime(
                      t.dueDate!.year,
                      t.dueDate!.month,
                      t.dueDate!.day,
                    ).isAtSameMomentAs(selectedStart),
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

        final bool isPastSelection = _isSelectedDateInPast();

        if (tasks.isEmpty) {
          final emptyTitle = _getEmptyStateTitle(allTasks);
          final emptyMessage = _getEmptyStateMessage(allTasks);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.task_alt,
                        size: 64,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        emptyTitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      if (emptyMessage.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          emptyMessage,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (!isPastSelection) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _quickEarnPoints,
                              icon: const Icon(Icons.flash_on),
                              label: const Text('Quick Task'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onPrimary,
                              ),
                            ),
                            if (_shouldShowAddTaskButton()) ...[
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: _addNewTask,
                                icon: const Icon(Icons.add_task),
                                label: const Text('Add Task'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // Separate regular tasks from redemption tasks
        final regularTasks = tasks
            .where((task) => task.category != 'Reward Redemption')
            .toList();
        final redemptionTasks = allTasks
            .where(
              (task) =>
                  task.category == 'Reward Redemption' &&
                  task.status == TaskStatus.completed,
            )
            .toList();

        // Filter redemptions for selected date
        final selectedRedemptions = redemptionTasks.where((task) {
          if (task.completedAt != null) {
            final completedDate = DateTime(
              task.completedAt!.year,
              task.completedAt!.month,
              task.completedAt!.day,
            );
            return completedDate.isAtSameMomentAs(selectedStart);
          }
          return false;
        }).toList()..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Regular Tasks Section
            if (regularTasks.isNotEmpty) ...[
              Text(
                'Tasks',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...regularTasks
                  .map((task) => _buildTaskItemFromModel(task))
                  ,
              const SizedBox(height: 8),
              Card(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.3),
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
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...selectedRedemptions
                  .map((redemption) => _buildRedemptionHistoryCard(redemption))
                  ,
              const SizedBox(height: 8),
              Card(
                color: Theme.of(
                  context,
                ).colorScheme.errorContainer.withOpacity(0.3),
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
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt,
                            size: 64,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _getEmptyStateTitle(allTasks),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getEmptyStateMessage(allTasks),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          if (!isPastSelection) ...[
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _quickEarnPoints,
                                  icon: const Icon(Icons.flash_on),
                                  label: const Text('Quick Task'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  ),
                                ),
                                if (_shouldShowAddTaskButton()) ...[
                                  const SizedBox(width: 12),
                                  OutlinedButton.icon(
                                    onPressed: _addNewTask,
                                    icon: const Icon(Icons.add_task),
                                    label: const Text('Add Task'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
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
    final isCompleted =
        task.status == TaskStatus.completed ||
        task.status == TaskStatus.approved;
    final isRecurring = task.isRecurring;
    final isPending = task.status == TaskStatus.pending;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCompleted
              ? Colors.green
              : _getPriorityColor(task.priority),
          child: Icon(
            isCompleted
                ? Icons.check
                : (isRecurring ? Icons.repeat : Icons.task),
            color: Colors.white,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                AppLocalizations.of(context).translateTaskTitle(task.title),
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  fontWeight: FontWeight.w500,
                  color: isCompleted
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : null,
                ),
              ),
            ),
            if (isRecurring)
              Icon(
                Icons.repeat,
                size: 16,
                color: isCompleted
                    ? Colors.green
                    : Theme.of(context).colorScheme.secondary,
              ),
          ],
        ),
        subtitle: Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${task.category} • ${task.pointValue} points',
              style: TextStyle(
                color: isCompleted
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : null,
              ),
            ),
            if (task.dueDate != null)
              Text(
                '• Due: ${_formatTaskDate(task.dueDate!)}',
                style: TextStyle(
                  color: isCompleted
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : (task.isOverdue ? Colors.red : null),
                  fontWeight:
                      task.isOverdue && !isCompleted ? FontWeight.w600 : null,
                ),
              )
            else
              Text(
                '• Anytime',
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.7),
                ),
              ),
            if (isCompleted && task.completedAt != null)
              Text(
                '• Completed: ${_formatTaskDate(task.completedAt!)}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
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
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
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
                            side: const BorderSide(
                              color: Colors.orange,
                              width: 1,
                            ),
                            foregroundColor: Colors.orange,
                          ),
                          child: Text(
                            AppLocalizations.of(context).translate('undo'),
                            style: const TextStyle(fontSize: 10),
                          ),
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
                  child: Text(AppLocalizations.of(context).translate('done'), style: const TextStyle(fontSize: 12)),
                ),
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _translateTaskStatus(task.status),
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
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
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
                AppLocalizations.of(context).translate('available_rewards'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (_canManageRewards)
                ElevatedButton.icon(
                  onPressed: _openRewardsManagement,
                  icon: const Icon(Icons.settings, size: 18),
                  label: Text(AppLocalizations.of(context).translate('manage')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                )
              else
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _openRewardsManagement,
                      icon: const Icon(Icons.visibility, size: 18),
                      label: Text(AppLocalizations.of(context).translate('view')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _addRewardWish,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(AppLocalizations.of(context).translate('add')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Set Goal Button
          StreamBuilder<GoalModel?>(
            stream: _goalService.watchActiveGoal(),
            builder: (context, snapshot) {
              print('🎁 Rewards tab goal StreamBuilder - connectionState: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, hasError: ${snapshot.hasError}');
              if (snapshot.hasError) {
                print('❌ Rewards tab goal error: ${snapshot.error}');
              }
              final hasGoal = snapshot.hasData && snapshot.data != null;
              print('🎁 Rewards tab hasGoal: $hasGoal');
              
              return Column(
                children: [
                  if (hasGoal)
                    GoalProgressCard(
                      goal: snapshot.data!,
                      currentPoints: _currentPoints,
                      onDelete: () => _deleteGoal(snapshot.data!.id),
                    )
                  else
                    Card(
                      elevation: 2,
                      child: InkWell(
                        onTap: _showSetGoalDialog,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.flag,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context).translate('set_goal'),
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      AppLocalizations.of(context).translate('your_goal'),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),

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
            ...todayRedemptions.map(
              (redemption) => _buildRedemptionHistoryCard(redemption),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRewardGrid() {
    return ValueListenableBuilder<List<RewardItem>>(
      valueListenable: RewardService().rewardsStream,
      builder: (context, allRewards, child) {
        final activeRewards = allRewards.where((r) => r.isActive && r.status == 'approved').toList();
        final pendingRewards = allRewards.where((r) => r.status == 'pending').toList();

        if (activeRewards.isEmpty && pendingRewards.isEmpty) {
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
                      style: TextStyle(color: Colors.grey.shade500),
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
            // Active approved rewards
            for (int i = 0; i < activeRewards.length; i += 2)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(child: _buildRewardGridItem(activeRewards[i], isEnabled: true)),
                    const SizedBox(width: 12),
                    if (i + 1 < activeRewards.length)
                      Expanded(
                        child: _buildRewardGridItem(activeRewards[i + 1], isEnabled: true),
                      )
                    else
                      const Expanded(child: SizedBox()),
                  ],
                ),
              ),
            // Pending rewards (disabled)
            if (pendingRewards.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_bottom, size: 16, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Pending Approval',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              for (int i = 0; i < pendingRewards.length; i += 2)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(child: _buildRewardGridItem(pendingRewards[i], isEnabled: false)),
                      const SizedBox(width: 12),
                      if (i + 1 < pendingRewards.length)
                        Expanded(
                          child: _buildRewardGridItem(pendingRewards[i + 1], isEnabled: false),
                        )
                      else
                        const Expanded(child: SizedBox()),
                    ],
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildRewardGridItem(RewardItem reward, {bool isEnabled = true}) {
    final available = isEnabled && _currentPoints >= reward.points;
    final icon = IconData(reward.iconCodePoint, fontFamily: 'MaterialIcons');
    final color = Color(reward.colorValue);
    final isPending = reward.status == 'pending';

    return Card(
      elevation: isPending ? 1 : 2,
      color: isPending ? Colors.grey.shade50 : null,
      child: InkWell(
        onTap: isPending
            ? () => _showPendingRewardDialog(reward)
            : (available
                ? () => _redeemReward(reward.title, reward.points)
                : null),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: isEnabled && !isPending ? (available ? color : Colors.grey.shade300) : Colors.grey.shade200,
                    radius: 24,
                    child: Icon(
                      icon,
                      size: 24,
                      color: isEnabled && !isPending ? (available ? Colors.white : Colors.grey.shade600) : Colors.grey.shade400,
                    ),
                  ),
                  if (isPending)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.hourglass_bottom,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).translateRewardTitle(reward.title),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isEnabled && !isPending ? (available ? null : Theme.of(context).disabledColor) : Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending
                      ? Colors.amber.shade50
                      : (available
                          ? color.withOpacity(0.1)
                          : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isPending ? 'Pending' : '${reward.points} pts',
                  style: TextStyle(
                    color: isPending ? Colors.amber.shade700 : (available ? color : Colors.grey.shade600),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              if (!available && !isPending) ...[
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
          Text(AppLocalizations.of(context).profile, style: Theme.of(context).textTheme.headlineMedium),
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
              '${AppLocalizations.of(context).translate('joined')} ${_formatMemberSinceDate(AuthService.currentUser?.createdAt ?? DateTime.now())}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildProfileStat(
                  AppLocalizations.of(context).translate('total_points'),
                  _formatNumber(_currentPoints),
                ),
                _buildProfileStat(AppLocalizations.of(context).translate('tasks_done'), _totalTasksDone.toString()),
                _buildProfileStat(AppLocalizations.of(context).translate('rewards'), _totalRewards.toString()),
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
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildProfileStats() {
    // Calculate achievements based on real user activity
    final hasFirstTask = _totalTasksDone >= 1;
    final hasWeekStreak = _totalTasksDone >= 7; // Simplified: 7 completed tasks
    final hasPointCollector = _currentPoints >= 1000;
    final hasTaskMaster = _totalTasksDone >= 50;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).translate('achievements'), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _buildAchievementItem(
              AppLocalizations.of(context).translate('first_task'),
              AppLocalizations.of(context).translate('complete_first_task'),
              hasFirstTask,
            ),
            _buildAchievementItem(
              AppLocalizations.of(context).translate('week_streak'),
              AppLocalizations.of(context).translate('complete_7_tasks'),
              hasWeekStreak,
            ),
            _buildAchievementItem(
              AppLocalizations.of(context).translate('point_collector'),
              AppLocalizations.of(context).translate('earn_1000_points'),
              hasPointCollector,
            ),
            _buildAchievementItem(
              AppLocalizations.of(context).translate('task_master'),
              AppLocalizations.of(context).translate('complete_50_tasks'),
              hasTaskMaster,
            ),
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
          if (earned) const Icon(Icons.check_circle, color: Colors.green),
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
                title: Text(AppLocalizations.of(context).settings),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openSettings,
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: Text(AppLocalizations.of(context).translate('transaction_history')),
                trailing: const Icon(Icons.chevron_right),
                onTap: _viewAllHistory,
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: Text(AppLocalizations.of(context).translate('help_support')),
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
            child: Text(AppLocalizations.of(context).translate('logout')),
          ),
        ),
      ],
    );
  }

  Widget _buildFamilyTab() {
    return StreamBuilder<UserModel?>(
      stream: AuthService.userStream,
      initialData: AuthService.currentUser,
      builder: (context, snapshot) {
        final currentUser = snapshot.data;
        final isParent = currentUser?.hasManagementPermissions ?? false;

        return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.family_restroom,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).translate('family'),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      isParent ? AppLocalizations.of(context).translate('manage_family') : AppLocalizations.of(context).translate('family'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Family ID display
          if (currentUser?.familyId != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.key,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Family ID',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            currentUser!.familyId!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontFamily: 'monospace',
                                  letterSpacing: 0.5,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: 'Copy Family ID',
                      onPressed: () {
                        // Copy to clipboard
                        // ignore: unawaited_futures
                        Clipboard.setData(
                          ClipboardData(text: currentUser.familyId!),
                        ).then(
                          (_) => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Family ID copied to clipboard'),
                              duration: Duration(seconds: 2),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          if (isParent) ...[
            // Parent options
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Parent Controls',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.analytics),
                      title: const Text('Family Dashboard'),
                      subtitle: const Text(
                        'View children\'s progress and history',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _openFamilyDashboard,
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Child options
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).translate('join_family'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context).translate('use_invitation_code'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openJoinFamily,
                        icon: const Icon(Icons.family_restroom),
                        label: Text(AppLocalizations.of(context).translate('join_family')),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Family info card
          _buildFamilyStatusCard(currentUser, isParent),
        ],
      ),
    );
      },
    );
  }

  Widget _buildFamilyStatusCard(UserModel? currentUser, bool isParent) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).translate('family_status'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (currentUser?.familyId != null) ...[
              // User is part of a family
              FutureBuilder<Map<String, dynamic>?>(
                future: _getFamilyDetails(currentUser!.familyId!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context).translate('loading_family_info')),
                      ],
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.orange.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context).translate('unable_to_load_family'),
                            style: const TextStyle(color: Colors.orange),
                          ),
                        ),
                      ],
                    );
                  }

                  final familyData = snapshot.data!;
                  final familyName = familyData['name'] as String?;
                  final parentName = familyData['parentName'] as String?;
                  final childrenCount =
                      familyData['childrenCount'] as int? ?? 0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isParent
                                  ? '${AppLocalizations.of(context).translate('managing_family')}: ${familyName ?? AppLocalizations.of(context).translate('unknown')}'
                                  : '${AppLocalizations.of(context).translate('member_of')} ${parentName != null ? "$parentName's" : "a"} ${AppLocalizations.of(context).translate('family').toLowerCase()}',
                              style: TextStyle(
                                color: Colors.green.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (familyName != null || parentName != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isParent) ...[
                                Text(
                                  '${AppLocalizations.of(context).translate('family_label')}: ${familyName ?? AppLocalizations.of(context).translate('unknown')}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                Text(
                                  '$childrenCount ${childrenCount == 1 ? AppLocalizations.of(context).translate('child_singular') : AppLocalizations.of(context).translate('children_plural')}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                              ] else ...[
                                if (parentName != null) ...[
                                  Text(
                                    '${AppLocalizations.of(context).translate('parent_label')}: $parentName',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                                if (familyName != null) ...[
                                  Text(
                                    '${AppLocalizations.of(context).translate('family_label')}: $familyName',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ] else ...[
              // User is not part of a family
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).translate('not_part_of_family'),
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isParent
                    ? AppLocalizations.of(context).translate('create_family_description')
                    : AppLocalizations.of(context).translate('join_family_description'),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _getFamilyDetails(String familyId) async {
    try {
      final familyService = getIt<FamilyService>();
      await familyService.initialize(); // Ensure service is initialized

      // First try to get family by the provided ID
      var family = familyService.getFamilyById(familyId);

      // If not found, try to get the current family (in case of ID mismatch)
      if (family == null) {
        family = familyService.currentFamily;
        print('🔄 Family ID mismatch - using current family: ${family?.id}');

        // Sync user's family ID with current family
        if (family != null) {
          final currentUser = AuthService.currentUser;
          if (currentUser != null && currentUser.familyId != family.id) {
            print(
              '🔧 Syncing user family ID: ${currentUser.familyId} → ${family.id}',
            );
            try {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.id)
                  .update({'familyId': family.id});

              print('✅ User family ID updated in database');
            } catch (e) {
              print('❌ Failed to sync family ID: $e');
            }
          }
        }
      }

      if (family == null) {
        print('❌ No family found for ID: $familyId');
        return null;
      }

      // Get parent information with fallback
      String parentName = 'Parent';
      try {
        final userService = UserService();
        final parentUser = await userService
            .getUser(family.parentId)
            .timeout(const Duration(seconds: 3));

        if (parentUser != null) {
          if (parentUser.displayName.isNotEmpty) {
            parentName = parentUser.displayName;
          } else if (parentUser.email.isNotEmpty) {
            parentName = parentUser.email.split('@').first;
          }
        }
      } catch (e) {
        // Use fallback name if user data can't be loaded
        print('Could not load parent user data: $e');
        parentName = 'Parent (${family.parentId.substring(0, 8)})';
      }

      return {
        'name': family.name,
        'parentName': parentName,
        'childrenCount': family.childrenIds.length,
      };
    } catch (e) {
      print('Error loading family details: $e');
      return null;
    }
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
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ThemeDemoScreen()));
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _formatMemberSinceDate(DateTime date) {
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _quickEarnPoints() {
    if (_currentIndex == 1 && _isSelectedDateInPast()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).translate('tasks_only_today'),
          ),
        ),
      );
      return;
    }
    // Debug print family ID and templates
    final currentUser = AuthService.currentUser;
    print(
      '👨‍👩‍👧‍👦 Opening Quick Task - Current user: ${currentUser?.id}, familyId: ${currentUser?.familyId}',
    );

    // Pre-load templates to debug
    _taskService.listQuickTaskTemplates().then((templates) {
      print('📋 Found ${templates.length} quick task templates:');
      for (final template in templates) {
        print(
          '  - "${template.title}" (points: ${template.pointValue}, category: ${template.category}, assignedTo: ${template.assignedToUserId})',
        );
      }
    });

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const QuickTaskScreen()));
  }

  /// Check if the "Add Task" button should be shown
  /// Show for: 1) Parent users (regardless of family status)
  ///          2) Child users who haven't joined a family
  /// Hide for: Child users who are already in a family
  bool _shouldShowAddTaskButton() {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return false;

    // Always show for parent users
    if (currentUser.accountType.name == 'parent') {
      return true;
    }

    // For child users, only show if they haven't joined a family
    if (currentUser.accountType.name == 'child') {
      return currentUser.familyId == null;
    }

    // Default to false for safety
    return false;
  }

  /// Child users linked to a family should not see the manage tasks button.
  bool _shouldShowManageTasksButton() {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) {
      return false;
    }

    if (currentUser.accountType.name == 'child' &&
        currentUser.familyId != null) {
      return false;
    }

    return true;
  }

  bool get _canManageRewards {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) {
      return false;
    }

    return currentUser.accountType.name == 'parent';
  }

  void _addNewTask() {
    if (_currentIndex == 1 && _isSelectedDateInPast()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).translate('tasks_only_today'),
          ),
        ),
      );
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AddTaskScreen()));
  }

  void _viewAllHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const TransactionHistoryScreen()),
    );
  }

  void _openRewardsManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const RewardsManagementScreen()),
    );
  }

  Future<void> _showSetGoalDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => SetGoalDialog(
        currentPoints: _currentPoints,
      ),
    );

    if (result == true && mounted) {
      // Check if goal is already completed
      await _checkGoalCompletion();
    }
  }

  Future<void> _deleteGoal(String goalId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Goal'),
        content: const Text('Are you sure you want to remove this goal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _goalService.deleteGoal(goalId);
        if (mounted) {
          // Force a rebuild by calling setState
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Goal removed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error removing goal: $e')),
          );
        }
      }
    }
  }

  Future<void> _checkGoalCompletion() async {
    try {
      final completed = await _goalService.checkAndCompleteGoal(_currentPoints);
      
      if (completed && mounted) {
        // Show celebration dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.celebration, color: Colors.amber, size: 32),
                const SizedBox(width: 12),
                Text(
                  'Goal Achieved!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🎉 Congratulations! 🎉',
                  style: TextStyle(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'You\'ve reached your goal! Keep up the great work!',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Awesome!'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error checking goal completion: $e');
    }
  }

  void _addRewardWish() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddEditRewardScreen()),
    );
  }

  void _showPendingRewardDialog(RewardItem reward) {
    final titleController = TextEditingController(text: reward.title);
    final descController = TextEditingController(text: reward.description);
    final pointsController = TextEditingController(text: reward.points.toString());
    final isParent = _canManageRewards;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                IconData(reward.iconCodePoint, fontFamily: 'MaterialIcons'),
                color: Color(reward.colorValue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isParent ? 'Review Reward Request' : 'Edit Reward Request',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (reward.createdBy != null && isParent) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Requested by child • ${_formatDate(reward.createdAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (!isParent) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You can edit your request while waiting for approval',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Reward Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pointsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Points Required',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            if (!isParent)
              ElevatedButton(
                onPressed: () async {
                  try {
                    final updatedReward = reward.copyWith(
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      points: int.tryParse(pointsController.text) ?? reward.points,
                      updatedAt: DateTime.now(),
                    );
                    
                    await _rewardService.editPendingReward(reward.id, updatedReward);
                    if (context.mounted) Navigator.pop(context);
                    _showSnackBar('Reward request updated!');
                    await _rewardService.reloadRewards();
                  } catch (e) {
                    _showSnackBar('Error updating reward: $e');
                  }
                },
                child: const Text('Save'),
              ),
            if (isParent) ...[
              TextButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Reject Request'),
                      content: const Text(
                        'Are you sure you want to reject this reward request? This cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Reject'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    try {
                      await _rewardService.rejectReward(reward.id);
                      if (context.mounted) Navigator.pop(context);
                      _showSnackBar('Reward request rejected');
                      await _rewardService.reloadRewards();
                    } catch (e) {
                      _showSnackBar('Error rejecting reward: $e');
                    }
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Reject'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    // Update reward details if edited
                    final updatedReward = reward.copyWith(
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      points: int.tryParse(pointsController.text) ?? reward.points,
                      updatedAt: DateTime.now(),
                    );
                    
                    // Save edits first if any changes were made
                    if (titleController.text.trim() != reward.title ||
                        descController.text.trim() != reward.description ||
                        (int.tryParse(pointsController.text) ?? reward.points) != reward.points) {
                      await _rewardService.editPendingReward(reward.id, updatedReward);
                    }
                    
                    // Then approve
                    await _rewardService.approveReward(reward.id);
                    if (context.mounted) Navigator.pop(context);
                    _showSnackBar('Reward approved and added to catalog!');
                    await _rewardService.reloadRewards();
                  } catch (e) {
                    _showSnackBar('Error approving reward: $e');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Approve'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  void _redeemReward(String rewardName, int pointCost) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Redeem $rewardName'),
        content: Text(
          'Are you sure you want to redeem this reward for $pointCost points?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await _taskService.recordRewardRedemption(
                  rewardName: rewardName,
                  pointCost: pointCost,
                );

                // Update local state immediately
                setState(() {
                  _currentPoints -= pointCost;
                });

                _showSnackBar(
                  '$rewardName redeemed successfully! -$pointCost points',
                );

                // Reload points to ensure accuracy with database
                _loadUserPoints();
              } catch (e) {
                _showSnackBar('Error redeeming reward: $e');
              }
            },
            child: Text(AppLocalizations.of(context).translate('redeem')),
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
        title: Text(AppLocalizations.of(context).translate('complete')),
        content: Text(
          '${AppLocalizations.of(context).translate('mark_as_completed')} "${task.title}" ${AppLocalizations.of(context).translate('as_completed')}\n\n${AppLocalizations.of(context).translate('you_will_earn')} ${task.pointValue} ${AppLocalizations.of(context).translate('points')}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getPriorityColor(task.priority),
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context).translate('complete')),
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
        title: Text(AppLocalizations.of(context).translate('undo_task_completion')),
        content: Text(
          '${AppLocalizations.of(context).translate('undo_completion_message')} "${task.title}"?\n\n${AppLocalizations.of(context).translate('you_will_lose')} ${task.pointValue} ${AppLocalizations.of(context).translate('points')}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context).translate('undo')),
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

        _showSnackBar(
          '${task.title} ${AppLocalizations.of(context).translate('completion_undone')} -${task.pointValue} ${AppLocalizations.of(context).translate('points')}',
        );

        // Reload points from database to ensure accuracy
        _loadUserPoints();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('${AppLocalizations.of(context).translate('error_undoing_task')}: $e');
      }
    }
  }

  void _openSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }

  void _openHelp() {
    _showSnackBar('Help & support feature coming soon!');
  }

  Future<List<TaskModel>> _getTodayRedemptions() async {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      return await _taskService.getRewardRedemptions(
        start: todayStart,
        end: todayEnd,
      );
    } catch (e) {
      return [];
    }
  }

  Widget _buildRedemptionHistoryCard(TaskModel redemption) {
    final rewardName = redemption.title.replaceFirst('Reward: ', '');
    final pointsCost =
        -redemption.pointValue; // Convert negative back to positive for display

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
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.errorContainer.withOpacity(0.3),
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
        content: Text(
          'Are you sure you want to undo the redemption of "$rewardName"?\n\nThis will refund $pointsCost points.',
        ),
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
        await _taskService.undoRewardRedemption(redemption.id);

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
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Perform logout
      await AuthService.signOut();

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        // Navigate to login screen and clear all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
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
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // Date selection and formatting methods
  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();
    final DateTime todayOnly = DateTime(now.year, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(todayOnly) ? todayOnly : _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      // Disallow selecting future dates by setting lastDate to today
      lastDate: todayOnly,
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
        // Ensure picked date is not in the future (extra safety)
        final pickedOnly = DateTime(picked.year, picked.month, picked.day);
        final todayOnlyLocal = DateTime.now();
        final todayDateOnly = DateTime(
          todayOnlyLocal.year,
          todayOnlyLocal.month,
          todayOnlyLocal.day,
        );
        if (pickedOnly.isAfter(todayDateOnly)) {
          // Shouldn't happen due to lastDate, but guard anyway
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot select a future date')),
          );
          _selectedDate = todayDateOnly;
        } else {
          _selectedDate = pickedOnly;
        }

        // Update stream to reflect new selected date
        _updateTasksStreamForSelectedDate();
      });
    }
  }

  bool _isToday() {
    final today = DateTime.now();
    return _selectedDate.year == today.year &&
        _selectedDate.month == today.month &&
        _selectedDate.day == today.day;
  }

  bool _isSelectedDateInPast() {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final selectedOnly = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    return selectedOnly.isBefore(todayOnly);
  }

  String _translateTaskStatus(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return AppLocalizations.of(context).translate('pending').toUpperCase();
      case TaskStatus.completed:
        return AppLocalizations.of(context).translate('completed').toUpperCase();
      default:
        return status.name.toUpperCase();
    }
  }

  String _getSelectedDateTitle() {
    if (_isToday()) {
      return AppLocalizations.of(context).translate('todays_tasks');
    } else {
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));
      final yesterday = today.subtract(const Duration(days: 1));

      if (_selectedDate.year == tomorrow.year &&
          _selectedDate.month == tomorrow.month &&
          _selectedDate.day == tomorrow.day) {
        return AppLocalizations.of(context).translate('tomorrows_tasks');
      } else if (_selectedDate.year == yesterday.year &&
          _selectedDate.month == yesterday.month &&
          _selectedDate.day == yesterday.day) {
        return AppLocalizations.of(context).translate('yesterdays_tasks');
      } else {
        return AppLocalizations.of(context).translate('tasks');
      }
    }
  }

  String _formatSelectedDateSubtitle() {
    final months = [
      AppLocalizations.of(context).translate('january'),
      AppLocalizations.of(context).translate('february'),
      AppLocalizations.of(context).translate('march'),
      AppLocalizations.of(context).translate('april'),
      AppLocalizations.of(context).translate('may'),
      AppLocalizations.of(context).translate('june'),
      AppLocalizations.of(context).translate('july'),
      AppLocalizations.of(context).translate('august'),
      AppLocalizations.of(context).translate('september'),
      AppLocalizations.of(context).translate('october'),
      AppLocalizations.of(context).translate('november'),
      AppLocalizations.of(context).translate('december'),
    ];

    return '${months[_selectedDate.month - 1]} ${_selectedDate.day}, ${_selectedDate.year}';
  }

  String _formatSelectedDate() {
    final months = [
      AppLocalizations.of(context).translate('jan'),
      AppLocalizations.of(context).translate('feb'),
      AppLocalizations.of(context).translate('mar'),
      AppLocalizations.of(context).translate('apr'),
      AppLocalizations.of(context).translate('may_short'),
      AppLocalizations.of(context).translate('jun'),
      AppLocalizations.of(context).translate('jul'),
      AppLocalizations.of(context).translate('aug'),
      AppLocalizations.of(context).translate('sep'),
      AppLocalizations.of(context).translate('oct'),
      AppLocalizations.of(context).translate('nov'),
      AppLocalizations.of(context).translate('dec'),
    ];

    return '${months[_selectedDate.month - 1]} ${_selectedDate.day}';
  }

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
      _updateTasksStreamForSelectedDate();
    });
  }

  void _nextDay() {
    final next = _selectedDate.add(const Duration(days: 1));
    final today = DateTime.now();
    final nextOnly = DateTime(next.year, next.month, next.day);
    final todayOnly = DateTime(today.year, today.month, today.day);

    if (nextOnly.isAfter(todayOnly)) {
      // Prevent navigating into the future
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('cannot_navigate_future'))),
      );
      return;
    }

    setState(() {
      _selectedDate = nextOnly;
      _updateTasksStreamForSelectedDate();
    });
  }

  String _getEmptyStateTitle(List<TaskModel> allTasks) {
    if (_isSelectedDateInPast()) {
      return 'No task was planned and completed yet!';
    }

    if (allTasks.isEmpty) {
      return 'No tasks yet';
    }

    if (_isToday()) {
      return AppLocalizations.of(context).translate('no_tasks_for_today');
    } else {
      return AppLocalizations.of(context).translate('no_tasks_scheduled');
    }
  }

  String _getEmptyStateMessage(List<TaskModel> allTasks) {
    if (_isSelectedDateInPast()) {
      return '';
    }

    if (allTasks.isEmpty) {
      return 'Create your first task to get started!';
    }

    if (_isToday()) {
      return 'All your tasks are scheduled for other days or already completed! 🎉';
    } else {
      return 'No tasks scheduled for this future date yet.';
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
      MaterialPageRoute(builder: (context) => const TaskManagementScreen()),
    );
  }

  void _openFamilyDashboard() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const FamilyDashboardScreen()),
    );
  }

  void _openJoinFamily() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const JoinFamilyScreen()))
        .then((success) {
          if (success == true) {
            // Refresh the app state after successfully joining a family
            setState(() {});
          }
        });
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
    final targetDateOnly = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );

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
        if (daysDiff < 0) {
          return false;
        }

        if (pattern.daysOfWeek.isNotEmpty) {
          if (!pattern.daysOfWeek.contains(targetDateOnly.weekday)) {
            return false;
          }
          final weeksDiff = daysDiff ~/ 7;
          return weeksDiff % pattern.interval == 0;
        }

        return daysDiff % (7 * pattern.interval) == 0;

      case RecurrenceType.monthly:
        // Check if it's the same day of month with the right interval
        final monthsDiff =
            (targetDateOnly.year - patternStartDate.year) * 12 +
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
        title: Text(AppLocalizations.of(context).translate('task_history')),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: StreamBuilder<List<TaskModel>>(
        stream: widget.taskService.getRecentHistoryForCurrentUser(days: 5),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
                    AppLocalizations.of(context).translate('error_loading_history'),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: theme.textTheme.bodySmall,
                  ),
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
                  Icon(
                    Icons.history,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No completed tasks yet',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete some tasks to see your history!',
                    style: theme.textTheme.bodyMedium,
                  ),
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
                ...historyData
                    .map((dayData) => _buildDaySection(dayData, theme))
                    ,
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
        return (task.status == TaskStatus.completed ||
                task.status == TaskStatus.approved) &&
            task.completedAt != null &&
            task.completedAt!.isAfter(dayStart) &&
            task.completedAt!.isBefore(dayEnd);
      }).toList();

      if (completedTasks.isNotEmpty || i == 0) {
        // Always show today even if empty
        final totalPoints = completedTasks.fold<int>(
          0,
          (sum, task) => sum + task.pointValue,
        );
        historyData.add(
          DayHistoryData(
            date: dayStart,
            tasks: completedTasks,
            totalTasks: completedTasks.length,
            totalPoints: totalPoints,
          ),
        );
      }
    }

    return historyData;
  }

  Widget _buildOverallSummary(
    List<DayHistoryData> historyData,
    ThemeData theme,
  ) {
    final totalTasks = historyData.fold<int>(
      0,
      (sum, day) => sum + day.totalTasks,
    );
    final totalPoints = historyData.fold<int>(
      0,
      (sum, day) => sum + day.totalPoints,
    );
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
                Text(
                  '5-Day Summary',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Tasks',
                    totalTasks.toString(),
                    Icons.task_alt,
                    Colors.blue,
                    theme,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Total Points',
                    totalPoints.toString(),
                    Icons.stars,
                    Colors.orange,
                    theme,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Active Days',
                    activeDays.toString(),
                    Icons.calendar_today,
                    Colors.green,
                    theme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String title,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
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
                      Text(
                        _formatDayTitle(dayData.date),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatFullDate(dayData.date),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.task_alt,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${dayData.totalTasks}',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        '${dayData.totalPoints}',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (dayData.tasks.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Text(
                    'No tasks completed',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else ...[
              const SizedBox(height: 12),
              ...dayData.tasks
                  .map((task) => _buildHistoryTaskItem(task, theme))
                  ,
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
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
                        AppLocalizations.of(context).translateTaskTitle(task.title),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isRedemption ? Colors.red : null,
                        ),
                      ),
                    ),
                    if (isRecurring && !isRedemption)
                      Icon(
                        Icons.repeat,
                        size: 16,
                        color: theme.colorScheme.secondary,
                      ),
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
              ),
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
    } else if (targetDate.isAtSameMomentAs(
      today.subtract(const Duration(days: 1)),
    )) {
      return 'Yesterday';
    } else {
      final weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      return weekdays[date.weekday - 1];
    }
  }

  String _formatFullDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
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
