import 'package:flutter_test/flutter_test.dart';
import 'package:ai_rewards_system/features/redemption/domain/entities/redemption_option.dart';

void main() {
  group('RedemptionOption', () {
    const validTitle = 'Coffee Reward';
    const validDescription = 'Get a free coffee from our partner cafes';
    const validRequiredPoints = 500;
    const validCategoryId = 'food_beverage';

    group('create factory', () {
      test('should create valid redemption option with required fields', () {
        final option = RedemptionOption.create(
          title: validTitle,
          description: validDescription,
          requiredPoints: validRequiredPoints,
          categoryId: validCategoryId,
        );

        expect(option.title, validTitle);
        expect(option.description, validDescription);
        expect(option.requiredPoints, validRequiredPoints);
        expect(option.categoryId, validCategoryId);
        expect(option.isActive, isTrue);
        expect(option.id, isNotEmpty);
        expect(option.createdAt, isNotNull);
      });

      test('should create with optional fields', () {
        final expiryDate = DateTime.now().add(const Duration(days: 30));
        const imageUrl = 'https://example.com/coffee.jpg';

        final option = RedemptionOption.create(
          title: validTitle,
          description: validDescription,
          requiredPoints: validRequiredPoints,
          categoryId: validCategoryId,
          isActive: false,
          expiryDate: expiryDate,
          imageUrl: imageUrl,
        );

        expect(option.isActive, isFalse);
        expect(option.expiryDate, expiryDate);
        expect(option.imageUrl, imageUrl);
      });

      test('should trim title and description', () {
        final option = RedemptionOption.create(
          title: '  $validTitle  ',
          description: '  $validDescription  ',
          requiredPoints: validRequiredPoints,
          categoryId: validCategoryId,
        );

        expect(option.title, validTitle);
        expect(option.description, validDescription);
      });
    });

    group('validation', () {
      group('required points', () {
        test('should throw for points less than 100 (BR-008)', () {
          expect(
            () => RedemptionOption.create(
              title: validTitle,
              description: validDescription,
              requiredPoints: 99,
              categoryId: validCategoryId,
            ),
            throwsA(isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('BR-008'),
            )),
          );
        });

        test('should accept minimum valid points (100)', () {
          final option = RedemptionOption.create(
            title: validTitle,
            description: validDescription,
            requiredPoints: 100,
            categoryId: validCategoryId,
          );

          expect(option.requiredPoints, 100);
        });

        test('should throw for excessive points', () {
          expect(
            () => RedemptionOption.create(
              title: validTitle,
              description: validDescription,
              requiredPoints: 1000001,
              categoryId: validCategoryId,
            ),
            throwsA(isA<ArgumentError>()),
          );
        });
      });

      group('title validation', () {
        test('should throw for empty title', () {
          expect(
            () => RedemptionOption.create(
              title: '',
              description: validDescription,
              requiredPoints: validRequiredPoints,
              categoryId: validCategoryId,
            ),
            throwsA(isA<ArgumentError>()),
          );
        });

        test('should throw for whitespace-only title', () {
          expect(
            () => RedemptionOption.create(
              title: '   ',
              description: validDescription,
              requiredPoints: validRequiredPoints,
              categoryId: validCategoryId,
            ),
            throwsA(isA<ArgumentError>()),
          );
        });

        test('should throw for title over 100 characters', () {
          final longTitle = 'a' * 101;
          expect(
            () => RedemptionOption.create(
              title: longTitle,
              description: validDescription,
              requiredPoints: validRequiredPoints,
              categoryId: validCategoryId,
            ),
            throwsA(isA<ArgumentError>()),
          );
        });
      });

      group('description validation', () {
        test('should throw for empty description', () {
          expect(
            () => RedemptionOption.create(
              title: validTitle,
              description: '',
              requiredPoints: validRequiredPoints,
              categoryId: validCategoryId,
            ),
            throwsA(isA<ArgumentError>()),
          );
        });

        test('should throw for description over 500 characters', () {
          final longDescription = 'a' * 501;
          expect(
            () => RedemptionOption.create(
              title: validTitle,
              description: longDescription,
              requiredPoints: validRequiredPoints,
              categoryId: validCategoryId,
            ),
            throwsA(isA<ArgumentError>()),
          );
        });
      });

      group('expiry date validation', () {
        test('should throw for past expiry date', () {
          final pastDate = DateTime.now().subtract(const Duration(days: 1));
          expect(
            () => RedemptionOption.create(
              title: validTitle,
              description: validDescription,
              requiredPoints: validRequiredPoints,
              categoryId: validCategoryId,
              expiryDate: pastDate,
            ),
            throwsA(isA<ArgumentError>()),
          );
        });

        test('should accept future expiry date', () {
          final futureDate = DateTime.now().add(const Duration(days: 1));
          final option = RedemptionOption.create(
            title: validTitle,
            description: validDescription,
            requiredPoints: validRequiredPoints,
            categoryId: validCategoryId,
            expiryDate: futureDate,
          );

          expect(option.expiryDate, futureDate);
        });
      });
    });

    group('copyWith', () {
      late RedemptionOption baseOption;

      setUp(() {
        baseOption = RedemptionOption.create(
          title: validTitle,
          description: validDescription,
          requiredPoints: validRequiredPoints,
          categoryId: validCategoryId,
        );
      });

      test('should create copy with updated fields', () {
        const newTitle = 'Updated Title';
        final updatedOption = baseOption.copyWith(title: newTitle);

        expect(updatedOption.title, newTitle);
        expect(updatedOption.description, baseOption.description);
        expect(updatedOption.requiredPoints, baseOption.requiredPoints);
        expect(updatedOption.updatedAt, isNotNull);
      });

      test('should validate updated fields', () {
        expect(
          () => baseOption.copyWith(requiredPoints: 99),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should preserve original when no changes', () {
        final copied = baseOption.copyWith();

        expect(copied.title, baseOption.title);
        expect(copied.description, baseOption.description);
        expect(copied.requiredPoints, baseOption.requiredPoints);
        expect(copied.categoryId, baseOption.categoryId);
      });
    });

    group('availability checks', () {
      late RedemptionOption activeOption;

      setUp(() {
        activeOption = RedemptionOption.create(
          title: validTitle,
          description: validDescription,
          requiredPoints: validRequiredPoints,
          categoryId: validCategoryId,
        );
      });

      group('isAvailable', () {
        test('should return true for active option without expiry', () {
          expect(activeOption.isAvailable, isTrue);
        });

        test('should return false for inactive option', () {
          final inactiveOption = activeOption.copyWith(isActive: false);
          expect(inactiveOption.isAvailable, isFalse);
        });

        test('should return true for active option with future expiry', () {
          final futureExpiry = DateTime.now().add(const Duration(days: 30));
          final futureOption = activeOption.copyWith(expiryDate: futureExpiry);
          expect(futureOption.isAvailable, isTrue);
        });

        test('should return false for expired option', () {
          final pastExpiry = DateTime.now().subtract(const Duration(days: 1));
          final expiredOption = RedemptionOption(
            id: 'test',
            title: validTitle,
            description: validDescription,
            requiredPoints: validRequiredPoints,
            categoryId: validCategoryId,
            isActive: true,
            expiryDate: pastExpiry,
            createdAt: DateTime.now(),
          );
          expect(expiredOption.isAvailable, isFalse);
        });
      });

      group('isExpired', () {
        test('should return false for option without expiry date', () {
          expect(activeOption.isExpired, isFalse);
        });

        test('should return true for expired option', () {
          final pastExpiry = DateTime.now().subtract(const Duration(days: 1));
          final expiredOption = RedemptionOption(
            id: 'test',
            title: validTitle,
            description: validDescription,
            requiredPoints: validRequiredPoints,
            categoryId: validCategoryId,
            isActive: true,
            expiryDate: pastExpiry,
            createdAt: DateTime.now(),
          );
          expect(expiredOption.isExpired, isTrue);
        });
      });

      group('canRedeemWith', () {
        test('should return true for sufficient points and available option', () {
          expect(activeOption.canRedeemWith(1000), isTrue);
        });

        test('should return false for insufficient points', () {
          expect(activeOption.canRedeemWith(100), isFalse);
        });

        test('should return false for unavailable option', () {
          final unavailableOption = activeOption.copyWith(isActive: false);
          expect(unavailableOption.canRedeemWith(1000), isFalse);
        });
      });
    });

    group('equality', () {
      test('should be equal for same properties', () {
        final option1 = RedemptionOption.create(
          title: validTitle,
          description: validDescription,
          requiredPoints: validRequiredPoints,
          categoryId: validCategoryId,
        );
        final option2 = RedemptionOption(
          id: option1.id,
          title: option1.title,
          description: option1.description,
          requiredPoints: option1.requiredPoints,
          categoryId: option1.categoryId,
          isActive: option1.isActive,
          expiryDate: option1.expiryDate,
          imageUrl: option1.imageUrl,
          createdAt: option1.createdAt,
          updatedAt: option1.updatedAt,
        );

        expect(option1, equals(option2));
      });

      test('should not be equal for different properties', () {
        final option1 = RedemptionOption.create(
          title: validTitle,
          description: validDescription,
          requiredPoints: validRequiredPoints,
          categoryId: validCategoryId,
        );
        final option2 = option1.copyWith(title: 'Different Title');

        expect(option1, isNot(equals(option2)));
      });
    });

    group('toString', () {
      test('should return meaningful string representation', () {
        final option = RedemptionOption.create(
          title: validTitle,
          description: validDescription,
          requiredPoints: validRequiredPoints,
          categoryId: validCategoryId,
        );

        final toString = option.toString();
        expect(toString, contains('RedemptionOption'));
        expect(toString, contains(option.id));
        expect(toString, contains(validTitle));
        expect(toString, contains(validRequiredPoints.toString()));
      });
    });
  });
}