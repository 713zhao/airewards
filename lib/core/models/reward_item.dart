class RewardItem {
  final String id;
  final String title;
  final String description;
  final int points;
  final String category;
  final int iconCodePoint;
  final int colorValue;
  final bool isActive;
  final String? familyId; // Family this reward belongs to
  final String status; // 'pending' | 'approved'
  final String? createdBy;
  final String? approvedBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? approvedAt;

  RewardItem({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.category,
    required this.iconCodePoint,
    required this.colorValue,
    required this.isActive,
    this.familyId,
    this.status = 'approved',
    this.createdBy,
    this.approvedBy,
    required this.createdAt,
    this.updatedAt,
    this.approvedAt,
  });

  RewardItem copyWith({
    String? id,
    String? title,
    String? description,
    int? points,
    String? category,
    int? iconCodePoint,
    int? colorValue,
    bool? isActive,
    String? familyId,
    String? status,
    String? createdBy,
    String? approvedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? approvedAt,
  }) {
    return RewardItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      points: points ?? this.points,
      category: category ?? this.category,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      isActive: isActive ?? this.isActive,
      familyId: familyId ?? this.familyId,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      approvedBy: approvedBy ?? this.approvedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'points': points,
      'category': category,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
      'isActive': isActive,
      'familyId': familyId,
      'status': status,
      'createdBy': createdBy,
      'approvedBy': approvedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
    };
  }

  factory RewardItem.fromJson(Map<String, dynamic> json) {
    return RewardItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      points: json['points'] as int,
      category: json['category'] as String,
      iconCodePoint: json['iconCodePoint'] as int,
      colorValue: json['colorValue'] as int,
      isActive: json['isActive'] as bool,
      familyId: json['familyId'] as String?,
      status: json['status'] as String? ?? 'approved',
      createdBy: json['createdBy'] as String?,
      approvedBy: json['approvedBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt'] as String) : null,
    );
  }
}