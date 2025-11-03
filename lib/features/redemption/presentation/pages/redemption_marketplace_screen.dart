import 'package:flutter/material.dart';

/// Reward redemption marketplace screen
class RedemptionMarketplaceScreen extends StatefulWidget {
  const RedemptionMarketplaceScreen({super.key});

  @override
  State<RedemptionMarketplaceScreen> createState() => _RedemptionMarketplaceScreenState();
}

class _RedemptionMarketplaceScreenState extends State<RedemptionMarketplaceScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String _selectedCategory = 'All';
  List<Map<String, dynamic>> _availableRedemptions = [];
  List<Map<String, dynamic>> _myRedemptions = [];
  int _userPoints = 2450;

  static const List<String> _categories = [
    'All',
    'Gift Cards',
    'Experiences',
    'Digital Rewards',
    'Physical Items',
    'Donations',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRedemptionData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRedemptionData() async {
    setState(() => _isLoading = true);
    
    // Simulate API calls
    await Future.delayed(const Duration(milliseconds: 800));
    
    _generateMockRedemptionData();
    
    setState(() => _isLoading = false);
  }

  void _generateMockRedemptionData() {
    _availableRedemptions = [
      {
        'id': '1',
        'title': 'Amazon Gift Card',
        'description': '\$10 Amazon Gift Card for online shopping',
        'points': 1000,
        'category': 'Gift Cards',
        'image': null,
        'availability': 'Available',
        'estimatedDelivery': '1-2 business days',
        'popularity': 95,
        'tags': ['Popular', 'Digital'],
      },
      {
        'id': '2',
        'title': 'Coffee Shop Voucher',
        'description': '\$5 voucher for your favorite local coffee shop',
        'points': 500,
        'category': 'Gift Cards',
        'image': null,
        'availability': 'Available',
        'estimatedDelivery': 'Instant',
        'popularity': 87,
        'tags': ['Local', 'Instant'],
      },
      {
        'id': '3',
        'title': 'Movie Theater Tickets',
        'description': 'Two tickets for any movie at participating theaters',
        'points': 1500,
        'category': 'Experiences',
        'image': null,
        'availability': 'Available',
        'estimatedDelivery': '2-3 business days',
        'popularity': 78,
        'tags': ['Entertainment', 'Couple'],
      },
      {
        'id': '4',
        'title': 'Spotify Premium (1 Month)',
        'description': 'One month of Spotify Premium subscription',
        'points': 800,
        'category': 'Digital Rewards',
        'image': null,
        'availability': 'Available',
        'estimatedDelivery': 'Instant',
        'popularity': 92,
        'tags': ['Music', 'Digital', 'Popular'],
      },
      {
        'id': '5',
        'title': 'Fitness Tracker',
        'description': 'Basic fitness tracker with step counting and heart rate',
        'points': 5000,
        'category': 'Physical Items',
        'image': null,
        'availability': 'Limited Stock',
        'estimatedDelivery': '5-7 business days',
        'popularity': 65,
        'tags': ['Health', 'Technology'],
      },
      {
        'id': '6',
        'title': 'Tree Planting Donation',
        'description': 'Plant 5 trees in your name through environmental partners',
        'points': 300,
        'category': 'Donations',
        'image': null,
        'availability': 'Available',
        'estimatedDelivery': 'Certificate in 1 week',
        'popularity': 72,
        'tags': ['Environment', 'Social Impact'],
      },
      {
        'id': '7',
        'title': 'Online Course Access',
        'description': 'Access to premium online courses for 3 months',
        'points': 2000,
        'category': 'Digital Rewards',
        'image': null,
        'availability': 'Available',
        'estimatedDelivery': 'Instant',
        'popularity': 81,
        'tags': ['Learning', 'Digital'],
      },
      {
        'id': '8',
        'title': 'Wireless Earbuds',
        'description': 'Quality wireless earbuds with noise cancellation',
        'points': 3500,
        'category': 'Physical Items',
        'image': null,
        'availability': 'Available',
        'estimatedDelivery': '3-5 business days',
        'popularity': 89,
        'tags': ['Technology', 'Audio'],
      },
    ];

    _myRedemptions = [
      {
        'id': 'r1',
        'redemptionId': '2',
        'title': 'Coffee Shop Voucher',
        'points': 500,
        'redeemedAt': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        'status': 'Delivered',
        'code': 'COFFEE-12345',
        'expiresAt': DateTime.now().add(const Duration(days: 27)).toIso8601String(),
      },
      {
        'id': 'r2',
        'redemptionId': '4',
        'title': 'Spotify Premium (1 Month)',
        'points': 800,
        'redeemedAt': DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
        'status': 'Active',
        'code': 'SPOTIFY-67890',
        'expiresAt': DateTime.now().add(const Duration(days: 23)).toIso8601String(),
      },
      {
        'id': 'r3',
        'redemptionId': '1',
        'title': 'Amazon Gift Card',
        'points': 1000,
        'redeemedAt': DateTime.now().subtract(const Duration(days: 14)).toIso8601String(),
        'status': 'Used',
        'code': 'AMAZON-ABCDE',
        'expiresAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reward Marketplace'),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars, size: 16, color: Colors.amber.shade700),
                const SizedBox(width: 4),
                Text(
                  '$_userPoints',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Marketplace', icon: Icon(Icons.store)),
            Tab(text: 'My Rewards', icon: Icon(Icons.redeem)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMarketplaceTab(),
                _buildMyRewardsTab(),
              ],
            ),
    );
  }

  Widget _buildMarketplaceTab() {
    final filteredRedemptions = _selectedCategory == 'All'
        ? _availableRedemptions
        : _availableRedemptions.where((r) => r['category'] == _selectedCategory).toList();

    return RefreshIndicator(
      onRefresh: _loadRedemptionData,
      child: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: filteredRedemptions.isEmpty
                ? _buildEmptyMarketplace()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredRedemptions.length,
                    itemBuilder: (context, index) {
                      final redemption = filteredRedemptions[index];
                      return _buildRedemptionCard(redemption);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRewardsTab() {
    return RefreshIndicator(
      onRefresh: _loadRedemptionData,
      child: _myRedemptions.isEmpty
          ? _buildEmptyMyRewards()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _myRedemptions.length,
              itemBuilder: (context, index) {
                final redemption = _myRedemptions[index];
                return _buildMyRedemptionCard(redemption);
              },
            ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Categories',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _showSortDialog,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sort, size: 16),
                    SizedBox(width: 4),
                    Text('Sort'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedemptionCard(Map<String, dynamic> redemption) {
    final canAfford = _userPoints >= redemption['points'];
    final isLimitedStock = redemption['availability'] == 'Limited Stock';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // Image placeholder
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: const Icon(
              Icons.image,
              size: 48,
              color: Colors.grey,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        redemption['title'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isLimitedStock)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Limited',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  redemption['description'],
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Tags
                if (redemption['tags'] != null && redemption['tags'].isNotEmpty)
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: (redemption['tags'] as List<String>).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      redemption['estimatedDelivery'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.thumb_up, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${redemption['popularity']}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.stars, size: 20, color: Colors.amber.shade700),
                            const SizedBox(width: 8),
                            Text(
                              '${redemption['points']} points',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: canAfford ? () => _redeemReward(redemption) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canAfford ? null : Colors.grey.shade300,
                      ),
                      child: Text(canAfford ? 'Redeem' : 'Insufficient Points'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRedemptionCard(Map<String, dynamic> redemption) {
    final status = redemption['status'] as String;
    final redeemedAt = DateTime.parse(redemption['redeemedAt']);
    final expiresAt = DateTime.parse(redemption['expiresAt']);
    final isExpired = expiresAt.isBefore(DateTime.now());

    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case 'Delivered':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Active':
        statusColor = Colors.blue;
        statusIcon = Icons.play_circle;
        break;
      case 'Used':
        statusColor = Colors.grey;
        statusIcon = Icons.check_circle_outline;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    redemption['title'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.stars, size: 16, color: Colors.amber.shade700),
                const SizedBox(width: 4),
                Text(
                  '${redemption['points']} points',
                  style: TextStyle(
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Redeemed ${_formatDate(redeemedAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            
            if (redemption['code'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Redemption Code',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            redemption['code'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _copyCode(redemption['code']),
                      icon: const Icon(Icons.copy, size: 20),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    isExpired
                        ? 'Expired ${_formatDate(expiresAt)}'
                        : 'Expires ${_formatDate(expiresAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isExpired ? Colors.red : Colors.grey.shade600,
                      fontWeight: isExpired ? FontWeight.bold : null,
                    ),
                  ),
                ),
                if (status == 'Active')
                  TextButton(
                    onPressed: () => _useReward(redemption),
                    child: const Text('Use Now'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMarketplace() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No rewards available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new rewards!',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMyRewards() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.redeem_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No redeemed rewards',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Redeem your first reward from the marketplace!',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _tabController.animateTo(0),
            child: const Text('Browse Marketplace'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'today';
    } else if (difference == 1) {
      return 'yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else if (difference > 0) {
      return '${date.day}/${date.month}/${date.year}';
    } else {
      // Future date
      final futureDays = date.difference(now).inDays;
      if (futureDays == 1) {
        return 'tomorrow';
      } else if (futureDays < 7) {
        return 'in $futureDays days';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    }
  }

  Future<void> _redeemReward(Map<String, dynamic> redemption) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Redemption'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Redeem "${redemption['title']}" for ${redemption['points']} points?'),
            const SizedBox(height: 8),
            Text(
              'Estimated delivery: ${redemption['estimatedDelivery']}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Simulate redemption process
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(seconds: 2));

      // Deduct points and add to my rewards
      setState(() {
        _userPoints -= redemption['points'] as int;
        _myRedemptions.insert(0, {
          'id': 'r${_myRedemptions.length + 1}',
          'redemptionId': redemption['id'],
          'title': redemption['title'],
          'points': redemption['points'],
          'redeemedAt': DateTime.now().toIso8601String(),
          'status': 'Delivered',
          'code': 'CODE-${DateTime.now().millisecondsSinceEpoch}',
          'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        });
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully redeemed "${redemption['title']}"!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Switch to My Rewards tab
        _tabController.animateTo(1);
      }
    }
  }

  void _copyCode(String code) {
    // In a real app, would use Clipboard.setData
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Code "$code" copied to clipboard')),
    );
  }

  void _useReward(Map<String, dynamic> redemption) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Use Reward'),
        content: Text('Mark "${redemption['title']}" as used?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                redemption['status'] = 'Used';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reward marked as used')),
              );
            },
            child: const Text('Mark Used'),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Points (Low to High)'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _availableRedemptions.sort((a, b) => a['points'].compareTo(b['points']));
                });
              },
            ),
            ListTile(
              title: const Text('Points (High to Low)'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _availableRedemptions.sort((a, b) => b['points'].compareTo(a['points']));
                });
              },
            ),
            ListTile(
              title: const Text('Popularity'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _availableRedemptions.sort((a, b) => b['popularity'].compareTo(a['popularity']));
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}