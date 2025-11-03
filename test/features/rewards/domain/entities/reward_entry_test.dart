import 'package:flutter_test/flutter_test.dart';
import 'package:ai_rewards_system/core/errors/failures.dart';
import 'package:ai_rewards_system/features/rewards/domain/entities/reward_entry.dart';
import 'package:ai_rewards_system/features/rewards/domain/entities/reward_type.dart';

void main() {
  group('RewardEntry', () {
    const validId = 'test-id';
    const validUserId = 'user-123';
    const validPoints = 100;
    const validDescription = 'Test reward description';
    const validCategoryId = 'category-123';
    final validCreatedAt = DateTime.now();
    const validType = RewardType.earned;

    group('create', () {
      test('should return Right with valid RewardEntry when all data is valid', () {
        final result = RewardEntry.create(
          id: validId,
          userId: validUserId,
          points: validPoints,
          description: validDescription,
          categoryId: validCategoryId,
          createdAt: validCreatedAt,
          type: validType,
        );

        expect(result.isRight, isTrue);
        
        final entry = result.right;
        expect(entry.id, equals(validId));
        expect(entry.userId, equals(validUserId));
        expect(entry.points, equals(validPoints));
        expect(entry.description, equals(validDescription));
        expect(entry.categoryId, equals(validCategoryId));
        expect(entry.createdAt, equals(validCreatedAt));
        expect(entry.updatedAt, isNull);
        expect(entry.isSynced, isFalse);
        expect(entry.type, equals(validType));
      });

      test('should create entry with custom sync status and updatedAt', () {
        final updatedAt = validCreatedAt.add(const Duration(hours: 1));
        
        final result = RewardEntry.create(
          id: validId,
          userId: validUserId,
          points: validPoints,
          description: validDescription,
          categoryId: validCategoryId,
          createdAt: validCreatedAt,
          updatedAt: updatedAt,
          isSynced: true,
          type: validType,
        );

        expect(result.isRight, isTrue);
        
        final entry = result.right;
        expect(entry.updatedAt, equals(updatedAt));
        expect(entry.isSynced, isTrue);
      });

      test('should trim whitespace from description', () {
        const descriptionWithWhitespace = '  ${validDescription}  ';
        
        final result = RewardEntry.create(
          id: validId,
          userId: validUserId,
          points: validPoints,
          description: descriptionWithWhitespace,
          categoryId: validCategoryId,
          createdAt: validCreatedAt,
          type: validType,
        );

        expect(result.isRight, isTrue);
        expect(result.right.description, equals(validDescription));
      });

      group('validation failures', () {
        test('should return Left when ID is empty', () {
          final result = RewardEntry.create(
            id: '',
            userId: validUserId,
            points: validPoints,
            description: validDescription,
            categoryId: validCategoryId,
            createdAt: validCreatedAt,
            type: validType,
          );

          expect(result.isLeft, isTrue);
          expect(result.left, isA<ValidationFailure>());
          expect(result.left.message, contains('Reward entry ID cannot be empty'));
        });

        test('should return Left when userId is empty', () {
          final result = RewardEntry.create(
            id: validId,
            userId: '',
            points: validPoints,
            description: validDescription,
            categoryId: validCategoryId,
            createdAt: validCreatedAt,
            type: validType,
          );

          expect(result.isLeft, isTrue);
          expect(result.left, isA<ValidationFailure>());
          expect(result.left.message, contains('User ID cannot be empty'));
        });

        test('should return Left when categoryId is empty (BR-011)', () {
          final result = RewardEntry.create(
            id: validId,
            userId: validUserId,
            points: validPoints,
            description: validDescription,
            categoryId: '',
            createdAt: validCreatedAt,
            type: validType,
          );

          expect(result.isLeft, isTrue);
          expect(result.left, isA<ValidationFailure>());
          expect(result.left.message, contains('Category ID cannot be empty'));
          expect(result.left.message, contains('BR-011'));
        });

        test('should return Left when description is empty (mandatory field)', () {
          final result = RewardEntry.create(
            id: validId,
            userId: validUserId,
            points: validPoints,
            description: '',
            categoryId: validCategoryId,
            createdAt: validCreatedAt,
            type: validType,
          );

          expect(result.isLeft, isTrue);
          expect(result.left, isA<ValidationFailure>());
          expect(result.left.message, contains('Description cannot be empty'));
        });

        test('should return Left when description is only whitespace', () {
          final result = RewardEntry.create(
            id: validId,
            userId: validUserId,
            points: validPoints,
            description: '   ',
            categoryId: validCategoryId,
            createdAt: validCreatedAt,
            type: validType,
          );

          expect(result.isLeft, isTrue);
          expect(result.left, isA<ValidationFailure>());
          expect(result.left.message, contains('Description cannot be only whitespace'));
        });

        test('should return Left when description exceeds 500 characters', () {
          final longDescription = 'A' * 501;
          
          final result = RewardEntry.create(
            id: validId,
            userId: validUserId,
            points: validPoints,
            description: longDescription,
            categoryId: validCategoryId,
            createdAt: validCreatedAt,
            type: validType,
          );

          expect(result.isLeft, isTrue);
          expect(result.left, isA<ValidationFailure>());
          expect(result.left.message, contains('Description cannot exceed 500 characters'));
        });

        test('should return Left when updatedAt is before createdAt', () {
          final invalidUpdatedAt = validCreatedAt.subtract(const Duration(hours: 1));
          
          final result = RewardEntry.create(
            id: validId,
            userId: validUserId,
            points: validPoints,
            description: validDescription,
            categoryId: validCategoryId,
            createdAt: validCreatedAt,
            updatedAt: invalidUpdatedAt,
            type: validType,
          );

          expect(result.isLeft, isTrue);
          expect(result.left, isA<ValidationFailure>());
          expect(result.left.message, contains('Updated date cannot be before created date'));
        });
      });

      group('point validation (BR-001, BR-002, BR-003)', () {
        test('should accept positive points for earned type (BR-001)', () {
          final result = RewardEntry.create(
            id: validId,
            userId: validUserId,
            points: 1,
            description: validDescription,
            categoryId: validCategoryId,
            createdAt: validCreatedAt,
            type: RewardType.earned,
          );

          expect(result.isRight, isTrue);
          expect(result.right.points, equals(1));
        });

        test('should accept maximum points value (BR-002)', () {
          final result = RewardEntry.create(
            id: validId,
            userId: validUserId,
            points: 10000,
            description: validDescription,
            categoryId: validCategoryId,
            createdAt: validCreatedAt,
            type: RewardType.earned,
          );

          expect(result.isRight, isTrue);
          expect(result.right.points, equals(10000));
        });

        test('should return Left when points exceed maximum (BR-002)', () {
          final result = RewardEntry.create(
            id: validId,
            userId: validUserId,
            points: 10001,
            description: validDescription,
            categoryId: validCategoryId,
            createdAt: validCreatedAt,
            type: RewardType.earned,
          );

          expect(result.isLeft, isTrue);
          expect(result.left, isA<ValidationFailure>());
          expect(result.left.message, contains('Maximum point entry value is 10,000 points'));
          expect(result.left.message, contains('BR-002'));
        });

        test('should return Left when negative points for non-adjusted type (BR-003)', () {
          final typesToTest = [RewardType.earned, RewardType.bonus];
          
          for (final type in typesToTest) {
            final result = RewardEntry.create(
              id: validId,
              userId: validUserId,
              points: -100,
              description: validDescription,
              categoryId: validCategoryId,
              createdAt: validCreatedAt,
              type: type,
            );

            expect(result.isLeft, isTrue, reason: 'Negative points should fail for $type');
            expect(result.left, isA<ValidationFailure>());
            expect(result.left.message, contains('Points cannot be negative'));
            expect(result.left.message, contains('BR-003'));
          }
        });

        test('should accept negative points for adjusted type', () {
          final result = RewardEntry.create(
            id: validId,
            userId: validUserId,
            points: -100,
            description: validDescription,
            categoryId: validCategoryId,
            createdAt: validCreatedAt,
            type: RewardType.adjusted,
          );

          expect(result.isRight, isTrue);
          expect(result.right.points, equals(-100));
        });

        test('should accept large negative adjustments within limit', () {
          final result = RewardEntry.create(
            id: validId,
            userId: validUserId,
            points: -10000,
            description: validDescription,
            categoryId: validCategoryId,
            createdAt: validCreatedAt,
            type: RewardType.adjusted,
          );

          expect(result.isRight, isTrue);
          expect(result.right.points, equals(-10000));
        });

        test('should return Left when negative adjustment exceeds limit (BR-002)', () {
          final result = RewardEntry.create(
            id: validId,
            userId: validUserId,
            points: -10001,
            description: validDescription,
            categoryId: validCategoryId,
            createdAt: validCreatedAt,
            type: RewardType.adjusted,
          );

          expect(result.isLeft, isTrue);
          expect(result.left, isA<ValidationFailure>());
          expect(result.left.message, contains('Maximum point entry value is 10,000 points'));
          expect(result.left.message, contains('BR-002'));
        });
      });
    });

    group('canBeModified (BR-004)', () {
      test('should return true when created less than 24 hours ago', () {
        final recentTime = DateTime.now().subtract(const Duration(hours: 23));
        
        final entry = RewardEntry.create(
          id: validId,
          userId: validUserId,
          points: validPoints,
          description: validDescription,
          categoryId: validCategoryId,
          createdAt: recentTime,
          type: validType,
        ).right;

        expect(entry.canBeModified(), isTrue);
      });

      test('should return false when created exactly 24 hours ago', () {
        final exactTime = DateTime.now().subtract(const Duration(hours: 24));
        
        final entry = RewardEntry.create(
          id: validId,
          userId: validUserId,
          points: validPoints,
          description: validDescription,
          categoryId: validCategoryId,
          createdAt: exactTime,
          type: validType,
        ).right;

        expect(entry.canBeModified(), isFalse);
      });

      test('should return false when created more than 24 hours ago', () {
        final oldTime = DateTime.now().subtract(const Duration(hours: 25));
        
        final entry = RewardEntry.create(
          id: validId,
          userId: validUserId,
          points: validPoints,
          description: validDescription,
          categoryId: validCategoryId,
          createdAt: oldTime,
          type: validType,
        ).right;

        expect(entry.canBeModified(), isFalse);
      });
    });

    group('isRecent', () {
      test('should return true when created less than 1 hour ago', () {
        final recentTime = DateTime.now().subtract(const Duration(minutes: 30));
        
        final entry = RewardEntry.create(
          id: validId,
          userId: validUserId,
          points: validPoints,
          description: validDescription,
          categoryId: validCategoryId,
          createdAt: recentTime,
          type: validType,
        ).right;

        expect(entry.isRecent(), isTrue);
      });

      test('should return false when created more than 1 hour ago', () {
        final oldTime = DateTime.now().subtract(const Duration(hours: 2));
        
        final entry = RewardEntry.create(
          id: validId,
          userId: validUserId,
          points: validPoints,
          description: validDescription,
          categoryId: validCategoryId,
          createdAt: oldTime,
          type: validType,
        ).right;

        expect(entry.isRecent(), isFalse);
      });
    });

    group('copyWith', () {
      late RewardEntry originalEntry;

      setUp(() {
        originalEntry = RewardEntry.create(
          id: validId,
          userId: validUserId,
          points: validPoints,
          description: validDescription,
          categoryId: validCategoryId,
          createdAt: validCreatedAt,
          type: validType,
        ).right;
      });

      test('should return same entry when no parameters provided', () {
        final copied = originalEntry.copyWith();

        expect(copied, equals(originalEntry));
        expect(identical(copied, originalEntry), isFalse);
      });

      test('should update individual properties and set updatedAt', () {
        const newPoints = 200;
        final copied = originalEntry.copyWith(points: newPoints);

        expect(copied.points, equals(newPoints));
        expect(copied.updatedAt, isNotNull);
        expect(copied.isSynced, isFalse); // Should reset sync status
        expect(copied.id, equals(originalEntry.id));
        expect(copied.userId, equals(originalEntry.userId));
        expect(copied.description, equals(originalEntry.description));
        expect(copied.categoryId, equals(originalEntry.categoryId));
        expect(copied.createdAt, equals(originalEntry.createdAt));
        expect(copied.type, equals(originalEntry.type));
      });

      test('should not update updatedAt when no changes made', () {
        final copied = originalEntry.copyWith(
          id: originalEntry.id,
          userId: originalEntry.userId,
          points: originalEntry.points,
          description: originalEntry.description,
          categoryId: originalEntry.categoryId,
          createdAt: originalEntry.createdAt,
          type: originalEntry.type,
          isSynced: originalEntry.isSynced,
        );

        expect(copied.updatedAt, equals(originalEntry.updatedAt));
        expect(copied.isSynced, equals(originalEntry.isSynced));
      });

      test('should use provided updatedAt when specified', () {
        final specificTime = DateTime.now().add(const Duration(hours: 1));
        final copied = originalEntry.copyWith(
          points: 200,
          updatedAt: specificTime,
        );

        expect(copied.updatedAt, equals(specificTime));
      });

      test('should update multiple properties', () {
        const newPoints = 200;
        const newDescription = 'Updated description';
        const newType = RewardType.bonus;

        final copied = originalEntry.copyWith(
          points: newPoints,
          description: newDescription,
          type: newType,
        );

        expect(copied.points, equals(newPoints));
        expect(copied.description, equals(newDescription));
        expect(copied.type, equals(newType));
        expect(copied.updatedAt, isNotNull);
        expect(copied.isSynced, isFalse);
      });
    });

    group('serialization', () {
      late RewardEntry entry;
      final updatedAt = DateTime.now().add(const Duration(hours: 1));

      setUp(() {
        entry = RewardEntry.create(
          id: validId,
          userId: validUserId,
          points: validPoints,
          description: validDescription,
          categoryId: validCategoryId,
          createdAt: validCreatedAt,
          updatedAt: updatedAt,
          isSynced: true,
          type: validType,
        ).right;
      });

      test('should serialize to JSON correctly', () {
        final json = entry.toJson();

        expect(json['id'], equals(validId));
        expect(json['userId'], equals(validUserId));
        expect(json['points'], equals(validPoints));
        expect(json['description'], equals(validDescription));
        expect(json['categoryId'], equals(validCategoryId));
        expect(json['createdAt'], equals(validCreatedAt.millisecondsSinceEpoch));
        expect(json['updatedAt'], equals(updatedAt.millisecondsSinceEpoch));
        expect(json['isSynced'], isTrue);
        expect(json['type'], equals(validType.value));
      });

      test('should deserialize from JSON correctly', () {
        final json = entry.toJson();
        final deserialized = RewardEntry.fromJson(json);

        expect(deserialized, equals(entry));
      });

      test('should handle null updatedAt in serialization', () {
        final entryWithoutUpdate = RewardEntry.create(
          id: validId,
          userId: validUserId,
          points: validPoints,
          description: validDescription,
          categoryId: validCategoryId,
          createdAt: validCreatedAt,
          type: validType,
        ).right;

        final json = entryWithoutUpdate.toJson();
        final deserialized = RewardEntry.fromJson(json);

        expect(deserialized.updatedAt, isNull);
        expect(deserialized, equals(entryWithoutUpdate));
      });

      test('should handle missing isSynced in JSON', () {
        final json = {
          'id': validId,
          'userId': validUserId,
          'points': validPoints,
          'description': validDescription,
          'categoryId': validCategoryId,
          'createdAt': validCreatedAt.millisecondsSinceEpoch,
          'type': validType.value,
          // isSynced is missing
        };

        final deserialized = RewardEntry.fromJson(json);
        expect(deserialized.isSynced, isFalse);
      });
    });

    group('equality and hashCode', () {
      test('should be equal when all properties are the same', () {
        final entry1 = RewardEntry.create(
          id: validId,
          userId: validUserId,
          points: validPoints,
          description: validDescription,
          categoryId: validCategoryId,
          createdAt: validCreatedAt,
          type: validType,
        ).right;

        final entry2 = RewardEntry.create(
          id: validId,
          userId: validUserId,
          points: validPoints,
          description: validDescription,
          categoryId: validCategoryId,
          createdAt: validCreatedAt,
          type: validType,
        ).right;

        expect(entry1, equals(entry2));
        expect(entry1.hashCode, equals(entry2.hashCode));
      });

      test('should not be equal when properties differ', () {
        final entry1 = RewardEntry.create(
          id: validId,
          userId: validUserId,
          points: validPoints,
          description: validDescription,
          categoryId: validCategoryId,
          createdAt: validCreatedAt,
          type: validType,
        ).right;

        final entry2 = RewardEntry.create(
          id: 'different-id',
          userId: validUserId,
          points: validPoints,
          description: validDescription,
          categoryId: validCategoryId,
          createdAt: validCreatedAt,
          type: validType,
        ).right;

        expect(entry1, isNot(equals(entry2)));
      });
    });

    group('toString', () {
      test('should return readable string representation', () {
        final entry = RewardEntry.create(
          id: validId,
          userId: validUserId,
          points: validPoints,
          description: validDescription,
          categoryId: validCategoryId,
          createdAt: validCreatedAt,
          type: validType,
        ).right;

        final stringRep = entry.toString();

        expect(stringRep, contains('RewardEntry'));
        expect(stringRep, contains(validId));
        expect(stringRep, contains(validUserId));
        expect(stringRep, contains(validPoints.toString()));
        expect(stringRep, contains(validDescription));
        expect(stringRep, contains(validCategoryId));
        expect(stringRep, contains(validType.toString()));
      });
    });
  });
}