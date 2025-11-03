import 'package:flutter/material.dart';
import '../../domain/entities/entities.dart';
import '../theme/kids_theme_extension.dart';
import 'animated_widgets.dart';

/// Fun and colorful reward card for displaying redemption options
/// 
/// This widget creates an engaging card with animations, fun colors,
/// and child-friendly icons to make browsing rewards exciting for kids.
class FunRewardCard extends StatefulWidget {
  const FunRewardCard({
    super.key,
    required this.option,
    this.onTap,
    this.isSelected = false,
    this.showAnimation = false,
  });

  final RedemptionOption option;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool showAnimation;

  @override
  State<FunRewardCard> createState() => _FunRewardCardState();
}

class _FunRewardCardState extends State<FunRewardCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _rotateAnimation = Tween<double>(
      begin: -0.1,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    if (widget.showAnimation) {
      Future.delayed(Duration(milliseconds: 200 * (widget.option.id.hashCode % 5)), () {
        if (mounted) {
          _controller.forward();
        }
      });
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon() {
    final category = widget.option.categoryId.toLowerCase();
    
    switch (category) {
      case 'toys':
        return Icons.toys;
      case 'games':
        return Icons.games;
      case 'books':
        return Icons.menu_book;
      case 'art':
        return Icons.palette;
      case 'sports':
        return Icons.sports_soccer;
      case 'music':
        return Icons.music_note;
      case 'food':
        return Icons.cake;
      case 'outdoor':
        return Icons.park;
      case 'electronics':
        return Icons.devices;
      case 'clothes':
        return Icons.checkroom;
      default:
        return Icons.card_giftcard;
    }
  }

  Color _getCategoryColor(BuildContext context) {
    final kidsTheme = context.kidsTheme;
    final category = widget.option.categoryId.toLowerCase();
    
    switch (category) {
      case 'toys':
        return kidsTheme.heartRed;
      case 'games':
        return kidsTheme.primaryFun;
      case 'books':
        return kidsTheme.leafGreen;
      case 'art':
        return kidsTheme.purpleMagic;
      case 'sports':
        return kidsTheme.sunOrange;
      case 'music':
        return kidsTheme.pinkBubble;
      case 'food':
        return kidsTheme.secondaryFun;
      case 'outdoor':
        return kidsTheme.skyBlue;
      case 'electronics':
        return kidsTheme.coinSilver;
      case 'clothes':
        return kidsTheme.purpleMagic;
      default:
        return kidsTheme.primaryFun;
    }
  }

  CoinType _getCoinType() {
    if (widget.option.requiredPoints >= 5000) {
      return CoinType.gold;
    } else if (widget.option.requiredPoints >= 1000) {
      return CoinType.silver;
    } else {
      return CoinType.bronze;
    }
  }

  @override
  Widget build(BuildContext context) {
    final kidsTheme = context.kidsTheme;
    final categoryColor = _getCategoryColor(context);
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotateAnimation.value,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.isSelected ? categoryColor.withOpacity(0.1) : kidsTheme.surfaceFun,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.isSelected ? categoryColor : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: categoryColor.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                    if (widget.isSelected)
                      BoxShadow(
                        color: categoryColor.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header with category icon and availability
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            categoryColor,
                            categoryColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(17),
                          topRight: Radius.circular(17),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getCategoryIcon(),
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const Spacer(),
                          if (widget.option.isAvailable)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: kidsTheme.successFun,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Available!',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: kidsTheme.warningFun,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.hourglass_empty,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Soon!',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              widget.option.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: categoryColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            
                            // Description
                            Expanded(
                              child: Text(
                                widget.option.description,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Points and coin
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'You need:',
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          AnimatedCoinWidget(
                                            points: widget.option.requiredPoints,
                                            size: 32,
                                            coinType: _getCoinType(),
                                            isAnimating: widget.showAnimation,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${widget.option.requiredPoints}',
                                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: categoryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Fun action button
                                BouncingButton(
                                  onPressed: widget.onTap ?? () {},
                                  backgroundColor: categoryColor,
                                  borderRadius: 12,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text('Get it!'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Points balance display widget with fun animations
/// 
/// This widget shows the user's current points balance in a
/// visually appealing way with coin animations and celebrations.
class FunPointsBalance extends StatefulWidget {
  const FunPointsBalance({
    super.key,
    required this.availablePoints,
    this.showCelebration = false,
    this.onTap,
  });

  final int availablePoints;
  final bool showCelebration;
  final VoidCallback? onTap;

  @override
  State<FunPointsBalance> createState() => _FunPointsBalanceState();
}

class _FunPointsBalanceState extends State<FunPointsBalance>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late AnimationController _pulseController;
  
  late Animation<double> _celebrationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _celebrationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);

    if (widget.showCelebration) {
      _celebrationController.forward();
    }
  }

  @override
  void didUpdateWidget(FunPointsBalance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showCelebration && !oldWidget.showCelebration) {
      _celebrationController.forward();
    }
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kidsTheme = context.kidsTheme;
    
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_celebrationAnimation, _pulseAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kidsTheme.coinGold,
                    kidsTheme.coinGold.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: kidsTheme.coinGold.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Animated coins
                  AnimatedCoinWidget(
                    points: widget.availablePoints,
                    size: 60,
                    coinType: CoinType.gold,
                    isAnimating: widget.showCelebration,
                  ),
                  
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Points',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.availablePoints}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Ready to spend!',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Celebration sparkles
                  if (widget.showCelebration)
                    Transform.rotate(
                      angle: _celebrationAnimation.value * 6.28,
                      child: Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}