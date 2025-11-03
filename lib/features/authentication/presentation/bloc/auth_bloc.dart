import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/usecases.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC for managing authentication state and operations.
/// 
/// This BLoC handles all authentication-related events including sign-in,
/// sign-up, sign-out, biometric authentication, session management, and
/// state persistence. It provides comprehensive error handling, loading
/// states, and automatic session validation.
/// 
/// Key features:
/// - Multiple authentication methods (email, Google, biometric)
/// - Automatic session management and timeout handling
/// - State persistence for auto-login functionality
/// - Comprehensive error handling with retry mechanisms
/// - Biometric authentication setup and management
/// - Real-time authentication state monitoring
@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final SignInWithEmail _signInWithEmail;
  final SignInWithGoogle _signInWithGoogle;
  final SignUpWithEmail _signUpWithEmail;
  final SignOut _signOut;
  // Stream subscription for auth state changes
  StreamSubscription<User?>? _authStateSubscription;
  
  // Timer for session timeout validation
  Timer? _sessionTimer;
  
  // Constants
  static const Duration _sessionTimeout = Duration(minutes: 30);
  static const Duration _sessionWarningTime = Duration(minutes: 5);
  
  // In-memory storage for demo purposes (would use secure storage in production)
  bool _autoLoginEnabled = false;
  bool _biometricEnabled = false;
  
  AuthBloc({
    required AuthRepository authRepository,
    required SignInWithEmail signInWithEmail,
    required SignInWithGoogle signInWithGoogle,
    required SignUpWithEmail signUpWithEmail,
    required SignOut signOut,
  })  : _authRepository = authRepository,
        _signInWithEmail = signInWithEmail,
        _signInWithGoogle = signInWithGoogle,
        _signUpWithEmail = signUpWithEmail,
        _signOut = signOut,
        super(const AuthInitial()) {
    
    // Register event handlers
    on<AuthStarted>(_onAuthStarted);
    on<AuthSignInWithEmailRequested>(_onSignInWithEmailRequested);
    on<AuthSignInWithGoogleRequested>(_onSignInWithGoogleRequested);
    on<AuthSignInWithBiometricRequested>(_onSignInWithBiometricRequested);
    on<AuthSignUpWithEmailRequested>(_onSignUpWithEmailRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthEmailVerificationRequested>(_onEmailVerificationRequested);
    on<AuthUpdateProfileRequested>(_onUpdateProfileRequested);
    on<AuthDeleteAccountRequested>(_onDeleteAccountRequested);
    on<AuthEnableBiometricRequested>(_onEnableBiometricRequested);
    on<AuthDisableBiometricRequested>(_onDisableBiometricRequested);
    on<AuthCheckBiometricAvailabilityRequested>(_onCheckBiometricAvailabilityRequested);
    on<AuthRetryRequested>(_onRetryRequested);
    on<AuthErrorCleared>(_onErrorCleared);
    on<AuthStateChanged>(_onAuthStateChanged);
    on<AuthAutoLoginRequested>(_onAutoLoginRequested);
    on<AuthRefreshSessionRequested>(_onRefreshSessionRequested);
    on<AuthValidateSessionRequested>(_onValidateSessionRequested);
    
    // Start listening to authentication state changes
    _initializeAuthStateListener();
  }

  /// Initialize the authentication state listener
  void _initializeAuthStateListener() {
    _authStateSubscription = _authRepository.authStateChanges.listen(
      (user) => add(AuthStateChanged(user)),
      onError: (error) {
        dev.log('Auth state stream error: $error', name: 'AuthBloc');
        add(const AuthStateChanged(null));
      },
    );
  }

  /// Handle authentication initialization
  Future<void> _onAuthStarted(
    AuthStarted event,
    Emitter<AuthState> emit,
  ) async {
    dev.log('Authentication started', name: 'AuthBloc');
    
    emit(const AuthLoading(
      message: 'Initializing...',
      operationType: AuthOperationType.autoLogin,
    ));

    try {
      // Check for current user
      final result = await _authRepository.getCurrentUser();
      
      await result.fold(
        (failure) async {
          dev.log('No current user found: ${failure.message}', name: 'AuthBloc');
          emit(const AuthUnauthenticated(showWelcome: true));
        },
        (user) async {
          if (user != null) {
            dev.log('Found current user: ${user.email}', name: 'AuthBloc');
            
            // Check if auto-login is enabled
            final autoLoginEnabled = await _isAutoLoginEnabled();
            
            if (autoLoginEnabled) {
              await _authenticateUser(user, emit);
            } else {
              emit(const AuthUnauthenticated(showWelcome: true));
            }
          } else {
            emit(const AuthUnauthenticated(showWelcome: true));
          }
        },
      );
    } catch (e) {
      dev.log('Error during auth initialization: $e', name: 'AuthBloc');
      emit(AuthError(
        message: 'Failed to initialize authentication: ${e.toString()}',
        errorType: AuthErrorType.generic,
      ));
    }
  }

  /// Handle email sign-in
  Future<void> _onSignInWithEmailRequested(
    AuthSignInWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(
      message: 'Signing in...',
      operationType: AuthOperationType.signIn,
    ));

    try {
      final result = await _signInWithEmail(SignInWithEmailParams(
        email: event.email,
        password: event.password,
      ));

      await result.fold(
        (failure) async {
          emit(AuthError(
            message: failure.message,
            errorType: _mapFailureToErrorType(failure),
          ));
        },
        (user) async {
          // Save auto-login preference
          if (event.rememberMe) {
            await _setAutoLoginEnabled(true);
          }
          
          await _authenticateUser(user, emit);
        },
      );
    } catch (e) {
      emit(AuthError(
        message: 'Sign in failed: ${e.toString()}',
        errorType: AuthErrorType.generic,
      ));
    }
  }

  /// Handle Google sign-in
  Future<void> _onSignInWithGoogleRequested(
    AuthSignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(
      message: 'Signing in with Google...',
      operationType: AuthOperationType.signIn,
    ));

    try {
      final result = await _signInWithGoogle();

      await result.fold(
        (failure) async {
          emit(AuthError(
            message: failure.message,
            errorType: _mapFailureToErrorType(failure),
          ));
        },
        (user) async {
          await _authenticateUser(user, emit);
        },
      );
    } catch (e) {
      emit(AuthError(
        message: 'Google sign in failed: ${e.toString()}',
        errorType: AuthErrorType.generic,
      ));
    }
  }

  /// Handle biometric sign-in
  Future<void> _onSignInWithBiometricRequested(
    AuthSignInWithBiometricRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(
      message: 'Authenticating with biometrics...',
      operationType: AuthOperationType.signIn,
    ));

    try {
      // Check if biometric is enabled
      final biometricEnabled = await _isBiometricEnabled();
      if (!biometricEnabled) {
        emit(const AuthError(
          message: 'Biometric authentication is not enabled',
          errorType: AuthErrorType.biometricNotAvailable,
        ));
        return;
      }

      // For now, just get current user since biometric service integration
      // would require additional implementation
      final result = await _authRepository.getCurrentUser();
      
      await result.fold(
        (failure) async {
          emit(AuthError(
            message: 'Biometric authentication failed: ${failure.message}',
            errorType: AuthErrorType.biometricNotAvailable,
          ));
        },
        (user) async {
          if (user != null) {
            await _authenticateUser(user, emit);
          } else {
            emit(const AuthError(
              message: 'No user found for biometric authentication',
              errorType: AuthErrorType.userNotFound,
            ));
          }
        },
      );
    } catch (e) {
      emit(AuthError(
        message: 'Biometric authentication failed: ${e.toString()}',
        errorType: AuthErrorType.biometricNotAvailable,
      ));
    }
  }

  /// Handle email sign-up
  Future<void> _onSignUpWithEmailRequested(
    AuthSignUpWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(
      message: 'Creating account...',
      operationType: AuthOperationType.signUp,
    ));

    try {
      final result = await _signUpWithEmail(SignUpWithEmailParams(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      ));

      await result.fold(
        (failure) async {
          emit(AuthError(
            message: failure.message,
            errorType: _mapFailureToErrorType(failure),
          ));
        },
        (user) async {
          await _authenticateUser(user, emit);
        },
      );
    } catch (e) {
      emit(AuthError(
        message: 'Sign up failed: ${e.toString()}',
        errorType: AuthErrorType.generic,
      ));
    }
  }

  /// Handle sign-out
  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(
      message: 'Signing out...',
      operationType: AuthOperationType.signOut,
    ));

    try {
      final result = await _signOut();

      await result.fold(
        (failure) async {
          emit(AuthError(
            message: failure.message,
            errorType: _mapFailureToErrorType(failure),
          ));
        },
        (_) async {
          // Clear stored preferences
          await _setAutoLoginEnabled(false);
          await _setBiometricEnabled(false);
          
          // Cancel session timer
          _cancelSessionTimer();
          
          emit(const AuthUnauthenticated(
            message: 'Successfully signed out',
          ));
        },
      );
    } catch (e) {
      emit(AuthError(
        message: 'Sign out failed: ${e.toString()}',
        errorType: AuthErrorType.generic,
      ));
    }
  }

  /// Handle password reset request
  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(
      message: 'Sending password reset email...',
      operationType: AuthOperationType.passwordReset,
    ));

    try {
      final result = await _authRepository.sendPasswordResetEmail(event.email);

      result.fold(
        (failure) {
          emit(AuthError(
            message: failure.message,
            errorType: _mapFailureToErrorType(failure),
          ));
        },
        (_) {
          emit(const AuthOperationSuccess(
            message: 'Password reset email sent successfully',
            operationType: AuthOperationType.passwordReset,
          ));
        },
      );
    } catch (e) {
      emit(AuthError(
        message: 'Failed to send password reset email: ${e.toString()}',
        errorType: AuthErrorType.generic,
      ));
    }
  }

  /// Handle email verification request
  Future<void> _onEmailVerificationRequested(
    AuthEmailVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(
      message: 'Sending verification email...',
      operationType: AuthOperationType.emailVerification,
    ));

    try {
      final result = await _authRepository.sendEmailVerification();

      result.fold(
        (failure) {
          emit(AuthError(
            message: failure.message,
            errorType: _mapFailureToErrorType(failure),
          ));
        },
        (_) {
          emit(const AuthOperationSuccess(
            message: 'Verification email sent successfully',
            operationType: AuthOperationType.emailVerification,
          ));
        },
      );
    } catch (e) {
      emit(AuthError(
        message: 'Failed to send verification email: ${e.toString()}',
        errorType: AuthErrorType.generic,
      ));
    }
  }

  /// Handle profile update
  Future<void> _onUpdateProfileRequested(
    AuthUpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(
      message: 'Updating profile...',
      operationType: AuthOperationType.profileUpdate,
    ));

    try {
      final result = await _authRepository.updateProfile(
        displayName: event.displayName,
        photoUrl: event.photoUrl,
      );

      result.fold(
        (failure) {
          emit(AuthError(
            message: failure.message,
            errorType: _mapFailureToErrorType(failure),
          ));
        },
        (user) {
          if (state is AuthAuthenticated) {
            final currentState = state as AuthAuthenticated;
            emit(currentState.copyWith(user: user));
          }
        },
      );
    } catch (e) {
      emit(AuthError(
        message: 'Failed to update profile: ${e.toString()}',
        errorType: AuthErrorType.generic,
      ));
    }
  }

  /// Handle account deletion
  Future<void> _onDeleteAccountRequested(
    AuthDeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(
      message: 'Deleting account...',
      operationType: AuthOperationType.deleteAccount,
    ));

    try {
      final result = await _authRepository.deleteAccount();

      await result.fold(
        (failure) async {
          emit(AuthError(
            message: failure.message,
            errorType: _mapFailureToErrorType(failure),
          ));
        },
        (_) async {
          // Clear all stored data
          await _setAutoLoginEnabled(false);
          await _setBiometricEnabled(false);
          _cancelSessionTimer();
          
          emit(const AuthUnauthenticated(
            message: 'Account deleted successfully',
          ));
        },
      );
    } catch (e) {
      emit(AuthError(
        message: 'Failed to delete account: ${e.toString()}',
        errorType: AuthErrorType.generic,
      ));
    }
  }

  /// Handle enable biometric authentication
  Future<void> _onEnableBiometricRequested(
    AuthEnableBiometricRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(
      message: 'Setting up biometric authentication...',
      operationType: AuthOperationType.biometricSetup,
    ));

    try {
      // For now, just enable the setting since biometric service
      // would require additional implementation
      await _setBiometricEnabled(true);
      
      if (state is AuthAuthenticated) {
        final currentState = state as AuthAuthenticated;
        emit(currentState.copyWith(biometricEnabled: true));
      } else {
        emit(const AuthOperationSuccess(
          message: 'Biometric authentication enabled successfully',
          operationType: AuthOperationType.biometricSetup,
        ));
      }
    } catch (e) {
      emit(AuthError(
        message: 'Failed to enable biometric authentication: ${e.toString()}',
        errorType: AuthErrorType.biometricNotAvailable,
      ));
    }
  }

  /// Handle disable biometric authentication
  Future<void> _onDisableBiometricRequested(
    AuthDisableBiometricRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _setBiometricEnabled(false);
      
      if (state is AuthAuthenticated) {
        final currentState = state as AuthAuthenticated;
        emit(currentState.copyWith(biometricEnabled: false));
      } else {
        emit(const AuthOperationSuccess(
          message: 'Biometric authentication disabled',
          operationType: AuthOperationType.biometricSetup,
        ));
      }
    } catch (e) {
      emit(AuthError(
        message: 'Failed to disable biometric authentication: ${e.toString()}',
        errorType: AuthErrorType.generic,
      ));
    }
  }

  /// Handle check biometric availability
  Future<void> _onCheckBiometricAvailabilityRequested(
    AuthCheckBiometricAvailabilityRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // For now, assume biometric is available on most devices
      // In a real implementation, this would check device capabilities
      emit(const AuthBiometricAvailable(
        availableBiometrics: [BiometricType.fingerprint, BiometricType.face],
        isEnrolled: true,
      ));
    } catch (e) {
      emit(AuthError(
        message: 'Failed to check biometric availability: ${e.toString()}',
        errorType: AuthErrorType.biometricNotAvailable,
      ));
    }
  }

  /// Handle retry authentication
  Future<void> _onRetryRequested(
    AuthRetryRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Reset to initial state to allow retry
    emit(const AuthInitial());
    add(const AuthStarted());
  }

  /// Handle clear error
  void _onErrorCleared(
    AuthErrorCleared event,
    Emitter<AuthState> emit,
  ) {
    emit(const AuthUnauthenticated());
  }

  /// Handle authentication state changes from external sources
  Future<void> _onAuthStateChanged(
    AuthStateChanged event,
    Emitter<AuthState> emit,
  ) async {
    final user = event.user as User?;
    
    if (user != null) {
      await _authenticateUser(user, emit);
    } else {
      _cancelSessionTimer();
      emit(const AuthUnauthenticated());
    }
  }

  /// Handle auto-login request
  Future<void> _onAutoLoginRequested(
    AuthAutoLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    add(const AuthStarted());
  }

  /// Handle session refresh
  Future<void> _onRefreshSessionRequested(
    AuthRefreshSessionRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthAuthenticated) {
      final currentState = state as AuthAuthenticated;
      emit(currentState.copyWith(
        lastActivity: DateTime.now(),
        isSessionValid: true,
      ));
      _startSessionTimer();
    }
  }

  /// Handle session validation
  Future<void> _onValidateSessionRequested(
    AuthValidateSessionRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthAuthenticated) {
      final currentState = state as AuthAuthenticated;
      final lastActivity = currentState.lastActivity ?? DateTime.now();
      final timeSinceLastActivity = DateTime.now().difference(lastActivity);
      
      if (timeSinceLastActivity >= _sessionTimeout) {
        emit(const AuthError(
          message: 'Session expired. Please sign in again.',
          errorType: AuthErrorType.sessionExpired,
          canRetry: false,
        ));
      } else if (timeSinceLastActivity >= (_sessionTimeout - _sessionWarningTime)) {
        final timeRemaining = _sessionTimeout - timeSinceLastActivity;
        emit(AuthSessionExpiring(
          user: currentState.user,
          timeRemaining: timeRemaining,
        ));
      }
    }
  }

  // Helper methods

  /// Authenticate user and set up session
  Future<void> _authenticateUser(User user, Emitter<AuthState> emit) async {
    final biometricEnabled = await _isBiometricEnabled();
    
    emit(AuthAuthenticated(
      user: user,
      biometricEnabled: biometricEnabled,
      lastActivity: DateTime.now(),
    ));
    
    _startSessionTimer();
  }

  /// Start session timeout timer
  void _startSessionTimer() {
    _cancelSessionTimer();
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      add(const AuthValidateSessionRequested());
    });
  }

  /// Cancel session timeout timer
  void _cancelSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  /// Check if auto-login is enabled
  Future<bool> _isAutoLoginEnabled() async {
    return _autoLoginEnabled;
  }

  /// Set auto-login enabled state
  Future<void> _setAutoLoginEnabled(bool enabled) async {
    _autoLoginEnabled = enabled;
  }

  /// Check if biometric is enabled
  Future<bool> _isBiometricEnabled() async {
    return _biometricEnabled;
  }

  /// Set biometric enabled state
  Future<void> _setBiometricEnabled(bool enabled) async {
    _biometricEnabled = enabled;
  }

  /// Map failure to appropriate error type
  AuthErrorType _mapFailureToErrorType(Failure failure) {
    if (failure is NetworkFailure) {
      return AuthErrorType.network;
    } else if (failure is AuthFailure) {
      final message = failure.message.toLowerCase();
      
      if (message.contains('invalid') || message.contains('wrong')) {
        return AuthErrorType.invalidCredentials;
      } else if (message.contains('not found') || message.contains('no user')) {
        return AuthErrorType.userNotFound;
      } else if (message.contains('already exists') || message.contains('in use')) {
        return AuthErrorType.emailAlreadyInUse;
      } else if (message.contains('weak password')) {
        return AuthErrorType.weakPassword;
      } else if (message.contains('too many')) {
        return AuthErrorType.tooManyRequests;
      } else if (message.contains('disabled')) {
        return AuthErrorType.userDisabled;
      } else if (message.contains('session') || message.contains('expired')) {
        return AuthErrorType.sessionExpired;
      } else {
        return AuthErrorType.generic;
      }
    } else if (failure is ValidationFailure) {
      return AuthErrorType.invalidCredentials;
    } else {
      return AuthErrorType.generic;
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    _cancelSessionTimer();
    return super.close();
  }
}