import 'package:cloud_firestore/cloud_firestore.dart';

/// User model representing a family member in the AI Rewards system
class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final UserRole role;
  final String? familyId;
  final int currentPoints;
  final int totalPointsEarned;
  final int totalPointsSpent;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final Map<String, dynamic> preferences;
  final List<String> achievements;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.role,
    this.familyId,
    this.currentPoints = 0,
    this.totalPointsEarned = 0,
    this.totalPointsSpent = 0,
    required this.createdAt,
    required this.lastLoginAt,
    this.preferences = const {},
    this.achievements = const [],
    this.isActive = true,
  });

  /// Create a new user with default values
  factory UserModel.create({
    required String id,
    required String email,
    required String displayName,
    String? photoUrl,
    UserRole role = UserRole.child,
    String? familyId,
  }) {
    final now = DateTime.now();
    return UserModel(
      id: id,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      role: role,
      familyId: familyId,
      createdAt: now,
      lastLoginAt: now,
    );
  }

  /// Create from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      photoUrl: json['photoUrl'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${json['role']}',
        orElse: () => UserRole.child,
      ),
      familyId: json['familyId'] as String?,
      currentPoints: json['currentPoints'] as int? ?? 0,
      totalPointsEarned: json['totalPointsEarned'] as int? ?? 0,
      totalPointsSpent: json['totalPointsSpent'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: DateTime.parse(json['lastLoginAt'] as String),
      preferences: Map<String, dynamic>.from(json['preferences'] as Map? ?? {}),
      achievements: List<String>.from(json['achievements'] as List? ?? []),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromJson({
      ...data,
      'id': doc.id,
      'createdAt': (data['createdAt'] as Timestamp).toDate().toIso8601String(),
      'lastLoginAt': (data['lastLoginAt'] as Timestamp).toDate().toIso8601String(),
    });
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role.toString().split('.').last,
      'familyId': familyId,
      'currentPoints': currentPoints,
      'totalPointsEarned': totalPointsEarned,
      'totalPointsSpent': totalPointsSpent,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'preferences': preferences,
      'achievements': achievements,
      'isActive': isActive,
    };
  }

  /// Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Firestore document ID is separate
    json['createdAt'] = Timestamp.fromDate(createdAt);
    json['lastLoginAt'] = Timestamp.fromDate(lastLoginAt);
    return json;
  }

  /// Create a copy with updated values
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    UserRole? role,
    String? familyId,
    int? currentPoints,
    int? totalPointsEarned,
    int? totalPointsSpent,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? preferences,
    List<String>? achievements,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      familyId: familyId ?? this.familyId,
      currentPoints: currentPoints ?? this.currentPoints,
      totalPointsEarned: totalPointsEarned ?? this.totalPointsEarned,
      totalPointsSpent: totalPointsSpent ?? this.totalPointsSpent,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
      achievements: achievements ?? this.achievements,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Add points to user account
  UserModel addPoints(int points) {
    return copyWith(
      currentPoints: currentPoints + points,
      totalPointsEarned: totalPointsEarned + points,
    );
  }

  /// Spend points from user account
  UserModel spendPoints(int points) {
    if (currentPoints < points) {
      throw Exception('Insufficient points');
    }
    return copyWith(
      currentPoints: currentPoints - points,
      totalPointsSpent: totalPointsSpent + points,
    );
  }

  /// Add achievement
  UserModel addAchievement(String achievement) {
    if (achievements.contains(achievement)) return this;
    return copyWith(
      achievements: [...achievements, achievement],
    );
  }

  /// Check if user is a parent
  bool get isParent => role == UserRole.parent;

  /// Check if user is a child
  bool get isChild => role == UserRole.child;

  /// Check if user has sufficient points
  bool hasPoints(int requiredPoints) => currentPoints >= requiredPoints;

  @override
  String toString() => 'UserModel(id: $id, displayName: $displayName, role: $role, points: $currentPoints)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// User role enumeration
enum UserRole {
  parent,
  child,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.parent:
        return 'Parent';
      case UserRole.child:
        return 'Child';
      case UserRole.admin:
        return 'Admin';
    }
  }

  bool get canManageFamily => this == UserRole.parent || this == UserRole.admin;
  bool get canCreateTasks => this == UserRole.parent || this == UserRole.admin;
  bool get canApproveRewards => this == UserRole.parent || this == UserRole.admin;
}