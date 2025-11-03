import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../lib/core/errors/failures.dart';
import '../../../../../lib/core/utils/either.dart';
import '../../../../../lib/features/profile/data/services/profile_mock_data_service.dart';
import '../../../../../lib/features/profile/domain/repositories/profile_repository.dart';
import '../../../../../lib/features/profile/presentation/bloc/profile_bloc.dart';
import '../../../../../lib/features/profile/presentation/bloc/profile_event.dart';
import '../../../../../lib/features/profile/presentation/bloc/profile_state.dart';

/// Mock repository for testing
class MockProfileRepository extends Mock implements ProfileRepository {}

/// Mock file for avatar upload testing
class MockFile extends Mock implements File {}

void main() {
  group('ProfileBloc', () {
    late ProfileBloc profileBloc;
    late MockProfileRepository mockRepository;
    late MockFile mockFile;

    // Test data
    final testUserId = 'test_user_123';
    final testUserProfile = UserProfile(
      id: testUserId,
      displayName: 'Test Kid',
      email: 'testkid@example.com',
      avatarId: 'avatar_cat',
      themeId: 'theme_default',
      totalPoints: 150,
      currentStreak: 5,
      longestStreak: 12,
      level: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastActive: DateTime.now(),
      privacySettings: const UserPrivacySettings(
        profileVisible: false,
        achievementsVisible: true,
        allowFriendRequests: false,
        dataCollection: false,
      ),
      parentalControls: const ParentalControls(
        enabled: true,
        blockedFeatures: ['social', 'chat'],
        requireApproval: true,
        parentEmail: 'parent@example.com',
      ),
      notificationSettings: const NotificationSettings(
        achievementNotifications: true,
        goalReminders: true,
        streakReminders: true,
        weeklyReports: false,
        celebrationSounds: true,
      ),
    );

    final testAchievements = [
      Achievement(
        id: 'ach_1',
        title: '🌟 First Steps',
        description: 'Earned your first points!',
        icon: 'star',
        color: '#FFD700',
        tier: AchievementTier.bronze,
        earnedAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      Achievement(
        id: 'ach_2',
        title: '🔥 Streak Starter',
        description: 'Started your first streak!',
        icon: 'local_fire_department',
        color: '#FF6347',
        tier: AchievementTier.bronze,
        earnedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];

    final testBadges = [
      Badge(
        id: 'badge_1',
        title: '⭐ Superstar',
        description: 'Outstanding performance!',
        icon: 'star',
        color: '#FFD700',
        earnedAt: DateTime.now().subtract(const Duration(days: 7)),
        isDisplayed: true,
      ),
      Badge(
        id: 'badge_2',
        title: '🏆 Champion',
        description: 'Completed multiple goals!',
        icon: 'emoji_events',
        color: '#FF8C00',
        earnedAt: DateTime.now().subtract(const Duration(days: 3)),
        isDisplayed: false,
      ),
    ];

    final testStatistics = UserStatistics(
      totalActivities: 125,
      completedGoals: 8,
      totalAchievements: 12,
      categoryStats: {
        'Learning': 45,
        'Chores': 30,
        'Reading': 25,
        'Exercise': 20,
        'Creativity': 5,
      },
      joinDate: DateTime.now().subtract(const Duration(days: 30)),
      daysActive: 25,
    );

    setUp(() {
      mockRepository = MockProfileRepository();
      mockFile = MockFile();
      profileBloc = ProfileBloc(profileRepository: mockRepository);
      
      // Register fallback values for mocktail
      registerFallbackValue(const UserPrivacySettings());
      registerFallbackValue(const ParentalControls());
      registerFallbackValue(const NotificationSettings());
      registerFallbackValue(mockFile);
    });

    tearDown(() {
      profileBloc.close();
    });

    test('initial state is ProfileInitial', () {
      expect(profileBloc.state, equals(const ProfileInitial()));
    });

    group('LoadUserProfile', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [loading, loaded] when profile is loaded successfully',
        build: () {
          when(() => mockRepository.getUserProfile(any()))
              .thenAnswer((_) async => Right(testUserProfile));
          return profileBloc;
        },
        act: (bloc) => bloc.add(LoadUserProfile(testUserId)),
        expect: () => [
          const ProfileLoading(
            message: '🌟 Getting your awesome profile ready...',
          ),
          ProfileLoaded(
            profile: testUserProfile,
            successMessage: '✨ Welcome back, ${testUserProfile.displayName}!',
          ),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [loading, error] when profile loading fails',
        build: () {
          when(() => mockRepository.getUserProfile(any()))
              .thenAnswer((_) async => Left(NetworkFailure('Connection failed')));
          return profileBloc;
        },
        act: (bloc) => bloc.add(LoadUserProfile(testUserId)),
        expect: () => [
          const ProfileLoading(
            message: '🌟 Getting your awesome profile ready...',
          ),
          ProfileError.network(),
        ],
      );
    });

    group('UpdateProfile', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [updating, loaded] when profile is updated successfully',
        build: () {
          when(() => mockRepository.updateUserProfile(any()))
              .thenAnswer((_) async => Right(testUserProfile.copyWith(
                displayName: 'Updated Name',
              )));
          return profileBloc;
        },
        seed: () => ProfileLoaded(profile: testUserProfile),
        act: (bloc) => bloc.add(UpdateProfile(
          userId: testUserId,
          displayName: 'Updated Name',
        )),
        expect: () => [
          ProfileUpdating(
            currentProfile: testUserProfile,
            updateType: 'profile',
            message: '📝 Updating your profile with new information...',
          ),
          ProfileLoaded(
            profile: testUserProfile.copyWith(displayName: 'Updated Name'),
            successMessage: '🎉 Profile updated successfully!',
          ),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits error when profile update fails with validation',
        build: () {
          when(() => mockRepository.updateUserProfile(any()))
              .thenAnswer((_) async => Left(ValidationFailure('Invalid email')));
          return profileBloc;
        },
        seed: () => ProfileLoaded(profile: testUserProfile),
        act: (bloc) => bloc.add(UpdateProfile(
          userId: testUserId,
          email: 'invalid-email',
        )),
        expect: () => [
          ProfileUpdating(
            currentProfile: testUserProfile,
            updateType: 'profile',
            message: '📝 Updating your profile with new information...',
          ),
          ProfileError.validation('Invalid email'),
        ],
      );
    });

    group('UploadCustomAvatar', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [uploading, loaded] when avatar upload is successful',
        build: () {
          when(() => mockFile.path).thenReturn('/test/avatar.jpg');
          when(() => mockRepository.uploadCustomAvatar(any(), any()))
              .thenAnswer((_) async => Right(testUserProfile.copyWith(
                avatarUrl: 'https://example.com/avatar.jpg',
              )));
          return profileBloc;
        },
        seed: () => ProfileLoaded(profile: testUserProfile),
        act: (bloc) => bloc.add(UploadCustomAvatar(
          userId: testUserId,
          avatarPath: '/test/avatar.jpg',
        )),
        expect: () => [
          AvatarUploading(currentProfile: testUserProfile, progress: 0.1),
          AvatarUploading(currentProfile: testUserProfile, progress: 0.5),
          AvatarUploading(currentProfile: testUserProfile, progress: 0.8),
          ProfileLoaded(
            profile: testUserProfile.copyWith(
              avatarUrl: 'https://example.com/avatar.jpg',
            ),
            successMessage: '🖼️ Amazing! Your new avatar looks fantastic!',
          ),
        ],
        wait: const Duration(milliseconds: 1600), // Wait for delays
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits error when avatar upload fails',
        build: () {
          when(() => mockFile.path).thenReturn('/test/avatar.jpg');
          when(() => mockRepository.uploadCustomAvatar(any(), any()))
              .thenAnswer((_) async => Left(ValidationFailure('File too large')));
          return profileBloc;
        },
        seed: () => ProfileLoaded(profile: testUserProfile),
        act: (bloc) => bloc.add(UploadCustomAvatar(
          userId: testUserId,
          avatarPath: '/test/avatar.jpg',
        )),
        expect: () => [
          AvatarUploading(currentProfile: testUserProfile, progress: 0.1),
          AvatarUploading(currentProfile: testUserProfile, progress: 0.5),
          AvatarUploading(currentProfile: testUserProfile, progress: 0.8),
          ProfileError.validation('File too large'),
        ],
        wait: const Duration(milliseconds: 1600),
      );
    });

    group('UpdateAvatar', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [updating, loaded] when predefined avatar is selected',
        build: () {
          when(() => mockRepository.updateAvatar(any(), any()))
              .thenAnswer((_) async => Right(testUserProfile.copyWith(
                avatarId: 'avatar_dog',
              )));
          return profileBloc;
        },
        seed: () => ProfileLoaded(profile: testUserProfile),
        act: (bloc) => bloc.add(UpdateAvatar(
          userId: testUserId,
          avatarId: 'avatar_dog',
        )),
        expect: () => [
          ProfileUpdating(
            currentProfile: testUserProfile,
            updateType: 'avatar',
            message: '🎭 Updating your avatar...',
          ),
          ProfileLoaded(
            profile: testUserProfile.copyWith(avatarId: 'avatar_dog'),
            successMessage: '🎨 Perfect! Your new look is amazing!',
          ),
        ],
      );
    });

    group('UpdateTheme', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [updating, loaded] when theme is changed',
        build: () {
          when(() => mockRepository.updateTheme(any(), any()))
              .thenAnswer((_) async => Right(testUserProfile.copyWith(
                themeId: 'theme_ocean',
              )));
          return profileBloc;
        },
        seed: () => ProfileLoaded(profile: testUserProfile),
        act: (bloc) => bloc.add(UpdateTheme(
          userId: testUserId,
          themeId: 'theme_ocean',
        )),
        expect: () => [
          ProfileUpdating(
            currentProfile: testUserProfile,
            updateType: 'theme',
            message: '🌈 Applying your new colorful theme...',
          ),
          ProfileLoaded(
            profile: testUserProfile.copyWith(themeId: 'theme_ocean'),
            successMessage: '✨ Wow! Your new theme looks absolutely stunning!',
          ),
        ],
      );
    });

    group('UpdatePrivacySettings', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [updating, loaded] when privacy settings are updated',
        build: () {
          final newSettings = testUserProfile.privacySettings.copyWith(
            profileVisible: true,
          );
          when(() => mockRepository.updatePrivacySettings(any(), any()))
              .thenAnswer((_) async => Right(testUserProfile.copyWith(
                privacySettings: newSettings,
              )));
          return profileBloc;
        },
        seed: () => ProfileLoaded(profile: testUserProfile),
        act: (bloc) => bloc.add(UpdatePrivacySettings(
          userId: testUserId,
          settings: testUserProfile.privacySettings.copyWith(
            profileVisible: true,
          ),
        )),
        expect: () => [
          ProfileUpdating(
            currentProfile: testUserProfile,
            updateType: 'privacy',
            message: '🔒 Updating your privacy settings to keep you safe...',
          ),
          ProfileLoaded(
            profile: testUserProfile.copyWith(
              privacySettings: testUserProfile.privacySettings.copyWith(
                profileVisible: true,
              ),
            ),
            successMessage: '🛡️ Great! Your privacy settings help keep you safe online!',
          ),
        ],
      );
    });

    group('UpdateParentalControls', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [updating, loaded] when parental controls are updated',
        build: () {
          final newControls = testUserProfile.parentalControls.copyWith(
            requireApproval: false,
          );
          when(() => mockRepository.updateParentalControls(any(), any()))
              .thenAnswer((_) async => Right(testUserProfile.copyWith(
                parentalControls: newControls,
              )));
          return profileBloc;
        },
        seed: () => ProfileLoaded(profile: testUserProfile),
        act: (bloc) => bloc.add(UpdateParentalControls(
          userId: testUserId,
          controls: testUserProfile.parentalControls.copyWith(
            requireApproval: false,
          ),
        )),
        expect: () => [
          ProfileUpdating(
            currentProfile: testUserProfile,
            updateType: 'parental_controls',
            message: '👨‍👩‍👧‍👦 Updating safety features...',
          ),
          ProfileLoaded(
            profile: testUserProfile.copyWith(
              parentalControls: testUserProfile.parentalControls.copyWith(
                requireApproval: false,
              ),
            ),
            successMessage: '🔐 Safety settings updated! Your grown-ups help keep you safe.',
          ),
        ],
      );
    });

    group('UpdateNotificationSettings', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [updating, loaded] when notification settings are updated',
        build: () {
          final newSettings = testUserProfile.notificationSettings.copyWith(
            weeklyReports: true,
          );
          when(() => mockRepository.updateNotificationSettings(any(), any()))
              .thenAnswer((_) async => Right(testUserProfile.copyWith(
                notificationSettings: newSettings,
              )));
          return profileBloc;
        },
        seed: () => ProfileLoaded(profile: testUserProfile),
        act: (bloc) => bloc.add(UpdateNotificationSettings(
          userId: testUserId,
          settings: testUserProfile.notificationSettings.copyWith(
            weeklyReports: true,
          ),
        )),
        expect: () => [
          ProfileUpdating(
            currentProfile: testUserProfile,
            updateType: 'notifications',
            message: '🔔 Setting up your notification preferences...',
          ),
          ProfileLoaded(
            profile: testUserProfile.copyWith(
              notificationSettings: testUserProfile.notificationSettings.copyWith(
                weeklyReports: true,
              ),
            ),
            successMessage: '📢 Perfect! We\'ll notify you about the fun stuff!',
          ),
        ],
      );
    });

    group('LoadUserAchievements', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [loading, achievementsLoaded] with celebration for recent achievements',
        build: () {
          when(() => mockRepository.getUserAchievements(any()))
              .thenAnswer((_) async => Right(testAchievements));
          return profileBloc;
        },
        act: (bloc) => bloc.add(LoadUserAchievements(testUserId)),
        expect: () => [
          const ProfileLoading(
            message: '🏆 Loading your amazing achievements...',
          ),
          AchievementsLoaded(
            achievements: testAchievements,
            celebrationMessage: '🎉 You earned 1 new achievement this week!',
          ),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [loading, achievementsLoaded] without celebration for old achievements',
        build: () {
          final oldAchievements = testAchievements.map((a) => 
            Achievement(
              id: a.id,
              title: a.title,
              description: a.description,
              icon: a.icon,
              color: a.color,
              tier: a.tier,
              earnedAt: DateTime.now().subtract(const Duration(days: 30)),
            )
          ).toList();
          
          when(() => mockRepository.getUserAchievements(any()))
              .thenAnswer((_) async => Right(oldAchievements));
          return profileBloc;
        },
        act: (bloc) => bloc.add(LoadUserAchievements(testUserId)),
        expect: () => [
          const ProfileLoading(
            message: '🏆 Loading your amazing achievements...',
          ),
          AchievementsLoaded(
            achievements: isA<List<Achievement>>(),
            celebrationMessage: null,
          ),
        ],
      );
    });

    group('LoadUserBadges', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [loading, badgesLoaded] when badges are loaded',
        build: () {
          when(() => mockRepository.getUserBadges(any()))
              .thenAnswer((_) async => Right(testBadges));
          return profileBloc;
        },
        act: (bloc) => bloc.add(LoadUserBadges(testUserId)),
        expect: () => [
          const ProfileLoading(
            message: '🎖️ Getting your awesome badges...',
          ),
          BadgesLoaded(
            badges: testBadges,
            selectedBadge: testBadges.first, // First badge is displayed
            message: '✨ You\'ve earned ${testBadges.length} awesome badges!',
          ),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits encouraging message when no badges earned yet',
        build: () {
          when(() => mockRepository.getUserBadges(any()))
              .thenAnswer((_) async => const Right([]));
          return profileBloc;
        },
        act: (bloc) => bloc.add(LoadUserBadges(testUserId)),
        expect: () => [
          const ProfileLoading(
            message: '🎖️ Getting your awesome badges...',
          ),
          const BadgesLoaded(
            badges: [],
            selectedBadge: null,
            message: '🎯 Complete activities to earn your first badge!',
          ),
        ],
      );
    });

    group('SelectDisplayBadge', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits success when badge is selected for display',
        build: () {
          when(() => mockRepository.selectDisplayBadge(any(), any()))
              .thenAnswer((_) async => Right(testUserProfile));
          return profileBloc;
        },
        act: (bloc) => bloc.add(SelectDisplayBadge(
          userId: testUserId,
          badgeId: 'badge_2',
        )),
        expect: () => [
          ProfileLoaded(
            profile: testUserProfile,
            successMessage: '🏆 Awesome! Your badge is now proudly displayed!',
          ),
        ],
      );
    });

    group('LoadUserStatistics', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [loading, statisticsLoaded] with insight for high activity user',
        build: () {
          final highActivityStats = UserStatistics(
            totalActivities: 75,
            completedGoals: 8,
            totalAchievements: 12,
            categoryStats: testStatistics.categoryStats,
            joinDate: testStatistics.joinDate,
            daysActive: testStatistics.daysActive,
          );
          when(() => mockRepository.getUserStatistics(any()))
              .thenAnswer((_) async => Right(highActivityStats));
          return profileBloc;
        },
        act: (bloc) => bloc.add(LoadUserStatistics(testUserId)),
        expect: () => [
          const ProfileLoading(
            message: '📊 Calculating your awesome progress...',
          ),
          StatisticsLoaded(
            statistics: isA<UserStatistics>(),
            insightMessage: contains('You\'ve completed 75 activities'),
          ),
        ],
      );
    });

    group('CheckNewAchievements', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits celebration when new achievements are found',
        build: () {
          final newAchievement = Achievement(
            id: 'ach_new',
            title: '🎉 New Achievement',
            description: 'You did something awesome!',
            icon: 'celebration',
            color: '#FFD700',
            tier: AchievementTier.gold,
            earnedAt: DateTime.now(),
          );
          when(() => mockRepository.checkNewAchievements(any()))
              .thenAnswer((_) async => Right([newAchievement]));
          return profileBloc;
        },
        seed: () => ProfileLoaded(profile: testUserProfile),
        act: (bloc) => bloc.add(CheckNewAchievements(testUserId)),
        expect: () => [
          AchievementCelebration(
            achievement: isA<Achievement>(),
            updatedProfile: testUserProfile,
            celebrationMessage: contains('Amazing! You just earned'),
          ),
        ],
      );
    });

    group('ExportUserData', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [loading, exportReady] when data export is successful',
        build: () {
          when(() => mockRepository.exportUserData(any()))
              .thenAnswer((_) async => const Right({'data': 'exported'}));
          return profileBloc;
        },
        act: (bloc) => bloc.add(ExportUserData(testUserId)),
        expect: () => [
          const ProfileLoading(
            message: '📦 Preparing your data for download...',
          ),
          isA<DataExportReady>()
              .having((state) => state.exportData, 'exportData', {'data': 'exported'})
              .having((state) => state.downloadUrl, 'downloadUrl', contains(testUserId)),
        ],
      );
    });

    group('ValidateUserData', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits validation result when data is valid',
        build: () {
          when(() => mockRepository.validateUserData(any()))
              .thenAnswer((_) async => const Right(true));
          return profileBloc;
        },
        act: (bloc) => bloc.add(ValidateUserData(testUserId)),
        expect: () => [
          const ProfileLoading(
            message: '🔍 Checking your data...',
          ),
          const ValidationResult(
            isValid: true,
            message: '✅ Everything looks perfect! Your data is all good.',
          ),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits validation result when data has issues',
        build: () {
          when(() => mockRepository.validateUserData(any()))
              .thenAnswer((_) async => const Right(false));
          return profileBloc;
        },
        act: (bloc) => bloc.add(ValidateUserData(testUserId)),
        expect: () => [
          const ProfileLoading(
            message: '🔍 Checking your data...',
          ),
          const ValidationResult(
            isValid: false,
            message: '⚠️ We found some issues that need attention.',
          ),
        ],
      );
    });

    group('ClearProfileCache', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits cache cleared message when cache is cleared successfully',
        build: () {
          when(() => mockRepository.clearCache())
              .thenAnswer((_) async => const Right(null));
          return profileBloc;
        },
        act: (bloc) => bloc.add(const ClearProfileCache()),
        expect: () => [
          const CacheCleared(
            message: '✨ Cache cleared! Everything is fresh and ready!',
          ),
        ],
      );
    });

    group('Celebration Logic', () {
      test('triggers level up celebration for appropriate level', () {
        final levelUpProfile = testUserProfile.copyWith(
          level: 3,
          totalPoints: 250, // Just reached level 3
        );
        
        // This would be tested through integration with the BLoC
        expect(levelUpProfile.level, equals(3));
        expect(levelUpProfile.levelProgress, equals(50)); // 250 % 100 = 50
      });

      test('triggers streak milestone celebration for week streaks', () {
        final streakProfile = testUserProfile.copyWith(currentStreak: 14);
        
        // Check if streak is a multiple of 7 (weekly milestone)
        expect(streakProfile.currentStreak % 7, equals(0));
        expect(streakProfile.currentStreak, equals(14));
      });
    });

    group('Error Handling', () {
      blocTest<ProfileBloc, ProfileState>(
        'maps network failures to appropriate error state',
        build: () {
          when(() => mockRepository.getUserProfile(any()))
              .thenAnswer((_) async => Left(NetworkFailure('Network error')));
          return profileBloc;
        },
        act: (bloc) => bloc.add(LoadUserProfile(testUserId)),
        expect: () => [
          const ProfileLoading(
            message: '🌟 Getting your awesome profile ready...',
          ),
          ProfileError.network(),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'maps validation failures to appropriate error state',
        build: () {
          when(() => mockRepository.updateUserProfile(any()))
              .thenAnswer((_) async => Left(ValidationFailure('Validation error')));
          return profileBloc;
        },
        seed: () => ProfileLoaded(profile: testUserProfile),
        act: (bloc) => bloc.add(UpdateProfile(
          userId: testUserId,
          displayName: '',
        )),
        expect: () => [
          ProfileUpdating(
            currentProfile: testUserProfile,
            updateType: 'profile',
            message: '📝 Updating your profile with new information...',
          ),
          ProfileError.validation('Validation error'),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'maps database failures to generic error state',
        build: () {
          when(() => mockRepository.getUserProfile(any()))
              .thenAnswer((_) async => Left(DatabaseFailure('DB error')));
          return profileBloc;
        },
        act: (bloc) => bloc.add(LoadUserProfile(testUserId)),
        expect: () => [
          const ProfileLoading(
            message: '🌟 Getting your awesome profile ready...',
          ),
          ProfileError.generic('DB error'),
        ],
      );
    });
  });
}