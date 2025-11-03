import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'encryption_service.dart';

/// Comprehensive audit logging system for security events and compliance
class AuditLoggingService {
  static const int _maxLogEntries = 10000;
  static const Duration _logRetentionPeriod = Duration(days: 90);
  
  static bool _initialized = false;
  static List<AuditLogEntry> _logEntries = [];
  static Timer? _logMaintenanceTimer;
  
  /// Initialize audit logging service
  static Future<void> initialize() async {
    if (_initialized) return;
    
    debugPrint('📋 Initializing AuditLoggingService...');
    
    try {
      await _loadExistingLogs();
      _startLogMaintenance();
      
      // Log service initialization
      await logSecurityEvent(
        event: SecurityEventType.systemInit,
        description: 'Audit logging service initialized',
        severity: LogSeverity.info,
      );
      
      _initialized = true;
      debugPrint('✅ AuditLoggingService initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize AuditLoggingService: $e');
      rethrow;
    }
  }
  
  /// Log authentication events
  static Future<void> logAuthenticationEvent({
    required AuthEventType eventType,
    required String userId,
    String? deviceId,
    String? ipAddress,
    String? userAgent,
    Map<String, dynamic>? metadata,
    LogSeverity severity = LogSeverity.info,
  }) async {
    final entry = AuditLogEntry(
      id: _generateLogId(),
      timestamp: DateTime.now(),
      category: LogCategory.authentication,
      eventType: eventType.toString(),
      severity: severity,
      userId: userId,
      deviceId: deviceId,
      ipAddress: ipAddress,
      userAgent: userAgent,
      description: _getAuthEventDescription(eventType),
      metadata: metadata ?? {},
    );
    
    await _addLogEntry(entry);
    
    // Alert on suspicious activities
    if (_isSuspiciousAuthEvent(eventType)) {
      await _triggerSecurityAlert(entry);
    }
  }
  
  /// Log security events
  static Future<void> logSecurityEvent({
    required SecurityEventType event,
    required String description,
    required LogSeverity severity,
    String? userId,
    String? deviceId,
    String? ipAddress,
    Map<String, dynamic>? metadata,
  }) async {
    final entry = AuditLogEntry(
      id: _generateLogId(),
      timestamp: DateTime.now(),
      category: LogCategory.security,
      eventType: event.toString(),
      severity: severity,
      userId: userId,
      deviceId: deviceId,
      ipAddress: ipAddress,
      description: description,
      metadata: metadata ?? {},
    );
    
    await _addLogEntry(entry);
    
    // Alert on high severity events
    if (severity == LogSeverity.critical || severity == LogSeverity.error) {
      await _triggerSecurityAlert(entry);
    }
  }
  
  /// Log data access events for privacy compliance
  static Future<void> logDataAccess({
    required String userId,
    required DataAccessType accessType,
    required String dataCategory,
    String? reason,
    String? deviceId,
    Map<String, dynamic>? metadata,
  }) async {
    final entry = AuditLogEntry(
      id: _generateLogId(),
      timestamp: DateTime.now(),
      category: LogCategory.dataAccess,
      eventType: accessType.toString(),
      severity: LogSeverity.info,
      userId: userId,
      deviceId: deviceId,
      description: 'Data access: $dataCategory (${accessType.toString()})',
      metadata: {
        'dataCategory': dataCategory,
        'reason': reason,
        ...metadata ?? {},
      },
    );
    
    await _addLogEntry(entry);
  }
  
  /// Log parental control events
  static Future<void> logParentalControlEvent({
    required String parentUserId,
    required String childUserId,
    required ParentalEventType eventType,
    String? description,
    String? deviceId,
    Map<String, dynamic>? metadata,
  }) async {
    final entry = AuditLogEntry(
      id: _generateLogId(),
      timestamp: DateTime.now(),
      category: LogCategory.parentalControl,
      eventType: eventType.toString(),
      severity: LogSeverity.info,
      userId: childUserId,
      deviceId: deviceId,
      description: description ?? _getParentalEventDescription(eventType),
      metadata: {
        'parentUserId': parentUserId,
        'childUserId': childUserId,
        ...metadata ?? {},
      },
    );
    
    await _addLogEntry(entry);
  }
  
  /// Log privacy compliance events
  static Future<void> logPrivacyEvent({
    required String userId,
    required PrivacyEventType eventType,
    String? description,
    String? deviceId,
    Map<String, dynamic>? metadata,
  }) async {
    final entry = AuditLogEntry(
      id: _generateLogId(),
      timestamp: DateTime.now(),
      category: LogCategory.privacy,
      eventType: eventType.toString(),
      severity: LogSeverity.info,
      userId: userId,
      deviceId: deviceId,
      description: description ?? _getPrivacyEventDescription(eventType),
      metadata: metadata ?? {},
    );
    
    await _addLogEntry(entry);
  }
  
