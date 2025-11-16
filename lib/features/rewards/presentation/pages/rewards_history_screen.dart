import 'package:flutter/material.dart';

/// Screen for viewing and filtering rewards history
class RewardsHistoryScreen extends StatefulWidget {
  const RewardsHistoryScreen({super.key});

  @override
  State<RewardsHistoryScreen> createState() => _RewardsHistoryScreenState();
}

class _RewardsHistoryScreenState extends State<RewardsHistoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedTimeframe = 'All Time';
  String _sortBy = 'Date';
  bool _sortAscending = false;
  
  // Filter options
  static const List<String> _categories = [
    'All',
    'Personal Growth',
    'Health & Fitness',
    'Work & Career',
    'Relationships',
    'Learning',
    'Creativity',
    'Finance',
    'Hobbies',
    'Travel',
    'Other',
  ];
  
  static const List<String> _timeframes = [
    'All Time',
    'Today',
    'This Week',
    'This Month',
    'Last 30 Days',
    'This Year',
  ];
  
  static const List<String> _sortOptions = [
    'Date',
    'Points',
    'Title',
    'Category',
  ];

  // Mock data for demonstration
  List<Map<String, dynamic>> _allRewards = [];
  List<Map<String, dynamic>> _filteredRewards = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _generateMockData();
    _applyFilters();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _generateMockData() {
    final now = DateTime.now();
    _allRewards = [
      {
        'id': '1',
        'title': 'Morning Workout Completed',
        'description': 'Finished 30-minute cardio session',
        'points': 100,
        'category': 'Health & Fitness',
        'iconCodePoint': Icons.fitness_center.codePoint,
        'colorValue': Colors.green.value,
        'completedAt': now.subtract(const Duration(hours: 2)).toIso8601String(),
        'status': 'completed',
      },
      {
        'id': '2',
        'title': 'Read Chapter of Book',
        'description': 'Completed chapter 5 of "The Psychology of Achievement"',
        'points': 75,
        'category': 'Learning',
        'iconCodePoint': Icons.school.codePoint,
        'colorValue': Colors.blue.value,
        'completedAt': now.subtract(const Duration(days: 1)).toIso8601String(),
        'status': 'completed',
      },
      {
        'id': '3',
        'title': 'Team Meeting Presentation',
        'description': 'Delivered quarterly results presentation',
        'points': 150,
        'category': 'Work & Career',
        'iconCodePoint': Icons.work.codePoint,
        'colorValue': Colors.purple.value,
        'completedAt': now.subtract(const Duration(days: 2)).toIso8601String(),
        'status': 'completed',
      },
      {
        'id': '4',
        'title': 'Meditation Session',
        'description': '15-minute mindfulness meditation',
        'points': 50,
        'category': 'Personal Growth',
        'iconCodePoint': Icons.self_improvement.codePoint,
        'colorValue': Colors.orange.value,
        'completedAt': now.subtract(const Duration(days: 3)).toIso8601String(),
        'status': 'completed',
      },
      {
        'id': '5',
        'title': 'Cook Healthy Meal',
        'description': 'Prepared homemade salmon with vegetables',
        'points': 80,
        'category': 'Health & Fitness',
        'iconCodePoint': Icons.restaurant.codePoint,
        'colorValue': Colors.teal.value,
        'completedAt': now.subtract(const Duration(days: 5)).toIso8601String(),
        'status': 'completed',
      },
      {
        'id': '6',
        'title': 'Complete Project Milestone',
        'description': 'Finished Phase 1 of mobile app development',
        'points': 200,
        'category': 'Work & Career',
        'iconCodePoint': Icons.lightbulb.codePoint,
        'colorValue': Colors.amber.value,
        'completedAt': now.subtract(const Duration(days: 7)).toIso8601String(),
        'status': 'completed',
      },
      {
        'id': '7',
        'title': 'Call Family Member',
        'description': 'Had 30-minute conversation with mom',
        'points': 60,
        'category': 'Relationships',
        'iconCodePoint': Icons.favorite.codePoint,
        'colorValue': Colors.pink.value,
        'completedAt': now.subtract(const Duration(days: 10)).toIso8601String(),
        'status': 'completed',
      },
      {
        'id': '8',
        'title': 'Save Money Goal',
        'description': 'Added \$100 to emergency fund',
        'points': 120,
        'category': 'Finance',
        'iconCodePoint': Icons.attach_money.codePoint,
        'colorValue': Colors.green.value,
        'completedAt': now.subtract(const Duration(days: 14)).toIso8601String(),
        'status': 'completed',
      },
    ];
  }

  void _applyFilters() {
    setState(() {
      _filteredRewards = _allRewards.where((reward) {
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final searchLower = _searchQuery.toLowerCase();
          if (!reward['title'].toLowerCase().contains(searchLower) &&
              !reward['description'].toLowerCase().contains(searchLower)) {
            return false;
          }
        }

        // Category filter
        if (_selectedCategory != 'All' && reward['category'] != _selectedCategory) {
          return false;
        }

        // Timeframe filter
        if (_selectedTimeframe != 'All Time') {
          final completedAt = DateTime.parse(reward['completedAt']);
          final now = DateTime.now();
          
          switch (_selectedTimeframe) {
            case 'Today':
              if (!_isSameDay(completedAt, now)) return false;
              break;
            case 'This Week':
              final weekStart = now.subtract(Duration(days: now.weekday - 1));
              if (completedAt.isBefore(weekStart)) return false;
              break;
            case 'This Month':
              if (completedAt.month != now.month || completedAt.year != now.year) {
                return false;
              }
              break;
            case 'Last 30 Days':
              final thirtyDaysAgo = now.subtract(const Duration(days: 30));
              if (completedAt.isBefore(thirtyDaysAgo)) return false;
              break;
            case 'This Year':
              if (completedAt.year != now.year) return false;
              break;
          }
        }

        return true;
      }).toList();

      // Apply sorting
      _filteredRewards.sort((a, b) {
        int comparison = 0;
        
        switch (_sortBy) {
          case 'Date':
            comparison = DateTime.parse(a['completedAt'])
                .compareTo(DateTime.parse(b['completedAt']));
            break;
          case 'Points':
            comparison = a['points'].compareTo(b['points']);
            break;
          case 'Title':
            comparison = a['title'].compareTo(b['title']);
            break;
          case 'Category':
            comparison = a['category'].compareTo(b['category']);
            break;
        }
        
        return _sortAscending ? comparison : -comparison;
      });
    });
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _showExportDialog();
                  break;
                case 'stats':
                  _showStatsDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export History'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'stats',
                child: ListTile(
                  leading: Icon(Icons.analytics),
                  title: Text('View Statistics'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.list)),
            Tab(text: 'Recent', icon: Icon(Icons.schedule)),
            Tab(text: 'Top Rewards', icon: Icon(Icons.star)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndQuickFilters(),
          _buildSummaryCards(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllRewardsTab(),
                _buildRecentRewardsTab(),
                _buildTopRewardsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndQuickFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search rewards...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                        _applyFilters();
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _applyFilters();
            },
          ),
          const SizedBox(height: 12),
          
          // Quick filters
          Row(
            children: [
              Expanded(
                child: _buildQuickFilter(
                  'Category',
                  _selectedCategory,
                  _categories,
                  (value) => setState(() {
                    _selectedCategory = value;
                    _applyFilters();
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickFilter(
                  'Time',
                  _selectedTimeframe,
                  _timeframes,
                  (value) => setState(() {
                    _selectedTimeframe = value;
                    _applyFilters();
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilter(
    String label,
    String value,
    List<String> options,
    Function(String) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(label),
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(
                option,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalRewards = _filteredRewards.length;
    final totalPoints = _filteredRewards.fold<int>(
      0,
      (sum, reward) => sum + (reward['points'] as int),
    );
    final avgPoints = totalRewards > 0 ? (totalPoints / totalRewards).round() : 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Total Rewards',
              totalRewards.toString(),
              Icons.emoji_events,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              'Total Points',
              totalPoints.toString(),
              Icons.stars,
              Colors.amber,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              'Avg Points',
              avgPoints.toString(),
              Icons.trending_up,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
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
        ),
      ),
    );
  }

  Widget _buildAllRewardsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredRewards.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredRewards.length,
        itemBuilder: (context, index) {
          final reward = _filteredRewards[index];
          return _buildRewardCard(reward);
        },
      ),
    );
  }

  Widget _buildRecentRewardsTab() {
    final recentRewards = _filteredRewards.where((reward) {
      final completedAt = DateTime.parse(reward['completedAt']);
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      return completedAt.isAfter(sevenDaysAgo);
    }).toList();

    if (recentRewards.isEmpty) {
      return _buildEmptyState(message: 'No rewards completed in the last 7 days');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recentRewards.length,
      itemBuilder: (context, index) {
        final reward = recentRewards[index];
        return _buildRewardCard(reward);
      },
    );
  }

  Widget _buildTopRewardsTab() {
    final topRewards = List<Map<String, dynamic>>.from(_filteredRewards)
      ..sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));

    if (topRewards.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: topRewards.length,
      itemBuilder: (context, index) {
        final reward = topRewards[index];
        return _buildRewardCard(reward, showRank: true, rank: index + 1);
      },
    );
  }

  Widget _buildRewardCard(
    Map<String, dynamic> reward, {
    bool showRank = false,
    int? rank,
  }) {
    final completedAt = DateTime.parse(reward['completedAt']);
    final icon = IconData(
      reward['iconCodePoint'],
      fontFamily: 'MaterialIcons',
    );
    final color = Color(reward['colorValue']);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),
            if (showRank && rank != null)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '#$rank',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(reward['title']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reward['description'].isNotEmpty)
              Text(
                reward['description'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.category, size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  reward['category'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(completedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
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
        onTap: () => _showRewardDetails(reward),
      ),
    );
  }

  Widget _buildEmptyState({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message ?? 'No rewards found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or complete some rewards!',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    // In real app, would fetch fresh data here
    _generateMockData();
    _applyFilters();
    
    setState(() => _isLoading = false);
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter & Sort'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _sortBy,
              decoration: const InputDecoration(labelText: 'Sort by'),
              items: _sortOptions.map((option) {
                return DropdownMenuItem(value: option, child: Text(option));
              }).toList(),
              onChanged: (value) {
                setState(() => _sortBy = value!);
              },
            ),
            CheckboxListTile(
              title: const Text('Ascending order'),
              value: _sortAscending,
              onChanged: (value) {
                setState(() => _sortAscending = value!);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _applyFilters();
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export History'),
        content: const Text('Choose export format:'),
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

  void _showStatsDialog() {
    final totalRewards = _filteredRewards.length;
    final totalPoints = _filteredRewards.fold<int>(
      0,
      (sum, reward) => sum + (reward['points'] as int),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Rewards: $totalRewards'),
            Text('Total Points: $totalPoints'),
            Text('Average Points: ${totalRewards > 0 ? (totalPoints / totalRewards).round() : 0}'),
            // Add more statistics here
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRewardDetails(Map<String, dynamic> reward) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(reward['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reward['description']),
            const SizedBox(height: 8),
            Text('Points: ${reward['points']}'),
            Text('Category: ${reward['category']}'),
            Text('Completed: ${_formatDate(DateTime.parse(reward['completedAt']))}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}