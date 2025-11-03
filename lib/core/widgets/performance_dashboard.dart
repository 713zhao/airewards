import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;

import '../services/performance_service.dart';
import '../services/memory_management_service.dart';

/// Performance monitoring dashboard for development and debugging
class PerformanceDashboard extends StatefulWidget {
  const PerformanceDashboard({super.key});

  @override
  State<PerformanceDashboard> createState() => _PerformanceDashboardState();
}

class _PerformanceDashboardState extends State<PerformanceDashboard>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  Map<String, dynamic> _performanceMetrics = {};
  Map<String, dynamic> _memoryMetrics = {};
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _refreshMetrics();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _refreshMetrics() async {
    setState(() => _isRefreshing = true);
    
    try {
      _refreshController.forward().then((_) {
        _refreshController.reset();
      });

      // Get performance metrics
      _performanceMetrics = await PerformanceService.getPerformanceMetrics();
      
      // Get memory metrics
      _memoryMetrics = await MemoryManagementService.getMemoryMetrics();
      
    } catch (e) {
      developer.log('Error refreshing metrics: $e', name: 'PerformanceDashboard');
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: RotationTransition(
              turns: _refreshController,
              child: const Icon(Icons.refresh),
            ),
            onPressed: _isRefreshing ? null : _refreshMetrics,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Frame Rate Monitor
            _buildFrameRateCard(),
            
            const SizedBox(height: 16),
            
            // Memory Usage Card
            _buildMemoryCard(),
            
            const SizedBox(height: 16),
            
            // Performance Metrics Card
            _buildPerformanceMetricsCard(),
            
            const SizedBox(height: 16),
            
            // Network Performance Card
            _buildNetworkCard(),
            
            const SizedBox(height: 16),
            
            // Actions Card
            _buildActionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildFrameRateCard() {
    final frameRate = _performanceMetrics['frameRate'] ?? 60.0;
    final isGood = frameRate >= 55;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.speed,
                  color: isGood ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Frame Rate',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
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
                        '${frameRate.toStringAsFixed(1)} FPS',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: isGood ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isGood ? 'Excellent' : 'Needs Optimization',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isGood ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: frameRate / 60,
                    strokeWidth: 8,
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isGood ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoryCard() {
    final memoryUsage = _memoryMetrics['usedMemoryMB'] ?? 0.0;
    final maxMemory = _memoryMetrics['maxMemoryMB'] ?? 512.0;
    final percentage = memoryUsage / maxMemory;
    final isGood = percentage < 0.8;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.memory,
                  color: isGood ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Memory Usage',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            LinearProgressIndicator(
              value: percentage,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                isGood ? Colors.green : Colors.red,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${memoryUsage.toStringAsFixed(1)} MB',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${(percentage * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isGood ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Tracked Objects: ${_memoryMetrics['trackedObjects'] ?? 0}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetricsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics),
                const SizedBox(width: 8),
                Text(
                  'Performance Metrics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            _buildMetricRow(
              'App Launch Time',
              '${_performanceMetrics['appLaunchTime'] ?? 0}ms',
              _performanceMetrics['appLaunchTime'] != null && 
              _performanceMetrics['appLaunchTime'] < 2000,
            ),
            
            _buildMetricRow(
              'Screen Transitions',
              '${_performanceMetrics['screenTransitions'] ?? 0}',
              true,
            ),
            
            _buildMetricRow(
              'User Actions',
              '${_performanceMetrics['userActions'] ?? 0}',
              true,
            ),
            
            _buildMetricRow(
              'Network Requests',
              '${_performanceMetrics['networkRequests'] ?? 0}',
              true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkCard() {
    final avgResponseTime = _performanceMetrics['avgNetworkResponseTime'] ?? 0.0;
    final isGood = avgResponseTime < 1000 || avgResponseTime == 0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.network_check,
                  color: isGood ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Network Performance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            _buildMetricRow(
              'Avg Response Time',
              avgResponseTime > 0 ? '${avgResponseTime.toStringAsFixed(0)}ms' : 'N/A',
              isGood,
            ),
            
            _buildMetricRow(
              'Failed Requests',
              '${_performanceMetrics['failedNetworkRequests'] ?? 0}',
              (_performanceMetrics['failedNetworkRequests'] ?? 0) == 0,
            ),
            
            _buildMetricRow(
              'Cache Hit Rate',
              '${(_performanceMetrics['cacheHitRate'] ?? 0.0 * 100).toStringAsFixed(1)}%',
              (_performanceMetrics['cacheHitRate'] ?? 0.0) > 0.8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.build),
                const SizedBox(width: 8),
                Text(
                  'Performance Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await MemoryManagementService.handleMemoryPressure();
                    _refreshMetrics();
                    HapticFeedback.lightImpact();
                  },
                  icon: const Icon(Icons.cleaning_services),
                  label: const Text('Force GC'),
                ),
                
                ElevatedButton.icon(
                  onPressed: () async {
                    await PerformanceService.clearMetrics();
                    _refreshMetrics();
                    HapticFeedback.lightImpact();
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear Metrics'),
                ),
                
                ElevatedButton.icon(
                  onPressed: () {
                    developer.log('Performance snapshot taken', name: 'Dashboard');
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Performance snapshot logged'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Snapshot'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, bool isGood) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isGood ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating performance overlay for real-time monitoring
class PerformanceOverlay extends StatefulWidget {
  final Widget child;
  final bool showOverlay;

  const PerformanceOverlay({
    super.key,
    required this.child,
    this.showOverlay = false,
  });

  @override
  State<PerformanceOverlay> createState() => _PerformanceOverlayState();
}

class _PerformanceOverlayState extends State<PerformanceOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Map<String, dynamic> _metrics = {};
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
    
    if (widget.showOverlay) {
      _startMonitoring();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startMonitoring() {
    // Update metrics every second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && widget.showOverlay) {
        _updateMetrics();
        _startMonitoring();
      }
    });
  }

  void _updateMetrics() async {
    try {
      final metrics = await PerformanceService.getPerformanceMetrics();
      final memoryMetrics = await MemoryManagementService.getMemoryMetrics();
      
      setState(() {
        _metrics = {...metrics, ...memoryMetrics};
      });
    } catch (e) {
      // Silently handle errors in overlay
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
        if (widget.showOverlay)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'FPS: ${(_metrics['frameRate'] ?? 60.0).toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    'MEM: ${(_metrics['usedMemoryMB'] ?? 0.0).toStringAsFixed(0)}MB',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RotationTransition(
                        turns: _controller,
                        child: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'PERF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
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
}