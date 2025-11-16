import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';

/// Represents a reward category for organizing reward entries
/// Categories help users organize their points by activity type
@immutable
class RewardCategory extends Equatable {
  /// Unique identifier for the category
  final String id;
  
  /// Display name of the category
  final String name;
  
  /// Optional description of the category
  final String? description;
  
  /// Color associated with the category for UI display
  final Color color;
  
  /// Icon data for visual representation
  final IconData iconData;
  
  /// Whether this is a default system category (cannot be deleted)
  final bool isDefault;

  const RewardCategory({
    required this.id,
    required this.name,
    this.description,
    required this.color,
    required this.iconData,
    this.isDefault = false,
  });

  /// Creates a RewardCategory with validation
  static Either<ValidationFailure, RewardCategory> create({
    required String id,
    required String name,
    String? description,
    required Color color,
    required IconData iconData,
    bool isDefault = false,
  }) {
    // Validate ID
    if (id.isEmpty) {
      return Left(ValidationFailure('Category ID cannot be empty'));
    }

    // Validate name
    final nameValidation = _validateName(name);
    if (nameValidation.isLeft) {
      return Left(nameValidation.left);
    }

    // Validate description length if provided
    if (description != null && description.length > 200) {
      return Left(ValidationFailure('Category description cannot exceed 200 characters'));
    }

    return Right(RewardCategory(
      id: id,
      name: name.trim(),
      description: description?.trim(),
      color: color,
      iconData: iconData,
      isDefault: isDefault,
    ));
  }

  /// Validates category name according to business rules
  static Either<ValidationFailure, String> _validateName(String name) {
    if (name.isEmpty) {
      return Left(ValidationFailure('Category name cannot be empty'));
    }
    
    if (name.trim().isEmpty) {
      return Left(ValidationFailure('Category name cannot be only whitespace'));
    }
    
    if (name.length > 50) {
      return Left(ValidationFailure('Category name cannot exceed 50 characters'));
    }
    
    // Check for valid characters (letters, numbers, spaces, basic punctuation)
    final validPattern = RegExp(r'^[a-zA-Z0-9\s\-_\.]+$');
    if (!validPattern.hasMatch(name)) {
      return Left(ValidationFailure('Category name contains invalid characters'));
    }
    
    return Right(name.trim());
  }

  /// Creates a copy of this category with updated values
  RewardCategory copyWith({
    String? id,
    String? name,
    String? description,
    Color? color,
    IconData? iconData,
    bool? isDefault,
  }) {
    return RewardCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      iconData: iconData ?? this.iconData,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  /// Converts category to JSON map for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color.value,
      'iconData': iconData.codePoint,
      'isDefault': isDefault,
    };
  }

  /// Creates category from JSON map
  static RewardCategory fromJson(Map<String, dynamic> json) {
    return RewardCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      color: Color(json['color'] as int),
      iconData: IconData(json['iconData'] as int, fontFamily: 'MaterialIcons'),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, name, description, color, iconData, isDefault];

  @override
  String toString() {
    return 'RewardCategory(id: $id, name: $name, description: $description, '
           'color: $color, iconData: $iconData, isDefault: $isDefault)';
  }
}