import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a family unit with parent and children
class Family extends Equatable {
  /// Unique identifier for the family
  final String id;
  
  /// Family name or display name
  final String name;
  
  /// ID of the parent/guardian account
  final String parentId;
  
  /// List of child account IDs
  final List<String> childrenIds;
  
  /// Family creation timestamp
  final DateTime createdAt;
  
  /// Last update timestamp
  final DateTime updatedAt;
  
  /// Optional family description or motto
  final String? description;
  
  /// Family settings (e.g., point values, reward rules)
  final Map<String, dynamic> settings;

  const Family({
    required this.id,
    required this.name,
    required this.parentId,
    required this.childrenIds,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.settings = const {},
  });

  /// Create a copy of the family with updated fields
  Family copyWith({
    String? id,
    String? name,
    String? parentId,
    List<String>? childrenIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    Map<String, dynamic>? settings,
  }) {
    return Family(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      childrenIds: childrenIds ?? this.childrenIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      settings: settings ?? this.settings,
    );
  }

  /// Create Family from JSON
  factory Family.fromJson(Map<String, dynamic> json) {
    return Family(
      id: json['id'] as String,
      name: json['name'] as String,
      parentId: json['parentId'] as String,
      childrenIds: List<String>.from(json['childrenIds'] ?? []),
      createdAt: _parseTimestamp(json['createdAt']),
      updatedAt: _parseTimestamp(json['updatedAt']),
      description: json['description'] as String?,
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
    );
  }

  /// Create Family from Firestore document
  factory Family.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Family(
      id: doc.id,
      name: data['name'] as String,
      parentId: data['parentId'] as String,
      childrenIds: List<String>.from(data['childrenIds'] ?? []),
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
      description: data['description'] as String?,
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
    );
  }
  
  /// Helper method to parse timestamps from various formats
  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    
    if (value is Timestamp) {
      return value.toDate();
    }
    
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('❌ Error parsing timestamp string: $e');
        return DateTime.now();
      }
    }
    
    print('⚠️ Unknown timestamp format: ${value.runtimeType}');
    return DateTime.now();
  }

  /// Convert Family to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parentId': parentId,
      'childrenIds': childrenIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'description': description,
      'settings': settings,
    };
  }

  /// Convert Family to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'parentId': parentId,
      'childrenIds': childrenIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'description': description,
      'settings': settings,
    };
  }

  /// Add a child to the family
  Family addChild(String childId) {
    if (childrenIds.contains(childId)) return this;
    
    return copyWith(
      childrenIds: [...childrenIds, childId],
      updatedAt: DateTime.now(),
    );
  }

  /// Remove a child from the family
  Family removeChild(String childId) {
    return copyWith(
      childrenIds: childrenIds.where((id) => id != childId).toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// Check if a user is the parent of this family
  bool isParent(String userId) => parentId == userId;

  /// Check if a user is a child in this family
  bool isChild(String userId) => childrenIds.contains(userId);

  /// Check if a user is a member of this family
  bool isMember(String userId) => isParent(userId) || isChild(userId);

  /// Get the number of children in the family
  int get childrenCount => childrenIds.length;

  /// Check if the family has any children
  bool get hasChildren => childrenIds.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        name,
        parentId,
        childrenIds,
        createdAt,
        updatedAt,
        description,
        settings,
      ];

  @override
  String toString() => 'Family(id: $id, name: $name, parent: $parentId, children: ${childrenIds.length})';
}