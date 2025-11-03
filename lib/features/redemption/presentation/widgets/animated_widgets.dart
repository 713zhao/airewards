import 'package:flutter/material.dart';
import '../theme/kids_theme_extension.dart';

/// Animated coin widget for displaying points in a fun way
/// 
/// This widget creates a bouncing, spinning coin with customizable
/// colors and animations to make point display engaging for kids.
class AnimatedCoinWidget extends StatefulWidget {
  const AnimatedCoinWidget({
    super.key,
    required this.points,
    this.size = 60.0,
    this.coinType = CoinType.gold,
    this.isAnimating = false,
    this.onTap,
  });

  final int points;
  final double size;
  final CoinType coinType;
  final bool isAnimating;
  final VoidCallback? onTap;

  @override
  State<AnimatedCoinWidget> createState() => _AnimatedCoinWidgetState();
}

class _AnimatedCoinWidgetState extends State<AnimatedCoinWidget>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _spinController;
  late AnimationController _glowController;
  
  late Animation<double> _bounceAnimation;
  late Animation<double> _spinAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _spinController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _spinAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _glowController.repeat(reverse: true);
    
    if (widget.isAnimating) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(AnimatedCoinWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating && !oldWidget.isAnimating) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _bounceController.forward().then((_) {
      _spinController.repeat();
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _spinController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Color _getCoinColor(BuildContext context) {
    final kidsTheme = context.kidsTheme;
    switch (widget.coinType) {
      case CoinType.gold:
        return kidsTheme.coinGold;
      case CoinType.silver:
        return kidsTheme.coinSilver;
      case CoinType.bronze:
        return kidsTheme.coinBronze;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _bounceAnimation,
          _spinAnimation,
          _glowAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: 0.8 + (_bounceAnimation.value * 0.2),
            child: Transform.rotate(
              angle: _spinAnimation.value * 2 * 3.14159,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _getCoinColor(context),
                      _getCoinColor(context).withOpacity(0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getCoinColor(context).withOpacity(_glowAnimation.value * 0.5),
                      blurRadius: 10 * _glowAnimation.value,
                      spreadRadius: 2 * _glowAnimation.value,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: Colors.white,
                        size: widget.size * 0.3,
                      ),
                      Text(
                        '${widget.points}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: widget.size * 0.15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Types of coins for different point values
enum CoinType {
  gold,
  silver,
  bronze,
}

/// Fun star rating widget with animations
/// 
/// This widget creates animated stars that bounce in sequence
/// for showing ratings or achievements in a kid-friendly way.
class AnimatedStarRating extends StatefulWidget {
  const AnimatedStarRating({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.size = 24.0,
    this.isAnimating = false,
    this.onRatingTap,
  });

  final double rating;
  final int maxRating;
  final double size;
  final bool isAnimating;
  final Function(double)? onRatingTap;

  @override
  State<AnimatedStarRating> createState() => _AnimatedStarRatingState();
}

class _AnimatedStarRatingState extends State<AnimatedStarRating>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    
    _controllers = List.generate(
      widget.maxRating,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );

    _animations = _controllers
        .map(
          (controller) => Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: controller, curve: Curves.elasticOut),
          ),
        )
        .toList();

    if (widget.isAnimating) {
      _startAnimation();
    }
  }

  void _startAnimation() async {
    for (int i = 0; i < widget.rating.floor(); i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      _controllers[i].forward();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kidsTheme = context.kidsTheme;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.maxRating, (index) {
        return GestureDetector(
          onTap: widget.onRatingTap != null
              ? () => widget.onRatingTap!(index + 1.0)
              : null,
          child: AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              final scale = 0.5 + (_animations[index].value * 0.5);
              final isFilledStar = index < widget.rating.floor();
              final isHalfStar = index < widget.rating && index >= widget.rating.floor();
              
              return Transform.scale(
                scale: scale,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    isFilledStar || isHalfStar ? Icons.star : Icons.star_border,
                    size: widget.size,
                    color: isFilledStar || isHalfStar
                        ? kidsTheme.starYellow
                        : Colors.grey[300],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

/// Bouncing button with kid-friendly styling
/// 
/// This widget creates a colorful button that bounces when pressed
/// and provides haptic feedback for better engagement.
class BouncingButton extends StatefulWidget {
  const BouncingButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.elevation = 4.0,
    this.isEnabled = true,
  });

  final VoidCallback onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double elevation;
  final bool isEnabled;

  @override
  State<BouncingButton> createState() => _BouncingButtonState();
}

class _BouncingButtonState extends State<BouncingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.isEnabled) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.isEnabled) {
      _controller.reverse();
      widget.onPressed();
    }
  }

  void _onTapCancel() {
    if (widget.isEnabled) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final kidsTheme = context.kidsTheme;
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                color: widget.isEnabled
                    ? (widget.backgroundColor ?? kidsTheme.primaryFun)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: widget.isEnabled
                    ? [
                        BoxShadow(
                          color: (widget.backgroundColor ?? kidsTheme.primaryFun)
                              .withOpacity(0.3),
                          blurRadius: widget.elevation,
                          offset: Offset(0, widget.elevation / 2),
                        ),
                      ]
                    : null,
                gradient: widget.isEnabled
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          widget.backgroundColor ?? kidsTheme.primaryFun,
                          (widget.backgroundColor ?? kidsTheme.primaryFun)
                              .withOpacity(0.8),
                        ],
                      )
                    : null,
              ),
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: widget.isEnabled
                      ? (widget.foregroundColor ?? Colors.white)
                      : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}