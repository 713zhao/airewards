import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/user_entities.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

/// BLoC for managing user profile and settings with kid-friendly features.
/// 
/// This BLoC handles comprehensive user profile management designed specifically
/// for children, including avatar customization, achievement showcase, parental
/// controls, privacy settings, and engaging profile statistics. All operations
/// are designed with child safety and engagement in mind.
/// 
/// Key features:
/// - Kid-safe profile customization with fun avatars and themes
/// - Achievement and badge showcase with celebratory animations
/// - Parental control integration for safety settings
/// - Privacy-first approach with minimal data collection
/// - Engaging statistics and progress visualization
/// - Theme and personalization options designed for children
@injectable
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _profileRepository;
  
  // Timers and subscriptions for real-time updates
  Timer? _achievementCheckTimer;
  StreamSubscription<UserProfile>? _profileSubscription;
  
  // Current user context
  String? _currentUserId;
  
  // Constants for kid-friendly features
  static const Duration _achievementCheckInterval = Duration(minutes: 10);
  static const int _maxCustomAvatars = 50;
  static const int _maxThemes = 20;
  
  ProfileBloc({
    required ProfileRepository profileRepository,
  })  : _profileRepository = profileRepository,
        super(const ProfileInitial()) {
    
    // Register event handlers with kid-friendly messaging
    on<ProfileLoadRequested>(_onProfileLoadRequested);
    on<ProfileRefreshRequested>(_onProfileRefreshRequested);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
    on<ProfileAvatarUpdateRequested>(_onProfileAvatarUpdateRequested);
    on<ProfileThemeChanged>(_onProfileThemeChanged);
    on<ProfilePrivacySettingsUpdated>(_onProfilePrivacySettingsUpdated);
    on<ProfileParentalControlsUpdated>(_onProfileParentalControlsUpdated);
    on<ProfileNotificationSettingsUpdated>(_onProfileNotificationSettingsUpdated);
    on<ProfileAchievementUpdated>(_onProfileAchievementUpdated);
    on<ProfileBadgeSelected>(_onProfileBadgeSelected);
    on<ProfileStreakUpdated>(_onProfileStreakUpdated);
    on<ProfileStatsRefreshed>(_onProfileStatsRefreshed);
    on<ProfileExportRequested>(_onProfileExportRequested);
    on<ProfileImportRequested>(_onProfileImportRequested);
    on<ProfileDeleteRequested>(_onProfileDeleteRequested);
    on<ProfileRealTimeStarted>(_onProfileRealTimeStarted);
    on<ProfileRealTimeStopped>(_onProfileRealTimeStopped);
    on<ProfileDataUpdated>(_onProfileDataUpdated);
    on<ProfileErrorCleared>(_onProfileErrorCleared);
    on<ProfileResetRequested>(_onProfileResetRequested);
  }

  /// Load user profile with engaging loading messages
  Future<void> _onProfileLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    _currentUserId = event.userId;
    
    if (!event.forceRefresh && state is ProfileLoaded) {
      return; // Return cached data if available
    }

    emit(const ProfileLoading(
      message: '👤 Loading your awesome profile...',
      loadingType: ProfileLoadingType.initialLoad,
    ));

    try {
      // Load profile data in parallel for better performance
      final futures = await Future.wait([
        _profileRepository.getUserProfile(event.userId),
        _profileRepository.getUserAchievements(event.userId),
        _profileRepository.getUserBadges(event.userId),
        _profileRepository.getUserStatistics(event.userId),
        _profileRepository.getAvailableThemes(),
        _profileRepository.getAvailableAvatars(),
      ]);

      final profileResult = futures[0] as Either<Failure, UserProfile>;
      final achievementsResult = futures[1] as Either<Failure, List<Achievement>>;
      final badgesResult = futures[2] as Either<Failure, List<Badge>>;
      final statsResult = futures[3] as Either<Failure, UserStatistics>;
      final themesResult = futures[4] as Either<Failure, List<AppTheme>>;
      final avatarsResult = futures[5] as Either<Failure, List<Avatar>>;

      // Check for any failures
      final profileFailure = profileResult.fold((f) => f, (_) => null);
      if (profileFailure != null) {
        emit(ProfileError(
          message: '😅 Couldn\'t load your profile right now. Let\'s try again!',
          errorType: ProfileErrorType.loadError,
          canRetry: true,
        ));
        return;
      }

      // Extract successful results
      final profile = profileResult.fold((_) => null, (data) => data)!;
      final achievements = achievementsResult.fold((_) => <Achievement>[], (data) => data);
      final badges = badgesResult.fold((_) => <Badge>[], (data) => data);
      final stats = statsResult.fold((_) => null, (data) => data);
      final themes = themesResult.fold((_) => <AppTheme>[], (data) => data);
      final avatars = avatarsResult.fold((_) => <Avatar>[], (data) => data);

      emit(ProfileLoaded(
        profile: profile,
        achievements: achievements,
        badges: badges,
        statistics: stats,
        availableThemes: themes,
        availableAvatars: avatars,
        lastUpdated: DateTime.now(),
      ));

      // Start periodic achievement checks
      _startAchievementChecks();

    } catch (e) {
      emit(ProfileError(
        message: '😓 Something went wrong loading your profile. Don\'t worry, we can fix it!',
        errorType: ProfileErrorType.generic,
        canRetry: true,
        details: e.toString(),
      ));
    }
  }

  /// Refresh profile data
  Future<void> _onProfileRefreshRequested(
    ProfileRefreshRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (_currentUserId == null) return;

    if (event.showLoading && state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      emit(ProfileRefreshing(
        currentProfile: currentState.profile,
        message: '🔄 Updating your profile...',
      ));
    }

    // Reload profile data
    add(ProfileLoadRequested(
      userId: _currentUserId!,
      forceRefresh: true,
    ));
  }

  /// Update user profile information
  Future<void> _onProfileUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is! ProfileLoaded) return;

    final currentState = state as ProfileLoaded;
    
    emit(ProfileOperationInProgress(
      currentProfile: currentState.profile,
      message: '✏️ Updating your profile...',
      operationType: ProfileOperationType.update,
    ));

    try {
      final result = await _profileRepository.updateUserProfile(event.updates);

      result.fold(
        (failure) {
          emit(ProfileError(
            message: '😅 Couldn\'t update your profile right now. Try again!',
            errorType: ProfileErrorType.updateError,
            canRetry: true,
          ));
        },
        (updatedProfile) {
          emit(currentState.copyWith(
            profile: updatedProfile,
            lastUpdated: DateTime.now(),
          ));
          
          // Show success message
          emit(ProfileOperationSuccess(
            message: '🎉 Profile updated successfully!',
            operationType: ProfileOperationType.update,
          ));
          
          // Return to loaded state
          Timer(const Duration(seconds: 2), () {
            if (state is ProfileOperationSuccess) {
              emit(currentState.copyWith(profile: updatedProfile));
            }
          });
        },
      );

    } catch (e) {
      emit(ProfileError(
        message: '😓 Something went wrong updating your profile.',
        errorType: ProfileErrorType.generic,
        canRetry: true,
      ));
    }
  }

  /// Update user avatar
  Future<void> _onProfileAvatarUpdateRequested(
    ProfileAvatarUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is! ProfileLoaded) return;

    final currentState = state as ProfileLoaded;
    
    emit(ProfileOperationInProgress(
      currentProfile: currentState.profile,
      message: '🖼️ Updating your awesome avatar...',
      operationType: ProfileOperationType.avatarUpdate,
    ));

    try {
      Either<Failure, UserProfile> result;
      
      if (event.avatarFile != null) {
        // Upload custom avatar
        result = await _profileRepository.uploadCustomAvatar(
          currentState.profile.id,
          event.avatarFile!,
        );
      } else if (event.avatarId != null) {
        // Select predefined avatar
        result = await _profileRepository.updateAvatar(
          currentState.profile.id,
          event.avatarId!,
        );
      } else {
        emit(ProfileError(
          message: '😅 Please select an avatar to update!',
          errorType: ProfileErrorType.validationError,
          canRetry: false,
        ));
        return;
      }

      result.fold(
        (failure) {
          emit(ProfileError(
            message: '😅 Couldn\'t update your avatar right now. Try again!',
            errorType: ProfileErrorType.avatarError,
            canRetry: true,
          ));
        },
        (updatedProfile) {
          emit(currentState.copyWith(
            profile: updatedProfile,
            lastUpdated: DateTime.now(),
          ));
          
          emit(ProfileOperationSuccess(
            message: '🎨 Your new avatar looks amazing!',
            operationType: ProfileOperationType.avatarUpdate,
          ));
        },
      );

    } catch (e) {
      emit(ProfileError(
        message: '😓 Something went wrong with your avatar update.',
        errorType: ProfileErrorType.generic,
        canRetry: true,
      ));
    }
  }

  /// Change app theme
  Future<void> _onProfileThemeChanged(
    ProfileThemeChanged event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is! ProfileLoaded) return;

    final currentState = state as ProfileLoaded;
    
    try {
      final result = await _profileRepository.updateTheme(
        currentState.profile.id,
        event.themeId,
      );

      result.fold(
        (failure) {
          emit(ProfileError(
            message: '🎨 Couldn\'t change your theme right now. Try again!',
            errorType: ProfileErrorType.themeError,
            canRetry: true,
          ));
        },
        (updatedProfile) {
          emit(currentState.copyWith(
            profile: updatedProfile,
            lastUpdated: DateTime.now(),
          ));
        },
      );

    } catch (e) {
      emit(ProfileError(
        message: '😓 Something went wrong changing your theme.',
        errorType: ProfileErrorType.generic,
        canRetry: true,
      ));
    }
  }

  /// Update privacy settings with parental guidance
  Future<void> _onProfilePrivacySettingsUpdated(
    ProfilePrivacySettingsUpdated event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is! ProfileLoaded) return;

    final currentState = state as ProfileLoaded;
    
    emit(ProfileOperationInProgress(
      currentProfile: currentState.profile,
      message: '🔒 Updating your privacy settings...',
      operationType: ProfileOperationType.privacyUpdate,
    ));

    try {
      final result = await _profileRepository.updatePrivacySettings(
        currentState.profile.id,
        event.settings,
      );

      result.fold(
        (failure) {
          emit(ProfileError(
            message: '🔒 Couldn\'t update privacy settings. Try again!',
            errorType: ProfileErrorType.privacyError,
            canRetry: true,
          ));
        },
        (updatedProfile) {
          emit(currentState.copyWith(
            profile: updatedProfile,
            lastUpdated: DateTime.now(),
          ));
          
          emit(ProfileOperationSuccess(
            message: '🔒 Privacy settings updated safely!',
            operationType: ProfileOperationType.privacyUpdate,
          ));
        },
      );

    } catch (e) {
      emit(ProfileError(
        message: '😓 Something went wrong with privacy settings.',
        errorType: ProfileErrorType.generic,
        canRetry: true,
      ));
    }
  }

  /// Update parental controls
  Future<void> _onProfileParentalControlsUpdated(
    ProfileParentalControlsUpdated event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is! ProfileLoaded) return;

    final currentState = state as ProfileLoaded;
    
    try {
      final result = await _profileRepository.updateParentalControls(
        currentState.profile.id,
        event.controls,
      );

      result.fold(
        (failure) {
          emit(ProfileError(
            message: '👨‍👩‍👧‍👦 Couldn\'t update parental controls. Try again!',
            errorType: ProfileErrorType.parentalControlError,
            canRetry: true,
          ));
        },
        (updatedProfile) {
          emit(currentState.copyWith(
            profile: updatedProfile,
            lastUpdated: DateTime.now(),
          ));
        },
      );

    } catch (e) {
      emit(ProfileError(
        message: '😓 Something went wrong with parental controls.',
        errorType: ProfileErrorType.generic,
        canRetry: true,
      ));
    }
  }

  /// Update notification settings
  Future<void> _onProfileNotificationSettingsUpdated(
    ProfileNotificationSettingsUpdated event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is! ProfileLoaded) return;

    final currentState = state as ProfileLoaded;
    
    try {
      final result = await _profileRepository.updateNotificationSettings(
        currentState.profile.id,
        event.settings,
      );

      result.fold(
        (failure) {
          emit(ProfileError(
            message: '🔔 Couldn\'t update notification settings. Try again!',
            errorType: ProfileErrorType.notificationError,
            canRetry: true,
          ));
        },
        (updatedProfile) {
          emit(currentState.copyWith(
            profile: updatedProfile,
            lastUpdated: DateTime.now(),
          ));
        },
      );

    } catch (e) {
      emit(ProfileError(
        message: '😓 Something went wrong with notification settings.',
        errorType: ProfileErrorType.generic,
        canRetry: true,
      ));
    }
  }

  /// Handle achievement updates
  void _onProfileAchievementUpdated(
    ProfileAchievementUpdated event,
    Emitter<ProfileState> emit,
  ) {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      final updatedAchievements = List<Achievement>.from(currentState.achievements);
      
      // Update or add achievement
      final existingIndex = updatedAchievements.indexWhere(
        (a) => a.id == event.achievement.id,
      );
      
      if (existingIndex != -1) {
        updatedAchievements[existingIndex] = event.achievement;
      } else {
        updatedAchievements.add(event.achievement);
      }
      
      emit(currentState.copyWith(
        achievements: updatedAchievements,
        lastUpdated: DateTime.now(),
      ));
    }
  }

  /// Handle badge selection
  Future<void> _onProfileBadgeSelected(
    ProfileBadgeSelected event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is! ProfileLoaded) return;

    final currentState = state as ProfileLoaded;
    
    try {
      final result = await _profileRepository.selectDisplayBadge(
        currentState.profile.id,
        event.badgeId,
      );

      result.fold(
        (failure) {
          emit(ProfileError(
            message: '🏆 Couldn\'t select that badge right now. Try again!',
            errorType: ProfileErrorType.badgeError,
            canRetry: true,
          ));
        },
        (updatedProfile) {
          emit(currentState.copyWith(
            profile: updatedProfile,
            lastUpdated: DateTime.now(),
          ));
        },
      );

    } catch (e) {
      emit(ProfileError(
        message: '😓 Something went wrong selecting your badge.',
        errorType: ProfileErrorType.generic,
        canRetry: true,
      ));
    }
  }

  /// Handle streak updates
  void _onProfileStreakUpdated(
    ProfileStreakUpdated event,
    Emitter<ProfileState> emit,
  ) {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      final updatedProfile = currentState.profile.copyWith(
        currentStreak: event.newStreak,
        longestStreak: event.newStreak > currentState.profile.longestStreak
            ? event.newStreak
            : currentState.profile.longestStreak,
      );
      
      emit(currentState.copyWith(
        profile: updatedProfile,
        lastUpdated: DateTime.now(),
      ));
    }
  }

  /// Refresh user statistics
  Future<void> _onProfileStatsRefreshed(
    ProfileStatsRefreshed event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is! ProfileLoaded) return;

    final currentState = state as ProfileLoaded;
    
    try {
      final result = await _profileRepository.getUserStatistics(currentState.profile.id);

      result.fold(
        (failure) {
          // Silently fail for stats refresh
        },
        (updatedStats) {
          emit(currentState.copyWith(
            statistics: updatedStats,
            lastUpdated: DateTime.now(),
          ));
        },
      );

    } catch (e) {
      // Silently handle stats refresh errors
    }
  }

  /// Export profile data
  Future<void> _onProfileExportRequested(
    ProfileExportRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is! ProfileLoaded) return;

    final currentState = state as ProfileLoaded;
    
    emit(ProfileExportInProgress(
      format: event.format,
      progress: 0,
      statusMessage: '💾 Preparing your profile data...',
    ));

    try {
      final result = await _profileRepository.exportProfileData(
        currentState.profile.id,
        event.format,
      );

      result.fold(
        (failure) {
          emit(ProfileError(
            message: '💾 Couldn\'t export your data right now. Try again!',
            errorType: ProfileErrorType.exportError,
            canRetry: true,
          ));
        },
        (filePath) {
          emit(ProfileExportCompleted(
            filePath: filePath,
            format: event.format,
          ));
        },
      );

    } catch (e) {
      emit(ProfileError(
        message: '😓 Something went wrong exporting your data.',
        errorType: ProfileErrorType.generic,
        canRetry: true,
      ));
    }
  }

  /// Import profile data
  Future<void> _onProfileImportRequested(
    ProfileImportRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileImportInProgress(
      format: event.format,
      progress: 0,
      statusMessage: '📤 Importing your profile data...',
    ));

    try {
      final result = await _profileRepository.importProfileData(
        event.filePath,
        event.format,
      );

      result.fold(
        (failure) {
          emit(ProfileError(
            message: '📤 Couldn\'t import your data. Check the file and try again!',
            errorType: ProfileErrorType.importError,
            canRetry: true,
          ));
        },
        (importResult) {
          emit(ProfileImportCompleted(
            format: event.format,
            importedItems: importResult.totalImported,
            errors: importResult.errors,
          ));
        },
      );

    } catch (e) {
      emit(ProfileError(
        message: '😓 Something went wrong importing your data.',
        errorType: ProfileErrorType.generic,
        canRetry: true,
      ));
    }
  }

  /// Delete user profile (requires parental confirmation)
  Future<void> _onProfileDeleteRequested(
    ProfileDeleteRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is! ProfileLoaded) return;

    final currentState = state as ProfileLoaded;
    
    emit(ProfileOperationInProgress(
      currentProfile: currentState.profile,
      message: '🗑️ Removing profile data...',
      operationType: ProfileOperationType.delete,
    ));

    try {
      final result = await _profileRepository.deleteUserProfile(
        currentState.profile.id,
        event.confirmationCode,
      );

      result.fold(
        (failure) {
          emit(ProfileError(
            message: '🗑️ Couldn\'t delete profile. Check with a parent!',
            errorType: ProfileErrorType.deleteError,
            canRetry: true,
          ));
        },
        (_) {
          emit(const ProfileDeleted(
            message: '👋 Profile has been safely removed.',
          ));
        },
      );

    } catch (e) {
      emit(ProfileError(
        message: '😓 Something went wrong deleting the profile.',
        errorType: ProfileErrorType.generic,
        canRetry: true,
      ));
    }
  }

  /// Start real-time profile updates
  Future<void> _onProfileRealTimeStarted(
    ProfileRealTimeStarted event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is! ProfileLoaded || _currentUserId == null) {
      return;
    }

    try {
      await _profileSubscription?.cancel();
      
      _profileSubscription = _profileRepository
          .watchUserProfile(_currentUserId!)
          .listen(
            (profile) => add(ProfileDataUpdated(profile: profile)),
            onError: (error) {
              // Handle real-time errors silently
            },
          );

      final currentState = state as ProfileLoaded;
      emit(currentState.copyWith(isRealTimeEnabled: true));

    } catch (e) {
      // Handle real-time setup errors silently
    }
  }

  /// Stop real-time profile updates
  Future<void> _onProfileRealTimeStopped(
    ProfileRealTimeStopped event,
    Emitter<ProfileState> emit,
  ) async {
    await _profileSubscription?.cancel();
    _profileSubscription = null;

    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      emit(currentState.copyWith(isRealTimeEnabled: false));
    }
  }

  /// Handle real-time profile data updates
  void _onProfileDataUpdated(
    ProfileDataUpdated event,
    Emitter<ProfileState> emit,
  ) {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      
      emit(currentState.copyWith(
        profile: event.profile,
        lastUpdated: DateTime.now(),
      ));
    }
  }

  /// Clear error state
  void _onProfileErrorCleared(
    ProfileErrorCleared event,
    Emitter<ProfileState> emit,
  ) {
    if (_currentUserId != null) {
      add(ProfileLoadRequested(userId: _currentUserId!));
    } else {
      emit(const ProfileInitial());
    }
  }

  /// Reset profile state
  void _onProfileResetRequested(
    ProfileResetRequested event,
    Emitter<ProfileState> emit,
  ) {
    _stopAllTimers();
    emit(const ProfileInitial());
  }

  /// Start periodic achievement checks
  void _startAchievementChecks() {
    _achievementCheckTimer?.cancel();
    _achievementCheckTimer = Timer.periodic(_achievementCheckInterval, (_) {
      if (_currentUserId != null) {
        _checkForNewAchievements();
      }
    });
  }

  /// Check for new achievements
  Future<void> _checkForNewAchievements() async {
    if (_currentUserId == null) return;
    
    try {
      final result = await _profileRepository.checkNewAchievements(_currentUserId!);
      
      result.fold(
        (_) {}, // Silently handle errors
        (newAchievements) {
          for (final achievement in newAchievements) {
            add(ProfileAchievementUpdated(achievement: achievement));
          }
        },
      );
    } catch (e) {
      // Silently handle achievement check errors
    }
  }

  /// Stop all timers and subscriptions
  void _stopAllTimers() {
    _achievementCheckTimer?.cancel();
    _profileSubscription?.cancel();
    _achievementCheckTimer = null;
    _profileSubscription = null;
  }

  @override
  Future<void> close() {
    _stopAllTimers();
    return super.close();
  }
}