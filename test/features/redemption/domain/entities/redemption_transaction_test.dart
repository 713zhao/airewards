import 'package:flutter_test/flutter_test.dart';
import 'package:ai_rewards_system/features/redemption/domain/entities/redemption_transaction.dart';
import 'package:ai_rewards_system/features/redemption/domain/entities/redemption_status.dart';

void main() {
  group('RedemptionTransaction', () {
    const validUserId = 'user123';
    const validOptionId = 'option456';
    const validPointsUsed = 500;

    group('create factory', () {
      test('should create valid redemption transaction', () {
        final transaction = RedemptionTransaction.create(
          userId: validUserId,
          optionId: validOptionId,
          pointsUsed: validPointsUsed,
        );

        expect(transaction.userId, validUserId);
        expect(transaction.optionId, validOptionId);
        expect(transaction.pointsUsed, validPointsUsed);
        expect(transaction.status, RedemptionStatus.pending);
        expect(transaction.id, isNotEmpty);
        expect(transaction.createdAt, isNotNull);
        expect(transaction.redeemedAt, isNotNull);
      });

      test('should create with notes', () {
        const notes = 'Special redemption for VIP user';
        final transaction = RedemptionTransaction.create(
          userId: validUserId,
          optionId: validOptionId,
          pointsUsed: validPointsUsed,
          notes: notes,
        );

        expect(transaction.notes, notes);
      });

      test('should trim notes', () {
        const notes = '  Test notes  ';
        final transaction = RedemptionTransaction.create(
          userId: validUserId,
          optionId: validOptionId,
          pointsUsed: validPointsUsed,
          notes: notes,
        );

        expect(transaction.notes, 'Test notes');
      });

      test('should generate unique IDs for different transactions', () {
        final transaction1 = RedemptionTransaction.create(
          userId: validUserId,
          optionId: validOptionId,
          pointsUsed: validPointsUsed,
        );

        final transaction2 = RedemptionTransaction.create(
          userId: 'user456',
          optionId: validOptionId,
          pointsUsed: validPointsUsed,
        );

        expect(transaction1.id, isNot(equals(transaction2.id)));
      });
    });

    group('validation', () {
      group('points used validation', () {
        test('should throw for points less than 100 (BR-008)', () {
          expect(
            () => RedemptionTransaction.create(
              userId: validUserId,
              optionId: validOptionId,
              pointsUsed: 99,
            ),
            throwsA(isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('BR-008'),
            )),
          );
        });

        test('should accept minimum valid points (100)', () {
          final transaction = RedemptionTransaction.create(
            userId: validUserId,
            optionId: validOptionId,
            pointsUsed: 100,
          );

          expect(transaction.pointsUsed, 100);
        });

        test('should throw for excessive points', () {
          expect(
            () => RedemptionTransaction.create(
              userId: validUserId,
              optionId: validOptionId,
              pointsUsed: 1000001,
            ),
            throwsA(isA<ArgumentError>()),
          );
        });
      });

      group('user ID validation', () {
        test('should throw for empty user ID', () {
          expect(
            () => RedemptionTransaction.create(
              userId: '',
              optionId: validOptionId,
              pointsUsed: validPointsUsed,
            ),
            throwsA(isA<ArgumentError>()),
          );
        });

        test('should throw for whitespace-only user ID', () {
          expect(
            () => RedemptionTransaction.create(
              userId: '   ',
              optionId: validOptionId,
              pointsUsed: validPointsUsed,
            ),
            throwsA(isA<ArgumentError>()),
          );
        });
      });

      group('option ID validation', () {
        test('should throw for empty option ID', () {
          expect(
            () => RedemptionTransaction.create(
              userId: validUserId,
              optionId: '',
              pointsUsed: validPointsUsed,
            ),
            throwsA(isA<ArgumentError>()),
          );
        });

        test('should throw for whitespace-only option ID', () {
          expect(
            () => RedemptionTransaction.create(
              userId: validUserId,
              optionId: '   ',
              pointsUsed: validPointsUsed,
            ),
            throwsA(isA<ArgumentError>()),
          );
        });
      });
    });

    group('copyWith', () {
      late RedemptionTransaction baseTransaction;

      setUp(() {
        baseTransaction = RedemptionTransaction.create(
          userId: validUserId,
          optionId: validOptionId,
          pointsUsed: validPointsUsed,
        );
      });

      test('should create copy with updated fields', () {
        const newNotes = 'Updated notes';
        final updatedTransaction = baseTransaction.copyWith(notes: newNotes);

        expect(updatedTransaction.notes, newNotes);
        expect(updatedTransaction.userId, baseTransaction.userId);
        expect(updatedTransaction.pointsUsed, baseTransaction.pointsUsed);
        expect(updatedTransaction.updatedAt, isNotNull);
      });

      test('should validate updated fields', () {
        expect(
          () => baseTransaction.copyWith(pointsUsed: 99),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should prevent status changes for finalized transactions (BR-009)', () {
        final completedTransaction = baseTransaction.complete();

        expect(
          () => completedTransaction.copyWith(status: RedemptionStatus.cancelled),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('BR-009'),
          )),
        );
      });

      test('should allow status changes for non-finalized transactions', () {
        final cancelledTransaction = baseTransaction.copyWith(
          status: RedemptionStatus.cancelled,
        );

        expect(cancelledTransaction.status, RedemptionStatus.cancelled);
      });
    });

    group('status transition methods', () {
      late RedemptionTransaction pendingTransaction;

      setUp(() {
        pendingTransaction = RedemptionTransaction.create(
          userId: validUserId,
          optionId: validOptionId,
          pointsUsed: validPointsUsed,
        );
      });

      group('complete', () {
        test('should complete pending transaction', () {
          final completed = pendingTransaction.complete();

          expect(completed.status, RedemptionStatus.completed);
          expect(completed.completedAt, isNotNull);
          expect(completed.isSuccessful, isTrue);
        });

        test('should complete with notes', () {
          const completionNotes = 'Successfully processed';
          final completed = pendingTransaction.complete(notes: completionNotes);

          expect(completed.notes, completionNotes);
        });

        test('should throw for non-pending transaction', () {
          final completedTransaction = pendingTransaction.complete();

          expect(
            () => completedTransaction.complete(),
            throwsA(isA<StateError>()),
          );
        });
      });

      group('cancel', () {
        test('should cancel pending transaction', () {
          final cancelled = pendingTransaction.cancel();

          expect(cancelled.status, RedemptionStatus.cancelled);
          expect(cancelled.cancelledAt, isNotNull);
        });

        test('should cancel with reason', () {
          const reason = 'User requested cancellation';
          final cancelled = pendingTransaction.cancel(reason: reason);

          expect(cancelled.notes, reason);
        });

        test('should throw for non-cancellable transaction', () {
          final completedTransaction = pendingTransaction.complete();

          expect(
            () => completedTransaction.cancel(),
            throwsA(isA<StateError>()),
          );
        });
      });

      group('expire', () {
        test('should expire pending transaction', () {
          final expired = pendingTransaction.expire();

          expect(expired.status, RedemptionStatus.expired);
        });

        test('should expire with notes', () {
          const notes = 'Transaction expired after timeout';
          final expired = pendingTransaction.expire(notes: notes);

          expect(expired.notes, notes);
        });

        test('should throw for non-pending transaction', () {
          final completedTransaction = pendingTransaction.complete();

          expect(
            () => completedTransaction.expire(),
            throwsA(isA<StateError>()),
          );
        });
      });
    });

    group('status check properties', () {
      late RedemptionTransaction pendingTransaction;

      setUp(() {
        pendingTransaction = RedemptionTransaction.create(
          userId: validUserId,
          optionId: validOptionId,
          pointsUsed: validPointsUsed,
        );
      });

      test('should correctly identify final states', () {
        expect(pendingTransaction.isFinal, isFalse);
        expect(pendingTransaction.complete().isFinal, isTrue);
        expect(pendingTransaction.cancel().isFinal, isTrue);
        expect(pendingTransaction.expire().isFinal, isTrue);
      });

      test('should correctly identify cancellable states', () {
        expect(pendingTransaction.canBeCancelled, isTrue);
        expect(pendingTransaction.complete().canBeCancelled, isFalse);
        expect(pendingTransaction.cancel().canBeCancelled, isFalse);
        expect(pendingTransaction.expire().canBeCancelled, isFalse);
      });

      test('should correctly identify pending state', () {
        expect(pendingTransaction.isPending, isTrue);
        expect(pendingTransaction.complete().isPending, isFalse);
        expect(pendingTransaction.cancel().isPending, isFalse);
        expect(pendingTransaction.expire().isPending, isFalse);
      });

      test('should correctly identify successful transactions', () {
        expect(pendingTransaction.isSuccessful, isFalse);
        expect(pendingTransaction.complete().isSuccessful, isTrue);
        expect(pendingTransaction.cancel().isSuccessful, isFalse);
        expect(pendingTransaction.expire().isSuccessful, isFalse);
      });
    });

    group('age property', () {
      test('should calculate age correctly', () {
        final transaction = RedemptionTransaction.create(
          userId: validUserId,
          optionId: validOptionId,
          pointsUsed: validPointsUsed,
        );

        final age = transaction.age;
        expect(age.inMilliseconds, greaterThanOrEqualTo(0));
        expect(age.inHours, lessThan(1));
      });
    });

    group('equality', () {
      test('should be equal for same properties', () {
        final transaction1 = RedemptionTransaction.create(
          userId: validUserId,
          optionId: validOptionId,
          pointsUsed: validPointsUsed,
        );
        final transaction2 = RedemptionTransaction(
          id: transaction1.id,
          userId: transaction1.userId,
          optionId: transaction1.optionId,
          pointsUsed: transaction1.pointsUsed,
          redeemedAt: transaction1.redeemedAt,
          status: transaction1.status,
          notes: transaction1.notes,
          createdAt: transaction1.createdAt,
          updatedAt: transaction1.updatedAt,
          completedAt: transaction1.completedAt,
          cancelledAt: transaction1.cancelledAt,
        );

        expect(transaction1, equals(transaction2));
      });

      test('should not be equal for different properties', () {
        final transaction1 = RedemptionTransaction.create(
          userId: validUserId,
          optionId: validOptionId,
          pointsUsed: validPointsUsed,
        );
        final transaction2 = transaction1.copyWith(notes: 'Different notes');

        expect(transaction1, isNot(equals(transaction2)));
      });
    });

    group('toString', () {
      test('should return meaningful string representation', () {
        final transaction = RedemptionTransaction.create(
          userId: validUserId,
          optionId: validOptionId,
          pointsUsed: validPointsUsed,
        );

        final toString = transaction.toString();
        expect(toString, contains('RedemptionTransaction'));
        expect(toString, contains(transaction.id));
        expect(toString, contains(validUserId));
        expect(toString, contains(validPointsUsed.toString()));
        expect(toString, contains('pending'));
      });
    });
  });
}