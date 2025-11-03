import 'package:equatable/equatable.dart';

import 'redemption_status.dart';

/// Domain entity representing a completed or attempted redemption transaction.
/// 
/// This entity tracks the complete lifecycle of a redemption from request
/// to completion, including points used, status changes, and audit information.
class RedemptionTransaction extends Equatable {
  /// Unique identifier for the transaction
  final String id;
  
  /// ID of the user who made the redemption
  final String userId;
  
  /// ID of the redemption option that was redeemed
  final String optionId;
  
  /// Number of points deducted for this redemption
  final int pointsUsed;
  
  /// Timestamp when the redemption was requested
  final DateTime redeemedAt;
  
  /// Current status of the redemption
  final RedemptionStatus status;
  
  /// Optional notes about the redemption (reason for cancellation, etc.)
  final String? notes;
  
  /// Timestamp when the transaction was created
  final DateTime createdAt;
  
  /// Timestamp when the transaction was last updated
  final DateTime? updatedAt;
  
  /// Optional timestamp when the transaction was completed
  final DateTime? completedAt;
  
  /// Optional timestamp when the transaction was cancelled
  final DateTime? cancelledAt;

  const RedemptionTransaction({
    required this.id,
    required this.userId,
    required this.optionId,
    required this.pointsUsed,
    required this.redeemedAt,
    required this.status,
    required this.createdAt,
    this.notes,
    this.updatedAt,
    this.completedAt,
    this.cancelledAt,
  });

  /// Factory constructor to create a new redemption transaction
  factory RedemptionTransaction.create({
    required String userId,
    required String optionId,
    required int pointsUsed,
    String? notes,
  }) {
    _validatePointsUsed(pointsUsed);
    _validateUserId(userId);
    _validateOptionId(optionId);

    final now = DateTime.now();
    
    return RedemptionTransaction(
      id: '${now.millisecondsSinceEpoch}_${userId.hashCode}',
      userId: userId,
      optionId: optionId,
      pointsUsed: pointsUsed,
      redeemedAt: now,
      status: RedemptionStatus.pending,
      notes: notes?.trim(),
      createdAt: now,
    );
  }

  /// Creates a copy of this transaction with updated fields
  RedemptionTransaction copyWith({
    String? id,
    String? userId,
    String? optionId,
    int? pointsUsed,
    DateTime? redeemedAt,
    RedemptionStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
  }) {
    final newPointsUsed = pointsUsed ?? this.pointsUsed;
    final newStatus = status ?? this.status;
    final newUserId = userId ?? this.userId;
    final newOptionId = optionId ?? this.optionId;

    if (pointsUsed != null) _validatePointsUsed(newPointsUsed);
    if (userId != null) _validateUserId(newUserId);
    if (optionId != null) _validateOptionId(newOptionId);

    // Business Rule BR-009: Redemptions are final and cannot be reversed
    if (this.status.isFinal && newStatus != this.status) {
      throw StateError(
        'Cannot change status of finalized redemption (BR-009). '
        'Current status: ${this.status}, attempted: $newStatus',
      );
    }

    return RedemptionTransaction(
      id: id ?? this.id,
      userId: newUserId,
      optionId: newOptionId,
      pointsUsed: newPointsUsed,
      redeemedAt: redeemedAt ?? this.redeemedAt,
      status: newStatus,
      notes: notes?.trim() ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }

  /// Marks the transaction as completed
  RedemptionTransaction complete({String? notes}) {
    if (status != RedemptionStatus.pending) {
      throw StateError('Can only complete pending redemptions. Current status: $status');
    }

    return copyWith(
      status: RedemptionStatus.completed,
      completedAt: DateTime.now(),
      notes: notes,
    );
  }

  /// Cancels the transaction with optional reason
  RedemptionTransaction cancel({String? reason}) {
    if (!status.canBeCancelled) {
      throw StateError('Cannot cancel redemption with status: $status');
    }

    return copyWith(
      status: RedemptionStatus.cancelled,
      cancelledAt: DateTime.now(),
      notes: reason,
    );
  }

  /// Marks the transaction as expired
  RedemptionTransaction expire({String? notes}) {
    if (status != RedemptionStatus.pending) {
      throw StateError('Can only expire pending redemptions. Current status: $status');
    }

    return copyWith(
      status: RedemptionStatus.expired,
      notes: notes,
    );
  }

  /// Returns true if this transaction is in a final state
  bool get isFinal => status.isFinal;

  /// Returns true if this transaction can be cancelled
  bool get canBeCancelled => status.canBeCancelled;

  /// Returns true if this transaction is still pending
  bool get isPending => status == RedemptionStatus.pending;

  /// Returns true if this transaction was successful
  bool get isSuccessful => status == RedemptionStatus.completed;

  /// Returns the duration since the transaction was created
  Duration get age => DateTime.now().difference(createdAt);

  /// Validates that points used meets business rules
  /// 
  /// Business Rule BR-008: Minimum redemption value: 100 points
  static void _validatePointsUsed(int points) {
    if (points < 100) {
      throw ArgumentError(
        'Points used must be at least 100 (BR-008). Got: $points',
      );
    }
    if (points > 1000000) {
      throw ArgumentError(
        'Points used cannot exceed 1,000,000. Got: $points',
      );
    }
  }

  /// Validates user ID is not empty
  static void _validateUserId(String userId) {
    if (userId.trim().isEmpty) {
      throw ArgumentError('User ID cannot be empty');
    }
  }

  /// Validates option ID is not empty
  static void _validateOptionId(String optionId) {
    if (optionId.trim().isEmpty) {
      throw ArgumentError('Option ID cannot be empty');
    }
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    optionId,
    pointsUsed,
    redeemedAt,
    status,
    notes,
    createdAt,
    updatedAt,
    completedAt,
    cancelledAt,
  ];

  @override
  String toString() {
    return 'RedemptionTransaction{id: $id, userId: $userId, pointsUsed: $pointsUsed, status: $status}';
  }
}