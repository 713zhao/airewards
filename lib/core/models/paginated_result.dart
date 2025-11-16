import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Generic paginated result container for repository operations
/// Used to handle pagination consistently across all list-based operations
@immutable
class PaginatedResult<T> extends Equatable {
  /// List of items for the current page
  final List<T> items;
  
  /// Total number of items available across all pages
  final int totalCount;
  
  /// Current page number (1-based)
  final int currentPage;
  
  /// Whether there are more pages available
  final bool hasNextPage;
  
  /// Whether there is a previous page available
  final bool hasPreviousPage;
  
  /// Total number of pages available
  final int totalPages;

  const PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.hasNextPage,
  }) : hasPreviousPage = currentPage > 1,
       totalPages = totalCount == 0 ? 1 : ((totalCount - 1) ~/ items.length) + 1;

  /// Creates an empty paginated result
  const PaginatedResult.empty()
      : items = const [],
        totalCount = 0,
        currentPage = 1,
        hasNextPage = false,
        hasPreviousPage = false,
        totalPages = 1;

  /// Creates a paginated result from a simple list (for single-page results)
  const PaginatedResult.fromList(List<T> items)
      : items = items,
        totalCount = items.length,
        currentPage = 1,
        hasNextPage = false,
        hasPreviousPage = false,
        totalPages = 1;

  /// Whether the result is empty
  bool get isEmpty => items.isEmpty;

  /// Whether the result has items
  bool get isNotEmpty => items.isNotEmpty;

  /// Number of items in current page
  int get itemCount => items.length;

  @override
  List<Object?> get props => [
        items,
        totalCount,
        currentPage,
        hasNextPage,
        hasPreviousPage,
        totalPages,
      ];

  @override
  String toString() {
    return 'PaginatedResult(itemCount: $itemCount, totalCount: $totalCount, '
           'currentPage: $currentPage, totalPages: $totalPages, '
           'hasNextPage: $hasNextPage, hasPreviousPage: $hasPreviousPage)';
  }
}