import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/account_type.dart';
import '../services/user_service.dart';
import '../services/task_generation_service.dart';
import '../injection/injection.dart';

/// Authentication service handling Firebase Auth integration
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static GoogleSignIn? _googleSignIn;
  
  static final StreamController<UserModel?> _userController = StreamController<UserModel?>.broadcast();
  static UserModel? _currentUser;

  /// Initialize authentication service
  static Future<void> initialize() async {
    debugPrint('🔐 Initializing AuthService...');
    
    try {
      // On Web, ensure auth persistence is set (Safari private mode may not support IndexedDB)
      if (kIsWeb) {
        try {
          await _auth.setPersistence(Persistence.LOCAL);
        } on FirebaseAuthException {
          try {
            await _auth.setPersistence(Persistence.SESSION);
          } catch (_) {}
        } catch (_) {}
      }

      // Initialize Google Sign-In (like home.dart approach)
      if (kIsWeb) {
        _googleSignIn = GoogleSignIn(
          clientId: '755453095615-c5v90iun8t5d21eujogqivqu1c0923kq.apps.googleusercontent.com',
          scopes: ['email', 'profile'],
        );
      } else {
        _googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );
      }
      
  debugPrint('Google Sign-In initialized');
    } catch (e) {
      debugPrint('⚠️ Google Sign-In initialization failed: $e');
      // Continue without Google Sign-In - user can still use email auth
    }

    // Listen to auth state changes
    _auth.authStateChanges().listen(_onAuthStateChanged);
    
    // On web, also check for redirect results (needed for iOS Safari fallback)
    if (kIsWeb) {
      try {
        final result = await _auth.getRedirectResult();
        if (result.user != null) {
          await _loadCurrentUser(result.user!);
        }
      } catch (_) {}
    }

    // Check if user is already signed in
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      await _loadCurrentUser(firebaseUser);
    } else {
      // Ensure the stream emits initial null state
      _currentUser = null;
      _userController.add(null);
    }
    
    debugPrint('✅ AuthService initialized');
  }

  /// Get current user stream
  static Stream<UserModel?> get userStream => _userController.stream;

  /// Get current user
  static UserModel? get currentUser => _currentUser;

  /// Update the current user in memory (used after profile/family changes)
  static void updateCurrentUser(UserModel user) {
    _currentUser = user;
    _userController.add(user);
    debugPrint('🔄 Current user updated in AuthService: ${user.displayName} (familyId: ${user.familyId})');
  }

  /// Check if user is authenticated
  static bool get isAuthenticated => _currentUser != null;

  /// Sign in with email and password
  static Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      // Use both debugPrint (for terminal) and print (for browser console on web)
  debugPrint('Signing in with email');
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        debugPrint('Email authentication successful');
        return await _loadCurrentUser(credential.user!);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Email sign-in failed: ${e.code} - ${e.message}');
      String userMessage = _getFirebaseAuthErrorMessage(e.code);
      throw AuthException(userMessage);
    } catch (e) {
      debugPrint('Email sign-in failed: $e');
      throw AuthException('Sign-in failed. Please try again.');
    }
  }

  /// Sign up with email and password
  static Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    UserRole role = UserRole.child,
    AccountType accountType = AccountType.child,
  }) async {
    try {
  debugPrint('Signing up with email');
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(displayName);
        
        // Create user model without familyId (they'll create/join one later)
        final user = UserModel.create(
          id: credential.user!.uid,
          email: email,
          displayName: displayName,
          photoUrl: credential.user!.photoURL,
          role: role,
          accountType: accountType,
          familyId: null, // New users start without a family
        );
        
        // Cache account type and role for disaster recovery
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_account_type_${user.id}', accountType.value);
        await prefs.setString('cached_role_${user.id}', role.name);
        
        // Save to database
        final userService = getIt<UserService>();
        await userService.createUser(user);
        
        _currentUser = user;
        _userController.add(user);
        
        return user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Email sign-up failed: ${e.code} - ${e.message}');
      String userMessage = _getFirebaseAuthErrorMessage(e.code);
      throw AuthException(userMessage);
    } catch (e) {
      debugPrint('❌ Email sign-up failed: $e');
      throw AuthException('Sign-up failed. Please try again.');
    }
  }

  /// Sign in with Google
  static Future<UserModel?> signInWithGoogle() async {
    try {
      debugPrint('🔐 Starting Google Sign-In...');
      
      // Ensure AuthService is initialized (similar to home.dart FirestoreSync init)
      if (_googleSignIn == null) {
        debugPrint('🔐 Google Sign-In not initialized, attempting to initialize...');
        await initialize();
      }
      
      // Prefer using FirebaseAuth provider flow on web to better handle Safari popup/redirect quirks
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        try {
          debugPrint('🔐 Attempting signInWithPopup for Google on web');
          final cred = await _auth.signInWithPopup(provider);
          if (cred.user != null) {
            debugPrint('✅ Firebase authentication (popup) successful');
            return await _loadCurrentUser(cred.user!);
          }
        } on FirebaseAuthException catch (e) {
          // Popup may be blocked/closed on iOS Safari; fallback to redirect flow
          final code = e.code.toLowerCase();
          debugPrint('⚠️ signInWithPopup failed: ${e.code} - ${e.message}. Falling back to redirect...');
          if (code.contains('popup') || code.contains('blocked') || code.contains('unauthorized-domain')) {
            await _auth.signInWithRedirect(provider);
            // The app will be redirected back and _onAuthStateChanged will handle loading the user
            return null;
          } else {
            // If it's another error, fall through to google_sign_in fallback
          }
        } catch (e) {
          debugPrint('⚠️ signInWithPopup unexpected error: $e. Will try google_sign_in fallback.');
        }
      }

      if (_googleSignIn == null) {
        throw AuthException('Google Sign-In not available on this device. Try Email sign-in instead.');
      }

      // Fallback path: google_sign_in package
      final googleUser = await _googleSignIn!.signIn();
      if (googleUser == null) {
        debugPrint('🔐 Google sign-in cancelled by user');
        return null; // User cancelled, not an error
      }
      debugPrint('✅ Google user obtained: ${googleUser.email}');
      final googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        debugPrint('❌ Failed to obtain Google authentication tokens');
        throw AuthException('Failed to obtain Google authentication tokens');
      }
      debugPrint('🔐 Creating Firebase credential...');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      debugPrint('🔐 Signing in to Firebase...');
      final authResult = await _auth.signInWithCredential(credential);
      if (authResult.user != null) {
        debugPrint('✅ Firebase authentication successful');
        return await _loadCurrentUser(authResult.user!);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Google sign-in failed: $e');
      
      final errorMsg = e.toString();
      
      // Don't show error for user-cancelled actions (similar to home.dart)
      if (errorMsg.contains('popup_closed') || 
          errorMsg.contains('popup-closed-by-user') || 
          errorMsg.contains('user-cancelled') ||
          errorMsg.contains('popup closed')) {
        debugPrint('[AuthService] Google sign-in cancelled by user');
        return null; // Silently return without throwing error
      }
      
      // Handle specific errors like home.dart
      String userFriendlyMessage = 'Google sign-in failed';
      
      if (errorMsg.contains('configuration-not-found') || 
          errorMsg.contains('firebase-not-initialized')) {
        userFriendlyMessage = 'Google sign-in not available on this device. Try Email sign-in instead.';
      } else if (errorMsg.contains('network-error') || 
                 errorMsg.contains('network') || 
                 errorMsg.contains('connectivity')) {
        userFriendlyMessage = 'Network error - check internet connection';
      } else if (errorMsg.contains('google-signin-not-available')) {
        userFriendlyMessage = 'Google Play Services unavailable. Use Email sign-in instead.';
      } else if (errorMsg.contains('huawei-device-restriction')) {
        userFriendlyMessage = 'Huawei device detected: Google sign-in restricted. Use Email sign-in instead.';
      } else if (errorMsg.contains('google-signin-not-available-on-device')) {
        userFriendlyMessage = 'Google authentication unavailable. Use Email sign-in instead.';
      }
      
      throw AuthException(userFriendlyMessage);
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      debugPrint('🔐 Signing out...');
      
      // Sign out from Google if signed in
      if (_googleSignIn != null) {
        await _googleSignIn!.signOut();
      }
      
      // Sign out from Firebase
      await _auth.signOut();
      
      _currentUser = null;
      _userController.add(null);
      
      debugPrint('✅ Successfully signed out');
    } catch (e) {
      debugPrint('❌ Sign-out failed: $e');
      throw AuthException('Sign-out failed: $e');
    }
  }

  /// Reset password
  static Future<void> resetPassword(String email) async {
    try {
      debugPrint('🔐 Sending password reset email to: $email');
      
      await _auth.sendPasswordResetEmail(email: email);
      
      debugPrint('✅ Password reset email sent');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Password reset failed: ${e.message}');
      throw AuthException(e.message ?? 'Password reset failed');
    }
  }

  /// Update user profile
  static Future<UserModel?> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null || _currentUser == null) {
        throw AuthException('No user signed in');
      }
      
      debugPrint('🔐 Updating user profile...');
      
      // Update Firebase user profile
      await firebaseUser.updateDisplayName(displayName);
      await firebaseUser.updatePhotoURL(photoUrl);
      
      // Update user model
      final updatedUser = _currentUser!.copyWith(
        displayName: displayName ?? _currentUser!.displayName,
        photoUrl: photoUrl ?? _currentUser!.photoUrl,
      );
      
      // Save to database
      final userService = getIt<UserService>();
      await userService.updateUser(updatedUser);
      
      _currentUser = updatedUser;
      _userController.add(updatedUser);
      
      debugPrint('✅ Profile updated successfully');
      return updatedUser;
    } catch (e) {
      debugPrint('❌ Profile update failed: $e');
      throw AuthException('Profile update failed: $e');
    }
  }

  /// Delete user account
  static Future<void> deleteAccount() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null || _currentUser == null) {
        throw AuthException('No user signed in');
      }
      
      debugPrint('🔐 Deleting user account...');
      
      // Delete user data from database
      final userService = getIt<UserService>();
      await userService.deleteUser(_currentUser!.id);
      
      // Delete Firebase account
      await firebaseUser.delete();
      
      _currentUser = null;
      _userController.add(null);
      
      debugPrint('✅ Account deleted successfully');
    } catch (e) {
      debugPrint('❌ Account deletion failed: $e');
      throw AuthException('Account deletion failed: $e');
    }
  }

  /// Handle auth state changes
  static Future<void> _onAuthStateChanged(User? firebaseUser) async {
    debugPrint('🔐 Auth state changed: ${firebaseUser?.uid}');
    
    if (firebaseUser != null) {
      await _loadCurrentUser(firebaseUser);
    } else {
      _currentUser = null;
      _userController.add(null);
    }
  }

  /// Load current user from database
  static Future<UserModel?> _loadCurrentUser(User firebaseUser) async {
    try {
  debugPrint('Loading user data');
      
      final userService = getIt<UserService>();
      UserModel? user = await userService.getUser(firebaseUser.uid);
      
      // If user doesn't exist in database, create it
      if (user == null) {
        debugPrint('🔐 User document not found in database, attempting to restore...');
        
        // Try to restore from cached account type
        final prefs = await SharedPreferences.getInstance();
        final cachedAccountType = prefs.getString('cached_account_type_${firebaseUser.uid}');
        final cachedRole = prefs.getString('cached_role_${firebaseUser.uid}');
        
        AccountType accountType = AccountType.child; // Default fallback
        UserRole role = UserRole.child; // Default fallback
        
        if (cachedAccountType != null) {
          debugPrint('🔐 Found cached account type: $cachedAccountType');
          accountType = AccountType.fromString(cachedAccountType);
          
          if (cachedRole != null) {
            role = UserRole.values.firstWhere(
              (r) => r.toString() == 'UserRole.$cachedRole',
              orElse: () => UserRole.child,
            );
          } else {
            // Derive role from account type if not cached
            role = accountType == AccountType.parent ? UserRole.parent : UserRole.child;
          }
        } else {
          debugPrint('🔐 No cached account type found, defaulting to child');
        }
        
        user = UserModel.create(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? 'Unknown User',
          photoUrl: firebaseUser.photoURL,
          accountType: accountType,
          role: role,
        );
        
        await userService.createUser(user);
        debugPrint('🔐 Recreated user with accountType: ${accountType.value}, role: ${role.name}');
      } else {
        // Cache the account type and role for future use
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_account_type_${user.id}', user.accountType.value);
        await prefs.setString('cached_role_${user.id}', user.role.name);
        
        // Update last login time
        user = user.copyWith(lastLoginAt: DateTime.now());
        await userService.updateUser(user);
      }
      
      _currentUser = user;
      _userController.add(user);


      // Trigger task generation for today (blocking) for all users with a family.
      // Wait for generation to complete so UI shows tasks immediately.
      try {
        if (user.familyId != null) {
          final uid = user.id;
          debugPrint('🔁 Starting task generation for user $uid (${user.accountType})...');
          final generated = await TaskGenerationService()
              .generateTasksForUserForDate(
                userId: uid, 
                date: DateTime.now(), 
                familyId: user.familyId
              );
          debugPrint('Task generation complete for user $uid: ${generated.length} items');
        }
      } catch (e) {
  debugPrint('Task generation failed for user ${user.id}: $e');
        // Don't block login on generation failure
      }
      
      // Initialize family relationships if user has a familyId
      // TEMPORARILY DISABLED TO STOP AUTO-CREATION LOOP
      // if (user.familyId != null) {
      //   await _ensureFamilySetup(user);
      // }
      
      // No more task syncing - child tasks are assigned individually
      
    debugPrint('User loaded successfully: ${user.displayName}');
      return user;
    } catch (e) {
      debugPrint('❌ Failed to load user: $e');
      return null;
    }
  }

  // Family setup helpers removed - managed elsewhere.

  /// Convert Firebase Auth error codes to user-friendly messages
  static String _getFirebaseAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-credential':
        return 'The provided credentials are invalid.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  // Task auto-sync removed - child tasks are assigned individually.

  /// Clean up resources
  static void dispose() {
    _userController.close();
  }
}

/// Authentication exception class
class AuthException implements Exception {
  final String message;
  
  const AuthException(this.message);
  
  @override
  String toString() => 'AuthException: $message';
}