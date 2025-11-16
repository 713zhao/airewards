import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'api_client.dart';
import '../models/user.dart';
import '../models/task.dart';
import '../models/reward.dart';
import '../models/family.dart';
import '../models/notification.dart';

/// Comprehensive backend service for API integration
class BackendService {
  static bool _initialized = false;
  static StreamController<SyncStatus>? _syncStatusController;
  static Timer? _periodicSyncTimer;

  /// Initialize backend service
  static Future<void> initialize() async {
    if (_initialized) return;

    debugPrint('🔧 Initializing BackendService...');

    try {
      await ApiClient.initialize();
      _syncStatusController = StreamController<SyncStatus>.broadcast();
      _startPeriodicSync();

      _initialized = true;
      debugPrint('✅ BackendService initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize BackendService: $e');
      rethrow;
    }
  }

  /// Get sync status stream
  static Stream<SyncStatus> get syncStatusStream =>
      _syncStatusController?.stream ?? const Stream.empty();

  /// Dispose backend service
  static void dispose() {
    _syncStatusController?.close();
    _periodicSyncTimer?.cancel();
    _initialized = false;
  }

  // ========== Authentication API ==========

  /// Login user
  static Future<AuthResponse> login({
    required String email,
    required String password,
    String? deviceId,
  }) async {
    try {
      final response = await ApiClient.post<Map<String, dynamic>>('auth/login', body: {
        'email': email,
        'password': password,
        'device_id': deviceId,
      });

      if (response.success && response.data != null) {
        final authData = AuthResponse.fromJson(response.data!);
        
        // Set auth token for future requests
        ApiClient.setAuthToken(
          authData.accessToken,
          refreshToken: authData.refreshToken,
        );

        return authData;
      } else {
        throw ApiException(
          response.error?.message ?? 'Login failed',
          code: response.error?.code,
        );
      }
    } catch (e) {
      debugPrint('❌ Login failed: $e');
      rethrow;
    }
  }

