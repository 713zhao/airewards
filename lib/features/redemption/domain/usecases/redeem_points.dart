import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../entities/entities.dart';
import '../repositories/repositories.dart';

/// Parameters for redeeming points.
/// 
/// This class encapsulates all the required data for processing a point redemption
/// and provides comprehensive validation according to business rules.
class RedeemPointsParams {
  final String userId;
  final String optionId;
  final int pointsToRedeem;
  final String? notes;
  final bool requiresConfirmation;

  const RedeemPointsParams({
    required this.userId,
    required this.optionId,
    required this.pointsToRedeem,
    this.notes,
    this.requiresConfirmation = true,
  });

  /// Create validated params with business rule validation.
  /// 
  /// Validates according to:
  /// - BR-006: Users cannot redeem more points than available balance
  /// - BR-008: Minimum redemption value: 100 points
  /// - User and option ID validation
  /// 
  /// Returns [Either<ValidationFailure, RedeemPointsParams>]:
  /// - Left: [ValidationFailure] if validation fails
  /// - Right: [RedeemPointsParams] if validation succeeds
  static Either<ValidationFailure, RedeemPointsParams> create({
    required String userId,
    required String optionId,
    required int pointsToRedeem,
    String? notes,
    bool requiresConfirmation = true,
  }) {
    // Validate user ID
    if (userId.trim().isEmpty) {
      return Either.left(ValidationFailure('User ID cannot be empty'));
    }

    // Validate option ID
    if (optionId.trim().isEmpty) {
      return Either.left(ValidationFailure('Redemption option ID cannot be empty'));
    }

    // Validate points according to business rules
    final pointsValidation = _validatePoints(pointsToRedeem);
    if (pointsValidation.isLeft) {
      return Either.left(pointsValidation.left);
    }

    // Validate notes length if provided
    if (notes != null && notes.length > 500) {
      return Either.left(ValidationFailure('Notes cannot exceed 500 characters'));
    }

    return Either.right(RedeemPointsParams(
      userId: userId.trim(),
      optionId: optionId.trim(),
      pointsToRedeem: pointsToRedeem,
      notes: notes?.trim(),
      requiresConfirmation: requiresConfirmation,
    ));
  }

  /// Validates points according to business rule BR-008
  static Either<ValidationFailure, int> _validatePoints(int points) {
    // BR-008: Minimum redemption value: 100 points
    if (points < 100) {
      return Either.left(ValidationFailure(
        'Minimum redemption value is 100 points (BR-008). Got: $points',
      ));
    }

    // Maximum redemption limit for security
    if (points > 1000000) {
      return Either.left(ValidationFailure(
        'Maximum redemption value is 1,000,000 points. Got: $points',
      ));
    }

    return Either.right(points);
  }

  /// Converts to RedemptionRequest for repository operations
  RedemptionRequest toRedemptionRequest() {
    return RedemptionRequest(
      userId: userId,
      optionId: optionId,
      pointsToRedeem: pointsToRedeem,
      notes: notes,
      requiresConfirmation: requiresConfirmation,
    );
  }

  @override
  String toString() {
    return 'RedeemPointsParams(userId: $userId, optionId: $optionId, '
           'pointsToRedeem: $pointsToRedeem, requiresConfirmation: $requiresConfirmation)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RedeemPointsParams &&
        other.userId == userId &&
        other.optionId == optionId &&
        other.pointsToRedeem == pointsToRedeem &&
        other.notes == notes &&
        other.requiresConfirmation == requiresConfirmation;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        optionId.hashCode ^
        pointsToRedeem.hashCode ^
        notes.hashCode ^
        requiresConfirmation.hashCode;
  }
}

