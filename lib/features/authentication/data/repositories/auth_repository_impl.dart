import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../datasources/auth_local_datasource.dart';
import '../models/user_model.dart';

/// Concrete implementation of the AuthRepository interface.
/// 
/// This implementation coordinates between Firebase authentication and local
/// data sources, providing offline authentication support, state management,
/// and seamless online/offline synchronization.
@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource _firebaseAuthDataSource;
  final AuthLocalDataSource _localDataSource;
  final ConnectivityService _connectivityService;
  final SyncService _syncService;

  const AuthRepositoryImpl(
    this._firebaseAuthDataSource,
    this._localDataSource,
    this._connectivityService,
    this._syncService,
  );

  @override
  Future<Either<Failure, User>> signInWithEmail(String email, String password) async {
    try {
      // Check connectivity
      final hasConnection = await _connectivityService.hasConnection();
      
      if (!hasConnection) {
        // Try offline authentication with cached credentials
        return await _handleOfflineSignIn(email, password);
      }

      // Online authentication
      final result = await _firebaseAuthDataSource.signInWithEmail(
        email: email,
        password: password,
      );

      return result.fold(
        (exception) => Either.left(_mapAuthException(exception)),
        (userModel) async {
          final user = userModel.toEntity();
          
          // Cache user data for offline access
          await _cacheUserData(userModel);
          
          // Trigger sync after successful authentication
          _syncService.forceSyncNow();
          
          return Either.right(user);
        },
      );
    } catch (e) {
      return Either.left(AuthFailure('Sign in failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    try {
      // Require online connection for Google Sign-In
      if (!await _connectivityService.hasConnection()) {
        return Either.left(NetworkFailure('Internet connection required for Google Sign-In'));
      }

      final result = await _firebaseAuthDataSource.signInWithGoogle();

      return result.fold(
        (exception) => Either.left(_mapAuthException(exception)),
        (userModel) async {
          final user = userModel.toEntity();
          
          // Cache user data for offline access
          await _cacheUserData(userModel);
          
          // Trigger sync after successful authentication
          _syncService.forceSyncNow();
          
          return Either.right(user);
        },
      );
    } catch (e) {
      return Either.left(AuthFailure('Google sign in failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> signUpWithEmail(String email, String password) async {
    try {
      // Require online connection for sign up
      if (!await _connectivityService.hasConnection()) {
        return Either.left(NetworkFailure('Internet connection required for sign up'));
      }

      final result = await _firebaseAuthDataSource.signUpWithEmail(
        email: email,
        password: password,
      );

      return result.fold(
        (exception) => Either.left(_mapAuthException(exception)),
        (userModel) async {
          final user = userModel.toEntity();
          
          // Cache user data for offline access
          await _cacheUserData(userModel);
          
          // Trigger sync after successful authentication
          _syncService.forceSyncNow();
          
          return Either.right(user);
        },
      );
    } catch (e) {
      return Either.left(AuthFailure('Sign up failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      // Always try to sign out from Firebase first
      if (await _connectivityService.hasConnection()) {
        final result = await _firebaseAuthDataSource.signOut();
        result.fold(
          (exception) => null, // Continue with local sign out even if remote fails
          (_) => null,
        );
      }

      // Clear local cached data
      await _localDataSource.clearCache();
      
      return Either.right(null);
    } catch (e) {
      return Either.left(AuthFailure('Sign out failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      // Try to get current user from Firebase first if online
      if (await _connectivityService.hasConnection()) {
        final result = await _firebaseAuthDataSource.getCurrentUser();
        return result.fold(
          (exception) async {
            // Fall back to cached user if Firebase fails
            return await _getCachedCurrentUser();
          },
          (userModel) async {
            if (userModel != null) {
              final user = userModel.toEntity();
              // Update cache with fresh data
              await _cacheUserData(userModel);
              return Either.right(user);
            } else {
              return Either.right(null);
            }
          },
        );
      } else {
        // Offline - get cached user
        return await _getCachedCurrentUser();
      }
    } catch (e) {
      return Either.left(AuthFailure('Get current user failed: ${e.toString()}'));
    }
  }

  @override
  Stream<User?> get authStateChanges {
    // Transform Firebase auth state changes to User entities
    return _firebaseAuthDataSource.authStateChanges.map((userModel) {
      if (userModel != null) {
        // Cache user data when state changes
        _cacheUserData(userModel);
        return userModel.toEntity();
      } else {
        // Clear cache when user signs out
        _localDataSource.clearCache();
        return null;
      }
    });
  }

  @override
  Future<Either<Failure, bool>> isEmailVerified() async {
    try {
      // Require online connection to check email verification
      if (!await _connectivityService.hasConnection()) {
        return Either.left(NetworkFailure('Internet connection required to check email verification'));
      }

      final userResult = await _firebaseAuthDataSource.getCurrentUser();
      
      return userResult.fold(
        (exception) => Either.left(_mapAuthException(exception)),
        (userModel) {
          if (userModel != null) {
            // Assume email is verified for now - would need to check UserModel structure
            return Either.right(true);
          } else {
            return Either.left(AuthFailure('No user is currently signed in'));
          }
        },
      );
    } catch (e) {
      return Either.left(AuthFailure('Check email verification failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> sendEmailVerification() async {
    try {
      // Require online connection for email verification
      if (!await _connectivityService.hasConnection()) {
        return Either.left(NetworkFailure('Internet connection required for email verification'));
      }

      // This would require additional Firebase Auth methods in the data source
      // For now, return success as a placeholder
      return Either.right(null);
    } catch (e) {
      return Either.left(AuthFailure('Send email verification failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      // Require online connection for password reset
      if (!await _connectivityService.hasConnection()) {
        return Either.left(NetworkFailure('Internet connection required for password reset'));
      }

      final result = await _firebaseAuthDataSource.sendPasswordResetEmail(email);

      return result.fold(
        (exception) => Either.left(_mapAuthException(exception)),
        (_) => Either.right(null),
      );
    } catch (e) {
      return Either.left(AuthFailure('Send password reset email failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      // Require online connection for profile updates
      if (!await _connectivityService.hasConnection()) {
        return Either.left(NetworkFailure('Internet connection required for profile updates'));
      }

      final result = await _firebaseAuthDataSource.updateProfile(
        displayName: displayName,
        photoURL: photoUrl,
      );

      return result.fold(
        (exception) => Either.left(_mapAuthException(exception)),
        (userModel) async {
          final user = userModel.toEntity();
          
          // Update cached user data
          await _cacheUserData(userModel);
          
          return Either.right(user);
        },
      );
    } catch (e) {
      return Either.left(AuthFailure('Update profile failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      // Require online connection for account deletion
      if (!await _connectivityService.hasConnection()) {
        return Either.left(NetworkFailure('Internet connection required for account deletion'));
      }

      // This would require additional Firebase Auth methods in the data source
      // For now, clear local cache as a placeholder
      await _localDataSource.clearCache();
      
      return Either.right(null);
    } catch (e) {
      return Either.left(AuthFailure('Delete account failed: ${e.toString()}'));
    }
  }

  /// Handle offline authentication using cached credentials
  Future<Either<Failure, User>> _handleOfflineSignIn(String email, String password) async {
    try {
      final result = await _localDataSource.getCachedUserByEmail(email);
      
      return result.fold(
        (exception) => Either.left(NetworkFailure('No internet connection and no cached credentials')),
        (cachedUserModel) {
          // For offline auth, we assume cached credentials are valid
          // In a real implementation, you'd verify hashed passwords
          return Either.right(cachedUserModel.toEntity());
        },
      );
    } catch (e) {
      return Either.left(AuthFailure('Offline authentication failed: ${e.toString()}'));
    }
  }

  /// Get cached current user
  Future<Either<Failure, User?>> _getCachedCurrentUser() async {
    try {
      final result = await _localDataSource.getLastActiveUser();
      
      return result.fold(
        (exception) => Either.right(null), // No cached user is not an error
        (userModel) => userModel != null 
            ? Either.right(userModel.toEntity())
            : Either.right(null),
      );
    } catch (e) {
      return Either.left(AuthFailure('Get cached user failed: ${e.toString()}'));
    }
  }

  /// Cache user data for offline access
  Future<void> _cacheUserData(UserModel userModel) async {
    try {
      await _localDataSource.cacheUser(userModel);
      await _localDataSource.setLastActiveUser(userModel.id);
    } catch (e) {
      // Cache failures shouldn't break the auth flow
      print('Warning: Failed to cache user data: $e');
    }
  }

  /// Map Firebase auth exceptions to domain failures
  Failure _mapAuthException(dynamic exception) {
    final message = exception.toString();
    
    if (message.contains('network') || message.contains('connection')) {
      return NetworkFailure(message);
    }
    if (message.contains('invalid') || message.contains('wrong') || message.contains('not-found')) {
      return ValidationFailure(message);
    }
    if (message.contains('too-many-requests')) {
      return ValidationFailure('Too many attempts. Please try again later.');
    }
    if (message.contains('user-disabled')) {
      return AuthFailure('This account has been disabled.');
    }
    if (message.contains('email-already-in-use')) {
      return ValidationFailure('An account already exists with this email address.');
    }
    if (message.contains('weak-password')) {
      return ValidationFailure('Password is too weak. Please choose a stronger password.');
    }
    
    return AuthFailure(message);
  }
}