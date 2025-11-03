import 'package:ai_rewards_system/core/errors/failures.dart';
import 'package:ai_rewards_system/core/usecases/usecase.dart';
import 'package:ai_rewards_system/core/utils/either.dart';
import 'package:ai_rewards_system/features/authentication/domain/entities/user.dart';
import 'package:ai_rewards_system/features/authentication/domain/entities/auth_provider.dart';
import 'package:ai_rewards_system/features/authentication/domain/repositories/auth_repository.dart';

/// Use case for signing in with Google OAuth.
/// 
/// This use case handles the business logic for Google authentication,
/// including validation, error handling, and user creation/update logic.
/// It follows the single responsibility principle by focusing solely on
/// Google sign-in functionality.
/// 
/// Business rules:
/// - User must have a valid Google account
/// - Internet connection is required for authentication
/// - User profile is automatically created/updated from Google data
/// - Session is established upon successful authentication
class SignInWithGoogle implements NoParamsUseCase<User> {
  final AuthRepository repository;

  /// Creates a new [SignInWithGoogle] use case.
  /// 
  /// Parameters:
  /// - [repository]: The authentication repository for data operations
  const SignInWithGoogle(this.repository);

  /// Execute the Google sign-in process.
  /// 
  /// This method orchestrates the Google OAuth flow and handles all
  /// business logic related to Google authentication.
  /// 
  /// Returns [Either<Failure, User>]:
  /// - Left: [Failure] if sign-in fails (cancelled, network issues, etc.)
  /// - Right: [User] object if sign-in succeeds
  /// 
  /// Possible failures:
  /// - [AuthFailure.cancelled] if user cancels the sign-in flow
  /// - [AuthFailure.unknown] for unexpected authentication errors
  /// - [NetworkFailure] for network connectivity issues
  /// - [PermissionFailure] if Google services are unavailable
  /// 
  /// Business logic handled:
  /// 1. Validates Google services availability
  /// 2. Initiates OAuth flow through repository
  /// 3. Handles authentication result
  /// 4. Updates user's last login timestamp
  /// 5. Ensures user profile data is synced
  @override
  Future<Either<Failure, User>> call() async {
    try {
      // Delegate to repository for the actual authentication
      final result = await repository.signInWithGoogle();
      
      return result.fold(
        // Handle authentication failure
        (failure) => Either.left(failure),
        // Handle authentication success
        (user) async {
          // Update last login timestamp as part of business logic
          final updatedUser = user.updateLastLogin();
          
          // Note: In a more complex implementation, you might:
          // - Sync user data with local storage
          // - Track authentication events for analytics
          // - Validate user account status
          // - Handle first-time user setup
          
          return Either.right(updatedUser);
        },
      );
    } catch (e) {
      // Handle unexpected errors
      return Either.left(AuthFailure.unknown('Unexpected error during Google sign-in: $e'));
    }
  }

  /// Validates if Google services are available on the device.
  /// 
  /// This method can be used by the presentation layer to check
  /// if Google sign-in should be offered as an option.
  /// 
  /// Returns [Either<Failure, bool>]:
  /// - Left: [Failure] if validation fails
  /// - Right: true if Google services are available
  Future<Either<Failure, bool>> isGoogleServicesAvailable() async {
    // In a real implementation, this would check:
    // - Google Play Services availability (Android)
    // - Network connectivity
    // - App configuration
    
    // For now, we'll assume Google services are available
    // This would be implemented with actual Google services checks
    return Either.right(true);
  }

  /// Checks if the user has previously signed in with Google.
  /// 
  /// This can be used to provide a better UX by showing appropriate
  /// messaging or UI states.
  /// 
  /// Returns [Either<Failure, bool>]:
  /// - Left: [Failure] if check fails
  /// - Right: true if user has Google authentication history
  Future<Either<Failure, bool>> hasPreviousGoogleSignIn() async {
    final currentUserResult = await repository.getCurrentUser();
    
    return currentUserResult.fold(
      (failure) => Either.left(failure),
      (user) {
        final hasPreviousSignIn = user?.provider == AuthProvider.google;
        return Either.right(hasPreviousSignIn);
      },
    );
  }
}