/// Use case for redeeming points for rewards.
/// 
/// This use case handles the complete business logic for point redemptions,
/// including validation, business rule enforcement, and error handling.
/// It ensures transaction atomicity and proper audit logging.
/// 
/// Business rules enforced:
/// - BR-006: Users cannot redeem more points than available balance
/// - BR-007: Redemption requires confirmation dialog (enforced in presentation layer)
/// - BR-008: Minimum redemption value: 100 points
/// - BR-009: Redemptions are final and cannot be reversed
/// - BR-010: Partial redemptions are allowed
/// 
/// Additional validations:
/// - Option availability and expiry checks
/// - Point balance verification
/// - Transaction atomicity
/// - Audit trail maintenance
class RedeemPoints implements UseCase<RedemptionTransaction, RedeemPointsParams> {
  final RedemptionRepository repository;

  /// Creates a new [RedeemPoints] use case.
  /// 
  /// Parameters:
  /// - [repository]: The redemption repository for data operations
  const RedeemPoints(this.repository);

  /// Execute the point redemption process.
  /// 
  /// This method orchestrates the redemption flow and handles all business
  /// logic related to redeeming points for rewards.
  /// 
  /// Parameters:
  /// - [params]: Contains all data needed to process the redemption
  /// 
  /// Returns [Either<Failure, RedemptionTransaction>]:
  /// - Left: [Failure] if redemption fails
  /// - Right: [RedemptionTransaction] if redemption succeeds
  /// 
  /// Possible failures:
  /// - [ValidationFailure] for business rule violations
  /// - [InsufficientPointsFailure] for insufficient balance
  /// - [NotFoundFailure] if redemption option doesn't exist
  /// - [NetworkFailure] for network connectivity issues
  /// 
  /// Business logic handled:
  /// 1. Validates redemption option exists and is available
  /// 2. Verifies user has sufficient points (BR-006)
  /// 3. Validates minimum redemption amount (BR-008)
  /// 4. Creates atomic redemption transaction (BR-009)
  /// 5. Provides comprehensive audit logging
  @override
  Future<Either<Failure, RedemptionTransaction>> call(RedeemPointsParams params) async {
    try {
      // Step 1: Validate redemption option exists and is available
      final optionValidation = await _validateRedemptionOption(params.optionId);
      if (optionValidation.isLeft) {
        return Either.left(optionValidation.left);
      }
      final redemptionOption = optionValidation.right;

      // Step 2: Verify user has sufficient points (BR-006)
      final balanceValidation = await _validatePointBalance(params.userId, params.pointsToRedeem);
      if (balanceValidation.isLeft) {
        return Either.left(balanceValidation.left);
      }

      // Step 3: Validate redemption amount against option requirements
      final amountValidation = _validateRedemptionAmount(params.pointsToRedeem, redemptionOption.requiredPoints);
      if (amountValidation.isLeft) {
        return Either.left(amountValidation.left);
      }

      // Step 4: Additional business validation
      final businessValidation = await _performBusinessValidation(params, redemptionOption);
      if (businessValidation.isLeft) {
        return Either.left(businessValidation.left);
      }

      // Step 5: Process the redemption through repository (atomic operation)
      final redemptionRequest = params.toRedemptionRequest();
      final result = await repository.redeemPoints(redemptionRequest);

      return result.fold(
        // Handle redemption failure
        (failure) async {
          await _logFailedRedemption(params, failure);
          return Either.left(failure);
        },
        // Handle redemption success
        (transaction) async {
          // Step 6: Log successful redemption for audit trail
          await _logSuccessfulRedemption(transaction, redemptionOption);
          
          // Note: In a more complex implementation, you might:
          // - Send confirmation notifications to user
          // - Update user achievement/badge progress
          // - Sync with external reward fulfillment systems
          // - Update analytics and reporting data
          // - Trigger follow-up actions based on redemption type
          
          return Either.right(transaction);
        },
      );
    } catch (e) {
      // Handle unexpected errors
      await _logUnexpectedError(params, e);
      return Either.left(ValidationFailure('Unexpected error during point redemption: $e'));
    }
  }