  /// Query audit logs with filtering
  static Future<List<AuditLogEntry>> queryLogs({
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
    LogCategory? category,
    LogSeverity? minSeverity,
    int? limit,
  }) async {
    var filteredLogs = _logEntries.where((entry) {
      if (startDate != null && entry.timestamp.isBefore(startDate)) return false;
      if (endDate != null && entry.timestamp.isAfter(endDate)) return false;
      if (userId != null && entry.userId != userId) return false;
      if (category != null && entry.category != category) return false;
      if (minSeverity != null && _getSeverityLevel(entry.severity) < _getSeverityLevel(minSeverity)) return false;
      return true;
    }).toList();
    
    // Sort by timestamp (newest first)
    filteredLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    if (limit != null && filteredLogs.length > limit) {
      filteredLogs = filteredLogs.take(limit).toList();
    }
    
    return filteredLogs;
  }
  
  /// Get security summary for dashboard
  static Future<SecuritySummary> getSecuritySummary({
    Duration period = const Duration(hours: 24),
  }) async {
    final cutoff = DateTime.now().subtract(period);
    final recentLogs = _logEntries.where((log) => log.timestamp.isAfter(cutoff));
    
    final summary = SecuritySummary(
      totalEvents: recentLogs.length,
      criticalEvents: recentLogs.where((log) => log.severity == LogSeverity.critical).length,
      errorEvents: recentLogs.where((log) => log.severity == LogSeverity.error).length,
      warningEvents: recentLogs.where((log) => log.severity == LogSeverity.warning).length,
      authenticationEvents: recentLogs.where((log) => log.category == LogCategory.authentication).length,
      dataAccessEvents: recentLogs.where((log) => log.category == LogCategory.dataAccess).length,
      privacyEvents: recentLogs.where((log) => log.category == LogCategory.privacy).length,
      uniqueUsers: recentLogs.map((log) => log.userId).where((id) => id != null).toSet().length,
      periodStart: cutoff,
      periodEnd: DateTime.now(),
    );
    
    return summary;
  }
  
  /// Export logs for compliance reporting
  static Future<String> exportLogs({
    DateTime? startDate,
    DateTime? endDate,
    ExportFormat format = ExportFormat.json,
  }) async {
    final logs = await queryLogs(
      startDate: startDate,
      endDate: endDate,
    );
    
    switch (format) {
      case ExportFormat.json:
        return _exportAsJson(logs);
      case ExportFormat.csv:
        return _exportAsCsv(logs);
      default:
        throw ArgumentError('Unsupported export format: $format');
    }
  }
  
  /// Detect suspicious patterns in logs
  static Future<List<SecurityAlert>> detectSuspiciousActivity({
    Duration period = const Duration(hours: 1),
  }) async {
    final alerts = <SecurityAlert>[];
    final cutoff = DateTime.now().subtract(period);
    final recentLogs = _logEntries.where((log) => log.timestamp.isAfter(cutoff));
    
    // Multiple failed login attempts
    final failedLogins = recentLogs
        .where((log) => log.category == LogCategory.authentication && 
                       log.eventType == AuthEventType.loginFailed.toString())
        .toList();
    
    final failedLoginsByUser = <String, int>{};
    for (final log in failedLogins) {
      if (log.userId != null) {
        failedLoginsByUser[log.userId!] = (failedLoginsByUser[log.userId!] ?? 0) + 1;
      }
    }
    
    for (final entry in failedLoginsByUser.entries) {
      if (entry.value >= 5) {
        alerts.add(SecurityAlert(
          id: _generateAlertId(),
          timestamp: DateTime.now(),
          type: AlertType.suspiciousActivity,
          severity: LogSeverity.warning,
          title: 'Multiple Failed Login Attempts',
          description: 'User ${entry.key} has ${entry.value} failed login attempts in the last hour',
          userId: entry.key,
        ));
      }
    }
    
    // Unusual data access patterns
    final dataAccess = recentLogs
        .where((log) => log.category == LogCategory.dataAccess)
        .toList();
    
    final accessByUser = <String, int>{};
    for (final log in dataAccess) {
      if (log.userId != null) {
        accessByUser[log.userId!] = (accessByUser[log.userId!] ?? 0) + 1;
      }
    }
    
    for (final entry in accessByUser.entries) {
      if (entry.value >= 50) { // High volume data access
        alerts.add(SecurityAlert(
          id: _generateAlertId(),
          timestamp: DateTime.now(),
          type: AlertType.unusualDataAccess,
          severity: LogSeverity.warning,
          title: 'High Volume Data Access',
          description: 'User ${entry.key} accessed data ${entry.value} times in the last hour',
          userId: entry.key,
        ));
      }
    }
    
    return alerts;
  }
  
