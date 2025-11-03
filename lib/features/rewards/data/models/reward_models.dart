import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/entities.dart';

/// Data model for reward entries extending the domain entity.
/// 
/// This model adds database-specific fields and serialization capabilities
/// to the domain RewardEntry entity. It includes sync tracking, versioning,
/// and conversion methods for local storage and API communication.
class RewardEntryModel extends RewardEntry {
  /// Sync version for conflict resolution
  final int version;
  
  const RewardEntryModel({
    required super.id,
    required super.userId,
    required super.points,
    required super.description,
    required super.categoryId,
    required super.type,
    required super.createdAt,
    super.updatedAt,
    super.isSynced = false,
    required this.version,
  });
  
  /// Creates a RewardEntryModel from domain entity
  factory RewardEntryModel.fromEntity(RewardEntry entry, {int? version}) {
    return RewardEntryModel(
      id: entry.id,
      userId: entry.userId,
      description: entry.description,
      points: entry.points,
      categoryId: entry.categoryId,
      type: entry.type,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      isSynced: entry.isSynced,
      version: version ?? 1,
    );
  }
  
  /// Creates a RewardEntryModel from JSON map
  factory RewardEntryModel.fromJson(Map<String, dynamic> json) {
    return RewardEntryModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      description: json['description'] as String,
      points: json['points'] as int,
      categoryId: json['categoryId'] as String,
      type: RewardType.fromString(json['type'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      isSynced: json['isSynced'] as bool? ?? false,
      version: json['version'] as int? ?? 1,
    );
  }
  
  /// Creates a RewardEntryModel from Firestore document
  factory RewardEntryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RewardEntryModel(
      id: doc.id,
      userId: data['userId'] as String,
      description: data['description'] as String,
      points: data['points'] as int,
      categoryId: data['categoryId'] as String,
      type: RewardType.fromString(data['type'] as String),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
      isSynced: data['isSynced'] as bool? ?? false,
      version: data['version'] as int? ?? 1,
    );
  }
  
  /// Converts to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'description': description,
      'points': points,
      'categoryId': categoryId,
      'type': type.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isSynced': isSynced,
      'version': version,
    };
  }
  
  /// Converts to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'description': description,
      'points': points,
      'categoryId': categoryId,
      'type': type.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isSynced': isSynced,
      'version': version,
    };
  }
  
  /// Creates a new instance with updated fields
  @override
  RewardEntryModel copyWith({
    String? id,
    String? userId,
    int? points,
    String? description,
    String? categoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    RewardType? type,
    int? version,
  }) {
    return RewardEntryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      points: points ?? this.points,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      type: type ?? this.type,
      version: version ?? this.version,
    );
  }
  
  /// Converts to domain entity
  @override
  RewardEntry toEntity() {
    return RewardEntry(
      id: id,
      userId: userId,
      description: description,
      points: points,
      categoryId: categoryId,
      type: type,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isSynced: isSynced,
    );
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RewardEntryModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          version == other.version;
  
  @override
  int get hashCode => id.hashCode ^ version.hashCode;
  
  @override
  String toString() {
    return 'RewardEntryModel{id: $id, description: $description, points: $points, version: $version}';
  }
}

/// Data model for categories extending the domain entity.
/// 
/// This model adds database-specific fields and serialization capabilities
/// to the domain RewardCategory entity. It includes sync tracking, versioning,
/// and conversion methods for local storage and API communication.
class CategoryModel extends RewardCategory {
  /// Sync version for conflict resolution
  final int version;
  /// Timestamp when category was created
  final DateTime createdAt;
  /// Timestamp when category was last updated
  final DateTime updatedAt;
  
  const CategoryModel({
    required super.id,
    required super.name,
    super.description,
    required super.color,
    required super.iconData,
    super.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });
  
  /// Creates a CategoryModel from domain entity
  factory CategoryModel.fromEntity(RewardCategory category, {int? version}) {
    final now = DateTime.now();
    return CategoryModel(
      id: category.id,
      name: category.name,
      description: category.description,
      color: category.color,
      iconData: category.iconData,
      isDefault: category.isDefault,
      createdAt: now,
      updatedAt: now,
      version: version ?? 1,
    );
  }
  
  /// Creates a CategoryModel from JSON map
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      color: Color(json['colorValue'] as int),
      iconData: IconData(
        json['iconCodePoint'] as int,
        fontFamily: json['iconFontFamily'] as String?,
      ),
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      version: json['version'] as int? ?? 1,
    );
  }
  
  /// Creates a CategoryModel from Firestore document
  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: data['name'] as String,
      description: data['description'] as String?,
      color: Color(data['colorValue'] as int),
      iconData: IconData(
        data['iconCodePoint'] as int,
        fontFamily: data['iconFontFamily'] as String?,
      ),
      isDefault: data['isDefault'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      version: data['version'] as int? ?? 1,
    );
  }
  
  /// Converts to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'colorValue': color.value,
      'iconCodePoint': iconData.codePoint,
      'iconFontFamily': iconData.fontFamily,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'version': version,
    };
  }
  
  /// Converts to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'colorValue': color.value,
      'iconCodePoint': iconData.codePoint,
      'iconFontFamily': iconData.fontFamily,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'version': version,
    };
  }
  
  /// Creates a new instance with updated fields
  @override
  CategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    Color? color,
    IconData? iconData,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      iconData: iconData ?? this.iconData,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }
  
  /// Converts to domain entity
  RewardCategory toEntity() {
    return RewardCategory(
      id: id,
      name: name,
      description: description,
      color: color,
      iconData: iconData,
      isDefault: isDefault,
    );
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          version == other.version;
  
  @override
  int get hashCode => id.hashCode ^ version.hashCode;
  
  @override
  String toString() {
    return 'CategoryModel{id: $id, name: $name, isDefault: $isDefault, version: $version}';
  }
}