  /// Validates that the specified redemption option exists and is available.
  Future<Either<Failure, RedemptionOption>> _validateRedemptionOption(String optionId) async {
    final optionsResult = await repository.getRedemptionOptions();
    
    return optionsResult.fold(
      (failure) => Either.left(failure),
      (options) {
        try {
          final option = options.firstWhere(
            (opt) => opt.id == optionId,
            orElse: () => throw StateError('Option not found'),
          );
          
          // Check if option is available (not expired and active)
          if (!option.isAvailable) {
            return Either.left(ValidationFailure(
              'Redemption option is no longer available',
            ));
          }
          
          return Either.right(option);
        } catch (e) {
          return Either.left(ValidationFailure('Redemption option with ID $optionId not found'));
        }
      },
    );
  }

  /// Verifies user has sufficient points for the redemption (BR-006).
  Future<Either<Failure, int>> _validatePointBalance(String userId, int requiredPoints) async {
    final balanceResult = await repository.getAvailablePoints(userId);
    
    return balanceResult.fold(
      (failure) => Either.left(failure),
      (availablePoints) {
        // BR-006: Users cannot redeem more points than available balance
        if (availablePoints < requiredPoints) {
          return Either.left(InsufficientPointsFailure(
            requiredPoints: requiredPoints,
            availablePoints: availablePoints,
          ));
        }
        
        return Either.right(availablePoints);
      },
    );
  }

  /// Validates redemption amount against option requirements (BR-010: Partial redemptions allowed).
  Either<ValidationFailure, bool> _validateRedemptionAmount(int pointsToRedeem, int optionRequiredPoints) {
    // For partial redemptions (BR-010), check if points are sufficient for at least one unit
    if (pointsToRedeem < optionRequiredPoints) {
      return Either.left(ValidationFailure(
        'Insufficient points for this redemption option. '
        'Required: $optionRequiredPoints, Provided: $pointsToRedeem',
      ));
    }
    
    // Validate that redemption amount is a valid multiple for partial redemptions
    // This allows users to redeem multiples of the base requirement
    final remainder = pointsToRedeem % optionRequiredPoints;
    if (remainder != 0) {
      return Either.left(ValidationFailure(
        'Points to redeem must be a multiple of the required amount. '
        'Required: $optionRequiredPoints, Provided: $pointsToRedeem',
      ));
    }
    
    return Either.right(true);
  }

  /// Performs additional business validation that requires repository access.
  Future<Either<Failure, bool>> _performBusinessValidation(
    RedeemPointsParams params,
    RedemptionOption option,
  ) async {
    // Validate user can redeem this amount
    final canRedeemResult = await repository.canRedeem(params.userId, params.pointsToRedeem);
    if (canRedeemResult.isLeft) {
      return Either.left(canRedeemResult.left);
    }
    
    if (!canRedeemResult.right) {
      return Either.left(ValidationFailure('User is not eligible to redeem this amount'));
    }

    // Additional validation could include:
    // - Daily/monthly redemption limits per user
    // - Category-specific redemption restrictions
    // - Time-based restrictions (e.g., no redemptions on holidays)
    // - User account status validation
    // - Fraud detection checks
    
    return Either.right(true);
  }

  /// Validates redemption data before attempting to process.
  /// 
  /// This method can be used by the presentation layer for early validation
  /// before making the actual redemption request.
  /// 
  /// Parameters:
  /// - [userId]: User ID to validate
  /// - [optionId]: Redemption option ID to validate
  /// - [pointsToRedeem]: Points amount to validate
  /// - [notes]: Optional notes to validate
  /// 
  /// Returns [Either<ValidationFailure, bool>]:
  /// - Left: [ValidationFailure] if validation fails
  /// - Right: true if validation passes
  Future<Either<ValidationFailure, bool>> validateRedemptionData({
    required String userId,
    required String optionId,
    required int pointsToRedeem,
    String? notes,
  }) async {
    final paramsResult = RedeemPointsParams.create(
      userId: userId,
      optionId: optionId,
      pointsToRedeem: pointsToRedeem,
      notes: notes,
    );

    return paramsResult.fold(
      (failure) => Either.left(failure),
      (_) => Either.right(true),
    );
  }

