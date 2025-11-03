/// Enum defining the different types of reward entries
/// Used to categorize how points were acquired or modified
enum RewardType {
  /// Points earned through normal activities
  earned('EARNED'),
  
  /// Points manually adjusted by admin or system
  adjusted('ADJUSTED'),
  
  /// Bonus points from special events or promotions
  bonus('BONUS');

  const RewardType(this.value);

  /// String value for serialization
  final String value;

  /// Create RewardType from string value
  static RewardType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'EARNED':
        return RewardType.earned;
      case 'ADJUSTED':
        return RewardType.adjusted;
      case 'BONUS':
        return RewardType.bonus;
      default:
        throw ArgumentError('Invalid RewardType value: $value');
    }
  }

  @override
  String toString() => value;
}