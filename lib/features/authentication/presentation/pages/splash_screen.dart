import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/services/analytics_service.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/animated_logo.dart';

/// Splash screen with app initialization, authentication check, and navigation
@injectable
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _fadeController;
  late final Animation<double> _logoScale;
  late final Animation<double> _fadeAnimation;
  
  bool _initializationComplete = false;
  bool _minimumTimeElapsed = false;
  String _loadingMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startInitialization();
  }

  void _setupAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _logoController.forward();
    _fadeController.forward();
  }

  void _startInitialization() async {
    // Ensure minimum splash time for branding
    Future.delayed(AppConstants.minimumSplashDuration, () {
      if (mounted) {
        setState(() {
          _minimumTimeElapsed = true;
        });
        _checkNavigationReady();
      }
    });

    try {
      // Initialize core services
      await _initializeServices();
      
      if (mounted) {
        setState(() {
          _initializationComplete = true;
          _loadingMessage = 'Ready!';
        });
        _checkNavigationReady();
      }
    } catch (e) {
      if (mounted) {
        _handleInitializationError(e);
      }
    }
  }

  Future<void> _initializeServices() async {
    // Update loading message
    if (mounted) {
      setState(() => _loadingMessage = 'Setting up services...');
    }

    // Initialize analytics
    await getIt<AnalyticsService>().initialize();
    
    // Check authentication state
    if (mounted) {
      setState(() => _loadingMessage = 'Checking authentication...');
    }
    
    // Trigger auth state check
    context.read<AuthBloc>().add(const AuthCheckRequested());
    
    // Initialize other core services
    if (mounted) {
      setState(() => _loadingMessage = 'Finalizing...');
    }
    
    // Small delay to show final message
    await Future.delayed(const Duration(milliseconds: 300));
  }

  void _checkNavigationReady() {
    if (_initializationComplete && _minimumTimeElapsed) {
      _navigateBasedOnAuthState();
    }
  }

  void _navigateBasedOnAuthState() {
    final authState = context.read<AuthBloc>().state;
    
    // Small delay for smooth transition
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      if (authState is AuthAuthenticated) {
        // User is authenticated, go to main app
        context.go('/dashboard');
      } else if (authState is AuthUnauthenticated) {
        // User not authenticated, go to login
        context.go('/login');
      } else {
        // Still loading, listen for auth changes
        _listenForAuthStateChanges();
      }
    });
  }

  void _listenForAuthStateChanges() {
    // Listen for auth state changes and navigate accordingly
    final authBloc = context.read<AuthBloc>();
    
    authBloc.stream.listen((state) {
      if (!mounted) return;
      
      if (state is AuthAuthenticated) {
        context.go('/dashboard');
      } else if (state is AuthUnauthenticated) {
        context.go('/login');
      } else if (state is AuthError) {
        _handleAuthError(state.message);
      }
    });
  }

  void _handleInitializationError(dynamic error) {
    setState(() {
      _loadingMessage = 'Initialization failed';
    });
    
    // Show error dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Initialization Error'),
        content: Text(
          'Failed to initialize the app. Please restart the application.\n\nError: ${error.toString()}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startInitialization(); // Retry
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _handleAuthError(String message) {
    // Navigate to login on auth error
    context.go('/login');
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primaryContainer,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              
              // Animated Logo Section
              ScaleTransition(
                scale: _logoScale,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // App Logo
                      Container(
                        width: size.width * 0.3,
                        height: size.width * 0.3,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.stars,
                          size: size.width * 0.15,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // App Name
                      Text(
                        AppConstants.appName,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // App Tagline
                      Text(
                        'Earn • Track • Redeem',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimary.withOpacity(0.8),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(flex: 2),
              
              // Loading Section
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Loading Animation
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.onPrimary,
                        ),
                        strokeWidth: 3.0,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Loading Message
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _loadingMessage,
                        key: ValueKey(_loadingMessage),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onPrimary.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Version Info
              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Text(
                    'Version ${AppConstants.appVersion}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimary.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// BLoC listener wrapper for splash screen navigation
class SplashScreenWrapper extends StatelessWidget {
  const SplashScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Handle navigation based on auth state changes
        if (state is AuthAuthenticated) {
          // User authenticated, go to main app
          context.go('/dashboard');
        } else if (state is AuthUnauthenticated) {
          // User not authenticated, go to login
          context.go('/login');
        }
      },
      child: const SplashScreen(),
    );
  }
}