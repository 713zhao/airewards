import 'package:flutter/material.dart';
import '../pages/main_shell.dart';
import '../../../advertisements/presentation/widgets/ad_banner_widget.dart';

/// Custom app bar for the rewards app with integrated ads
class RewardsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int currentIndex;
  final List<NavigationItem> navigationItems;
  final VoidCallback? onNotificationTapped;
  final VoidCallback? onSearchTapped;
  final bool showAdBanner;

  const RewardsAppBar({
    super.key,
    required this.currentIndex,
    required this.navigationItems,
    this.onNotificationTapped,
    this.onSearchTapped,
    this.showAdBanner = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (showAdBanner ? 50 : 0),
      );

  String _getTitle() {
    if (currentIndex < navigationItems.length) {
      switch (currentIndex) {
        case 0:
          return 'AI Rewards';
        case 1:
          return 'My Rewards';
        case 2:
          return 'Redeem Points';
        case 3:
          return 'History';
        case 4:
          return 'Profile';
        default:
          return navigationItems[currentIndex].label;
      }
    }
    return 'AI Rewards';
  }

  List<Widget> _getActions(BuildContext context) {
    final theme = Theme.of(context);
    
    switch (currentIndex) {
      case 0: // Dashboard
        return [
          // Search button
          IconButton(
            onPressed: onSearchTapped,
            icon: const Icon(Icons.search),
            tooltip: 'Search rewards',
          ),
          // Notifications button
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: onNotificationTapped,
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Notifications',
              ),
              // Notification badge
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ];
        
      case 1: // Rewards
        return [
          // Filter button
          IconButton(
            onPressed: () => _showFilterSheet(context),
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter rewards',
          ),
          // Search button
          IconButton(
            onPressed: onSearchTapped,
            icon: const Icon(Icons.search),
            tooltip: 'Search rewards',
          ),
        ];
        
      case 2: // Redemption
        return [
          // Search button
          IconButton(
            onPressed: onSearchTapped,
            icon: const Icon(Icons.search),
            tooltip: 'Search rewards',
          ),
        ];
        
      case 3: // History
        return [
          // Export button
          IconButton(
            onPressed: () => _showExportOptions(context),
            icon: const Icon(Icons.download),
            tooltip: 'Export history',
          ),
          // Filter button
          IconButton(
            onPressed: () => _showFilterSheet(context),
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter history',
          ),
        ];
        
      case 4: // Profile
        return [
          // Settings button
          IconButton(
            onPressed: () => _navigateToSettings(context),
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),
        ];
        
      default:
        return [];
    }
  }

  Widget? _buildBottom() {
    if (!showAdBanner) return null;
    
    return const SizedBox(
      height: 50,
      child: AdBannerWidget(
        adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test banner ID
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppBar(
      title: Text(
        _getTitle(),
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: false,
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      actions: _getActions(context),
      bottom: showAdBanner
          ? PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: _buildBottom()!,
            )
          : null,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withOpacity(0.8),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const FilterBottomSheet(),
    );
  }

  void _showExportOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ExportOptionsDialog(),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.of(context).pushNamed('/settings');
  }
}

/// Filter bottom sheet for rewards and history
class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  DateTimeRange? _dateRange;
  Set<String> _selectedCategories = {};
  RangeValues _pointRange = const RangeValues(0, 1000);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Filter Options',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _dateRange = null;
                      _selectedCategories.clear();
                      _pointRange = const RangeValues(0, 1000);
                    });
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),
          
          // Filter Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Range
                  Text(
                    'Date Range',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: _dateRange,
                      );
                      if (picked != null) {
                        setState(() {
                          _dateRange = picked;
                        });
                      }
                    },
                    child: Text(
                      _dateRange == null
                          ? 'Select Date Range'
                          : '${_dateRange!.start.toString().split(' ')[0]} - ${_dateRange!.end.toString().split(' ')[0]}',
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Point Range
                  Text(
                    'Point Range',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RangeSlider(
                    values: _pointRange,
                    min: 0,
                    max: 1000,
                    divisions: 20,
                    labels: RangeLabels(
                      _pointRange.start.round().toString(),
                      _pointRange.end.round().toString(),
                    ),
                    onChanged: (values) {
                      setState(() {
                        _pointRange = values;
                      });
                    },
                  ),
                  
                  const Spacer(),
                ],
              ),
            ),
          ),
          
          // Apply Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // TODO: Apply filters
                },
                child: const Text('Apply Filters'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Export options dialog
class ExportOptionsDialog extends StatelessWidget {
  const ExportOptionsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export History'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text('Export as PDF'),
            subtitle: const Text('Complete history with charts'),
            onTap: () {
              Navigator.of(context).pop();
              // TODO: Export as PDF
            },
          ),
          ListTile(
            leading: const Icon(Icons.table_chart),
            title: const Text('Export as CSV'),
            subtitle: const Text('Raw data for analysis'),
            onTap: () {
              Navigator.of(context).pop();
              // TODO: Export as CSV
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}