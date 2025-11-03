import '../../../../core/errors/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/utils/either.dart';
import '../entities/entities.dart';

/// Repository interface for redemption-related data operations
/// 
/// This interface defines the contract for all redemption data operations,
/// following the Repository pattern from Clean Architecture.
/// Implementations should handle data persistence, caching, and point balance validation.
abstract class RedemptionRepository {
  /// Retrieves all available redemption options
  /// 
  /// Returns active redemption options that users can exchange points for.
  /// Options are filtered by availability and expiry status.
  /// 
  /// Returns:
  /// - Right: [List<RedemptionOption>] sorted by required points (ascending)
  /// - Left: [NetworkFailure] for connectivity issues
  /// - Left: [CacheFailure] if local cache is corrupted
  /// 
  /// Example:
  /// ```dart
  /// final result = await repository.getRedemptionOptions();
  /// if (result.isRight) {
  ///   final options = result.right;
  ///   print('Available options: ${options.length}');
  /// }
  /// ```
  Future<Either<Failure, List<RedemptionOption>>> getRedemptionOptions();

  /// Retrieves available redemption options filtered by category
  /// 
  /// Parameters:
  /// - [categoryId]: Optional category ID for filtering options
  /// 
  /// Returns:
  /// - Right: [List<RedemptionOption>] filtered by category
  /// - Left: [Failure] if operation fails
  /// 
  /// Example:
  /// ```dart
  /// final result = await repository.getRedemptionOptionsByCategory('food');
  /// ```
  Future<Either<Failure, List<RedemptionOption>>> getRedemptionOptionsByCategory({
    String? categoryId,
  });

  /// Processes a point redemption transaction
  /// 
  /// Business rule validation:
  /// - BR-006: Cannot redeem more points than available balance
  /// - BR-007: Redemption requires confirmation dialog (handled in use case)
  /// - BR-008: Minimum redemption value: 100 points
  /// - BR-009: Redemptions are final and cannot be reversed
  /// - BR-010: Partial redemptions are allowed
  /// 
  /// Parameters:
  /// - [request]: The redemption request details
  /// 
  /// Returns:
  /// - Right: [RedemptionTransaction] with PENDING status initially
  /// - Left: [ValidationFailure] for business rule violations
  /// - Left: [InsufficientPointsFailure] for insufficient balance
  /// - Left: [NetworkFailure] for connectivity issues
  /// 
  /// Example:
  /// ```dart
  /// final request = RedemptionRequest(
  ///   userId: 'user123',
  ///   optionId: 'option456', 
  ///   pointsToRedeem: 500,
  ///   notes: 'Birthday reward',
  /// );
  /// 
  /// final result = await repository.redeemPoints(request);
  /// ```
  Future<Either<Failure, RedemptionTransaction>> redeemPoints(RedemptionRequest request);

