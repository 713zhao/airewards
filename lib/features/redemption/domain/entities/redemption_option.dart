import 'package:equatable/equatable.dart';

/// Domain entity representing a redemption option available to users.
/// 
/// This entity defines what users can redeem their points for, including
/// the required points, category, availability, and expiration information.
class RedemptionOption extends Equatable {
  /// Unique identifier for the redemption option
  final String id;
  
  /// Display title of the redemption option
  final String title;
  
  /// Detailed description of what the user gets
  final String description;
  
  /// Number of points required for this redemption
  final int requiredPoints;
  
  /// Category ID this redemption option belongs to
  final String categoryId;
  
  /// Whether this option is currently available for redemption
  final bool isActive;
  
  /// Optional expiry date after which this option is no longer available
  final DateTime? expiryDate;
  
  /// Optional image URL for visual representation
  final String? imageUrl;
  
  /// Timestamp when this option was created
  final DateTime createdAt;
  
  /// Timestamp when this option was last updated
  final DateTime? updatedAt;

  const RedemptionOption({
    required this.id,
    required this.title,
    required this.description,
    required this.requiredPoints,
    required this.categoryId,
    required this.isActive,
    required this.createdAt,
    this.expiryDate,
    this.imageUrl,
    this.updatedAt,
  });

  /// Factory constructor to create a new redemption option with generated ID
  factory RedemptionOption.create({
    required String title,
    required String description,
    required int requiredPoints,
    required String categoryId,
    bool isActive = true,
    DateTime? expiryDate,
    String? imageUrl,
  }) {
    _validateRequiredPoints(requiredPoints);
    _validateTitle(title);
    _validateDescription(description);
    _validateExpiryDate(expiryDate);

    return RedemptionOption(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      description: description.trim(),
      requiredPoints: requiredPoints,
      categoryId: categoryId,
      isActive: isActive,
      expiryDate: expiryDate,
      imageUrl: imageUrl?.trim(),
      createdAt: DateTime.now(),
    );
  }

  /// Creates a copy of this redemption option with updated fields
  RedemptionOption copyWith({
    String? id,
    String? title,
    String? description,
    int? requiredPoints,
    String? categoryId,
    bool? isActive,
    DateTime? expiryDate,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final newTitle = title ?? this.title;
    final newDescription = description ?? this.description;
    final newRequiredPoints = requiredPoints ?? this.requiredPoints;
    final newExpiryDate = expiryDate ?? this.expiryDate;

    if (title != null) _validateTitle(newTitle);
    if (description != null) _validateDescription(newDescription);
    if (requiredPoints != null) _validateRequiredPoints(newRequiredPoints);
    if (expiryDate != null) _validateExpiryDate(newExpiryDate);

    return RedemptionOption(
      id: id ?? this.id,
      title: newTitle.trim(),
      description: newDescription.trim(),
      requiredPoints: newRequiredPoints,
      categoryId: categoryId ?? this.categoryId,
      isActive: isActive ?? this.isActive,
      expiryDate: newExpiryDate,
      imageUrl: imageUrl?.trim() ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Returns true if this redemption option is currently available
  /// 
  /// Checks both the isActive flag and expiry date
  bool get isAvailable {
    if (!isActive) return false;
    if (expiryDate == null) return true;
    return DateTime.now().isBefore(expiryDate!);
  }

  /// Returns true if this redemption option has expired
  bool get isExpired {
    return expiryDate != null && DateTime.now().isAfter(expiryDate!);
  }

  /// Returns true if a user can redeem this option with their available points
  bool canRedeemWith(int availablePoints) {
    return isAvailable && availablePoints >= requiredPoints;
  }

  /// Validates that required points meets business rules
  /// 
  /// Business Rule BR-008: Minimum redemption value: 100 points
  static void _validateRequiredPoints(int points) {
    if (points < 100) {
      throw ArgumentError(
        'Required points must be at least 100 (BR-008). Got: $points',
      );
    }
    if (points > 1000000) {
      throw ArgumentError(
        'Required points cannot exceed 1,000,000. Got: $points',
      );
    }
  }

  /// Validates title is not empty and within length limits
  static void _validateTitle(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Title cannot be empty');
    }
    if (trimmed.length > 100) {
      throw ArgumentError(
        'Title cannot be longer than 100 characters. Got: ${trimmed.length}',
      );
    }
  }

  /// Validates description is not empty and within length limits
  static void _validateDescription(String description) {
    final trimmed = description.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Description cannot be empty');
    }
    if (trimmed.length > 500) {
      throw ArgumentError(
        'Description cannot be longer than 500 characters. Got: ${trimmed.length}',
      );
    }
  }

  /// Validates expiry date is in the future if provided
  static void _validateExpiryDate(DateTime? expiryDate) {
    if (expiryDate != null && expiryDate.isBefore(DateTime.now())) {
      throw ArgumentError('Expiry date cannot be in the past');
    }
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    requiredPoints,
    categoryId,
    isActive,
    expiryDate,
    imageUrl,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() {
    return 'RedemptionOption{id: $id, title: $title, requiredPoints: $requiredPoints, isAvailable: $isAvailable}';
  }
}