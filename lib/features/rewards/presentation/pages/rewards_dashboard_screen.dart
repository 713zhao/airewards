import 'package:flutter/material.dart';
import 'add_edit_reward_screen.dart';
import 'rewards_history_screen.dart';
import 'rewards_management_screen.dart';
import '../../../analytics/presentation/pages/analytics_dashboard_screen.dart';

/// Main rewards dashboard screen
class RewardsDashboardScreen extends StatefulWidget {
  const RewardsDashboardScreen({super.key});

  @override
  State<RewardsDashboardScreen> createState() => _RewardsDashboardScreenState();
}

class _RewardsDashboardScreenState extends State<RewardsDashboardScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _activeRewards = [];
  List<Map<String, dynamic>> _suggestedRewards = [];
  Map<String, dynamic>? _dailyGoal;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Simulate API calls
    await Future.delayed(const Duration(milliseconds: 800));
    
    _generateMockData();
    
    setState(() => _isLoading = false);
  }

  void _generateMockData() {
    // Active rewards (pending completion)
    _activeRewards = [
      {
        'id': '1',
        'title': 'Complete Daily Workout',
        'description': 'Finish 30-minute exercise routine',
        'points': 100,
        'category': 'Health & Fitness',
        'iconCodePoint': Icons.fitness_center.codePoint,
        'colorValue': Colors.green.value,
        'progress': 0.7, // 70% complete
        'dueDate': DateTime.now().add(const Duration(hours: 3)).toIso8601String(),
      },
      {
        'id': '2',
        'title': 'Read for 20 Minutes',
        'description': 'Continue reading current book',
        'points': 50,
        'category': 'Learning',
        'iconCodePoint': Icons.book.codePoint,
        'colorValue': Colors.blue.value,
        'progress': 0.3,
        'dueDate': DateTime.now().add(const Duration(hours: 6)).toIso8601String(),
      },
      {
        'id': '3',
        'title': 'Practice Gratitude',
        'description': 'Write 3 things you\'re grateful for',
        'points': 30,
        'category': 'Personal Growth',
        'iconCodePoint': Icons.favorite.codePoint,
        'colorValue': Colors.pink.value,
        'progress': 0.0,
        'dueDate': DateTime.now().add(const Duration(hours: 12)).toIso8601String(),
      },
    ];

    // Suggested rewards
    _suggestedRewards = [
      {
        'id': '4',
        'title': 'Organize Workspace',
        'description': 'Clean and organize your desk area',
        'points': 75,
        'category': 'Personal Growth',
        'iconCodePoint': Icons.cleaning_services.codePoint,
        'colorValue': Colors.orange.value,
      },
      {
        'id': '5',
        'title': 'Call a Friend',
        'description': 'Reach out to someone you haven\'t talked to recently',
        'points': 60,
        'category': 'Relationships',
        'iconCodePoint': Icons.phone.codePoint,
        'colorValue': Colors.purple.value,
      },
      {
        'id': '6',
        'title': 'Learn Something New',
        'description': 'Watch an educational video or tutorial',
        'points': 80,
        'category': 'Learning',
        'iconCodePoint': Icons.play_circle.codePoint,
        'colorValue': Colors.indigo.value,
      },
    ];

    // Daily goal
    _dailyGoal = {
      'targetPoints': 300,
      'currentPoints': 180,
      'rewardsCompleted': 3,
      'targetRewards': 5,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(),
              const SizedBox(height: 24),
              _buildDailyGoalCard(),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildActiveRewardsSection(),
              const SizedBox(height: 24),
              _buildSuggestedRewardsSection(),
              const SizedBox(height: 24),
              _buildStatsOverview(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewReward,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning!';
    } else if (hour < 17) {
      greeting = 'Good Afternoon!';
    } else {
      greeting = 'Good Evening!';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ready to earn some rewards today?',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyGoalCard() {
    if (_dailyGoal == null) return const SizedBox();

    final pointsProgress = _dailyGoal!['currentPoints'] / _dailyGoal!['targetPoints'];
    final rewardsProgress = _dailyGoal!['rewardsCompleted'] / _dailyGoal!['targetRewards'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.track_changes, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Today\'s Goal',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(pointsProgress * 100).toInt()}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Points progress
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Points'),
                    Text('${_dailyGoal!['currentPoints']} / ${_dailyGoal!['targetPoints']}'),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: pointsProgress,
                  backgroundColor: Colors.grey.shade200,
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Rewards progress
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Rewards'),
                    Text('${_dailyGoal!['rewardsCompleted']} / ${_dailyGoal!['targetRewards']}'),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: rewardsProgress,
                  backgroundColor: Colors.grey.shade200,
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Add Reward',
                Icons.add_circle,
                Colors.blue,
                _addNewReward,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionCard(
                'Manage',
                Icons.edit,
                Colors.purple,
                _manageRewards,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionCard(
                'History',
                Icons.history,
                Colors.green,
                _viewHistory,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionCard(
                'Analytics',
                Icons.analytics,
                Colors.orange,
                _viewAnalytics,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveRewardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Rewards',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: _viewHistory,
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_activeRewards.isEmpty)
          _buildEmptyActiveRewards()
        else
          Column(
            children: _activeRewards.map((reward) {
              return _buildActiveRewardCard(reward);
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildActiveRewardCard(Map<String, dynamic> reward) {
    final icon = IconData(
      reward['iconCodePoint'],
      fontFamily: 'MaterialIcons',
    );
    final color = Color(reward['colorValue']);
    final progress = reward['progress'] as double;
    final dueDate = DateTime.parse(reward['dueDate']);
    final timeLeft = dueDate.difference(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color,
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reward['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (reward['description'].isNotEmpty)
                        Text(
                          reward['description'],
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars, size: 16, color: Colors.amber.shade700),
                          const SizedBox(width: 4),
                          Text(
                            reward['points'].toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimeLeft(timeLeft),
                      style: TextStyle(
                        fontSize: 12,
                        color: timeLeft.inHours < 2 ? Colors.red : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade200,
                        color: color,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _completeReward(reward),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Complete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyActiveRewards() {
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
                'No active rewards',
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
                onPressed: _addNewReward,
                child: const Text('Add Reward'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedRewardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggested Rewards',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _suggestedRewards.length,
            itemBuilder: (context, index) {
              final reward = _suggestedRewards[index];
              return _buildSuggestedRewardCard(reward);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestedRewardCard(Map<String, dynamic> reward) {
    final icon = IconData(
      reward['iconCodePoint'],
      fontFamily: 'MaterialIcons',
    );
    final color = Color(reward['colorValue']);

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        child: InkWell(
          onTap: () => _addSuggestedReward(reward),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: color,
                      radius: 16,
                      child: Icon(icon, color: Colors.white, size: 16),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars, size: 12, color: Colors.amber.shade700),
                          const SizedBox(width: 2),
                          Text(
                            reward['points'].toString(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  reward['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  reward['description'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _addSuggestedReward(reward),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                    child: const Text(
                      'Add',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This Week\'s Overview',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard('Rewards\nCompleted', '12', Icons.check_circle, Colors.green),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard('Total\nPoints', '850', Icons.stars, Colors.amber),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard('Streak\nDays', '5', Icons.local_fire_department, Colors.orange),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard('Categories\nActive', '4', Icons.category, Colors.blue),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeLeft(Duration timeLeft) {
    if (timeLeft.inDays > 0) {
      return '${timeLeft.inDays}d left';
    } else if (timeLeft.inHours > 0) {
      return '${timeLeft.inHours}h left';
    } else if (timeLeft.inMinutes > 0) {
      return '${timeLeft.inMinutes}m left';
    } else {
      return 'Due now';
    }
  }

  Future<void> _addNewReward() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditRewardScreen(),
      ),
    );

    if (result != null) {
      // Reward was added, refresh data
      _loadData();
    }
  }

  Future<void> _completeReward(Map<String, dynamic> reward) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Reward'),
        content: Text('Mark "${reward['title']}" as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Remove from active rewards
      setState(() {
        _activeRewards.removeWhere((r) => r['id'] == reward['id']);
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Congratulations! You earned ${reward['points']} points!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _addSuggestedReward(Map<String, dynamic> reward) async {
    // Add to active rewards
    setState(() {
      final newReward = Map<String, dynamic>.from(reward);
      newReward['progress'] = 0.0;
      newReward['dueDate'] = DateTime.now().add(const Duration(days: 1)).toIso8601String();
      _activeRewards.add(newReward);
      _suggestedRewards.remove(reward);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${reward['title']}" to your active rewards!'),
      ),
    );
  }

  void _viewHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RewardsHistoryScreen(),
      ),
    );
  }

  void _viewAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AnalyticsDashboardScreen(),
      ),
    );
  }

  void _manageRewards() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RewardsManagementScreen(),
      ),
    );
  }
}