import 'package:equatable/equatable.dart';

/// Domain entity representing a redemption category.
/// 
/// This entity defines categories for organizing redemption options
/// and provides filtering and organizational structure.
class RedemptionCategory extends Equatable {
  /// Unique identifier for the category
  final String id;
  
  /// Display name of the category
  final String name;
  
  /// Description of what this category contains
  final String description;
  
  /// Icon identifier for visual representation
  final String iconName;
  
  /// Whether this category is active and visible
  final bool isActive;
  
  /// Sort order for display purposes
  final int sortOrder;
  
  /// Timestamp when this category was created
  final DateTime createdAt;
  
  /// Timestamp when this category was last updated
  final DateTime? updatedAt;

  const RedemptionCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor to create a new redemption category with validation
  factory RedemptionCategory.create({
    required String id,
    required String name,
    required String description,
    required String iconName,
    bool isActive = true,
    int sortOrder = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RedemptionCategory(
      id: id,
      name: name,
      description: description,
      iconName: iconName,
      isActive: isActive,
      sortOrder: sortOrder,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt,
    );
  }

  /// Creates a copy of this category with updated fields
  RedemptionCategory copyWith({
    String? id,
    String? name,
    String? description,
    String? iconName,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RedemptionCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Validates the category data
  bool get isValid {
    return id.isNotEmpty &&
           name.isNotEmpty &&
           description.isNotEmpty &&
           iconName.isNotEmpty;
  }

  /// Returns a formatted display name
  String get displayName => name.trim();

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    iconName,
    isActive,
    sortOrder,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() {
    return 'RedemptionCategory(id: $id, name: $name, isActive: $isActive)';
  }
}

/// Predefined redemption categories for common use cases
class RedemptionCategories {
  static final DateTime _defaultCreatedAt = DateTime(2025, 1, 1);

  static final List<RedemptionCategory> defaultCategories = [
    RedemptionCategory(
      id: 'gift_cards',
      name: 'Gift Cards',
      description: 'Digital and physical gift cards for various retailers',
      iconName: 'card_giftcard',
      isActive: true,
      sortOrder: 1,
      createdAt: _defaultCreatedAt,
    ),
    RedemptionCategory(
      id: 'electronics',
      name: 'Electronics',
      description: 'Gadgets, accessories, and electronic devices',
      iconName: 'devices',
      isActive: true,
      sortOrder: 2,
      createdAt: _defaultCreatedAt,
    ),
    RedemptionCategory(
      id: 'experiences',
      name: 'Experiences',
      description: 'Events, activities, and experiential rewards',
      iconName: 'local_activity',
      isActive: true,
      sortOrder: 3,
      createdAt: _defaultCreatedAt,
    ),
    RedemptionCategory(
      id: 'charity',
      name: 'Charity Donations',
      description: 'Donate points to charitable organizations',
      iconName: 'favorite',
      isActive: true,
      sortOrder: 4,
      createdAt: _defaultCreatedAt,
    ),
    RedemptionCategory(
      id: 'merchandise',
      name: 'Merchandise',
      description: 'Branded items, clothing, and accessories',
      iconName: 'shopping_bag',
      isActive: true,
      sortOrder: 5,
      createdAt: _defaultCreatedAt,
    ),
  ];

  /// Gets a category by ID
  static RedemptionCategory? getCategoryById(String id) {
    try {
      return defaultCategories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Gets all active categories sorted by sort order
  static List<RedemptionCategory> getActiveCategories() {
    return defaultCategories
        .where((category) => category.isActive)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }
}