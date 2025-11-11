import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'task_model.g.dart';

/// Task model representing a task/chore in the AI Rewards system
@JsonSerializable()
class TaskModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final int pointValue;
  final TaskStatus status;
  final TaskPriority priority;
  final String assignedToUserId;
  final String? assignedByUserId;
  final String familyId;
  final DateTime createdAt;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final DateTime? approvedAt;
  final String? approvedByUserId;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final bool isRecurring;
  final RecurrencePattern? recurrencePattern;
  final String? instructions;
  final List<String> attachments;
  final bool showInQuickTasks;

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.pointValue,
    this.status = TaskStatus.pending,
    this.priority = TaskPriority.medium,
    required this.assignedToUserId,
    this.assignedByUserId,
    required this.familyId,
    required this.createdAt,
    this.dueDate,
    this.completedAt,
    this.approvedAt,
    this.approvedByUserId,
    this.tags = const [],
    this.metadata = const {},
    this.isRecurring = false,
    this.recurrencePattern,
    this.instructions,
    this.attachments = const [],
    this.showInQuickTasks = true,
  });

  /// Create a new task
  factory TaskModel.create({
    required String id,
    required String title,
    required String description,
    required String category,
    required int pointValue,
    required String assignedToUserId,
    String? assignedByUserId,
    required String familyId,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    List<String> tags = const [],
    bool isRecurring = false,
    RecurrencePattern? recurrencePattern,
    String? instructions,
    bool showInQuickTasks = true,
  }) {
    return TaskModel(
      id: id,
      title: title,
      description: description,
      category: category,
      pointValue: pointValue,
      assignedToUserId: assignedToUserId,
      assignedByUserId: assignedByUserId,
      familyId: familyId,
      priority: priority,
      createdAt: DateTime.now(),
      dueDate: dueDate,
      tags: tags,
      isRecurring: isRecurring,
      recurrencePattern: recurrencePattern,
      instructions: instructions,
      showInQuickTasks: showInQuickTasks,
    );
  }

  /// Create from JSON
  factory TaskModel.fromJson(Map<String, dynamic> json) => _$TaskModelFromJson(json);

  /// Create from Firestore document
  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel.fromJson({
      ...data,
      'id': doc.id,
      'createdAt': (data['createdAt'] as Timestamp).toDate().toIso8601String(),
      'dueDate': data['dueDate'] != null ? (data['dueDate'] as Timestamp).toDate().toIso8601String() : null,
      'completedAt': data['completedAt'] != null ? (data['completedAt'] as Timestamp).toDate().toIso8601String() : null,
      'approvedAt': data['approvedAt'] != null ? (data['approvedAt'] as Timestamp).toDate().toIso8601String() : null,
    });
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$TaskModelToJson(this);

  /// Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Firestore document ID is separate
    json['createdAt'] = Timestamp.fromDate(createdAt);
    json['dueDate'] = dueDate != null ? Timestamp.fromDate(dueDate!) : null;
    json['completedAt'] = completedAt != null ? Timestamp.fromDate(completedAt!) : null;
    json['approvedAt'] = approvedAt != null ? Timestamp.fromDate(approvedAt!) : null;
    
    // Properly serialize RecurrencePattern
    if (recurrencePattern != null) {
      json['recurrencePattern'] = recurrencePattern!.toJson();
    } else {
      json['recurrencePattern'] = null;
    }
    
    return json;
  }

  /// Create a copy with updated values
  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    int? pointValue,
    TaskStatus? status,
    TaskPriority? priority,
    String? assignedToUserId,
    String? assignedByUserId,
    String? familyId,
    DateTime? createdAt,
    DateTime? dueDate,
    DateTime? completedAt,
    DateTime? approvedAt,
    String? approvedByUserId,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    bool? isRecurring,
    RecurrencePattern? recurrencePattern,
    String? instructions,
    List<String>? attachments,
    bool? showInQuickTasks,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      pointValue: pointValue ?? this.pointValue,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      assignedByUserId: assignedByUserId ?? this.assignedByUserId,
      familyId: familyId ?? this.familyId,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedByUserId: approvedByUserId ?? this.approvedByUserId,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      instructions: instructions ?? this.instructions,
      attachments: attachments ?? this.attachments,
      showInQuickTasks: showInQuickTasks ?? this.showInQuickTasks,
    );
  }

  /// Mark task as completed
  TaskModel markCompleted() {
    return copyWith(
      status: TaskStatus.completed,
      completedAt: DateTime.now(),
    );
  }

  /// Mark task as approved and award points
  TaskModel markApproved(String approvedByUserId) {
    return copyWith(
      status: TaskStatus.approved,
      approvedAt: DateTime.now(),
      approvedByUserId: approvedByUserId,
    );
  }

  /// Mark task as rejected
  TaskModel markRejected() {
    return copyWith(
      status: TaskStatus.rejected,
      completedAt: null, // Reset completion time
    );
  }

  /// Check if task is overdue
  bool get isOverdue {
    if (dueDate == null || status != TaskStatus.pending) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  /// Check if task is completed
  bool get isCompleted => status == TaskStatus.completed || status == TaskStatus.approved;

  /// Check if task needs approval
  bool get needsApproval => status == TaskStatus.completed;

  /// Check if task is approved
  bool get isApproved => status == TaskStatus.approved;

  /// Get days until due date
  int? get daysUntilDue {
    if (dueDate == null) return null;
    return dueDate!.difference(DateTime.now()).inDays;
  }

  @override
  String toString() => 'TaskModel(id: $id, title: $title, status: $status, points: $pointValue)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Task status enumeration
@JsonEnum()
enum TaskStatus {
  @JsonValue('pending')
  pending,
  
  @JsonValue('in_progress')
  inProgress,
  
  @JsonValue('completed')
  completed,
  
  @JsonValue('approved')
  approved,
  
  @JsonValue('rejected')
  rejected,
  
  @JsonValue('cancelled')
  cancelled;

  String get displayName {
    switch (this) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.approved:
        return 'Approved';
      case TaskStatus.rejected:
        return 'Rejected';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isActive => this == TaskStatus.pending || this == TaskStatus.inProgress;
  bool get isFinished => this == TaskStatus.approved || this == TaskStatus.rejected || this == TaskStatus.cancelled;
}

/// Task priority enumeration
@JsonEnum()
enum TaskPriority {
  @JsonValue('low')
  low,
  
  @JsonValue('medium')
  medium,
  
  @JsonValue('high')
  high,
  
  @JsonValue('urgent')
  urgent;

  String get displayName {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }

  int get sortOrder {
    switch (this) {
      case TaskPriority.low:
        return 0;
      case TaskPriority.medium:
        return 1;
      case TaskPriority.high:
        return 2;
      case TaskPriority.urgent:
        return 3;
    }
  }
}

/// Recurrence pattern for recurring tasks
@JsonSerializable()
class RecurrencePattern {
  final RecurrenceType type;
  final int interval;
  final List<int> daysOfWeek;
  final int? dayOfMonth;
  final DateTime? endDate;

  const RecurrencePattern({
    required this.type,
    this.interval = 1,
    this.daysOfWeek = const [],
    this.dayOfMonth,
    this.endDate,
  });

  factory RecurrencePattern.fromJson(Map<String, dynamic> json) => _$RecurrencePatternFromJson(json);
  Map<String, dynamic> toJson() => _$RecurrencePatternToJson(this);

  /// Create a RecurrencePattern from a generic map (useful for configs)
  factory RecurrencePattern.fromMap(Map<String, dynamic> map) {
    final typeStr = (map['type'] ?? 'daily') as String;
    RecurrenceType type = RecurrenceType.daily;
    switch (typeStr) {
      case 'weekly':
        type = RecurrenceType.weekly;
        break;
      case 'monthly':
        type = RecurrenceType.monthly;
        break;
      case 'yearly':
        type = RecurrenceType.yearly;
        break;
      default:
        type = RecurrenceType.daily;
    }

    int interval = 1;
    try {
      if (map['interval'] is int) interval = map['interval'] as int;
      else if (map['interval'] != null) interval = int.parse(map['interval'].toString());
    } catch (_) {
      interval = 1;
    }

    List<int> daysOfWeek = <int>[];
    if (map['daysOfWeek'] is List) {
      final rawDays = List<dynamic>.from(map['daysOfWeek'] as List);
      daysOfWeek = rawDays
          .map((value) {
            if (value is num) {
              final day = value.toInt();
              return day == 0 ? 7 : day; // normalize 0 => Sunday (7)
            }
            if (value is String) {
              final parsed = int.tryParse(value.trim());
              if (parsed == null) return 0;
              return parsed == 0 ? 7 : parsed;
            }
            return 0;
          })
          .where((day) => day >= 1 && day <= 7)
          .toSet()
          .toList()
        ..sort();
    }

    int? dayOfMonth;
    if (map['dayOfMonth'] != null) {
      dayOfMonth = map['dayOfMonth'] is int ? map['dayOfMonth'] as int : int.tryParse(map['dayOfMonth'].toString());
    }

    DateTime? endDate;
    if (map['endDate'] is String) {
      try {
        endDate = DateTime.parse(map['endDate'] as String);
      } catch (_) {
        endDate = null;
      }
    }

    return RecurrencePattern(
      type: type,
      interval: interval,
      daysOfWeek: daysOfWeek,
      dayOfMonth: dayOfMonth,
      endDate: endDate,
    );
  }

  /// Get next due date based on pattern
  DateTime getNextDueDate(DateTime lastDueDate) {
    switch (type) {
      case RecurrenceType.daily:
        return lastDueDate.add(Duration(days: interval));
      case RecurrenceType.weekly:
        return lastDueDate.add(Duration(days: 7 * interval));
      case RecurrenceType.monthly:
        return DateTime(lastDueDate.year, lastDueDate.month + interval, dayOfMonth ?? lastDueDate.day);
      case RecurrenceType.yearly:
        return DateTime(lastDueDate.year + interval, lastDueDate.month, lastDueDate.day);
    }
  }
}

/// Recurrence type enumeration
@JsonEnum()
enum RecurrenceType {
  @JsonValue('daily')
  daily,
  
  @JsonValue('weekly')
  weekly,
  
  @JsonValue('monthly')
  monthly,
  
  @JsonValue('yearly')
  yearly;
}