  /// Helper methods
  static Future<void> _addLogEntry(AuditLogEntry entry) async {
    _logEntries.add(entry);
    
    // Maintain log size limit
    if (_logEntries.length > _maxLogEntries) {
      _logEntries.removeRange(0, _logEntries.length - _maxLogEntries);
    }
    
    // Persist to secure storage
    await _persistLogEntry(entry);
    
    debugPrint('📋 Logged ${entry.category}: ${entry.eventType}');
  }
  
  static Future<void> _loadExistingLogs() async {
    try {
      final logsJson = await EncryptionService.secureRetrieve('audit_logs');
      if (logsJson != null) {
        final logsList = jsonDecode(logsJson) as List;
        _logEntries = logsList
            .map((json) => AuditLogEntry.fromJson(json))
            .toList();
        
        // Remove expired logs
        final cutoff = DateTime.now().subtract(_logRetentionPeriod);
        _logEntries.removeWhere((entry) => entry.timestamp.isBefore(cutoff));
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load existing logs: $e');
      _logEntries = [];
    }
  }
  
  static void _startLogMaintenance() {
    _logMaintenanceTimer?.cancel();
    _logMaintenanceTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _performLogMaintenance();
    });
  }
  
  static Future<void> _performLogMaintenance() async {
    final before = _logEntries.length;
    
    // Remove old logs
    final cutoff = DateTime.now().subtract(_logRetentionPeriod);
    _logEntries.removeWhere((entry) => entry.timestamp.isBefore(cutoff));
    
    // Persist cleaned logs
    await _persistAllLogs();
    
    final after = _logEntries.length;
    if (before != after) {
      debugPrint('🧹 Log maintenance: removed ${before - after} old entries');
    }
  }
  
  static Future<void> _persistLogEntry(AuditLogEntry entry) async {
    // In production, persist individual entries to database
    // For demo, we'll batch persist
  }
  
  static Future<void> _persistAllLogs() async {
    try {
      final logsJson = jsonEncode(_logEntries.map((e) => e.toJson()).toList());
      await EncryptionService.secureStore('audit_logs', logsJson);
    } catch (e) {
      debugPrint('❌ Failed to persist logs: $e');
    }
  }
  
  static String _generateLogId() {
    return 'log_${DateTime.now().millisecondsSinceEpoch}_${EncryptionService.generateSecureToken(8)}';
  }
  
  static String _generateAlertId() {
    return 'alert_${DateTime.now().millisecondsSinceEpoch}_${EncryptionService.generateSecureToken(8)}';
  }
  
  static String _getAuthEventDescription(AuthEventType eventType) {
    switch (eventType) {
      case AuthEventType.loginSuccess:
        return 'Successful user login';
      case AuthEventType.loginFailed:
        return 'Failed login attempt';
      case AuthEventType.logout:
        return 'User logout';
      case AuthEventType.passwordReset:
        return 'Password reset requested';
      case AuthEventType.accountLocked:
        return 'Account locked due to failed attempts';
      case AuthEventType.sessionExpired:
        return 'User session expired';
      case AuthEventType.parentalVerification:
        return 'Parental verification performed';
    }
  }
  
  static String _getParentalEventDescription(ParentalEventType eventType) {
    switch (eventType) {
      case ParentalEventType.consentGiven:
        return 'Parental consent provided';
      case ParentalEventType.consentRevoked:
        return 'Parental consent revoked';
      case ParentalEventType.settingsChanged:
        return 'Parental settings modified';
      case ParentalEventType.dataRequested:
        return 'Child data export requested';
      case ParentalEventType.accountDeleted:
        return 'Child account deletion requested';
    }
  }
  
  static String _getPrivacyEventDescription(PrivacyEventType eventType) {
    switch (eventType) {
      case PrivacyEventType.dataExported:
        return 'User data exported';
      case PrivacyEventType.dataDeleted:
        return 'User data deleted';
      case PrivacyEventType.privacySettingsChanged:
        return 'Privacy settings updated';
      case PrivacyEventType.cookieConsent:
        return 'Cookie consent provided';
      case PrivacyEventType.dataProcessingConsent:
        return 'Data processing consent given';
    }
  }
  
  static bool _isSuspiciousAuthEvent(AuthEventType eventType) {
    return [
      AuthEventType.loginFailed,
      AuthEventType.accountLocked,
    ].contains(eventType);
  }
  
  static Future<void> _triggerSecurityAlert(AuditLogEntry entry) async {
    debugPrint('🚨 Security Alert: ${entry.description}');
    // In production, send notifications to security team
  }
  
  static int _getSeverityLevel(LogSeverity severity) {
    switch (severity) {
      case LogSeverity.debug:
        return 0;
      case LogSeverity.info:
        return 1;
      case LogSeverity.warning:
        return 2;
      case LogSeverity.error:
        return 3;
      case LogSeverity.critical:
        return 4;
    }
  }
  
  static String _exportAsJson(List<AuditLogEntry> logs) {
    return jsonEncode(logs.map((log) => log.toJson()).toList());
  }
  
  static String _exportAsCsv(List<AuditLogEntry> logs) {
    final buffer = StringBuffer();
    
    // CSV Header
    buffer.writeln('Timestamp,Category,Event Type,Severity,User ID,Device ID,IP Address,Description');
    
    // CSV Data
    for (final log in logs) {
      buffer.writeln(
        '${log.timestamp.toIso8601String()},'
        '${log.category},'
        '${log.eventType},'
        '${log.severity},'
        '${log.userId ?? ""},'
        '${log.deviceId ?? ""},'
        '${log.ipAddress ?? ""},'
        '"${log.description.replaceAll('"', '""')}"'
      );
    }
    
    return buffer.toString();
  }
}

