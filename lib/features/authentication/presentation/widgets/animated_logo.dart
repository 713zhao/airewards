import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animated logo widget with particle effects and smooth animations
class AnimatedLogo extends StatefulWidget {
  final double size;
  final Color? color;
  final Duration duration;
  final bool showParticles;

  const AnimatedLogo({
    super.key,
    this.size = 120.0,
    this.color,
    this.duration = const Duration(seconds: 2),
    this.showParticles = true,
  });

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    // Rotation animation
    _rotationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));

    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeOut,
    ));
  }

  void _startAnimations() {
    // Start rotation
    _rotationController.repeat();
    
    // Start pulse animation with repeat
    _pulseController.repeat(reverse: true);
    
    // Start particle animation
    if (widget.showParticles) {
      _particleController.repeat();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logoColor = widget.color ?? theme.colorScheme.primary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Particle effects (background)
          if (widget.showParticles)
            AnimatedBuilder(
              animation: _particleAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: ParticlePainter(
                    animation: _particleAnimation.value,
                    color: logoColor.withOpacity(0.3),
                  ),
                );
              },
            ),

          // Outer glow ring
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: widget.size * _pulseAnimation.value,
                height: widget.size * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: logoColor.withOpacity(0.3),
                      blurRadius: 20.0,
                      spreadRadius: 5.0,
                    ),
                  ],
                ),
              );
            },
          ),

          // Main logo container
          AnimatedBuilder(
            animation: Listenable.merge([_rotationAnimation, _pulseAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value * 0.8,
                child: Transform.rotate(
                  angle: _rotationAnimation.value * 2 * math.pi,
                  child: Container(
                    width: widget.size * 0.7,
                    height: widget.size * 0.7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          logoColor.withOpacity(0.9),
                          logoColor,
                          logoColor.withOpacity(0.7),
                        ],
                        stops: const [0.0, 0.7, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: logoColor.withOpacity(0.5),
                          blurRadius: 15.0,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.stars,
                      size: widget.size * 0.35,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),

          // Inner sparkle effects
          AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: -_rotationAnimation.value * 2 * math.pi,
                child: CustomPaint(
                  size: Size(widget.size * 0.6, widget.size * 0.6),
                  painter: SparklePainter(
                    animation: _rotationAnimation.value,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Custom painter for particle effects around the logo
class ParticlePainter extends CustomPainter {
  final double animation;
  final Color color;
  final int particleCount = 12;

  ParticlePainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * math.pi;
      final animationOffset = (animation + (i / particleCount)) % 1.0;
      
      // Calculate particle position
      final distance = radius * 0.8 * (0.5 + 0.5 * math.sin(animationOffset * 2 * math.pi));
      final x = center.dx + distance * math.cos(angle);
      final y = center.dy + distance * math.sin(angle);
      
      // Calculate particle size based on animation
      final particleSize = 3.0 * (0.5 + 0.5 * math.sin(animationOffset * math.pi));
      
      // Draw particle
      canvas.drawCircle(
        Offset(x, y),
        particleSize,
        paint..color = color.withOpacity(0.7 * (1.0 - animationOffset)),
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

/// Custom painter for sparkle effects inside the logo
class SparklePainter extends CustomPainter {
  final double animation;
  final Color color;
  final int sparkleCount = 6;

  SparklePainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    for (int i = 0; i < sparkleCount; i++) {
      final angle = (i / sparkleCount) * 2 * math.pi + animation * 2 * math.pi;
      final animationOffset = (animation * 2 + (i / sparkleCount)) % 1.0;
      
      // Calculate sparkle position
      final distance = radius * (0.3 + 0.4 * math.sin(animationOffset * 2 * math.pi));
      final x = center.dx + distance * math.cos(angle);
      final y = center.dy + distance * math.sin(angle);
      
      // Draw sparkle
      _drawSparkle(canvas, Offset(x, y), paint, animationOffset);
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, Paint paint, double animation) {
    final sparkleSize = 2.0 + 3.0 * math.sin(animation * math.pi);
    
    // Draw four-pointed star
    final path = Path();
    
    // Vertical line
    path.moveTo(center.dx, center.dy - sparkleSize);
    path.lineTo(center.dx, center.dy + sparkleSize);
    
    // Horizontal line
    path.moveTo(center.dx - sparkleSize, center.dy);
    path.lineTo(center.dx + sparkleSize, center.dy);
    
    // Set stroke properties
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.5;
    paint.strokeCap = StrokeCap.round;
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SparklePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}