import 'dart:io';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../../domain/repositories/profile_repository.dart';
import '../services/profile_mock_data_service.dart';

/// Mock implementation of ProfileRepository for development and testing
@LazySingleton(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileMockDataService _mockDataService;

  const ProfileRepositoryImpl(this._mockDataService);

  @override
  Future<Either<Failure, UserProfile>> getUserProfile(String userId) async {
    try {
      return await _mockDataService.getUserProfile(userId);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get user profile: $e'));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> updateUserProfile(
    Map<String, dynamic> updates,
  ) async {
    try {
      // Validate required fields
      if (!updates.containsKey('userId')) {
        return Left(ValidationFailure('User ID is required'));
      }

      // Validate display name if provided
      final displayName = updates['displayName'] as String?;
      if (displayName != null && displayName.trim().isEmpty) {
        return Left(ValidationFailure('Display name cannot be empty'));
      }

      // Validate email format if provided
      final email = updates['email'] as String?;
      if (email != null && !_isValidEmail(email)) {
        return Left(ValidationFailure('Invalid email format'));
      }

      return await _mockDataService.updateUserProfile(updates);
    } catch (e) {
      return Left(DatabaseFailure('Failed to update user profile: $e'));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> uploadCustomAvatar(
    String userId,
    File avatarFile,
  ) async {
    try {
      // Validate file exists
      if (!await avatarFile.exists()) {
        return Left(ValidationFailure('Avatar file does not exist'));
      }

      // Validate file size (max 5MB for example)
      final fileSize = await avatarFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        return Left(ValidationFailure('Avatar file is too large (max 5MB)'));
      }

      // Validate file type (basic check)
      final extension = avatarFile.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
        return Left(ValidationFailure('Invalid avatar file type. Use JPG, PNG, or GIF'));
      }

      return await _mockDataService.uploadCustomAvatar(userId, avatarFile);
    } catch (e) {
      return Left(DatabaseFailure('Failed to upload custom avatar: $e'));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> updateAvatar(
    String userId,
    String avatarId,
  ) async {
    try {
      if (avatarId.trim().isEmpty) {
        return Left(ValidationFailure('Avatar ID cannot be empty'));
      }

      return await _mockDataService.updateAvatar(userId, avatarId);
    } catch (e) {
      return Left(DatabaseFailure('Failed to update avatar: $e'));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> updateTheme(
    String userId,
    String themeId,
  ) async {
    try {
      if (themeId.trim().isEmpty) {
        return Left(ValidationFailure('Theme ID cannot be empty'));
      }

      return await _mockDataService.updateTheme(userId, themeId);
    } catch (e) {
      return Left(DatabaseFailure('Failed to update theme: $e'));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> updatePrivacySettings(
    String userId,
    UserPrivacySettings settings,
  ) async {
    try {
      return await _mockDataService.updatePrivacySettings(userId, settings);
    } catch (e) {
      return Left(DatabaseFailure('Failed to update privacy settings: $e'));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> updateParentalControls(
    String userId,
    ParentalControls controls,
  ) async {
    try {
      // Validate parent email if provided
      if (controls.parentEmail != null && 
          controls.parentEmail!.isNotEmpty && 
          !_isValidEmail(controls.parentEmail!)) {
        return Left(ValidationFailure('Invalid parent email format'));
      }

      return await _mockDataService.updateParentalControls(userId, controls);
    } catch (e) {
      return Left(DatabaseFailure('Failed to update parental controls: $e'));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> updateNotificationSettings(
    String userId,
    NotificationSettings settings,
  ) async {
    try {
      return await _mockDataService.updateNotificationSettings(userId, settings);
    } catch (e) {
      return Left(DatabaseFailure('Failed to update notification settings: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Achievement>>> getUserAchievements(String userId) async {
    try {
      return await _mockDataService.getUserAchievements(userId);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get user achievements: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Badge>>> getUserBadges(String userId) async {
    try {
      return await _mockDataService.getUserBadges(userId);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get user badges: $e'));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> selectDisplayBadge(
    String userId,
    String badgeId,
  ) async {
    try {
      if (badgeId.trim().isEmpty) {
        return Left(ValidationFailure('Badge ID cannot be empty'));
      }

      // Verify user has this badge
      final badgesResult = await getUserBadges(userId);
      return badgesResult.fold(
        (failure) => Left(failure),
        (badges) {
          final hasBadge = badges.any((badge) => badge.id == badgeId);
          if (!hasBadge) {
            return Left(ValidationFailure('User does not have the specified badge'));
          }

          return _mockDataService.selectDisplayBadge(userId, badgeId);
        },
      );
    } catch (e) {
      return Left(DatabaseFailure('Failed to select display badge: $e'));
    }
  }

  @override
  Future<Either<Failure, UserStatistics>> getUserStatistics(String userId) async {
    try {
      return await _mockDataService.getUserStatistics(userId);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get user statistics: $e'));
    }
  }

  @override
  Future<Either<Failure, List<AppTheme>>> getAvailableThemes() async {
    try {
      return await _mockDataService.getAvailableThemes();
    } catch (e) {
      return Left(DatabaseFailure('Failed to get available themes: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Avatar>>> getAvailableAvatars() async {
    try {
      return await _mockDataService.getAvailableAvatars();
    } catch (e) {
      return Left(DatabaseFailure('Failed to get available avatars: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Achievement>>> checkNewAchievements(String userId) async {
    try {
      return await _mockDataService.checkNewAchievements(userId);
    } catch (e) {
      return Left(DatabaseFailure('Failed to check new achievements: $e'));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> deleteProfile(String userId) async {
    try {
      // In a real implementation, this would handle complete profile deletion
      // For mock service, we'll simulate the deletion
      await Future.delayed(const Duration(milliseconds: 500));
      
      // This would typically:
      // 1. Delete all user data
      // 2. Remove profile from database
      // 3. Clean up associated files
      // 4. Handle GDPR compliance
      
      return Left(DatabaseFailure('Profile deletion not implemented in mock service'));
    } catch (e) {
      return Left(DatabaseFailure('Failed to delete profile: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> exportUserData(String userId) async {
    try {
      // Get all user data for export
      final profileResult = await getUserProfile(userId);
      final achievementsResult = await getUserAchievements(userId);
      final badgesResult = await getUserBadges(userId);
      final statisticsResult = await getUserStatistics(userId);

      return profileResult.fold(
        (failure) => Left(failure),
        (profile) => achievementsResult.fold(
          (failure) => Left(failure),
          (achievements) => badgesResult.fold(
            (failure) => Left(failure),
            (badges) => statisticsResult.fold(
              (failure) => Left(failure),
              (statistics) {
                final exportData = <String, dynamic>{
                  'profile': {
                    'id': profile.id,
                    'displayName': profile.displayName,
                    'email': profile.email,
                    'totalPoints': profile.totalPoints,
                    'currentStreak': profile.currentStreak,
                    'longestStreak': profile.longestStreak,
                    'level': profile.level,
                    'createdAt': profile.createdAt.toIso8601String(),
                    'lastActive': profile.lastActive.toIso8601String(),
                    'customizations': profile.customizations,
                  },
                  'achievements': achievements.map((achievement) => {
                    'id': achievement.id,
                    'title': achievement.title,
                    'description': achievement.description,
                    'tier': achievement.tier.name,
                    'earnedAt': achievement.earnedAt.toIso8601String(),
                  }).toList(),
                  'badges': badges.map((badge) => {
                    'id': badge.id,
                    'title': badge.title,
                    'description': badge.description,
                    'earnedAt': badge.earnedAt.toIso8601String(),
                    'isDisplayed': badge.isDisplayed,
                  }).toList(),
                  'statistics': {
                    'totalActivities': statistics.totalActivities,
                    'completedGoals': statistics.completedGoals,
                    'totalAchievements': statistics.totalAchievements,
                    'categoryStats': statistics.categoryStats,
                    'joinDate': statistics.joinDate.toIso8601String(),
                    'daysActive': statistics.daysActive,
                  },
                  'exportedAt': DateTime.now().toIso8601String(),
                  'version': '1.0',
                };

                return Right(exportData);
              },
            ),
          ),
        ),
      );
    } catch (e) {
      return Left(DatabaseFailure('Failed to export user data: $e'));
    }
  }

  @override
  Stream<UserProfile> watchUserProfile(String userId) {
    return _mockDataService.watchUserProfile(userId);
  }

  @override
  Future<Either<Failure, void>> clearCache() async {
    try {
      // In a real implementation, this would clear cached profile data
      await Future.delayed(const Duration(milliseconds: 100));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to clear cache: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> validateUserData(String userId) async {
    try {
      final profileResult = await getUserProfile(userId);
      
      return profileResult.fold(
        (failure) => Left(failure),
        (profile) {
          // Validate profile data integrity
          final validations = [
            profile.id.isNotEmpty,
            profile.displayName.isNotEmpty,
            _isValidEmail(profile.email),
            profile.totalPoints >= 0,
            profile.currentStreak >= 0,
            profile.longestStreak >= profile.currentStreak,
            profile.level > 0,
            profile.createdAt.isBefore(DateTime.now()),
            profile.lastActive.isBefore(DateTime.now().add(const Duration(minutes: 1))),
          ];

          final isValid = validations.every((validation) => validation);
          return Right(isValid);
        },
      );
    } catch (e) {
      return Left(ValidationFailure('Failed to validate user data: $e'));
    }
  }

  /// Helper method to validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}