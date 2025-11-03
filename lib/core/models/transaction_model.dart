import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'transaction_model.g.dart';

/// Transaction model representing point transactions in the AI Rewards system
@JsonSerializable()
class TransactionModel {
  final String id;
  final String userId;
  final String familyId;
  final TransactionType type;
  final int points;
  final String? taskId;
  final String? rewardId;
  final String? approvedByUserId;
  final String description;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.familyId,
    required this.type,
    required this.points,
    this.taskId,
    this.rewardId,
    this.approvedByUserId,
    required this.description,
    required this.createdAt,
    this.metadata = const {},
  });

  /// Create a new transaction for earning points
  factory TransactionModel.earnPoints({
    required String id,
    required String userId,
    required String familyId,
    required int points,
    required String taskId,
    String? approvedByUserId,
    String? description,
  }) {
    return TransactionModel(
      id: id,
      userId: userId,
      familyId: familyId,
      type: TransactionType.earned,
      points: points,
      taskId: taskId,
      approvedByUserId: approvedByUserId,
      description: description ?? 'Points earned for completing task',
      createdAt: DateTime.now(),
    );
  }

  /// Create a new transaction for spending points
  factory TransactionModel.spendPoints({
    required String id,
    required String userId,
    required String familyId,
    required int points,
    required String rewardId,
    String? description,
  }) {
    return TransactionModel(
      id: id,
      userId: userId,
      familyId: familyId,
      type: TransactionType.spent,
      points: points,
      rewardId: rewardId,
      description: description ?? 'Points spent on reward',
      createdAt: DateTime.now(),
    );
  }

  /// Create a transaction for bonus points
  factory TransactionModel.bonusPoints({
    required String id,
    required String userId,
    required String familyId,
    required int points,
    required String givenByUserId,
    String? description,
  }) {
    return TransactionModel(
      id: id,
      userId: userId,
      familyId: familyId,
      type: TransactionType.bonus,
      points: points,
      approvedByUserId: givenByUserId,
      description: description ?? 'Bonus points awarded',
      createdAt: DateTime.now(),
    );
  }

  /// Create a transaction for penalty points
  factory TransactionModel.penaltyPoints({
    required String id,
    required String userId,
    required String familyId,
    required int points,
    required String givenByUserId,
    String? description,
  }) {
    return TransactionModel(
      id: id,
      userId: userId,
      familyId: familyId,
      type: TransactionType.penalty,
      points: points,
      approvedByUserId: givenByUserId,
      description: description ?? 'Penalty points deducted',
      createdAt: DateTime.now(),
    );
  }

  /// Create from JSON
  factory TransactionModel.fromJson(Map<String, dynamic> json) => _$TransactionModelFromJson(json);

  /// Create from Firestore document
  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel.fromJson({
      ...data,
      'id': doc.id,
      'createdAt': (data['createdAt'] as Timestamp).toDate().toIso8601String(),
    });
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$TransactionModelToJson(this);

  /// Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Firestore document ID is separate
    json['createdAt'] = Timestamp.fromDate(createdAt);
    return json;
  }

  /// Create a copy with updated values
  TransactionModel copyWith({
    String? id,
    String? userId,
    String? familyId,
    TransactionType? type,
    int? points,
    String? taskId,
    String? rewardId,
    String? approvedByUserId,
    String? description,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      familyId: familyId ?? this.familyId,
      type: type ?? this.type,
      points: points ?? this.points,
      taskId: taskId ?? this.taskId,
      rewardId: rewardId ?? this.rewardId,
      approvedByUserId: approvedByUserId ?? this.approvedByUserId,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if transaction is positive (adds points)
  bool get isPositive => type == TransactionType.earned || type == TransactionType.bonus;

  /// Check if transaction is negative (removes points)
  bool get isNegative => type == TransactionType.spent || type == TransactionType.penalty;

  /// Get the actual point change (negative for spending/penalty)
  int get pointChange {
    switch (type) {
      case TransactionType.earned:
      case TransactionType.bonus:
        return points;
      case TransactionType.spent:
      case TransactionType.penalty:
        return -points;
    }
  }

  @override
  String toString() => 'TransactionModel(id: $id, type: $type, points: $points, user: $userId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Transaction type enumeration
@JsonEnum()
enum TransactionType {
  @JsonValue('earned')
  earned,
  
  @JsonValue('spent')
  spent,
  
  @JsonValue('bonus')
  bonus,
  
  @JsonValue('penalty')
  penalty;

  String get displayName {
    switch (this) {
      case TransactionType.earned:
        return 'Earned';
      case TransactionType.spent:
        return 'Spent';
      case TransactionType.bonus:
        return 'Bonus';
      case TransactionType.penalty:
        return 'Penalty';
    }
  }

  String get icon {
    switch (this) {
      case TransactionType.earned:
        return '✅';
      case TransactionType.spent:
        return '🛒';
      case TransactionType.bonus:
        return '🎁';
      case TransactionType.penalty:
        return '⚠️';
    }
  }
}