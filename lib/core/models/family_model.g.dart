// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FamilyModel _$FamilyModelFromJson(Map<String, dynamic> json) => FamilyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      adminUserId: json['adminUserId'] as String,
      memberIds: (json['memberIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
      settings: json['settings'] as Map<String, dynamic>? ?? const {},
      subscription: $enumDecodeNullable(
              _$FamilySubscriptionEnumMap, json['subscription']) ??
          FamilySubscription.free,
      isActive: json['isActive'] as bool? ?? true,
      inviteCode: json['inviteCode'] as String?,
      inviteCodeExpiry: json['inviteCodeExpiry'] == null
          ? null
          : DateTime.parse(json['inviteCodeExpiry'] as String),
    );

Map<String, dynamic> _$FamilyModelToJson(FamilyModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'adminUserId': instance.adminUserId,
      'memberIds': instance.memberIds,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastUpdatedAt': instance.lastUpdatedAt.toIso8601String(),
      'settings': instance.settings,
      'subscription': _$FamilySubscriptionEnumMap[instance.subscription]!,
      'isActive': instance.isActive,
      'inviteCode': instance.inviteCode,
      'inviteCodeExpiry': instance.inviteCodeExpiry?.toIso8601String(),
    };

const _$FamilySubscriptionEnumMap = {
  FamilySubscription.free: 'free',
  FamilySubscription.premium: 'premium',
  FamilySubscription.enterprise: 'enterprise',
};
