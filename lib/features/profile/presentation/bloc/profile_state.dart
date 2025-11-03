import 'package:equatable/equatable.dart';
import '../../../profile/data/services/profile_mock_data_service.dart';

/// Base class for all profile states
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

/// Loading state with engaging message
class ProfileLoading extends ProfileState {
  final String message;

  const ProfileLoading({
    this.message = '🌟 Loading your amazing profile...',
  });

  @override
  List<Object> get props => [message];
}

/// Profile loaded successfully
class ProfileLoaded extends ProfileState {
  final UserProfile profile;
  final String? successMessage;

  const ProfileLoaded({
    required this.profile,
    this.successMessage,
  });

  @override
  List<Object?> get props => [profile, successMessage];

  /// Create celebration state for achievements
  ProfileLoaded withCelebration(String message) {
    return ProfileLoaded(
      profile: profile,
      successMessage: '🎉 $message',
    );
  }

  /// Create success state for updates
  ProfileLoaded withSuccess(String message) {
    return ProfileLoaded(
      profile: profile,
      successMessage: '✅ $message',
    );
  }
}

/// Profile update in progress
class ProfileUpdating extends ProfileState {
  final UserProfile currentProfile;
  final String updateType;
  final String message;

  const ProfileUpdating({
    required this.currentProfile,
    required this.updateType,
    required this.message,
  });

  @override
  List<Object> get props => [currentProfile, updateType, message];
}

/// Avatar upload in progress
class AvatarUploading extends ProfileState {
  final UserProfile currentProfile;
  final double progress;

  const AvatarUploading({
    required this.currentProfile,
    this.progress = 0.0,
  });

  @override
  List<Object> get props => [currentProfile, progress];
}

/// Achievements loaded
class AchievementsLoaded extends ProfileState {
  final List<Achievement> achievements;
  final List<Achievement>? newAchievements;
  final String? celebrationMessage;

  const AchievementsLoaded({
    required this.achievements,
    this.newAchievements,
    this.celebrationMessage,
  });

  @override
  List<Object?> get props => [achievements, newAchievements, celebrationMessage];
}

/// Badges loaded
class BadgesLoaded extends ProfileState {
  final List<Badge> badges;
  final Badge? selectedBadge;
  final String? message;

  const BadgesLoaded({
    required this.badges,
    this.selectedBadge,
    this.message,
  });

  @override
  List<Object?> get props => [badges, selectedBadge, message];
}

/// Statistics loaded
class StatisticsLoaded extends ProfileState {
  final UserStatistics statistics;
  final String? insightMessage;

  const StatisticsLoaded({
    required this.statistics,
    this.insightMessage,
  });

  @override
  List<Object?> get props => [statistics, insightMessage];
}

/// Themes loaded
class ThemesLoaded extends ProfileState {
  final List<AppTheme> themes;
  final AppTheme? selectedTheme;

  const ThemesLoaded({
    required this.themes,
    this.selectedTheme,
  });

  @override
  List<Object?> get props => [themes, selectedTheme];
}

/// Avatars loaded
class AvatarsLoaded extends ProfileState {
  final List<Avatar> avatars;
  final Avatar? selectedAvatar;

  const AvatarsLoaded({
    required this.avatars,
    this.selectedAvatar,
  });

  @override
  List<Object?> get props => [avatars, selectedAvatar];
}

/// Data export ready
class DataExportReady extends ProfileState {
  final Map<String, dynamic> exportData;
  final String downloadUrl;

  const DataExportReady({
    required this.exportData,
    required this.downloadUrl,
  });

  @override
  List<Object> get props => [exportData, downloadUrl];
}

/// Validation result
class ValidationResult extends ProfileState {
  final bool isValid;
  final List<String> issues;
  final String message;

  const ValidationResult({
    required this.isValid,
    this.issues = const [],
    required this.message,
  });

  @override
  List<Object> get props => [isValid, issues, message];
}

/// Cache cleared
class CacheCleared extends ProfileState {
  final String message;

  const CacheCleared({
    this.message = '✨ Cache cleared! Everything is fresh and ready!',
  });

  @override
  List<Object> get props => [message];
}

/// New achievement celebration
class AchievementCelebration extends ProfileState {
  final Achievement achievement;
  final UserProfile updatedProfile;
  final String celebrationMessage;

  const AchievementCelebration({
    required this.achievement,
    required this.updatedProfile,
    required this.celebrationMessage,
  });

  @override
  List<Object> get props => [achievement, updatedProfile, celebrationMessage];
}

/// Level up celebration
class LevelUpCelebration extends ProfileState {
  final int newLevel;
  final UserProfile updatedProfile;
  final String celebrationMessage;

  const LevelUpCelebration({
    required this.newLevel,
    required this.updatedProfile,
    required this.celebrationMessage,
  });

  @override
  List<Object> get props => [newLevel, updatedProfile, celebrationMessage];
}

/// Streak milestone celebration
class StreakMilestoneCelebration extends ProfileState {
  final int streakCount;
  final UserProfile updatedProfile;
  final String celebrationMessage;

  const StreakMilestoneCelebration({
    required this.streakCount,
    required this.updatedProfile,
    required this.celebrationMessage,
  });

  @override
  List<Object> get props => [streakCount, updatedProfile, celebrationMessage];
}

/// Error state with kid-friendly messages
class ProfileError extends ProfileState {
  final String message;
  final String? technicalDetails;
  final bool isRetryable;

  const ProfileError({
    required this.message,
    this.technicalDetails,
    this.isRetryable = true,
  });

  @override
  List<Object?> get props => [message, technicalDetails, isRetryable];

  /// Create user-friendly error messages
  factory ProfileError.network() {
    return const ProfileError(
      message: '🌐 Oops! Having trouble connecting. Let\'s try again in a moment!',
      isRetryable: true,
    );
  }

  factory ProfileError.validation(String details) {
    return ProfileError(
      message: '📝 Hmm, something needs to be fixed before we can continue.',
      technicalDetails: details,
      isRetryable: false,
    );
  }

  factory ProfileError.permission() {
    return const ProfileError(
      message: '🔒 You\'ll need permission from a grown-up for this feature.',
      isRetryable: false,
    );
  }

  factory ProfileError.fileSize() {
    return const ProfileError(
      message: '📁 That file is too big! Try choosing a smaller picture.',
      isRetryable: false,
    );
  }

  factory ProfileError.fileType() {
    return const ProfileError(
      message: '🖼️ We can only use JPG, PNG, or GIF pictures for your avatar.',
      isRetryable: false,
    );
  }

  factory ProfileError.generic(String details) {
    return ProfileError(
      message: '😅 Something unexpected happened. Don\'t worry, we\'ll figure it out!',
      technicalDetails: details,
      isRetryable: true,
    );
  }
}