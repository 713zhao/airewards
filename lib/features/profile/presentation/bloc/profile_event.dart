import 'package:equatable/equatable.dart';
import '../../../profile/data/services/profile_mock_data_service.dart';

/// Base class for all profile events
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Load user profile
class LoadUserProfile extends ProfileEvent {
  final String userId;

  const LoadUserProfile(this.userId);

  @override
  List<Object> get props => [userId];
}

/// Update profile information
class UpdateProfile extends ProfileEvent {
  final String userId;
  final String? displayName;
  final String? email;
  final Map<String, dynamic>? customizations;

  const UpdateProfile({
    required this.userId,
    this.displayName,
    this.email,
    this.customizations,
  });

  @override
  List<Object?> get props => [userId, displayName, email, customizations];
}

/// Upload custom avatar
class UploadCustomAvatar extends ProfileEvent {
  final String userId;
  final String avatarPath;

  const UploadCustomAvatar({
    required this.userId,
    required this.avatarPath,
  });

  @override
  List<Object> get props => [userId, avatarPath];
}

/// Update avatar with predefined avatar
class UpdateAvatar extends ProfileEvent {
  final String userId;
  final String avatarId;

  const UpdateAvatar({
    required this.userId,
    required this.avatarId,
  });

  @override
  List<Object> get props => [userId, avatarId];
}

/// Update theme
class UpdateTheme extends ProfileEvent {
  final String userId;
  final String themeId;

  const UpdateTheme({
    required this.userId,
    required this.themeId,
  });

  @override
  List<Object> get props => [userId, themeId];
}

/// Update privacy settings
class UpdatePrivacySettings extends ProfileEvent {
  final String userId;
  final UserPrivacySettings settings;

  const UpdatePrivacySettings({
    required this.userId,
    required this.settings,
  });

  @override
  List<Object> get props => [userId, settings];
}

/// Update parental controls
class UpdateParentalControls extends ProfileEvent {
  final String userId;
  final ParentalControls controls;

  const UpdateParentalControls({
    required this.userId,
    required this.controls,
  });

  @override
  List<Object> get props => [userId, controls];
}

/// Update notification settings
class UpdateNotificationSettings extends ProfileEvent {
  final String userId;
  final NotificationSettings settings;

  const UpdateNotificationSettings({
    required this.userId,
    required this.settings,
  });

  @override
  List<Object> get props => [userId, settings];
}

/// Load user achievements
class LoadUserAchievements extends ProfileEvent {
  final String userId;

  const LoadUserAchievements(this.userId);

  @override
  List<Object> get props => [userId];
}

/// Load user badges
class LoadUserBadges extends ProfileEvent {
  final String userId;

  const LoadUserBadges(this.userId);

  @override
  List<Object> get props => [userId];
}

/// Select display badge
class SelectDisplayBadge extends ProfileEvent {
  final String userId;
  final String badgeId;

  const SelectDisplayBadge({
    required this.userId,
    required this.badgeId,
  });

  @override
  List<Object> get props => [userId, badgeId];
}

/// Load user statistics
class LoadUserStatistics extends ProfileEvent {
  final String userId;

  const LoadUserStatistics(this.userId);

  @override
  List<Object> get props => [userId];
}

/// Load available themes
class LoadAvailableThemes extends ProfileEvent {
  const LoadAvailableThemes();
}

/// Load available avatars
class LoadAvailableAvatars extends ProfileEvent {
  const LoadAvailableAvatars();
}

/// Check for new achievements
class CheckNewAchievements extends ProfileEvent {
  final String userId;

  const CheckNewAchievements(this.userId);

  @override
  List<Object> get props => [userId];
}

/// Export user data
class ExportUserData extends ProfileEvent {
  final String userId;

  const ExportUserData(this.userId);

  @override
  List<Object> get props => [userId];
}

/// Validate user data
class ValidateUserData extends ProfileEvent {
  final String userId;

  const ValidateUserData(this.userId);

  @override
  List<Object> get props => [userId];
}

/// Clear cache
class ClearProfileCache extends ProfileEvent {
  const ClearProfileCache();
}

/// Refresh profile data
class RefreshProfile extends ProfileEvent {
  final String userId;

  const RefreshProfile(this.userId);

  @override
  List<Object> get props => [userId];
}