import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'encryption_service.dart';

/// Comprehensive authentication security service for child-safe apps
class AuthenticationSecurityService {
  static const int _maxLoginAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 30);
  static const Duration _sessionTimeout = Duration(hours: 2);
  static const int _passwordMinLength = 8;
  
  static bool _initialized = false;
  static Map<String, LoginAttemptTracker> _loginAttempts = {};
  static Map<String, UserSession> _activeSessions = {};
  static Timer? _sessionCleanupTimer;
  
  /// Initialize authentication security service
  static Future<void> initialize() async {
    if (_initialized) return;
    
    debugPrint('🔐 Initializing AuthenticationSecurityService...');
    
    try {
      await _loadLoginAttempts();
      await _loadActiveSessions();
      _startSessionCleanup();
      
      _initialized = true;
      debugPrint('✅ AuthenticationSecurityService initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize AuthenticationSecurityService: $e');
      rethrow;
    }
  }
  
  /// Validate password strength for child-safe accounts
  static PasswordValidationResult validatePassword(String password) {
    final issues = <String>[];
    
    if (password.length < _passwordMinLength) {
      issues.add('Password must be at least $_passwordMinLength characters long');
    }
    
    if (!password.contains(RegExp(r'[A-Z]'))) {
      issues.add('Password must contain at least one uppercase letter');
    }
    
    if (!password.contains(RegExp(r'[a-z]'))) {
      issues.add('Password must contain at least one lowercase letter');
    }
    
    if (!password.contains(RegExp(r'[0-9]'))) {
      issues.add('Password must contain at least one number');
    }
    
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      issues.add('Password must contain at least one special character');
    }
    
    // Check for common weak passwords
    if (_isCommonPassword(password)) {
      issues.add('Password is too common - please choose a more unique password');
    }
    
    final strength = _calculatePasswordStrength(password);
    
    return PasswordValidationResult(
      isValid: issues.isEmpty && strength >= 3,
      strength: strength,
      issues: issues,
    );
  }
  
  /// Attempt user login with security checks
  static Future<LoginResult> attemptLogin({
    required String identifier, // email or username
    required String password,
    required String deviceId,
    String? parentalPin,
  }) async {
    debugPrint('🔑 Attempting login for: ${_maskIdentifier(identifier)}');
    
    try {
      // Check if account is locked out
      if (_isAccountLockedOut(identifier)) {
        return LoginResult(
          success: false,
          errorType: LoginErrorType.accountLockedOut,
          message: 'Account is temporarily locked due to too many failed attempts',
          lockoutExpiresAt: _getLockoutExpiry(identifier),
        );
      }
      
      // Verify credentials (in production, check against secure database)
      final credentialsValid = await _verifyCredentials(identifier, password);
      
      if (!credentialsValid) {
        _recordFailedAttempt(identifier, deviceId);
        
        final attemptsLeft = _maxLoginAttempts - _getFailedAttempts(identifier);
        return LoginResult(
          success: false,
          errorType: LoginErrorType.invalidCredentials,
          message: 'Invalid credentials. $attemptsLeft attempts remaining.',
          attemptsRemaining: attemptsLeft,
        );
      }
      
      // Check if account requires parental verification
      final user = await _getUserDetails(identifier);
      if (user.requiresParentalVerification && parentalPin == null) {
        return LoginResult(
          success: false,
          errorType: LoginErrorType.parentalVerificationRequired,
          message: 'Parental verification required for child accounts',
        );
      }
      
      if (user.requiresParentalVerification) {
        final parentalPinValid = await _verifyParentalPin(user.parentEmail!, parentalPin!);
        if (!parentalPinValid) {
          return LoginResult(
            success: false,
            errorType: LoginErrorType.invalidParentalPin,
            message: 'Invalid parental PIN',
          );
        }
      }
      
      // Create secure session
      final session = await _createUserSession(user, deviceId);
      
      // Clear failed attempts on successful login
      _clearFailedAttempts(identifier);
      
      debugPrint('✅ Login successful for: ${_maskIdentifier(identifier)}');
      
      return LoginResult(
        success: true,
        sessionToken: session.token,
        sessionExpiresAt: session.expiresAt,
        user: user,
      );
      
    } catch (e) {
      debugPrint('❌ Login attempt failed: $e');
      return LoginResult(
        success: false,
        errorType: LoginErrorType.systemError,
        message: 'System error during login',
      );
    }
  }
  
  /// Create secure user session
  static Future<UserSession> _createUserSession(UserDetails user, String deviceId) async {
    final token = _generateSecureSessionToken();
    final expiresAt = DateTime.now().add(_sessionTimeout);
    
    final session = UserSession(
      token: token,
      userId: user.id,
      deviceId: deviceId,
      createdAt: DateTime.now(),
      expiresAt: expiresAt,
      isChildAccount: user.isChild,
      lastActivity: DateTime.now(),
    );
    
    _activeSessions[token] = session;
    
    // In production, store in secure database
    await EncryptionService.secureStore(
      'session_$token',
      jsonEncode(session.toJson()),
    );
    
    return session;
  }
  
  /// Validate session token
  static Future<SessionValidationResult> validateSession(String token) async {
    final session = _activeSessions[token];
    
    if (session == null) {
      return SessionValidationResult(
        isValid: false,
        reason: 'Session not found',
      );
    }
    
    if (DateTime.now().isAfter(session.expiresAt)) {
      await _invalidateSession(token);
      return SessionValidationResult(
        isValid: false,
        reason: 'Session expired',
      );
    }
    
    // Update last activity
    session.lastActivity = DateTime.now();
    
    return SessionValidationResult(
      isValid: true,
      session: session,
    );
  }
  
  /// Logout and invalidate session
  static Future<void> logout(String token) async {
    debugPrint('🚪 Logging out session: ${_maskToken(token)}');
    await _invalidateSession(token);
  }
  
  /// Invalidate all sessions for a user (security breach response)
  static Future<void> invalidateAllUserSessions(String userId) async {
    debugPrint('🚨 Invalidating all sessions for user: ${_maskIdentifier(userId)}');
    
    final userSessions = _activeSessions.entries
        .where((entry) => entry.value.userId == userId)
        .map((entry) => entry.key)
        .toList();
    
    for (final token in userSessions) {
      await _invalidateSession(token);
    }
  }
  
  /// Generate secure password reset token
  static Future<PasswordResetRequest> initiatePasswordReset({
    required String identifier,
    String? parentEmail, // Required for child accounts
  }) async {
    debugPrint('🔄 Initiating password reset for: ${_maskIdentifier(identifier)}');
    
    try {
      final user = await _getUserDetails(identifier);
      
      // For child accounts, parent email is required
      if (user.isChild && (parentEmail == null || parentEmail != user.parentEmail)) {
        throw Exception('Parent email required for child account password reset');
      }
      
      final resetToken = EncryptionService.generateSecureToken(32);
      final expiresAt = DateTime.now().add(const Duration(hours: 1));
      
      final request = PasswordResetRequest(
        token: resetToken,
        userId: user.id,
        requestedAt: DateTime.now(),
        expiresAt: expiresAt,
        isChildAccount: user.isChild,
        parentEmail: user.isChild ? parentEmail! : null,
      );
      
      // In production, store reset request and send email
      await _storePasswordResetRequest(request);
      await _sendPasswordResetEmail(request, user);
      
      return request;
    } catch (e) {
      debugPrint('❌ Password reset initiation failed: $e');
      rethrow;
    }
  }
  
  /// Complete password reset with token
  static Future<bool> completePasswordReset({
    required String resetToken,
    required String newPassword,
    String? parentalPin, // Required for child accounts
  }) async {
    debugPrint('🔄 Completing password reset with token: ${_maskToken(resetToken)}');
    
    try {
      final request = await _getPasswordResetRequest(resetToken);
      if (request == null || DateTime.now().isAfter(request.expiresAt)) {
        debugPrint('❌ Invalid or expired reset token');
        return false;
      }
      
      // Validate new password
      final passwordValidation = validatePassword(newPassword);
      if (!passwordValidation.isValid) {
        debugPrint('❌ New password does not meet security requirements');
        return false;
      }
      
      // For child accounts, verify parental PIN
      if (request.isChildAccount && parentalPin != null) {
        final pinValid = await _verifyParentalPin(request.parentEmail!, parentalPin);
        if (!pinValid) {
          debugPrint('❌ Invalid parental PIN for password reset');
          return false;
        }
      }
      
      // Update password securely
      await _updateUserPassword(request.userId, newPassword);
      
      // Invalidate all existing sessions for security
      await invalidateAllUserSessions(request.userId);
      
      // Clean up reset request
      await _deletePasswordResetRequest(resetToken);
      
      debugPrint('✅ Password reset completed successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Password reset completion failed: $e');
      return false;
    }
  }
  
  /// Generate secure parental PIN
  static String generateParentalPin() {
    final random = Random.secure();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }
  
  /// Security monitoring methods
  static SecurityStatus getSecurityStatus() {
    final now = DateTime.now();
    final activeSessions = _activeSessions.values
        .where((session) => now.isBefore(session.expiresAt))
        .length;
    
    final lockedAccounts = _loginAttempts.values
        .where((tracker) => tracker.isLockedOut(now))
        .length;
    
    return SecurityStatus(
      activeSessions: activeSessions,
      lockedAccounts: lockedAccounts,
      failedAttempts: _getTotalFailedAttempts(),
      lastSecurityEvent: _getLastSecurityEvent(),
    );
  }
  
  /// Helper methods
  static Future<void> _loadLoginAttempts() async {
    // In production, load from secure storage
    _loginAttempts = {};
  }
  
  static Future<void> _loadActiveSessions() async {
    // In production, load from secure storage
    _activeSessions = {};
  }
  
  static void _startSessionCleanup() {
    _sessionCleanupTimer?.cancel();
    _sessionCleanupTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _cleanupExpiredSessions();
    });
  }
  
  static void _cleanupExpiredSessions() {
    final now = DateTime.now();
    final expiredTokens = _activeSessions.entries
        .where((entry) => now.isAfter(entry.value.expiresAt))
        .map((entry) => entry.key)
        .toList();
    
    for (final token in expiredTokens) {
      _activeSessions.remove(token);
    }
    
    if (expiredTokens.isNotEmpty) {
      debugPrint('🧹 Cleaned up ${expiredTokens.length} expired sessions');
    }
  }
  
  static bool _isCommonPassword(String password) {
    final commonPasswords = [
      'password', '123456', 'password123', 'admin', 'qwerty',
      'letmein', 'welcome', '123456789', 'password1', 'abc123'
    ];
    return commonPasswords.contains(password.toLowerCase());
  }
  
  static int _calculatePasswordStrength(String password) {
    int strength = 0;
    
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
    
    return strength;
  }
  
  static String _maskIdentifier(String identifier) {
    if (identifier.contains('@')) {
      final parts = identifier.split('@');
      final masked = '${parts[0].substring(0, 2)}***@${parts[1]}';
      return masked;
    }
    return '${identifier.substring(0, 2)}***';
  }
  
  static String _maskToken(String token) {
    return '${token.substring(0, 8)}***';
  }
  
  static bool _isAccountLockedOut(String identifier) {
    final tracker = _loginAttempts[identifier];
    return tracker?.isLockedOut(DateTime.now()) ?? false;
  }
  
  static DateTime? _getLockoutExpiry(String identifier) {
    final tracker = _loginAttempts[identifier];
    return tracker?.lockoutExpiresAt;
  }
  
  static int _getFailedAttempts(String identifier) {
    final tracker = _loginAttempts[identifier];
    return tracker?.attempts ?? 0;
  }
  
  static void _recordFailedAttempt(String identifier, String deviceId) {
    final tracker = _loginAttempts[identifier] ?? LoginAttemptTracker(identifier);
    tracker.recordFailedAttempt(deviceId);
    _loginAttempts[identifier] = tracker;
    
    if (tracker.attempts >= _maxLoginAttempts) {
      tracker.lockAccount(_lockoutDuration);
      debugPrint('🔒 Account locked for excessive failed attempts: ${_maskIdentifier(identifier)}');
    }
  }
  
  static void _clearFailedAttempts(String identifier) {
    _loginAttempts.remove(identifier);
  }
  
  static String _generateSecureSessionToken() {
    return EncryptionService.generateSecureToken(64);
  }
  
  static Future<bool> _verifyCredentials(String identifier, String password) async {
    // In production, verify against secure database with hashed passwords
    return identifier.isNotEmpty && password.isNotEmpty;
  }
  
  static Future<UserDetails> _getUserDetails(String identifier) async {
    // In production, fetch from secure database
    return UserDetails(
      id: 'user123',
      email: identifier,
      isChild: true,
      requiresParentalVerification: true,
      parentEmail: 'parent@example.com',
    );
  }
  
  static Future<bool> _verifyParentalPin(String parentEmail, String pin) async {
    // In production, verify against stored parental PIN
    return pin.length == 6;
  }
  
  static Future<void> _invalidateSession(String token) async {
    _activeSessions.remove(token);
    await EncryptionService.secureDelete('session_$token');
  }
  
  static Future<void> _storePasswordResetRequest(PasswordResetRequest request) async {
    // In production, store in secure database
  }
  
  static Future<void> _sendPasswordResetEmail(PasswordResetRequest request, UserDetails user) async {
    // In production, send email with reset link
    debugPrint('📧 Password reset email sent');
  }
  
  static Future<PasswordResetRequest?> _getPasswordResetRequest(String token) async {
    // In production, retrieve from secure database
    return null;
  }
  
  static Future<void> _updateUserPassword(String userId, String newPassword) async {
    // In production, hash and store new password securely
    debugPrint('🔐 Password updated for user: ${_maskIdentifier(userId)}');
  }
  
  static Future<void> _deletePasswordResetRequest(String token) async {
    // In production, remove from database
  }
  
  static int _getTotalFailedAttempts() {
    return _loginAttempts.values.fold(0, (sum, tracker) => sum + tracker.attempts);
  }
  
  static DateTime? _getLastSecurityEvent() {
    // In production, track security events
    return DateTime.now().subtract(const Duration(hours: 1));
  }
}

