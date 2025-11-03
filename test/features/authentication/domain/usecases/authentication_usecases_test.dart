import 'package:flutter_test/flutter_test.dart';
import 'package:ai_rewards_system/core/errors/failures.dart';
import 'package:ai_rewards_system/core/utils/either.dart';
import 'package:ai_rewards_system/features/authentication/domain/entities/user.dart';
import 'package:ai_rewards_system/features/authentication/domain/entities/auth_provider.dart';
import 'package:ai_rewards_system/features/authentication/domain/repositories/auth_repository.dart';
import 'package:ai_rewards_system/features/authentication/domain/usecases/sign_in_with_google.dart';
import 'package:ai_rewards_system/features/authentication/domain/usecases/sign_in_with_email.dart';
import 'package:ai_rewards_system/features/authentication/domain/usecases/sign_up_with_email.dart';
import 'package:ai_rewards_system/features/authentication/domain/usecases/sign_out.dart';
import 'package:ai_rewards_system/features/authentication/domain/usecases/get_current_user.dart';

// Mock repository for testing
class MockAuthRepository implements AuthRepository {
  User? _currentUser;
  final List<String> _registeredEmails = [];
  bool _shouldFailSignIn = false;
  bool _shouldFailSignUp = false;
  bool _shouldFailSignOut = false;

  // Test helpers
  void setCurrentUser(User? user) => _currentUser = user;
  void setShouldFailSignIn(bool fail) => _shouldFailSignIn = fail;
  void setShouldFailSignUp(bool fail) => _shouldFailSignUp = fail;
  void setShouldFailSignOut(bool fail) => _shouldFailSignOut = fail;
  void addRegisteredEmail(String email) => _registeredEmails.add(email);
  void reset() {
    _currentUser = null;
    _registeredEmails.clear();
    _shouldFailSignIn = false;
    _shouldFailSignUp = false;
    _shouldFailSignOut = false;
  }

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    if (_shouldFailSignIn) {
      return Either.left(AuthFailure.cancelled());
    }

    final user = User(
      id: 'google-user-123',
      email: 'test@gmail.com',
      displayName: 'Test User',
      photoUrl: 'https://example.com/photo.jpg',
      provider: AuthProvider.google,
      createdAt: DateTime.now().subtract(Duration(days: 30)),
      lastLoginAt: DateTime.now().subtract(Duration(minutes: 5)),
    );
    _currentUser = user;
    return Either.right(user);
  }

  @override
  Future<Either<Failure, User>> signInWithEmail(String email, String password) async {
    if (_shouldFailSignIn) {
      return Either.left(AuthFailure.invalidCredentials());
    }

    if (!_registeredEmails.contains(email)) {
      return Either.left(AuthFailure.userNotFound());
    }

    if (password == 'wrongpassword') {
      return Either.left(AuthFailure.invalidCredentials());
    }

    final user = User(
      id: 'email-user-123',
      email: email,
      provider: AuthProvider.email,
      createdAt: DateTime.now().subtract(Duration(days: 30)),
      lastLoginAt: DateTime.now().subtract(Duration(minutes: 5)),
    );
    _currentUser = user;
    return Either.right(user);
  }

  @override
  Future<Either<Failure, User>> signUpWithEmail(String email, String password) async {
    if (_shouldFailSignUp) {
      return Either.left(AuthFailure.weakPassword());
    }

    if (_registeredEmails.contains(email)) {
      return Either.left(AuthFailure.emailAlreadyInUse());
    }

    _registeredEmails.add(email);
    final user = User(
      id: 'new-user-123',
      email: email,
      provider: AuthProvider.email,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
    _currentUser = user;
    return Either.right(user);
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    if (_shouldFailSignOut) {
      return Either.left(AuthFailure.unknown('Sign out failed'));
    }

    _currentUser = null;
    return Either.right(null);
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    return Either.right(_currentUser);
  }

  @override
  Stream<User?> get authStateChanges => Stream.value(_currentUser);

  @override
  Future<Either<Failure, bool>> isEmailVerified() async {
    if (_currentUser == null) {
      return Either.left(AuthFailure.sessionExpired());
    }
    return Either.right(_currentUser!.provider == AuthProvider.google);
  }

  @override
  Future<Either<Failure, void>> sendEmailVerification() async {
    if (_currentUser == null) {
      return Either.left(AuthFailure.sessionExpired());
    }
    return Either.right(null);
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    if (!_registeredEmails.contains(email)) {
      return Either.left(AuthFailure.userNotFound());
    }
    return Either.right(null);
  }

  @override
  Future<Either<Failure, User>> updateProfile({String? displayName, String? photoUrl}) async {
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
    _registeredEmails.remove(_currentUser!.email);
    _currentUser = null;
    return Either.right(null);
  }
}

