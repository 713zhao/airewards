// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GoalModel _$GoalModelFromJson(Map<String, dynamic> json) => GoalModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      familyId: json['familyId'] as String,
      targetType: $enumDecode(_$GoalTargetTypeEnumMap, json['targetType']),
      targetPoints: (json['targetPoints'] as num?)?.toInt(),
      targetRewardId: json['targetRewardId'] as String?,
      targetRewardName: json['targetRewardName'] as String?,
      targetRewardCost: (json['targetRewardCost'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      startingPoints: (json['startingPoints'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$GoalModelToJson(GoalModel instance) => <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'familyId': instance.familyId,
      'targetType': _$GoalTargetTypeEnumMap[instance.targetType]!,
      'targetPoints': instance.targetPoints,
      'targetRewardId': instance.targetRewardId,
      'targetRewardName': instance.targetRewardName,
      'targetRewardCost': instance.targetRewardCost,
      'createdAt': instance.createdAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'isActive': instance.isActive,
      'startingPoints': instance.startingPoints,
    };

const _$GoalTargetTypeEnumMap = {
  GoalTargetType.points: 'points',
  GoalTargetType.reward: 'reward',
};
