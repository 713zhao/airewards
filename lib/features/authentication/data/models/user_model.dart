import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../domain/entities/entities.dart';

/// Data model for User entity with JSON serialization support.
/// 
/// This model extends the domain User entity and provides serialization
/// capabilities for local storage and API communication. It maintains
/// all the properties of the domain entity while adding database and
/// JSON conversion functionality.
class UserModel extends User {
  /// Whether the user account is currently active
  final bool isActive;
  
  /// Total reward points accumulated by the user
  final int totalPoints;
  
  /// Version number for optimistic locking and sync conflict resolution
  final int version;

  const UserModel({
    required super.id,
    required super.email,
    required super.provider,
    required super.createdAt,
    required super.lastLoginAt,
    super.displayName,
    super.photoUrl,
    this.isActive = true,
    this.totalPoints = 0,
    this.version = 1,
  });

  /// Creates a UserModel from a User domain entity
  factory UserModel.fromEntity(User user, {
    bool isActive = true,
    int totalPoints = 0,
    int version = 1,
  }) {
    return UserModel(
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoUrl,
      provider: user.provider,
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt,
      isActive: isActive,
      totalPoints: totalPoints,
      version: version,
    );
  }

  /// Creates a UserModel from JSON data
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      provider: AuthProvider.fromString(json['provider'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
      lastLoginAt: DateTime.fromMillisecondsSinceEpoch(json['last_login_at'] as int),
      isActive: json['is_active'] as bool? ?? true,
      totalPoints: json['total_points'] as int? ?? 0,
      version: json['version'] as int? ?? 1,
    );
  }

  /// Creates a UserModel from Firebase document data
  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      email: data['email'] as String,
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      provider: AuthProvider.fromString(data['provider'] as String),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp).toDate(),
      isActive: data['isActive'] as bool? ?? true,
      totalPoints: data['totalPoints'] as int? ?? 0,
      version: data['version'] as int? ?? 1,
    );
  }

  /// Creates a UserModel from Firebase Auth User
  factory UserModel.fromFirebaseUser(
    firebase_auth.User firebaseUser, {
    AuthProvider? provider,
    bool isActive = true,
    int totalPoints = 0,
    int version = 1,
  }) {
    final now = DateTime.now();
    
    return UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email!,
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      provider: provider ?? AuthProvider.email,
      createdAt: firebaseUser.metadata.creationTime ?? now,
      lastLoginAt: firebaseUser.metadata.lastSignInTime ?? now,
      isActive: isActive,
      totalPoints: totalPoints,
      version: version,
    );
  }

  /// Converts the model to JSON for API requests and local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'provider': provider.value,
      'created_at': createdAt.millisecondsSinceEpoch,
      'last_login_at': lastLoginAt.millisecondsSinceEpoch,
      'is_active': isActive,
      'total_points': totalPoints,
      'version': version,
    };
  }

  /// Converts the model to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'provider': provider.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'isActive': isActive,
      'totalPoints': totalPoints,
      'version': version,
      'updatedAt': Timestamp.now(),
    };
  }

  /// Converts the model to a domain User entity
  User toEntity() {
    return User(
      id: id,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      provider: provider,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
    );
  }

  /// Creates a copy of this model with updated fields
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    AuthProvider? provider,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    int? totalPoints,
    int? version,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      provider: provider ?? this.provider,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      totalPoints: totalPoints ?? this.totalPoints,
      version: version ?? this.version,
    );
  }

  /// Creates a new UserModel with updated last login time
  UserModel updateLastLogin() {
    return copyWith(
      lastLoginAt: DateTime.now(),
      isActive: true,
    );
  }

  /// Creates a new UserModel with updated points total
  UserModel updatePoints(int newPoints) {
    return copyWith(
      totalPoints: newPoints,
      version: version + 1,
    );
  }

  /// Creates a new UserModel with incremented version for sync operations
  UserModel incrementVersion() {
    return copyWith(version: version + 1);
  }

  /// Creates a new UserModel marked as inactive (for soft delete)
  UserModel deactivate() {
    return copyWith(
      isActive: false,
      version: version + 1,
    );
  }

  /// Returns true if this model needs to be synced with remote storage
  bool needsSync(UserModel? remoteModel) {
    if (remoteModel == null) return true;
    return version > remoteModel.version;
  }

  /// Merges this model with a remote model for conflict resolution
  UserModel mergeWithRemote(UserModel remoteModel) {
    // Use the model with higher version number
    if (remoteModel.version > version) {
      return remoteModel;
    } else if (version > remoteModel.version) {
      return this;
    } else {
      // Same version - merge based on most recent updates
      // In a real scenario, you'd have more sophisticated conflict resolution
      return remoteModel.lastLoginAt.isAfter(lastLoginAt) 
          ? remoteModel 
          : this;
    }
  }

  @override
  List<Object?> get props => [
    ...super.props,
    isActive,
    totalPoints,
    version,
  ];

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, displayName: $displayName, '
        'provider: $provider, isActive: $isActive, totalPoints: $totalPoints, '
        'version: $version, createdAt: $createdAt, lastLoginAt: $lastLoginAt)';
  }
}