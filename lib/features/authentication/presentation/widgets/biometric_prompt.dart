import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Biometric authentication prompt widget
class BiometricPrompt extends StatefulWidget {
  final String title;
  final String subtitle;
  final String description;
  final VoidCallback? onCancel;
  final Function(bool success)? onResult;
  final bool showFallback;

  const BiometricPrompt({
    super.key,
    this.title = 'Biometric Authentication',
    this.subtitle = 'Use your biometric to authenticate',
    this.description = 'Place your finger on the sensor or look at the camera',
    this.onCancel,
    this.onResult,
    this.showFallback = true,
  });

  @override
  State<BiometricPrompt> createState() => _BiometricPromptState();
}

class _BiometricPromptState extends State<BiometricPrompt>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;
  
  bool _isAuthenticating = false;
  bool _hasFailed = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAuthentication();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _shakeAnimation = Tween<double>(
      begin: -5.0,
      end: 5.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    _pulseController.repeat(reverse: true);
  }

  Future<void> _startAuthentication() async {
    setState(() {
      _isAuthenticating = true;
      _statusMessage = 'Waiting for biometric...';
    });

    try {
      // Simulate biometric authentication
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate random success/failure for demo
      final success = DateTime.now().millisecondsSinceEpoch % 3 != 0;
      
      if (success) {
        _onAuthSuccess();
      } else {
        _onAuthFailure('Authentication failed. Please try again.');
      }
    } catch (e) {
      _onAuthFailure('Biometric authentication error: ${e.toString()}');
    }
  }

  void _onAuthSuccess() {
    setState(() {
      _isAuthenticating = false;
      _hasFailed = false;
      _statusMessage = 'Authentication successful!';
    });

    _pulseController.stop();
    
    // Call result callback
    widget.onResult?.call(true);
    
    // Auto-close after success
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    });
  }

  void _onAuthFailure(String error) {
    setState(() {
      _isAuthenticating = false;
      _hasFailed = true;
      _statusMessage = error;
    });

    _pulseController.stop();
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });

    // Provide haptic feedback
    HapticFeedback.heavyImpact();
    
    // Call result callback
    widget.onResult?.call(false);
  }

  void _retry() {
    setState(() {
      _hasFailed = false;
    });
    _startAuthentication();
  }

  void _useFallback() {
    Navigator.of(context).pop('fallback');
  }

  void _cancel() {
    widget.onCancel?.call();
    Navigator.of(context).pop(false);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Text(
              widget.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              widget.subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Biometric Icon with Animation
            AnimatedBuilder(
              animation: Listenable.merge([_pulseAnimation, _shakeAnimation]),
              builder: (context, child) {
                return Transform.translate(
                  offset: _hasFailed 
                      ? Offset(_shakeAnimation.value, 0)
                      : Offset.zero,
                  child: Transform.scale(
                    scale: _isAuthenticating ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getIconBackgroundColor(theme),
                        boxShadow: [
                          BoxShadow(
                            color: _getIconColor(theme).withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _getIconData(),
                        size: 40,
                        color: _getIconColor(theme),
                      ),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Status Message
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _statusMessage,
                key: ValueKey(_statusMessage),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _hasFailed 
                      ? theme.colorScheme.error 
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Description
            Text(
              widget.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Action Buttons
            _buildActionButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    if (_isAuthenticating) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _cancel,
              child: const Text('Cancel'),
            ),
          ),
        ],
      );
    }

    if (_hasFailed) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _retry,
                  child: const Text('Try Again'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _cancel,
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
          
          if (widget.showFallback) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: _useFallback,
              child: const Text('Use Password Instead'),
            ),
          ],
        ],
      );
    }

    // Success state or default
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _cancel,
            child: const Text('Close'),
          ),
        ),
      ],
    );
  }

  IconData _getIconData() {
    if (_hasFailed) {
      return Icons.error_outline;
    }
    
    if (!_isAuthenticating && _statusMessage.contains('successful')) {
      return Icons.check_circle_outline;
    }
    
    return Icons.fingerprint;
  }

  Color _getIconColor(ThemeData theme) {
    if (_hasFailed) {
      return theme.colorScheme.error;
    }
    
    if (!_isAuthenticating && _statusMessage.contains('successful')) {
      return Colors.green;
    }
    
    return theme.colorScheme.primary;
  }

  Color _getIconBackgroundColor(ThemeData theme) {
    if (_hasFailed) {
      return theme.colorScheme.error.withOpacity(0.1);
    }
    
    if (!_isAuthenticating && _statusMessage.contains('successful')) {
      return Colors.green.withOpacity(0.1);
    }
    
    return theme.colorScheme.primary.withOpacity(0.1);
  }
}

/// Helper function to show biometric prompt dialog
Future<dynamic> showBiometricPrompt({
  required BuildContext context,
  String title = 'Biometric Authentication',
  String subtitle = 'Use your biometric to authenticate',
  String description = 'Place your finger on the sensor or look at the camera',
  bool showFallback = true,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => BiometricPrompt(
      title: title,
      subtitle: subtitle,
      description: description,
      showFallback: showFallback,
    ),
  );
}