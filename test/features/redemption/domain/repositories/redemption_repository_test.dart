import 'package:flutter_test/flutter_test.dart';
import 'package:ai_rewards_system/features/redemption/domain/repositories/redemption_repository.dart';

void main() {
  group('RedemptionRequest', () {
    const validUserId = 'user123';
    const validOptionId = 'option456';
    const validPointsToRedeem = 500;

    test('should create valid redemption request with required fields', () {
      const request = RedemptionRequest(
        userId: validUserId,
        optionId: validOptionId,
        pointsToRedeem: validPointsToRedeem,
      );

      expect(request.userId, validUserId);
      expect(request.optionId, validOptionId);
      expect(request.pointsToRedeem, validPointsToRedeem);
      expect(request.requiresConfirmation, isTrue); // default value
      expect(request.notes, isNull);
    });

    test('should create redemption request with optional fields', () {
      const notes = 'Special redemption';
      const request = RedemptionRequest(
        userId: validUserId,
        optionId: validOptionId,
        pointsToRedeem: validPointsToRedeem,
        notes: notes,
        requiresConfirmation: false,
      );

      expect(request.notes, notes);
      expect(request.requiresConfirmation, isFalse);
    });

    test('should have meaningful toString', () {
      const request = RedemptionRequest(
        userId: validUserId,
        optionId: validOptionId,
        pointsToRedeem: validPointsToRedeem,
      );

      final toString = request.toString();
      expect(toString, contains('RedemptionRequest'));
      expect(toString, contains(validUserId));
      expect(toString, contains(validOptionId));
      expect(toString, contains(validPointsToRedeem.toString()));
    });
  });

  group('RedemptionStats', () {
    test('should create valid redemption stats', () {
      final firstDate = DateTime(2025, 1, 1);
      final lastDate = DateTime(2025, 10, 31);
      
      final stats = RedemptionStats(
        totalTransactions: 10,
        completedTransactions: 8,
        cancelledTransactions: 2,
        totalPointsRedeemed: 4000,
        firstRedemptionDate: firstDate,
        lastRedemptionDate: lastDate,
        favoriteCategory: 'food',
      );

      expect(stats.totalTransactions, 10);
      expect(stats.completedTransactions, 8);
      expect(stats.cancelledTransactions, 2);
      expect(stats.totalPointsRedeemed, 4000);
      expect(stats.favoriteCategory, 'food');
    });

    test('should calculate success rate correctly', () {
      const stats = RedemptionStats(
        totalTransactions: 10,
        completedTransactions: 8,
        cancelledTransactions: 2,
        totalPointsRedeemed: 4000,
      );

      expect(stats.successRate, 80.0);
    });

    test('should handle zero transactions for success rate', () {
      const stats = RedemptionStats(
        totalTransactions: 0,
        completedTransactions: 0,
        cancelledTransactions: 0,
        totalPointsRedeemed: 0,
      );

      expect(stats.successRate, 0.0);
    });

    test('should calculate average points per redemption correctly', () {
      const stats = RedemptionStats(
        totalTransactions: 10,
        completedTransactions: 8,
        cancelledTransactions: 2,
        totalPointsRedeemed: 4000,
      );

      expect(stats.averagePointsPerRedemption, 500.0);
    });

    test('should handle zero completed transactions for average', () {
      const stats = RedemptionStats(
        totalTransactions: 5,
        completedTransactions: 0,
        cancelledTransactions: 5,
        totalPointsRedeemed: 0,
      );

      expect(stats.averagePointsPerRedemption, 0.0);
    });

    test('should have meaningful toString', () {
      const stats = RedemptionStats(
        totalTransactions: 10,
        completedTransactions: 8,
        cancelledTransactions: 2,
        totalPointsRedeemed: 4000,
      );

      final toString = stats.toString();
      expect(toString, contains('RedemptionStats'));
      expect(toString, contains('totalTransactions: 10'));
      expect(toString, contains('completedTransactions: 8'));
      expect(toString, contains('totalPointsRedeemed: 4000'));
      expect(toString, contains('80.0%'));
    });
  });

  group('RedemptionSyncResult', () {
    test('should create valid sync result', () {
      final timestamp = DateTime.now();
      final result = RedemptionSyncResult(
        transactionsSynced: 5,
        optionsSynced: 3,
        conflictedTransactions: const ['txn1', 'txn2'],
        syncTimestamp: timestamp,
      );

      expect(result.transactionsSynced, 5);
      expect(result.optionsSynced, 3);
      expect(result.conflictedTransactions, hasLength(2));
      expect(result.conflictedTransactions, contains('txn1'));
      expect(result.conflictedTransactions, contains('txn2'));
      expect(result.syncTimestamp, timestamp);
    });

    test('should have meaningful toString', () {
      final timestamp = DateTime.now();
      final result = RedemptionSyncResult(
        transactionsSynced: 5,
        optionsSynced: 3,
        conflictedTransactions: const ['txn1', 'txn2'],
        syncTimestamp: timestamp,
      );

      final toString = result.toString();
      expect(toString, contains('RedemptionSyncResult'));
      expect(toString, contains('transactionsSynced: 5'));
      expect(toString, contains('optionsSynced: 3'));
      expect(toString, contains('conflictedTransactions: 2'));
      expect(toString, contains('syncTimestamp: $timestamp'));
    });
  });

  group('InsufficientPointsFailure', () {
    test('should create failure with required and available points', () {
      const failure = InsufficientPointsFailure(
        requiredPoints: 500,
        availablePoints: 300,
      );

      expect(failure.requiredPoints, 500);
      expect(failure.availablePoints, 300);
      expect(failure.message, 'Insufficient points for redemption');
    });

    test('should create failure with custom message', () {
      const customMessage = 'Not enough points for this reward';
      const failure = InsufficientPointsFailure(
        requiredPoints: 500,
        availablePoints: 300,
        message: customMessage,
      );

      expect(failure.message, customMessage);
    });

    test('should have meaningful toString', () {
      const failure = InsufficientPointsFailure(
        requiredPoints: 500,
        availablePoints: 300,
      );

      final toString = failure.toString();
      expect(toString, contains('InsufficientPointsFailure'));
      expect(toString, contains('required: 500'));
      expect(toString, contains('available: 300'));
    });

    test('should be equal for same points', () {
      const failure1 = InsufficientPointsFailure(
        requiredPoints: 500,
        availablePoints: 300,
      );
      const failure2 = InsufficientPointsFailure(
        requiredPoints: 500,
        availablePoints: 300,
      );

      expect(failure1, equals(failure2));
    });

    test('should not be equal for different points', () {
      const failure1 = InsufficientPointsFailure(
        requiredPoints: 500,
        availablePoints: 300,
      );
      const failure2 = InsufficientPointsFailure(
        requiredPoints: 600,
        availablePoints: 300,
      );

      expect(failure1, isNot(equals(failure2)));
    });
  });
}