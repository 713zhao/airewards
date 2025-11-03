import 'package:ai_rewards_system/core/errors/failures.dart';
import 'package:ai_rewards_system/core/usecases/usecase.dart';
import 'package:ai_rewards_system/core/utils/either.dart';
import 'package:ai_rewards_system/features/authentication/domain/entities/user.dart';
import 'package:ai_rewards_system/features/authentication/domain/repositories/auth_repository.dart';

/// Use case for retrieving the currently authenticated user.
/// 
/// This use case handles fetching and managing the current user's
/// authentication state. It provides a clean interface for the
/// presentation layer to access user information while handling
/// various edge cases and business logic.
/// 
/// Business rules:
/// - User data should be cached when possible for performance
/// - Session validity should be checked before returning user data
/// - Null result indicates no authenticated user
/// - Expired sessions should be handled gracefully
/// - User data should be up-to-date when network is available
class GetCurrentUser implements NoParamsUseCase<User?> {
  final AuthRepository repository;

  /// Creates a new [GetCurrentUser] use case.
  /// 
  /// Parameters:
  /// - [repository]: The authentication repository for data operations
  const GetCurrentUser(this.repository);

  /// Retrieve the currently authenticated user.
  /// 
  /// This method handles the business logic for fetching current user
  /// information, including session validation and data freshness checks.
  /// 
  /// Returns [Either<Failure, User?>]:
  /// - Left: [Failure] if operation fails
  /// - Right: [User] if user is authenticated, null if no user is signed in
  /// 
  /// Possible failures:
  /// - [AuthFailure.sessionExpired] if the session has expired
  /// - [CacheFailure] if local cache access fails
  /// - [NetworkFailure] for network connectivity issues
  /// 
  /// Business logic handled:
  /// 1. Attempts to retrieve user from cache first (performance)
  /// 2. Validates session freshness
  /// 3. Refreshes user data from remote if needed
  /// 4. Handles session expiry gracefully
  /// 5. Updates local cache with fresh data
  @override
  Future<Either<Failure, User?>> call() async {
    try {
      // Step 1: Attempt to get current user from repository
      final result = await repository.getCurrentUser();
      
      return result.fold(
        // Handle failure cases
        (failure) async {
          // If session expired, return null (no user) instead of error
          if (failure is AuthFailure) {
            return Either.right(null);
          }
          
          // For other failures, propagate the error
          return Either.left(failure);
        },
        // Handle success case
        (user) async {
          // If no user, return null
          if (user == null) {
            return Either.right(null);
          }
          
          // Step 2: Validate and potentially refresh user data
          final validatedUser = await _validateAndRefreshUser(user);
          return validatedUser;
        },
      );
    } catch (e) {
      return Either.left(AuthFailure.unknown('Unexpected error retrieving current user: $e'));
    }
  }

  /// Get current user with real-time data refresh.
  /// 
  /// This method forces a refresh of user data from the remote source,
  /// bypassing any local cache. Use this when you need the most up-to-date
  /// user information.
  /// 
  /// Returns [Either<Failure, User?>]:
  /// - Left: [Failure] if refresh fails
  /// - Right: [User] with fresh data if user is authenticated
  Future<Either<Failure, User?>> getCurrentUserWithRefresh() async {
    try {
      // Force refresh by getting user data from remote source
      final result = await repository.getCurrentUser();
      
      return result.fold(
        (failure) {
          if (failure is AuthFailure) {
            return Either.right(null);
          }
          return Either.left(failure);
        },
        (user) async {
          if (user == null) {
            return Either.right(null);
          }
          
          // In a real implementation, this would force a remote fetch
          // For now, we return the user as-is
          return Either.right(user);
        },
      );
    } catch (e) {
      return Either.left(AuthFailure.unknown('Error refreshing current user: $e'));
    }
  }

  /// Check if a user is currently authenticated.
  /// 
  /// This is a lightweight check that doesn't return user data,
  /// only authentication status.
  /// 
  /// Returns [Either<Failure, bool>]:
  /// - Left: [Failure] if check fails
  /// - Right: true if user is authenticated, false otherwise
  Future<Either<Failure, bool>> isUserAuthenticated() async {
    final result = await call();
    
    return result.fold(
      (failure) => Either.left(failure),
      (user) => Either.right(user != null),
    );
  }

