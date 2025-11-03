/// Enumeration defining the possible states of a redemption transaction.
/// 
/// This enum represents the lifecycle of a redemption from initial request
/// through completion or failure states.
enum RedemptionStatus {
  /// Redemption request has been submitted but not yet processed
  pending('pending'),
  
  /// Redemption has been successfully completed
  completed('completed'),
  
  /// Redemption was cancelled by user or system
  cancelled('cancelled'),
  
  /// Redemption expired before completion
  expired('expired');

  const RedemptionStatus(this.value);

  /// String representation of the status for serialization
  final String value;

  /// Creates a [RedemptionStatus] from a string value
  /// 
  /// Throws [ArgumentError] if the value doesn't match any enum value
  static RedemptionStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return RedemptionStatus.pending;
      case 'completed':
        return RedemptionStatus.completed;
      case 'cancelled':
        return RedemptionStatus.cancelled;
      case 'expired':
        return RedemptionStatus.expired;
      default:
        throw ArgumentError('Unknown redemption status: $value');
    }
  }

  /// Returns true if the redemption is in a final state (cannot be modified)
  bool get isFinal => this == completed || this == cancelled || this == expired;

  /// Returns true if the redemption can be cancelled
  bool get canBeCancelled => this == pending;

  /// Returns true if the redemption is still active (can potentially complete)
  bool get isActive => this == pending;

  @override
  String toString() => value;
}