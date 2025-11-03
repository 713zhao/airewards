import 'dart:async';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/entities.dart' as domain;
import '../models/models.dart';

/// Remote data source for Firebase authentication operations.
/// 
/// This class handles all Firebase authentication operations including
/// Google Sign-In, email/password authentication, and user state management.
/// It provides comprehensive error handling, timeout management, and proper
/// authentication flow coordination.
/// 
/// Key features:
/// - Google Sign-In integration with proper credential handling
/// - Email/password authentication with validation
/// - Authentication state streaming and management
/// - Token refresh and session management
/// - Comprehensive error handling and recovery
/// - Timeout management for network operations
/// - User profile synchronization with Firestore
abstract class FirebaseAuthDataSource {
  /// Stream of authentication state changes
  /// 
  /// Returns [Stream<UserModel?>]:
  /// - Emits [UserModel] when user is authenticated
  /// - Emits null when user is not authenticated
  /// - Continuously monitors authentication state
  Stream<UserModel?> get authStateChanges;
  
  /// Get currently authenticated user
  /// 
  /// Returns [Either<AuthException, UserModel?>]:
  /// - Left: [AuthException] if error occurs
  /// - Right: [UserModel] if authenticated, null if not
  Future<Either<AuthException, UserModel?>> getCurrentUser();
  
  /// Sign in with Google account
  /// 
  /// Returns [Either<AuthException, UserModel>]:
  /// - Left: [AuthException] if sign-in fails
  /// - Right: [UserModel] of authenticated user
  Future<Either<AuthException, UserModel>> signInWithGoogle();
  
  /// Sign in with email and password
  /// 
  /// Parameters:
  /// - [email]: User's email address
  /// - [password]: User's password
  /// 
  /// Returns [Either<AuthException, UserModel>]:
  /// - Left: [AuthException] if sign-in fails
  /// - Right: [UserModel] of authenticated user
  Future<Either<AuthException, UserModel>> signInWithEmail({
    required String email,
    required String password,
  });
  
  /// Sign up with email and password
  /// 
  /// Parameters:
  /// - [email]: User's email address
  /// - [password]: User's password
  /// - [displayName]: Optional display name
  /// 
  /// Returns [Either<AuthException, UserModel>]:
  /// - Left: [AuthException] if sign-up fails
  /// - Right: [UserModel] of newly created user
  Future<Either<AuthException, UserModel>> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  });
  
  /// Sign out current user
  /// 
  /// Returns [Either<AuthException, void>]:
  /// - Left: [AuthException] if sign-out fails
  /// - Right: void if successful
  Future<Either<AuthException, void>> signOut();
  
  /// Send password reset email
  /// 
  /// Parameters:
  /// - [email]: User's email address
  /// 
  /// Returns [Either<AuthException, void>]:
  /// - Left: [AuthException] if operation fails
  /// - Right: void if email sent successfully
  Future<Either<AuthException, void>> sendPasswordResetEmail(String email);
  
  /// Update user profile information
  /// 
  /// Parameters:
  /// - [displayName]: New display name
  /// - [photoURL]: New photo URL
  /// 
  /// Returns [Either<AuthException, UserModel>]:
  /// - Left: [AuthException] if update fails
  /// - Right: Updated [UserModel]
  Future<Either<AuthException, UserModel>> updateProfile({
    String? displayName,
    String? photoURL,
  });
  
  /// Refresh authentication token
  /// 
  /// Returns [Either<AuthException, String>]:
  /// - Left: [AuthException] if refresh fails
  /// - Right: New authentication token
  Future<Either<AuthException, String>> refreshToken();
  
  /// Delete user account
  /// 
  /// Returns [Either<AuthException, void>]:
  /// - Left: [AuthException] if deletion fails
  /// - Right: void if successful
  Future<Either<AuthException, void>> deleteAccount();
}

/// Implementation of [FirebaseAuthDataSource] using Firebase Auth SDK.
@LazySingleton(as: FirebaseAuthDataSource)
class FirebaseAuthDataSourceImpl implements FirebaseAuthDataSource {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  
  // Stream controller for auth state changes
  late final StreamController<UserModel?> _authStateController;
  late final StreamSubscription<firebase_auth.User?> _authStateSubscription;
  
