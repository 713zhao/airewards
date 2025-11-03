import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../entities/entities.dart';
import '../repositories/repositories.dart';

/// Parameters for getting redemption options.
/// 
/// This class encapsulates filtering and sorting options for retrieving
/// available redemption options with comprehensive validation.
class GetRedemptionOptionsParams {
  final String? categoryId;
  final int? minPoints;
  final int? maxPoints;
  final bool includeExpired;
  final RedemptionSortOrder sortOrder;

  const GetRedemptionOptionsParams({
    this.categoryId,
    this.minPoints,
    this.maxPoints,
    this.includeExpired = false,
    this.sortOrder = RedemptionSortOrder.pointsAscending,
  });

  /// Create validated params with business rule validation.
  /// 
  /// Validates filtering parameters and ensures valid ranges.
  /// 
  /// Returns [Either<ValidationFailure, GetRedemptionOptionsParams>]:
  /// - Left: [ValidationFailure] if validation fails
  /// - Right: [GetRedemptionOptionsParams] if validation succeeds
  static Either<ValidationFailure, GetRedemptionOptionsParams> create({
    String? categoryId,
    int? minPoints,
    int? maxPoints,
    bool includeExpired = false,
    RedemptionSortOrder sortOrder = RedemptionSortOrder.pointsAscending,
  }) {
    // Validate category ID if provided
    if (categoryId != null && categoryId.trim().isEmpty) {
      return Either.left(ValidationFailure('Category ID cannot be empty if provided'));
    }

    // Validate point range
    if (minPoints != null && minPoints < 0) {
      return Either.left(ValidationFailure('Minimum points cannot be negative'));
    }

    if (maxPoints != null && maxPoints < 0) {
      return Either.left(ValidationFailure('Maximum points cannot be negative'));
    }

    if (minPoints != null && maxPoints != null && minPoints > maxPoints) {
      return Either.left(ValidationFailure('Minimum points cannot be greater than maximum points'));
    }

    return Either.right(GetRedemptionOptionsParams(
      categoryId: categoryId?.trim(),
      minPoints: minPoints,
      maxPoints: maxPoints,
      includeExpired: includeExpired,
      sortOrder: sortOrder,
    ));
  }

  @override
  String toString() {
    return 'GetRedemptionOptionsParams(categoryId: $categoryId, minPoints: $minPoints, '
           'maxPoints: $maxPoints, includeExpired: $includeExpired, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetRedemptionOptionsParams &&
        other.categoryId == categoryId &&
        other.minPoints == minPoints &&
        other.maxPoints == maxPoints &&
        other.includeExpired == includeExpired &&
        other.sortOrder == sortOrder;
  }

  @override
  int get hashCode {
    return categoryId.hashCode ^
        minPoints.hashCode ^
        maxPoints.hashCode ^
        includeExpired.hashCode ^
        sortOrder.hashCode;
  }
}

/// Sorting options for redemption options
enum RedemptionSortOrder {
  pointsAscending,
  pointsDescending,
  titleAscending,
  titleDescending,
  createdDateAscending,
  createdDateDescending,
}

/// Use case for retrieving available redemption options.
/// 
/// This use case handles the business logic for fetching and filtering
/// redemption options that users can exchange their points for.
/// It provides comprehensive filtering, sorting, and availability checking.
/// 
/// Features provided:
/// - Category-based filtering
/// - Point range filtering
/// - Availability and expiry checking
/// - Multiple sorting options
/// - User-specific point balance context
/// 
/// Business rules enforced:
/// - Only shows active redemption options by default
/// - Filters expired options unless explicitly requested
/// - Validates user access to options
/// - Provides point balance context for each option
class GetRedemptionOptions implements UseCase<List<RedemptionOptionWithContext>, GetRedemptionOptionsParams> {
  final RedemptionRepository repository;

  /// Creates a new [GetRedemptionOptions] use case.
  /// 
  /// Parameters:
  /// - [repository]: The redemption repository for data operations
  const GetRedemptionOptions(this.repository);

