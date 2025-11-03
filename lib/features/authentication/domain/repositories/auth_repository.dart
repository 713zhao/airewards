import 'package:ai_rewards_system/core/errors/failures.dart';
import 'package:ai_rewards_system/core/utils/either.dart';
import 'package:ai_rewards_system/features/authentication/domain/entities/user.dart';

/// Abstract repository interface for authentication operations.
/// 
/// This interface defines all authentication-related operations following
/// clean architecture principles. It uses the Either pattern for error
/// handling, returning Failure objects on the left and success values
/// on the right.
/// 
/// The repository abstracts away the data source implementation details,
/// allowing for different implementations (Firebase, local storage, etc.)
/// while maintaining the same interface contract.
abstract class AuthRepository {
  /// Sign in a user with Google OAuth.
  /// 
  /// Returns [Either<Failure, User>]:
  /// - Left: [AuthFailure] if sign-in fails
  /// - Right: [User] object if sign-in succeeds
  /// 
  /// Possible failures:
  /// - [AuthFailure.cancelled] if user cancels the sign-in
  /// - [AuthFailure.unknown] for unexpected errors
  /// - [NetworkFailure] for network-related issues
  Future<Either<Failure, User>> signInWithGoogle();

  /// Sign in a user with email and password.
  /// 
  /// Parameters:
  /// - [email]: User's email address
  /// - [password]: User's password
  /// 
  /// Returns [Either<Failure, User>]:
  /// - Left: [AuthFailure] if sign-in fails
  /// - Right: [User] object if sign-in succeeds
  /// 
  /// Possible failures:
  /// - [AuthFailure.invalidCredentials] for wrong email/password
  /// - [AuthFailure.userNotFound] if no account exists with email
  /// - [AuthFailure.userDisabled] if account is disabled
  /// - [AuthFailure.tooManyRequests] for rate limiting
  /// - [NetworkFailure] for network-related issues
  Future<Either<Failure, User>> signInWithEmail(String email, String password);

  /// Register a new user with email and password.
  /// 
  /// Parameters:
  /// - [email]: User's email address
  /// - [password]: User's password
  /// 
  /// Returns [Either<Failure, User>]:
  /// - Left: [AuthFailure] if registration fails
  /// - Right: [User] object if registration succeeds
  /// 
  /// Possible failures:
  /// - [AuthFailure.emailAlreadyInUse] if email is already registered
  /// - [AuthFailure.weakPassword] if password doesn't meet requirements
  /// - [ValidationFailure] for invalid email or password format
  /// - [NetworkFailure] for network-related issues
  Future<Either<Failure, User>> signUpWithEmail(String email, String password);

  /// Sign out the current user.
  /// 
  /// Returns [Either<Failure, void>]:
  /// - Left: [AuthFailure] if sign-out fails
  /// - Right: void if sign-out succeeds
  /// 
  /// This method should:
  /// - Clear authentication tokens
  /// - Clear local user data cache
  /// - Notify authentication state listeners
  /// 
  /// Possible failures:
  /// - [AuthFailure.unknown] for unexpected errors
  /// - [NetworkFailure] for network-related issues
  Future<Either<Failure, void>> signOut();

  /// Get the currently signed-in user.
  /// 
  /// Returns [Either<Failure, User?>]:
  /// - Left: [Failure] if operation fails
  /// - Right: [User] if user is signed in, null if no user is signed in
  /// 
  /// This method should return cached user data when available
  /// and only fetch from remote when necessary.
  /// 
  /// Possible failures:
  /// - [AuthFailure.sessionExpired] if session is no longer valid
  /// - [CacheFailure] for cache-related issues
  /// - [NetworkFailure] for network-related issues
  Future<Either<Failure, User?>> getCurrentUser();

  /// Stream of authentication state changes.
  /// 
  /// This stream should emit:
  /// - [User] object when user signs in
  /// - null when user signs out
  /// - Updated [User] object when user data changes
  /// 
  /// The stream should be hot and maintain the current authentication
  /// state. It should automatically handle session expiry and token
  /// refresh when possible.
  /// 
  /// Implementation notes:
  /// - Should emit current state immediately on subscription
  /// - Should handle authentication state persistence across app restarts
  /// - Should gracefully handle network connectivity changes
  Stream<User?> get authStateChanges;

  /// Check if user email is verified.
  /// 
  /// Returns [Either<Failure, bool>]:
  /// - Left: [Failure] if operation fails
  /// - Right: true if email is verified, false otherwise
  /// 
  /// Note: Some authentication providers (Google, Apple) automatically
  /// verify emails, while email/password authentication may require
  /// manual verification.
  /// 
  /// Possible failures:
  /// - [AuthFailure.sessionExpired] if session is no longer valid
  /// - [NetworkFailure] for network-related issues
  Future<Either<Failure, bool>> isEmailVerified();

  /// Send email verification to current user.
  /// 
  /// Returns [Either<Failure, void>]:
  /// - Left: [Failure] if operation fails
  /// - Right: void if verification email sent successfully
  /// 
  /// This method should only work for email/password authenticated users.
  /// 
  /// Possible failures:
  /// - [AuthFailure.requiresRecentLogin] if user needs to re-authenticate
  /// - [AuthFailure.tooManyRequests] for rate limiting
  /// - [NetworkFailure] for network-related issues
  Future<Either<Failure, void>> sendEmailVerification();

  /// Send password reset email.
  /// 
  /// Parameters:
  /// - [email]: Email address to send reset link to
  /// 
  /// Returns [Either<Failure, void>]:
  /// - Left: [Failure] if operation fails
  /// - Right: void if reset email sent successfully
  /// 
  /// Possible failures:
  /// - [AuthFailure.userNotFound] if no account exists with email
  /// - [AuthFailure.tooManyRequests] for rate limiting
  /// - [ValidationFailure] for invalid email format
  /// - [NetworkFailure] for network-related issues
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);

  /// Update user profile information.
  /// 
  /// Parameters:
  /// - [displayName]: New display name (optional)
  /// - [photoUrl]: New photo URL (optional)
  /// 
  /// Returns [Either<Failure, User>]:
  /// - Left: [Failure] if update fails
  /// - Right: Updated [User] object
  /// 
  /// Possible failures:
  /// - [AuthFailure.requiresRecentLogin] if user needs to re-authenticate
  /// - [ValidationFailure] for invalid input data
  /// - [NetworkFailure] for network-related issues
  Future<Either<Failure, User>> updateProfile({
    String? displayName,
    String? photoUrl,
  });

  /// Delete the current user account.
  /// 
  /// Returns [Either<Failure, void>]:
  /// - Left: [Failure] if deletion fails
  /// - Right: void if deletion succeeds
  /// 
  /// This is a destructive operation that:
  /// - Deletes the user account from the authentication provider
  /// - Should trigger cleanup of user data
  /// - Signs out the user
  /// 
  /// Possible failures:
  /// - [AuthFailure.requiresRecentLogin] if user needs to re-authenticate
  /// - [NetworkFailure] for network-related issues
  Future<Either<Failure, void>> deleteAccount();
}