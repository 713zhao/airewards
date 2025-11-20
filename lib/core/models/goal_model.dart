import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'goal_model.g.dart';

/// Goal model representing a user's point or reward target
@JsonSerializable()
class GoalModel {
  final String id;
  final String userId;
  final String familyId;
  final GoalTargetType targetType;
  final int? targetPoints;
  final String? targetRewardId;
  final String? targetRewardName;
  final int? targetRewardCost;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isActive;
  final int startingPoints;

  const GoalModel({
    required this.id,
    required this.userId,
    required this.familyId,
    required this.targetType,
    this.targetPoints,
    this.targetRewardId,
    this.targetRewardName,
    this.targetRewardCost,
    required this.createdAt,
    this.completedAt,
    this.isActive = true,
    this.startingPoints = 0,
  });

  /// Create a new points goal
  factory GoalModel.createPointsGoal({
    required String id,
    required String userId,
    required String familyId,
    required int targetPoints,
    required int startingPoints,
  }) {
    return GoalModel(
      id: id,
      userId: userId,
      familyId: familyId,
      targetType: GoalTargetType.points,
      targetPoints: targetPoints,
      createdAt: DateTime.now(),
      startingPoints: startingPoints,
    );
  }

  /// Create a new reward goal
  factory GoalModel.createRewardGoal({
    required String id,
    required String userId,
    required String familyId,
    required String targetRewardId,
    required String targetRewardName,
    required int targetRewardCost,
    required int startingPoints,
  }) {
    return GoalModel(
      id: id,
      userId: userId,
      familyId: familyId,
      targetType: GoalTargetType.reward,
      targetRewardId: targetRewardId,
      targetRewardName: targetRewardName,
      targetRewardCost: targetRewardCost,
      targetPoints: targetRewardCost,
      createdAt: DateTime.now(),
      startingPoints: startingPoints,
    );
  }

  /// Create from JSON
  factory GoalModel.fromJson(Map<String, dynamic> json) => _$GoalModelFromJson(json);

  /// Create from Firestore document
  factory GoalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GoalModel.fromJson({
      ...data,
      'id': doc.id,
      'createdAt': (data['createdAt'] as Timestamp).toDate().toIso8601String(),
      'completedAt': data['completedAt'] != null 
          ? (data['completedAt'] as Timestamp).toDate().toIso8601String() 
          : null,
    });
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$GoalModelToJson(this);

  /// Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id');
    json['createdAt'] = Timestamp.fromDate(createdAt);
    json['completedAt'] = completedAt != null ? Timestamp.fromDate(completedAt!) : null;
    return json;
  }

  /// Create a copy with updated values
  GoalModel copyWith({
    String? id,
    String? userId,
    String? familyId,
    GoalTargetType? targetType,
    int? targetPoints,
    String? targetRewardId,
    String? targetRewardName,
    int? targetRewardCost,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? isActive,
    int? startingPoints,
  }) {
    return GoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      familyId: familyId ?? this.familyId,
      targetType: targetType ?? this.targetType,
      targetPoints: targetPoints ?? this.targetPoints,
      targetRewardId: targetRewardId ?? this.targetRewardId,
      targetRewardName: targetRewardName ?? this.targetRewardName,
      targetRewardCost: targetRewardCost ?? this.targetRewardCost,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      isActive: isActive ?? this.isActive,
      startingPoints: startingPoints ?? this.startingPoints,
    );
  }

  /// Mark goal as completed
  GoalModel markCompleted() {
    return copyWith(
      completedAt: DateTime.now(),
      isActive: false,
    );
  }

  /// Get target description for display
  String get targetDescription {
    if (targetType == GoalTargetType.points) {
      return '$targetPoints points';
    } else {
      return targetRewardName ?? 'Reward';
    }
  }

  /// Get points needed to reach goal
  int getPointsNeeded(int currentPoints) {
    final target = targetPoints ?? 0;
    final needed = target - currentPoints;
    return needed > 0 ? needed : 0;
  }

  /// Calculate progress percentage
  double getProgress(int currentPoints) {
    final target = targetPoints ?? 0;
    if (target == 0) return 0;
    
    // If target equals starting points, that's invalid but show as 0%
    final range = target - startingPoints;
    if (range <= 0) return 0;
    
    final earned = currentPoints - startingPoints;
    final progress = earned / range;
    
    print('🎯 Progress calculation:');
    print('   Current: $currentPoints, Starting: $startingPoints, Target: $target');
    print('   Earned: $earned, Range: $range, Progress: ${(progress * 100).toStringAsFixed(1)}%');
    
    return progress.clamp(0.0, 1.0);
  }

  /// Check if goal is completed
  bool isGoalCompleted(int currentPoints) {
    final target = targetPoints ?? 0;
    return currentPoints >= target;
  }

  @override
  String toString() => 'GoalModel(id: $id, targetType: $targetType, target: $targetDescription)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Goal target type enumeration
@JsonEnum()
enum GoalTargetType {
  @JsonValue('points')
  points,
  
  @JsonValue('reward')
  reward;

  String get displayName {
    switch (this) {
      case GoalTargetType.points:
        return 'Points Target';
      case GoalTargetType.reward:
        return 'Reward Target';
    }
  }
}
