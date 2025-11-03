import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Loading overlay for authentication operations with animated spinner
class AuthLoadingOverlay extends StatefulWidget {
  final String message;
  final Color? backgroundColor;
  final Color? spinnerColor;

  const AuthLoadingOverlay({
    super.key,
    required this.message,
    this.backgroundColor,
    this.spinnerColor,
  });

  @override
  State<AuthLoadingOverlay> createState() => _AuthLoadingOverlayState();
}

class _AuthLoadingOverlayState extends State<AuthLoadingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _spinController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _spinAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _spinController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _spinAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: Curves.linear,
    ));

    _fadeController.forward();
    _spinController.repeat();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: widget.backgroundColor ?? 
            theme.colorScheme.surface.withOpacity(0.8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32.0),
            margin: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.2),
                  blurRadius: 20.0,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Custom Loading Spinner
                AnimatedBuilder(
                  animation: _spinAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(60, 60),
                      painter: LoadingSpinnerPainter(
                        progress: _spinAnimation.value,
                        color: widget.spinnerColor ?? theme.colorScheme.primary,
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Loading Message
                Text(
                  widget.message,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                // Subtitle
                Text(
                  'Please wait...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the loading spinner
class LoadingSpinnerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final int segments = 8;

  LoadingSpinnerPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < segments; i++) {
      final angle = (i / segments) * 2 * math.pi + progress;
      final opacity = (i / segments);
      
      paint.color = color.withOpacity(opacity);
      
      final startX = center.dx + (radius - 8) * math.cos(angle);
      final startY = center.dy + (radius - 8) * math.sin(angle);
      final endX = center.dx + radius * math.cos(angle);
      final endY = center.dy + radius * math.sin(angle);
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(LoadingSpinnerPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}