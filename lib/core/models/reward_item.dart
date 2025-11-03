class RewardItem {
  final String id;
  final String title;
  final String description;
  final int points;
  final String category;
  final int iconCodePoint;
  final int colorValue;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  RewardItem({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.category,
    required this.iconCodePoint,
    required this.colorValue,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
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
    DateTime? createdAt,
    DateTime? updatedAt,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory RewardItem.fromJson(Map<String, dynamic> json) {
    return RewardItem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      points: json['points'],
      category: json['category'],
      iconCodePoint: json['iconCodePoint'],
      colorValue: json['colorValue'],
      isActive: json['isActive'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
}