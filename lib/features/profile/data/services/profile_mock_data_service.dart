import 'dart:async';
import 'dart:math' as math;
import 'dart:io';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';

/// Mock user profile entity for kid-friendly profile management
class UserProfile {
  final String id;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final String? avatarId;
  final String themeId;
  final int totalPoints;
  final int currentStreak;
  final int longestStreak;
  final int level;
  final DateTime createdAt;
  final DateTime lastActive;
  final UserPrivacySettings privacySettings;
  final ParentalControls parentalControls;
  final NotificationSettings notificationSettings;
  final Map<String, dynamic> customizations;

  const UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    this.avatarId,
    this.themeId = 'default',
    this.totalPoints = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.level = 1,
    required this.createdAt,
    required this.lastActive,
    required this.privacySettings,
    required this.parentalControls,
    required this.notificationSettings,
    this.customizations = const {},
  });

  UserProfile copyWith({
    String? id,
    String? displayName,
    String? email,
    String? avatarUrl,
    String? avatarId,
    String? themeId,
    int? totalPoints,
    int? currentStreak,
    int? longestStreak,
    int? level,
    DateTime? createdAt,
    DateTime? lastActive,
    UserPrivacySettings? privacySettings,
    ParentalControls? parentalControls,
    NotificationSettings? notificationSettings,
    Map<String, dynamic>? customizations,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarId: avatarId ?? this.avatarId,
      themeId: themeId ?? this.themeId,
      totalPoints: totalPoints ?? this.totalPoints,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      level: level ?? this.level,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      privacySettings: privacySettings ?? this.privacySettings,
      parentalControls: parentalControls ?? this.parentalControls,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      customizations: customizations ?? this.customizations,
    );
  }

  /// Calculate current level based on points
  int get calculatedLevel => (totalPoints / 100).floor() + 1;

  /// Get experience points within current level
  int get levelProgress => totalPoints % 100;

  /// Get points needed for next level
  int get pointsToNextLevel => 100 - levelProgress;
}

/// Supporting profile entities
class UserPrivacySettings {
  final bool profileVisible;
  final bool achievementsVisible;
  final bool allowFriendRequests;
  final bool dataCollection;

  const UserPrivacySettings({
    this.profileVisible = false,
    this.achievementsVisible = true,
    this.allowFriendRequests = false,
    this.dataCollection = false,
  });

  UserPrivacySettings copyWith({
    bool? profileVisible,
    bool? achievementsVisible,
    bool? allowFriendRequests,
    bool? dataCollection,
  }) {
    return UserPrivacySettings(
      profileVisible: profileVisible ?? this.profileVisible,
      achievementsVisible: achievementsVisible ?? this.achievementsVisible,
      allowFriendRequests: allowFriendRequests ?? this.allowFriendRequests,
      dataCollection: dataCollection ?? this.dataCollection,
    );
  }
}

class ParentalControls {
  final bool enabled;
  final List<String> blockedFeatures;
  final bool requireApproval;
  final String? parentEmail;
  final Map<String, bool> permissions;

  const ParentalControls({
    this.enabled = true,
    this.blockedFeatures = const [],
    this.requireApproval = true,
    this.parentEmail,
    this.permissions = const {},
  });

  ParentalControls copyWith({
    bool? enabled,
    List<String>? blockedFeatures,
    bool? requireApproval,
    String? parentEmail,
    Map<String, bool>? permissions,
  }) {
    return ParentalControls(
      enabled: enabled ?? this.enabled,
      blockedFeatures: blockedFeatures ?? this.blockedFeatures,
      requireApproval: requireApproval ?? this.requireApproval,
      parentEmail: parentEmail ?? this.parentEmail,
      permissions: permissions ?? this.permissions,
    );
  }
}

class NotificationSettings {
  final bool achievementNotifications;
  final bool goalReminders;
  final bool streakReminders;
  final bool weeklyReports;
  final bool celebrationSounds;

  const NotificationSettings({
    this.achievementNotifications = true,
    this.goalReminders = true,
    this.streakReminders = true,
    this.weeklyReports = false,
    this.celebrationSounds = true,
  });

  NotificationSettings copyWith({
    bool? achievementNotifications,
    bool? goalReminders,
    bool? streakReminders,
    bool? weeklyReports,
    bool? celebrationSounds,
  }) {
    return NotificationSettings(
      achievementNotifications: achievementNotifications ?? this.achievementNotifications,
      goalReminders: goalReminders ?? this.goalReminders,
      streakReminders: streakReminders ?? this.streakReminders,
      weeklyReports: weeklyReports ?? this.weeklyReports,
      celebrationSounds: celebrationSounds ?? this.celebrationSounds,
    );
  }
}