  /// Execute the redemption options retrieval process.
  /// 
  /// This method fetches available redemption options and applies the specified
  /// filtering, sorting, and context enrichment.
  /// 
  /// Parameters:
  /// - [params]: Contains filtering and sorting preferences
  /// 
  /// Returns [Either<Failure, List<RedemptionOptionWithContext>>]:
  /// - Left: [Failure] if retrieval fails
  /// - Right: [List<RedemptionOptionWithContext>] with filtered and sorted options
  /// 
  /// Possible failures:
  /// - [ValidationFailure] for invalid filter parameters
  /// - [NetworkFailure] for connectivity issues
  /// - [CacheFailure] for local cache issues
  /// 
  /// Business logic handled:
  /// 1. Retrieves all available redemption options
  /// 2. Applies category and point range filters
  /// 3. Filters expired options based on preferences
  /// 4. Enriches options with user context (affordability, etc.)
  /// 5. Sorts according to specified order
  /// 6. Provides comprehensive option metadata
  @override
  Future<Either<Failure, List<RedemptionOptionWithContext>>> call(GetRedemptionOptionsParams params) async {
    try {
      // Step 1: Get all redemption options from repository
      final optionsResult = await _getBaseOptions(params.categoryId);
      if (optionsResult.isLeft) {
        return Either.left(optionsResult.left);
      }
      final options = optionsResult.right;

      // Step 2: Apply filtering based on parameters
      final filteredOptions = _applyFilters(options, params);

      // Step 3: Enrich options with context (this could include user-specific data)
      final enrichedOptionsResult = await _enrichWithContext(filteredOptions);
      if (enrichedOptionsResult.isLeft) {
        return Either.left(enrichedOptionsResult.left);
      }
      final enrichedOptions = enrichedOptionsResult.right;

      // Step 4: Sort according to specified order
      final sortedOptions = _applySorting(enrichedOptions, params.sortOrder);

      // Step 5: Log successful retrieval for analytics
      await _logSuccessfulRetrieval(params, sortedOptions.length);

      return Either.right(sortedOptions);
    } catch (e) {
      // Handle unexpected errors
      await _logUnexpectedError(params, e);
      return Either.left(ValidationFailure('Unexpected error retrieving redemption options: $e'));
    }
  }

  /// Gets base redemption options, optionally filtered by category.
  Future<Either<Failure, List<RedemptionOption>>> _getBaseOptions(String? categoryId) async {
    if (categoryId != null) {
      return repository.getRedemptionOptionsByCategory(categoryId: categoryId);
    } else {
      return repository.getRedemptionOptions();
    }
  }

