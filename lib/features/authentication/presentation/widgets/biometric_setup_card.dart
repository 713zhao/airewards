import 'package:flutter/material.dart';
import '../bloc/auth_state.dart';

/// Card widget for biometric setup options
class BiometricSetupCard extends StatefulWidget {
  final BiometricType biometricType;
  final VoidCallback onTap;
  final bool isLoading;

  const BiometricSetupCard({
    super.key,
    required this.biometricType,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  State<BiometricSetupCard> createState() => _BiometricSetupCardState();
}

class _BiometricSetupCardState extends State<BiometricSetupCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.isLoading) {
      _animationController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  IconData _getIcon() {
    switch (widget.biometricType) {
      case BiometricType.fingerprint:
        return Icons.fingerprint;
      case BiometricType.face:
        return Icons.face;
      case BiometricType.iris:
        return Icons.remove_red_eye;
      case BiometricType.voice:
        return Icons.record_voice_over;
      case BiometricType.deviceCredentials:
        return Icons.lock;
    }
  }

  String _getTitle() {
    switch (widget.biometricType) {
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.face:
        return 'Face Recognition';
      case BiometricType.iris:
        return 'Iris Scan';
      case BiometricType.voice:
        return 'Voice Recognition';
      case BiometricType.deviceCredentials:
        return 'Device Credentials';
    }
  }

  String _getDescription() {
    switch (widget.biometricType) {
      case BiometricType.fingerprint:
        return 'Use your fingerprint to quickly and securely sign in';
      case BiometricType.face:
        return 'Use face recognition for hands-free authentication';
      case BiometricType.iris:
        return 'Use iris scanning for highly secure authentication';
      case BiometricType.voice:
        return 'Use your voice for convenient authentication';
      case BiometricType.deviceCredentials:
        return 'Use your device PIN, pattern, or password';
    }
  }

  Color _getPrimaryColor(ThemeData theme) {
    switch (widget.biometricType) {
      case BiometricType.fingerprint:
        return theme.colorScheme.primary;
      case BiometricType.face:
        return Colors.green;
      case BiometricType.iris:
        return Colors.purple;
      case BiometricType.voice:
        return Colors.orange;
      case BiometricType.deviceCredentials:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = _getPrimaryColor(theme);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            onTap: widget.isLoading ? null : widget.onTap,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: primaryColor.withOpacity(0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon Container
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: widget.isLoading
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                            ),
                          )
                        : Icon(
                            _getIcon(),
                            size: 30,
                            color: primaryColor,
                          ),
                  ),

                  const SizedBox(width: 16),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          _getTitle(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Description
                        Text(
                          _getDescription(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow Icon
                  if (!widget.isLoading)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}