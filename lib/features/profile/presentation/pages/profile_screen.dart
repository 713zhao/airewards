import 'package:flutter/material.dart';

/// Main profile screen with user information and settings
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _userStats;
  List<Map<String, dynamic>> _recentAchievements = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    // Simulate API calls
    await Future.delayed(const Duration(milliseconds: 800));
    
    _generateMockData();
    
    setState(() => _isLoading = false);
  }

  void _generateMockData() {
    _userProfile = {
      'id': 'user_123',
      'name': 'Alex Johnson',
      'email': 'alex.johnson@example.com',
      'avatar': null, // No avatar image
      'memberSince': '2024-01-15',
      'totalPoints': 2450,
      'level': 12,
      'nextLevelPoints': 2800,
      'streak': 15,
      'title': 'Reward Champion',
      'bio': 'Passionate about personal growth and achieving goals!',
    };

    _userStats = {
      'totalRewards': 47,
      'completedThisWeek': 8,
      'completedThisMonth': 23,
      'averageDaily': 3.2,
      'favoriteCategory': 'Health & Fitness',
      'longestStreak': 28,
    };

    _recentAchievements = [
      {
        'id': '1',
        'title': 'Week Warrior',
        'description': 'Complete 7 rewards in one week',
        'iconCodePoint': Icons.military_tech.codePoint,
        'colorValue': Colors.amber.value,
        'unlockedAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        'id': '2',
        'title': 'Health Hero',
        'description': 'Complete 10 health & fitness rewards',
        'iconCodePoint': Icons.favorite.codePoint,
        'colorValue': Colors.red.value,
        'unlockedAt': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      },
      {
        'id': '3',
        'title': 'Learning Leader',
        'description': 'Complete 15 learning rewards',
        'iconCodePoint': Icons.school.codePoint,
        'colorValue': Colors.blue.value,
        'unlockedAt': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
      },
    ];
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
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 24),
              _buildStatsSection(),
              const SizedBox(height: 24),
              _buildLevelProgressCard(),
              const SizedBox(height: 24),
              _buildRecentAchievementsSection(),
              const SizedBox(height: 24),
              _buildQuickActionsGrid(),
              const SizedBox(height: 24),
              _buildSettingsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    if (_userProfile == null) return const SizedBox();

    final levelProgress = (_userProfile!['totalPoints'] - 
        (_userProfile!['level'] * 200)) / 200; // Simplified level calculation

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        _userProfile!['name'].substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          '${_userProfile!['level']}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userProfile!['name'],
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _userProfile!['title'],
                        style: TextStyle(
                          color: Colors.amber.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.stars,
                            size: 16,
                            color: Colors.amber.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_userProfile!['totalPoints']} points',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 16,
                            color: Colors.orange.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_userProfile!['streak']} day streak',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _editProfile,
                  icon: const Icon(Icons.edit),
                ),
              ],
            ),
            
            if (_userProfile!['bio'].isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _userProfile!['bio'],
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Level progress
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Level ${_userProfile!['level']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Level ${_userProfile!['level'] + 1}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: levelProgress,
                  backgroundColor: Colors.grey.shade200,
                  color: Colors.amber,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_userProfile!['nextLevelPoints'] - _userProfile!['totalPoints']} points to next level',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_userStats == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Statistics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: [
            _buildStatCard(
              'Total Rewards',
              '${_userStats!['totalRewards']}',
              Icons.emoji_events,
              Colors.amber,
            ),
            _buildStatCard(
              'This Week',
              '${_userStats!['completedThisWeek']}',
              Icons.calendar_view_week,
              Colors.blue,
            ),
            _buildStatCard(
              'This Month',
              '${_userStats!['completedThisMonth']}',
              Icons.calendar_month,
              Colors.green,
            ),
            _buildStatCard(
              'Daily Average',
              '${_userStats!['averageDaily']}',
              Icons.trending_up,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
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

  Widget _buildLevelProgressCard() {
    if (_userProfile == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.military_tech, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Text(
                  'Progression',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                      Text(
                        'Current Level: ${_userProfile!['level']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Total Points: ${_userProfile!['totalPoints']}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Best Streak',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: Colors.orange.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_userStats!['longestStreak']} days',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  Widget _buildRecentAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Achievements',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: _viewAllAchievements,
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recentAchievements.length,
            itemBuilder: (context, index) {
              final achievement = _recentAchievements[index];
              return _buildAchievementCard(achievement);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCard(Map<String, dynamic> achievement) {
    final icon = IconData(
      achievement['iconCodePoint'],
      fontFamily: 'MaterialIcons',
    );
    final color = Color(achievement['colorValue']);
    final unlockedAt = DateTime.parse(achievement['unlockedAt']);

    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: color,
                radius: 20,
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 4),
              Text(
                achievement['title'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _formatAchievementDate(unlockedAt),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: [
            _buildQuickActionCard(
              'Edit Profile',
              Icons.edit,
              Colors.blue,
              _editProfile,
            ),
            _buildQuickActionCard(
              'Achievements',
              Icons.emoji_events,
              Colors.amber,
              _viewAllAchievements,
            ),
            _buildQuickActionCard(
              'Export Data',
              Icons.download,
              Colors.green,
              _exportData,
            ),
            _buildQuickActionCard(
              'Share Profile',
              Icons.share,
              Colors.purple,
              _shareProfile,
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
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              _buildSettingsTile(
                'Notifications',
                'Manage notification preferences',
                Icons.notifications,
                _openNotificationSettings,
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                'Privacy',
                'Control your data and privacy',
                Icons.privacy_tip,
                _openPrivacySettings,
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                'Account',
                'Manage your account settings',
                Icons.account_circle,
                _openAccountSettings,
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                'About',
                'App information and support',
                Icons.info,
                _openAbout,
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                'Sign Out',
                'Sign out of your account',
                Icons.logout,
                _signOut,
                textColor: Colors.red,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  String _formatAchievementDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '${difference}d ago';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  void _editProfile() {
    // Navigate to edit profile screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit profile feature coming soon!')),
    );
  }

  void _viewAllAchievements() {
    // Navigate to achievements screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Achievements screen coming soon!')),
    );
  }

  void _exportData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Export your profile and activity data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data export started...')),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _shareProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share profile feature coming soon!')),
    );
  }

  void _openNotificationSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification settings coming soon!')),
    );
  }

  void _openPrivacySettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy settings coming soon!')),
    );
  }

  void _openAccountSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account settings coming soon!')),
    );
  }

  void _openAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'AI Rewards',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.stars, size: 48),
      children: const [
        Text('A gamified personal achievement tracking app.'),
      ],
    );
  }

  void _signOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle sign out
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Signed out successfully')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}