  /// Gets redemption preview information for the user.
  /// 
  /// This method provides information about what the redemption will cost
  /// and the user's remaining balance after redemption.
  /// 
  /// Parameters:
  /// - [userId]: User requesting the redemption
  /// - [optionId]: Redemption option being considered
  /// - [pointsToRedeem]: Points amount for redemption
  /// 
  /// Returns [Either<Failure, RedemptionPreview>]:
  /// - Left: [Failure] if preview calculation fails
  /// - Right: [RedemptionPreview] with cost and balance information
  Future<Either<Failure, RedemptionPreview>> getRedemptionPreview({
    required String userId,
    required String optionId,
    required int pointsToRedeem,
  }) async {
    final optionResult = await _validateRedemptionOption(optionId);
    if (optionResult.isLeft) {
      return Either.left(optionResult.left);
    }
    final option = optionResult.right;

    final balanceResult = await repository.getAvailablePoints(userId);
    if (balanceResult.isLeft) {
      return Either.left(balanceResult.left);
    }
    final currentBalance = balanceResult.right;

    final remainingBalance = currentBalance - pointsToRedeem;
    final canAfford = currentBalance >= pointsToRedeem;
    final unitsToRedeem = pointsToRedeem ~/ option.requiredPoints;

    return Either.right(RedemptionPreview(
      option: option,
      pointsToRedeem: pointsToRedeem,
      currentBalance: currentBalance,
      remainingBalance: remainingBalance,
      canAfford: canAfford,
      unitsToRedeem: unitsToRedeem,
    ));
  }

  /// Log failed redemption attempt for audit trail and fraud detection.
  Future<void> _logFailedRedemption(RedeemPointsParams params, Failure failure) async {
    // In a real implementation, this would:
    // - Log to audit system with failure details
    // - Track failed redemption attempts per user
    // - Monitor for suspicious redemption patterns
    // - Send alerts for repeated failures
    // - Update fraud detection metrics
    
    // For now, this is a placeholder
    // print('Failed redemption attempt for user ${params.userId}: $failure');
  }

  /// Log successful redemption for audit trail and analytics.
  Future<void> _logSuccessfulRedemption(RedemptionTransaction transaction, RedemptionOption option) async {
    // In a real implementation, this would:
    // - Log to audit system with transaction details
    // - Update user redemption statistics
    // - Track popular redemption options
    // - Send confirmation notifications
    // - Update analytics dashboards
    // - Trigger fulfillment workflows
    
    // For now, this is a placeholder
    // print('Successful redemption: ${transaction.id} for ${transaction.pointsUsed} points');
  }

  /// Log unexpected errors for debugging and monitoring.
  Future<void> _logUnexpectedError(RedeemPointsParams params, Object error) async {
    // In a real implementation, this would:
    // - Log to error monitoring system
    // - Send alerts to development team
    // - Track error patterns and frequency
    // - Include stack traces and context
    
    // For now, this is a placeholder
    // print('Unexpected error during redemption for user ${params.userId}: $error');
  }
}

/// Information about a redemption preview
class RedemptionPreview {
  final RedemptionOption option;
  final int pointsToRedeem;
  final int currentBalance;
  final int remainingBalance;
  final bool canAfford;
  final int unitsToRedeem;

  const RedemptionPreview({
    required this.option,
    required this.pointsToRedeem,
    required this.currentBalance,
    required this.remainingBalance,
    required this.canAfford,
    required this.unitsToRedeem,
  });

  /// The cost per unit of this redemption
  int get costPerUnit => option.requiredPoints;

  /// Whether this is a partial redemption (multiple units)
  bool get isPartialRedemption => unitsToRedeem > 1;

  /// The total value being redeemed
  String get redemptionSummary {
    if (unitsToRedeem == 1) {
      return '1x ${option.title}';
    } else {
      return '${unitsToRedeem}x ${option.title}';
    }
  }

  @override
  String toString() {
    return 'RedemptionPreview(option: ${option.title}, pointsToRedeem: $pointsToRedeem, '
           'currentBalance: $currentBalance, canAfford: $canAfford, units: $unitsToRedeem)';
  }
}