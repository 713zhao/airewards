import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_rewards_system/core/errors/failures.dart';
import 'package:ai_rewards_system/features/rewards/domain/entities/reward_category.dart';

void main() {
  group('RewardCategory', () {
    const validId = 'test-id';
    const validName = 'Test Category';
    const validDescription = 'Test description';
    const validColor = Colors.blue;
    const validIconData = Icons.star;

    group('create', () {
      test('should return Right with valid RewardCategory when all data is valid', () {
        final result = RewardCategory.create(
          id: validId,
          name: validName,
          description: validDescription,
          color: validColor,
          iconData: validIconData,
        );

        expect(result.isRight, isTrue);
        
        final category = result.right;
        expect(category.id, equals(validId));
        expect(category.name, equals(validName));
        expect(category.description, equals(validDescription));
        expect(category.color, equals(validColor));
        expect(category.iconData, equals(validIconData));
        expect(category.isDefault, isFalse);
      });

      test('should create default category when isDefault is true', () {
        final result = RewardCategory.create(
          id: validId,
          name: validName,
          color: validColor,
          iconData: validIconData,
          isDefault: true,
        );

        expect(result.isRight, isTrue);
        expect(result.right.isDefault, isTrue);
      });

      test('should trim whitespace from name and description', () {
        final result = RewardCategory.create(
          id: validId,
          name: '  $validName  ',
          description: '  $validDescription  ',
          color: validColor,
          iconData: validIconData,
        );

        expect(result.isRight, isTrue);
        
        final category = result.right;
        expect(category.name, equals(validName));
        expect(category.description, equals(validDescription));
      });

      test('should work without description', () {
        final result = RewardCategory.create(
          id: validId,
          name: validName,
          color: validColor,
          iconData: validIconData,
        );

        expect(result.isRight, isTrue);
        expect(result.right.description, isNull);
      });

      group('validation failures', () {
        test('should return Left when ID is empty', () {
          final result = RewardCategory.create(
            id: '',
            name: validName,
            color: validColor,
            iconData: validIconData,
          );

          expect(result.isLeft, isTrue);
          expect(result.left, isA<ValidationFailure>());
          expect(result.left.message, contains('Category ID cannot be empty'));
        });

        test('should return Left when name is empty', () {
          final result = RewardCategory.create(
            id: validId,
            name: '',
            color: validColor,
            iconData: validIconData,
          );

          expect(result.isLeft, isTrue);
          expect(result.left, isA<ValidationFailure>());
          expect(result.left.message, contains('Category name cannot be empty'));
        });

        test('should return Left when name is only whitespace', () {
          final result = RewardCategory.create(
            id: validId,
            name: '   ',
            color: validColor,
            iconData: validIconData,
          );

          expect(result.isLeft, isTrue);
          expect(result.left, isA<ValidationFailure>());
          expect(result.left.message, contains('Category name cannot be only whitespace'));
        });

        test('should return Left when name exceeds 50 characters', () {
          final longName = 'A' * 51;
          final result = RewardCategory.create(
            id: validId,
            name: longName,
            color: validColor,
            iconData: validIconData,
          );

          expect(result.isLeft, isTrue);
          expect(result.left, isA<ValidationFailure>());
          expect(result.left.message, contains('Category name cannot exceed 50 characters'));
        });

        test('should return Left when name contains invalid characters', () {
          const invalidNames = [
            'Test@Category',
            'Test#Category',
            'Test%Category',
            'Test&Category',
            'Test*Category',
          ];

          for (final invalidName in invalidNames) {
            final result = RewardCategory.create(
              id: validId,
              name: invalidName,
              color: validColor,
              iconData: validIconData,
            );

            expect(result.isLeft, isTrue, reason: 'Name "$invalidName" should be invalid');
            expect(result.left, isA<ValidationFailure>());
            expect(result.left.message, contains('Category name contains invalid characters'));
          }
        });

        test('should accept valid special characters in name', () {
          const validNames = [
            'Test-Category',
            'Test_Category',
            'Test.Category',
            'Test Category',
            'Test123',
            'Category-1_Test.2',
          ];

          for (final validName in validNames) {
            final result = RewardCategory.create(
              id: validId,
              name: validName,
              color: validColor,
              iconData: validIconData,
            );

            expect(result.isRight, isTrue, reason: 'Name "$validName" should be valid');
          }
        });

        test('should return Left when description exceeds 200 characters', () {
          final longDescription = 'A' * 201;
          final result = RewardCategory.create(
            id: validId,
            name: validName,
            description: longDescription,
            color: validColor,
            iconData: validIconData,
          );

          expect(result.isLeft, isTrue);
          expect(result.left, isA<ValidationFailure>());
          expect(result.left.message, contains('Category description cannot exceed 200 characters'));
        });

        test('should accept description with exactly 200 characters', () {
          final maxDescription = 'A' * 200;
          final result = RewardCategory.create(
            id: validId,
            name: validName,
            description: maxDescription,
            color: validColor,
            iconData: validIconData,
          );

          expect(result.isRight, isTrue);
          expect(result.right.description, equals(maxDescription));
        });
      });
    });

    group('copyWith', () {
      late RewardCategory originalCategory;

      setUp(() {
        originalCategory = RewardCategory.create(
          id: validId,
          name: validName,
          description: validDescription,
          color: validColor,
          iconData: validIconData,
        ).right;
      });

      test('should return same category when no parameters provided', () {
        final copied = originalCategory.copyWith();

        expect(copied, equals(originalCategory));
        expect(identical(copied, originalCategory), isFalse);
      });

      test('should update individual properties', () {
        const newName = 'Updated Name';
        final copied = originalCategory.copyWith(name: newName);

        expect(copied.name, equals(newName));
        expect(copied.id, equals(originalCategory.id));
        expect(copied.description, equals(originalCategory.description));
        expect(copied.color, equals(originalCategory.color));
        expect(copied.iconData, equals(originalCategory.iconData));
        expect(copied.isDefault, equals(originalCategory.isDefault));
      });

      test('should update multiple properties', () {
        const newName = 'Updated Name';
        const newDescription = 'Updated description';
        const newColor = Colors.red;

        final copied = originalCategory.copyWith(
          name: newName,
          description: newDescription,
          color: newColor,
        );

        expect(copied.name, equals(newName));
        expect(copied.description, equals(newDescription));
        expect(copied.color, equals(newColor));
        expect(copied.id, equals(originalCategory.id));
        expect(copied.iconData, equals(originalCategory.iconData));
        expect(copied.isDefault, equals(originalCategory.isDefault));
      });
    });

    group('serialization', () {
      late RewardCategory category;

      setUp(() {
        category = RewardCategory.create(
          id: validId,
          name: validName,
          description: validDescription,
          color: validColor,
          iconData: validIconData,
          isDefault: true,
        ).right;
      });

      test('should serialize to JSON correctly', () {
        final json = category.toJson();

        expect(json['id'], equals(validId));
        expect(json['name'], equals(validName));
        expect(json['description'], equals(validDescription));
        expect(json['color'], equals(validColor.value));
        expect(json['iconData'], equals(validIconData.codePoint));
        expect(json['isDefault'], isTrue);
      });

      test('should deserialize from JSON correctly', () {
        final json = category.toJson();
        final deserialized = RewardCategory.fromJson(json);

        expect(deserialized, equals(category));
      });

      test('should handle null description in serialization', () {
        final categoryWithoutDescription = RewardCategory.create(
          id: validId,
          name: validName,
          color: validColor,
          iconData: validIconData,
        ).right;

        final json = categoryWithoutDescription.toJson();
        final deserialized = RewardCategory.fromJson(json);

        expect(deserialized.description, isNull);
        expect(deserialized, equals(categoryWithoutDescription));
      });

      test('should handle missing isDefault in JSON', () {
        final json = {
          'id': validId,
          'name': validName,
          'description': validDescription,
          'color': validColor.value,
          'iconData': validIconData.codePoint,
          // isDefault is missing
        };

        final deserialized = RewardCategory.fromJson(json);
        expect(deserialized.isDefault, isFalse);
      });
    });

    group('equality and hashCode', () {
      test('should be equal when all properties are the same', () {
        final category1 = RewardCategory.create(
          id: validId,
          name: validName,
          description: validDescription,
          color: validColor,
          iconData: validIconData,
        ).right;

        final category2 = RewardCategory.create(
          id: validId,
          name: validName,
          description: validDescription,
          color: validColor,
          iconData: validIconData,
        ).right;

        expect(category1, equals(category2));
        expect(category1.hashCode, equals(category2.hashCode));
      });

      test('should not be equal when properties differ', () {
        final category1 = RewardCategory.create(
          id: validId,
          name: validName,
          color: validColor,
          iconData: validIconData,
        ).right;

        final category2 = RewardCategory.create(
          id: 'different-id',
          name: validName,
          color: validColor,
          iconData: validIconData,
        ).right;

        expect(category1, isNot(equals(category2)));
      });
    });

    group('toString', () {
      test('should return readable string representation', () {
        final category = RewardCategory.create(
          id: validId,
          name: validName,
          description: validDescription,
          color: validColor,
          iconData: validIconData,
          isDefault: true,
        ).right;

        final stringRep = category.toString();

        expect(stringRep, contains('RewardCategory'));
        expect(stringRep, contains(validId));
        expect(stringRep, contains(validName));
        expect(stringRep, contains(validDescription));
        expect(stringRep, contains('true'));
      });
    });
  });
}