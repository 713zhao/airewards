import 'package:flutter/material.dart';
import '../../../../core/models/goal_model.dart';
import '../../../../core/services/goal_service.dart';
import '../../core/l10n/app_localizations.dart';

/// Widget to display goal progress card
class GoalProgressCard extends StatefulWidget {
  final GoalModel goal;
  final int currentPoints;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const GoalProgressCard({
    super.key,
    required this.goal,
    required this.currentPoints,
    this.onTap,
    this.onDelete,
  });

  @override
  State<GoalProgressCard> createState() => _GoalProgressCardState();
}

class _GoalProgressCardState extends State<GoalProgressCard> {
  final _goalService = GoalService();
  int? _estimatedDays;
  bool _isLoadingEstimate = false;

  @override
  void initState() {
    super.initState();
    _calculateEstimate();
  }

  @override
  void didUpdateWidget(GoalProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recalculate estimate if points or goal changed
    if (oldWidget.currentPoints != widget.currentPoints ||
        oldWidget.goal.id != widget.goal.id) {
      _calculateEstimate();
    }
  }

  Future<void> _calculateEstimate() async {
    setState(() => _isLoadingEstimate = true);
    
    try {
      final days = await _goalService.calculateDaysToGoal(
        targetPoints: widget.goal.targetPoints ?? 0,
        currentPoints: widget.currentPoints,
        lookbackDays: 5,
      );
      
      if (mounted) {
        setState(() {
          _estimatedDays = days;
        });
      }
    } catch (e) {
      print('Error calculating estimate: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingEstimate = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.goal.getProgress(widget.currentPoints);
    final pointsNeeded = widget.goal.getPointsNeeded(widget.currentPoints);
    final isCompleted = widget.goal.isGoalCompleted(widget.currentPoints);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.secondaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.goal.targetType == GoalTargetType.points
                          ? Icons.stars
                          : Icons.card_giftcard,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).translate('your_goal_label'),
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          widget.goal.targetDescription,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: widget.onDelete,
                      tooltip: AppLocalizations.of(context).translate('remove_goal'),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context).translate('progress_label'),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted
                            ? Colors.green
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      icon: Icons.trending_up,
                      label: AppLocalizations.of(context).translate('current'),
                      value: '${widget.currentPoints} ${AppLocalizations.of(context).translate('pts')}',
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      icon: Icons.flag,
                      label: AppLocalizations.of(context).translate('target'),
                      value: '${widget.goal.targetPoints} ${AppLocalizations.of(context).translate('pts')}',
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      icon: Icons.info_outline,
                      label: AppLocalizations.of(context).translate('needed'),
                      value: isCompleted ? AppLocalizations.of(context).translate('done_exclamation') : '$pointsNeeded ${AppLocalizations.of(context).translate('pts')}',
                      valueColor: isCompleted ? Colors.green : null,
                    ),
                  ),
                ],
              ),
              
              // Estimated Days
              if (!isCompleted && _estimatedDays != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _estimatedDays == 0
                              ? AppLocalizations.of(context).translate('goal_reached')
                              : '${AppLocalizations.of(context).translate('estimated')}: ~$_estimatedDays ${_estimatedDays == 1 ? AppLocalizations.of(context).translate('day') : AppLocalizations.of(context).translate('days')} ${AppLocalizations.of(context).translate('to_reach_goal')}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (!isCompleted && _isLoadingEstimate) ...[
                const SizedBox(height: 16),
                const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ] else if (!isCompleted && _estimatedDays == null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context).translate('complete_more_tasks_estimate'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Completion Badge
              if (isCompleted) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.celebration,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '🎉 ${AppLocalizations.of(context).translate('goal_achieved')} 🎉',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