class UserStatistics {
  final int totalActivities;
  final int completedGoals;
  final int totalAchievements;
  final Map<String, int> categoryStats;
  final DateTime joinDate;
  final int daysActive;

  const UserStatistics({
    required this.totalActivities,
    required this.completedGoals,
    required this.totalAchievements,
    required this.categoryStats,
    required this.joinDate,
    required this.daysActive,
  });
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String color;
  final AchievementTier tier;
  final DateTime earnedAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.tier,
    required this.earnedAt,
  });
}

class Badge {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String color;
  final DateTime earnedAt;
  final bool isDisplayed;

  const Badge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.earnedAt,
    this.isDisplayed = false,
  });

  Badge copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    String? color,
    DateTime? earnedAt,
    bool? isDisplayed,
  }) {
    return Badge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      earnedAt: earnedAt ?? this.earnedAt,
      isDisplayed: isDisplayed ?? this.isDisplayed,
    );
  }
}

class AppTheme {
  final String id;
  final String name;
  final String primaryColor;
  final String accentColor;
  final String description;
  final bool isUnlocked;

  const AppTheme({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.accentColor,
    required this.description,
    this.isUnlocked = false,
  });
}

class Avatar {
  final String id;
  final String name;
  final String imageUrl;
  final String category;
  final bool isUnlocked;

  const Avatar({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.category,
    this.isUnlocked = false,
  });
}

enum AchievementTier { bronze, silver, gold, platinum, diamond }

/// Mock data service for profile management with kid-friendly features
class ProfileMockDataService {
  static final ProfileMockDataService _instance = ProfileMockDataService._internal();
  factory ProfileMockDataService() => _instance;
  ProfileMockDataService._internal();

  final math.Random _random = math.Random();

  // Mock data storage
  final Map<String, UserProfile> _userProfiles = {};
  final Map<String, List<Achievement>> _userAchievements = {};
  final Map<String, List<Badge>> _userBadges = {};
  final Map<String, UserStatistics> _userStatistics = {};

  // Stream controllers for real-time updates
  final Map<String, StreamController<UserProfile>> _profileStreams = {};

  /// Initialize mock profile data for a user
  void initializeMockProfileForUser(String userId) {
    if (!_userProfiles.containsKey(userId)) {
      _userProfiles[userId] = _generateMockProfile(userId);
    }
    if (!_userAchievements.containsKey(userId)) {
      _userAchievements[userId] = _generateMockAchievements();
    }
    if (!_userBadges.containsKey(userId)) {
      _userBadges[userId] = _generateMockBadges();
    }
    if (!_userStatistics.containsKey(userId)) {
      _userStatistics[userId] = _generateMockStatistics();
    }
  }

  /// Get user profile
  Future<Either<Failure, UserProfile>> getUserProfile(String userId) async {
    await _simulateNetworkDelay();
    
    initializeMockProfileForUser(userId);
    
    try {
      final profile = _userProfiles[userId];
      if (profile != null) {
        return Right(profile);
      } else {
        return Left(DatabaseFailure('Profile not found for user: $userId'));
      }
    } catch (e) {
      return Left(DatabaseFailure('Failed to get user profile: $e'));
    }
  }

  /// Update user profile
  Future<Either<Failure, UserProfile>> updateUserProfile(
    Map<String, dynamic> updates,
  ) async {
    await _simulateNetworkDelay();
    
    try {
      final userId = updates['userId'] as String?;
      if (userId == null) {
        return Left(ValidationFailure('User ID is required'));
      }

      final currentProfile = _userProfiles[userId];
      if (currentProfile == null) {
        return Left(DatabaseFailure('Profile not found'));
      }

      final updatedProfile = currentProfile.copyWith(
        displayName: updates['displayName'] as String?,
        email: updates['email'] as String?,
        themeId: updates['themeId'] as String?,
        customizations: updates['customizations'] as Map<String, dynamic>?,
        lastActive: DateTime.now(),
      );

      _userProfiles[userId] = updatedProfile;
      _notifyProfileUpdate(userId, updatedProfile);

      return Right(updatedProfile);
    } catch (e) {
      return Left(DatabaseFailure('Failed to update profile: $e'));
    }
  }

