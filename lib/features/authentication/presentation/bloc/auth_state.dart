import 'package:equatable/equatable.dart';

import '../../domain/entities/user.dart';

/// Base class for all authentication states
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];

  /// Helper to check if authentication is in progress
  bool get isLoading => this is AuthLoading;

  /// Helper to check if user is authenticated
  bool get isAuthenticated => this is AuthAuthenticated;

  /// Helper to check if user is unauthenticated
  bool get isUnauthenticated => this is AuthUnauthenticated;

  /// Helper to check if there's an error
  bool get hasError => this is AuthError;

  /// Helper to get current user if authenticated
  User? get user => this is AuthAuthenticated 
      ? (this as AuthAuthenticated).user 
      : null;
}

/// Initial authentication state before any operations
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// State when authentication operation is in progress
class AuthLoading extends AuthState {
  final String? message;
  final AuthOperationType operationType;

  const AuthLoading({
    this.message,
    this.operationType = AuthOperationType.signIn,
  });

  @override
  List<Object?> get props => [message, operationType];
}

/// State when user is authenticated
class AuthAuthenticated extends AuthState {
  final User user;
  final bool isEmailVerified;
  final bool biometricEnabled;
  final DateTime? lastActivity;
  final bool isSessionValid;

  const AuthAuthenticated({
    required this.user,
    this.isEmailVerified = true,
    this.biometricEnabled = false,
    this.lastActivity,
    this.isSessionValid = true,
  });

  @override
  List<Object?> get props => [
    user,
    isEmailVerified,
    biometricEnabled,
    lastActivity,
    isSessionValid,
  ];

  /// Create a copy with updated properties
  AuthAuthenticated copyWith({
    User? user,
    bool? isEmailVerified,
    bool? biometricEnabled,
    DateTime? lastActivity,
    bool? isSessionValid,
  }) {
    return AuthAuthenticated(
      user: user ?? this.user,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      lastActivity: lastActivity ?? this.lastActivity,
      isSessionValid: isSessionValid ?? this.isSessionValid,
    );
  }
}

/// State when user is not authenticated
class AuthUnauthenticated extends AuthState {
  final String? message;
  final bool showWelcome;

  const AuthUnauthenticated({
    this.message,
    this.showWelcome = false,
  });

  @override
  List<Object?> get props => [message, showWelcome];
}

/// State when an authentication error occurs
class AuthError extends AuthState {
  final String message;
  final AuthErrorType errorType;
  final bool canRetry;
  final dynamic originalException;

  const AuthError({
    required this.message,
    this.errorType = AuthErrorType.generic,
    this.canRetry = true,
    this.originalException,
  });

  @override
  List<Object?> get props => [message, errorType, canRetry, originalException];
}

/// State for successful operations that don't change authentication status
class AuthOperationSuccess extends AuthState {
  final String message;
  final AuthOperationType operationType;
  final Map<String, dynamic>? data;

  const AuthOperationSuccess({
    required this.message,
    required this.operationType,
    this.data,
  });

  @override
  List<Object?> get props => [message, operationType, data];
}

/// State when biometric authentication is available but not set up
class AuthBiometricAvailable extends AuthState {
  final List<BiometricType> availableBiometrics;
  final bool isEnrolled;

  const AuthBiometricAvailable({
    required this.availableBiometrics,
    this.isEnrolled = false,
  });

  @override
  List<Object?> get props => [availableBiometrics, isEnrolled];
}

/// State when session is about to expire
class AuthSessionExpiring extends AuthState {
  final User user;
  final Duration timeRemaining;
  final bool canExtend;

  const AuthSessionExpiring({
    required this.user,
    required this.timeRemaining,
    this.canExtend = true,
  });

  @override
  List<Object?> get props => [user, timeRemaining, canExtend];
}

