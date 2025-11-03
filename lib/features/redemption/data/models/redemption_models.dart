import '../../domain/entities/entities.dart';

/// Data model for RedemptionOption with JSON serialization support.
/// 
/// This model extends the domain entity with data layer specific functionality
/// including JSON serialization/deserialization, data transformation, and
/// mapping between different data representations.
class RedemptionOptionModel extends RedemptionOption {
  /// Sync version for conflict resolution
  final int version;
  
  const RedemptionOptionModel({
    required super.id,
    required super.title,
    required super.description,
    required super.requiredPoints,
    required super.categoryId,
    required super.isActive,
    required super.createdAt,
    super.expiryDate,
    super.imageUrl,
    super.updatedAt,
    required this.version,
  });

  /// Creates a RedemptionOptionModel from a domain entity.
  /// 
  /// This factory method converts a domain RedemptionOption to its
  /// corresponding data model for persistence and serialization.
  /// 
  /// Parameters:
  /// - [option]: Domain entity to convert
  /// - [version]: Version number for conflict resolution
  /// 
  /// Returns: [RedemptionOptionModel] with same data
  factory RedemptionOptionModel.fromEntity(RedemptionOption option, {int? version}) {
    return RedemptionOptionModel(
      id: option.id,
      title: option.title,
      description: option.description,
      requiredPoints: option.requiredPoints,
      categoryId: option.categoryId,
      isActive: option.isActive,
      createdAt: option.createdAt,
      expiryDate: option.expiryDate,
      imageUrl: option.imageUrl,
      updatedAt: option.updatedAt,
      version: version ?? 1,
    );
  }

  /// Creates a RedemptionOptionModel from JSON data.
  /// 
  /// This factory method handles deserialization from API responses,
  /// local storage, and other JSON data sources.
  /// 
  /// Parameters:
  /// - [json]: JSON map containing redemption option data
  /// 
  /// Returns: [RedemptionOptionModel] parsed from JSON
  /// 
  /// Throws: [FormatException] if JSON is malformed
  factory RedemptionOptionModel.fromJson(Map<String, dynamic> json) {
    return RedemptionOptionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      requiredPoints: json['requiredPoints'] as int,
      categoryId: json['categoryId'] as String,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiryDate: json['expiryDate'] != null 
          ? DateTime.parse(json['expiryDate'] as String) 
          : null,
      imageUrl: json['imageUrl'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      version: json['version'] as int? ?? 1,
    );
  }

  /// Creates a RedemptionOptionModel from Firestore document.
  factory RedemptionOptionModel.fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RedemptionOptionModel(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String,
      requiredPoints: data['requiredPoints'] as int,
      categoryId: data['categoryId'] as String,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as dynamic).toDate() 
          : DateTime.now(),
      expiryDate: data['expiryDate'] != null
          ? (data['expiryDate'] as dynamic).toDate()
          : null,
      imageUrl: data['imageUrl'] as String?,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as dynamic).toDate()
          : null,
      version: data['version'] as int? ?? 1,
    );
  }

  /// Converts to Firestore document data.
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'requiredPoints': requiredPoints,
      'categoryId': categoryId,
      'isActive': isActive,
      'createdAt': createdAt,
      if (expiryDate != null) 'expiryDate': expiryDate,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (updatedAt != null) 'updatedAt': updatedAt,
      'version': version,
    };
  }

  /// Converts the model to JSON for serialization.
  /// 
  /// This method handles serialization for API requests, local storage,
  /// and other JSON data persistence needs.
  /// 
  /// Returns: [Map<String, dynamic>] JSON representation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'requiredPoints': requiredPoints,
      'categoryId': categoryId,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      if (expiryDate != null) 'expiryDate': expiryDate!.toIso8601String(),
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// Creates a copy of the model with updated fields.
  /// 
  /// This method enables immutable updates for data synchronization,
  /// caching, and state management scenarios.
  /// 
  /// Parameters: Optional new values for any field
  /// 
  /// Returns: [RedemptionOptionModel] with updated values
  @override
  RedemptionOptionModel copyWith({
    String? id,
    String? title,
    String? description,
    int? requiredPoints,
    String? categoryId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? expiryDate,
    String? imageUrl,
    DateTime? updatedAt,
    int? version,
  }) {
    return RedemptionOptionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      requiredPoints: requiredPoints ?? this.requiredPoints,
      categoryId: categoryId ?? this.categoryId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      expiryDate: expiryDate ?? this.expiryDate,
      imageUrl: imageUrl ?? this.imageUrl,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }

  /// Converts to domain entity.
  /// 
  /// This method provides the mapping from data model back to domain entity
  /// for use in business logic and presentation layers.
  /// 
  /// Returns: [RedemptionOption] domain entity
  RedemptionOption toEntity() {
    return RedemptionOption(
      id: id,
      title: title,
      description: description,
      requiredPoints: requiredPoints,
      categoryId: categoryId,
      isActive: isActive,
      createdAt: createdAt,
      expiryDate: expiryDate,
      imageUrl: imageUrl,
      updatedAt: updatedAt,
    );
  }
}

