// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reward_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RewardModel _$RewardModelFromJson(Map<String, dynamic> json) => RewardModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      pointCost: (json['pointCost'] as num).toInt(),
      type: $enumDecode(_$RewardTypeEnumMap, json['type']),
      imageUrl: json['imageUrl'] as String?,
      familyId: json['familyId'] as String,
      createdByUserId: json['createdByUserId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      isUnlimited: json['isUnlimited'] as bool? ?? true,
      maxRedemptions: (json['maxRedemptions'] as num?)?.toInt(),
      currentRedemptions: (json['currentRedemptions'] as num?)?.toInt() ?? 0,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
      availability: $enumDecodeNullable(
              _$RewardAvailabilityEnumMap, json['availability']) ??
          RewardAvailability.always,
      eligibleUserIds: (json['eligibleUserIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$RewardModelToJson(RewardModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'category': instance.category,
      'pointCost': instance.pointCost,
      'type': _$RewardTypeEnumMap[instance.type]!,
      'imageUrl': instance.imageUrl,
      'familyId': instance.familyId,
      'createdByUserId': instance.createdByUserId,
      'createdAt': instance.createdAt.toIso8601String(),
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'isActive': instance.isActive,
      'isUnlimited': instance.isUnlimited,
      'maxRedemptions': instance.maxRedemptions,
      'currentRedemptions': instance.currentRedemptions,
      'tags': instance.tags,
      'metadata': instance.metadata,
      'availability': _$RewardAvailabilityEnumMap[instance.availability]!,
      'eligibleUserIds': instance.eligibleUserIds,
    };

const _$RewardTypeEnumMap = {
  RewardType.physical: 'physical',
  RewardType.digital: 'digital',
  RewardType.experience: 'experience',
  RewardType.privilege: 'privilege',
  RewardType.money: 'money',
};

const _$RewardAvailabilityEnumMap = {
  RewardAvailability.always: 'always',
  RewardAvailability.weekends: 'weekends',
  RewardAvailability.weekdays: 'weekdays',
  RewardAvailability.custom: 'custom',
};
