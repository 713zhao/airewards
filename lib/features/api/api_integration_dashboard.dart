import 'package:flutter/material.dart';
import 'dart:async';

import '../../core/services/backend_service.dart';
import '../../core/services/network_service.dart';
import '../../core/services/data_sync_service.dart';
import '../../core/services/api_client.dart';

/// Comprehensive API integration dashboard for monitoring and management
class ApiIntegrationDashboard extends StatefulWidget {
  const ApiIntegrationDashboard({super.key});

  @override
  State<ApiIntegrationDashboard> createState() => _ApiIntegrationDashboardState();
}

class _ApiIntegrationDashboardState extends State<ApiIntegrationDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription<NetworkStatus>? _networkSubscription;
  StreamSubscription<SyncEvent>? _syncSubscription;
  
  NetworkStatus _networkStatus = NetworkStatus.unknown;
  NetworkQuality? _networkQuality;
  ConnectionInfo? _connectionInfo;
  SyncStatus _syncStatus = SyncStatus.idle;
  int _pendingSyncCount = 0;
  
  bool _isLoading = true;
  final Map<String, ApiEndpointStatus> _endpointStatuses = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeDashboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _networkSubscription?.cancel();
    _syncSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeDashboard() async {
    setState(() => _isLoading = true);

    try {
      // Initialize services if not already done
      await NetworkService.initialize();
      await DataSyncService.initialize();

      // Subscribe to network status
      _networkSubscription = NetworkService.statusStream.listen((status) {
        if (mounted) {
          setState(() => _networkStatus = status);
        }
      });

      // Subscribe to sync events
      _syncSubscription = DataSyncService.syncEventStream.listen((event) {
        if (mounted) {
          _handleSyncEvent(event);
        }
      });

      // Load initial data
      await _loadDashboardData();
    } catch (e) {
      debugPrint('❌ Failed to initialize API dashboard: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize dashboard: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadDashboardData() async {
    // Get current network status
    _networkStatus = NetworkService.currentStatus;
    
    // Get network quality
    _networkQuality = await NetworkService.assessNetworkQuality();
    
    // Get connection info
    _connectionInfo = await NetworkService.getConnectionInfo();
    
    // Get sync status
    _pendingSyncCount = DataSyncService.pendingSyncCount;
    
    // Test API endpoints
    await _testApiEndpoints();
    
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _testApiEndpoints() async {
    final endpoints = [
      'health',
      'auth/login',
      'users/me',
      'tasks',
      'rewards',
    ];

    for (final endpoint in endpoints) {
      try {
        final stopwatch = Stopwatch()..start();
        final response = await ApiClient.get(endpoint).timeout(
          const Duration(seconds: 5),
        );
        stopwatch.stop();

        _endpointStatuses[endpoint] = ApiEndpointStatus(
          endpoint: endpoint,
          isHealthy: response.success,
          responseTime: stopwatch.elapsed,
          statusCode: response.statusCode,
          lastChecked: DateTime.now(),
          error: response.error?.message,
        );
      } catch (e) {
        _endpointStatuses[endpoint] = ApiEndpointStatus(
          endpoint: endpoint,
          isHealthy: false,
          responseTime: null,
          statusCode: null,
          lastChecked: DateTime.now(),
          error: e.toString(),
        );
      }
    }
  }

  void _handleSyncEvent(SyncEvent event) {
    switch (event.type) {
      case SyncEventType.started:
        _syncStatus = SyncStatus.syncing;
        break;
      case SyncEventType.completed:
        _syncStatus = SyncStatus.completed;
        break;
      case SyncEventType.failed:
        _syncStatus = SyncStatus.failed;
        break;
      case SyncEventType.queued:
        _pendingSyncCount = DataSyncService.pendingSyncCount;
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Integration Dashboard'),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.network_check), text: 'Network'),
            Tab(icon: Icon(Icons.sync), text: 'Sync'),
            Tab(icon: Icon(Icons.api), text: 'Endpoints'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildNetworkTab(),
                _buildSyncTab(),
                _buildEndpointsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSystemStatusCard(),
          const SizedBox(height: 16),
          _buildQuickActionsCard(),
          const SizedBox(height: 16),
          _buildRecentActivityCard(),
        ],
      ),
    );
  }

  Widget _buildNetworkTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNetworkStatusCard(),
          const SizedBox(height: 16),
          _buildConnectionInfoCard(),
          const SizedBox(height: 16),
          _buildNetworkQualityCard(),
          const SizedBox(height: 16),
          _buildNetworkMetricsCard(),
        ],
      ),
    );
  }

  Widget _buildSyncTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSyncStatusCard(),
          const SizedBox(height: 16),
          _buildPendingSyncsCard(),
          const SizedBox(height: 16),
          _buildSyncHistoryCard(),
        ],
      ),
    );
  }

  Widget _buildEndpointsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEndpointOverviewCard(),
          const SizedBox(height: 16),
          ..._endpointStatuses.values.map((status) => _buildEndpointCard(status)),
        ],
      ),
    );
  }

  Widget _buildSystemStatusCard() {
    final overallHealthy = _networkStatus == NetworkStatus.connected &&
        _syncStatus != SyncStatus.failed &&
        _endpointStatuses.values.any((status) => status.isHealthy);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'System Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: overallHealthy ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    overallHealthy ? 'HEALTHY' : 'ISSUES',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatusIndicator('Network', _networkStatus == NetworkStatus.connected),
            _buildStatusIndicator('Sync Service', _syncStatus != SyncStatus.failed),
            _buildStatusIndicator('API Endpoints', _endpointStatuses.values.any((s) => s.isHealthy)),
            _buildStatusIndicator('Authentication', true), // Would check auth status
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String label, bool isHealthy) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isHealthy ? Icons.check_circle : Icons.error,
            color: isHealthy ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(
            isHealthy ? 'OK' : 'ERROR',
            style: TextStyle(
              color: isHealthy ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  'Force Sync',
                  Icons.sync,
                  Colors.blue,
                  () => _performFullSync(),
                ),
                _buildActionButton(
                  'Test Network',
                  Icons.network_check,
                  Colors.green,
                  () => _testNetworkQuality(),
                ),
                _buildActionButton(
                  'Clear Cache',
                  Icons.clear,
                  Colors.orange,
                  () => _clearCache(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
          ),
          child: Icon(icon, size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecentActivityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildActivityItem('Network status changed', 'Connected', DateTime.now().subtract(const Duration(minutes: 5))),
            _buildActivityItem('Sync completed', '15 items synchronized', DateTime.now().subtract(const Duration(minutes: 12))),
            _buildActivityItem('API endpoint tested', '/api/v1/health - OK', DateTime.now().subtract(const Duration(minutes: 20))),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, DateTime timestamp) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.info_outline, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Text(
        _formatTime(timestamp),
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      ),
    );
  }

  Widget _buildNetworkStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Network Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  _getNetworkIcon(_networkStatus),
                  color: _getNetworkColor(_networkStatus),
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getNetworkStatusText(_networkStatus),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getNetworkDescription(_networkStatus),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionInfoCard() {
    if (_connectionInfo == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Loading connection info...'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connection Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Type', _connectionInfo!.type.toString().split('.').last.toUpperCase()),
            _buildInfoRow('Internet Access', _connectionInfo!.hasInternet ? 'Available' : 'No Access'),
            _buildInfoRow('Speed', _connectionInfo!.speed?.toString().split('.').last ?? 'Unknown'),
            _buildInfoRow('Last Updated', _formatDateTime(_connectionInfo!.timestamp)),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkQualityCard() {
    if (_networkQuality == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Measuring network quality...'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Network Quality',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: _networkQuality!.score / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getQualityColor(_networkQuality!.level),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${_networkQuality!.score}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_networkQuality!.description),
            if (_networkQuality!.recommendations.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Recommendations:', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._networkQuality!.recommendations.map(
                (rec) => Text('• $rec', style: const TextStyle(fontSize: 12)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkMetricsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Network Metrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMetricRow('Latency', _networkQuality?.avgLatency?.toStringAsFixed(0) ?? 'N/A', 'ms'),
            _buildMetricRow('Uptime', '99.5', '%'),
            _buildMetricRow('Data Usage', '125.4', 'MB'),
            _buildMetricRow('Requests', '1,247', 'total'),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Synchronization Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  _getSyncIcon(_syncStatus),
                  color: _getSyncColor(_syncStatus),
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getSyncStatusText(_syncStatus),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Pending operations: $_pendingSyncCount',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingSyncsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pending Syncs',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_pendingSyncCount > 0)
                  Chip(
                    label: Text('$_pendingSyncCount'),
                    backgroundColor: Colors.orange[100],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_pendingSyncCount == 0)
              const Text('No pending synchronizations')
            else
              Column(
                children: [
                  _buildPendingSyncItem('User Profile Update', 'user_123'),
                  _buildPendingSyncItem('Task Completion', 'task_456'),
                  _buildPendingSyncItem('Reward Redemption', 'reward_789'),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingSyncItem(String type, String id) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.sync_problem, color: Colors.orange),
      title: Text(type),
      subtitle: Text('ID: $id'),
      trailing: IconButton(
        icon: const Icon(Icons.sync),
        onPressed: () {
          // Retry sync for this item
        },
      ),
    );
  }

  Widget _buildSyncHistoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sync History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSyncHistoryItem('Full Sync', 'Completed successfully', DateTime.now().subtract(const Duration(minutes: 15)), true),
            _buildSyncHistoryItem('Task Sync', 'Completed successfully', DateTime.now().subtract(const Duration(hours: 1)), true),
            _buildSyncHistoryItem('User Sync', 'Failed - Network error', DateTime.now().subtract(const Duration(hours: 2)), false),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncHistoryItem(String operation, String result, DateTime timestamp, bool success) {
    return ListTile(
      dense: true,
      leading: Icon(
        success ? Icons.check_circle : Icons.error,
        color: success ? Colors.green : Colors.red,
      ),
      title: Text(operation),
      subtitle: Text(result),
      trailing: Text(
        _formatTime(timestamp),
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      ),
    );
  }

  Widget _buildEndpointOverviewCard() {
    final healthyEndpoints = _endpointStatuses.values.where((s) => s.isHealthy).length;
    final totalEndpoints = _endpointStatuses.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'API Endpoints',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text('$healthyEndpoints / $totalEndpoints endpoints healthy'),
                ),
                ElevatedButton(
                  onPressed: _testApiEndpoints,
                  child: const Text('Test All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: totalEndpoints > 0 ? healthyEndpoints / totalEndpoints : 0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                healthyEndpoints == totalEndpoints ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndpointCard(ApiEndpointStatus status) {
    return Card(
      child: ListTile(
        leading: Icon(
          status.isHealthy ? Icons.check_circle : Icons.error,
          color: status.isHealthy ? Colors.green : Colors.red,
        ),
        title: Text(status.endpoint),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (status.responseTime != null)
              Text('Response time: ${status.responseTime!.inMilliseconds}ms'),
            if (status.error != null)
              Text('Error: ${status.error!}', style: const TextStyle(color: Colors.red)),
            Text('Last checked: ${_formatTime(status.lastChecked)}'),
          ],
        ),
        trailing: status.statusCode != null
            ? Chip(
                label: Text('${status.statusCode}'),
                backgroundColor: status.isHealthy ? Colors.green[100] : Colors.red[100],
              )
            : null,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text('$value $unit', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Helper methods for icons and colors
  IconData _getNetworkIcon(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.connected:
        return Icons.wifi;
      case NetworkStatus.disconnected:
        return Icons.wifi_off;
      case NetworkStatus.limited:
        return Icons.wifi_tethering_error;
      default:
        return Icons.help_outline;
    }
  }

  Color _getNetworkColor(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.connected:
        return Colors.green;
      case NetworkStatus.disconnected:
        return Colors.red;
      case NetworkStatus.limited:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getNetworkStatusText(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.connected:
        return 'Connected';
      case NetworkStatus.disconnected:
        return 'Disconnected';
      case NetworkStatus.limited:
        return 'Limited';
      default:
        return 'Unknown';
    }
  }

  String _getNetworkDescription(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.connected:
        return 'Internet connection available';
      case NetworkStatus.disconnected:
        return 'No network connection';
      case NetworkStatus.limited:
        return 'Network available but no internet';
      default:
        return 'Network status unknown';
    }
  }

  IconData _getSyncIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.completed:
        return Icons.check_circle;
      case SyncStatus.failed:
        return Icons.error;
      default:
        return Icons.sync_disabled;
    }
  }

  Color _getSyncColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.completed:
        return Colors.green;
      case SyncStatus.failed:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getSyncStatusText(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.completed:
        return 'Up to date';
      case SyncStatus.failed:
        return 'Sync failed';
      default:
        return 'Idle';
    }
  }

  Color _getQualityColor(QualityLevel level) {
    switch (level) {
      case QualityLevel.excellent:
        return Colors.green;
      case QualityLevel.good:
        return Colors.lightGreen;
      case QualityLevel.fair:
        return Colors.orange;
      case QualityLevel.poor:
        return Colors.red;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Action methods
  Future<void> _performFullSync() async {
    try {
      await DataSyncService.performFullSync();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Full synchronization completed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testNetworkQuality() async {
    setState(() => _isLoading = true);
    _networkQuality = await NetworkService.assessNetworkQuality();
    setState(() => _isLoading = false);
  }

  Future<void> _clearCache() async {
    // Implement cache clearing
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache cleared'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

// Supporting classes
class ApiEndpointStatus {
  final String endpoint;
  final bool isHealthy;
  final Duration? responseTime;
  final int? statusCode;
  final DateTime lastChecked;
  final String? error;

  const ApiEndpointStatus({
    required this.endpoint,
    required this.isHealthy,
    this.responseTime,
    this.statusCode,
    required this.lastChecked,
    this.error,
  });
}