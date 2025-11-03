import 'package:equatable/equatable.dart';
import 'auth_provider.dart';

/// Domain entity representing a user in the AI Rewards System.
/// 
/// This entity follows clean architecture principles and is immutable.
/// All properties are final and the class implements proper equality
/// comparison for testing and state management purposes.
class User extends Equatable {
  /// Unique identifier for the user
  final String id;
  
  /// User's email address - required field
  final String email;
  
  /// User's display name - optional, may be null for email-only accounts
  final String? displayName;
  
  /// URL to user's profile photo - optional
  final String? photoUrl;
  
  /// Authentication provider used for this user account
  final AuthProvider provider;
  
  /// Timestamp when the user account was created
  final DateTime createdAt;
  
  /// Timestamp of the user's last login
  final DateTime lastLoginAt;

  const User({
    required this.id,
    required this.email,
    required this.provider,
    required this.createdAt,
    required this.lastLoginAt,
    this.displayName,
    this.photoUrl,
  });

  /// Creates a copy of this user with updated fields
  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    AuthProvider? provider,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      provider: provider ?? this.provider,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  /// Creates a new User instance with updated last login time
  User updateLastLogin() {
    return copyWith(lastLoginAt: DateTime.now());
  }

  /// Returns true if the user has a complete profile
  bool get hasCompleteProfile {
    return displayName != null && displayName!.isNotEmpty;
  }

  /// Returns the user's display name or email if display name is not available
  String get displayNameOrEmail {
    return displayName?.isNotEmpty == true ? displayName! : email;
  }

  /// Returns true if the user has a profile photo
  bool get hasProfilePhoto {
    return photoUrl != null && photoUrl!.isNotEmpty;
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        photoUrl,
        provider,
        createdAt,
        lastLoginAt,
      ];

  @override
  bool get stringify => true;

  @override
  String toString() {
    return 'User(id: $id, email: $email, displayName: $displayName, '
        'provider: $provider, createdAt: $createdAt, lastLoginAt: $lastLoginAt)';
  }
}