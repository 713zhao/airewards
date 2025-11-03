import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/services/firebase_service.dart';
import '../../../../core/errors/auth_exceptions.dart';

/// Authentication service supporting Email/Password, Phone, and Google Sign-In
@lazySingleton
class AuthService {
  final FirebaseAuth _auth = FirebaseService.auth;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Current authenticated user
  User? get currentUser => _auth.currentUser;
  
  /// Authentication state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  // EMAIL/PASSWORD AUTHENTICATION

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      debugPrint('✅ Email sign-in successful: ${credential.user?.email}');
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Email sign-in error: ${e.code} - ${e.message}');
      throw AuthException.fromFirebaseAuthException(e);
    } catch (e) {
      debugPrint('❌ Unexpected email sign-in error: $e');
      throw const AuthException.unknown();
    }
  }

  /// Create account with email and password
  Future<UserCredential> createAccountWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user?.updateDisplayName(displayName);
      }

      // Send email verification
      await credential.user?.sendEmailVerification();
      
      debugPrint('✅ Account creation successful: ${credential.user?.email}');
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Account creation error: ${e.code} - ${e.message}');
      throw AuthException.fromFirebaseAuthException(e);
    } catch (e) {
      debugPrint('❌ Unexpected account creation error: $e');
      throw const AuthException.unknown();
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      debugPrint('✅ Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Password reset error: ${e.code} - ${e.message}');
      throw AuthException.fromFirebaseAuthException(e);
    } catch (e) {
      debugPrint('❌ Unexpected password reset error: $e');
      throw const AuthException.unknown();
    }
  }

  // GOOGLE SIGN-IN AUTHENTICATION

  /// Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw const AuthException.cancelled();
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      
      debugPrint('✅ Google sign-in successful: ${userCredential.user?.email}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Google sign-in error: ${e.code} - ${e.message}');
      throw AuthException.fromFirebaseAuthException(e);
    } catch (e) {
      debugPrint('❌ Unexpected Google sign-in error: $e');
      throw const AuthException.unknown();
    }
  }

  // PHONE AUTHENTICATION

  /// Verify phone number and send SMS code
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) codeSent,
    required Function(AuthException error) verificationFailed,
    Function(UserCredential credential)? verificationCompleted,
    int? timeout,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: Duration(seconds: timeout ?? 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (verificationCompleted != null) {
            try {
              final userCredential = await _auth.signInWithCredential(credential);
              verificationCompleted(userCredential);
              debugPrint('✅ Phone verification auto-completed');
            } catch (e) {
              debugPrint('❌ Auto phone verification error: $e');
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ Phone verification failed: ${e.code} - ${e.message}');
          verificationFailed(AuthException.fromFirebaseAuthException(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('✅ SMS code sent to: $phoneNumber');
          codeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('⏰ Phone verification timeout for: $phoneNumber');
        },
      );
    } catch (e) {
      debugPrint('❌ Unexpected phone verification error: $e');
      verificationFailed(const AuthException.unknown());
    }
  }

  /// Sign in with phone number using SMS code
  Future<UserCredential> signInWithPhoneCredential({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      debugPrint('✅ Phone sign-in successful: ${userCredential.user?.phoneNumber}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Phone sign-in error: ${e.code} - ${e.message}');
      throw AuthException.fromFirebaseAuthException(e);
    } catch (e) {
      debugPrint('❌ Unexpected phone sign-in error: $e');
      throw const AuthException.unknown();
    }
  }

  // GENERAL AUTHENTICATION METHODS

  /// Sign out from all providers
  Future<void> signOut() async {
    try {
      // Sign out from Google if signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      
      // Sign out from Firebase
      await _auth.signOut();
      
      debugPrint('✅ User signed out successfully');
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      throw const AuthException.unknown();
    }
  }

  /// Delete current user account
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw const AuthException.userNotFound();
      }

      await user.delete();
      debugPrint('✅ User account deleted successfully');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Account deletion error: ${e.code} - ${e.message}');
      throw AuthException.fromFirebaseAuthException(e);
    } catch (e) {
      debugPrint('❌ Unexpected account deletion error: $e');
      throw const AuthException.unknown();
    }
  }

  /// Send email verification to current user
  Future<void> sendEmailVerification() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw const AuthException.userNotFound();
      }

      await user.sendEmailVerification();
      debugPrint('✅ Email verification sent');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Email verification error: ${e.code} - ${e.message}');
      throw AuthException.fromFirebaseAuthException(e);
    } catch (e) {
      debugPrint('❌ Unexpected email verification error: $e');
      throw const AuthException.unknown();
    }
  }

  /// Reload current user data
  Future<void> reloadUser() async {
    try {
      await currentUser?.reload();
      debugPrint('✅ User data reloaded');
    } catch (e) {
      debugPrint('❌ User reload error: $e');
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw const AuthException.userNotFound();
      }

      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoURL);
      
      debugPrint('✅ User profile updated');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Profile update error: ${e.code} - ${e.message}');
      throw AuthException.fromFirebaseAuthException(e);
    } catch (e) {
      debugPrint('❌ Unexpected profile update error: $e');
      throw const AuthException.unknown();
    }
  }

  /// Link additional authentication provider to current account
  Future<UserCredential> linkWithCredential(AuthCredential credential) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw const AuthException.userNotFound();
      }

      final linkedCredential = await user.linkWithCredential(credential);
      debugPrint('✅ Authentication provider linked successfully');
      return linkedCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Provider linking error: ${e.code} - ${e.message}');
      throw AuthException.fromFirebaseAuthException(e);
    } catch (e) {
      debugPrint('❌ Unexpected provider linking error: $e');
      throw const AuthException.unknown();
    }
  }

  /// Unlink authentication provider from current account
  Future<User> unlinkProvider(String providerId) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw const AuthException.userNotFound();
      }

      final updatedUser = await user.unlink(providerId);
      debugPrint('✅ Authentication provider unlinked: $providerId');
      return updatedUser;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Provider unlinking error: ${e.code} - ${e.message}');
      throw AuthException.fromFirebaseAuthException(e);
    } catch (e) {
      debugPrint('❌ Unexpected provider unlinking error: $e');
      throw const AuthException.unknown();
    }
  }
}
