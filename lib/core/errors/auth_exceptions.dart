import 'package:firebase_auth/firebase_auth.dart';

/// Custom authentication exception class
class AuthException implements Exception {
  final String code;
  final String message;

  const AuthException({
    required this.code,
    required this.message,
  });

  // Common authentication exceptions
  const AuthException.unknown() : this(
    code: 'unknown',
    message: 'An unknown error occurred',
  );

  const AuthException.cancelled() : this(
    code: 'cancelled',
    message: 'Operation was cancelled by the user',
  );

  const AuthException.userNotFound() : this(
    code: 'user-not-found',
    message: 'No user found',
  );

  const AuthException.weakPassword() : this(
    code: 'weak-password',
    message: 'Password is too weak',
  );

  const AuthException.emailAlreadyInUse() : this(
    code: 'email-already-in-use',
    message: 'Email is already registered',
  );

  const AuthException.invalidEmail() : this(
    code: 'invalid-email',
    message: 'Email address is invalid',
  );

  const AuthException.wrongPassword() : this(
    code: 'wrong-password',
    message: 'Incorrect password',
  );

  const AuthException.userDisabled() : this(
    code: 'user-disabled',
    message: 'User account has been disabled',
  );

  const AuthException.tooManyRequests() : this(
    code: 'too-many-requests',
    message: 'Too many requests. Try again later',
  );

  const AuthException.networkError() : this(
    code: 'network-request-failed',
    message: 'Network connection failed',
  );

  const AuthException.invalidVerificationCode() : this(
    code: 'invalid-verification-code',
    message: 'Invalid verification code',
  );

  const AuthException.invalidPhoneNumber() : this(
    code: 'invalid-phone-number',
    message: 'Phone number is invalid',
  );

  const AuthException.sessionExpired() : this(
    code: 'session-expired',
    message: 'Session has expired',
  );

  const AuthException.requiresRecentLogin() : this(
    code: 'requires-recent-login',
    message: 'Please sign in again to continue',
  );

  /// Create AuthException from FirebaseAuthException
  factory AuthException.fromFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return const AuthException.weakPassword();
      case 'email-already-in-use':
        return const AuthException.emailAlreadyInUse();
      case 'invalid-email':
        return const AuthException.invalidEmail();
      case 'wrong-password':
        return const AuthException.wrongPassword();
      case 'user-not-found':
        return const AuthException.userNotFound();
      case 'user-disabled':
        return const AuthException.userDisabled();
      case 'too-many-requests':
        return const AuthException.tooManyRequests();
      case 'network-request-failed':
        return const AuthException.networkError();
      case 'invalid-verification-code':
        return const AuthException.invalidVerificationCode();
      case 'invalid-phone-number':
        return const AuthException.invalidPhoneNumber();
      case 'session-expired':
        return const AuthException.sessionExpired();
      case 'requires-recent-login':
        return const AuthException.requiresRecentLogin();
      default:
        return AuthException(
          code: e.code,
          message: e.message ?? 'An authentication error occurred',
        );
    }
  }

  /// Get user-friendly error message
  String get userMessage {
    switch (code) {
      case 'weak-password':
        return 'Password should be at least 6 characters long';
      case 'email-already-in-use':
        return 'An account with this email already exists';
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'wrong-password':
        return 'Incorrect email or password';
      case 'user-not-found':
        return 'No account found with this email';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';
      case 'network-request-failed':
        return 'Please check your internet connection';
      case 'invalid-verification-code':
        return 'Invalid verification code. Please try again';
      case 'invalid-phone-number':
        return 'Please enter a valid phone number';
      case 'session-expired':
        return 'Your session has expired. Please sign in again';
      case 'requires-recent-login':
        return 'Please sign in again to continue';
      case 'cancelled':
        return 'Sign-in was cancelled';
      default:
        return message;
    }
  }

  @override
  String toString() => 'AuthException($code): $message';
}