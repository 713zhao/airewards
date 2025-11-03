import 'package:flutter_test/flutter_test.dart';
import 'package:ai_rewards_system/core/errors/failures.dart';
import 'package:ai_rewards_system/core/utils/either.dart';
import 'package:ai_rewards_system/features/authentication/domain/entities/user.dart';
import 'package:ai_rewards_system/features/authentication/domain/entities/auth_provider.dart';
import 'package:ai_rewards_system/features/authentication/domain/repositories/auth_repository.dart';

// Mock implementation for testing the interface contract
class MockAuthRepository implements AuthRepository {
  User? _currentUser;
  final List<User> _users = [];
  bool _isSignedIn = false;

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    // Simulate Google sign-in
    final user = User(
      id: 'google-user-123',
      email: 'test@gmail.com',
      displayName: 'Test User',
      photoUrl: 'https://example.com/photo.jpg',
      provider: AuthProvider.google,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
    _currentUser = user;
    _isSignedIn = true;
    return Either.right(user);
  }

  @override
  Future<Either<Failure, User>> signInWithEmail(String email, String password) async {
    // Simulate email/password validation
    if (email == 'invalid@example.com') {
      return Either.left(AuthFailure.userNotFound());
    }
    if (password == 'wrongpassword') {
      return Either.left(AuthFailure.invalidCredentials());
    }

    final user = User(
      id: 'email-user-123',
      email: email,
      provider: AuthProvider.email,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
    _currentUser = user;
    _isSignedIn = true;
    return Either.right(user);
  }

  @override
  Future<Either<Failure, User>> signUpWithEmail(String email, String password) async {
    // Simulate email registration validation
    if (_users.any((user) => user.email == email)) {
      return Either.left(AuthFailure.emailAlreadyInUse());
    }
    if (password.length < 6) {
      return Either.left(AuthFailure.weakPassword());
    }

    final user = User(
      id: 'new-user-123',
      email: email,
      provider: AuthProvider.email,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
    _users.add(user);
    _currentUser = user;
    _isSignedIn = true;
    return Either.right(user);
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    _currentUser = null;
    _isSignedIn = false;
    return Either.right(null);
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    if (!_isSignedIn) {
      return Either.right(null);
    }
    return Either.right(_currentUser);
  }

  @override
  Stream<User?> get authStateChanges {
    return Stream.value(_currentUser);
  }

  @override
  Future<Either<Failure, bool>> isEmailVerified() async {
    if (_currentUser == null) {
      return Either.left(AuthFailure.sessionExpired());
    }
    // Google users are automatically verified
    if (_currentUser!.provider == AuthProvider.google) {
      return Either.right(true);
    }
    // Email users need verification
    return Either.right(false);
  }

  @override
  Future<Either<Failure, void>> sendEmailVerification() async {
    if (_currentUser == null) {
      return Either.left(AuthFailure.sessionExpired());
    }
    if (_currentUser!.provider != AuthProvider.email) {
      return Either.left(AuthFailure.invalidOperation());
    }
    return Either.right(null);
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    if (!_users.any((user) => user.email == email)) {
      return Either.left(AuthFailure.userNotFound());
    }
    return Either.right(null);
  }

  @override
  Future<Either<Failure, User>> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    if (_currentUser == null) {
      return Either.left(AuthFailure.sessionExpired());
    }

    final updatedUser = _currentUser!.copyWith(
      displayName: displayName,
      photoUrl: photoUrl,
    );
    _currentUser = updatedUser;
    return Either.right(updatedUser);
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    if (_currentUser == null) {
      return Either.left(AuthFailure.sessionExpired());
    }
    _users.removeWhere((user) => user.id == _currentUser!.id);
    _currentUser = null;
    _isSignedIn = false;
    return Either.right(null);
  }
}

void main() {
  group('AuthRepository Interface Tests', () {
    late MockAuthRepository repository;

    setUp(() {
      repository = MockAuthRepository();
    });

    group('signInWithGoogle', () {
      test('should return User on successful Google sign-in', () async {
        // Act
        final result = await repository.signInWithGoogle();

        // Assert
        expect(result.isRight, isTrue);
        final user = result.right;
        expect(user.email, equals('test@gmail.com'));
        expect(user.provider, equals(AuthProvider.google));
        expect(user.displayName, equals('Test User'));
        expect(user.photoUrl, isNotNull);
      });

      test('should update current user after successful sign-in', () async {
        // Act
        await repository.signInWithGoogle();
        final currentUserResult = await repository.getCurrentUser();

        // Assert
        expect(currentUserResult.isRight, isTrue);
        expect(currentUserResult.right, isNotNull);
        expect(currentUserResult.right!.provider, equals(AuthProvider.google));
      });
    });

    group('signInWithEmail', () {
      test('should return User on successful email sign-in', () async {
        // Act
        final result = await repository.signInWithEmail('test@example.com', 'password123');

        // Assert
        expect(result.isRight, isTrue);
        final user = result.right;
        expect(user.email, equals('test@example.com'));
        expect(user.provider, equals(AuthProvider.email));
      });

      test('should return AuthFailure for invalid credentials', () async {
        // Act
        final result = await repository.signInWithEmail('test@example.com', 'wrongpassword');

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left, isA<AuthFailure>());
      });

      test('should return AuthFailure for user not found', () async {
        // Act
        final result = await repository.signInWithEmail('invalid@example.com', 'password123');

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left, isA<AuthFailure>());
      });
    });

    group('signUpWithEmail', () {
      test('should return User on successful registration', () async {
        // Act
        final result = await repository.signUpWithEmail('newuser@example.com', 'password123');

        // Assert
        expect(result.isRight, isTrue);
        final user = result.right;
        expect(user.email, equals('newuser@example.com'));
        expect(user.provider, equals(AuthProvider.email));
      });

      test('should return AuthFailure for weak password', () async {
        // Act
        final result = await repository.signUpWithEmail('newuser@example.com', '123');

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left, isA<AuthFailure>());
      });

      test('should return AuthFailure for email already in use', () async {
        // Arrange - First registration
        await repository.signUpWithEmail('existing@example.com', 'password123');

        // Act - Try to register with same email
        final result = await repository.signUpWithEmail('existing@example.com', 'password456');

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left, isA<AuthFailure>());
      });
    });

    group('signOut', () {
      test('should return success and clear current user', () async {
        // Arrange - Sign in first
        await repository.signInWithEmail('test@example.com', 'password123');

        // Act
        final result = await repository.signOut();

        // Assert
        expect(result.isRight, isTrue);
        final currentUserResult = await repository.getCurrentUser();
        expect(currentUserResult.right, isNull);
      });
    });

    group('getCurrentUser', () {
      test('should return null when no user is signed in', () async {
        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right, isNull);
      });

      test('should return current user when signed in', () async {
        // Arrange
        await repository.signInWithEmail('test@example.com', 'password123');

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right, isNotNull);
        expect(result.right!.email, equals('test@example.com'));
      });
    });

    group('authStateChanges', () {
      test('should return stream of User changes', () {
        // Act
        final stream = repository.authStateChanges;

        // Assert
        expect(stream, isA<Stream<User?>>());
      });
    });

    group('isEmailVerified', () {
      test('should return true for Google provider', () async {
        // Arrange
        await repository.signInWithGoogle();

        // Act
        final result = await repository.isEmailVerified();

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right, isTrue);
      });

      test('should return false for email provider', () async {
        // Arrange
        await repository.signInWithEmail('test@example.com', 'password123');

        // Act
        final result = await repository.isEmailVerified();

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right, isFalse);
      });

      test('should return failure when no user is signed in', () async {
        // Act
        final result = await repository.isEmailVerified();

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left, isA<AuthFailure>());
      });
    });

    group('sendEmailVerification', () {
      test('should return success for email provider', () async {
        // Arrange
        await repository.signInWithEmail('test@example.com', 'password123');

        // Act
        final result = await repository.sendEmailVerification();

        // Assert
        expect(result.isRight, isTrue);
      });

      test('should return failure when no user is signed in', () async {
        // Act
        final result = await repository.sendEmailVerification();

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left, isA<AuthFailure>());
      });
    });

    group('sendPasswordResetEmail', () {
      test('should return success for existing user', () async {
        // Arrange
        await repository.signUpWithEmail('test@example.com', 'password123');

        // Act
        final result = await repository.sendPasswordResetEmail('test@example.com');

        // Assert
        expect(result.isRight, isTrue);
      });

      test('should return failure for non-existing user', () async {
        // Act
        final result = await repository.sendPasswordResetEmail('nonexisting@example.com');

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left, isA<AuthFailure>());
      });
    });

    group('updateProfile', () {
      test('should return updated User with new profile data', () async {
        // Arrange
        await repository.signInWithEmail('test@example.com', 'password123');

        // Act
        final result = await repository.updateProfile(
          displayName: 'Updated Name',
          photoUrl: 'https://example.com/new-photo.jpg',
        );

        // Assert
        expect(result.isRight, isTrue);
        final user = result.right;
        expect(user.displayName, equals('Updated Name'));
        expect(user.photoUrl, equals('https://example.com/new-photo.jpg'));
      });

      test('should return failure when no user is signed in', () async {
        // Act
        final result = await repository.updateProfile(displayName: 'Test Name');

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left, isA<AuthFailure>());
      });
    });

    group('deleteAccount', () {
      test('should return success and clear current user', () async {
        // Arrange
        await repository.signInWithEmail('test@example.com', 'password123');

        // Act
        final result = await repository.deleteAccount();

        // Assert
        expect(result.isRight, isTrue);
        final currentUserResult = await repository.getCurrentUser();
        expect(currentUserResult.right, isNull);
      });

      test('should return failure when no user is signed in', () async {
        // Act
        final result = await repository.deleteAccount();

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left, isA<AuthFailure>());
      });
    });

    group('Interface Contract Verification', () {
      test('all methods should return Either or Stream types', () {
        // This test verifies that the interface methods have correct return types
        final repository = MockAuthRepository();

        // Verify return types through runtime type checking
        expect(repository.signInWithGoogle(), isA<Future<Either<Failure, User>>>());
        expect(repository.signInWithEmail('', ''), isA<Future<Either<Failure, User>>>());
        expect(repository.signUpWithEmail('', ''), isA<Future<Either<Failure, User>>>());
        expect(repository.signOut(), isA<Future<Either<Failure, void>>>());
        expect(repository.getCurrentUser(), isA<Future<Either<Failure, User?>>>());
        expect(repository.authStateChanges, isA<Stream<User?>>());
        expect(repository.isEmailVerified(), isA<Future<Either<Failure, bool>>>());
        expect(repository.sendEmailVerification(), isA<Future<Either<Failure, void>>>());
        expect(repository.sendPasswordResetEmail(''), isA<Future<Either<Failure, void>>>());
        expect(repository.updateProfile(), isA<Future<Either<Failure, User>>>());
        expect(repository.deleteAccount(), isA<Future<Either<Failure, void>>>());
      });

      test('repository should be abstract interface', () {
        // Verify that AuthRepository is abstract by checking it's assignable
        AuthRepository repository = MockAuthRepository();
        expect(repository, isA<AuthRepository>());
      });
    });
  });
}