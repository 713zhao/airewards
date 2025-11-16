import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../core/security/audit_logging_service.dart';
import '../../core/security/authentication_security_service.dart';

/// Comprehensive security monitoring dashboard
class SecurityDashboard extends StatefulWidget {
  const SecurityDashboard({super.key});

  @override
  State<SecurityDashboard> createState() => _SecurityDashboardState();
}

class _SecurityDashboardState extends State<SecurityDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  SecuritySummary? _summary;
  List<SecurityAlert> _alerts = [];
  SecurityStatus? _status;
  List<AuditLogEntry> _recentLogs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSecurityData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSecurityData() async {
    setState(() => _isLoading = true);

    try {
      // Load security summary
      _summary = await AuditLoggingService.getSecuritySummary(
        period: const Duration(hours: 24),
      );

      // Detect suspicious activities
      _alerts = await AuditLoggingService.detectSuspiciousActivity();

      // Get security status
      _status = AuthenticationSecurityService.getSecurityStatus();

      // Load recent logs
      _recentLogs = await AuditLoggingService.queryLogs(
        startDate: DateTime.now().subtract(const Duration(hours: 6)),
        limit: 50,
      );
    } catch (e) {
      debugPrint('❌ Failed to load security data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load security data'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Dashboard'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSecurityData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.warning), text: 'Alerts'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            Tab(icon: Icon(Icons.list), text: 'Logs'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildAlertsTab(),
                _buildAnalyticsTab(),
                _buildLogsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    if (_summary == null || _status == null) {
      return const Center(child: Text('Failed to load security overview'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSecurityStatusCard(),
          const SizedBox(height: 16),
          _buildQuickStatsGrid(),
          const SizedBox(height: 16),
          _buildThreatLevelCard(),
          const SizedBox(height: 16),
          _buildRecentActivityCard(),
        ],
      ),
    );
  }

  Widget _buildAlertsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Security Alerts',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_alerts.isNotEmpty)
                Chip(
                  label: Text('${_alerts.length}'),
                  backgroundColor: Colors.red[100],
                  labelStyle: TextStyle(color: Colors.red[700]),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_alerts.isEmpty)
            _buildNoAlertsCard()
          else
            ..._alerts.map((alert) => _buildAlertCard(alert)),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Security Analytics',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildEventDistributionCard(),
          const SizedBox(height: 16),
          _buildSecurityTrendsCard(),
          const SizedBox(height: 16),
          _buildUserActivityCard(),
        ],
      ),
    );
  }

  Widget _buildLogsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Security Logs',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _exportLogs,
                icon: const Icon(Icons.download),
                label: const Text('Export'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _recentLogs.isEmpty
              ? const Center(child: Text('No logs found'))
              : ListView.builder(
                  itemCount: _recentLogs.length,
                  itemBuilder: (context, index) =>
                      _buildLogEntry(_recentLogs[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildSecurityStatusCard() {
    final threatLevel = _calculateThreatLevel();
    final threatColor = _getThreatColor(threatLevel);

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
                  'Security Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: threatColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: threatColor),
                  ),
                  child: Text(
                    threatLevel,
                    style: TextStyle(
                      color: threatColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatusMetric(
                    'Active Sessions',
                    _status!.activeSessions.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatusMetric(
                    'Locked Accounts',
                    _status!.lockedAccounts.toString(),
                    Icons.lock,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatusMetric(
                    'Failed Attempts',
                    _status!.failedAttempts.toString(),
                    Icons.error,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Events',
          _summary!.totalEvents.toString(),
          Icons.event,
          Colors.blue,
        ),
        _buildStatCard(
          'Critical Events',
          _summary!.criticalEvents.toString(),
          Icons.priority_high,
          Colors.red,
        ),
        _buildStatCard(
          'Authentication',
          _summary!.authenticationEvents.toString(),
          Icons.login,
          Colors.green,
        ),
        _buildStatCard(
          'Data Access',
          _summary!.dataAccessEvents.toString(),
          Icons.data_usage,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreatLevelCard() {
    final threatLevel = _calculateThreatLevel();
    final threatColor = _getThreatColor(threatLevel);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Threat Assessment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: _getThreatLevelValue(threatLevel),
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(threatColor),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  threatLevel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: threatColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _getThreatDescription(threatLevel),
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    final recentActivity = _recentLogs.take(5).toList();

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
            if (recentActivity.isEmpty)
              const Text('No recent activity')
            else
              ...recentActivity.map((log) => _buildRecentActivityItem(log)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityItem(AuditLogEntry log) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getSeverityColor(log.severity),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.description,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatTime(log.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAlertsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.shield,
              size: 64,
              color: Colors.green[300],
            ),
            const SizedBox(height: 16),
            Text(
              'All Clear',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No security alerts detected',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(SecurityAlert alert) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getSeverityColor(alert.severity),
          child: Icon(
            _getAlertIcon(alert.type),
            color: Colors.white,
          ),
        ),
        title: Text(alert.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alert.description),
            const SizedBox(height: 4),
            Text(
              _formatDateTime(alert.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showAlertActions(alert),
        ),
      ),
    );
  }

  Widget _buildEventDistributionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Event Distribution (24h)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: CustomPaint(
                painter: PieChartPainter(_getEventDistributionData()),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTrendsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Security Trends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: CustomPaint(
                painter: LineChartPainter(_getSecurityTrendsData()),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserActivityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildUserActivityStat('Unique Users (24h)', _summary!.uniqueUsers.toString()),
            _buildUserActivityStat('Active Sessions', _status!.activeSessions.toString()),
            _buildUserActivityStat('Authentication Events', _summary!.authenticationEvents.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildUserActivityStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntry(AuditLogEntry log) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getSeverityColor(log.severity),
          radius: 16,
          child: Icon(
            _getCategoryIcon(log.category),
            color: Colors.white,
            size: 16,
          ),
        ),
        title: Text(
          log.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(_formatDateTime(log.timestamp)),
        trailing: Chip(
          label: Text(
            log.severity.toString().split('.').last.toUpperCase(),
            style: const TextStyle(fontSize: 10),
          ),
          backgroundColor: _getSeverityColor(log.severity).withOpacity(0.1),
          labelStyle: TextStyle(
            color: _getSeverityColor(log.severity),
          ),
        ),
      ),
    );
  }

  // Helper methods
  String _calculateThreatLevel() {
    final criticalEvents = _summary?.criticalEvents ?? 0;
    final errorEvents = _summary?.errorEvents ?? 0;
    final warningEvents = _summary?.warningEvents ?? 0;
    final alertCount = _alerts.length;

    if (criticalEvents > 0 || alertCount > 5) return 'HIGH';
    if (errorEvents > 3 || warningEvents > 10 || alertCount > 2) return 'MEDIUM';
    return 'LOW';
  }

  Color _getThreatColor(String threatLevel) {
    switch (threatLevel) {
      case 'HIGH':
        return Colors.red[700]!;
      case 'MEDIUM':
        return Colors.orange[700]!;
      case 'LOW':
        return Colors.green[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  double _getThreatLevelValue(String threatLevel) {
    switch (threatLevel) {
      case 'HIGH':
        return 1.0;
      case 'MEDIUM':
        return 0.6;
      case 'LOW':
        return 0.3;
      default:
        return 0.0;
    }
  }

  String _getThreatDescription(String threatLevel) {
    switch (threatLevel) {
      case 'HIGH':
        return 'Critical security events detected. Immediate attention required.';
      case 'MEDIUM':
        return 'Some security concerns detected. Monitor closely.';
      case 'LOW':
        return 'Security status is normal. Continue monitoring.';
      default:
        return 'Unknown threat level.';
    }
  }

  Color _getSeverityColor(LogSeverity severity) {
    switch (severity) {
      case LogSeverity.critical:
        return Colors.red[700]!;
      case LogSeverity.error:
        return Colors.orange[700]!;
      case LogSeverity.warning:
        return Colors.yellow[700]!;
      case LogSeverity.info:
        return Colors.blue[700]!;
      case LogSeverity.debug:
        return Colors.grey[700]!;
    }
  }

  IconData _getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.suspiciousActivity:
        return Icons.warning;
      case AlertType.unusualDataAccess:
        return Icons.data_usage;
      case AlertType.securityBreach:
        return Icons.security;
      case AlertType.complianceViolation:
        return Icons.gavel;
    }
  }

  IconData _getCategoryIcon(LogCategory category) {
    switch (category) {
      case LogCategory.authentication:
        return Icons.login;
      case LogCategory.security:
        return Icons.security;
      case LogCategory.dataAccess:
        return Icons.data_usage;
      case LogCategory.parentalControl:
        return Icons.family_restroom;
      case LogCategory.privacy:
        return Icons.privacy_tip;
      case LogCategory.system:
        return Icons.settings;
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

  List<ChartData> _getEventDistributionData() {
    return [
      ChartData('Auth', _summary!.authenticationEvents.toDouble(), Colors.blue),
      ChartData('Security', (_summary!.criticalEvents + _summary!.errorEvents).toDouble(), Colors.red),
      ChartData('Data', _summary!.dataAccessEvents.toDouble(), Colors.purple),
      ChartData('Privacy', _summary!.privacyEvents.toDouble(), Colors.green),
    ];
  }

  List<ChartPoint> _getSecurityTrendsData() {
    // Mock data for demonstration
    return List.generate(24, (index) {
      return ChartPoint(
        index.toDouble(),
        math.Random().nextDouble() * 100,
      );
    });
  }

  void _exportLogs() {
    // Implement log export functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Logs'),
        content: const Text('Select export format and date range.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Implement actual export
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showAlertActions(SecurityAlert alert) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('View Details'),
              onTap: () {
                Navigator.of(context).pop();
                // Show alert details
              },
            ),
            ListTile(
              leading: const Icon(Icons.check),
              title: const Text('Mark as Resolved'),
              onTap: () {
                Navigator.of(context).pop();
                // Mark alert as resolved
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Dismiss'),
              onTap: () {
                Navigator.of(context).pop();
                // Dismiss alert
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painters for charts
class PieChartPainter extends CustomPainter {
  final List<ChartData> data;

  PieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;
    
    final total = data.fold(0.0, (sum, item) => sum + item.value);
    double currentAngle = -math.pi / 2;

    for (final item in data) {
      final sweepAngle = (item.value / total) * 2 * math.pi;
      
      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        sweepAngle,
        true,
        paint,
      );

      currentAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class LineChartPainter extends CustomPainter {
  final List<ChartPoint> points;

  LineChartPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue[700]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    for (int i = 0; i < points.length; i++) {
      final x = (points[i].x / (points.length - 1)) * size.width;
      final y = size.height - (points[i].y / 100) * size.height;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Supporting classes
class ChartData {
  final String label;
  final double value;
  final Color color;

  const ChartData(this.label, this.value, this.color);
}

class ChartPoint {
  final double x;
  final double y;

  const ChartPoint(this.x, this.y);
}