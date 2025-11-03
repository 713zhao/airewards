import 'package:flutter_test/flutter_test.dart';
import 'package:ai_rewards_system/features/rewards/domain/entities/reward_type.dart';

void main() {
  group('RewardType', () {
    group('enum values', () {
      test('should have correct string values', () {
        expect(RewardType.earned.value, equals('EARNED'));
        expect(RewardType.adjusted.value, equals('ADJUSTED'));
        expect(RewardType.bonus.value, equals('BONUS'));
      });

      test('should have correct toString representation', () {
        expect(RewardType.earned.toString(), equals('EARNED'));
        expect(RewardType.adjusted.toString(), equals('ADJUSTED'));
        expect(RewardType.bonus.toString(), equals('BONUS'));
      });
    });

    group('fromString', () {
      test('should create correct enum from string value', () {
        expect(RewardType.fromString('EARNED'), equals(RewardType.earned));
        expect(RewardType.fromString('ADJUSTED'), equals(RewardType.adjusted));
        expect(RewardType.fromString('BONUS'), equals(RewardType.bonus));
      });

      test('should handle lowercase input', () {
        expect(RewardType.fromString('earned'), equals(RewardType.earned));
        expect(RewardType.fromString('adjusted'), equals(RewardType.adjusted));
        expect(RewardType.fromString('bonus'), equals(RewardType.bonus));
      });

      test('should handle mixed case input', () {
        expect(RewardType.fromString('Earned'), equals(RewardType.earned));
        expect(RewardType.fromString('aDjUsTeD'), equals(RewardType.adjusted));
        expect(RewardType.fromString('BoNuS'), equals(RewardType.bonus));
      });

      test('should throw ArgumentError for invalid values', () {
        expect(
          () => RewardType.fromString('INVALID'),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => RewardType.fromString(''),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => RewardType.fromString('reward'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should include invalid value in error message', () {
        try {
          RewardType.fromString('INVALID');
          fail('Expected ArgumentError to be thrown');
        } catch (e) {
          expect(e.toString(), contains('Invalid RewardType value: INVALID'));
        }
      });
    });

    group('equality', () {
      test('should be equal when same type', () {
        expect(RewardType.earned, equals(RewardType.earned));
        expect(RewardType.adjusted, equals(RewardType.adjusted));
        expect(RewardType.bonus, equals(RewardType.bonus));
      });

      test('should not be equal when different types', () {
        expect(RewardType.earned, isNot(equals(RewardType.adjusted)));
        expect(RewardType.earned, isNot(equals(RewardType.bonus)));
        expect(RewardType.adjusted, isNot(equals(RewardType.bonus)));
      });
    });

    group('use in switch statements', () {
      test('should work correctly in switch statements', () {
        String getTypeDescription(RewardType type) {
          switch (type) {
            case RewardType.earned:
              return 'Points earned through activities';
            case RewardType.adjusted:
              return 'Points manually adjusted';
            case RewardType.bonus:
              return 'Bonus points from promotions';
          }
        }

        expect(getTypeDescription(RewardType.earned), 
               equals('Points earned through activities'));
        expect(getTypeDescription(RewardType.adjusted), 
               equals('Points manually adjusted'));
        expect(getTypeDescription(RewardType.bonus), 
               equals('Bonus points from promotions'));
      });
    });
  });
}