  /// Register new user
  static Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
    DateTime? dateOfBirth,
    String? parentEmail,
  }) async {
    try {
      final response = await ApiClient.post<Map<String, dynamic>>('auth/register', body: {
        'email': email,
        'password': password,
        'name': name,
        'date_of_birth': dateOfBirth?.toIso8601String(),
        'parent_email': parentEmail,
      });

      if (response.success && response.data != null) {
        return AuthResponse.fromJson(response.data!);
      } else {
        throw ApiException(
          response.error?.message ?? 'Registration failed',
          code: response.error?.code,
        );
      }
    } catch (e) {
      debugPrint('❌ Registration failed: $e');
      rethrow;
    }
  }

  /// Logout user
  static Future<void> logout() async {
    try {
      await ApiClient.post('auth/logout');
      ApiClient.clearAuth();
    } catch (e) {
      debugPrint('⚠️ Logout error (continuing anyway): $e');
      ApiClient.clearAuth();
    }
  }

  /// Refresh authentication token
  static Future<AuthResponse> refreshToken(String refreshToken) async {
    try {
      final response = await ApiClient.post<Map<String, dynamic>>('auth/refresh', body: {
        'refresh_token': refreshToken,
      });

      if (response.success && response.data != null) {
        return AuthResponse.fromJson(response.data!);
      } else {
        throw ApiException(
          response.error?.message ?? 'Token refresh failed',
          code: response.error?.code,
        );
      }
    } catch (e) {
      debugPrint('❌ Token refresh failed: $e');
      rethrow;
    }
  }

  // ========== User API ==========

  /// Get user profile
  static Future<User> getUserProfile(String userId) async {
    try {
      final response = await ApiClient.get<Map<String, dynamic>>('users/$userId');

      if (response.success && response.data != null) {
        return User.fromJson(response.data!);
      } else {
        throw ApiException(
          response.error?.message ?? 'Failed to get user profile',
          code: response.error?.code,
        );
      }
    } catch (e) {
      debugPrint('❌ Get user profile failed: $e');
      rethrow;
    }
  }

  /// Update user profile
  static Future<User> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    try {
      final response = await ApiClient.put<Map<String, dynamic>>('users/$userId', body: updates);

      if (response.success && response.data != null) {
        return User.fromJson(response.data!);
      } else {
        throw ApiException(
          response.error?.message ?? 'Failed to update user profile',
          code: response.error?.code,
        );
      }
    } catch (e) {
      debugPrint('❌ Update user profile failed: $e');
      rethrow;
    }
  }

  /// Upload user avatar
  static Future<String> uploadUserAvatar(String userId, String imagePath) async {
    try {
      final response = await ApiClient.uploadFile<Map<String, dynamic>>(
        'users/$userId/avatar',
        File(imagePath),
        fieldName: 'avatar',
      );

      if (response.success && response.data != null) {
        return response.data!['avatar_url'];
      } else {
        throw ApiException(
          response.error?.message ?? 'Failed to upload avatar',
          code: response.error?.code,
        );
      }
    } catch (e) {
      debugPrint('❌ Upload avatar failed: $e');
      rethrow;
    }
  }

  // ========== Task API ==========

  /// Get user tasks
  static Future<List<Task>> getUserTasks(String userId, {
    String? status,
    String? category,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (category != null) queryParams['category'] = category;
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final response = await ApiClient.get<List<dynamic>>(
        'users/$userId/tasks',
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        return response.data!.map((json) => Task.fromJson(json)).toList();
      } else {
        throw ApiException(
          response.error?.message ?? 'Failed to get tasks',
          code: response.error?.code,
        );
      }
    } catch (e) {
      debugPrint('❌ Get user tasks failed: $e');
      rethrow;
    }
  }

  /// Create new task
  static Future<Task> createTask(String userId, TaskCreateRequest request) async {
    try {
      final response = await ApiClient.post<Map<String, dynamic>>(
        'users/$userId/tasks',
        body: request.toJson(),
      );

      if (response.success && response.data != null) {
        return Task.fromJson(response.data!);
      } else {
        throw ApiException(
          response.error?.message ?? 'Failed to create task',
          code: response.error?.code,
        );
      }
    } catch (e) {
      debugPrint('❌ Create task failed: $e');
      rethrow;
    }
  }

  /// Update task
  static Future<Task> updateTask(String taskId, Map<String, dynamic> updates) async {
    try {
      final response = await ApiClient.put<Map<String, dynamic>>('tasks/$taskId', body: updates);

      if (response.success && response.data != null) {
        return Task.fromJson(response.data!);
      } else {
        throw ApiException(
          response.error?.message ?? 'Failed to update task',
          code: response.error?.code,
        );
      }
    } catch (e) {
      debugPrint('❌ Update task failed: $e');
      rethrow;
    }
  }

  /// Complete task
  static Future<TaskCompletionResponse> completeTask(String taskId, {
    String? notes,
    List<String>? attachments,
  }) async {
    try {
      final response = await ApiClient.post<Map<String, dynamic>>('tasks/$taskId/complete', body: {
        'notes': notes,
        'attachments': attachments,
        'completed_at': DateTime.now().toIso8601String(),
      });

      if (response.success && response.data != null) {
        return TaskCompletionResponse.fromJson(response.data!);
      } else {
        throw ApiException(
          response.error?.message ?? 'Failed to complete task',
          code: response.error?.code,
        );
      }
    } catch (e) {
      debugPrint('❌ Complete task failed: $e');
      rethrow;
    }
  }

  // ========== Rewards API ==========

  /// Get available rewards
  static Future<List<Reward>> getRewards({
    String? category,
    int? minPoints,
    int? maxPoints,
    bool? available,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (category != null) queryParams['category'] = category;
      if (minPoints != null) queryParams['min_points'] = minPoints.toString();
      if (maxPoints != null) queryParams['max_points'] = maxPoints.toString();
      if (available != null) queryParams['available'] = available.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final response = await ApiClient.get<List<dynamic>>(
        'rewards',
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        return response.data!.map((json) => Reward.fromJson(json)).toList();
      } else {
        throw ApiException(
          response.error?.message ?? 'Failed to get rewards',
          code: response.error?.code,
        );
      }
    } catch (e) {
      debugPrint('❌ Get rewards failed: $e');
      rethrow;
    }
  }

  /// Redeem reward
  static Future<RedemptionResponse> redeemReward(String userId, String rewardId) async {
    try {
      final response = await ApiClient.post<Map<String, dynamic>>('users/$userId/redemptions', body: {
        'reward_id': rewardId,
        'redeemed_at': DateTime.now().toIso8601String(),
      });

      if (response.success && response.data != null) {
        return RedemptionResponse.fromJson(response.data!);
      } else {
        throw ApiException(
          response.error?.message ?? 'Failed to redeem reward',
          code: response.error?.code,
        );
      }
    } catch (e) {
      debugPrint('❌ Redeem reward failed: $e');
      rethrow;
    }
  }

  /// Get user redemptions
  static Future<List<Redemption>> getUserRedemptions(String userId, {
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final response = await ApiClient.get<List<dynamic>>(
        'users/$userId/redemptions',
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        return response.data!.map((json) => Redemption.fromJson(json)).toList();
      } else {
        throw ApiException(
          response.error?.message ?? 'Failed to get redemptions',
          code: response.error?.code,
        );
      }
    } catch (e) {
      debugPrint('❌ Get user redemptions failed: $e');
      rethrow;
    }
  }

  // ========== Family API ==========

  /// Get user families
  static Future<List<Family>> getUserFamilies(String userId) async {
    try {
      final response = await ApiClient.get<List<dynamic>>('users/$userId/families');

      if (response.success && response.data != null) {
        return response.data!.map((json) => Family.fromJson(json)).toList();
      } else {
        throw ApiException(
          response.error?.message ?? 'Failed to get families',
          code: response.error?.code,
        );
      }
    } catch (e) {
      debugPrint('❌ Get user families failed: $e');
      rethrow;
    }
  }

  /// Create family
  static Future<Family> createFamily(CreateFamilyRequest request) async {
    try {
      final response = await ApiClient.post<Map<String, dynamic>>('families', body: request.toJson());

      if (response.success && response.data != null) {
        return Family.fromJson(response.data!);
      } else {
        throw ApiException(
          response.error?.message ?? 'Failed to create family',
          code: response.error?.code,
        );
      }
    } catch (e) {
      debugPrint('❌ Create family failed: $e');
      rethrow;
    }
  }

  /// Join family
  static Future<FamilyMembership> joinFamily(String familyId, String inviteCode) async {
    try {
      final response = await ApiClient.post<Map<String, dynamic>>('families/$familyId/join', body: {
        'invite_code': inviteCode,
      });

      if (response.success && response.data != null) {
        return FamilyMembership.fromJson(response.data!);
      } else {
        throw ApiException(
          response.error?.message ?? 'Failed to join family',
          code: response.error?.code,
        );
      }
    } catch (e) {
      debugPrint('❌ Join family failed: $e');
      rethrow;
    }
  }

  // ========== Notifications API ==========

  /// Get user notifications
  static Future<List<AppNotification>> getUserNotifications(String userId, {
    bool? read,
    String? type,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (read != null) queryParams['read'] = read.toString();
      if (type != null) queryParams['type'] = type;
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final response = await ApiClient.get<List<dynamic>>(
        'users/$userId/notifications',
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        return response.data!.map((json) => AppNotification.fromJson(json)).toList();
      } else {
        throw ApiException(
          response.error?.message ?? 'Failed to get notifications',
          code: response.error?.code,
        );
      }
    } catch (e) {
      debugPrint('❌ Get user notifications failed: $e');
      rethrow;
    }
  }

  /// Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final response = await ApiClient.put('notifications/$notificationId/read');

      if (!response.success) {
        throw ApiException(
          response.error?.message ?? 'Failed to mark notification as read',
          code: response.error?.code,
        );
      }
    } catch (e) {
      debugPrint('❌ Mark notification as read failed: $e');
      rethrow;
    }
  }

  // ========== Sync Operations ==========

  /// Perform full data synchronization
  static Future<SyncResult> performFullSync() async {
    _updateSyncStatus(SyncStatus.syncing);

    try {
      debugPrint('🔄 Starting full data synchronization...');

      final syncResult = SyncResult(
        startTime: DateTime.now(),
        success: true,
      );

      // Sync user data
      try {
        await _syncUserData();
        syncResult.userDataSynced = true;
      } catch (e) {
        syncResult.errors.add('User data sync failed: $e');
      }

      // Sync tasks
      try {
        await _syncTasks();
        syncResult.tasksSynced = true;
      } catch (e) {
        syncResult.errors.add('Tasks sync failed: $e');
      }

      // Sync rewards
      try {
        await _syncRewards();
        syncResult.rewardsSynced = true;
      } catch (e) {
        syncResult.errors.add('Rewards sync failed: $e');
      }

      // Sync notifications
      try {
        await _syncNotifications();
        syncResult.notificationsSynced = true;
      } catch (e) {
        syncResult.errors.add('Notifications sync failed: $e');
      }

      syncResult.endTime = DateTime.now();
      syncResult.success = syncResult.errors.isEmpty;

      _updateSyncStatus(syncResult.success ? SyncStatus.completed : SyncStatus.failed);

      debugPrint('✅ Full synchronization completed: ${syncResult.errors.isEmpty ? 'SUCCESS' : 'WITH ERRORS'}');
      return syncResult;

    } catch (e) {
      debugPrint('❌ Full synchronization failed: $e');
      _updateSyncStatus(SyncStatus.failed);
      
      return SyncResult(
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        success: false,
        errors: ['Full sync failed: $e'],
      );
    }
  }

  /// Start periodic synchronization
  static void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      performFullSync();
        });
  }

  /// Update sync status
  static void _updateSyncStatus(SyncStatus status) {
    _syncStatusController?.add(status);
  }

  /// Sync user data
  static Future<void> _syncUserData() async {
    // Implementation would sync user profile changes
    debugPrint('🔄 Syncing user data...');
  }

  /// Sync tasks
  static Future<void> _syncTasks() async {
    // Implementation would sync task changes
    debugPrint('🔄 Syncing tasks...');
  }

  /// Sync rewards
  static Future<void> _syncRewards() async {
    // Implementation would sync reward catalog
    debugPrint('🔄 Syncing rewards...');
  }

  /// Sync notifications
  static Future<void> _syncNotifications() async {
    // Implementation would sync notifications
    debugPrint('🔄 Syncing notifications...');
  }
}