/// Enum for different types of authentication operations
enum AuthOperationType {
  signIn,
  signUp,
  signOut,
  passwordReset,
  emailVerification,
  profileUpdate,
  deleteAccount,
  biometricSetup,
  sessionRefresh,
  autoLogin,
}

/// Enum for different types of authentication errors
enum AuthErrorType {
  generic,
  network,
  invalidCredentials,
  userNotFound,
  emailAlreadyInUse,
  weakPassword,
  tooManyRequests,
  userDisabled,
  operationNotAllowed,
  biometricNotAvailable,
  biometricNotEnrolled,
  sessionExpired,
  permissionDenied,
  offline,
}

/// Enum for different types of biometric authentication
enum BiometricType {
  fingerprint,
  face,
  iris,
  voice,
  deviceCredentials,
}

/// Extension methods for AuthErrorType
extension AuthErrorTypeExtension on AuthErrorType {
  /// Get user-friendly error message
  String get userMessage {
    switch (this) {
      case AuthErrorType.network:
        return 'Network connection error. Please check your internet connection.';
      case AuthErrorType.invalidCredentials:
        return 'Invalid email or password. Please try again.';
      case AuthErrorType.userNotFound:
        return 'No account found with this email address.';
      case AuthErrorType.emailAlreadyInUse:
        return 'An account already exists with this email address.';
      case AuthErrorType.weakPassword:
        return 'Password is too weak. Please choose a stronger password.';
      case AuthErrorType.tooManyRequests:
        return 'Too many attempts. Please wait before trying again.';
      case AuthErrorType.userDisabled:
        return 'This account has been disabled. Please contact support.';
      case AuthErrorType.operationNotAllowed:
        return 'This operation is not allowed. Please contact support.';
      case AuthErrorType.biometricNotAvailable:
        return 'Biometric authentication is not available on this device.';
      case AuthErrorType.biometricNotEnrolled:
        return 'No biometric credentials are enrolled on this device.';
      case AuthErrorType.sessionExpired:
        return 'Your session has expired. Please sign in again.';
      case AuthErrorType.permissionDenied:
        return 'Permission denied. Please check your account permissions.';
      case AuthErrorType.offline:
        return 'You are offline. Some features may not be available.';
      case AuthErrorType.generic:
        return 'An error occurred. Please try again.';
    }
  }

  /// Check if error is recoverable
  bool get isRecoverable {
    switch (this) {
      case AuthErrorType.network:
      case AuthErrorType.tooManyRequests:
      case AuthErrorType.offline:
      case AuthErrorType.generic:
      case AuthErrorType.invalidCredentials:
      case AuthErrorType.userNotFound:
      case AuthErrorType.emailAlreadyInUse:
      case AuthErrorType.weakPassword:
      case AuthErrorType.biometricNotEnrolled:
      case AuthErrorType.sessionExpired:
      case AuthErrorType.permissionDenied:
        return true;
      case AuthErrorType.userDisabled:
      case AuthErrorType.operationNotAllowed:
      case AuthErrorType.biometricNotAvailable:
        return false;
    }
  }
}

/// Extension methods for AuthOperationType
extension AuthOperationTypeExtension on AuthOperationType {
  /// Get user-friendly operation name
  String get displayName {
    switch (this) {
      case AuthOperationType.signIn:
        return 'Signing In';
      case AuthOperationType.signUp:
        return 'Creating Account';
      case AuthOperationType.signOut:
        return 'Signing Out';
      case AuthOperationType.passwordReset:
        return 'Sending Reset Email';
      case AuthOperationType.emailVerification:
        return 'Sending Verification Email';
      case AuthOperationType.profileUpdate:
        return 'Updating Profile';
      case AuthOperationType.deleteAccount:
        return 'Deleting Account';
      case AuthOperationType.biometricSetup:
        return 'Setting up Biometric Authentication';
      case AuthOperationType.sessionRefresh:
        return 'Refreshing Session';
      case AuthOperationType.autoLogin:
        return 'Auto-Login';
    }
  }
}