import 'package:ai_rewards_system/core/errors/failures.dart';
import 'package:ai_rewards_system/core/usecases/usecase.dart';
import 'package:ai_rewards_system/core/utils/either.dart';
import 'package:ai_rewards_system/features/authentication/domain/entities/user.dart';
import 'package:ai_rewards_system/features/authentication/domain/repositories/auth_repository.dart';

/// Use case for signing out the current user.
/// 
/// This use case handles the complete sign-out process, including cleaning up
/// user sessions, clearing local data, and ensuring proper security measures.
/// It follows the single responsibility principle by focusing solely on
/// the sign-out functionality and related cleanup operations.
/// 
/// Business rules:
/// - User must be currently signed in to sign out
/// - All authentication tokens should be cleared
/// - Local user data cache should be cleared appropriately
/// - Session should be terminated securely
/// - Analytics events should be tracked
/// - Offline data sync should be handled before sign-out (if applicable)
class SignOut implements NoParamsUseCase<void> {
  final AuthRepository repository;

  /// Creates a new [SignOut] use case.
  /// 
  /// Parameters:
  /// - [repository]: The authentication repository for data operations
  const SignOut(this.repository);

  /// Execute the sign-out process.
  /// 
  /// This method orchestrates the complete sign-out flow and handles
  /// all business logic related to user session termination.
  /// 
  /// Returns [Either<Failure, void>]:
  /// - Left: [Failure] if sign-out fails
  /// - Right: void if sign-out succeeds
  /// 
  /// Possible failures:
  /// - [AuthFailure.unknown] for unexpected sign-out errors
  /// - [NetworkFailure] for network connectivity issues (if remote sign-out is needed)
  /// - [CacheFailure] if local data cleanup fails
  /// 
  /// Business logic handled:
  /// 1. Validates that a user is currently signed in
  /// 2. Performs pre-sign-out cleanup (sync pending data, etc.)
  /// 3. Initiates sign-out through repository
  /// 4. Performs post-sign-out cleanup
  /// 5. Logs sign-out event for analytics and security
  /// 6. Ensures all sensitive data is cleared from memory
  @override
  Future<Either<Failure, void>> call() async {
    try {
      // Step 1: Check if user is currently signed in
      final currentUserResult = await repository.getCurrentUser();
      
      User? currentUser;
      final userCheckResult = currentUserResult.fold(
        (failure) => failure,
        (user) {
          currentUser = user;
          return null; // No failure
        },
      );

      // If there was a failure getting current user, handle it
      if (userCheckResult is Failure) {
        // If it's a session expired error, we can still proceed with sign-out
        if (userCheckResult is AuthFailure) {
          // User is already signed out or session expired, consider it success
          return Either.right(null);
        }
        return Either.left(userCheckResult);
      }

      // If no user is signed in, consider sign-out successful
      if (currentUser == null) {
        return Either.right(null);
      }

      // Step 2: Perform pre-sign-out operations
      await _performPreSignOutCleanup(currentUser!);

      // Step 3: Execute the actual sign-out through repository
      final signOutResult = await repository.signOut();
      
      return signOutResult.fold(
        // Handle sign-out failure
        (failure) async {
          await _logFailedSignOut(currentUser!, failure);
          return Either.left(failure);
        },
        // Handle sign-out success
        (_) async {
          // Step 4: Perform post-sign-out cleanup
          await _performPostSignOutCleanup(currentUser!);
          
          // Step 5: Log successful sign-out
          await _logSuccessfulSignOut(currentUser!);
          
          return Either.right(null);
        },
      );
    } catch (e) {
      // Handle unexpected errors
      return Either.left(AuthFailure.unknown('Unexpected error during sign-out: $e'));
    }
  }

