import 'package:equatable/equatable.dart';

/// Enumeration for sync operations
enum SyncOperation {
  insert('INSERT'),
  update('UPDATE'),
  delete('DELETE');

  const SyncOperation(this.value);
  final String value;

  /// Create from string value
  static SyncOperation fromString(String value) {
    switch (value.toUpperCase()) {
      case 'INSERT':
        return SyncOperation.insert;
      case 'UPDATE':
        return SyncOperation.update;
      case 'DELETE':
        return SyncOperation.delete;
      default:
        throw ArgumentError('Unknown sync operation: $value');
    }
  }
}

/// Enumeration for sync status
enum SyncStatus {
  pending('PENDING'),
  processing('PROCESSING'),
  completed('COMPLETED'),
  failed('FAILED'),
  cancelled('CANCELLED');

  const SyncStatus(this.value);
  final String value;

  /// Create from string value
  static SyncStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING':
        return SyncStatus.pending;
      case 'PROCESSING':
        return SyncStatus.processing;
      case 'COMPLETED':
        return SyncStatus.completed;
      case 'FAILED':
        return SyncStatus.failed;
      case 'CANCELLED':
        return SyncStatus.cancelled;
      default:
        throw ArgumentError('Unknown sync status: $value');
    }
  }
}

/// Model representing a sync queue item
class SyncQueueItem extends Equatable {
  final String id;
  final String entityType;
  final String entityId;
  final SyncOperation operation;
  final Map<String, dynamic> payload;
  final SyncStatus status;
  final int priority;
  final int retryCount;
  final int maxRetries;
  final DateTime createdAt;
  final DateTime scheduledAt;
  final DateTime? lastAttemptAt;
  final String? error;
  final Map<String, dynamic>? metadata;

  const SyncQueueItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    this.status = SyncStatus.pending,
    this.priority = 0,
    this.retryCount = 0,
    this.maxRetries = 3,
    required this.createdAt,
    required this.scheduledAt,
    this.lastAttemptAt,
    this.error,
    this.metadata,
  });

  /// Create from database map
  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] as String,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as String,
      operation: SyncOperation.fromString(map['operation'] as String),
      payload: Map<String, dynamic>.from(map['payload'] as Map),
      status: SyncStatus.fromString(map['status'] as String),
      priority: map['priority'] as int,
      retryCount: map['retry_count'] as int,
      maxRetries: map['max_retries'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      scheduledAt: DateTime.fromMillisecondsSinceEpoch(map['scheduled_at'] as int),
      lastAttemptAt: map['last_attempt_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_attempt_at'] as int)
          : null,
      error: map['error'] as String?,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation.value,
      'payload': payload,
      'status': status.value,
      'priority': priority,
      'retry_count': retryCount,
      'max_retries': maxRetries,
      'created_at': createdAt.millisecondsSinceEpoch,
      'scheduled_at': scheduledAt.millisecondsSinceEpoch,
      'last_attempt_at': lastAttemptAt?.millisecondsSinceEpoch,
      'error': error,
      'metadata': metadata,
    };
  }

  /// Create a copy with updated fields
  SyncQueueItem copyWith({
    String? id,
    String? entityType,
    String? entityId,
    SyncOperation? operation,
    Map<String, dynamic>? payload,
    SyncStatus? status,
    int? priority,
    int? retryCount,
    int? maxRetries,
    DateTime? createdAt,
    DateTime? scheduledAt,
    DateTime? lastAttemptAt,
    String? error,
    Map<String, dynamic>? metadata,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
      createdAt: createdAt ?? this.createdAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      error: error ?? this.error,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if item is ready for processing
  bool get isReadyForProcessing {
    return status == SyncStatus.pending &&
           retryCount < maxRetries &&
           DateTime.now().isAfter(scheduledAt);
  }

  /// Check if item has failed permanently
  bool get hasPermanentlyFailed {
    return status == SyncStatus.failed && retryCount >= maxRetries;
  }

  /// Check if item should be retried
  bool get shouldRetry {
    return status == SyncStatus.failed && retryCount < maxRetries;
  }

  /// Calculate next retry time with exponential backoff
  DateTime get nextRetryTime {
    if (!shouldRetry) return scheduledAt;
    
    // Exponential backoff: 2^retry_count minutes
    final backoffMinutes = (1 << retryCount).clamp(1, 60);
    return DateTime.now().add(Duration(minutes: backoffMinutes));
  }

  @override
  List<Object?> get props => [
        id,
        entityType,
        entityId,
        operation,
        payload,
        status,
        priority,
        retryCount,
        maxRetries,
        createdAt,
        scheduledAt,
        lastAttemptAt,
        error,
        metadata,
      ];

  @override
  String toString() {
    return 'SyncQueueItem('
        'id: $id, '
        'entityType: $entityType, '
        'entityId: $entityId, '
        'operation: ${operation.value}, '
        'status: ${status.value}, '
        'priority: $priority, '
        'retryCount: $retryCount'
        ')';
  }
}

/// Result of a sync operation
class SyncResult extends Equatable {
  final bool success;
  final String? error;
  final Map<String, dynamic>? data;

  const SyncResult({
    required this.success,
    this.error,
    this.data,
  });

  /// Create success result
  factory SyncResult.success({Map<String, dynamic>? data}) {
    return SyncResult(success: true, data: data);
  }

  /// Create failure result
  factory SyncResult.failure(String error) {
    return SyncResult(success: false, error: error);
  }

  @override
  List<Object?> get props => [success, error, data];

  @override
  String toString() {
    return 'SyncResult(success: $success, error: $error, data: $data)';
  }
}

/// Statistics for sync operations
class SyncStatistics extends Equatable {
  final int totalItems;
  final int pendingItems;
  final int completedItems;
  final int failedItems;
  final int processingItems;
  final DateTime? lastSyncAt;
  final Duration? averageProcessingTime;

  const SyncStatistics({
    required this.totalItems,
    required this.pendingItems,
    required this.completedItems,
    required this.failedItems,
    required this.processingItems,
    this.lastSyncAt,
    this.averageProcessingTime,
  });

  /// Calculate success rate as a percentage
  double get successRate {
    if (totalItems == 0) return 0.0;
    return (completedItems / totalItems) * 100;
  }

  /// Check if sync is currently active
  bool get isSyncActive => processingItems > 0;

  /// Check if there are items waiting to be processed
  bool get hasPendingWork => pendingItems > 0;

  @override
  List<Object?> get props => [
        totalItems,
        pendingItems,
        completedItems,
        failedItems,
        processingItems,
        lastSyncAt,
        averageProcessingTime,
      ];

  @override
  String toString() {
    return 'SyncStatistics('
        'total: $totalItems, '
        'pending: $pendingItems, '
        'completed: $completedItems, '
        'failed: $failedItems, '
        'processing: $processingItems, '
        'successRate: ${successRate.toStringAsFixed(1)}%'
        ')';
  }
}