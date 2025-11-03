import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/usecases.dart';
import 'redemption_options_state.dart';

/// Cubit for managing redemption options state and operations
/// 
/// This cubit handles:
/// - Loading and displaying redemption options
/// - Filtering by category, points range, and search
/// - Refreshing options data
/// - Handling loading and error states
class RedemptionOptionsCubit extends Cubit<RedemptionOptionsState> {
  final GetRedemptionOptions getRedemptionOptionsUseCase;

  RedemptionOptionsCubit({
    required this.getRedemptionOptionsUseCase,
  }) : super(const RedemptionOptionsInitial());

  /// Loads redemption options from the repository
  /// 
  /// This method fetches all available redemption options and applies
  /// any existing filters. It handles loading states and errors gracefully.
  /// 
  /// Parameters:
  /// - [forceRefresh]: Whether to force a refresh from remote data source
  Future<void> loadRedemptionOptions({bool forceRefresh = false}) async {
    if (state is RedemptionOptionsLoaded && !forceRefresh) {
      // If already loaded and not forcing refresh, just return
      return;
    }

    if (state is! RedemptionOptionsLoaded) {
      emit(const RedemptionOptionsLoading());
    } else {
      // Show refresh indicator on existing loaded state
      final currentState = state as RedemptionOptionsLoaded;
      emit(currentState.copyWith(isRefreshing: true));
    }

    try {
      // Create request parameters with current filters
      final currentFilters = _getCurrentFilters();
      
      final params = GetRedemptionOptionsParams.create(
        categoryId: currentFilters.category,
        minPoints: currentFilters.minPoints,
        maxPoints: currentFilters.maxPoints,
        includeExpired: false,
        sortOrder: RedemptionSortOrder.pointsAscending,
      );

      if (params.isLeft) {
        emit(RedemptionOptionsError(
          message: params.left.message,
          canRetry: true,
        ));
        return;
      }

      final result = await getRedemptionOptionsUseCase(params.right);

      result.fold(
        (failure) {
          emit(RedemptionOptionsError(
            message: failure.message,
            canRetry: true,
          ));
        },
        (options) {
          if (options.isEmpty) {
            emit(RedemptionOptionsEmpty(
              message: _getEmptyMessage(currentFilters),
              hasFilters: currentFilters.hasActiveFilters,
            ));
          } else {
            emit(RedemptionOptionsLoaded(
              options: options,
              selectedCategory: currentFilters.category,
              minPoints: currentFilters.minPoints,
              maxPoints: currentFilters.maxPoints,
              searchQuery: currentFilters.searchQuery,
              isRefreshing: false,
            ));
          }
        },
      );
    } catch (e) {
      emit(RedemptionOptionsError(
        message: 'Unexpected error: ${e.toString()}',
        canRetry: true,
      ));
    }
  }

  /// Refreshes redemption options data
  /// 
  /// Forces a refresh from the remote data source to get the latest
  /// availability and pricing information.
  Future<void> refreshRedemptionOptions() async {
    await loadRedemptionOptions(forceRefresh: true);
  }

  /// Filters redemption options by category
  /// 
  /// Parameters:
  /// - [category]: Category ID to filter by, or null to show all categories
  void filterByCategory(String? category) {
    final current = state;
    if (current is RedemptionOptionsLoaded) {
      emit(current.copyWith(selectedCategory: category));
    } else {
      // Load with the new category filter
      _loadWithFilters(category: category);
    }
  }

  /// Filters redemption options by points range
  /// 
  /// Parameters:
  /// - [minPoints]: Minimum points required, or null for no minimum
  /// - [maxPoints]: Maximum points required, or null for no maximum
  void filterByPointsRange({int? minPoints, int? maxPoints}) {
    final current = state;
    if (current is RedemptionOptionsLoaded) {
      emit(current.copyWith(
        minPoints: minPoints,
        maxPoints: maxPoints,
      ));
    } else {
      // Load with the new points filter
      _loadWithFilters(minPoints: minPoints, maxPoints: maxPoints);
    }
  }

  /// Searches redemption options by query
  /// 
  /// Parameters:
  /// - [query]: Search query to filter by title and description
  void searchRedemptionOptions(String? query) {
    final current = state;
    if (current is RedemptionOptionsLoaded) {
      emit(current.copyWith(searchQuery: query));
    } else {
      // Load with the search query
      _loadWithFilters(searchQuery: query);
    }
  }

