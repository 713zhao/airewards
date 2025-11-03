import 'package:flutter/material.dart';
import '../../../dashboard/presentation/pages/dashboard_screen.dart';
import '../../../rewards/presentation/pages/rewards_dashboard_screen.dart';
import '../../../redemption/presentation/pages/redemption_screen.dart';
import '../../../profile/presentation/pages/profile_screen.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/rewards_app_bar.dart';

/// Main app shell with bottom navigation and screen management
class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late PageController _pageController;
  
  int _currentIndex = 0;
  bool _isKeyboardVisible = false;
  
  // Navigation items configuration
  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Dashboard',
      route: '/dashboard',
    ),
    NavigationItem(
      icon: Icons.stars_outlined,
      selectedIcon: Icons.stars,
      label: 'Rewards',
      route: '/rewards',
    ),
    NavigationItem(
      icon: Icons.redeem_outlined,
      selectedIcon: Icons.redeem,
      label: 'Redeem',
      route: '/redeem',
    ),
    NavigationItem(
      icon: Icons.history_outlined,
      selectedIcon: Icons.history,
      label: 'History',
      route: '/history',
    ),
    NavigationItem(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Profile',
      route: '/profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _navigationItems.length - 1);
    
    _tabController = TabController(
      length: _navigationItems.length,
      initialIndex: _currentIndex,
      vsync: this,
    );
    
    _pageController = PageController(initialPage: _currentIndex);
    
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    setState(() {
      _isKeyboardVisible = bottomInset > 0;
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _onDestinationSelected(_tabController.index);
    }
  }

  void _onDestinationSelected(int index) {
    if (index == _currentIndex) {
      // If tapping the same tab, scroll to top or refresh
      _onSameTabTapped(index);
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    // Update controllers
    _tabController.animateTo(index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    // Analytics tracking
    _trackScreenView(index);
  }

  void _onSameTabTapped(int index) {
    // Handle same tab tapped (scroll to top, refresh, etc.)
    switch (index) {
      case 0: // Dashboard
        // TODO: Refresh dashboard data
        break;
      case 1: // Rewards
        // TODO: Scroll rewards list to top
        break;
      case 2: // Redeem
        // TODO: Refresh redemption options
        break;
      case 3: // History
        // TODO: Scroll history to top
        break;
      case 4: // Profile
        // TODO: Refresh profile data
        break;
    }
  }

  void _trackScreenView(int index) {
    final screenName = _navigationItems[index].label.toLowerCase();
    // TODO: Add analytics tracking
    debugPrint('Screen view: $screenName');
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _pageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      
      // Custom App Bar
      appBar: RewardsAppBar(
        currentIndex: _currentIndex,
        navigationItems: _navigationItems,
        onNotificationTapped: _onNotificationTapped,
        onSearchTapped: _onSearchTapped,
      ),
      
      // Main Content
      body: Column(
        children: [
          // Page Content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                if (index != _currentIndex) {
                  setState(() {
                    _currentIndex = index;
                  });
                  _tabController.animateTo(index);
                  _trackScreenView(index);
                }
              },
              children: _buildPages(),
            ),
          ),
        ],
      ),
      
      // Bottom Navigation
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 200),
        offset: _isKeyboardVisible ? const Offset(0, 1) : Offset.zero,
        child: CustomBottomNavigation(
          currentIndex: _currentIndex,
          items: _navigationItems,
          onDestinationSelected: _onDestinationSelected,
        ),
      ),
      
      // Floating Action Button (for quick add reward)
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  List<Widget> _buildPages() {
    return [
      // Dashboard
      const DashboardScreen(),
      
      // Rewards Dashboard
      const RewardsDashboardScreen(),
      
      // Redemption
      const RedemptionScreen(),
      
      // History (Combined)
      const HistoryScreen(),
      
      // Profile
      const ProfileScreen(),
    ];
  }

  Widget? _buildFloatingActionButton() {
    // Show FAB only on rewards and dashboard screens
    if (_currentIndex == 0 || _currentIndex == 1) {
      return FloatingActionButton(
        onPressed: _onAddRewardTapped,
        tooltip: 'Add Reward',
        child: const Icon(Icons.add),
      );
    }
    return null;
  }

  void _onAddRewardTapped() {
    // Navigate to add reward screen
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddRewardBottomSheet(),
    );
  }

  void _onNotificationTapped() {
    // Navigate to notifications screen
    Navigator.of(context).pushNamed('/notifications');
  }

  void _onSearchTapped() {
    // Show search delegate or navigate to search screen
    showSearch(
      context: context,
      delegate: RewardsSearchDelegate(),
    );
  }
}

/// Navigation item configuration
class NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;
  final Color? color;
  final Widget? badge;

  const NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
    this.color,
    this.badge,
  });
}

/// Temporary placeholder screens that will be replaced with actual implementations
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64),
          SizedBox(height: 16),
          Text(
            'History Screen',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Combined rewards and redemption history'),
        ],
      ),
    );
  }
}

/// Quick add reward bottom sheet
class AddRewardBottomSheet extends StatelessWidget {
  const AddRewardBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle, size: 64),
            SizedBox(height: 16),
            Text(
              'Add Reward',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Quick add reward bottom sheet'),
          ],
        ),
      ),
    );
  }
}

/// Search delegate for rewards
class RewardsSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = '';
        },
        icon: const Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, '');
      },
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return const Center(
      child: Text('Search Results'),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(
      child: Text('Search Suggestions'),
    );
  }
}