/// Data model for RedemptionTransaction with JSON serialization support.
/// 
/// This model extends the domain entity with data layer specific functionality
/// including JSON serialization/deserialization, status mapping, and
/// data transformation for different storage formats.
class RedemptionTransactionModel extends RedemptionTransaction {
  /// Sync version for conflict resolution
  final int version;
  
  const RedemptionTransactionModel({
    required super.id,
    required super.userId,
    required super.optionId,
    required super.pointsUsed,
    required super.redeemedAt,
    required super.status,
    required super.createdAt,
    super.notes,
    super.updatedAt,
    super.completedAt,
    super.cancelledAt,
    required this.version,
  });

  /// Creates a RedemptionTransactionModel from a domain entity.
  factory RedemptionTransactionModel.fromEntity(RedemptionTransaction transaction, {int? version}) {
    return RedemptionTransactionModel(
      id: transaction.id,
      userId: transaction.userId,
      optionId: transaction.optionId,
      pointsUsed: transaction.pointsUsed,
      redeemedAt: transaction.redeemedAt,
      status: transaction.status,
      createdAt: transaction.createdAt,
      notes: transaction.notes,
      updatedAt: transaction.updatedAt,
      completedAt: transaction.completedAt,
      cancelledAt: transaction.cancelledAt,
      version: version ?? 1,
    );
  }

  /// Creates a RedemptionTransactionModel from JSON data.
  /// 
  /// Handles status string to enum conversion and datetime parsing
  /// from various API and storage formats.
  factory RedemptionTransactionModel.fromJson(Map<String, dynamic> json) {
    return RedemptionTransactionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      optionId: json['optionId'] as String,
      pointsUsed: json['pointsUsed'] as int,
      redeemedAt: DateTime.parse(json['redeemedAt'] as String),
      status: _statusFromString(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      notes: json['notes'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'] as String)
          : null,
      version: json['version'] as int? ?? 1,
    );
  }

  /// Creates a RedemptionTransactionModel from Firestore document.
  factory RedemptionTransactionModel.fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RedemptionTransactionModel(
      id: doc.id,
      userId: data['userId'] as String,
      optionId: data['optionId'] as String,
      pointsUsed: data['pointsUsed'] as int,
      redeemedAt: (data['redeemedAt'] as dynamic).toDate(),
      status: _statusFromString(data['status'] as String),
      createdAt: (data['createdAt'] as dynamic).toDate(),
      notes: data['notes'] as String?,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as dynamic).toDate()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as dynamic).toDate()
          : null,
      cancelledAt: data['cancelledAt'] != null
          ? (data['cancelledAt'] as dynamic).toDate()
          : null,
      version: data['version'] as int? ?? 1,
    );
  }

  /// Converts to Firestore document data.
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'optionId': optionId,
      'pointsUsed': pointsUsed,
      'status': _statusToString(status),
      'redeemedAt': redeemedAt,
      'createdAt': createdAt,
      if (notes != null) 'notes': notes,
      if (updatedAt != null) 'updatedAt': updatedAt,
      if (completedAt != null) 'completedAt': completedAt,
      if (cancelledAt != null) 'cancelledAt': cancelledAt,
      'version': version,
    };
  }

  /// Converts the model to JSON for serialization.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'optionId': optionId,
      'pointsUsed': pointsUsed,
      'status': _statusToString(status),
      'redeemedAt': redeemedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      if (notes != null) 'notes': notes,
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      if (cancelledAt != null) 'cancelledAt': cancelledAt!.toIso8601String(),
    };
  }

  /// Creates a copy of the model with updated fields.
  @override
  RedemptionTransactionModel copyWith({
    String? id,
    String? userId,
    String? optionId,
    int? pointsUsed,
    DateTime? redeemedAt,
    RedemptionStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    int? version,
  }) {
    return RedemptionTransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      optionId: optionId ?? this.optionId,
      pointsUsed: pointsUsed ?? this.pointsUsed,
      redeemedAt: redeemedAt ?? this.redeemedAt,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      version: version ?? this.version,
    );
  }

  /// Converts to domain entity.
  RedemptionTransaction toEntity() {
    return RedemptionTransaction(
      id: id,
      userId: userId,
      optionId: optionId,
      pointsUsed: pointsUsed,
      redeemedAt: redeemedAt,
      status: status,
      createdAt: createdAt,
      notes: notes,
      updatedAt: updatedAt,
      completedAt: completedAt,
      cancelledAt: cancelledAt,
    );
  }

  /// Helper method to convert status enum to string for JSON serialization.
  static String _statusToString(RedemptionStatus status) {
    switch (status) {
      case RedemptionStatus.pending:
        return 'pending';
      case RedemptionStatus.completed:
        return 'completed';
      case RedemptionStatus.cancelled:
        return 'cancelled';
      case RedemptionStatus.expired:
        return 'expired';
    }
  }

  /// Helper method to convert status string to enum from JSON deserialization.
  static RedemptionStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return RedemptionStatus.pending;
      case 'completed':
        return RedemptionStatus.completed;
      case 'cancelled':
        return RedemptionStatus.cancelled;
      case 'expired':
        return RedemptionStatus.expired;
      default:
        throw FormatException('Unknown redemption status: $status');
    }
  }
}