// ========== Supporting Models ==========

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final User user;
  final DateTime expiresAt;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.expiresAt,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      user: User.fromJson(json['user']),
      expiresAt: DateTime.parse(json['expires_at']),
    );
  }
}

class TaskCreateRequest {
  final String title;
  final String description;
  final String category;
  final int pointValue;
  final DateTime? dueDate;
  final List<String> tags;

  const TaskCreateRequest({
    required this.title,
    required this.description,
    required this.category,
    required this.pointValue,
    this.dueDate,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'category': category,
    'point_value': pointValue,
    'due_date': dueDate?.toIso8601String(),
    'tags': tags,
  };
}

class TaskCompletionResponse {
  final Task task;
  final int pointsEarned;
  final List<Achievement> newAchievements;

  const TaskCompletionResponse({
    required this.task,
    required this.pointsEarned,
    required this.newAchievements,
  });

  factory TaskCompletionResponse.fromJson(Map<String, dynamic> json) {
    return TaskCompletionResponse(
      task: Task.fromJson(json['task']),
      pointsEarned: json['points_earned'],
      newAchievements: (json['new_achievements'] as List<dynamic>)
          .map((a) => Achievement.fromJson(a))
          .toList(),
    );
  }
}

class RedemptionResponse {
  final Redemption redemption;
  final int remainingPoints;

  const RedemptionResponse({
    required this.redemption,
    required this.remainingPoints,
  });

  factory RedemptionResponse.fromJson(Map<String, dynamic> json) {
    return RedemptionResponse(
      redemption: Redemption.fromJson(json['redemption']),
      remainingPoints: json['remaining_points'],
    );
  }
}

class CreateFamilyRequest {
  final String name;
  final String description;
  final Map<String, dynamic> settings;

  const CreateFamilyRequest({
    required this.name,
    required this.description,
    this.settings = const {},
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'settings': settings,
  };
}

class SyncResult {
  final DateTime startTime;
  DateTime? endTime;
  bool success;
  bool userDataSynced = false;
  bool tasksSynced = false;
  bool rewardsSynced = false;
  bool notificationsSynced = false;
  final List<String> errors = [];

  SyncResult({
    required this.startTime,
    this.endTime,
    this.success = false,
    List<String>? errors,
  }) {
    if (errors != null) {
      this.errors.addAll(errors);
    }
  }

  Duration? get duration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    return null;
  }
}

enum SyncStatus {
  idle,
  syncing,
  completed,
  failed,
}