// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransactionModel _$TransactionModelFromJson(Map<String, dynamic> json) =>
    TransactionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      familyId: json['familyId'] as String,
      type: $enumDecode(_$TransactionTypeEnumMap, json['type']),
      points: (json['points'] as num).toInt(),
      taskId: json['taskId'] as String?,
      rewardId: json['rewardId'] as String?,
      approvedByUserId: json['approvedByUserId'] as String?,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$TransactionModelToJson(TransactionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'familyId': instance.familyId,
      'type': _$TransactionTypeEnumMap[instance.type]!,
      'points': instance.points,
      'taskId': instance.taskId,
      'rewardId': instance.rewardId,
      'approvedByUserId': instance.approvedByUserId,
      'description': instance.description,
      'createdAt': instance.createdAt.toIso8601String(),
      'metadata': instance.metadata,
    };

const _$TransactionTypeEnumMap = {
  TransactionType.earned: 'earned',
  TransactionType.spent: 'spent',
  TransactionType.bonus: 'bonus',
  TransactionType.penalty: 'penalty',
};
