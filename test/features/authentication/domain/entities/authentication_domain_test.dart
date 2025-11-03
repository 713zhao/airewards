import 'package:flutter_test/flutter_test.dart';
import 'package:ai_rewards_system/features/authentication/domain/entities/user.dart';
import 'package:ai_rewards_system/features/authentication/domain/entities/auth_provider.dart';
import 'package:ai_rewards_system/features/authentication/domain/entities/value_objects.dart';

void main() {
  group('User Entity Tests', () {
    late DateTime testCreatedAt;
    late DateTime testLastLoginAt;

    setUp(() {
      testCreatedAt = DateTime(2024, 1, 1);
      testLastLoginAt = DateTime(2024, 1, 2);
    });

    test('should create a User with all required properties', () {
      // Arrange & Act
      final user = User(
        id: 'test-id',
        email: 'test@example.com',
        provider: AuthProvider.google,
        createdAt: testCreatedAt,
        lastLoginAt: testLastLoginAt,
      );

      // Assert
      expect(user.id, equals('test-id'));
      expect(user.email, equals('test@example.com'));
      expect(user.provider, equals(AuthProvider.google));
      expect(user.createdAt, equals(testCreatedAt));
      expect(user.lastLoginAt, equals(testLastLoginAt));
      expect(user.displayName, isNull);
      expect(user.photoUrl, isNull);
    });

    test('should create a User with optional properties', () {
      // Arrange & Act
      final user = User(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        photoUrl: 'https://example.com/photo.jpg',
        provider: AuthProvider.email,
        createdAt: testCreatedAt,
        lastLoginAt: testLastLoginAt,
      );

      // Assert
      expect(user.displayName, equals('Test User'));
      expect(user.photoUrl, equals('https://example.com/photo.jpg'));
    });

    test('should create a copy with updated fields', () {
      // Arrange
      final originalUser = User(
        id: 'test-id',
        email: 'test@example.com',
        provider: AuthProvider.google,
        createdAt: testCreatedAt,
        lastLoginAt: testLastLoginAt,
      );

      // Act
      final updatedUser = originalUser.copyWith(
        displayName: 'Updated Name',
        photoUrl: 'https://example.com/new-photo.jpg',
      );

      // Assert
      expect(updatedUser.id, equals(originalUser.id));
      expect(updatedUser.email, equals(originalUser.email));
      expect(updatedUser.displayName, equals('Updated Name'));
      expect(updatedUser.photoUrl, equals('https://example.com/new-photo.jpg'));
      expect(updatedUser.provider, equals(originalUser.provider));
    });

    test('should update last login time', () {
      // Arrange
      final user = User(
        id: 'test-id',
        email: 'test@example.com',
        provider: AuthProvider.google,
        createdAt: testCreatedAt,
        lastLoginAt: testLastLoginAt,
      );
      final beforeUpdate = DateTime.now();

      // Act
      final updatedUser = user.updateLastLogin();
      final afterUpdate = DateTime.now();

      // Assert
      expect(updatedUser.lastLoginAt.isAfter(beforeUpdate) ||
             updatedUser.lastLoginAt.isAtSameMomentAs(beforeUpdate), isTrue);
      expect(updatedUser.lastLoginAt.isBefore(afterUpdate) ||
             updatedUser.lastLoginAt.isAtSameMomentAs(afterUpdate), isTrue);
    });

    test('should correctly identify complete profile', () {
      // Arrange
      final userWithCompleteProfile = User(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        provider: AuthProvider.google,
        createdAt: testCreatedAt,
        lastLoginAt: testLastLoginAt,
      );

      final userWithIncompleteProfile = User(
        id: 'test-id',
        email: 'test@example.com',
        provider: AuthProvider.email,
        createdAt: testCreatedAt,
        lastLoginAt: testLastLoginAt,
      );

      final userWithEmptyDisplayName = User(
        id: 'test-id',
        email: 'test@example.com',
        displayName: '',
        provider: AuthProvider.email,
        createdAt: testCreatedAt,
        lastLoginAt: testLastLoginAt,
      );

      // Act & Assert
      expect(userWithCompleteProfile.hasCompleteProfile, isTrue);
      expect(userWithIncompleteProfile.hasCompleteProfile, isFalse);
      expect(userWithEmptyDisplayName.hasCompleteProfile, isFalse);
    });

    test('should return correct display name or email', () {
      // Arrange
      final userWithDisplayName = User(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        provider: AuthProvider.google,
        createdAt: testCreatedAt,
        lastLoginAt: testLastLoginAt,
      );

      final userWithoutDisplayName = User(
        id: 'test-id',
        email: 'test@example.com',
        provider: AuthProvider.email,
        createdAt: testCreatedAt,
        lastLoginAt: testLastLoginAt,
      );

      // Act & Assert
      expect(userWithDisplayName.displayNameOrEmail, equals('Test User'));
      expect(userWithoutDisplayName.displayNameOrEmail, equals('test@example.com'));
    });

    test('should correctly identify profile photo presence', () {
      // Arrange
      final userWithPhoto = User(
        id: 'test-id',
        email: 'test@example.com',
        photoUrl: 'https://example.com/photo.jpg',
        provider: AuthProvider.google,
        createdAt: testCreatedAt,
        lastLoginAt: testLastLoginAt,
      );

      final userWithoutPhoto = User(
        id: 'test-id',
        email: 'test@example.com',
        provider: AuthProvider.email,
        createdAt: testCreatedAt,
        lastLoginAt: testLastLoginAt,
      );

      final userWithEmptyPhotoUrl = User(
        id: 'test-id',
        email: 'test@example.com',
        photoUrl: '',
        provider: AuthProvider.email,
        createdAt: testCreatedAt,
        lastLoginAt: testLastLoginAt,
      );

      // Act & Assert
      expect(userWithPhoto.hasProfilePhoto, isTrue);
      expect(userWithoutPhoto.hasProfilePhoto, isFalse);
      expect(userWithEmptyPhotoUrl.hasProfilePhoto, isFalse);
    });

    test('should implement equality correctly', () {
      // Arrange
      final user1 = User(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        provider: AuthProvider.google,
        createdAt: testCreatedAt,
        lastLoginAt: testLastLoginAt,
      );

      final user2 = User(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        provider: AuthProvider.google,
        createdAt: testCreatedAt,
        lastLoginAt: testLastLoginAt,
      );

      final user3 = User(
        id: 'different-id',
        email: 'test@example.com',
        displayName: 'Test User',
        provider: AuthProvider.google,
        createdAt: testCreatedAt,
        lastLoginAt: testLastLoginAt,
      );

      // Act & Assert
      expect(user1, equals(user2));
      expect(user1.hashCode, equals(user2.hashCode));
      expect(user1, isNot(equals(user3)));
    });
  });

  group('AuthProvider Enum Tests', () {
    test('should have correct string values', () {
      expect(AuthProvider.google.value, equals('google'));
      expect(AuthProvider.email.value, equals('email'));
      expect(AuthProvider.apple.value, equals('apple'));
      expect(AuthProvider.anonymous.value, equals('anonymous'));
    });

    test('should create from string correctly', () {
      expect(AuthProvider.fromString('google'), equals(AuthProvider.google));
      expect(AuthProvider.fromString('GOOGLE'), equals(AuthProvider.google));
      expect(AuthProvider.fromString('email'), equals(AuthProvider.email));
      expect(AuthProvider.fromString('EMAIL'), equals(AuthProvider.email));
    });

    test('should throw error for unknown provider string', () {
      expect(() => AuthProvider.fromString('unknown'), throwsArgumentError);
    });

    test('should have correct display names', () {
      expect(AuthProvider.google.displayName, equals('Google'));
      expect(AuthProvider.email.displayName, equals('Email'));
      expect(AuthProvider.apple.displayName, equals('Apple'));
      expect(AuthProvider.anonymous.displayName, equals('Anonymous'));
    });

    test('should correctly identify profile photo support', () {
      expect(AuthProvider.google.supportsProfilePhoto, isTrue);
      expect(AuthProvider.apple.supportsProfilePhoto, isTrue);
      expect(AuthProvider.email.supportsProfilePhoto, isFalse);
      expect(AuthProvider.anonymous.supportsProfilePhoto, isFalse);
    });

    test('should correctly identify email verification requirement', () {
      expect(AuthProvider.email.requiresEmailVerification, isTrue);
      expect(AuthProvider.google.requiresEmailVerification, isFalse);
      expect(AuthProvider.apple.requiresEmailVerification, isFalse);
      expect(AuthProvider.anonymous.requiresEmailVerification, isFalse);
    });

    test('should correctly identify display name support', () {
      expect(AuthProvider.google.supportsDisplayName, isTrue);
      expect(AuthProvider.apple.supportsDisplayName, isTrue);
      expect(AuthProvider.email.supportsDisplayName, isFalse);
      expect(AuthProvider.anonymous.supportsDisplayName, isFalse);
    });

    test('toString should return value', () {
      expect(AuthProvider.google.toString(), equals('google'));
      expect(AuthProvider.email.toString(), equals('email'));
    });
  });

  group('Email Value Object Tests', () {
    test('should create valid email', () {
      final email = Email('test@example.com');
      expect(email.value, equals('test@example.com'));
    });

    test('should normalize email to lowercase', () {
      final email = Email('TEST@EXAMPLE.COM');
      expect(email.value, equals('test@example.com'));
    });

    test('should trim whitespace', () {
      final email = Email('  test@example.com  ');
      expect(email.value, equals('test@example.com'));
    });

    test('should throw error for invalid email', () {
      expect(() => Email('invalid-email'), throwsArgumentError);
      expect(() => Email(''), throwsArgumentError);
      expect(() => Email('test@'), throwsArgumentError);
      expect(() => Email('@example.com'), throwsArgumentError);
    });

    test('should validate email format correctly', () {
      expect(Email.isValid('test@example.com'), isTrue);
      expect(Email.isValid('user.name+tag@domain.co.uk'), isTrue);
      expect(Email.isValid('invalid-email'), isFalse);
      expect(Email.isValid(''), isFalse);
    });

    test('should extract domain correctly', () {
      final email = Email('test@example.com');
      expect(email.domain, equals('example.com'));
    });

    test('should extract local part correctly', () {
      final email = Email('test.user@example.com');
      expect(email.localPart, equals('test.user'));
    });

    test('should implement equality correctly', () {
      final email1 = Email('test@example.com');
      final email2 = Email('test@example.com');
      final email3 = Email('different@example.com');

      expect(email1, equals(email2));
      expect(email1.hashCode, equals(email2.hashCode));
      expect(email1, isNot(equals(email3)));
    });
  });

  group('Password Value Object Tests', () {
    test('should create valid password', () {
      final password = Password('ValidPass123');
      expect(password.length, equals(12));
    });

    test('should throw error for invalid password', () {
      expect(() => Password('short'), throwsArgumentError); // Too short
      expect(() => Password('nouppercase123'), throwsArgumentError); // No uppercase
      expect(() => Password('NOLOWERCASE123'), throwsArgumentError); // No lowercase
      expect(() => Password('NoNumbers'), throwsArgumentError); // No numbers
    });

    test('should validate password correctly', () {
      expect(Password.isValid('ValidPass123'), isTrue);
      expect(Password.isValid('short'), isFalse);
      expect(Password.isValid('nouppercase123'), isFalse);
    });

    test('should calculate strength score correctly', () {
      expect(Password.getStrengthScore('ValidPass123'), equals(4));
      expect(Password.getStrengthScore('ValidPass123!'), equals(5));
      expect(Password.getStrengthScore('weak'), equals(1));
    });

    test('should provide strength description', () {
      expect(Password.getStrengthDescription('ValidPass123'), equals('Good'));
      expect(Password.getStrengthDescription('ValidPass123!'), equals('Strong'));
      expect(Password.getStrengthDescription('weak'), equals('Very Weak'));
    });

    test('toString should hide password', () {
      final password = Password('ValidPass123');
      expect(password.toString(), equals('************'));
    });
  });

  group('DisplayName Value Object Tests', () {
    test('should create valid display name', () {
      final displayName = DisplayName('John Doe');
      expect(displayName.value, equals('John Doe'));
    });

    test('should trim whitespace', () {
      final displayName = DisplayName('  John Doe  ');
      expect(displayName.value, equals('John Doe'));
    });

    test('should throw error for invalid display name', () {
      expect(() => DisplayName(''), throwsArgumentError);
      expect(() => DisplayName('   '), throwsArgumentError);
      expect(() => DisplayName('!!!'), throwsArgumentError); // Only special chars
    });

    test('should validate display name correctly', () {
      expect(DisplayName.isValid('John Doe'), isTrue);
      expect(DisplayName.isValid('John123'), isTrue);
      expect(DisplayName.isValid(''), isFalse);
      expect(DisplayName.isValid('   '), isFalse);
    });

    test('should extract first name correctly', () {
      final displayName = DisplayName('John Doe Smith');
      expect(displayName.firstName, equals('John'));
    });

    test('should extract last name correctly', () {
      final displayName = DisplayName('John Doe Smith');
      expect(displayName.lastName, equals('Smith'));
    });

    test('should generate initials correctly', () {
      expect(DisplayName('John Doe').initials, equals('JD'));
      expect(DisplayName('John').initials, equals('J'));
      expect(DisplayName('John Doe Smith').initials, equals('JD'));
    });

    test('should implement equality correctly', () {
      final name1 = DisplayName('John Doe');
      final name2 = DisplayName('John Doe');
      final name3 = DisplayName('Jane Doe');

      expect(name1, equals(name2));
      expect(name1.hashCode, equals(name2.hashCode));
      expect(name1, isNot(equals(name3)));
    });
  });
}