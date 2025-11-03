import 'package:equatable/equatable.dart';

/// Base class for all authentication events
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event to start the authentication process
class AuthStarted extends AuthEvent {
  const AuthStarted();
}

/// Event to sign in with email and password
class AuthSignInWithEmailRequested extends AuthEvent {
  final String email;
  final String password;
  final bool rememberMe;

  const AuthSignInWithEmailRequested({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });

  @override
  List<Object?> get props => [email, password, rememberMe];
}

/// Event to sign in with Google
class AuthSignInWithGoogleRequested extends AuthEvent {
  const AuthSignInWithGoogleRequested();
}

/// Event to sign in with biometric authentication
class AuthSignInWithBiometricRequested extends AuthEvent {
  const AuthSignInWithBiometricRequested();
}

/// Event to sign up with email and password
class AuthSignUpWithEmailRequested extends AuthEvent {
  final String email;
  final String password;
  final String? displayName;

  const AuthSignUpWithEmailRequested({
    required this.email,
    required this.password,
    this.displayName,
  });

  @override
  List<Object?> get props => [email, password, displayName];
}

/// Event to sign out
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Event to send password reset email
class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthPasswordResetRequested({
    required this.email,
  });

  @override
  List<Object?> get props => [email];
}

/// Event to send email verification
class AuthEmailVerificationRequested extends AuthEvent {
  const AuthEmailVerificationRequested();
}

/// Event to update user profile
class AuthUpdateProfileRequested extends AuthEvent {
  final String? displayName;
  final String? photoUrl;

  const AuthUpdateProfileRequested({
    this.displayName,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [displayName, photoUrl];
}

/// Event to delete user account
class AuthDeleteAccountRequested extends AuthEvent {
  final String? reason;

  const AuthDeleteAccountRequested({
    this.reason,
  });

  @override
  List<Object?> get props => [reason];
}

/// Event to enable biometric authentication
class AuthEnableBiometricRequested extends AuthEvent {
  const AuthEnableBiometricRequested();
}

/// Event to disable biometric authentication
class AuthDisableBiometricRequested extends AuthEvent {
  const AuthDisableBiometricRequested();
}

/// Event to check biometric availability
class AuthCheckBiometricAvailabilityRequested extends AuthEvent {
  const AuthCheckBiometricAvailabilityRequested();
}

/// Event to retry failed authentication
class AuthRetryRequested extends AuthEvent {
  const AuthRetryRequested();
}

/// Event to clear authentication errors
class AuthErrorCleared extends AuthEvent {
  const AuthErrorCleared();
}

/// Event triggered by authentication state changes from external sources
class AuthStateChanged extends AuthEvent {
  final dynamic user; // User entity or null
  
  const AuthStateChanged(this.user);

  @override
  List<Object?> get props => [user];
}

/// Event to auto-login on app start
class AuthAutoLoginRequested extends AuthEvent {
  const AuthAutoLoginRequested();
}

/// Event to refresh user session
class AuthRefreshSessionRequested extends AuthEvent {
  const AuthRefreshSessionRequested();
}

/// Event to validate session timeout
class AuthValidateSessionRequested extends AuthEvent {
  const AuthValidateSessionRequested();
}