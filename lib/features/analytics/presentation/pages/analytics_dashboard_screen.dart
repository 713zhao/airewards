import 'package:flutter/material.dart';

/// Analytics dashboard with comprehensive insights and goal tracking
class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String _selectedPeriod = 'This Month';
  
  // Analytics data
  Map<String, dynamic>? _overviewData;
  List<Map<String, dynamic>> _categoryBreakdown = [];
  List<Map<String, dynamic>> _weeklyProgress = [];
  List<Map<String, dynamic>> _streakHistory = [];
  List<Map<String, dynamic>> _goals = [];

  static const List<String> _periods = [
    'This Week',
    'This Month', 
    'Last 3 Months',
    'This Year',
    'All Time',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);
    
    // Simulate API calls
    await Future.delayed(const Duration(milliseconds: 1000));
    
    _generateMockAnalyticsData();
    
    setState(() => _isLoading = false);
  }

  void _generateMockAnalyticsData() {
    // Overview statistics
    _overviewData = {
      'totalRewards': 47,
      'totalPoints': 2450,
      'averagePerDay': 3.2,
      'currentStreak': 15,
      'longestStreak': 28,
      'completionRate': 0.78, // 78%
      'weeklyGrowth': 0.12, // 12% growth
      'monthlyGrowth': 0.23, // 23% growth
    };

    // Category breakdown
    _categoryBreakdown = [
      {
        'category': 'Health & Fitness',
        'count': 15,
        'points': 750,
        'percentage': 0.32,
        'color': Colors.green.value,
      },
      {
        'category': 'Learning',
        'count': 12,
        'points': 600,
        'percentage': 0.26,
        'color': Colors.blue.value,
      },
      {
        'category': 'Work & Career',
        'count': 8,
        'points': 520,
        'percentage': 0.17,
        'color': Colors.purple.value,
      },
      {
        'category': 'Personal Growth',
        'count': 7,
        'points': 350,
        'percentage': 0.15,
        'color': Colors.orange.value,
      },
      {
        'category': 'Other',
        'count': 5,
        'points': 230,
        'percentage': 0.10,
        'color': Colors.grey.value,
      },
    ];

    // Weekly progress (last 8 weeks)
    final now = DateTime.now();
    _weeklyProgress = List.generate(8, (index) {
      final weekStart = now.subtract(Duration(days: (7 - index) * 7));
      return {
        'week': 'Week ${index + 1}',
        'date': weekStart,
        'rewards': 3 + (index * 2) + (index % 3),
        'points': 150 + (index * 80) + (index % 4 * 20),
        'target': 300,
      };
    });

    // Streak history
    _streakHistory = [
      {'date': now.subtract(const Duration(days: 30)), 'streak': 5},
      {'date': now.subtract(const Duration(days: 25)), 'streak': 8},
      {'date': now.subtract(const Duration(days: 20)), 'streak': 12},
      {'date': now.subtract(const Duration(days: 15)), 'streak': 18},
      {'date': now.subtract(const Duration(days: 10)), 'streak': 22},
      {'date': now.subtract(const Duration(days: 5)), 'streak': 28},
      {'date': now, 'streak': 15}, // Current streak after a break
    ];

    // Goals
    _goals = [
      {
        'id': '1',
        'title': 'Daily Fitness Goal',
        'description': 'Complete 1 fitness reward daily',
        'target': 30,
        'current': 22,
        'period': 'Monthly',
        'category': 'Health & Fitness',
        'color': Colors.green.value,
        'icon': Icons.fitness_center.codePoint,
        'startDate': DateTime(now.year, now.month, 1).toIso8601String(),
        'endDate': DateTime(now.year, now.month + 1, 0).toIso8601String(),
      },
      {
        'id': '2',
        'title': 'Learning Streak',
        'description': 'Maintain 21-day learning streak',
        'target': 21,
        'current': 15,
        'period': 'Streak',
        'category': 'Learning',
        'color': Colors.blue.value,
        'icon': Icons.school.codePoint,
        'startDate': now.subtract(const Duration(days: 15)).toIso8601String(),
        'endDate': now.add(const Duration(days: 6)).toIso8601String(),
      },
      {
        'id': '3',
        'title': 'Weekly Points Target',
        'description': 'Earn 500 points per week',
        'target': 500,
        'current': 380,
        'period': 'Weekly',
        'category': 'Overall',
        'color': Colors.amber.value,
        'icon': Icons.stars.codePoint,
        'startDate': now.subtract(Duration(days: now.weekday - 1)).toIso8601String(),
        'endDate': now.add(Duration(days: 7 - now.weekday)).toIso8601String(),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Goals'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_today),
            initialValue: _selectedPeriod,
            onSelected: (period) {
              setState(() => _selectedPeriod = period);
              _loadAnalyticsData();
            },
            itemBuilder: (context) => _periods.map((period) {
              return PopupMenuItem(
                value: period,
                child: Text(period),
              );
            }).toList(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Progress', icon: Icon(Icons.trending_up)),
            Tab(text: 'Goals', icon: Icon(Icons.flag)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildProgressTab(),
                _buildGoalsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewGoal,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodHeader(),
            const SizedBox(height: 16),
            _buildOverviewStats(),
            const SizedBox(height: 24),
            _buildCategoryBreakdown(),
            const SizedBox(height: 24),
            _buildPerformanceInsights(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeeklyProgressChart(),
            const SizedBox(height: 24),
            _buildStreakAnalysis(),
            const SizedBox(height: 24),
            _buildTrendAnalysis(),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGoalsHeader(),
            const SizedBox(height: 16),
            _buildActiveGoals(),
            const SizedBox(height: 24),
            _buildGoalsSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analytics Period',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _selectedPeriod,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _exportAnalytics,
              icon: const Icon(Icons.download),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewStats() {
    if (_overviewData == null) return const SizedBox();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        _buildStatCard(
          'Total Rewards',
          '${_overviewData!['totalRewards']}',
          Icons.emoji_events,
          Colors.amber,
          growth: _overviewData!['weeklyGrowth'],
        ),
        _buildStatCard(
          'Total Points',
          '${_overviewData!['totalPoints']}',
          Icons.stars,
          Colors.blue,
          growth: _overviewData!['monthlyGrowth'],
        ),
        _buildStatCard(
          'Daily Average',
          '${_overviewData!['averagePerDay']}',
          Icons.trending_up,
          Colors.green,
        ),
        _buildStatCard(
          'Current Streak',
          '${_overviewData!['currentStreak']} days',
          Icons.local_fire_department,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    double? growth,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                if (growth != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: growth >= 0 ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          growth >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 12,
                          color: growth >= 0 ? Colors.green : Colors.red,
                        ),
                        Text(
                          '${(growth * 100).abs().toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: growth >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Category Breakdown',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: _viewDetailedBreakdown,
              child: const Text('Details'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Pie chart representation (simplified)
                SizedBox(
                  height: 120,
                  child: Row(
                    children: _categoryBreakdown.map((category) {
                      return Expanded(
                        flex: (category['percentage'] * 100).round(),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: Color(category['color']),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${category['count']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${(category['percentage'] * 100).round()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                // Legend
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _categoryBreakdown.map((category) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Color(category['color']),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          category['category'],
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceInsights() {
    if (_overviewData == null) return const SizedBox();

    final completionRate = _overviewData!['completionRate'] as double;
    final insights = _generateInsights();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Insights',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircularProgressIndicator(
                      value: completionRate,
                      backgroundColor: Colors.grey.shade200,
                      strokeWidth: 8,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Completion Rate',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${(completionRate * 100).round()}%',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...insights.map((insight) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        insight['icon'],
                        size: 16,
                        color: insight['color'],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          insight['text'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyProgressChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Progress',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Simple bar chart representation
                SizedBox(
                  height: 200,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _weeklyProgress.map((week) {
                      final progress = week['points'] / week['target'];
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            children: [
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // Target line
                                      Container(
                                        height: 2,
                                        color: Colors.red.shade300,
                                      ),
                                      // Progress bar
                                      Container(
                                        height: (150 * progress).toDouble(),
                                        decoration: BoxDecoration(
                                          color: progress >= 1.0 
                                              ? Colors.green 
                                              : Colors.blue,
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(4),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                week['week'].toString().replaceAll('Week ', 'W'),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(width: 12, height: 12, color: Colors.blue),
                        const SizedBox(width: 4),
                        const Text('Points Earned', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        Container(width: 12, height: 2, color: Colors.red.shade300),
                        const SizedBox(width: 4),
                        const Text('Target', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStreakAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Streak Analysis',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStreakStat(
                        'Current Streak',
                        '${_overviewData!['currentStreak']} days',
                        Icons.local_fire_department,
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildStreakStat(
                        'Best Streak',
                        '${_overviewData!['longestStreak']} days',
                        Icons.emoji_events,
                        Colors.amber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Streak history visualization
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _streakHistory.length,
                    itemBuilder: (context, index) {
                      final streak = _streakHistory[index];
                      return Container(
                        width: 40,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(
                                    (streak['streak'] / 30).clamp(0.3, 1.0),
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text(
                                    '${streak['streak']}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(streak['date'] as DateTime).day}/${(streak['date'] as DateTime).month}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStreakStat(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTrendAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trend Analysis',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTrendItem(
                  'Weekly Growth',
                  '+12%',
                  'You\'re improving week over week',
                  Icons.trending_up,
                  Colors.green,
                ),
                const Divider(),
                _buildTrendItem(
                  'Peak Performance',
                  'Weekends',
                  'You complete most rewards on weekends',
                  Icons.weekend,
                  Colors.blue,
                ),
                const Divider(),
                _buildTrendItem(
                  'Best Category',
                  'Health & Fitness',
                  'Your most consistent category',
                  Icons.fitness_center,
                  Colors.green,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendItem(
    String title,
    String value,
    String description,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      value,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Active Goals',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        OutlinedButton.icon(
          onPressed: _addNewGoal,
          icon: const Icon(Icons.add),
          label: const Text('New Goal'),
        ),
      ],
    );
  }

  Widget _buildActiveGoals() {
    return Column(
      children: _goals.map((goal) => _buildGoalCard(goal)).toList(),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    final progress = (goal['current'] as int) / (goal['target'] as int);
    final icon = IconData(goal['icon'], fontFamily: 'MaterialIcons');
    final color = Color(goal['color']);
    final endDate = DateTime.parse(goal['endDate']);
    final daysLeft = endDate.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                        goal['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        goal['description'],
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (action) => _handleGoalAction(action, goal),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit Goal'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete Goal'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${goal['current']} / ${goal['target']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
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
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(progress * 100).round()}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      daysLeft > 0 ? '$daysLeft days left' : 'Overdue',
                      style: TextStyle(
                        fontSize: 12,
                        color: daysLeft > 0 ? Colors.grey.shade600 : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsSummary() {
    final activeGoals = _goals.length;
    final completedGoals = _goals.where((g) => g['current'] >= g['target']).length;
    final averageProgress = _goals.fold<double>(
      0,
      (sum, goal) => sum + ((goal['current'] as int) / (goal['target'] as int)),
    ) / _goals.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Goals Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildGoalSummaryItem(
                    'Active Goals',
                    activeGoals.toString(),
                    Icons.flag,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildGoalSummaryItem(
                    'Completed',
                    completedGoals.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildGoalSummaryItem(
                    'Avg Progress',
                    '${(averageProgress * 100).round()}%',
                    Icons.trending_up,
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

  Widget _buildGoalSummaryItem(String title, String value, IconData icon, Color color) {
    return Column(
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
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _generateInsights() {
    return [
      {
        'icon': Icons.trending_up,
        'color': Colors.green,
        'text': 'You\'re 23% more active this month compared to last month',
      },
      {
        'icon': Icons.schedule,
        'color': Colors.blue,
        'text': 'Your most productive time is between 2-4 PM',
      },
      {
        'icon': Icons.emoji_events,
        'color': Colors.amber,
        'text': 'You\'re in the top 15% of users in your category',
      },
    ];
  }

  void _exportAnalytics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Analytics'),
        content: const Text('Choose export format for your analytics data:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting as PDF...')),
              );
            },
            child: const Text('PDF'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting as CSV...')),
              );
            },
            child: const Text('CSV'),
          ),
        ],
      ),
    );
  }

  void _viewDetailedBreakdown() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Detailed breakdown feature coming soon!')),
    );
  }

  void _addNewGoal() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add new goal feature coming soon!')),
    );
  }

  void _handleGoalAction(String action, Map<String, dynamic> goal) {
    switch (action) {
      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Editing ${goal['title']}...')),
        );
        break;
      case 'delete':
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Goal'),
            content: Text('Are you sure you want to delete "${goal['title']}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _goals.removeWhere((g) => g['id'] == goal['id']);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Goal deleted')),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        break;
    }
  }
}