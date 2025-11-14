import 'package:flutter/material.dart';
import '../../core/services/family_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/task_service.dart';
import '../../core/services/user_service.dart';
import '../../core/services/reward_service.dart';
import '../../core/injection/injection.dart';

/// Screen for children to join a family using invitation code
class JoinFamilyScreen extends StatefulWidget {
  const JoinFamilyScreen({super.key});

  @override
  State<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

class _JoinFamilyScreenState extends State<JoinFamilyScreen> {
  final _invitationCodeController = TextEditingController();
  late FamilyService _familyService;
  
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _familyService = getIt<FamilyService>();
  }

  @override
  void dispose() {
    _invitationCodeController.dispose();
    super.dispose();
  }

  Future<void> _joinFamily() async {
    final code = _invitationCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an invitation code')),
      );
      return;
    }

    setState(() => _isJoining = true);

    try {
      final currentUser = AuthService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final joinedFamilyId = await _familyService.joinFamilyWithCode(
        invitationCode: code,
        userId: currentUser.id,
      );

      if (joinedFamilyId != null) {
        // Reload the user from Firestore to get updated familyId
        try {
          final userService = UserService();
          final updatedUser = await userService.getUser(currentUser.id);
          if (updatedUser != null) {
            // Update the cached user in AuthService
            AuthService.updateCurrentUser(updatedUser);
            debugPrint('✅ User reloaded with familyId: ${updatedUser.familyId}');
          }
        } catch (e) {
          debugPrint('⚠️ Failed to reload user after joining family: $e');
        }
        
        // Assign existing family tasks to the new child
        try {
          print('🎯 Assigning existing tasks to new family member...');
          final taskService = TaskService();
          await taskService.assignExistingTasksToNewChild(
            childUserId: currentUser.id,
            familyId: joinedFamilyId, // Use the familyId that was just joined
          );
          print('✅ Tasks assigned successfully');
        } catch (e) {
          print('⚠️ Error assigning tasks to new child: $e');
          // Don't fail the join process if task assignment fails
        }
        
        // Reload rewards from family
        try {
          print('🎁 Loading family rewards...');
          final rewardService = RewardService();
          await rewardService.reloadRewards();
          print('✅ Rewards loaded successfully');
        } catch (e) {
          print('⚠️ Error loading family rewards: $e');
          // Don't fail the join process if reward loading fails
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined the family! Tasks and rewards have been loaded.')),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid invitation code. Please check and try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining family: $e')),
      );
    } finally {
      setState(() => _isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Family'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.family_restroom,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Join Your Family',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the invitation code provided by your parent to join your family and start earning rewards!',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          TextField(
                            controller: _invitationCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Invitation Code',
                              hintText: 'Enter 8-character code',
                              prefixIcon: Icon(Icons.vpn_key),
                              border: OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.characters,
                            maxLength: 8,
                            onChanged: (value) {
                              // Auto-format to uppercase
                              final newValue = value.toUpperCase();
                              if (newValue != value) {
                                _invitationCodeController.text = newValue;
                                _invitationCodeController.selection = TextSelection.fromPosition(
                                  TextPosition(offset: newValue.length),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isJoining ? null : _joinFamily,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _isJoining
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Join Family'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(height: 8),
                        Text(
                          'How to get your invitation code:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ask your parent to go to Family Management and generate an invitation code for you.',
                          style: TextStyle(color: Colors.blue.shade700),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}