import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/validators.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../bloc/auth_event.dart';
import '../widgets/auth_header.dart';
import '../widgets/social_login_button.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_loading_overlay.dart';

/// Login screen with Material Design 3 components and comprehensive authentication options
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isBiometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkBiometricAvailability();
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
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _checkBiometricAvailability() async {
    // Add biometric availability check
    // This would typically use local_auth package
    setState(() {
      _isBiometricAvailable = true; // Placeholder
    });
  }

  void _handleEmailSignIn() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthSignInWithEmailRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          rememberMe: _rememberMe,
        ),
      );
    }
  }

  void _handleGoogleSignIn() {
    context.read<AuthBloc>().add(const AuthSignInWithGoogleRequested());
  }

  void _handleBiometricSignIn() {
    context.read<AuthBloc>().add(const AuthSignInWithBiometricRequested());
  }

  void _handleForgotPassword() {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address first'),
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(
      AuthPasswordResetRequested(email: _emailController.text.trim()),
    );
  }

  void _navigateToRegister() {
    // TODO: Implement navigation to register screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Register screen will be implemented next'),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            // TODO: Navigate to dashboard
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Login successful!')),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
                action: SnackBarAction(
                  label: 'Dismiss',
                  onPressed: () =>
                      ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                ),
              ),
            );
          } else if (state is AuthOperationSuccess && 
                     state.operationType == AuthOperationType.passwordReset) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Password reset link sent to ${_emailController.text.trim()}',
                ),
                backgroundColor: theme.colorScheme.primary,
              ),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // Main Content
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: size.height * 0.05),

                          // Auth Header
                          const AuthHeader(
                            title: 'Welcome Back',
                            subtitle: 'Sign in to continue earning rewards',
                          ),

                          SizedBox(height: size.height * 0.04),

                          // Login Form
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Email Field
                                AuthTextField(
                                  controller: _emailController,
                                  label: 'Email',
                                  hint: 'Enter your email address',
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: Icons.email_outlined,
                                  validator: Validators.validateEmailForm,
                                  textInputAction: TextInputAction.next,
                                ),

                                const SizedBox(height: 16),

                                // Password Field
                                AuthTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  hint: 'Enter your password',
                                  obscureText: !_isPasswordVisible,
                                  prefixIcon: Icons.lock_outlined,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                  validator: Validators.validatePasswordForm,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _handleEmailSignIn(),
                                ),

                                const SizedBox(height: 12),

                                // Remember Me & Forgot Password Row
                                Row(
                                  children: [
                                    // Remember Me Checkbox
                                    Checkbox(
                                      value: _rememberMe,
                                      onChanged: (value) {
                                        setState(() {
                                          _rememberMe = value ?? false;
                                        });
                                      },
                                    ),
                                    Text(
                                      'Remember me',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    const Spacer(),
                                    // Forgot Password Link
                                    TextButton(
                                      onPressed: _handleForgotPassword,
                                      child: const Text('Forgot Password?'),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // Sign In Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: FilledButton(
                                    onPressed: state is AuthLoading
                                        ? null
                                        : _handleEmailSignIn,
                                    child: state is AuthLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'Sign In',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Divider
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: theme.colorScheme.outline
                                      .withOpacity(0.5),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'or continue with',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: theme.colorScheme.outline
                                      .withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Social Login Buttons
                          Row(
                            children: [
                              // Google Sign In
                              Expanded(
                                child: SocialLoginButton(
                                  icon: Icons.g_mobiledata,
                                  label: 'Google',
                                  onPressed: state is AuthLoading
                                      ? null
                                      : _handleGoogleSignIn,
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black87,
                                  borderColor: theme.colorScheme.outline,
                                ),
                              ),

                              if (_isBiometricAvailable) ...[
                                const SizedBox(width: 12),
                                // Biometric Sign In
                                Expanded(
                                  child: SocialLoginButton(
                                    icon: Icons.fingerprint,
                                    label: 'Biometric',
                                    onPressed: state is AuthLoading
                                        ? null
                                        : _handleBiometricSignIn,
                                    backgroundColor:
                                        theme.colorScheme.primaryContainer,
                                    foregroundColor:
                                        theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          SizedBox(height: size.height * 0.05),

                          // Sign Up Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              TextButton(
                                onPressed: _navigateToRegister,
                                child: const Text(
                                  'Sign Up',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: size.height * 0.02),

                          // Terms and Privacy
                          Text(
                            'By continuing, you agree to our Terms of Service and Privacy Policy',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Loading Overlay
              if (state is AuthLoading)
                const AuthLoadingOverlay(
                  message: 'Signing you in...',
                ),
            ],
          );
        },
      ),
    );
  }
}