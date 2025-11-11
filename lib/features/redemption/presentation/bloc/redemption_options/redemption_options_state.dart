import 'package:equatable/equatable.dart';
import '../../../domain/usecases/get_redemption_options.dart';

// Sentinel object for copyWith to distinguish between null and unset
const _unset = Object();

/// Base state class for redemption options management
/// 
/// This abstract class defines the possible states for managing
/// redemption options in the UI, including loading, loaded,
/// empty, and error states with filtering capabilities.
abstract class RedemptionOptionsState extends Equatable {
  const RedemptionOptionsState();
}

/// Initial state when no data has been loaded yet
class RedemptionOptionsInitial extends RedemptionOptionsState {
  const RedemptionOptionsInitial();

  @override
  List<Object> get props => [];
}

/// State when redemption options are being loaded
class RedemptionOptionsLoading extends RedemptionOptionsState {
  @override
  List<Object> get props => [];

  const RedemptionOptionsLoading();
}

/// State when redemption options are successfully loaded
class RedemptionOptionsLoaded extends RedemptionOptionsState {
  final List<RedemptionOptionWithContext> options;
  final String? selectedCategory;
  final int? minPoints;
  final int? maxPoints;
  final String? searchQuery;
  final bool isRefreshing;

  const RedemptionOptionsLoaded({
    required this.options,
    this.selectedCategory,
    this.minPoints,
    this.maxPoints,
    this.searchQuery,
    this.isRefreshing = false,
  });

  @override
  List<Object?> get props => [
    options,
    selectedCategory,
    minPoints,
    maxPoints,
    searchQuery,
    isRefreshing,
  ];

  /// Creates a copy with updated fields
  RedemptionOptionsLoaded copyWith({
    List<RedemptionOptionWithContext>? options,
    String? selectedCategory,
    int? minPoints,
    int? maxPoints,
    String? searchQuery,
    bool? isRefreshing,
    // Use Object? to allow explicit null values
    Object? selectedCategoryReset = _unset,
    Object? minPointsReset = _unset,
    Object? maxPointsReset = _unset,
    Object? searchQueryReset = _unset,
  }) {
    return RedemptionOptionsLoaded(
      options: options ?? this.options,
      selectedCategory: selectedCategoryReset != _unset 
          ? selectedCategoryReset as String?
          : selectedCategory ?? this.selectedCategory,
      minPoints: minPointsReset != _unset
          ? minPointsReset as int?
          : minPoints ?? this.minPoints,
      maxPoints: maxPointsReset != _unset
          ? maxPointsReset as int?
          : maxPoints ?? this.maxPoints,
      searchQuery: searchQueryReset != _unset
          ? searchQueryReset as String?
          : searchQuery ?? this.searchQuery,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  /// Gets options filtered by current search and filter criteria
  /// 
  /// This getter applies client-side filtering to the loaded options
  /// based on the current filter state. Server-side filtering should
  /// be preferred when possible for better performance.
  List<RedemptionOptionWithContext> get filteredOptions {
    var filtered = options.where((optionWithContext) {
      final option = optionWithContext.option;
      
      // Apply category filter
      if (selectedCategory != null && option.categoryId != selectedCategory) {
        return false;
      }

      // Apply points range filter
      if (minPoints != null && option.requiredPoints < minPoints!) {
        return false;
      }

      if (maxPoints != null && option.requiredPoints > maxPoints!) {
        return false;
      }

      // Apply search query filter
      if (searchQuery != null && searchQuery!.isNotEmpty) {
        final query = searchQuery!.toLowerCase();
        final titleMatch = option.title.toLowerCase().contains(query);
        final descriptionMatch = option.description.toLowerCase().contains(query);
        
        if (!titleMatch && !descriptionMatch) {
          return false;
        }
      }

      return true;
    }).toList();

    return filtered;
  }

  /// Gets unique categories from available options
  /// 
  /// This helps populate category filter dropdowns and
  /// provides insight into available option categories.
  List<String> get availableCategories {
    final categories = options
        .map((optionWithContext) => optionWithContext.option.categoryId)
        .where((categoryId) => categoryId.isNotEmpty)
        .toSet()
        .toList();
    
    categories.sort(); // Sort alphabetically
    return categories;
  }

  /// Gets the points range across all options
  /// 
  /// This helps set up range sliders and provides
  /// context for filtering by points.
  PointsRange get pointsRange {
    if (options.isEmpty) {
      return const PointsRange(min: 0, max: 0);
    }

    final points = options.map((optionWithContext) => optionWithContext.option.requiredPoints).toList();
    return PointsRange(
      min: points.reduce((a, b) => a < b ? a : b),
      max: points.reduce((a, b) => a > b ? a : b),
    );
  }

  /// Whether any filters are currently active
  bool get hasActiveFilters {
    return selectedCategory != null ||
        minPoints != null ||
        maxPoints != null ||
        (searchQuery != null && searchQuery!.isNotEmpty);
  }

  /// Number of options before filtering
  int get totalOptionsCount => options.length;

  /// Number of options after filtering
  int get filteredOptionsCount => filteredOptions.length;

  /// Whether the current filter results are empty
  bool get isFiltered => hasActiveFilters && filteredOptions.isEmpty;
}

/// State when no redemption options are available
/// 
/// This can occur when there are genuinely no options available,
/// or when all options are filtered out by the current criteria.
class RedemptionOptionsEmpty extends RedemptionOptionsState {
  final String message;
  final bool hasFilters;

  const RedemptionOptionsEmpty({
    required this.message,
    this.hasFilters = false,
  });

  @override
  List<Object> get props => [message, hasFilters];
}

/// State when an error occurs loading redemption options
class RedemptionOptionsError extends RedemptionOptionsState {
  final String message;
  final bool canRetry;

  const RedemptionOptionsError({
    required this.message,
    this.canRetry = true,
  });

  @override
  List<Object> get props => [message, canRetry];
}

/// Helper class to represent a points range
/// 
/// This class encapsulates minimum and maximum point values
/// for use in filtering and UI components like range sliders.
class PointsRange extends Equatable {
  final int min;
  final int max;

  const PointsRange({
    required this.min,
    required this.max,
  });

  /// The range span (max - min)
  int get span => max - min;

  /// Whether this range represents a single value
  bool get isSingleValue => min == max;

  /// Whether this range is valid (min <= max)
  bool get isValid => min <= max;

  /// Creates a range that encompasses both this and another range
  PointsRange union(PointsRange other) {
    return PointsRange(
      min: min < other.min ? min : other.min,
      max: max > other.max ? max : other.max,
    );
  }

  /// Creates a range that represents the intersection of this and another range
  PointsRange? intersection(PointsRange other) {
    final intersectionMin = min > other.min ? min : other.min;
    final intersectionMax = max < other.max ? max : other.max;

    if (intersectionMin <= intersectionMax) {
      return PointsRange(min: intersectionMin, max: intersectionMax);
    }

    return null; // No intersection
  }

  /// Whether this range contains a specific value
  bool contains(int value) {
    return value >= min && value <= max;
  }

  /// Whether this range overlaps with another range
  bool overlapsWith(PointsRange other) {
    return intersection(other) != null;
  }

  @override
  List<Object> get props => [min, max];

  @override
  String toString() => 'PointsRange(min: $min, max: $max)';
}