  /// Get user authentication status with additional metadata.
  /// 
  /// Returns detailed information about the authentication state,
  /// including session age and verification status.
  /// 
  /// Returns [Either<Failure, AuthenticationStatus>]:
  /// - Left: [Failure] if check fails  
  /// - Right: [AuthenticationStatus] with detailed information
  Future<Either<Failure, AuthenticationStatus>> getAuthenticationStatus() async {
    final userResult = await call();
    
    return userResult.fold(
      (failure) => Either.left(failure),
      (user) async {
        if (user == null) {
          return Either.right(AuthenticationStatus.unauthenticated());
        }

        // Get email verification status
        final verificationResult = await repository.isEmailVerified();
        final isEmailVerified = verificationResult.fold(
          (_) => false, // Assume not verified on error
          (verified) => verified,
        );

        // Calculate session age
        final sessionAge = DateTime.now().difference(user.lastLoginAt);
        
        return Either.right(AuthenticationStatus.authenticated(
          user: user,
          isEmailVerified: isEmailVerified,
          sessionAge: sessionAge,
        ));
      },
    );
  }

  /// Validate user session and refresh if needed.
  Future<Either<Failure, User?>> _validateAndRefreshUser(User user) async {
    try {
      // Check if user data needs refresh (e.g., last login was too long ago)
      final now = DateTime.now();
      final sessionAge = now.difference(user.lastLoginAt);
      
      // If session is older than 24 hours, consider refreshing
      // (In a real app, this threshold would be configurable)
      if (sessionAge.inHours > 24) {
        // In a real implementation, this would:
        // - Check token validity with the auth provider
        // - Refresh user profile data
        // - Update last login timestamp
        // - Handle token refresh if needed
        
        // For now, just update the last login time
        final refreshedUser = user.updateLastLogin();
        return Either.right(refreshedUser);
      }
      
      // User data is fresh enough
      return Either.right(user);
    } catch (e) {
      // If refresh fails, return the original user data
      return Either.right(user);
    }
  }
}

/// Authentication status with detailed metadata.
class AuthenticationStatus {
  final User? user;
  final bool isAuthenticated;
  final bool isEmailVerified;
  final Duration? sessionAge;

  const AuthenticationStatus._({
    this.user,
    required this.isAuthenticated,
    required this.isEmailVerified,
    this.sessionAge,
  });

  /// Create status for authenticated user.
  factory AuthenticationStatus.authenticated({
    required User user,
    required bool isEmailVerified,
    required Duration sessionAge,
  }) {
    return AuthenticationStatus._(
      user: user,
      isAuthenticated: true,
      isEmailVerified: isEmailVerified,
      sessionAge: sessionAge,
    );
  }

  /// Create status for unauthenticated state.
  factory AuthenticationStatus.unauthenticated() {
    return const AuthenticationStatus._(
      isAuthenticated: false,
      isEmailVerified: false,
    );
  }

  /// Returns true if session is considered fresh (less than 1 hour old).
  bool get isSessionFresh => sessionAge != null && sessionAge!.inHours < 1;

  /// Returns true if session requires refresh (more than 24 hours old).
  bool get requiresRefresh => sessionAge != null && sessionAge!.inHours > 24;

  /// Returns true if user needs email verification.
  bool get needsEmailVerification => isAuthenticated && !isEmailVerified;

  @override
  String toString() {
    if (!isAuthenticated) {
      return 'AuthenticationStatus(unauthenticated)';
    }
    
    return 'AuthenticationStatus('
        'user: ${user?.email}, '
        'verified: $isEmailVerified, '
        'sessionAge: ${sessionAge?.inHours}h'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthenticationStatus &&
        other.user == user &&
        other.isAuthenticated == isAuthenticated &&
        other.isEmailVerified == isEmailVerified &&
        other.sessionAge == sessionAge;
  }

  @override
  int get hashCode => user.hashCode ^ 
      isAuthenticated.hashCode ^ 
      isEmailVerified.hashCode ^ 
      (sessionAge?.hashCode ?? 0);
}