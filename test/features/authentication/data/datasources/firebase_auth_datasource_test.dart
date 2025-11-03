import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../lib/core/errors/exceptions.dart';
import '../../../../lib/core/utils/either.dart';
import '../../../../lib/features/authentication/data/datasources/firebase_auth_datasource.dart';
import '../../../../lib/features/authentication/data/models/user_model.dart';
import '../../../../lib/features/authentication/domain/entities/entities.dart';

// Mock classes
@GenerateMocks([
  firebase_auth.FirebaseAuth,
  firebase_auth.User,
  firebase_auth.UserCredential,
  firebase_auth.UserMetadata,
  GoogleSignIn,
  GoogleSignInAccount,
  GoogleSignInAuthentication,
])
import 'firebase_auth_datasource_test.mocks.dart';

void main() {
  late FirebaseAuthDataSourceImpl dataSource;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockUser mockUser;
  late MockUserCredential mockUserCredential;
  late MockUserMetadata mockUserMetadata;
  late MockGoogleSignInAccount mockGoogleSignInAccount;
  late MockGoogleSignInAuthentication mockGoogleSignInAuth;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    mockUser = MockUser();
    mockUserCredential = MockUserCredential();
    mockUserMetadata = MockUserMetadata();
    mockGoogleSignInAccount = MockGoogleSignInAccount();
    mockGoogleSignInAuth = MockGoogleSignInAuthentication();

    dataSource = FirebaseAuthDataSourceImpl(
      firebaseAuth: mockFirebaseAuth,
      googleSignIn: mockGoogleSignIn,
    );
  });

  tearDown(() {
    dataSource.dispose();
  });

  group('FirebaseAuthDataSource - getCurrentUser', () {
    test('should return null when no user is authenticated', () async {
      // Arrange
      when(mockFirebaseAuth.currentUser).thenReturn(null);

      // Act
      final result = await dataSource.getCurrentUser();

      // Assert
      expect(result.isRight(), true);
      expect(result.getRight(), null);
      verify(mockFirebaseAuth.currentUser).called(1);
    });

    test('should return UserModel when user is authenticated', () async {
      // Arrange
      const userId = 'test_user_id';
      const email = 'test@example.com';
      const displayName = 'Test User';
      final creationTime = DateTime.now().subtract(const Duration(days: 30));
      final lastSignInTime = DateTime.now();

      when(mockUser.uid).thenReturn(userId);
      when(mockUser.email).thenReturn(email);
      when(mockUser.displayName).thenReturn(displayName);
      when(mockUser.photoURL).thenReturn(null);
      when(mockUser.metadata).thenReturn(mockUserMetadata);
      when(mockUserMetadata.creationTime).thenReturn(creationTime);
      when(mockUserMetadata.lastSignInTime).thenReturn(lastSignInTime);

      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.reload()).thenAnswer((_) async {});

      // Act
      final result = await dataSource.getCurrentUser();

      // Assert
      expect(result.isRight(), true);
      final userModel = result.getRight() as UserModel;
      expect(userModel.id, userId);
      expect(userModel.email, email);
      expect(userModel.displayName, displayName);
      verify(mockUser.reload()).called(1);
    });

    test('should return AuthException on error', () async {
      // Arrange
      when(mockFirebaseAuth.currentUser).thenThrow(Exception('Network error'));

      // Act
      final result = await dataSource.getCurrentUser();

      // Assert
      expect(result.isLeft(), true);
      expect(result.getLeft(), isA<AuthException>());
    });
  });

  group('FirebaseAuthDataSource - signInWithGoogle', () {
    test('should return UserModel on successful Google sign-in', () async {
      // Arrange
      const userId = 'google_user_id';
      const email = 'google@example.com';
      const accessToken = 'access_token';
      const idToken = 'id_token';

      when(mockGoogleSignIn.signIn()).thenAnswer((_) async => mockGoogleSignInAccount);
      when(mockGoogleSignInAccount.authentication).thenAnswer((_) async => mockGoogleSignInAuth);
      when(mockGoogleSignInAuth.accessToken).thenReturn(accessToken);
      when(mockGoogleSignInAuth.idToken).thenReturn(idToken);
      
      when(mockFirebaseAuth.signInWithCredential(any)).thenAnswer((_) async => mockUserCredential);
      when(mockUserCredential.user).thenReturn(mockUser);
      
      when(mockUser.uid).thenReturn(userId);
      when(mockUser.email).thenReturn(email);
      when(mockUser.displayName).thenReturn(null);
      when(mockUser.photoURL).thenReturn(null);
      when(mockUser.metadata).thenReturn(mockUserMetadata);
      when(mockUserMetadata.creationTime).thenReturn(DateTime.now());
      when(mockUserMetadata.lastSignInTime).thenReturn(DateTime.now());

      // Act
      final result = await dataSource.signInWithGoogle();

      // Assert
      expect(result.isRight(), true);
      final userModel = result.getRight() as UserModel;
      expect(userModel.id, userId);
      expect(userModel.email, email);
      expect(userModel.provider, AuthProvider.google);
      verify(mockGoogleSignIn.signIn()).called(1);
    });

    test('should return AuthException when Google sign-in is cancelled', () async {
      // Arrange
      when(mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

      // Act
      final result = await dataSource.signInWithGoogle();

      // Assert
      expect(result.isLeft(), true);
      final exception = result.getLeft() as AuthException;
      expect(exception.message, 'Google Sign-In was cancelled by user');
    });

    test('should return AuthException when authentication tokens are missing', () async {
      // Arrange
      when(mockGoogleSignIn.signIn()).thenAnswer((_) async => mockGoogleSignInAccount);
      when(mockGoogleSignInAccount.authentication).thenAnswer((_) async => mockGoogleSignInAuth);
      when(mockGoogleSignInAuth.accessToken).thenReturn(null);
      when(mockGoogleSignInAuth.idToken).thenReturn('id_token');

      // Act
      final result = await dataSource.signInWithGoogle();

      // Assert
      expect(result.isLeft(), true);
      final exception = result.getLeft() as AuthException;
      expect(exception.message, 'Failed to get Google authentication tokens');
    });

    test('should handle FirebaseAuthException properly', () async {
      // Arrange
      when(mockGoogleSignIn.signIn()).thenAnswer((_) async => mockGoogleSignInAccount);
      when(mockGoogleSignInAccount.authentication).thenAnswer((_) async => mockGoogleSignInAuth);
      when(mockGoogleSignInAuth.accessToken).thenReturn('access_token');
      when(mockGoogleSignInAuth.idToken).thenReturn('id_token');
      
      when(mockFirebaseAuth.signInWithCredential(any)).thenThrow(
        firebase_auth.FirebaseAuthException(code: 'network-request-failed'),
      );

      // Act
      final result = await dataSource.signInWithGoogle();

      // Assert
      expect(result.isLeft(), true);
      final exception = result.getLeft() as AuthException;
      expect(exception.message, 'Network error. Please check your connection');
    });
  });

  group('FirebaseAuthDataSource - signInWithEmail', () {
    test('should return UserModel on successful email sign-in', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';
      const userId = 'email_user_id';

      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      )).thenAnswer((_) async => mockUserCredential);
      
      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockUser.uid).thenReturn(userId);
      when(mockUser.email).thenReturn(email);
      when(mockUser.displayName).thenReturn(null);
      when(mockUser.photoURL).thenReturn(null);
      when(mockUser.metadata).thenReturn(mockUserMetadata);
      when(mockUserMetadata.creationTime).thenReturn(DateTime.now());
      when(mockUserMetadata.lastSignInTime).thenReturn(DateTime.now());

      // Act
      final result = await dataSource.signInWithEmail(email: email, password: password);

      // Assert
      expect(result.isRight(), true);
      final userModel = result.getRight() as UserModel;
      expect(userModel.id, userId);
      expect(userModel.email, email);
      expect(userModel.provider, AuthProvider.email);
    });

    test('should return AuthException for empty email', () async {
      // Act
      final result = await dataSource.signInWithEmail(email: '', password: 'password123');

      // Assert
      expect(result.isLeft(), true);
      final exception = result.getLeft() as AuthException;
      expect(exception.message, 'Email cannot be empty');
    });

    test('should return AuthException for empty password', () async {
      // Act
      final result = await dataSource.signInWithEmail(email: 'test@example.com', password: '');

      // Assert
      expect(result.isLeft(), true);
      final exception = result.getLeft() as AuthException;
      expect(exception.message, 'Password cannot be empty');
    });

    test('should return AuthException for invalid email format', () async {
      // Act
      final result = await dataSource.signInWithEmail(email: 'invalid-email', password: 'password123');

      // Assert
      expect(result.isLeft(), true);
      final exception = result.getLeft() as AuthException;
      expect(exception.message, 'Invalid email format');
    });

    test('should handle wrong-password FirebaseAuthException', () async {
      // Arrange
      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'wrongpassword',
      )).thenThrow(
        firebase_auth.FirebaseAuthException(code: 'wrong-password'),
      );

      // Act
      final result = await dataSource.signInWithEmail(
        email: 'test@example.com',
        password: 'wrongpassword',
      );

      // Assert
      expect(result.isLeft(), true);
      final exception = result.getLeft() as AuthException;
      expect(exception.message, 'Incorrect password');
    });
  });

  group('FirebaseAuthDataSource - signUpWithEmail', () {
    test('should return UserModel on successful email sign-up', () async {
      // Arrange
      const email = 'newuser@example.com';
      const password = 'password123';
      const displayName = 'New User';
      const userId = 'new_user_id';

      when(mockFirebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      )).thenAnswer((_) async => mockUserCredential);
      
      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockUser.updateDisplayName(displayName)).thenAnswer((_) async {});
      when(mockUser.reload()).thenAnswer((_) async {});
      
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn(userId);
      when(mockUser.email).thenReturn(email);
      when(mockUser.displayName).thenReturn(displayName);
      when(mockUser.photoURL).thenReturn(null);
      when(mockUser.metadata).thenReturn(mockUserMetadata);
      when(mockUserMetadata.creationTime).thenReturn(DateTime.now());
      when(mockUserMetadata.lastSignInTime).thenReturn(DateTime.now());

      // Act
      final result = await dataSource.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );

      // Assert
      expect(result.isRight(), true);
      final userModel = result.getRight() as UserModel;
      expect(userModel.id, userId);
      expect(userModel.email, email);
      expect(userModel.displayName, displayName);
    });

    test('should return AuthException for weak password', () async {
      // Arrange
      when(mockFirebaseAuth.createUserWithEmailAndPassword(
        email: 'test@example.com',
        password: '123',
      )).thenThrow(
        firebase_auth.FirebaseAuthException(code: 'weak-password'),
      );

      // Act
      final result = await dataSource.signUpWithEmail(
        email: 'test@example.com',
        password: '123',
      );

      // Assert
      expect(result.isLeft(), true);
      final exception = result.getLeft() as AuthException;
      expect(exception.message, 'Password is too weak');
    });

    test('should return AuthException for short password', () async {
      // Act
      final result = await dataSource.signUpWithEmail(
        email: 'test@example.com',
        password: '123',
      );

      // Assert
      expect(result.isLeft(), true);
      final exception = result.getLeft() as AuthException;
      expect(exception.message, 'Password must be at least 6 characters');
    });
  });

  group('FirebaseAuthDataSource - signOut', () {
    test('should sign out successfully', () async {
      // Arrange
      when(mockFirebaseAuth.signOut()).thenAnswer((_) async {});
      when(mockGoogleSignIn.isSignedIn()).thenAnswer((_) async => false);

      // Act
      final result = await dataSource.signOut();

      // Assert
      expect(result.isRight(), true);
      verify(mockFirebaseAuth.signOut()).called(1);
    });

    test('should sign out from Google Sign-In when signed in', () async {
      // Arrange
      when(mockFirebaseAuth.signOut()).thenAnswer((_) async {});
      when(mockGoogleSignIn.isSignedIn()).thenAnswer((_) async => true);
      when(mockGoogleSignIn.signOut()).thenAnswer((_) async => null);

      // Act
      final result = await dataSource.signOut();

      // Assert
      expect(result.isRight(), true);
      verify(mockFirebaseAuth.signOut()).called(1);
      verify(mockGoogleSignIn.signOut()).called(1);
    });

    test('should return AuthException on sign-out error', () async {
      // Arrange
      when(mockFirebaseAuth.signOut()).thenThrow(Exception('Sign-out error'));

      // Act
      final result = await dataSource.signOut();

      // Assert
      expect(result.isLeft(), true);
      expect(result.getLeft(), isA<AuthException>());
    });
  });

  group('FirebaseAuthDataSource - sendPasswordResetEmail', () {
    test('should send password reset email successfully', () async {
      // Arrange
      const email = 'test@example.com';
      when(mockFirebaseAuth.sendPasswordResetEmail(email: email))
          .thenAnswer((_) async {});

      // Act
      final result = await dataSource.sendPasswordResetEmail(email);

      // Assert
      expect(result.isRight(), true);
      verify(mockFirebaseAuth.sendPasswordResetEmail(email: email)).called(1);
    });

    test('should return AuthException for empty email', () async {
      // Act
      final result = await dataSource.sendPasswordResetEmail('');

      // Assert
      expect(result.isLeft(), true);
      final exception = result.getLeft() as AuthException;
      expect(exception.message, 'Email cannot be empty');
    });

    test('should return AuthException for invalid email', () async {
      // Act
      final result = await dataSource.sendPasswordResetEmail('invalid-email');

      // Assert
      expect(result.isLeft(), true);
      final exception = result.getLeft() as AuthException;
      expect(exception.message, 'Invalid email format');
    });
  });

  group('FirebaseAuthDataSource - updateProfile', () {
    test('should update profile successfully', () async {
      // Arrange
      const displayName = 'Updated Name';
      const photoURL = 'https://example.com/photo.jpg';
      const userId = 'user_id';

      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.updateDisplayName(displayName)).thenAnswer((_) async {});
      when(mockUser.updatePhotoURL(photoURL)).thenAnswer((_) async {});
      when(mockUser.reload()).thenAnswer((_) async {});
      
      when(mockUser.uid).thenReturn(userId);
      when(mockUser.email).thenReturn('test@example.com');
      when(mockUser.displayName).thenReturn(displayName);
      when(mockUser.photoURL).thenReturn(photoURL);
      when(mockUser.metadata).thenReturn(mockUserMetadata);
      when(mockUserMetadata.creationTime).thenReturn(DateTime.now());
      when(mockUserMetadata.lastSignInTime).thenReturn(DateTime.now());

      // Act
      final result = await dataSource.updateProfile(
        displayName: displayName,
        photoURL: photoURL,
      );

      // Assert
      expect(result.isRight(), true);
      final userModel = result.getRight() as UserModel;
      expect(userModel.displayName, displayName);
      expect(userModel.photoUrl, photoURL);
      verify(mockUser.updateDisplayName(displayName)).called(1);
      verify(mockUser.updatePhotoURL(photoURL)).called(1);
    });

    test('should return AuthException when no user is authenticated', () async {
      // Arrange
      when(mockFirebaseAuth.currentUser).thenReturn(null);

      // Act
      final result = await dataSource.updateProfile(displayName: 'New Name');

      // Assert
      expect(result.isLeft(), true);
      final exception = result.getLeft() as AuthException;
      expect(exception.message, 'No authenticated user');
    });
  });

  group('FirebaseAuthDataSource - refreshToken', () {
    test('should refresh token successfully', () async {
      // Arrange
      const token = 'refreshed_token';
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.getIdToken(true)).thenAnswer((_) async => token);

      // Act
      final result = await dataSource.refreshToken();

      // Assert
      expect(result.isRight(), true);
      expect(result.getRight(), token);
      verify(mockUser.getIdToken(true)).called(1);
    });

    test('should return AuthException when no user is authenticated', () async {
      // Arrange
      when(mockFirebaseAuth.currentUser).thenReturn(null);

      // Act
      final result = await dataSource.refreshToken();

      // Assert
      expect(result.isLeft(), true);
      final exception = result.getLeft() as AuthException;
      expect(exception.message, 'No authenticated user');
    });

    test('should return AuthException when token is null', () async {
      // Arrange
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.getIdToken(true)).thenAnswer((_) async => null);

      // Act
      final result = await dataSource.refreshToken();

      // Assert
      expect(result.isLeft(), true);
      final exception = result.getLeft() as AuthException;
      expect(exception.message, 'Failed to get authentication token');
    });
  });

  group('FirebaseAuthDataSource - deleteAccount', () {
    test('should delete account successfully', () async {
      // Arrange
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.delete()).thenAnswer((_) async {});
      when(mockGoogleSignIn.isSignedIn()).thenAnswer((_) async => false);

      // Act
      final result = await dataSource.deleteAccount();

      // Assert
      expect(result.isRight(), true);
      verify(mockUser.delete()).called(1);
    });

    test('should return AuthException when no user is authenticated', () async {
      // Arrange
      when(mockFirebaseAuth.currentUser).thenReturn(null);

      // Act
      final result = await dataSource.deleteAccount();

      // Assert
      expect(result.isLeft(), true);
      final exception = result.getLeft() as AuthException;
      expect(exception.message, 'No authenticated user');
    });
  });

  group('FirebaseAuthDataSource - authStateChanges', () {
    test('should emit UserModel when user signs in', () async {
      // Arrange
      const userId = 'test_user_id';
      const email = 'test@example.com';
      
      final StreamController<firebase_auth.User?> authController = 
          StreamController<firebase_auth.User?>();
      
      when(mockFirebaseAuth.authStateChanges())
          .thenAnswer((_) => authController.stream);
      
      when(mockUser.uid).thenReturn(userId);
      when(mockUser.email).thenReturn(email);
      when(mockUser.displayName).thenReturn(null);
      when(mockUser.photoURL).thenReturn(null);
      when(mockUser.metadata).thenReturn(mockUserMetadata);
      when(mockUserMetadata.creationTime).thenReturn(DateTime.now());
      when(mockUserMetadata.lastSignInTime).thenReturn(DateTime.now());

      // Create new data source to test stream
      final testDataSource = FirebaseAuthDataSourceImpl(
        firebaseAuth: mockFirebaseAuth,
        googleSignIn: mockGoogleSignIn,
      );

      // Act & Assert
      expectLater(
        testDataSource.authStateChanges,
        emitsInOrder([
          isA<UserModel>().having((u) => u.id, 'id', userId),
          null,
        ]),
      );

      authController.add(mockUser);
      authController.add(null);
      
      await Future.delayed(const Duration(milliseconds: 100));
      authController.close();
      testDataSource.dispose();
    });
  });

  group('FirebaseAuthDataSource - Exception Handling', () {
    test('should map FirebaseAuthException codes correctly', () async {
      // Test various Firebase Auth exception codes
      final testCases = {
        'user-not-found': 'No account found with this email address',
        'wrong-password': 'Incorrect password',
        'email-already-in-use': 'An account with this email already exists',
        'weak-password': 'Password is too weak',
        'invalid-email': 'Invalid email address format',
        'user-disabled': 'This account has been disabled',
        'too-many-requests': 'Too many failed attempts. Please try again later',
        'network-request-failed': 'Network error. Please check your connection',
      };

      for (final entry in testCases.entries) {
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password',
        )).thenThrow(
          firebase_auth.FirebaseAuthException(code: entry.key),
        );

        final result = await dataSource.signInWithEmail(
          email: 'test@example.com',
          password: 'password',
        );

        expect(result.isLeft(), true);
        final exception = result.getLeft() as AuthException;
        expect(exception.message, entry.value);
      }
    });
  });
}