import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/redemption/redemption_bloc.dart';
import '../bloc/redemption/redemption_event.dart';
import '../bloc/redemption/redemption_state.dart';
import '../theme/kids_theme_extension.dart';
import '../widgets/animated_widgets.dart';
import '../../domain/entities/entities.dart';

/// Fun redemption history screen for kids
/// 
/// This screen shows a playful timeline of past redemptions with
/// colorful cards, animations, and kid-friendly language.
class RedemptionHistoryScreen extends StatefulWidget {
  const RedemptionHistoryScreen({super.key});

  @override
  State<RedemptionHistoryScreen> createState() => _RedemptionHistoryScreenState();
}

class _RedemptionHistoryScreenState extends State<RedemptionHistoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late Animation<double> _headerAnimation;

  @override
  void initState() {
    super.initState();
    
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutBack,
    ));

    _headerController.forward();

    // Load redemption history
    context.read<RedemptionBloc>().add(const RedemptionHistoryRequested());
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kidsTheme = context.kidsTheme;
    
    return Theme(
      data: Theme.of(context).copyWith(
        extensions: [kidsTheme],
      ),
      child: Scaffold(
        backgroundColor: kidsTheme.backgroundFun,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: AnimatedBuilder(
            animation: _headerAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset((1 - _headerAnimation.value) * -100, 0),
                child: Opacity(
                  opacity: _headerAnimation.value,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kidsTheme.primaryFun,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.history,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Rewards',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: kidsTheme.primaryFun,
                            ),
                          ),
                          Text(
                            'Look what you got!',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            BouncingButton(
              onPressed: () {
                context.read<RedemptionBloc>().add(const RedemptionHistoryRefreshed());
              },
              backgroundColor: kidsTheme.secondaryFun,
              padding: const EdgeInsets.all(12),
              borderRadius: 12,
              child: Icon(Icons.refresh, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: BlocBuilder<RedemptionBloc, RedemptionState>(
          builder: (context, state) {
            if (state is RedemptionHistoryLoading) {
              return _buildLoadingState(context);
            }
            
            if (state is RedemptionHistoryError) {
              return _buildErrorState(context, state.message);
            }
            
            if (state is RedemptionHistoryLoaded) {
              if (state.transactions.isEmpty) {
                return _buildEmptyState(context);
              }
              
              return _buildHistoryList(context, state.transactions);
            }
            
            return _buildInitialState(context);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final kidsTheme = context.kidsTheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedCoinWidget(
            points: 500,
            size: 80,
            coinType: CoinType.gold,
            isAnimating: true,
          ),
          const SizedBox(height: 24),
          Text(
            'Finding your awesome rewards...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: kidsTheme.primaryFun,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This might take a moment!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final kidsTheme = context.kidsTheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kidsTheme.errorFun.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                Icons.error_outline,
                size: 60,
                color: kidsTheme.errorFun,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: kidsTheme.errorFun,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            BouncingButton(
              onPressed: () {
                context.read<RedemptionBloc>().add(const RedemptionHistoryRequested(forceRefresh: true));
              },
              backgroundColor: kidsTheme.primaryFun,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Try Again'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final kidsTheme = context.kidsTheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kidsTheme.secondaryFun.withOpacity(0.2),
                    kidsTheme.primaryFun.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.card_giftcard,
                size: 80,
                color: kidsTheme.primaryFun,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Rewards Yet!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: kidsTheme.primaryFun,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start earning points and get\namazing rewards to fill this page!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            BouncingButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              backgroundColor: kidsTheme.successFun,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Get Rewards!'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState(BuildContext context) {
    final kidsTheme = context.kidsTheme;
    
    return Center(
      child: BouncingButton(
        onPressed: () {
          context.read<RedemptionBloc>().add(const RedemptionHistoryRequested());
        },
        backgroundColor: kidsTheme.primaryFun,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, color: Colors.white),
            const SizedBox(width: 8),
            Text('Load My Rewards'),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context, List<RedemptionTransaction> transactions) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return FunHistoryCard(
          transaction: transaction,
          index: index,
          onTap: () => _showTransactionDetails(context, transaction),
        );
      },
    );
  }

  void _showTransactionDetails(BuildContext context, RedemptionTransaction transaction) {
    showDialog(
      context: context,
      builder: (context) => TransactionDetailsDialog(transaction: transaction),
    );
  }
}

/// Fun history card for displaying individual redemption transactions
class FunHistoryCard extends StatefulWidget {
  const FunHistoryCard({
    super.key,
    required this.transaction,
    required this.index,
    this.onTap,
  });

  final RedemptionTransaction transaction;
  final int index;
  final VoidCallback? onTap;

  @override
  State<FunHistoryCard> createState() => _FunHistoryCardState();
}

class _FunHistoryCardState extends State<FunHistoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    // Staggered animation based on index
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getStatusColor(BuildContext context) {
    final kidsTheme = context.kidsTheme;
    
    switch (widget.transaction.status) {
      case RedemptionStatus.completed:
        return kidsTheme.successFun;
      case RedemptionStatus.pending:
        return kidsTheme.warningFun;
      case RedemptionStatus.expired:
        return kidsTheme.errorFun;
      case RedemptionStatus.cancelled:
        return Colors.grey[600]!;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.transaction.status) {
      case RedemptionStatus.completed:
        return Icons.celebration;
      case RedemptionStatus.pending:
        return Icons.hourglass_empty;
      case RedemptionStatus.expired:
        return Icons.error_outline;
      case RedemptionStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  String _getStatusText() {
    switch (widget.transaction.status) {
      case RedemptionStatus.completed:
        return 'Got it!';
      case RedemptionStatus.pending:
        return 'Getting ready...';
      case RedemptionStatus.expired:
        return 'Time\'s up';
      case RedemptionStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(context);
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value, 0),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: widget.onTap,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Status indicator
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          _getStatusIcon(),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Transaction info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Option title
                            Text(
                              widget.transaction.optionId, // In real app, this would be the option title
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            const SizedBox(height: 4),
                            
                            // Status and date
                            Row(
                              children: [
                                Text(
                                  _getStatusText(),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  ' • ${_formatDate(widget.transaction.createdAt)}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Points spent
                            Row(
                              children: [
                                AnimatedCoinWidget(
                                  points: widget.transaction.pointsUsed,
                                  size: 20,
                                  coinType: widget.transaction.pointsUsed >= 5000 
                                      ? CoinType.gold 
                                      : widget.transaction.pointsUsed >= 1000 
                                          ? CoinType.silver 
                                          : CoinType.bronze,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${widget.transaction.pointsUsed} points',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Arrow
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey[400],
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Transaction details dialog
class TransactionDetailsDialog extends StatelessWidget {
  const TransactionDetailsDialog({
    super.key,
    required this.transaction,
  });

  final RedemptionTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final kidsTheme = context.kidsTheme;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Text(
              'Reward Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: kidsTheme.primaryFun,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Transaction info
            _buildDetailRow(context, 'Reward ID', transaction.id),
            _buildDetailRow(context, 'Points Used', '${transaction.pointsUsed}'),
            _buildDetailRow(context, 'Status', transaction.status.name),
            _buildDetailRow(context, 'Date', _formatFullDate(transaction.createdAt)),
            
            if (transaction.notes != null)
              _buildDetailRow(context, 'Notes', transaction.notes!),
            
            const SizedBox(height: 20),
            
            // Close button
            BouncingButton(
              onPressed: () => Navigator.of(context).pop(),
              backgroundColor: kidsTheme.primaryFun,
              child: Text('Got it!'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}