/// Supporting classes and enums
class AuditLogEntry {
  final String id;
  final DateTime timestamp;
  final LogCategory category;
  final String eventType;
  final LogSeverity severity;
  final String? userId;
  final String? deviceId;
  final String? ipAddress;
  final String? userAgent;
  final String description;
  final Map<String, dynamic> metadata;

  const AuditLogEntry({
    required this.id,
    required this.timestamp,
    required this.category,
    required this.eventType,
    required this.severity,
    this.userId,
    this.deviceId,
    this.ipAddress,
    this.userAgent,
    required this.description,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'category': category.toString(),
    'eventType': eventType,
    'severity': severity.toString(),
    'userId': userId,
    'deviceId': deviceId,
    'ipAddress': ipAddress,
    'userAgent': userAgent,
    'description': description,
    'metadata': metadata,
  };

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) => AuditLogEntry(
    id: json['id'],
    timestamp: DateTime.parse(json['timestamp']),
    category: LogCategory.values.firstWhere((e) => e.toString() == json['category']),
    eventType: json['eventType'],
    severity: LogSeverity.values.firstWhere((e) => e.toString() == json['severity']),
    userId: json['userId'],
    deviceId: json['deviceId'],
    ipAddress: json['ipAddress'],
    userAgent: json['userAgent'],
    description: json['description'],
    metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
  );
}

class SecuritySummary {
  final int totalEvents;
  final int criticalEvents;
  final int errorEvents;
  final int warningEvents;
  final int authenticationEvents;
  final int dataAccessEvents;
  final int privacyEvents;
  final int uniqueUsers;
  final DateTime periodStart;
  final DateTime periodEnd;

  const SecuritySummary({
    required this.totalEvents,
    required this.criticalEvents,
    required this.errorEvents,
    required this.warningEvents,
    required this.authenticationEvents,
    required this.dataAccessEvents,
    required this.privacyEvents,
    required this.uniqueUsers,
    required this.periodStart,
    required this.periodEnd,
  });
}

class SecurityAlert {
  final String id;
  final DateTime timestamp;
  final AlertType type;
  final LogSeverity severity;
  final String title;
  final String description;
  final String? userId;

  const SecurityAlert({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    this.userId,
  });
}

enum LogCategory {
  authentication,
  security,
  dataAccess,
  parentalControl,
  privacy,
  system,
}

enum LogSeverity {
  debug,
  info,
  warning,
  error,
  critical,
}

enum AuthEventType {
  loginSuccess,
  loginFailed,
  logout,
  passwordReset,
  accountLocked,
  sessionExpired,
  parentalVerification,
}

enum SecurityEventType {
  systemInit,
  configChange,
  dataEncryption,
  keyRotation,
  securityBreach,
  unauthorizedAccess,
}

enum DataAccessType {
  read,
  write,
  delete,
  export,
}

enum ParentalEventType {
  consentGiven,
  consentRevoked,
  settingsChanged,
  dataRequested,
  accountDeleted,
}

enum PrivacyEventType {
  dataExported,
  dataDeleted,
  privacySettingsChanged,
  cookieConsent,
  dataProcessingConsent,
}

enum AlertType {
  suspiciousActivity,
  unusualDataAccess,
  securityBreach,
  complianceViolation,
}

enum ExportFormat {
  json,
  csv,
}