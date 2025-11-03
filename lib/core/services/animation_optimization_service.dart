import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:injectable/injectable.dart';

/// Animation optimization service for smooth 60fps animations
@lazySingleton
class AnimationOptimizationService {
  static const Duration _defaultAnimationDuration = Duration(milliseconds: 300);
  static const Curve _defaultCurve = Curves.easeOutCubic;
  
  // Performance tracking
  static final Map<String, int> _animationPerformanceStats = {};
  static int _droppedFrames = 0;
  
  /// Initialize animation optimization service
  static void initialize() {
    // Set up frame callback monitoring in debug mode
    if (SchedulerBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      _setupFrameMonitoring();
    }
    
    debugPrint('🎬 AnimationOptimizationService initialized');
  }

  /// Set up frame rate monitoring
  static void _setupFrameMonitoring() {
    SchedulerBinding.instance.addTimingsCallback((timings) {
      for (final timing in timings) {
        final frameDuration = timing.totalSpan;
        // 60fps = ~16.67ms per frame, we'll allow up to 20ms before considering dropped
        if (frameDuration.inMilliseconds > 20) {
          _droppedFrames++;
        }
      }
    });
  }

  /// Create optimized fade transition
  static Widget createOptimizedFadeTransition({
    required Animation<double> animation,
    required Widget child,
    Duration duration = _defaultAnimationDuration,
    Curve curve = _defaultCurve,
  }) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: curve,
      ),
      child: RepaintBoundary(child: child),
    );
  }

  /// Create optimized slide transition
  static Widget createOptimizedSlideTransition({
    required Animation<double> animation,
    required Widget child,
    Offset begin = const Offset(1.0, 0.0),
    Offset end = Offset.zero,
    Curve curve = _defaultCurve,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: end,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: curve,
      )),
      child: RepaintBoundary(child: child),
    );
  }

  /// Create optimized scale transition
  static Widget createOptimizedScaleTransition({
    required Animation<double> animation,
    required Widget child,
    double beginScale = 0.0,
    double endScale = 1.0,
    Curve curve = _defaultCurve,
    Alignment alignment = Alignment.center,
  }) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: beginScale,
        end: endScale,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: curve,
      )),
      alignment: alignment,
      child: RepaintBoundary(child: child),
    );
  }

  /// Create kid-friendly celebration animation
  static Widget createCelebrationAnimation({
    required Animation<double> animation,
    required Widget child,
    bool includeConfetti = true,
    bool includeScale = true,
    bool includeRotation = false,
  }) {
    Widget result = child;

    if (includeScale) {
      result = ScaleTransition(
        scale: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.elasticOut,
        )),
        child: result,
      );
    }

    if (includeRotation) {
      result = RotationTransition(
        turns: Tween<double>(
          begin: 0.0,
          end: 0.25,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        )),
        child: result,
      );
    }

    if (includeConfetti) {
      result = Stack(
        alignment: Alignment.center,
        children: [
          result,
          ...List.generate(8, (index) => _buildConfettiParticle(animation, index)),
        ],
      );
    }

    return RepaintBoundary(child: result);
  }

  /// Build individual confetti particle
  static Widget _buildConfettiParticle(Animation<double> animation, int index) {
    final angle = (index * math.pi * 2) / 8;
    final distance = 100.0;
    
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final progress = animation.value;
        final x = math.cos(angle) * distance * progress;
        final y = math.sin(angle) * distance * progress - (progress * progress * 50);
        
        return Transform.translate(
          offset: Offset(x, y),
          child: Opacity(
            opacity: 1.0 - progress,
            child: Transform.rotate(
              angle: progress * math.pi * 4,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.primaries[index % Colors.primaries.length],
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Create optimized list animation
  static Widget createOptimizedListAnimation({
    required Animation<double> animation,
    required int index,
    required Widget child,
    Duration staggerDelay = const Duration(milliseconds: 50),
  }) {
    final delay = index * staggerDelay.inMilliseconds / 1000.0;
    
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final progress = math.max(0.0, (animation.value - delay) / (1.0 - delay));
        
        return Transform.translate(
          offset: Offset(0, 20 * (1 - progress)),
          child: Opacity(
            opacity: progress,
            child: RepaintBoundary(child: child),
          ),
        );
      },
    );
  }

  /// Create bouncy button animation
  static Widget createBouncyButton({
    required Widget child,
    required VoidCallback onPressed,
    Duration animationDuration = const Duration(milliseconds: 150),
  }) {
    return _BouncyButton(
      onPressed: onPressed,
      animationDuration: animationDuration,
      child: child,
    );
  }

  /// Create shimmer loading animation
  static Widget createShimmerLoading({
    required Widget child,
    Color baseColor = const Color(0xFFE0E0E0),
    Color highlightColor = const Color(0xFFF5F5F5),
    Duration period = const Duration(milliseconds: 1500),
  }) {
    return _ShimmerWidget(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: period,
      child: child,
    );
  }

  /// Get animation performance statistics
  static Map<String, dynamic> getPerformanceStats() {
    return {
      'dropped_frames': _droppedFrames,
      'animation_stats': Map<String, int>.from(_animationPerformanceStats),
      'target_fps': 60,
      'frame_budget_ms': 16.67,
    };
  }

  /// Reset performance statistics
  static void resetPerformanceStats() {
    _droppedFrames = 0;
    _animationPerformanceStats.clear();
  }
}

/// Bouncy button implementation
class _BouncyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Duration animationDuration;

  const _BouncyButton({
    required this.child,
    required this.onPressed,
    required this.animationDuration,
  });

  @override
  State<_BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<_BouncyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
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
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Shimmer loading animation implementation
class _ShimmerWidget extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration period;

  const _ShimmerWidget({
    required this.child,
    required this.baseColor,
    required this.highlightColor,
    required this.period,
  });

  @override
  State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<_ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.period,
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                math.max(0.0, _animation.value - 0.3),
                _animation.value,
                math.min(1.0, _animation.value + 0.3),
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Optimized animated container for kid-friendly UI
class OptimizedAnimatedContainer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Color? color;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Decoration? decoration;

  const OptimizedAnimatedContainer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.color,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.decoration,
  });

  @override
  State<OptimizedAnimatedContainer> createState() => _OptimizedAnimatedContainerState();
}

class _OptimizedAnimatedContainerState extends State<OptimizedAnimatedContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: widget.duration,
        curve: widget.curve,
        width: widget.width,
        height: widget.height,
        padding: widget.padding,
        margin: widget.margin,
        decoration: widget.decoration ??
            (widget.color != null
                ? BoxDecoration(color: widget.color)
                : null),
        child: widget.child,
      ),
    );
  }
}