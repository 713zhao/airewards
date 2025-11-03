import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../entities/entities.dart';
import '../repositories/repositories.dart';

/// Parameters for canceling a redemption transaction.
/// 
/// This class encapsulates the data needed to cancel a pending
/// or processing redemption transaction.
class CancelRedemptionParams {
  final String userId;
  final String transactionId;
  final String reason;

  const CancelRedemptionParams({
    required this.userId,
    required this.transactionId,
    required this.reason,
  });

  /// Create validated params with business rule validation.
  /// 
  /// Validates user identification, transaction ID, and cancellation reason.
  /// 
  /// Returns [Either<ValidationFailure, CancelRedemptionParams>]:
  /// - Left: [ValidationFailure] if validation fails
  /// - Right: Valid parameters
  static Either<ValidationFailure, CancelRedemptionParams> create({
    required String userId,
    required String transactionId,
    required String reason,
  }) {
    // Validate user ID
    if (userId.isEmpty) {
      return Either.left(ValidationFailure('User ID cannot be empty'));
    }

    // Validate transaction ID
    if (transactionId.isEmpty) {
      return Either.left(ValidationFailure('Transaction ID cannot be empty'));
    }

    // Validate reason
    if (reason.isEmpty) {
      return Either.left(ValidationFailure('Cancellation reason cannot be empty'));
    }

    if (reason.length < 3) {
      return Either.left(ValidationFailure('Cancellation reason must be at least 3 characters'));
    }

    if (reason.length > 500) {
      return Either.left(ValidationFailure('Cancellation reason cannot exceed 500 characters'));
    }

    return Either.right(CancelRedemptionParams(
      userId: userId,
      transactionId: transactionId,
      reason: reason,
    ));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CancelRedemptionParams &&
           other.userId == userId &&
           other.transactionId == transactionId &&
           other.reason == reason;
  }

  @override
  int get hashCode => Object.hash(userId, transactionId, reason);

  @override
  String toString() {
    return 'CancelRedemptionParams(userId: $userId, transactionId: $transactionId, reason: $reason)';
  }
}

/// Use case for canceling a redemption transaction.
/// 
/// This use case handles the cancellation of pending or processing
/// redemption transactions, including point refunds and status updates.
/// 
/// Business Rules Enforced:
/// - BR-009: Final transactions (completed/cancelled) cannot be modified
/// - Only the transaction owner can cancel their redemptions
/// - Cancellation reason is required for audit trails
/// 
/// Usage:
/// ```dart
/// final result = await cancelRedemption(CancelRedemptionParams(
///   userId: 'user123',
///   transactionId: 'txn_456',
///   reason: 'Changed my mind',
/// ));
/// 
/// result.fold(
///   (failure) => print('Cancellation failed: $failure'),
///   (transaction) => print('Cancelled: ${transaction.id}'),
/// );
/// ```
class CancelRedemption implements UseCase<RedemptionTransaction, CancelRedemptionParams> {
  final RedemptionRepository _repository;

  const CancelRedemption(this._repository);

  @override
  Future<Either<Failure, RedemptionTransaction>> call(CancelRedemptionParams params) async {
    try {
      // Validate parameters first
      final validationResult = CancelRedemptionParams.create(
        userId: params.userId,
        transactionId: params.transactionId,
        reason: params.reason,
      );

      if (validationResult.isLeft) {
        return Either.left(validationResult.left);
      }

      // Verify transaction exists and belongs to user (BR-009 validation)
      final getTransactionResult = await _repository.getRedemptionTransaction(
        transactionId: params.transactionId,
        userId: params.userId,
      );

      if (getTransactionResult.isLeft) {
        return Either.left(getTransactionResult.left);
      }

      final transaction = getTransactionResult.right;

      // Check if transaction can be cancelled (BR-009)
      if (transaction.status.isFinal) {
        return Either.left(ValidationFailure(
          'Cannot cancel ${transaction.status.value} transaction. Final transactions cannot be modified.',
        ));
      }

      // Verify ownership
      if (transaction.userId != params.userId) {
        return Either.left(ValidationFailure(
          'Access denied. You can only cancel your own transactions.',
        ));
      }

      // Perform cancellation through repository
      final cancelResult = await _repository.cancelRedemption(
        transactionId: params.transactionId,
        userId: params.userId,
        reason: params.reason,
      );

      return cancelResult.fold(
        (failure) => Either.left(failure),
        (cancelledTransaction) => Either.right(cancelledTransaction),
      );
    } catch (e) {
      return Either.left(
        ValidationFailure('Unexpected error cancelling redemption: ${e.toString()}'),
      );
    }
  }

  /// Cancels redemption with additional validation checks.
  /// 
  /// This method provides more detailed validation and feedback,
  /// useful for enhanced user experience and error handling.
  /// 
  /// Returns additional context about the cancellation process.
  Future<Either<Failure, Map<String, dynamic>>> cancelWithDetails(
    CancelRedemptionParams params,
  ) async {
    try {
      // Get transaction details first
      final getTransactionResult = await _repository.getRedemptionTransaction(
        transactionId: params.transactionId,
        userId: params.userId,
      );

      if (getTransactionResult.isLeft) {
        return Either.left(getTransactionResult.left);
      }

      final transaction = getTransactionResult.right;

      // Perform the cancellation
      final cancelResult = await call(params);

      if (cancelResult.isLeft) {
        return Either.left(cancelResult.left);
      }

      final cancelledTransaction = cancelResult.right;

      // Return detailed result
      return Either.right({
        'transaction': cancelledTransaction,
        'pointsRefunded': transaction.pointsUsed,
        'originalStatus': transaction.status.value,
        'newStatus': cancelledTransaction.status.value,
        'cancellationReason': params.reason,
        'cancellationDate': cancelledTransaction.updatedAt ?? DateTime.now(),
      });
    } catch (e) {
      return Either.left(
        ValidationFailure('Error cancelling with details: ${e.toString()}'),
      );
    }
  }

  /// Validates if a transaction can be cancelled without actually cancelling it.
  /// 
  /// This method is useful for UI validation and showing appropriate
  /// cancel buttons or messages to users.
  Future<Either<Failure, bool>> canCancel(String userId, String transactionId) async {
    try {
      final getTransactionResult = await _repository.getRedemptionTransaction(
        transactionId: transactionId,
        userId: userId,
      );

      if (getTransactionResult.isLeft) {
        return Either.left(getTransactionResult.left);
      }

      final transaction = getTransactionResult.right;

      // Check business rules
      final canCancel = !transaction.status.isFinal && transaction.userId == userId;

      return Either.right(canCancel);
    } catch (e) {
      return Either.left(
        ValidationFailure('Error checking cancellation eligibility: ${e.toString()}'),
      );
    }
  }
}