  /// Forces sign-out even if there are errors.
  /// 
  /// This method can be used in situations where the app needs to ensure
  /// the user is signed out regardless of potential errors (e.g., app reset,
  /// security incidents, etc.).
  /// 
  /// Returns [Either<Failure, void>]:
  /// - Left: [Failure] only if critical cleanup fails
  /// - Right: void if force sign-out completes
  Future<Either<Failure, void>> forceSignOut() async {
    try {
      // Get current user for cleanup (don't fail if this fails)
      User? currentUser;
      final currentUserResult = await repository.getCurrentUser();
      currentUserResult.fold(
        (_) => null, // Ignore failure
        (user) => currentUser = user,
      );

      // Perform cleanup operations (don't fail if these fail)
      if (currentUser != null) {
        await _performPreSignOutCleanup(currentUser!);
      }

      // Force sign-out through repository
      final signOutResult = await repository.signOut();
      
      // Perform post-cleanup regardless of sign-out result
      if (currentUser != null) {
        await _performPostSignOutCleanup(currentUser!);
        await _logSuccessfulSignOut(currentUser!);
      }

      return signOutResult.fold(
        (failure) => Either.left(failure),
        (_) => Either.right(null),
      );
    } catch (e) {
      return Either.left(AuthFailure.unknown('Force sign-out failed: $e'));
    }
  }

  /// Checks if a user is currently signed in.
  /// 
  /// This can be used by the presentation layer to determine
  /// whether to show sign-out options.
  /// 
  /// Returns [Either<Failure, bool>]:
  /// - Left: [Failure] if check fails
  /// - Right: true if user is signed in, false otherwise
  Future<Either<Failure, bool>> isUserSignedIn() async {
    final currentUserResult = await repository.getCurrentUser();
    
    return currentUserResult.fold(
      (failure) {
        // If it's a session expired error, user is not signed in
        if (failure is AuthFailure) {
          return Either.right(false);
        }
        return Either.left(failure);
      },
      (user) => Either.right(user != null),
    );
  }

  /// Perform cleanup operations before sign-out.
  /// 
  /// This includes operations like:
  /// - Syncing pending offline data
  /// - Saving user preferences
  /// - Clearing sensitive in-memory data
  /// - Canceling background operations
  Future<void> _performPreSignOutCleanup(User user) async {
    try {
      // In a real implementation, this would:
      // - Sync any pending offline data to the server
      // - Save current app state/preferences
      // - Cancel ongoing network requests
      // - Clear sensitive data from memory
      // - Stop background services related to the user
      
      // For now, this is a placeholder
      // await _syncPendingData(user);
      // await _saveUserPreferences(user);
      // await _clearSensitiveMemoryData();
    } catch (e) {
      // Log cleanup errors but don't fail sign-out
      // In a real app, you might want to log this for debugging
    }
  }

  /// Perform cleanup operations after successful sign-out.
  /// 
  /// This includes operations like:
  /// - Clearing all local caches
  /// - Resetting app state
  /// - Clearing navigation stack
  /// - Stopping user-specific services
  Future<void> _performPostSignOutCleanup(User user) async {
    try {
      // In a real implementation, this would:
      // - Clear all local caches and databases
      // - Reset app state to initial state
      // - Clear navigation history
      // - Stop user-specific background services
      // - Clear push notification tokens
      // - Reset theme/preference settings if needed
      
      // For now, this is a placeholder
      // await _clearLocalCaches();
      // await _resetAppState();
      // await _clearNotificationTokens();
    } catch (e) {
      // Log cleanup errors but don't fail sign-out
      // In a real app, you might want to log this for debugging
    }
  }

  /// Log failed sign-out attempt.
  Future<void> _logFailedSignOut(User user, Failure failure) async {
    // In a real implementation, this would:
    // - Log to error tracking system
    // - Send security alerts if appropriate
    // - Track failed sign-out statistics
    
    // For now, this is a placeholder
    // print('Failed sign-out for user ${user.email}: $failure');
  }

  /// Log successful sign-out for analytics and security.
  Future<void> _logSuccessfulSignOut(User user) async {
    // In a real implementation, this would:
    // - Log to analytics system
    // - Track user session duration
    // - Update security logs
    // - Send user behavior events
    
    // For now, this is a placeholder
    // print('Successful sign-out for user: ${user.email}');
  }
}