  /// Clears all applied filters
  /// 
  /// Resets the state to show all available redemption options
  /// without any category, points, or search filters.
  void clearFilters() {
    final current = state;
    if (current is RedemptionOptionsLoaded) {
      emit(current.copyWith(
        selectedCategoryReset: null,
        minPointsReset: null,
        maxPointsReset: null,
        searchQueryReset: null,
      ));
    } else {
      // Load without any filters
      loadRedemptionOptions();
    }
  }

  /// Applies multiple filters at once
  /// 
  /// This is more efficient than calling individual filter methods
  /// when you want to apply multiple filters simultaneously.
  /// 
  /// Parameters:
  /// - [category]: Category ID to filter by
  /// - [minPoints]: Minimum points required
  /// - [maxPoints]: Maximum points required
  /// - [searchQuery]: Search query for title/description
  void applyFilters({
    String? category,
    int? minPoints,
    int? maxPoints,
    String? searchQuery,
  }) {
    final current = state;
    if (current is RedemptionOptionsLoaded) {
      emit(current.copyWith(
        selectedCategory: category,
        minPoints: minPoints,
        maxPoints: maxPoints,
        searchQuery: searchQuery,
      ));
    } else {
      _loadWithFilters(
        category: category,
        minPoints: minPoints,
        maxPoints: maxPoints,
        searchQuery: searchQuery,
      );
    }
  }

  /// Retries loading redemption options after an error
  /// 
  /// This method is called when the user taps a retry button
  /// in the error state UI.
  Future<void> retry() async {
    await loadRedemptionOptions(forceRefresh: true);
  }

  /// Gets current filter values from state
  _FilterState _getCurrentFilters() {
    final current = state;
    if (current is RedemptionOptionsLoaded) {
      return _FilterState(
        category: current.selectedCategory,
        minPoints: current.minPoints,
        maxPoints: current.maxPoints,
        searchQuery: current.searchQuery,
      );
    }
    return const _FilterState();
  }

  /// Loads options with specific filters
  void _loadWithFilters({
    String? category,
    int? minPoints,
    int? maxPoints,
    String? searchQuery,
  }) {
    // This would trigger a new load with the specified filters
    // For now, we'll just load all options and apply filters client-side
    loadRedemptionOptions();
  }

  /// Gets appropriate empty message based on filters
  String _getEmptyMessage(_FilterState filters) {
    if (filters.hasActiveFilters) {
      return 'No redemption options match your current filters. Try adjusting your search criteria.';
    }
    return 'No redemption options are currently available. Please check back later.';
  }

  /// Gets available redemption option if state is loaded
  List<RedemptionOptionWithContext> get availableOptions {
    final current = state;
    if (current is RedemptionOptionsLoaded) {
      return current.filteredOptions;
    }
    return [];
  }

  /// Gets available categories if state is loaded
  List<String> get availableCategories {
    final current = state;
    if (current is RedemptionOptionsLoaded) {
      return current.availableCategories;
    }
    return [];
  }

  /// Gets points range if state is loaded
  PointsRange get pointsRange {
    final current = state;
    if (current is RedemptionOptionsLoaded) {
      return current.pointsRange;
    }
    return const PointsRange(min: 0, max: 0);
  }

  /// Checks if any filters are currently active
  bool get hasActiveFilters {
    final current = state;
    if (current is RedemptionOptionsLoaded) {
      return current.hasActiveFilters;
    }
    return false;
  }

  /// Gets the number of filtered options
  int get filteredCount {
    return availableOptions.length;
  }

  /// Gets the total number of options (before filtering)
  int get totalCount {
    final current = state;
    if (current is RedemptionOptionsLoaded) {
      return current.options.length;
    }
    return 0;
  }
}

/// Helper class to track filter state
class _FilterState {
  final String? category;
  final int? minPoints;
  final int? maxPoints;
  final String? searchQuery;

  const _FilterState({
    this.category,
    this.minPoints,
    this.maxPoints,
    this.searchQuery,
  });

  bool get hasActiveFilters {
    return category != null ||
        minPoints != null ||
        maxPoints != null ||
        (searchQuery != null && searchQuery!.isNotEmpty);
  }
}