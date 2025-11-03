import 'package:flutter_test/flutter_test.dart';
import 'package:ai_rewards_system/core/errors/failures.dart';
import 'package:ai_rewards_system/core/usecases/usecase.dart';
import 'package:ai_rewards_system/core/utils/either.dart';
import 'package:ai_rewards_system/features/authentication/domain/entities/user.dart';
import 'package:ai_rewards_system/features/authentication/domain/entities/auth_provider.dart';
import 'package:ai_rewards_system/features/authentication/domain/repositories/auth_repository.dart';
import 'package:ai_rewards_system/features/authentication/domain/usecases/sign_in_with_google.dart';
import 'package:ai_rewards_system/features/authentication/domain/usecases/sign_in_with_email.dart';
import 'package:ai_rewards_system/features/authentication/domain/usecases/sign_out.dart';

// Simple mock for testing
class TestAuthRepository implements AuthRepository {
  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    return Either.right(User(
      id: 'test-id',
      email: 'test@gmail.com',
      displayName: 'Test User',
      provider: AuthProvider.google,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    ));
  }

  @override
  Future<Either<Failure, User>> signInWithEmail(String email, String password) async {
    return Either.right(User(
      id: 'test-id',
      email: email,
      provider: AuthProvider.email,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    ));
  }

  @override
  Future<Either<Failure, User>> signUpWithEmail(String email, String password) async {
    return Either.right(User(
      id: 'test-id',
      email: email,
      provider: AuthProvider.email,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    ));
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    return Either.right(null);
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    return Either.right(null);
  }

  @override
  Stream<User?> get authStateChanges => Stream.value(null);

  @override
  Future<Either<Failure, bool>> isEmailVerified() async => Either.right(false);

  @override
  Future<Either<Failure, void>> sendEmailVerification() async => Either.right(null);

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async => Either.right(null);

  @override
  Future<Either<Failure, User>> updateProfile({String? displayName, String? photoUrl}) async {
    return Either.right(User(
      id: 'test-id',
      email: 'test@example.com',
      displayName: displayName,
      photoUrl: photoUrl,
      provider: AuthProvider.email,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    ));
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async => Either.right(null);
}

void main() {
  group('Authentication Use Cases Integration Test', () {
    late TestAuthRepository repository;

    setUp(() {
      repository = TestAuthRepository();
    });

    test('SignInWithGoogle should implement NoParamsUseCase correctly', () async {
      // Arrange
      final useCase = SignInWithGoogle(repository);

      // Act
      final result = await useCase();

      // Assert
      expect(result.isRight, isTrue);
      expect(result.right.provider, equals(AuthProvider.google));
    });

    test('SignInWithEmail should implement UseCase correctly', () async {
      // Arrange
      final useCase = SignInWithEmail(repository);
      final params = SignInWithEmailParams.create(
        email: 'test@example.com',
        password: 'ValidPass123',
      ).right;

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isRight, isTrue);
      expect(result.right.email, equals('test@example.com'));
    });

    test('SignOut should implement NoParamsUseCase correctly', () async {
      // Arrange
      final useCase = SignOut(repository);

      // Act
      final result = await useCase();

      // Assert
      expect(result.isRight, isTrue);
    });

    test('Use cases should follow clean architecture pattern', () {
      // Verify that use cases implement the correct interfaces
      final signInGoogle = SignInWithGoogle(repository);
      final signOut = SignOut(repository);

      expect(signInGoogle, isA<NoParamsUseCase<User>>());
      expect(signOut, isA<NoParamsUseCase<void>>());
    });
  });
}