  /// Upload custom avatar
  Future<Either<Failure, UserProfile>> uploadCustomAvatar(
    String userId,
    File avatarFile,
  ) async {
    await _simulateNetworkDelay(duration: 2000); // Simulate upload time
    
    try {
      final currentProfile = _userProfiles[userId];
      if (currentProfile == null) {
        return Left(DatabaseFailure('Profile not found'));
      }

      // Simulate avatar upload and get URL
      final mockAvatarUrl = 'https://mock-cdn.example.com/avatars/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final updatedProfile = currentProfile.copyWith(
        avatarUrl: mockAvatarUrl,
        avatarId: null, // Clear predefined avatar ID
        lastActive: DateTime.now(),
      );

      _userProfiles[userId] = updatedProfile;
      _notifyProfileUpdate(userId, updatedProfile);

      return Right(updatedProfile);
    } catch (e) {
      return Left(DatabaseFailure('Failed to upload avatar: $e'));
    }
  }

  /// Update avatar with predefined avatar
  Future<Either<Failure, UserProfile>> updateAvatar(
    String userId,
    String avatarId,
  ) async {
    await _simulateNetworkDelay();
    
    try {
      final currentProfile = _userProfiles[userId];
      if (currentProfile == null) {
        return Left(DatabaseFailure('Profile not found'));
      }

      final updatedProfile = currentProfile.copyWith(
        avatarId: avatarId,
        avatarUrl: null, // Clear custom avatar URL
        lastActive: DateTime.now(),
      );

      _userProfiles[userId] = updatedProfile;
      _notifyProfileUpdate(userId, updatedProfile);

      return Right(updatedProfile);
    } catch (e) {
      return Left(DatabaseFailure('Failed to update avatar: $e'));
    }
  }

  /// Update theme
  Future<Either<Failure, UserProfile>> updateTheme(
    String userId,
    String themeId,
  ) async {
    await _simulateNetworkDelay();
    
    try {
      final currentProfile = _userProfiles[userId];
      if (currentProfile == null) {
        return Left(DatabaseFailure('Profile not found'));
      }

      final updatedProfile = currentProfile.copyWith(
        themeId: themeId,
        lastActive: DateTime.now(),
      );

      _userProfiles[userId] = updatedProfile;
      _notifyProfileUpdate(userId, updatedProfile);

      return Right(updatedProfile);
    } catch (e) {
      return Left(DatabaseFailure('Failed to update theme: $e'));
    }
  }

  /// Update privacy settings
  Future<Either<Failure, UserProfile>> updatePrivacySettings(
    String userId,
    UserPrivacySettings settings,
  ) async {
    await _simulateNetworkDelay();
    
    try {
      final currentProfile = _userProfiles[userId];
      if (currentProfile == null) {
        return Left(DatabaseFailure('Profile not found'));
      }

      final updatedProfile = currentProfile.copyWith(
        privacySettings: settings,
        lastActive: DateTime.now(),
      );

      _userProfiles[userId] = updatedProfile;
      _notifyProfileUpdate(userId, updatedProfile);

      return Right(updatedProfile);
    } catch (e) {
      return Left(DatabaseFailure('Failed to update privacy settings: $e'));
    }
  }

  /// Update parental controls
  Future<Either<Failure, UserProfile>> updateParentalControls(
    String userId,
    ParentalControls controls,
  ) async {
    await _simulateNetworkDelay();
    
    try {
      final currentProfile = _userProfiles[userId];
      if (currentProfile == null) {
        return Left(DatabaseFailure('Profile not found'));
      }

      final updatedProfile = currentProfile.copyWith(
        parentalControls: controls,
        lastActive: DateTime.now(),
      );

      _userProfiles[userId] = updatedProfile;
      _notifyProfileUpdate(userId, updatedProfile);

      return Right(updatedProfile);
    } catch (e) {
      return Left(DatabaseFailure('Failed to update parental controls: $e'));
    }
  }

  /// Update notification settings
  Future<Either<Failure, UserProfile>> updateNotificationSettings(
    String userId,
    NotificationSettings settings,
  ) async {
    await _simulateNetworkDelay();
    
    try {
      final currentProfile = _userProfiles[userId];
      if (currentProfile == null) {
        return Left(DatabaseFailure('Profile not found'));
      }

      final updatedProfile = currentProfile.copyWith(
        notificationSettings: settings,
        lastActive: DateTime.now(),
      );

      _userProfiles[userId] = updatedProfile;
      _notifyProfileUpdate(userId, updatedProfile);

      return Right(updatedProfile);
    } catch (e) {
      return Left(DatabaseFailure('Failed to update notification settings: $e'));
    }
  }

  /// Get user achievements
  Future<Either<Failure, List<Achievement>>> getUserAchievements(String userId) async {
    await _simulateNetworkDelay();
    
    initializeMockProfileForUser(userId);
    
    try {
      return Right(_userAchievements[userId] ?? []);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get user achievements: $e'));
    }
  }

  /// Get user badges
  Future<Either<Failure, List<Badge>>> getUserBadges(String userId) async {
    await _simulateNetworkDelay();
    
    initializeMockProfileForUser(userId);
    
    try {
      return Right(_userBadges[userId] ?? []);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get user badges: $e'));
    }
  }

  /// Select display badge
  Future<Either<Failure, UserProfile>> selectDisplayBadge(
    String userId,
    String badgeId,
  ) async {
    await _simulateNetworkDelay();
    
    try {
      final userBadges = _userBadges[userId] ?? [];
      
      // Update badges - set selected badge as displayed, others as not displayed
      final updatedBadges = userBadges.map((badge) {
        return badge.copyWith(isDisplayed: badge.id == badgeId);
      }).toList();
      
      _userBadges[userId] = updatedBadges;

      final currentProfile = _userProfiles[userId];
      if (currentProfile != null) {
        final updatedProfile = currentProfile.copyWith(lastActive: DateTime.now());
        _userProfiles[userId] = updatedProfile;
        _notifyProfileUpdate(userId, updatedProfile);
        return Right(updatedProfile);
      } else {
        return Left(DatabaseFailure('Profile not found'));
      }
    } catch (e) {
      return Left(DatabaseFailure('Failed to select display badge: $e'));
    }
  }

  /// Get user statistics
  Future<Either<Failure, UserStatistics>> getUserStatistics(String userId) async {
    await _simulateNetworkDelay();
    
    initializeMockProfileForUser(userId);
    
    try {
      return Right(_userStatistics[userId]!);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get user statistics: $e'));
    }
  }

  /// Get available themes
  Future<Either<Failure, List<AppTheme>>> getAvailableThemes() async {
    await _simulateNetworkDelay();
    
    try {
      final themes = _generateMockThemes();
      return Right(themes);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get available themes: $e'));
    }
  }

  /// Get available avatars
  Future<Either<Failure, List<Avatar>>> getAvailableAvatars() async {
    await _simulateNetworkDelay();
    
    try {
      final avatars = _generateMockAvatars();
      return Right(avatars);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get available avatars: $e'));
    }
  }

  /// Check for new achievements
  Future<Either<Failure, List<Achievement>>> checkNewAchievements(String userId) async {
    await _simulateNetworkDelay();
    
    try {
      // Simulate checking for new achievements based on user activity
      // In a real implementation, this would analyze user data
      
      if (_random.nextDouble() > 0.8) {
        // 20% chance of new achievement
        final newAchievement = Achievement(
          id: 'new_${DateTime.now().millisecondsSinceEpoch}',
          title: '🌟 Amazing Progress!',
          description: 'You\'re doing incredible work!',
          icon: 'star',
          color: '#FFD700',
          tier: AchievementTier.gold,
          earnedAt: DateTime.now(),
        );
        
        _userAchievements[userId] = (_userAchievements[userId] ?? [])..add(newAchievement);
        
        return Right([newAchievement]);
      }
      
      return const Right([]);
    } catch (e) {
      return Left(DatabaseFailure('Failed to check new achievements: $e'));
    }
  }

  /// Watch user profile for real-time updates
  Stream<UserProfile> watchUserProfile(String userId) {
    initializeMockProfileForUser(userId);
    
    if (!_profileStreams.containsKey(userId)) {
      _profileStreams[userId] = StreamController<UserProfile>.broadcast();
    }
    
    return _profileStreams[userId]!.stream;
  }

  /// Generate mock profile data
  UserProfile _generateMockProfile(String userId) {
    final names = ['Alex', 'Sam', 'Jordan', 'Casey', 'Taylor', 'Morgan', 'Riley', 'Avery'];
    final name = names[_random.nextInt(names.length)];
    
    return UserProfile(
      id: userId,
      displayName: name,
      email: '${name.toLowerCase()}@example.com',
      avatarId: 'avatar_${_random.nextInt(10)}',
      themeId: 'theme_${_random.nextInt(5)}',
      totalPoints: _random.nextInt(500) + 100,
      currentStreak: _random.nextInt(20) + 1,
      longestStreak: _random.nextInt(50) + 10,
      createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(90) + 30)),
      lastActive: DateTime.now().subtract(Duration(hours: _random.nextInt(24))),
      privacySettings: UserPrivacySettings(
        profileVisible: false,
        achievementsVisible: true,
        allowFriendRequests: false,
        dataCollection: false,
      ),
      parentalControls: ParentalControls(
        enabled: true,
        blockedFeatures: const ['social', 'chat'],
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
      customizations: {
        'favoriteColor': '#FF6B6B',
        'preferredAnimation': 'bouncy',
        'soundEnabled': true,
      },
    );
  }

  List<Achievement> _generateMockAchievements() {
    return [
      Achievement(
        id: 'ach_1',
        title: '🌟 First Steps',
        description: 'Earned your first points!',
        icon: 'star',
        color: '#FFD700',
        tier: AchievementTier.bronze,
        earnedAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      Achievement(
        id: 'ach_2',
        title: '🔥 Streak Starter',
        description: 'Started your first streak!',
        icon: 'local_fire_department',
        color: '#FF6347',
        tier: AchievementTier.bronze,
        earnedAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      Achievement(
        id: 'ach_3',
        title: '💎 Point Collector',
        description: 'Collected 100 points!',
        icon: 'diamond',
        color: '#87CEEB',
        tier: AchievementTier.silver,
        earnedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }

  List<Badge> _generateMockBadges() {
    return [
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
      ),
    ];
  }

  UserStatistics _generateMockStatistics() {
    return UserStatistics(
      totalActivities: _random.nextInt(200) + 50,
      completedGoals: _random.nextInt(10) + 3,
      totalAchievements: _random.nextInt(15) + 5,
      categoryStats: {
        'Learning': _random.nextInt(50) + 10,
        'Chores': _random.nextInt(40) + 8,
        'Reading': _random.nextInt(30) + 5,
        'Exercise': _random.nextInt(25) + 5,
        'Creativity': _random.nextInt(20) + 3,
      },
      joinDate: DateTime.now().subtract(Duration(days: _random.nextInt(90) + 30)),
      daysActive: _random.nextInt(60) + 20,
    );
  }

  List<AppTheme> _generateMockThemes() {
    return [
      const AppTheme(
        id: 'theme_default',
        name: '🌈 Rainbow Fun',
        primaryColor: '#FF6B6B',
        accentColor: '#4ECDC4',
        description: 'Bright and colorful theme perfect for kids!',
        isUnlocked: true,
      ),
      const AppTheme(
        id: 'theme_ocean',
        name: '🌊 Ocean Adventure',
        primaryColor: '#45B7D1',
        accentColor: '#96CEB4',
        description: 'Dive into an ocean of fun!',
        isUnlocked: true,
      ),
      const AppTheme(
        id: 'theme_space',
        name: '🚀 Space Explorer',
        primaryColor: '#6C5CE7',
        accentColor: '#A29BFE',
        description: 'Blast off to the stars!',
        isUnlocked: false,
      ),
    ];
  }

  List<Avatar> _generateMockAvatars() {
    return [
      const Avatar(
        id: 'avatar_cat',
        name: '🐱 Friendly Cat',
        imageUrl: 'assets/avatars/cat.png',
        category: 'animals',
        isUnlocked: true,
      ),
      const Avatar(
        id: 'avatar_dog',
        name: '🐶 Happy Dog',
        imageUrl: 'assets/avatars/dog.png',
        category: 'animals',
        isUnlocked: true,
      ),
      const Avatar(
        id: 'avatar_robot',
        name: '🤖 Cool Robot',
        imageUrl: 'assets/avatars/robot.png',
        category: 'tech',
        isUnlocked: false,
      ),
    ];
  }

  /// Notify profile update to streams
  void _notifyProfileUpdate(String userId, UserProfile profile) {
    _profileStreams[userId]?.add(profile);
  }

  /// Simulate network delay
  Future<void> _simulateNetworkDelay({int duration = 300}) async {
    await Future.delayed(Duration(milliseconds: duration + _random.nextInt(200)));
  }

  /// Dispose resources
  void dispose() {
    for (final controller in _profileStreams.values) {
      controller.close();
    }
    _profileStreams.clear();
  }
}