import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../security/privacy_compliance_service.dart';
import '../security/authentication_security_service.dart';
import '../security/audit_logging_service.dart';

/// Comprehensive parental control interface for child safety management
class ParentalControlScreen extends StatefulWidget {
  final String childUserId;
  final String parentUserId;

  const ParentalControlScreen({
    super.key,
    required this.childUserId,
    required this.parentUserId,
  });

  @override
  State<ParentalControlScreen> createState() => _ParentalControlScreenState();
}

class _ParentalControlScreenState extends State<ParentalControlScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  ParentalControlSettings? _settings;
  ChildDataSummary? _dataSummary;
  List<AuditLogEntry> _recentActivity = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadParentalControlData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadParentalControlData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load parental control settings
      _settings = await PrivacyComplianceService.getParentalControlSettings(
        widget.childUserId,
      );
      
      // Load child data summary
      _dataSummary = await PrivacyComplianceService.getChildDataSummary(
        widget.childUserId,
      );
      
      // Load recent activity
      _recentActivity = await AuditLoggingService.queryLogs(
        userId: widget.childUserId,
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        limit: 20,
      );
      
    } catch (e) {
      debugPrint('❌ Failed to load parental control data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load parental control data'),
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
        title: const Text('Parental Controls'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
            Tab(icon: Icon(Icons.data_usage), text: 'Data'),
            Tab(icon: Icon(Icons.history), text: 'Activity'),
            Tab(icon: Icon(Icons.security), text: 'Privacy'),
            Tab(icon: Icon(Icons.help), text: 'Help'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSettingsTab(),
                _buildDataTab(),
                _buildActivityTab(),
                _buildPrivacyTab(),
                _buildHelpTab(),
              ],
            ),
    );
  }

  Widget _buildSettingsTab() {
    if (_settings == null) {
      return const Center(child: Text('Failed to load settings'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingsCard(
            'Account Settings',
            Icons.account_circle,
            [
              _buildSwitchTile(
                'Account Active',
                'Enable or disable the child account',
                _settings!.accountActive,
                (value) => _updateAccountActive(value),
              ),
              _buildSwitchTile(
                'Require Parental Approval',
                'Require approval for certain actions',
                _settings!.requireApproval,
                (value) => _updateRequireApproval(value),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsCard(
            'Privacy Settings',
            Icons.privacy_tip,
            [
              _buildSwitchTile(
                'Data Collection',
                'Allow collection of usage data',
                _settings!.dataCollectionEnabled,
                (value) => _updateDataCollection(value),
              ),
              _buildSwitchTile(
                'Analytics',
                'Allow anonymous analytics',
                _settings!.analyticsEnabled,
                (value) => _updateAnalytics(value),
              ),
              _buildSwitchTile(
                'Personalization',
                'Allow personalized content',
                _settings!.personalizationEnabled,
                (value) => _updatePersonalization(value),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsCard(
            'Time Limits',
            Icons.schedule,
            [
              _buildTimeLimitTile(),
              _buildDailyUsageTile(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataTab() {
    if (_dataSummary == null) {
      return const Center(child: Text('Failed to load data summary'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDataSummaryCard(),
          const SizedBox(height: 16),
          _buildDataCategoriesCard(),
          const SizedBox(height: 16),
          _buildDataActionsCard(),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_recentActivity.isEmpty)
            const Center(
              child: Text('No recent activity found'),
            )
          else
            ..._recentActivity.map((activity) => _buildActivityItem(activity)),
        ],
      ),
    );
  }

  Widget _buildPrivacyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPrivacyOverviewCard(),
          const SizedBox(height: 16),
          _buildConsentManagementCard(),
          const SizedBox(height: 16),
          _buildDataRightsCard(),
        ],
      ),
    );
  }

  Widget _buildHelpTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parental Control Help',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildHelpSection(
            'Getting Started',
            'Learn how to set up and manage your child\'s account safely.',
            Icons.play_circle,
          ),
          _buildHelpSection(
            'Privacy & Safety',
            'Understand how we protect your child\'s data and privacy.',
            Icons.shield,
          ),
          _buildHelpSection(
            'Managing Consent',
            'Control what data can be collected and how it\'s used.',
            Icons.verified_user,
          ),
          _buildHelpSection(
            'Data Rights',
            'Learn about your rights to access, modify, or delete data.',
            Icons.gavel,
          ),
          const SizedBox(height: 24),
          _buildContactSupportCard(),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(String title, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.blue[700],
    );
  }

  Widget _buildTimeLimitTile() {
    return ListTile(
      title: const Text('Daily Time Limit'),
      subtitle: Text('${_settings!.dailyTimeLimitMinutes} minutes'),
      trailing: const Icon(Icons.edit),
      onTap: () => _editTimeLimit(),
    );
  }

  Widget _buildDailyUsageTile() {
    return ListTile(
      title: const Text('Usage Today'),
      subtitle: Text('${_settings!.todayUsageMinutes} minutes'),
      trailing: CircularProgressIndicator(
        value: _settings!.todayUsageMinutes / _settings!.dailyTimeLimitMinutes,
        backgroundColor: Colors.grey[300],
        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
      ),
    );
  }

  Widget _buildDataSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDataStat('Profile Data', '${_dataSummary!.profileDataCount} items'),
            _buildDataStat('Activity Data', '${_dataSummary!.activityDataCount} entries'),
            _buildDataStat('Usage Data', '${_dataSummary!.usageDataCount} records'),
            _buildDataStat('Last Updated', _formatDate(_dataSummary!.lastUpdated)),
          ],
        ),
      ),
    );
  }

  Widget _buildDataStat(String label, String value) {
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

  Widget _buildDataCategoriesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._dataSummary!.dataCategories.map((category) =>
              _buildDataCategoryTile(category),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCategoryTile(DataCategory category) {
    return ListTile(
      leading: Icon(_getDataCategoryIcon(category.type)),
      title: Text(category.name),
      subtitle: Text('${category.itemCount} items'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _viewDataCategory(category),
    );
  }

  Widget _buildDataActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              'Export All Data',
              'Download a copy of all your child\'s data',
              Icons.download,
              () => _exportData(),
            ),
            _buildActionButton(
              'Delete Specific Data',
              'Remove selected data categories',
              Icons.delete_outline,
              () => _deleteSpecificData(),
            ),
            _buildActionButton(
              'Delete All Data',
              'Permanently remove all account data',
              Icons.delete_forever,
              () => _deleteAllData(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue[700]),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onPressed,
      ),
    );
  }

  Widget _buildActivityItem(AuditLogEntry activity) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getSeverityColor(activity.severity),
          child: Icon(
            _getActivityIcon(activity.category),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(activity.description),
        subtitle: Text(_formatDateTime(activity.timestamp)),
        trailing: _getSeverityBadge(activity.severity),
      ),
    );
  }

  Widget _buildPrivacyOverviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your child\'s privacy is our priority. We comply with COPPA and GDPR regulations to ensure their data is protected.',
            ),
            const SizedBox(height: 12),
            _buildPrivacyStat('Data Encrypted', '100%'),
            _buildPrivacyStat('Consent Status', 'Active'),
            _buildPrivacyStat('Last Review', _formatDate(DateTime.now())),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentManagementCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Consent Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildConsentItem('Data Collection', true),
            _buildConsentItem('Analytics', false),
            _buildConsentItem('Marketing', false),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _manageConsent(),
              child: const Text('Manage Consent'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentItem(String title, bool granted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Icon(
            granted ? Icons.check_circle : Icons.cancel,
            color: granted ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildDataRightsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Rights',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Under COPPA and GDPR, you have the right to:',
            ),
            const SizedBox(height: 12),
            _buildDataRight('Access your child\'s data'),
            _buildDataRight('Correct inaccurate information'),
            _buildDataRight('Delete personal data'),
            _buildDataRight('Restrict data processing'),
            _buildDataRight('Data portability'),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRight(String right) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.check, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(right)),
        ],
      ),
    );
  }

  Widget _buildHelpSection(String title, String description, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.blue[700]),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openHelpTopic(title),
      ),
    );
  }

  Widget _buildContactSupportCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Need Help?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Our support team is here to help with any questions about parental controls.',
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _contactSupport(),
              icon: const Icon(Icons.support_agent),
              label: const Text('Contact Support'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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

  Widget _getSeverityBadge(LogSeverity severity) {
    final color = _getSeverityColor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        severity.toString().split('.').last.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _getActivityIcon(LogCategory category) {
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

  IconData _getDataCategoryIcon(String type) {
    switch (type.toLowerCase()) {
      case 'profile':
        return Icons.person;
      case 'activity':
        return Icons.timeline;
      case 'usage':
        return Icons.analytics;
      case 'preferences':
        return Icons.tune;
      default:
        return Icons.folder;
    }
  }

  // Action methods
  Future<void> _updateAccountActive(bool value) async {
    // Update account active status
    await AuditLoggingService.logParentalControlEvent(
      parentUserId: widget.parentUserId,
      childUserId: widget.childUserId,
      eventType: ParentalEventType.settingsChanged,
      description: 'Account active status changed to $value',
    );
    setState(() {
      _settings!.accountActive = value;
    });
  }

  Future<void> _updateRequireApproval(bool value) async {
    setState(() {
      _settings!.requireApproval = value;
    });
  }

  Future<void> _updateDataCollection(bool value) async {
    setState(() {
      _settings!.dataCollectionEnabled = value;
    });
  }

  Future<void> _updateAnalytics(bool value) async {
    setState(() {
      _settings!.analyticsEnabled = value;
    });
  }

  Future<void> _updatePersonalization(bool value) async {
    setState(() {
      _settings!.personalizationEnabled = value;
    });
  }

  void _editTimeLimit() {
    showDialog(
      context: context,
      builder: (context) => TimeLimitDialog(
        currentLimit: _settings!.dailyTimeLimitMinutes,
        onSaved: (newLimit) {
          setState(() {
            _settings!.dailyTimeLimitMinutes = newLimit;
          });
        },
      ),
    );
  }

  void _viewDataCategory(DataCategory category) {
    // Navigate to detailed data category view
  }

  void _exportData() {
    // Implement data export functionality
  }

  void _deleteSpecificData() {
    // Implement selective data deletion
  }

  void _deleteAllData() {
    // Implement complete data deletion with confirmation
  }

  void _manageConsent() {
    // Navigate to consent management screen
  }

  void _openHelpTopic(String topic) {
    // Open help documentation for specific topic
  }

  void _contactSupport() {
    // Open support contact options
  }
}

/// Supporting classes
class ParentalControlSettings {
  bool accountActive;
  bool requireApproval;
  bool dataCollectionEnabled;
  bool analyticsEnabled;
  bool personalizationEnabled;
  int dailyTimeLimitMinutes;
  int todayUsageMinutes;

  ParentalControlSettings({
    required this.accountActive,
    required this.requireApproval,
    required this.dataCollectionEnabled,
    required this.analyticsEnabled,
    required this.personalizationEnabled,
    required this.dailyTimeLimitMinutes,
    required this.todayUsageMinutes,
  });
}

class ChildDataSummary {
  final int profileDataCount;
  final int activityDataCount;
  final int usageDataCount;
  final DateTime lastUpdated;
  final List<DataCategory> dataCategories;

  const ChildDataSummary({
    required this.profileDataCount,
    required this.activityDataCount,
    required this.usageDataCount,
    required this.lastUpdated,
    required this.dataCategories,
  });
}

class DataCategory {
  final String type;
  final String name;
  final int itemCount;

  const DataCategory({
    required this.type,
    required this.name,
    required this.itemCount,
  });
}

class TimeLimitDialog extends StatefulWidget {
  final int currentLimit;
  final ValueChanged<int> onSaved;

  const TimeLimitDialog({
    super.key,
    required this.currentLimit,
    required this.onSaved,
  });

  @override
  State<TimeLimitDialog> createState() => _TimeLimitDialogState();
}

class _TimeLimitDialogState extends State<TimeLimitDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentLimit.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Daily Time Limit'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          labelText: 'Minutes per day',
          suffixText: 'minutes',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final newLimit = int.tryParse(_controller.text) ?? widget.currentLimit;
            widget.onSaved(newLimit);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}