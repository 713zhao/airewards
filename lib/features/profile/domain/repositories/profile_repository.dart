import 'dart:io';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../../../profile/data/services/profile_mock_data_service.dart';

/// Repository interface for profile management operations
abstract class ProfileRepository {
  /// Get user profile by ID
  Future<Either<Failure, UserProfile>> getUserProfile(String userId);

  /// Update user profile with given updates
  Future<Either<Failure, UserProfile>> updateUserProfile(
    Map<String, dynamic> updates,
  );

  /// Upload custom avatar image
  Future<Either<Failure, UserProfile>> uploadCustomAvatar(
    String userId,
    File avatarFile,
  );

  /// Update avatar with predefined avatar ID
  Future<Either<Failure, UserProfile>> updateAvatar(
    String userId,
    String avatarId,
  );

  /// Update user theme
  Future<Either<Failure, UserProfile>> updateTheme(
    String userId,
    String themeId,
  );

  /// Update privacy settings
  Future<Either<Failure, UserProfile>> updatePrivacySettings(
    String userId,
    UserPrivacySettings settings,
  );

  /// Update parental controls
  Future<Either<Failure, UserProfile>> updateParentalControls(
    String userId,
    ParentalControls controls,
  );

  /// Update notification settings
  Future<Either<Failure, UserProfile>> updateNotificationSettings(
    String userId,
    NotificationSettings settings,
  );

  /// Get user achievements
  Future<Either<Failure, List<Achievement>>> getUserAchievements(String userId);

  /// Get user badges
  Future<Either<Failure, List<Badge>>> getUserBadges(String userId);

  /// Select display badge
  Future<Either<Failure, UserProfile>> selectDisplayBadge(
    String userId,
    String badgeId,
  );

  /// Get user statistics
  Future<Either<Failure, UserStatistics>> getUserStatistics(String userId);

  /// Get available themes
  Future<Either<Failure, List<AppTheme>>> getAvailableThemes();

  /// Get available avatars
  Future<Either<Failure, List<Avatar>>> getAvailableAvatars();

  /// Check for new achievements
  Future<Either<Failure, List<Achievement>>> checkNewAchievements(String userId);

  /// Delete user profile and all associated data
  Future<Either<Failure, UserProfile>> deleteProfile(String userId);

  /// Export all user data for GDPR compliance
  Future<Either<Failure, Map<String, dynamic>>> exportUserData(String userId);

  /// Watch user profile for real-time updates
  Stream<UserProfile> watchUserProfile(String userId);

  /// Clear cached profile data
  Future<Either<Failure, void>> clearCache();

  /// Validate user data integrity
  Future<Either<Failure, bool>> validateUserData(String userId);
}