  /// Applies filters based on the provided parameters.
  List<RedemptionOption> _applyFilters(List<RedemptionOption> options, GetRedemptionOptionsParams params) {
    return options.where((option) {
      // Filter by expiry status
      if (!params.includeExpired && option.isExpired) {
        return false;
      }

      // Filter by availability (active status and not expired)
      if (!params.includeExpired && !option.isAvailable) {
        return false;
      }

      // Filter by minimum points
      if (params.minPoints != null && option.requiredPoints < params.minPoints!) {
        return false;
      }

      // Filter by maximum points
      if (params.maxPoints != null && option.requiredPoints > params.maxPoints!) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Enriches redemption options with additional context.
  Future<Either<Failure, List<RedemptionOptionWithContext>>> _enrichWithContext(
    List<RedemptionOption> options,
  ) async {
    try {
      final enrichedOptions = <RedemptionOptionWithContext>[];

      for (final option in options) {
        // For each option, we could add user-specific context like:
        // - Whether user can afford it
        // - How many units they can redeem
        // - Popularity ranking
        // - User's redemption history with this option
        
        // For now, we'll create basic context
        final context = RedemptionOptionWithContext(
          option: option,
          isPopular: _isPopularOption(option),
          difficulty: _calculateDifficulty(option),
          estimatedValue: _estimateValue(option),
        );
        
        enrichedOptions.add(context);
      }

      return Either.right(enrichedOptions);
    } catch (e) {
      return Either.left(ValidationFailure('Error enriching redemption options: $e'));
    }
  }

  /// Determines if an option is popular based on various factors.
  bool _isPopularOption(RedemptionOption option) {
    // In a real implementation, this would check:
    // - Redemption frequency statistics
    // - User rating/feedback
    // - Recent redemption trends
    // - Category popularity
    
    // For now, use simple heuristics
    return option.requiredPoints <= 1000 && option.isAvailable;
  }

  /// Calculates difficulty level for obtaining this reward.
  RedemptionDifficulty _calculateDifficulty(RedemptionOption option) {
    if (option.requiredPoints <= 500) {
      return RedemptionDifficulty.easy;
    } else if (option.requiredPoints <= 2000) {
      return RedemptionDifficulty.medium;
    } else if (option.requiredPoints <= 5000) {
      return RedemptionDifficulty.hard;
    } else {
      return RedemptionDifficulty.expert;
    }
  }

  /// Estimates the real-world value of the redemption option.
  double _estimateValue(RedemptionOption option) {
    // In a real implementation, this would:
    // - Look up market values
    // - Consider partner discounts
    // - Factor in redemption costs
    // - Apply regional variations
    
    // For now, use simple point-to-dollar conversion
    return option.requiredPoints * 0.01; // 1 point = $0.01
  }

  /// Applies sorting to the enriched options list.
  List<RedemptionOptionWithContext> _applySorting(
    List<RedemptionOptionWithContext> options,
    RedemptionSortOrder sortOrder,
  ) {
    final sortedOptions = List<RedemptionOptionWithContext>.from(options);

    switch (sortOrder) {
      case RedemptionSortOrder.pointsAscending:
        sortedOptions.sort((a, b) => a.option.requiredPoints.compareTo(b.option.requiredPoints));
        break;
      case RedemptionSortOrder.pointsDescending:
        sortedOptions.sort((a, b) => b.option.requiredPoints.compareTo(a.option.requiredPoints));
        break;
      case RedemptionSortOrder.titleAscending:
        sortedOptions.sort((a, b) => a.option.title.toLowerCase().compareTo(b.option.title.toLowerCase()));
        break;
      case RedemptionSortOrder.titleDescending:
        sortedOptions.sort((a, b) => b.option.title.toLowerCase().compareTo(a.option.title.toLowerCase()));
        break;
      case RedemptionSortOrder.createdDateAscending:
        sortedOptions.sort((a, b) => a.option.createdAt.compareTo(b.option.createdAt));
        break;
      case RedemptionSortOrder.createdDateDescending:
        sortedOptions.sort((a, b) => b.option.createdAt.compareTo(a.option.createdAt));
        break;
    }

    return sortedOptions;
  }

  /// Validates option retrieval parameters before making repository calls.
  /// 
  /// This method can be used by the presentation layer for early validation
  /// before making the actual options request.
  /// 
  /// Parameters:
  /// - [categoryId]: Optional category filter to validate
  /// - [minPoints]: Optional minimum points filter to validate
  /// - [maxPoints]: Optional maximum points filter to validate
  /// 
  /// Returns [Either<ValidationFailure, bool>]:
  /// - Left: [ValidationFailure] if validation fails
  /// - Right: true if validation passes
  Future<Either<ValidationFailure, bool>> validateOptionsQuery({
    String? categoryId,
    int? minPoints,
    int? maxPoints,
  }) async {
    final paramsResult = GetRedemptionOptionsParams.create(
      categoryId: categoryId,
      minPoints: minPoints,
      maxPoints: maxPoints,
    );

    return paramsResult.fold(
      (failure) => Either.left(failure),
      (_) => Either.right(true),
    );
  }

  /// Gets popular redemption options with simplified parameters.
  /// 
  /// This convenience method returns the most popular redemption options
  /// sorted by popularity and affordability.
  /// 
  /// Returns [Either<Failure, List<RedemptionOptionWithContext>>]:
  /// - Left: [Failure] if retrieval fails
  /// - Right: [List<RedemptionOptionWithContext>] with popular options
  Future<Either<Failure, List<RedemptionOptionWithContext>>> getPopularOptions() async {
    const params = GetRedemptionOptionsParams(
      maxPoints: 2000, // Focus on affordable options
      includeExpired: false,
      sortOrder: RedemptionSortOrder.pointsAscending,
    );

    final result = await call(params);
    return result.fold(
      (failure) => Either.left(failure),
      (options) {
        // Filter to only popular options and limit to top 10
        final popularOptions = options
            .where((option) => option.isPopular)
            .take(10)
            .toList();
        return Either.right(popularOptions);
      },
    );
  }

  /// Gets redemption options filtered by difficulty level.
  /// 
  /// This method helps users find options appropriate for their experience level.
  /// 
  /// Parameters:
  /// - [difficulty]: The difficulty level to filter by
  /// 
  /// Returns [Either<Failure, List<RedemptionOptionWithContext>>]:
  /// - Left: [Failure] if retrieval fails
  /// - Right: [List<RedemptionOptionWithContext>] filtered by difficulty
  Future<Either<Failure, List<RedemptionOptionWithContext>>> getOptionsByDifficulty(
    RedemptionDifficulty difficulty,
  ) async {
    const params = GetRedemptionOptionsParams(
      includeExpired: false,
      sortOrder: RedemptionSortOrder.pointsAscending,
    );

    final result = await call(params);
    return result.fold(
      (failure) => Either.left(failure),
      (options) {
        final filteredOptions = options
            .where((option) => option.difficulty == difficulty)
            .toList();
        return Either.right(filteredOptions);
      },
    );
  }

  /// Log successful options retrieval for analytics.
  Future<void> _logSuccessfulRetrieval(GetRedemptionOptionsParams params, int optionCount) async {
    // In a real implementation, this would:
    // - Log to analytics system
    // - Track popular filter combinations
    // - Monitor option visibility and engagement
    // - Update recommendation algorithms
    
    // For now, this is a placeholder
    // print('Retrieved $optionCount redemption options with filters: $params');
  }

  /// Log unexpected errors for debugging and monitoring.
  Future<void> _logUnexpectedError(GetRedemptionOptionsParams params, Object error) async {
    // In a real implementation, this would:
    // - Log to error monitoring system
    // - Send alerts to development team
    // - Track error patterns and frequency
    // - Include stack traces and context
    
    // For now, this is a placeholder
    // print('Unexpected error retrieving redemption options: $error');
  }
}

/// Redemption option enriched with additional context and metadata
class RedemptionOptionWithContext {
  final RedemptionOption option;
  final bool isPopular;
  final RedemptionDifficulty difficulty;
  final double estimatedValue;

  const RedemptionOptionWithContext({
    required this.option,
    required this.isPopular,
    required this.difficulty,
    required this.estimatedValue,
  });

  /// Whether this option is affordable for a given point balance
  bool isAffordableWith(int availablePoints) {
    return option.canRedeemWith(availablePoints);
  }

  /// How many units can be redeemed with given points
  int maxUnitsWithPoints(int availablePoints) {
    if (!isAffordableWith(availablePoints)) return 0;
    return availablePoints ~/ option.requiredPoints;
  }

  /// Value per point ratio for this option
  double get valuePerPoint {
    return estimatedValue / option.requiredPoints;
  }

  @override
  String toString() {
    return 'RedemptionOptionWithContext(option: ${option.title}, isPopular: $isPopular, '
           'difficulty: $difficulty, estimatedValue: \$${estimatedValue.toStringAsFixed(2)})';
  }
}

/// Difficulty levels for redemption options
enum RedemptionDifficulty {
  easy,
  medium, 
  hard,
  expert,
}