  /// Retrieves paginated redemption history for a user
  /// 
  /// Parameters:
  /// - [userId]: The user's unique identifier
  /// - [page]: Page number for pagination (1-based, defaults to 1)
  /// - [limit]: Maximum items per page (defaults to 20)
  /// - [status]: Optional status filter for transactions
  /// - [startDate]: Optional start date for filtering transactions
  /// - [endDate]: Optional end date for filtering transactions
  /// 
  /// Returns:
  /// - Right: [PaginatedResult<RedemptionTransaction>] with filtered results
  /// - Left: [Failure] if operation fails
  /// 
  /// Example:
  /// ```dart
  /// final result = await repository.getRedemptionHistory(
  ///   userId: 'user123',
  ///   page: 1,
  ///   limit: 10,
  ///   status: RedemptionStatus.completed,
  /// );
  /// ```
  Future<Either<Failure, PaginatedResult<RedemptionTransaction>>> getRedemptionHistory({
    required String userId,
    int page = 1,
    int limit = 20,
    RedemptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Checks if a user can redeem the specified points amount
  /// 
  /// Validates point balance and redemption rules without processing the transaction.
  /// Used for UI validation before showing redemption options.
  /// 
  /// Parameters:
  /// - [userId]: The user's unique identifier
  /// - [points]: Number of points to validate for redemption
  /// 
  /// Returns:
  /// - Right: [bool] true if user can redeem the points
  /// - Left: [Failure] if validation check fails
  /// 
  /// Example:
  /// ```dart
  /// final result = await repository.canRedeem('user123', 500);
  /// if (result.isRight && result.right) {
  ///   // User can afford this redemption
  /// }
  /// ```
  Future<Either<Failure, bool>> canRedeem(String userId, int points);

  /// Retrieves the current available points for redemption
  /// 
  /// Returns the user's point balance that can be used for redemptions.
  /// This may differ from total points if some are reserved or pending.
  /// 
  /// Parameters:
  /// - [userId]: The user's unique identifier
  /// 
  /// Returns:
  /// - Right: [int] available points for redemption
  /// - Left: [Failure] if operation fails
  /// 
  /// Example:
  /// ```dart
  /// final result = await repository.getAvailablePoints('user123');
  /// if (result.isRight) {
  ///   print('Available for redemption: ${result.right} points');
  /// }
  /// ```
  Future<Either<Failure, int>> getAvailablePoints(String userId);

  /// Watches available points for a user with real-time updates
  /// 
  /// Returns a stream that emits the current available points whenever they change.
  /// Useful for real-time UI updates during redemption flows.
  /// 
  /// Parameters:
  /// - [userId]: The user's unique identifier
  /// 
  /// Returns:
  /// - Stream<int> that emits available points on changes
  /// - Stream errors represent failures (network, auth, etc.)
  /// 
  /// Example:
  /// ```dart
  /// repository.watchAvailablePoints('user123').listen(
  ///   (points) => print('Available points updated: $points'),
  ///   onError: (error) => print('Error watching points: $error'),
  /// );
  /// ```
  Stream<int> watchAvailablePoints(String userId);

  /// Retrieves a specific redemption transaction by ID
  /// 
  /// Parameters:
  /// - [transactionId]: Unique identifier of the transaction
  /// - [userId]: User ID for ownership verification
  /// 
  /// Returns:
  /// - Right: [RedemptionTransaction] with current status
  /// - Left: [NotFoundFailure] if transaction doesn't exist
  /// - Left: [AuthFailure] if user doesn't own the transaction
  /// 
  /// Example:
  /// ```dart
  /// final result = await repository.getRedemptionTransaction(
  ///   transactionId: 'txn123',
  ///   userId: 'user123',
  /// );
  /// ```
  Future<Either<Failure, RedemptionTransaction>> getRedemptionTransaction({
    required String transactionId,
    required String userId,
  });

  /// Updates the status of a redemption transaction
  /// 
  /// Business rule validation:
  /// - BR-009: Final transactions cannot be modified
  /// - Only authorized status transitions allowed
  /// - Audit trail must be maintained
  /// 
  /// Parameters:
  /// - [transactionId]: ID of the transaction to update
  /// - [newStatus]: New status to set
  /// - [notes]: Optional notes for the status change
  /// - [userId]: User ID for ownership verification
  /// 
  /// Returns:
  /// - Right: [RedemptionTransaction] with updated status
  /// - Left: [ValidationFailure] for invalid status transitions
  /// - Left: [NotFoundFailure] if transaction doesn't exist
  /// - Left: [AuthFailure] if user doesn't own the transaction
  /// 
  /// Example:
  /// ```dart
  /// final result = await repository.updateTransactionStatus(
  ///   transactionId: 'txn123',
  ///   newStatus: RedemptionStatus.completed,
  ///   notes: 'Reward delivered successfully',
  ///   userId: 'user123',
  /// );
  /// ```
  Future<Either<Failure, RedemptionTransaction>> updateTransactionStatus({
    required String transactionId,
    required RedemptionStatus newStatus,
    String? notes,
    required String userId,
  });

  /// Cancels a pending redemption transaction
  /// 
  /// Business rule validation:
  /// - Only pending transactions can be cancelled
  /// - Points are immediately returned to user's balance
  /// - Cancellation reason is required for audit
  /// 
  /// Parameters:
  /// - [transactionId]: ID of the transaction to cancel
  /// - [userId]: User ID for ownership verification
  /// - [reason]: Reason for cancellation
  /// 
  /// Returns:
  /// - Right: [RedemptionTransaction] with cancelled status
  /// - Left: [ValidationFailure] if transaction cannot be cancelled
  /// - Left: [NotFoundFailure] if transaction doesn't exist
  /// - Left: [AuthFailure] if user doesn't own the transaction
  /// 
  /// Example:
  /// ```dart
  /// final result = await repository.cancelRedemption(
  ///   transactionId: 'txn123',
  ///   userId: 'user123',
  ///   reason: 'User requested cancellation',
  /// );
  /// ```
  Future<Either<Failure, RedemptionTransaction>> cancelRedemption({
    required String transactionId,
    required String userId,
    required String reason,
  });

  /// Retrieves redemption statistics for a user
  /// 
  /// Returns summary statistics about user's redemption activity
  /// including total redeemed, successful transactions, etc.
  /// 
  /// Parameters:
  /// - [userId]: The user's unique identifier
  /// - [startDate]: Optional start date for statistics period
  /// - [endDate]: Optional end date for statistics period
  /// 
  /// Returns:
  /// - Right: [RedemptionStats] with user's redemption statistics
  /// - Left: [Failure] if operation fails
  /// 
  /// Example:
  /// ```dart
  /// final result = await repository.getRedemptionStats('user123');
  /// if (result.isRight) {
  ///   final stats = result.right;
  ///   print('Total redeemed: ${stats.totalPointsRedeemed}');
  /// }
  /// ```
  Future<Either<Failure, RedemptionStats>> getRedemptionStats({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Syncs redemption data with remote server
  /// 
  /// Uploads pending local changes and downloads remote updates.
  /// Handles transaction status synchronization and conflict resolution.
  /// 
  /// Returns:
  /// - Right: [RedemptionSyncResult] with statistics
  /// - Left: [NetworkFailure] if sync fails
  /// 
  /// Example:
  /// ```dart
  /// final result = await repository.syncRedemptions();
  /// if (result.isRight) {
  ///   final syncResult = result.right;
  ///   print('Synced ${syncResult.transactionsSynced} transactions');
  /// }
  /// ```
  Future<Either<Failure, RedemptionSyncResult>> syncRedemptions();
}

/// Request object for redemption operations
class RedemptionRequest {
  final String userId;
  final String optionId;
  final int pointsToRedeem;
  final String? notes;
  final bool requiresConfirmation;

  const RedemptionRequest({
    required this.userId,
    required this.optionId,
    required this.pointsToRedeem,
    this.notes,
    this.requiresConfirmation = true,
  });

  @override
  String toString() {
    return 'RedemptionRequest{userId: $userId, optionId: $optionId, pointsToRedeem: $pointsToRedeem}';
  }
}



/// Result of a redemption synchronization operation
class RedemptionSyncResult {
  final int transactionsSynced;
  final int optionsSynced;
  final List<String> conflictedTransactions;
  final DateTime syncTimestamp;

  const RedemptionSyncResult({
    required this.transactionsSynced,
    required this.optionsSynced,
    required this.conflictedTransactions,
    required this.syncTimestamp,
  });

  @override
  String toString() {
    return 'RedemptionSyncResult{transactionsSynced: $transactionsSynced, '
           'optionsSynced: $optionsSynced, '
           'conflictedTransactions: ${conflictedTransactions.length}, '
           'syncTimestamp: $syncTimestamp}';
  }
}

/// Specific failure for insufficient points
class InsufficientPointsFailure extends Failure {
  final int requiredPoints;
  final int availablePoints;

  const InsufficientPointsFailure({
    required this.requiredPoints,
    required this.availablePoints,
    String message = 'Insufficient points for redemption',
  }) : super(message);

  @override
  List<Object?> get props => [requiredPoints, availablePoints, message];

  @override
  String toString() {
    return 'InsufficientPointsFailure{required: $requiredPoints, available: $availablePoints}';
  }
}