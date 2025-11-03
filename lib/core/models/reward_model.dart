import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'reward_model.g.dart';

/// Reward model representing a reward in the AI Rewards system
@JsonSerializable()
class RewardModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final int pointCost;
  final RewardType type;
  final String? imageUrl;
  final String familyId;
  final String createdByUserId;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isActive;
  final bool isUnlimited;
  final int? maxRedemptions;
  final int currentRedemptions;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final RewardAvailability availability;
  final List<String> eligibleUserIds;

  const RewardModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.pointCost,
    required this.type,
    this.imageUrl,
    required this.familyId,
    required this.createdByUserId,
    required this.createdAt,
    this.expiresAt,
    this.isActive = true,
    this.isUnlimited = true,
    this.maxRedemptions,
    this.currentRedemptions = 0,
    this.tags = const [],
    this.metadata = const {},
    this.availability = RewardAvailability.always,
    this.eligibleUserIds = const [],
  });

  /// Create a new reward
  factory RewardModel.create({
    required String id,
    required String title,
    required String description,
    required String category,
    required int pointCost,
    required RewardType type,
    String? imageUrl,
    required String familyId,
    required String createdByUserId,
    DateTime? expiresAt,
    bool isUnlimited = true,
    int? maxRedemptions,
    List<String> tags = const [],
    RewardAvailability availability = RewardAvailability.always,
    List<String> eligibleUserIds = const [],
  }) {
    return RewardModel(
      id: id,
      title: title,
      description: description,
      category: category,
      pointCost: pointCost,
      type: type,
      imageUrl: imageUrl,
      familyId: familyId,
      createdByUserId: createdByUserId,
      createdAt: DateTime.now(),
      expiresAt: expiresAt,
      isUnlimited: isUnlimited,
      maxRedemptions: maxRedemptions,
      tags: tags,
      availability: availability,
      eligibleUserIds: eligibleUserIds,
    );
  }

  /// Create from JSON
  factory RewardModel.fromJson(Map<String, dynamic> json) => _$RewardModelFromJson(json);

  /// Create from Firestore document
  factory RewardModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RewardModel.fromJson({
      ...data,
      'id': doc.id,
      'createdAt': (data['createdAt'] as Timestamp).toDate().toIso8601String(),
      'expiresAt': data['expiresAt'] != null ? (data['expiresAt'] as Timestamp).toDate().toIso8601String() : null,
    });
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$RewardModelToJson(this);

  /// Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Firestore document ID is separate
    json['createdAt'] = Timestamp.fromDate(createdAt);
    json['expiresAt'] = expiresAt != null ? Timestamp.fromDate(expiresAt!) : null;
    return json;
  }

  /// Create a copy with updated values
  RewardModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    int? pointCost,
    RewardType? type,
    String? imageUrl,
    String? familyId,
    String? createdByUserId,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isActive,
    bool? isUnlimited,
    int? maxRedemptions,
    int? currentRedemptions,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    RewardAvailability? availability,
    List<String>? eligibleUserIds,
  }) {
    return RewardModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      pointCost: pointCost ?? this.pointCost,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      familyId: familyId ?? this.familyId,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      isUnlimited: isUnlimited ?? this.isUnlimited,
      maxRedemptions: maxRedemptions ?? this.maxRedemptions,
      currentRedemptions: currentRedemptions ?? this.currentRedemptions,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      availability: availability ?? this.availability,
      eligibleUserIds: eligibleUserIds ?? this.eligibleUserIds,
    );
  }

  /// Record a redemption
  RewardModel recordRedemption() {
    return copyWith(
      currentRedemptions: currentRedemptions + 1,
    );
  }

  /// Check if reward is available for redemption
  bool isAvailableForUser(String userId, int userPoints) {
    // Check if user has enough points
    if (userPoints < pointCost) return false;
    
    // Check if reward is active
    if (!isActive) return false;
    
    // Check if reward has expired
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return false;
    
    // Check if reward has reached max redemptions
    if (!isUnlimited && maxRedemptions != null && currentRedemptions >= maxRedemptions!) return false;
    
    // Check if user is eligible
    if (eligibleUserIds.isNotEmpty && !eligibleUserIds.contains(userId)) return false;
    
    // Check availability schedule
    if (!_isCurrentlyAvailable()) return false;
    
    return true;
  }

  /// Check if reward is currently available based on schedule
  bool _isCurrentlyAvailable() {
    switch (availability) {
      case RewardAvailability.always:
        return true;
      case RewardAvailability.weekends:
        final now = DateTime.now();
        return now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
      case RewardAvailability.weekdays:
        final now = DateTime.now();
        return now.weekday >= DateTime.monday && now.weekday <= DateTime.friday;
      case RewardAvailability.custom:
        // Custom availability would be handled via metadata
        return metadata['isCurrentlyAvailable'] == true;
    }
  }

  /// Check if reward is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if reward is sold out
  bool get isSoldOut {
    if (isUnlimited) return false;
    if (maxRedemptions == null) return false;
    return currentRedemptions >= maxRedemptions!;
  }

  /// Get remaining redemptions
  int? get remainingRedemptions {
    if (isUnlimited || maxRedemptions == null) return null;
    return maxRedemptions! - currentRedemptions;
  }

  @override
  String toString() => 'RewardModel(id: $id, title: $title, cost: $pointCost, type: $type)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RewardModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Reward type enumeration
@JsonEnum()
enum RewardType {
  @JsonValue('physical')
  physical,
  
  @JsonValue('digital')
  digital,
  
  @JsonValue('experience')
  experience,
  
  @JsonValue('privilege')
  privilege,
  
  @JsonValue('money')
  money;

  String get displayName {
    switch (this) {
      case RewardType.physical:
        return 'Physical Item';
      case RewardType.digital:
        return 'Digital Item';
      case RewardType.experience:
        return 'Experience';
      case RewardType.privilege:
        return 'Privilege';
      case RewardType.money:
        return 'Money';
    }
  }
}

/// Reward availability enumeration
@JsonEnum()
enum RewardAvailability {
  @JsonValue('always')
  always,
  
  @JsonValue('weekends')
  weekends,
  
  @JsonValue('weekdays')
  weekdays,
  
  @JsonValue('custom')
  custom;

  String get displayName {
    switch (this) {
      case RewardAvailability.always:
        return 'Always Available';
      case RewardAvailability.weekends:
        return 'Weekends Only';
      case RewardAvailability.weekdays:
        return 'Weekdays Only';
      case RewardAvailability.custom:
        return 'Custom Schedule';
    }
  }
}