void main() {
  group('Authentication Use Cases', () {
    late MockAuthRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthRepository();
    });

    tearDown(() {
      mockRepository.reset();
    });

    group('SignInWithGoogle', () {
      late SignInWithGoogle useCase;

      setUp(() {
        useCase = SignInWithGoogle(mockRepository);
      });

      test('should return User on successful Google sign-in', () async {
        // Act
        final result = await useCase();

        // Assert
        expect(result.isRight, isTrue);
        final user = result.right;
        expect(user.email, equals('test@gmail.com'));
        expect(user.provider, equals(AuthProvider.google));
        expect(user.displayName, equals('Test User'));
      });

      test('should update last login timestamp', () async {
        // Arrange
        final beforeLogin = DateTime.now();

        // Act
        final result = await useCase();

        // Assert
        expect(result.isRight, isTrue);
        final user = result.right;
        expect(user.lastLoginAt.isAfter(beforeLogin), isTrue);
      });

      test('should return AuthFailure when sign-in is cancelled', () async {
        // Arrange
        mockRepository.setShouldFailSignIn(true);

        // Act
        final result = await useCase();

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left, isA<AuthFailure>());
      });

      test('should check if Google services are available', () async {
        // Act
        final result = await useCase.isGoogleServicesAvailable();

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right, isTrue);
      });
    });

    group('SignInWithEmail', () {
      late SignInWithEmail useCase;

      setUp(() {
        useCase = SignInWithEmail(mockRepository);
        mockRepository.addRegisteredEmail('test@example.com');
      });

      group('SignInWithEmailParams', () {
        test('should create valid params with correct email and password', () {
          // Act
          final result = SignInWithEmailParams.create(
            email: 'test@example.com',
            password: 'ValidPass123',
          );

          // Assert
          expect(result.isRight, isTrue);
          final params = result.right;
          expect(params.email, equals('test@example.com'));
          expect(params.password, equals('ValidPass123'));
        });

        test('should return ValidationFailure for invalid email', () {
          // Act
          final result = SignInWithEmailParams.create(
            email: 'invalid-email',
            password: 'ValidPass123',
          );

          // Assert
          expect(result.isLeft, isTrue);
          expect(result.left, isA<ValidationFailure>());
        });

        test('should return ValidationFailure for empty password', () {
          // Act
          final result = SignInWithEmailParams.create(
            email: 'test@example.com',
            password: '',
          );

          // Assert
          expect(result.isLeft, isTrue);
          expect(result.left, isA<ValidationFailure>());
        });
      });

      test('should return User on successful email sign-in', () async {
        // Arrange
        final params = SignInWithEmailParams.create(
          email: 'test@example.com',
          password: 'ValidPass123',
        ).right;

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isRight, isTrue);
        final user = result.right;
        expect(user.email, equals('test@example.com'));
        expect(user.provider, equals(AuthProvider.email));
      });

      test('should return AuthFailure for invalid credentials', () async {
        // Arrange
        final params = SignInWithEmailParams.create(
          email: 'test@example.com',
          password: 'wrongpassword',
        ).right;

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left, isA<AuthFailure>());
      });

      test('should return AuthFailure for user not found', () async {
        // Arrange
        final params = SignInWithEmailParams.create(
          email: 'notfound@example.com',
          password: 'ValidPass123',
        ).right;

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left, isA<AuthFailure>());
      });

      test('should validate credentials', () async {
        // Act
        final result = await useCase.validateCredentials(
          email: 'test@example.com',
          password: 'ValidPass123',
        );

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right, isTrue);
      });
    });

    group('SignUpWithEmail', () {
      late SignUpWithEmail useCase;

      setUp(() {
        useCase = SignUpWithEmail(mockRepository);
      });

      group('SignUpWithEmailParams', () {
        test('should create valid params with all fields', () {
          // Act
          final result = SignUpWithEmailParams.create(
            email: 'newuser@example.com',
            password: 'ValidPass123',
            displayName: 'New User',
          );

          // Assert
          expect(result.isRight, isTrue);
          final params = result.right;
          expect(params.email, equals('newuser@example.com'));
          expect(params.password, equals('ValidPass123'));
          expect(params.displayName, equals('New User'));
        });

        test('should return ValidationFailure for weak password', () {
          // Act
          final result = SignUpWithEmailParams.create(
            email: 'test@example.com',
            password: 'weak',
          );

          // Assert
          expect(result.isLeft, isTrue);
          expect(result.left, isA<ValidationFailure>());
        });
      });

      test('should return User on successful registration', () async {
        // Arrange
        final params = SignUpWithEmailParams.create(
          email: 'newuser@example.com',
          password: 'ValidPass123',
          displayName: 'New User',
        ).right;

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isRight, isTrue);
        final user = result.right;
        expect(user.email, equals('newuser@example.com'));
        expect(user.provider, equals(AuthProvider.email));
      });

      test('should return AuthFailure for existing email', () async {
        // Arrange
        mockRepository.addRegisteredEmail('existing@example.com');
        final params = SignUpWithEmailParams.create(
          email: 'existing@example.com',
          password: 'ValidPass123',
        ).right;

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left, isA<AuthFailure>());
      });

      test('should validate password strength', () async {
        // Act
        final result = await useCase.validatePasswordStrength('ValidPass123');

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right, isA<String>());
      });
    });

    group('SignOut', () {
      late SignOut useCase;

      setUp(() {
        useCase = SignOut(mockRepository);
      });

      test('should return success on successful sign-out', () async {
        // Arrange - Set a current user
        final user = User(
          id: 'test-id',
          email: 'test@example.com',
          provider: AuthProvider.email,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        mockRepository.setCurrentUser(user);

        // Act
        final result = await useCase();

        // Assert
        expect(result.isRight, isTrue);
        
        // Verify user is cleared
        final currentUserResult = await mockRepository.getCurrentUser();
        expect(currentUserResult.right, isNull);
      });

      test('should return success when no user is signed in', () async {
        // Act
        final result = await useCase();

        // Assert
        expect(result.isRight, isTrue);
      });

      test('should return failure when sign-out fails', () async {
        // Arrange
        final user = User(
          id: 'test-id',
          email: 'test@example.com',
          provider: AuthProvider.email,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        mockRepository.setCurrentUser(user);
        mockRepository.setShouldFailSignOut(true);

        // Act
        final result = await useCase();

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left, isA<AuthFailure>());
      });

      test('should force sign out even with errors', () async {
        // Arrange
        final user = User(
          id: 'test-id',
          email: 'test@example.com',
          provider: AuthProvider.email,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        mockRepository.setCurrentUser(user);

        // Act
        final result = await useCase.forceSignOut();

        // Assert
        expect(result.isRight, isTrue);
      });

      test('should check if user is signed in', () async {
        // Arrange
        final user = User(
          id: 'test-id',
          email: 'test@example.com',
          provider: AuthProvider.email,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        mockRepository.setCurrentUser(user);

        // Act
        final result = await useCase.isUserSignedIn();

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right, isTrue);
      });
    });

    group('GetCurrentUser', () {
      late GetCurrentUser useCase;

      setUp(() {
        useCase = GetCurrentUser(mockRepository);
      });

      test('should return current user when signed in', () async {
        // Arrange
        final user = User(
          id: 'test-id',
          email: 'test@example.com',
          provider: AuthProvider.email,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        mockRepository.setCurrentUser(user);

        // Act
        final result = await useCase();

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right, isNotNull);
        expect(result.right!.email, equals('test@example.com'));
      });

      test('should return null when no user is signed in', () async {
        // Act
        final result = await useCase();

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right, isNull);
      });

      test('should check authentication status', () async {
        // Arrange
        final user = User(
          id: 'test-id',
          email: 'test@example.com',
          provider: AuthProvider.google,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        mockRepository.setCurrentUser(user);

        // Act
        final result = await useCase.isUserAuthenticated();

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right, isTrue);
      });

      test('should return detailed authentication status', () async {
        // Arrange
        final user = User(
          id: 'test-id',
          email: 'test@example.com',
          provider: AuthProvider.google,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        mockRepository.setCurrentUser(user);

        // Act
        final result = await useCase.getAuthenticationStatus();

        // Assert
        expect(result.isRight, isTrue);
        final status = result.right;
        expect(status.isAuthenticated, isTrue);
        expect(status.user, equals(user));
        expect(status.isEmailVerified, isTrue);
        expect(status.sessionAge, isNotNull);
      });

      test('should refresh user data when requested', () async {
        // Arrange
        final user = User(
          id: 'test-id',
          email: 'test@example.com',
          provider: AuthProvider.email,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now().subtract(Duration(hours: 2)),
        );
        mockRepository.setCurrentUser(user);

        // Act
        final result = await useCase.getCurrentUserWithRefresh();

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right, isNotNull);
      });
    });

    group('AuthenticationStatus', () {
      test('should create authenticated status', () {
        // Arrange
        final user = User(
          id: 'test-id',
          email: 'test@example.com',
          provider: AuthProvider.email,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        // Act
        final status = AuthenticationStatus.authenticated(
          user: user,
          isEmailVerified: true,
          sessionAge: Duration(minutes: 30),
        );

        // Assert
        expect(status.isAuthenticated, isTrue);
        expect(status.user, equals(user));
        expect(status.isEmailVerified, isTrue);
        expect(status.sessionAge, equals(Duration(minutes: 30)));
      });

      test('should create unauthenticated status', () {
        // Act
        final status = AuthenticationStatus.unauthenticated();

        // Assert
        expect(status.isAuthenticated, isFalse);
        expect(status.user, isNull);
        expect(status.isEmailVerified, isFalse);
        expect(status.sessionAge, isNull);
      });

      test('should determine session freshness', () {
        // Arrange
        final user = User(
          id: 'test-id',
          email: 'test@example.com',
          provider: AuthProvider.email,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        final freshStatus = AuthenticationStatus.authenticated(
          user: user,
          isEmailVerified: true,
          sessionAge: Duration(minutes: 30),
        );

        final staleStatus = AuthenticationStatus.authenticated(
          user: user,
          isEmailVerified: true,
          sessionAge: Duration(hours: 25),
        );

        // Assert
        expect(freshStatus.isSessionFresh, isTrue);
        expect(freshStatus.requiresRefresh, isFalse);
        expect(staleStatus.isSessionFresh, isFalse);
        expect(staleStatus.requiresRefresh, isTrue);
      });
    });
  });
}