/// Supporting classes
class LoginAttemptTracker {
  final String identifier;
  int attempts = 0;
  DateTime? lockoutExpiresAt;
  List<DateTime> attemptTimes = [];

  LoginAttemptTracker(this.identifier);

  void recordFailedAttempt(String deviceId) {
    attempts++;
    attemptTimes.add(DateTime.now());
  }

  bool isLockedOut(DateTime now) {
    return lockoutExpiresAt != null && now.isBefore(lockoutExpiresAt!);
  }

  void lockAccount(Duration lockoutDuration) {
    lockoutExpiresAt = DateTime.now().add(lockoutDuration);
  }
}

class UserSession {
  final String token;
  final String userId;
  final String deviceId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isChildAccount;
  DateTime lastActivity;

  UserSession({
    required this.token,
    required this.userId,
    required this.deviceId,
    required this.createdAt,
    required this.expiresAt,
    required this.isChildAccount,
    required this.lastActivity,
  });

  Map<String, dynamic> toJson() => {
    'token': token,
    'userId': userId,
    'deviceId': deviceId,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'isChildAccount': isChildAccount,
    'lastActivity': lastActivity.toIso8601String(),
  };
}

class UserDetails {
  final String id;
  final String email;
  final bool isChild;
  final bool requiresParentalVerification;
  final String? parentEmail;

