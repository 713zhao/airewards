import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../bloc/auth_event.dart';
import '../widgets/auth_header.dart';
import '../widgets/biometric_setup_card.dart';

/// Biometric authentication setup screen with device capability detection
class BiometricSetupScreen extends StatefulWidget {
  final bool isOnboarding;
  final VoidCallback? onSkip;
  final VoidCallback? onComplete;

  const BiometricSetupScreen({
    super.key,
    this.isOnboarding = false,
    this.onSkip,
    this.onComplete,
  });

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  List<BiometricType> _availableBiometrics = [];
  bool _isCheckingCapability = true;
  bool _isSetupComplete = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkBiometricCapability();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _checkBiometricCapability() async {
    setState(() {
      _isCheckingCapability = true;
    });

    context.read<AuthBloc>().add(const AuthCheckBiometricAvailabilityRequested());

    // Simulate capability check delay
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isCheckingCapability = false;
      // Simulate available biometrics
      _availableBiometrics = [
        BiometricType.fingerprint,
        BiometricType.face,
      ];
    });
  }

  void _enableBiometric() {
    context.read<AuthBloc>().add(const AuthEnableBiometricRequested());
  }

  void _skip() {
    if (widget.onSkip != null) {
      widget.onSkip!();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _complete() {
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: widget.isOnboarding
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text('Biometric Setup'),
            ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthOperationSuccess &&
              state.operationType == AuthOperationType.biometricSetup) {
            setState(() {
              _isSetupComplete = true;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Biometric authentication enabled successfully!'),
                backgroundColor: theme.colorScheme.primary,
              ),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.isOnboarding) 
                        SizedBox(height: size.height * 0.05),

                      // Header
                      const AuthHeader(
                        title: 'Secure Your Account',
                        subtitle: 'Set up biometric authentication for quick and secure access to your rewards',
                      ),

                      SizedBox(height: size.height * 0.04),

                      // Content
                      Expanded(
                        child: _buildContent(context, theme, state),
                      ),

                      // Action Buttons
                      _buildActionButtons(context, theme, state),
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

  Widget _buildContent(BuildContext context, ThemeData theme, AuthState state) {
    if (_isCheckingCapability) {
      return _buildCheckingCapability(theme);
    }

    if (_availableBiometrics.isEmpty) {
      return _buildNoBiometrics(theme);
    }

    if (_isSetupComplete) {
      return _buildSetupComplete(theme);
    }

    return _buildBiometricOptions(theme, state);
  }

  Widget _buildCheckingCapability(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text(
          'Checking device capabilities...',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildNoBiometrics(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.security_outlined,
          size: 100,
          color: theme.colorScheme.outline,
        ),
        const SizedBox(height: 24),
        Text(
          'Biometric Not Available',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Your device doesn\'t support biometric authentication or no biometric credentials are enrolled.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You can set up biometric authentication later in Settings',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSetupComplete(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check,
            size: 50,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Setup Complete!',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Biometric authentication has been enabled successfully. You can now use it to quickly access your account.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildBiometricOptions(ThemeData theme, AuthState state) {
    return Column(
      children: [
        // Biometric Cards
        ..._availableBiometrics.map((biometric) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: BiometricSetupCard(
            biometricType: biometric,
            onTap: _enableBiometric,
            isLoading: state is AuthLoading &&
                       state.operationType == AuthOperationType.biometricSetup,
          ),
        )),

        const SizedBox(height: 24),

        // Security Info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.security,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Security Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '• Biometric data is stored securely on your device\n'
                '• We never have access to your biometric information\n'
                '• You can disable this feature at any time in Settings',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme, AuthState state) {
    if (_isCheckingCapability) {
      return const SizedBox.shrink();
    }

    if (_isSetupComplete) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton(
          onPressed: _complete,
          child: const Text(
            'Continue',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Skip Button (if onboarding)
        if (widget.isOnboarding) ...[
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: _skip,
              child: const Text(
                'Skip for Now',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Enable Later Button (if available biometrics)
        if (_availableBiometrics.isNotEmpty && !widget.isOnboarding)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: TextButton(
              onPressed: _skip,
              child: const Text(
                'Maybe Later',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

        // Close Button (if no biometrics)
        if (_availableBiometrics.isEmpty)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: _skip,
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}