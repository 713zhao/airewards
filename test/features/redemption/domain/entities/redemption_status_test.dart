import 'package:flutter_test/flutter_test.dart';
import 'package:ai_rewards_system/features/redemption/domain/entities/redemption_status.dart';

void main() {
  group('RedemptionStatus', () {
    group('fromString', () {
      test('should create correct status from string', () {
        expect(RedemptionStatus.fromString('pending'), RedemptionStatus.pending);
        expect(RedemptionStatus.fromString('completed'), RedemptionStatus.completed);
        expect(RedemptionStatus.fromString('cancelled'), RedemptionStatus.cancelled);
        expect(RedemptionStatus.fromString('expired'), RedemptionStatus.expired);
      });

      test('should be case insensitive', () {
        expect(RedemptionStatus.fromString('PENDING'), RedemptionStatus.pending);
        expect(RedemptionStatus.fromString('Completed'), RedemptionStatus.completed);
        expect(RedemptionStatus.fromString('CANCELLED'), RedemptionStatus.cancelled);
        expect(RedemptionStatus.fromString('ExpIrEd'), RedemptionStatus.expired);
      });

      test('should throw ArgumentError for invalid status', () {
        expect(
          () => RedemptionStatus.fromString('invalid'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('isFinal', () {
      test('should return true for final states', () {
        expect(RedemptionStatus.completed.isFinal, isTrue);
        expect(RedemptionStatus.cancelled.isFinal, isTrue);
        expect(RedemptionStatus.expired.isFinal, isTrue);
      });

      test('should return false for non-final states', () {
        expect(RedemptionStatus.pending.isFinal, isFalse);
      });
    });

    group('canBeCancelled', () {
      test('should return true only for pending status', () {
        expect(RedemptionStatus.pending.canBeCancelled, isTrue);
        expect(RedemptionStatus.completed.canBeCancelled, isFalse);
        expect(RedemptionStatus.cancelled.canBeCancelled, isFalse);
        expect(RedemptionStatus.expired.canBeCancelled, isFalse);
      });
    });

    group('isActive', () {
      test('should return true only for pending status', () {
        expect(RedemptionStatus.pending.isActive, isTrue);
        expect(RedemptionStatus.completed.isActive, isFalse);
        expect(RedemptionStatus.cancelled.isActive, isFalse);
        expect(RedemptionStatus.expired.isActive, isFalse);
      });
    });

    group('toString', () {
      test('should return the value string', () {
        expect(RedemptionStatus.pending.toString(), 'pending');
        expect(RedemptionStatus.completed.toString(), 'completed');
        expect(RedemptionStatus.cancelled.toString(), 'cancelled');
        expect(RedemptionStatus.expired.toString(), 'expired');
      });
    });
  });
}