import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/models/goal_model.dart';
import '../../../../core/models/reward_item.dart';
import '../../../../core/services/goal_service.dart';
import '../../../../core/services/reward_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/l10n/app_localizations.dart';

/// Dialog for creating or editing a goal
class SetGoalDialog extends StatefulWidget {
  final GoalModel? existingGoal;
  final int currentPoints;

  const SetGoalDialog({
    super.key,
    this.existingGoal,
    required this.currentPoints,
  });

  @override
  State<SetGoalDialog> createState() => _SetGoalDialogState();
}

class _SetGoalDialogState extends State<SetGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pointsController = TextEditingController();
  final _goalService = GoalService();
  final _rewardService = RewardService();

  GoalTargetType _targetType = GoalTargetType.points;
  RewardItem? _selectedReward;
  List<RewardItem> _availableRewards = [];
  bool _isLoading = false;
  bool _isLoadingRewards = false;

  @override
  void initState() {
    super.initState();
    _loadRewards();
    
    if (widget.existingGoal != null) {
      _targetType = widget.existingGoal!.targetType;
      if (_targetType == GoalTargetType.points) {
        _pointsController.text = widget.existingGoal!.targetPoints?.toString() ?? '';
      }
    }
  }

  @override
  void dispose() {
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _loadRewards() async {
    setState(() => _isLoadingRewards = true);
    
    try {
      final rewards = await _rewardService.getActiveRewards();
      
      // Filter to show only active rewards
      final affordableRewards = rewards.where((r) {
        return r.isActive;
      }).toList();
      
      // Sort by points
      affordableRewards.sort((a, b) => a.points.compareTo(b.points));
      
      setState(() {
        _availableRewards = affordableRewards;
      });
      
      // Pre-select reward if editing
      if (widget.existingGoal?.targetRewardId != null && _availableRewards.isNotEmpty) {
        _selectedReward = _availableRewards.firstWhere(
          (r) => r.id == widget.existingGoal!.targetRewardId,
          orElse: () => _availableRewards.first,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading rewards: $e')),
        );
      }
    } finally {
      setState(() => _isLoadingRewards = false);
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    if (_targetType == GoalTargetType.reward && _selectedReward == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reward')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = AuthService.currentUser?.id;
      final familyId = AuthService.currentUser?.familyId;

      if (userId == null || familyId == null) {
        throw Exception('User not authenticated');
      }

      final GoalModel goal;
      
      if (_targetType == GoalTargetType.points) {
        final targetPoints = int.parse(_pointsController.text);
        goal = GoalModel.createPointsGoal(
          id: widget.existingGoal?.id ?? '',
          userId: userId,
          familyId: familyId,
          targetPoints: targetPoints,
          startingPoints: 0,
        );
      } else {
        goal = GoalModel.createRewardGoal(
          id: widget.existingGoal?.id ?? '',
          userId: userId,
          familyId: familyId,
          targetRewardId: _selectedReward!.id,
          targetRewardName: _selectedReward!.title,
          targetRewardCost: _selectedReward!.points,
          startingPoints: 0,
        );
      }

      await _goalService.createGoal(goal);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Goal set successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving goal: $e')),
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
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.flag,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.existingGoal == null ? 'Set Your Goal' : 'Edit Goal',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Points: ${widget.currentPoints}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Target Type Selection
                      Text(
                        'What\'s your goal?',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      
                      SegmentedButton<GoalTargetType>(
                        segments: const [
                          ButtonSegment(
                            value: GoalTargetType.points,
                            label: Text('Points Target'),
                            icon: Icon(Icons.stars),
                          ),
                          ButtonSegment(
                            value: GoalTargetType.reward,
                            label: Text('Reward Item'),
                            icon: Icon(Icons.card_giftcard),
                          ),
                        ],
                        selected: {_targetType},
                        onSelectionChanged: (Set<GoalTargetType> newSelection) {
                          setState(() {
                            _targetType = newSelection.first;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Target Input based on type
                      if (_targetType == GoalTargetType.points) ...[
                        TextFormField(
                          controller: _pointsController,
                          decoration: InputDecoration(
                            labelText: 'Target Points',
                            hintText: 'Enter your points goal',
                            prefixIcon: const Icon(Icons.stars),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            helperText: 'Set a target number of points to reach',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a target';
                            }
                            final points = int.tryParse(value);
                            if (points == null || points <= 0) {
                              return 'Please enter a valid number';
                            }
                            if (points <= widget.currentPoints) {
                              return 'Target must be higher than current points';
                            }
                            return null;
                          },
                        ),
                      ] else ...[
                        Text(
                          'Select Reward',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        
                        if (_isLoadingRewards)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_availableRewards.isEmpty)
                          const Text('No rewards available')
                        else
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            constraints: const BoxConstraints(maxHeight: 300),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _availableRewards.length,
                              itemBuilder: (context, index) {
                                final reward = _availableRewards[index];
                                final isSelected = _selectedReward?.id == reward.id;
                                
                                return ListTile(
                                  selected: isSelected,
                                  leading: CircleAvatar(
                                    backgroundColor: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.surfaceVariant,
                                    child: Icon(
                                      Icons.card_giftcard,
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.onPrimary
                                          : Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  title: Text(AppLocalizations.of(context).translateRewardTitle(reward.title)),
                                  subtitle: Text(AppLocalizations.of(context).translateRewardDescription(reward.description)),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      '${reward.points} pts',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedReward = reward;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveGoal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Set Goal'),
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
