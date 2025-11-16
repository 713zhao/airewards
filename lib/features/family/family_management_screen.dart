import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/family_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_service.dart';
import '../../core/models/family.dart';
import '../../core/models/user_model.dart';
import '../../core/models/task_model.dart';
import '../../core/injection/injection.dart';

/// Screen for parents to manage their family - add children, view family info
class FamilyManagementScreen extends StatefulWidget {
  const FamilyManagementScreen({super.key});

  @override
  State<FamilyManagementScreen> createState() => _FamilyManagementScreenState();
}

class _FamilyManagementScreenState extends State<FamilyManagementScreen> {
  late FamilyService _familyService;
  final _familyNameController = TextEditingController();
  final _invitationCodeController = TextEditingController();
  
  // Suppress all print statements in this class
  void print(Object? object) {}

  bool _isLoading = false;
  bool _isCreatingFamily = false;
  Family? _currentFamily;
  List<UserModel> _children = [];
  final Map<String, int> _childrenTodayPoints = {}; // Real-time points from today's activities
  String? _generatedInvitationCode;

  @override
  void initState() {
    super.initState();
    _familyService = getIt<FamilyService>();
    _loadFamilyData();
  }

  @override
  void dispose() {
    _familyNameController.dispose();
    _invitationCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadFamilyData() async {
    setState(() => _isLoading = true);
    
    try {
      await _familyService.initialize();
      _currentFamily = _familyService.currentFamily;
      
      if (_currentFamily != null) {
        _children = await _familyService.getCurrentFamilyChildren();
        await _loadChildrenTodayPoints();
      }
    } catch (e) {
      debugPrint('Error loading family data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadChildrenTodayPoints() async {
    _childrenTodayPoints.clear();
    
    for (final child in _children) {
      try {
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        // Use the same successful approach as main app screen - get ALL tasks first, then filter
        List<TaskModel> tasks = [];
        
        try {
          final querySnapshot = await FirebaseFirestore.instance
              .collection('tasks')
              .where('assignedToUserId', isEqualTo: child.id)
              .get()
              .timeout(const Duration(seconds: 3));
          
          tasks = querySnapshot.docs
              .map((doc) {
                try {
                  return TaskModel.fromFirestore(doc);
                } catch (e) {
                  debugPrint('Error parsing task ${doc.id}: $e');
                  return null;
                }
              })
              .where((task) => task != null)
              .cast<TaskModel>()
              .toList();
          
          debugPrint('📋 Found ${tasks.length} total tasks for ${child.displayName} (${child.id})');
        } catch (e) {
          debugPrint('⚠️ Direct query failed for ${child.displayName}: $e');
        }
        
        // Filter for today's completed tasks and redemptions
        int completedTasks = 0;
        int redemptions = 0;
        int pointsEarned = 0;
        int pointsSpent = 0;
        
        for (final task in tasks) {
          debugPrint('  📝 Task: ${task.title} - Completed: ${task.isCompleted} - Points: ${task.pointValue} - Category: ${task.category}');
          
          if (task.isCompleted && task.completedAt != null) {
            final completedDate = task.completedAt!;
            if (completedDate.isAfter(startOfDay) && completedDate.isBefore(endOfDay)) {
              final isRedemption = task.category == 'Reward Redemption';
              
              if (isRedemption) {
                redemptions++;
                pointsSpent += task.pointValue.abs().toInt(); // Redemptions usually have negative points
                debugPrint('  🎁 REDEMPTION: ${task.title} = ${task.pointValue.abs()} points spent');
              } else {
                completedTasks++;
                pointsEarned += task.pointValue.toInt();
                debugPrint('  ✅ TASK: ${task.title} = ${task.pointValue} points earned');
              }
            }
          }
        }

        final netPoints = pointsEarned - pointsSpent;
        _childrenTodayPoints[child.id] = netPoints;
        
        debugPrint('💰 Child ${child.displayName} (${child.id}) today: $completedTasks tasks (+$pointsEarned), $redemptions redemptions (-$pointsSpent), net: $netPoints');
      } catch (e) {
        debugPrint('❌ Error calculating points for ${child.displayName}: $e');
        _childrenTodayPoints[child.id] = 0;
      }
    }
  }

  Future<void> _createFamily() async {
    if (!_familyNameController.text.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a family name')),
      );
      return;
    }

    setState(() => _isCreatingFamily = true);

    try {
      final currentUser = AuthService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final family = await _familyService.createFamily(
        name: _familyNameController.text.trim(),
        parentId: currentUser.id,
        description: 'Family created by ${currentUser.displayName}',
      );

      // Reload user data from Firestore to update the in-memory familyId in AuthService
      try {
        final userService = getIt<UserService>();
        final refreshedUser = await userService.getUser(currentUser.id);
        if (refreshedUser != null) {
          // Update AuthService's currentUser
          AuthService.updateCurrentUser(refreshedUser);
          debugPrint('✅ User familyId refreshed: ${refreshedUser.familyId}');
        }
      } catch (e) {
        debugPrint('⚠️ Failed to refresh user data: $e');
      }

      setState(() {
        _currentFamily = family;
        _familyNameController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Family created successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating family: $e')),
      );
    } finally {
      setState(() => _isCreatingFamily = false);
    }
  }

  void _generateInvitationCode() {
    if (_currentFamily == null) return;
    
    setState(() {
      _generatedInvitationCode = _familyService.generateInvitationCode();
    });
  }

  void _copyInvitationCode() {
    if (_generatedInvitationCode == null) return;
    
    Clipboard.setData(ClipboardData(text: _generatedInvitationCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invitation code copied to clipboard!')),
    );
  }

  Future<void> _confirmAndDeleteFamily() async {
    if (_currentFamily == null) return;

    final currentUser = AuthService.currentUser;
    if (currentUser == null || !currentUser.isParent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only parents can delete a family')),
      );
      return;
    }

    String typed = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Delete Family'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('This will permanently delete the family and all family templates. This action cannot be undone.'),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (v) {
                      setState(() {
                        typed = v.trim();
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Type DELETE to confirm',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: typed == 'DELETE' ? () => Navigator.of(ctx).pop(true) : null,
                  child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: const [
            SizedBox(width: 24, height: 24, child: CircularProgressIndicator()),
            SizedBox(width: 16),
            Expanded(child: Text('Deleting family...')),
          ],
        ),
      ),
    );

    bool success = false;
    try {
      success = await _familyService.deleteFamily(_currentFamily!.id);
    } catch (e) {
      debugPrint('Error deleting family: $e');
      success = false;
    }

    // Close progress
    Navigator.of(context, rootNavigator: true).pop();

    if (success) {
      // Show success message before signing out
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Family deleted successfully. You will be signed out.'),
          duration: Duration(seconds: 2),
        ),
      );

      // Sign out the user since their user document has been deleted
      // This prevents the app from recreating the user with wrong account type
      await Future.delayed(const Duration(seconds: 2));
      await AuthService.signOut();
      
      // Navigate to login screen
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete family. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Management'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_currentFamily == null) ...[
                    _buildCreateFamilySection(),
                  ] else ...[
                    _buildFamilyInfoSection(),
                    const SizedBox(height: 24),
                    _buildChildrenSection(),
                    const SizedBox(height: 24),
                    _buildInvitationSection(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildCreateFamilySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Your Family',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a family to start managing tasks and rewards for your children.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _familyNameController,
              decoration: const InputDecoration(
                labelText: 'Family Name',
                hintText: 'e.g., The Smith Family',
                prefixIcon: Icon(Icons.family_restroom),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCreatingFamily ? null : _createFamily,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isCreatingFamily
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Family'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.family_restroom,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentFamily!.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Created ${_formatDate(_currentFamily!.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard('Children', '${_children.length}', Icons.child_care),
                const SizedBox(width: 16),
                _buildStatCard('Family ID', _currentFamily!.id.substring(0, 8), Icons.fingerprint),
              ],
            ),
            const SizedBox(height: 12),
            // Dangerous action: delete family (visible to parents only)
            if (AuthService.currentUser?.isParent ?? false) ...[
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _currentFamily == null ? null : _confirmAndDeleteFamily,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Delete Family'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildrenSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Children (${_children.length})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_children.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Icon(Icons.child_care, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'No children added yet',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Use the invitation code below to add children to your family',
                      style: TextStyle(color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ..._children.map((child) => _buildChildCard(child)),
          ],
        ),
      ),
    );
  }

  Widget _buildChildCard(UserModel child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            child: Text(child.displayName.substring(0, 1).toUpperCase()),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  child.email,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                Text(
                  '${_childrenTodayPoints[child.id] ?? 0} points today',
                  style: TextStyle(
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.verified, color: Colors.green.shade600),
        ],
      ),
    );
  }

  Widget _buildInvitationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Children',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate an invitation code for your children to join the family.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            if (_generatedInvitationCode == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generateInvitationCode,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Generate Invitation Code'),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Invitation Code',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _generatedInvitationCode!,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _copyInvitationCode,
                          icon: const Icon(Icons.copy),
                          tooltip: 'Copy code',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Share this code with your child to join the family',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _generatedInvitationCode = null;
                        });
                      },
                      child: const Text('Generate New Code'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}