import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import 'reward_type.dart';

/// Represents a single reward point entry in the system
/// Each entry tracks points earned, adjusted, or bonus points with full audit trail
@immutable
class RewardEntry extends Equatable {
  /// Unique identifier for the reward entry
  final String id;
  
  /// User ID who owns this reward entry
  final String userId;
  
  /// Number of points for this entry (must be positive for earned/bonus, can be negative for adjusted)
  final int points;
  
  /// Description of how the points were earned or reason for adjustment
  final String description;
  
  /// Category ID this entry belongs to
  final String categoryId;
  
  /// When this entry was created
  final DateTime createdAt;
  
  /// When this entry was last updated (null if never updated)
  final DateTime? updatedAt;
  
  /// Whether this entry has been synced with the server
  final bool isSynced;
  
  /// Type of reward entry (earned, adjusted, bonus)
  final RewardType type;

  const RewardEntry({
    required this.id,
    required this.userId,
    required this.points,
    required this.description,
    required this.categoryId,
    required this.createdAt,
    this.updatedAt,
    this.isSynced = false,
    required this.type,
  });

  /// Creates a RewardEntry with validation according to business rules
  static Either<ValidationFailure, RewardEntry> create({
    required String id,
    required String userId,
    required int points,
    required String description,
    required String categoryId,
    required DateTime createdAt,
    DateTime? updatedAt,
    bool isSynced = false,
    required RewardType type,
  }) {
    // Validate ID
    if (id.isEmpty) {
      return Left(ValidationFailure('Reward entry ID cannot be empty'));
    }

    // Validate user ID
    if (userId.isEmpty) {
      return Left(ValidationFailure('User ID cannot be empty'));
    }

    // Validate points according to business rules
    final pointsValidation = _validatePoints(points, type);
    if (pointsValidation.isLeft) {
      return Left(pointsValidation.left);
    }

    // Validate description (mandatory field per BR-011)
    final descriptionValidation = _validateDescription(description);
    if (descriptionValidation.isLeft) {
      return Left(descriptionValidation.left);
    }

    // Validate category ID (mandatory field per BR-011)
    if (categoryId.isEmpty) {
      return Left(ValidationFailure('Category ID cannot be empty (BR-011: Each reward entry must have a category)'));
    }

    // Validate timestamps
    if (updatedAt != null && updatedAt.isBefore(createdAt)) {
      return Left(ValidationFailure('Updated date cannot be before created date'));
    }

    return Right(RewardEntry(
      id: id,
      userId: userId,
      points: points,
      description: description.trim(),
      categoryId: categoryId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isSynced: isSynced,
      type: type,
    ));
  }

  /// Validates points according to business rules BR-001, BR-002, BR-003
  static Either<ValidationFailure, int> _validatePoints(int points, RewardType type) {
    // BR-003: Points cannot be negative (except for ADJUSTED type)
    if (points < 0 && type != RewardType.adjusted) {
      return Left(ValidationFailure('Points cannot be negative except for adjusted entries (BR-003)'));
    }

    // BR-001: Minimum point entry value: 1 point (for positive entries)
    if (points > 0 && points < 1) {
      return Left(ValidationFailure('Minimum point entry value is 1 point (BR-001)'));
    }

    // BR-002: Maximum point entry value: 10,000 points per transaction
    if (points.abs() > 10000) {
      return Left(ValidationFailure('Maximum point entry value is 10,000 points per transaction (BR-002)'));
    }

    return Right(points);
  }

  /// Validates description field
  static Either<ValidationFailure, String> _validateDescription(String description) {
    if (description.isEmpty) {
      return Left(ValidationFailure('Description cannot be empty (mandatory field per requirements)'));
    }
    
    if (description.trim().isEmpty) {
      return Left(ValidationFailure('Description cannot be only whitespace'));
    }
    
    if (description.length > 500) {
      return Left(ValidationFailure('Description cannot exceed 500 characters'));
    }
    
    return Right(description.trim());
  }

  /// Checks if this entry can be modified (BR-004: within 24 hours)
  bool canBeModified() {
    final now = DateTime.now();
    final timeDifference = now.difference(createdAt);
    return timeDifference.inHours < 24;
  }

  /// Checks if this entry is recent (created within last hour)
  bool isRecent() {
    final now = DateTime.now();
    final timeDifference = now.difference(createdAt);
    return timeDifference.inHours < 1;
  }

  /// Creates a copy of this entry with updated values
  /// Automatically sets updatedAt to current time if any value changes
  RewardEntry copyWith({
    String? id,
    String? userId,
    int? points,
    String? description,
    String? categoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    RewardType? type,
  }) {
    // Check if any meaningful properties changed (excluding updatedAt and isSynced)
    final hasChanges = (id != null && id != this.id) ||
        (userId != null && userId != this.userId) ||
        (points != null && points != this.points) ||
        (description != null && description != this.description) ||
        (categoryId != null && categoryId != this.categoryId) ||
        (createdAt != null && createdAt != this.createdAt) ||
        (type != null && type != this.type);

    return RewardEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      points: points ?? this.points,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: hasChanges ? (updatedAt ?? DateTime.now()) : (updatedAt ?? this.updatedAt),
      isSynced: hasChanges ? false : (isSynced ?? this.isSynced),
      type: type ?? this.type,
    );
  }

  /// Converts entry to JSON map for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'points': points,
      'description': description,
      'categoryId': categoryId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'isSynced': isSynced,
      'type': type.value,
    };
  }

  /// Creates entry from JSON map
  static RewardEntry fromJson(Map<String, dynamic> json) {
    return RewardEntry(
      id: json['id'] as String,
      userId: json['userId'] as String,
      points: json['points'] as int,
      description: json['description'] as String,
      categoryId: json['categoryId'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int)
          : null,
      isSynced: json['isSynced'] as bool? ?? false,
      type: RewardType.fromString(json['type'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        points,
        description,
        categoryId,
        createdAt,
        updatedAt,
        isSynced,
        type,
      ];

  @override
  String toString() {
    return 'RewardEntry(id: $id, userId: $userId, points: $points, '
           'description: $description, categoryId: $categoryId, '
           'createdAt: $createdAt, updatedAt: $updatedAt, '
           'isSynced: $isSynced, type: $type)';
  }
}