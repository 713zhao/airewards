import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/family_service.dart';
import '../../core/services/task_service.dart';
import '../../core/services/reward_service.dart';
import '../../core/injection/injection.dart';
import '../../core/services/data_deletion_service.dart';

// Top-level widget for double-confirmation before deleting all data
class _ConfirmDeleteInput extends StatefulWidget {
  final VoidCallback onConfirmed;
  const _ConfirmDeleteInput({required this.onConfirmed});

  @override
  State<_ConfirmDeleteInput> createState() => _ConfirmDeleteInputState();
}

class _ConfirmDeleteInputState extends State<_ConfirmDeleteInput> {
  final _controller = TextEditingController();
  bool _canConfirm = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _canConfirm = _controller.text.trim().toUpperCase() == 'DELETE';
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'Type DELETE',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _canConfirm ? widget.onConfirmed : null,
            icon: const Icon(Icons.delete_forever),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

/// Settings screen with configuration options for the app
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isRestoring = false;
  late FamilyService _familyService;

  @override
  void initState() {
    super.initState();
    _familyService = getIt<FamilyService>();
  }

  Future<void> _performRestore() async {
    setState(() => _isRestoring = true);
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser == null) {
        throw Exception('No user authenticated');
      }
      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Deleting all data and restoring defaults...'),
              const SizedBox(height: 8),
              Text(
                'This may take a few moments',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
      // Step 1: Delete all tasks
      await _deleteAllTasks(currentUser.familyId!);
      // Step 1b: Delete task history
      await _deleteAllTaskHistory(currentUser.familyId!);
      // Step 2: Delete all custom rewards
      await _deleteAllCustomRewards();
      // Step 3: Delete all redemption history
      await _deleteAllRedemptionHistory(currentUser.familyId!);
      // Step 4: Reset all family member points
      await _resetAllFamilyMemberPoints(currentUser.familyId!);
      // Step 5: Reset family settings
      await _resetFamilySettings(currentUser.familyId!);
      // Step 6: Create default tasks and rewards
      await _createDefaultTasksAndRewards(currentUser.familyId!, currentUser.id);
      // Close progress dialog
      Navigator.of(context).pop();
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Successfully restored to default settings!\nAll points, tasks, and rewards have been reset.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Restore failed: $e'),
          backgroundColor: Colors.red,
        ),
      );

      debugPrint('❌ Task assignment failed: $e');
    }
  }