/// Data model for RedemptionStats with JSON serialization support.
/// 
/// This model provides comprehensive statistics about user redemption activity
/// with support for data aggregation, time-based filtering, and analytics.
class RedemptionStatsModel {
  final String userId;
  final int totalRedemptions;
  final int totalPointsRedeemed;
  final int pendingRedemptions;
  final int completedRedemptions;
  final int cancelledRedemptions;
  final double averagePointsPerRedemption;
  final Map<String, int> redemptionsByCategory;
  final DateTime? firstRedemptionDate;
  final DateTime? lastRedemptionDate;
  final int redemptionsThisMonth;
  final int redemptionsThisYear;
  final Map<String, dynamic>? metadata;

  const RedemptionStatsModel({
    required this.userId,
    required this.totalRedemptions,
    required this.totalPointsRedeemed,
    required this.pendingRedemptions,
    required this.completedRedemptions,
    required this.cancelledRedemptions,
    required this.averagePointsPerRedemption,
    required this.redemptionsByCategory,
    this.firstRedemptionDate,
    this.lastRedemptionDate,
    required this.redemptionsThisMonth,
    required this.redemptionsThisYear,
    this.metadata,
  });

  /// Creates a RedemptionStatsModel from JSON data.
  factory RedemptionStatsModel.fromJson(Map<String, dynamic> json) {
    return RedemptionStatsModel(
      userId: json['userId'] as String,
      totalRedemptions: json['totalRedemptions'] as int,
      totalPointsRedeemed: json['totalPointsRedeemed'] as int,
      pendingRedemptions: json['pendingRedemptions'] as int,
      completedRedemptions: json['completedRedemptions'] as int,
      cancelledRedemptions: json['cancelledRedemptions'] as int,
      averagePointsPerRedemption: (json['averagePointsPerRedemption'] as num).toDouble(),
      redemptionsByCategory: Map<String, int>.from(json['redemptionsByCategory'] as Map),
      firstRedemptionDate: json['firstRedemptionDate'] != null
          ? DateTime.parse(json['firstRedemptionDate'] as String)
          : null,
      lastRedemptionDate: json['lastRedemptionDate'] != null
          ? DateTime.parse(json['lastRedemptionDate'] as String)
          : null,
      redemptionsThisMonth: json['redemptionsThisMonth'] as int,
      redemptionsThisYear: json['redemptionsThisYear'] as int,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }

  /// Converts the model to JSON for serialization.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalRedemptions': totalRedemptions,
      'totalPointsRedeemed': totalPointsRedeemed,
      'pendingRedemptions': pendingRedemptions,
      'completedRedemptions': completedRedemptions,
      'cancelledRedemptions': cancelledRedemptions,
      'averagePointsPerRedemption': averagePointsPerRedemption,
      'redemptionsByCategory': redemptionsByCategory,
      if (firstRedemptionDate != null) 
        'firstRedemptionDate': firstRedemptionDate!.toIso8601String(),
      if (lastRedemptionDate != null) 
        'lastRedemptionDate': lastRedemptionDate!.toIso8601String(),
      'redemptionsThisMonth': redemptionsThisMonth,
      'redemptionsThisYear': redemptionsThisYear,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Creates an empty stats model for a user.
  factory RedemptionStatsModel.empty(String userId) {
    return RedemptionStatsModel(
      userId: userId,
      totalRedemptions: 0,
      totalPointsRedeemed: 0,
      pendingRedemptions: 0,
      completedRedemptions: 0,
      cancelledRedemptions: 0,
      averagePointsPerRedemption: 0.0,
      redemptionsByCategory: {},
      redemptionsThisMonth: 0,
      redemptionsThisYear: 0,
    );
  }

  @override
  String toString() {
    return 'RedemptionStatsModel(userId: $userId, totalRedemptions: $totalRedemptions, '
           'totalPointsRedeemed: $totalPointsRedeemed, averagePoints: $averagePointsPerRedemption)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RedemptionStatsModel &&
        other.userId == userId &&
        other.totalRedemptions == totalRedemptions &&
        other.totalPointsRedeemed == totalPointsRedeemed;
  }

  @override
  int get hashCode {
    return userId.hashCode ^ 
        totalRedemptions.hashCode ^ 
        totalPointsRedeemed.hashCode;
  }
}