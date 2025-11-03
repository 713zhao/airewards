import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'family_model.g.dart';

/// Family model representing a family unit in the AI Rewards system
@JsonSerializable()
class FamilyModel {
  final String id;
  final String name;
  final String? description;
  final String adminUserId;
  final List<String> memberIds;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;
  final Map<String, dynamic> settings;
  final FamilySubscription subscription;
  final bool isActive;
  final String? inviteCode;
  final DateTime? inviteCodeExpiry;

  const FamilyModel({
    required this.id,
    required this.name,
    this.description,
    required this.adminUserId,
    this.memberIds = const [],
    required this.createdAt,
    required this.lastUpdatedAt,
    this.settings = const {},
    this.subscription = FamilySubscription.free,
    this.isActive = true,
    this.inviteCode,
    this.inviteCodeExpiry,
  });

  /// Create a new family
  factory FamilyModel.create({
    required String id,
    required String name,
    String? description,
    required String adminUserId,
    FamilySubscription subscription = FamilySubscription.free,
  }) {
    final now = DateTime.now();
    return FamilyModel(
      id: id,
      name: name,
      description: description,
      adminUserId: adminUserId,
      memberIds: [adminUserId], // Admin is automatically a member
      createdAt: now,
      lastUpdatedAt: now,
      subscription: subscription,
    );
  }

  /// Create from JSON
  factory FamilyModel.fromJson(Map<String, dynamic> json) => _$FamilyModelFromJson(json);

  /// Create from Firestore document
  factory FamilyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyModel.fromJson({
      ...data,
      'id': doc.id,
      'createdAt': (data['createdAt'] as Timestamp).toDate().toIso8601String(),
      'lastUpdatedAt': (data['lastUpdatedAt'] as Timestamp).toDate().toIso8601String(),
      'inviteCodeExpiry': data['inviteCodeExpiry'] != null 
          ? (data['inviteCodeExpiry'] as Timestamp).toDate().toIso8601String() 
          : null,
    });
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$FamilyModelToJson(this);

  /// Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Firestore document ID is separate
    json['createdAt'] = Timestamp.fromDate(createdAt);
    json['lastUpdatedAt'] = Timestamp.fromDate(lastUpdatedAt);
    json['inviteCodeExpiry'] = inviteCodeExpiry != null 
        ? Timestamp.fromDate(inviteCodeExpiry!) 
        : null;
    return json;
  }

  /// Create a copy with updated values
  FamilyModel copyWith({
    String? id,
    String? name,
    String? description,
    String? adminUserId,
    List<String>? memberIds,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    Map<String, dynamic>? settings,
    FamilySubscription? subscription,
    bool? isActive,
    String? inviteCode,
    DateTime? inviteCodeExpiry,
  }) {
    return FamilyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      adminUserId: adminUserId ?? this.adminUserId,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? DateTime.now(),
      settings: settings ?? this.settings,
      subscription: subscription ?? this.subscription,
      isActive: isActive ?? this.isActive,
      inviteCode: inviteCode ?? this.inviteCode,
      inviteCodeExpiry: inviteCodeExpiry ?? this.inviteCodeExpiry,
    );
  }

  /// Add a member to the family
  FamilyModel addMember(String userId) {
    if (memberIds.contains(userId)) return this;
    return copyWith(
      memberIds: [...memberIds, userId],
    );
  }

  /// Remove a member from the family
  FamilyModel removeMember(String userId) {
    if (!memberIds.contains(userId)) return this;
    if (userId == adminUserId) {
      throw Exception('Cannot remove family admin');
    }
    return copyWith(
      memberIds: memberIds.where((id) => id != userId).toList(),
    );
  }

  /// Generate a new invite code
  FamilyModel generateInviteCode() {
    final code = _generateRandomCode();
    final expiry = DateTime.now().add(const Duration(days: 7));
    return copyWith(
      inviteCode: code,
      inviteCodeExpiry: expiry,
    );
  }

  /// Clear the invite code
  FamilyModel clearInviteCode() {
    return copyWith(
      inviteCode: null,
      inviteCodeExpiry: null,
    );
  }

  /// Update family settings
  FamilyModel updateSettings(Map<String, dynamic> newSettings) {
    return copyWith(
      settings: {...settings, ...newSettings},
    );
  }

  /// Check if user is admin
  bool isAdmin(String userId) => userId == adminUserId;

  /// Check if user is member
  bool isMember(String userId) => memberIds.contains(userId);

  /// Check if invite code is valid
  bool get isInviteCodeValid {
    if (inviteCode == null || inviteCodeExpiry == null) return false;
    return DateTime.now().isBefore(inviteCodeExpiry!);
  }

  /// Get member count
  int get memberCount => memberIds.length;

  /// Get max members allowed for subscription
  int get maxMembersAllowed {
    switch (subscription) {
      case FamilySubscription.free:
        return 5;
      case FamilySubscription.premium:
        return 15;
      case FamilySubscription.enterprise:
        return 50;
    }
  }

  /// Check if can add more members
  bool get canAddMoreMembers => memberCount < maxMembersAllowed;

  /// Generate random invite code
  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(8, (index) => chars[(DateTime.now().millisecondsSinceEpoch + index) % chars.length]).join();
  }

  @override
  String toString() => 'FamilyModel(id: $id, name: $name, members: ${memberIds.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FamilyModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Family subscription type enumeration
@JsonEnum()
enum FamilySubscription {
  @JsonValue('free')
  free,
  
  @JsonValue('premium')
  premium,
  
  @JsonValue('enterprise')
  enterprise;

  String get displayName {
    switch (this) {
      case FamilySubscription.free:
        return 'Free';
      case FamilySubscription.premium:
        return 'Premium';
      case FamilySubscription.enterprise:
        return 'Enterprise';
    }
  }

  String get description {
    switch (this) {
      case FamilySubscription.free:
        return 'Up to 5 family members';
      case FamilySubscription.premium:
        return 'Up to 15 family members with advanced features';
      case FamilySubscription.enterprise:
        return 'Up to 50 members with full customization';
    }
  }
}