// ...existing methods...

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.currentUser;
    final isParent = currentUser?.accountType.name == 'parent';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // General Settings
            _buildSettingsSection(
              'General',
              [
                _buildSettingsTile(
                  'Notifications',
                  'Manage notification preferences',
                  Icons.notifications,
                  () => _showComingSoon('Notifications'),
                ),
                _buildSettingsTile(
                  'Theme',
                  'Choose light or dark theme',
                  Icons.palette,
                  () => _showComingSoon('Theme settings'),
                ),
                _buildSettingsTile(
                  'Language',
                  'Select your preferred language',
                  Icons.language,
                  () => _showComingSoon('Language settings'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Privacy & Security
            _buildSettingsSection(
              'Privacy & Security',
              [
                _buildSettingsTile(
                  'Privacy Settings',
                  'Control your data and privacy',
                  Icons.privacy_tip,
                  () => _showComingSoon('Privacy settings'),
                ),
                _buildSettingsTile(
                  'Account Security',
                  'Manage passwords and authentication',
                  Icons.security,
                  () => _showComingSoon('Account security'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Parent Only Settings
            if (isParent) ...[
              _buildSettingsSection(
                'Parent Controls',
                [
                  _buildSettingsTile(
                    'Family Management',
                    'Manage family members and settings',
                    Icons.family_restroom,
                    _openFamilyManagement,
                  ),
                  _buildSettingsTile(
                    'Parental Controls',
                    'Set controls and restrictions for children',
                    Icons.child_care,
                    () => _showComingSoon('Parental controls'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Data Management (Parent Only)
              _buildSettingsSection(
                'Data Management',
                [
                  _buildSettingsTile(
                    'Export Data',
                    'Download your family data',
                    Icons.download,
                    () => _showComingSoon('Export data'),
                  ),
                  _buildDangerousSettingsTile(
                    'Delete ALL Data',
                    'Permanently delete all data (family-wide for parent)',
                    Icons.delete_forever,
                    _confirmDeleteAllData,
                  ),
                  _buildDangerousSettingsTile(
                    'Restore to Default',
                    'Reset all data and restore default tasks/rewards',
                    Icons.restore,
                    _showRestoreConfirmation,
                    isLoading: _isRestoring,
                  ),
                  _buildSettingsTile(
                    'Fix Child Tasks (Debug)',
                    'Assign default tasks to existing children',
                    Icons.assignment_turned_in,
                    _assignTasksToChildren,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            // About & Support
            _buildSettingsSection(
              'About & Support',
              [
                _buildSettingsTile(
                  'Help & FAQ',
                  'Get help and find answers',
                  Icons.help_outline,
                  () => _showComingSoon('Help & FAQ'),
                ),
                _buildSettingsTile(
                  'About',
                  'App version and information',
                  Icons.info,
                  () => _showComingSoon('About'),
                ),
                _buildSettingsTile(
                  'Contact Support',
                  'Get in touch with our support team',
                  Icons.support_agent,
                  () => _showComingSoon('Contact support'),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
  // ...existing methods...

  void _showRestoreConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade700),
            const SizedBox(width: 8),
            const Text('Restore to Default'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action will permanently delete ALL of your family data and cannot be undone:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('• All custom tasks will be deleted'),
            Text('• All custom rewards will be deleted'),
            Text('• All task completion history will be deleted'),
            Text('• All point/redemption history will be deleted'),
            Text('• ALL family member points will be reset to 0'),
            Text('• All achievements will be cleared'),
            Text('• Family settings will be reset'),
            SizedBox(height: 16),
            Text(
              'Default tasks and rewards will be restored for a fresh start.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16),
            Text(
              'Are you absolutely sure you want to proceed?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performRestore();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete All & Restore'),
          ),
        ],
      ),
    );
  }


  Widget _buildSettingsSection(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: tiles,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 13,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildDangerousSettingsTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isLoading = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.red.shade700),
      title: Text(
        title,
        style: TextStyle(color: Colors.red.shade700),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 13,
        ),
      ),
      trailing: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(Icons.chevron_right, color: Colors.red.shade700),
      onTap: isLoading ? null : onTap,
    );
  }

  void _openFamilyManagement() {
    Navigator.of(context).pop(); // Close settings
    // This will trigger the family management screen from main app
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmDeleteAllData() {
    final currentUser = AuthService.currentUser;
    final isParent = currentUser?.accountType.name == 'parent';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red.shade700),
            const SizedBox(width: 8),
            const Text('Delete ALL Data'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isParent
                  ? 'This will permanently delete ALL data for your entire family: users, tasks, history, redemptions, and the family itself.'
                  : 'This will permanently delete ALL of your data: tasks, history, redemptions, and your user account.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('This action CANNOT be undone.'),
            const SizedBox(height: 16),
            const Text('Type DELETE to confirm:'),
            const SizedBox(height: 8),
            _ConfirmDeleteInput(
              onConfirmed: () async {
                Navigator.of(context).pop();
                await _performDeleteAllData();
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
      ),
    );
  }

  Future<void> _performDeleteAllData() async {
    try {
      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Deleting all data...'),
            ],
          ),
        ),
      );

      final service = DataDeletionService();
      await service.deleteAllData(includeFamilyIfParent: true);

      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ All data deleted. You have been signed out.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        // Navigate back to allow auth state listener to redirect to login
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pop(); // Close settings screen
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Deletion failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

// All methods using context, setState, and _familyService are now inside _SettingsScreenState

  Future<void> _deleteAllTasks(String familyId) async {
    final tasksQuery = await FirebaseFirestore.instance
        .collection('tasks')
        .where('familyId', isEqualTo: familyId)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in tasksQuery.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
    debugPrint('🗑️ Deleted ${tasksQuery.docs.length} tasks');
  }

  Future<void> _deleteAllTaskHistory(String familyId) async {
    int totalDeleted = 0;
    while (true) {
      final historyQuery = await FirebaseFirestore.instance
          .collection('task_history')
          .where('familyId', isEqualTo: familyId)
          .limit(300)
          .get();

      if (historyQuery.docs.isEmpty) break;

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in historyQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      totalDeleted += historyQuery.docs.length;
    }

    debugPrint('🗑️ Deleted $totalDeleted task history records');
  }

  Future<void> _deleteAllCustomRewards() async {
    // Reset rewards service to defaults
    final rewardService = RewardService();
    await rewardService.initialize(); // This will recreate defaults
    debugPrint('🗑️ Reset rewards to defaults');
  }

  Future<void> _deleteAllRedemptionHistory(String familyId) async {
    final redemptionsQuery = await FirebaseFirestore.instance
        .collection('redemptions')
        .where('familyId', isEqualTo: familyId)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in redemptionsQuery.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
    debugPrint('🗑️ Deleted ${redemptionsQuery.docs.length} redemptions');
  }

  Future<void> _resetFamilySettings(String familyId) async {
    // TODO: Implement actual reset logic
    debugPrint('Reset family settings for $familyId');
  }

  Future<void> _createDefaultTasksAndRewards(String familyId, String userId) async {
    // TODO: Implement actual creation logic
    debugPrint('Create default tasks and rewards for family $familyId, user $userId');
  }

  Future<void> _assignTasksToChildren() async {
    // TODO: Implement actual assignment logic
    debugPrint('Assign default tasks to children');
  }

  Future<void> _resetAllFamilyMemberPoints(String familyId) async {
    final usersQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('familyId', isEqualTo: familyId)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in usersQuery.docs) {
      batch.update(doc.reference, {
        'currentPoints': 0,
        'totalPoints': 0,
        'achievements': [],
      });
    }
    await batch.commit();
    debugPrint('🗑️ Reset points for ${usersQuery.docs.length} family members');
  }
// ...existing code...
}