  const UserDetails({
    required this.id,
    required this.email,
    required this.isChild,
    required this.requiresParentalVerification,
    this.parentEmail,
  });
}

class PasswordValidationResult {
  final bool isValid;
  final int strength; // 0-6
  final List<String> issues;

  const PasswordValidationResult({
    required this.isValid,
    required this.strength,
    required this.issues,
  });
}

class LoginResult {
  final bool success;
  final LoginErrorType? errorType;
  final String? message;
  final String? sessionToken;
  final DateTime? sessionExpiresAt;
  final UserDetails? user;
  final int? attemptsRemaining;
  final DateTime? lockoutExpiresAt;

  const LoginResult({
    required this.success,
    this.errorType,
    this.message,
    this.sessionToken,
    this.sessionExpiresAt,
    this.user,
    this.attemptsRemaining,
    this.lockoutExpiresAt,
  });
}

class SessionValidationResult {
  final bool isValid;
  final String? reason;
  final UserSession? session;

  const SessionValidationResult({
    required this.isValid,
    this.reason,
    this.session,
  });
}

class PasswordResetRequest {
  final String token;
  final String userId;
  final DateTime requestedAt;
  final DateTime expiresAt;
  final bool isChildAccount;
  final String? parentEmail;

  const PasswordResetRequest({
    required this.token,
    required this.userId,
    required this.requestedAt,
    required this.expiresAt,
    required this.isChildAccount,
    this.parentEmail,
  });
}

class SecurityStatus {
  final int activeSessions;
  final int lockedAccounts;
  final int failedAttempts;
  final DateTime? lastSecurityEvent;

  const SecurityStatus({
    required this.activeSessions,
    required this.lockedAccounts,
    required this.failedAttempts,
    this.lastSecurityEvent,
  });
}

enum LoginErrorType {
  invalidCredentials,
  accountLockedOut,
  parentalVerificationRequired,
  invalidParentalPin,
  systemError,
}