  FirebaseAuthDataSourceImpl({
    firebase_auth.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(
          scopes: ['email', 'profile'],
        ) {
    _authStateController = StreamController<UserModel?>.broadcast();
    _initializeAuthStateListener();
  }
  
  /// Initialize authentication state listener
  void _initializeAuthStateListener() {
    _authStateSubscription = _firebaseAuth.authStateChanges().listen(
      (firebase_auth.User? firebaseUser) {
        if (firebaseUser != null) {
          final userModel = UserModel.fromFirebaseUser(firebaseUser);
          _authStateController.add(userModel);
        } else {
          _authStateController.add(null);
        }
      },
      onError: (error) {
        log('Authentication state error: $error', name: 'FirebaseAuthDataSource');
        _authStateController.addError(AuthException(
          'Authentication state monitoring failed: ${error.toString()}',
        ));
      },
    );
  }
  
  @override
  Stream<UserModel?> get authStateChanges => _authStateController.stream;
  
  @override
  Future<Either<AuthException, UserModel?>> getCurrentUser() async {
    try {
      final firebase_auth.User? firebaseUser = _firebaseAuth.currentUser;
      
      if (firebaseUser == null) {
        return Either.right(null);
      }
      
      // Refresh token to ensure user is still valid
      await firebaseUser.reload();
      final refreshedUser = _firebaseAuth.currentUser;
      
      if (refreshedUser == null) {
        return Either.right(null);
      }
      
      final userModel = UserModel.fromFirebaseUser(refreshedUser);
      return Either.right(userModel);
    } catch (e) {
      return Either.left(AuthException('Failed to get current user: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<AuthException, UserModel>> signInWithGoogle() async {
    try {
      // Start Google Sign-In flow with timeout
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn()
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('Google Sign-In timeout'),
          );
      
      if (googleUser == null) {
        return Either.left(AuthException('Google Sign-In was cancelled by user'));
      }
      
      // Get authentication details with timeout
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Google authentication timeout'),
          );
      
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        return Either.left(AuthException('Failed to get Google authentication tokens'));
      }
      
      // Create Firebase credential
      final firebase_auth.AuthCredential credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase with timeout
      final firebase_auth.UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Firebase sign-in timeout'),
          );
      
      if (userCredential.user == null) {
        return Either.left(AuthException('Failed to authenticate with Firebase'));
      }
      
      final userModel = UserModel.fromFirebaseUser(
        userCredential.user!,
        provider: domain.AuthProvider.google,
      );
      
      log('Google Sign-In successful for user: ${userModel.email}', name: 'FirebaseAuthDataSource');
      return Either.right(userModel);
      
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Either.left(_handleFirebaseAuthException(e));
    } on TimeoutException catch (e) {
      return Either.left(AuthException('Sign-in timeout: ${e.message}'));
    } catch (e) {
      return Either.left(AuthException('Google Sign-In failed: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<AuthException, UserModel>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Validate input
      if (email.trim().isEmpty) {
        return Either.left(AuthException('Email cannot be empty'));
      }
      if (password.isEmpty) {
        return Either.left(AuthException('Password cannot be empty'));
      }
      if (!_isValidEmail(email)) {
        return Either.left(AuthException('Invalid email format'));
      }
      
      // Sign in with timeout
      final firebase_auth.UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Sign-in timeout'),
          );
      
      if (userCredential.user == null) {
        return Either.left(AuthException('Authentication failed'));
      }
      
      final userModel = UserModel.fromFirebaseUser(
        userCredential.user!,
        provider: domain.AuthProvider.email,
      );
      
      log('Email Sign-In successful for user: ${userModel.email}', name: 'FirebaseAuthDataSource');
      return Either.right(userModel);
      
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Either.left(_handleFirebaseAuthException(e));
    } on TimeoutException catch (e) {
      return Either.left(AuthException('Sign-in timeout: ${e.message}'));
    } catch (e) {
      return Either.left(AuthException('Email Sign-In failed: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<AuthException, UserModel>> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      // Validate input
      if (email.trim().isEmpty) {
        return Either.left(AuthException('Email cannot be empty'));
      }
      if (password.isEmpty) {
        return Either.left(AuthException('Password cannot be empty'));
      }
      if (!_isValidEmail(email)) {
        return Either.left(AuthException('Invalid email format'));
      }
      if (password.length < 6) {
        return Either.left(AuthException('Password must be at least 6 characters'));
      }
      
      // Create account with timeout
      final firebase_auth.UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Sign-up timeout'),
          );
      
      if (userCredential.user == null) {
        return Either.left(AuthException('Account creation failed'));
      }
      
      // Update display name if provided
      if (displayName != null && displayName.trim().isNotEmpty) {
        await userCredential.user!.updateDisplayName(displayName.trim());
        await userCredential.user!.reload();
      }
      
      final userModel = UserModel.fromFirebaseUser(
        _firebaseAuth.currentUser!,
        provider: domain.AuthProvider.email,
      );
      
      log('Email Sign-Up successful for user: ${userModel.email}', name: 'FirebaseAuthDataSource');
      return Either.right(userModel);
      
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Either.left(_handleFirebaseAuthException(e));
    } on TimeoutException catch (e) {
      return Either.left(AuthException('Sign-up timeout: ${e.message}'));
    } catch (e) {
      return Either.left(AuthException('Email Sign-Up failed: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<AuthException, void>> signOut() async {
    try {
      // Sign out from Firebase Auth
      await _firebaseAuth.signOut().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Sign-out timeout'),
      );
      
      // Sign out from Google Sign-In if available
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut().timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Google sign-out timeout'),
        );
      }
      
      log('Sign-out successful', name: 'FirebaseAuthDataSource');
      return Either.right(null);
      
    } on TimeoutException catch (e) {
      return Either.left(AuthException('Sign-out timeout: ${e.message}'));
    } catch (e) {
      return Either.left(AuthException('Sign-out failed: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<AuthException, void>> sendPasswordResetEmail(String email) async {
    try {
      if (email.trim().isEmpty) {
        return Either.left(AuthException('Email cannot be empty'));
      }
      if (!_isValidEmail(email)) {
        return Either.left(AuthException('Invalid email format'));
      }
      
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim()).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Password reset timeout'),
      );
      
      log('Password reset email sent to: ${email.trim()}', name: 'FirebaseAuthDataSource');
      return Either.right(null);
      
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Either.left(_handleFirebaseAuthException(e));
    } on TimeoutException catch (e) {
      return Either.left(AuthException('Password reset timeout: ${e.message}'));
    } catch (e) {
      return Either.left(AuthException('Password reset failed: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<AuthException, UserModel>> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final firebase_auth.User? user = _firebaseAuth.currentUser;
      if (user == null) {
        return Either.left(AuthException('No authenticated user'));
      }
      
      if (displayName != null) {
        await user.updateDisplayName(displayName.trim()).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Profile update timeout'),
        );
      }
      
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL.trim()).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Profile update timeout'),
        );
      }
      
      await user.reload();
      final updatedUser = _firebaseAuth.currentUser!;
      
      final userModel = UserModel.fromFirebaseUser(updatedUser);
      
      log('Profile update successful for user: ${userModel.email}', name: 'FirebaseAuthDataSource');
      return Either.right(userModel);
      
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Either.left(_handleFirebaseAuthException(e));
    } on TimeoutException catch (e) {
      return Either.left(AuthException('Profile update timeout: ${e.message}'));
    } catch (e) {
      return Either.left(AuthException('Profile update failed: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<AuthException, String>> refreshToken() async {
    try {
      final firebase_auth.User? user = _firebaseAuth.currentUser;
      if (user == null) {
        return Either.left(AuthException('No authenticated user'));
      }
      
      final String? tokenResult = await user.getIdToken(true).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Token refresh timeout'),
      );
      
      if (tokenResult == null) {
        return Either.left(AuthException('Failed to get authentication token'));
      }
      
      final String token = tokenResult;
      
      log('Token refresh successful', name: 'FirebaseAuthDataSource');
      return Either.right(token);
      
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Either.left(_handleFirebaseAuthException(e));
    } on TimeoutException catch (e) {
      return Either.left(AuthException('Token refresh timeout: ${e.message}'));
    } catch (e) {
      return Either.left(AuthException('Token refresh failed: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<AuthException, void>> deleteAccount() async {
    try {
      final firebase_auth.User? user = _firebaseAuth.currentUser;
      if (user == null) {
        return Either.left(AuthException('No authenticated user'));
      }
      
      await user.delete().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Account deletion timeout'),
      );
      
      // Sign out from Google Sign-In if available
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      
      log('Account deletion successful', name: 'FirebaseAuthDataSource');
      return Either.right(null);
      
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Either.left(_handleFirebaseAuthException(e));
    } on TimeoutException catch (e) {
      return Either.left(AuthException('Account deletion timeout: ${e.message}'));
    } catch (e) {
      return Either.left(AuthException('Account deletion failed: ${e.toString()}'));
    }
  }
  
  /// Handle Firebase Auth exceptions with proper error mapping
  AuthException _handleFirebaseAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AuthException('No account found with this email address');
      case 'wrong-password':
        return AuthException('Incorrect password');
      case 'email-already-in-use':
        return AuthException('An account with this email already exists');
      case 'weak-password':
        return AuthException('Password is too weak');
      case 'invalid-email':
        return AuthException('Invalid email address format');
      case 'user-disabled':
        return AuthException('This account has been disabled');
      case 'too-many-requests':
        return AuthException('Too many failed attempts. Please try again later');
      case 'operation-not-allowed':
        return AuthException('This authentication method is not enabled');
      case 'network-request-failed':
        return AuthException('Network error. Please check your connection');
      case 'requires-recent-login':
        return AuthException('This operation requires recent authentication');
      case 'account-exists-with-different-credential':
        return AuthException('Account exists with different sign-in method');
      case 'invalid-credential':
        return AuthException('Invalid authentication credentials');
      case 'credential-already-in-use':
        return AuthException('These credentials are already associated with another account');
      case 'expired-action-code':
        return AuthException('The action code has expired');
      case 'invalid-action-code':
        return AuthException('Invalid action code');
      case 'missing-email':
        return AuthException('Email address is required');
      case 'missing-password':
        return AuthException('Password is required');
      default:
        return AuthException('Authentication error: ${e.message ?? e.code}');
    }
  }
  
  /// Validate email format using basic regex
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email.trim());
  }
  
  /// Dispose resources
  void dispose() {
    _authStateSubscription.cancel();
    _authStateController.close();
  }
}

/// Timeout exception for authentication operations
class TimeoutException implements Exception {
  final String message;
  const TimeoutException(this.message);
  
  @override
  String toString() => 'TimeoutException: $message';
}