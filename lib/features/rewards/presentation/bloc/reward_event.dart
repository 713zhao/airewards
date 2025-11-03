import 'package:equatable/equatable.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/reward_repository.dart';

/// Base class for all reward events
sealed class RewardEvent extends Equatable {
  const RewardEvent();

  @override
  List<Object?> get props => [];
}

// Reward Entry Events

/// Event to load reward entries with optional filtering
class RewardEntriesLoaded extends RewardEvent {
  final String userId;
  final int page;
  final int limit;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? categoryId;
  final RewardType? type;
  final String? searchQuery;
  final bool forceRefresh;

  const RewardEntriesLoaded({
    required this.userId,
    this.page = 1,
    this.limit = 20,
    this.startDate,
    this.endDate,
    this.categoryId,
    this.type,
    this.searchQuery,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [
    userId,
    page,
    limit,
    startDate,
    endDate,
    categoryId,
    type,
    searchQuery,
    forceRefresh,
  ];
}

/// Event to load more reward entries (pagination)
class RewardEntriesLoadMore extends RewardEvent {
  final String userId;
  final String? categoryId;
  final RewardType? type;
  final String? searchQuery;

  const RewardEntriesLoadMore({
    required this.userId,
    this.categoryId,
    this.type,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [userId, categoryId, type, searchQuery];
}

/// Event to add a new reward entry
class RewardEntryAdded extends RewardEvent {
  final RewardEntry entry;
  final bool showSuccessMessage;

  const RewardEntryAdded({
    required this.entry,
    this.showSuccessMessage = true,
  });

  @override
  List<Object?> get props => [entry, showSuccessMessage];
}

/// Event to update an existing reward entry
class RewardEntryUpdated extends RewardEvent {
  final RewardEntry entry;
  final bool showSuccessMessage;

  const RewardEntryUpdated({
    required this.entry,
    this.showSuccessMessage = true,
  });

  @override
  List<Object?> get props => [entry, showSuccessMessage];
}

/// Event to delete a reward entry
class RewardEntryDeleted extends RewardEvent {
  final String entryId;
  final String userId;
  final bool showSuccessMessage;

  const RewardEntryDeleted({
    required this.entryId,
    required this.userId,
    this.showSuccessMessage = true,
  });

  @override
  List<Object?> get props => [entryId, userId, showSuccessMessage];
}

/// Event to restore a deleted reward entry (if within time limit)
class RewardEntryRestored extends RewardEvent {
  final String entryId;
  final String userId;

  const RewardEntryRestored({
    required this.entryId,
    required this.userId,
  });

  @override
  List<Object?> get props => [entryId, userId];
}

// Points and Statistics Events

/// Event to load total points for a user
class RewardPointsLoaded extends RewardEvent {
  final String userId;
  final bool forceRefresh;

  const RewardPointsLoaded({
    required this.userId,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [userId, forceRefresh];
}

/// Event to start watching real-time points updates
class RewardPointsWatchStarted extends RewardEvent {
  final String userId;

  const RewardPointsWatchStarted({
    required this.userId,
  });

  @override
  List<Object?> get props => [userId];
}

/// Event to stop watching real-time points updates
class RewardPointsWatchStopped extends RewardEvent {
  const RewardPointsWatchStopped();
}

/// Event when points are updated from external source (real-time update)
class RewardPointsUpdated extends RewardEvent {
  final int newTotal;
  final DateTime timestamp;

  const RewardPointsUpdated({
    required this.newTotal,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [newTotal, timestamp];
}

// Category Events

/// Event to load reward categories
class RewardCategoriesLoaded extends RewardEvent {
  final bool forceRefresh;

  const RewardCategoriesLoaded({
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [forceRefresh];
}

/// Event to add a new reward category
class RewardCategoryAdded extends RewardEvent {
  final RewardCategory category;

  const RewardCategoryAdded({
    required this.category,
  });

  @override
  List<Object?> get props => [category];
}

/// Event to update an existing reward category
class RewardCategoryUpdated extends RewardEvent {
  final RewardCategory category;

  const RewardCategoryUpdated({
    required this.category,
  });

  @override
  List<Object?> get props => [category];
}

/// Event to delete a reward category
class RewardCategoryDeleted extends RewardEvent {
  final String categoryId;
  final String reassignToCategoryId;

  const RewardCategoryDeleted({
    required this.categoryId,
    required this.reassignToCategoryId,
  });

  @override
  List<Object?> get props => [categoryId, reassignToCategoryId];
}

// Search and Filter Events

/// Event to search reward entries
class RewardEntriesSearched extends RewardEvent {
  final String userId;
  final String query;
  final String? categoryId;
  final RewardType? type;

  const RewardEntriesSearched({
    required this.userId,
    required this.query,
    this.categoryId,
    this.type,
  });

  @override
  List<Object?> get props => [userId, query, categoryId, type];
}

/// Event to clear search and reset filters
class RewardSearchCleared extends RewardEvent {
  final String userId;

  const RewardSearchCleared({
    required this.userId,
  });

  @override
  List<Object?> get props => [userId];
}

/// Event to apply date range filter
class RewardDateFilterApplied extends RewardEvent {
  final String userId;
  final DateTime startDate;
  final DateTime endDate;

  const RewardDateFilterApplied({
    required this.userId,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [userId, startDate, endDate];
}

/// Event to apply category filter
class RewardCategoryFilterApplied extends RewardEvent {
  final String userId;
  final String? categoryId; // null means all categories

  const RewardCategoryFilterApplied({
    required this.userId,
    this.categoryId,
  });

  @override
  List<Object?> get props => [userId, categoryId];
}

/// Event to apply type filter
class RewardTypeFilterApplied extends RewardEvent {
  final String userId;
  final RewardType? type; // null means all types

  const RewardTypeFilterApplied({
    required this.userId,
    this.type,
  });

  @override
  List<Object?> get props => [userId, type];
}

// Bulk Operations Events

/// Event to perform batch operations on multiple entries
class RewardBatchOperationRequested extends RewardEvent {
  final List<RewardBatchOperation> operations;

  const RewardBatchOperationRequested({
    required this.operations,
  });

  @override
  List<Object?> get props => [operations];
}

/// Event to select/deselect entries for batch operations
class RewardEntriesSelectionChanged extends RewardEvent {
  final List<String> selectedEntryIds;

  const RewardEntriesSelectionChanged({
    required this.selectedEntryIds,
  });

  @override
  List<Object?> get props => [selectedEntryIds];
}

/// Event to select all visible entries
class RewardEntriesSelectAll extends RewardEvent {
  const RewardEntriesSelectAll();
}

/// Event to deselect all entries
class RewardEntriesDeselectAll extends RewardEvent {
  const RewardEntriesDeselectAll();
}

// Sync and Cache Events

/// Event to sync rewards with server
class RewardSyncRequested extends RewardEvent {
  final bool showProgress;

  const RewardSyncRequested({
    this.showProgress = true,
  });

  @override
  List<Object?> get props => [showProgress];
}

/// Event to clear local cache and reload
class RewardCacheCleared extends RewardEvent {
  final String userId;

  const RewardCacheCleared({
    required this.userId,
  });

  @override
  List<Object?> get props => [userId];
}

// UI State Events

/// Event to refresh the entire rewards view
class RewardViewRefreshed extends RewardEvent {
  final String userId;

  const RewardViewRefreshed({
    required this.userId,
  });

  @override
  List<Object?> get props => [userId];
}

/// Event to reset the BLoC state
class RewardStateReset extends RewardEvent {
  const RewardStateReset();
}

/// Event to retry failed operations
class RewardOperationRetried extends RewardEvent {
  const RewardOperationRetried();
}

/// Event to clear error states
class RewardErrorCleared extends RewardEvent {
  const RewardErrorCleared();
}

/// Event to show/hide loading states
class RewardLoadingStateChanged extends RewardEvent {
  final bool isLoading;
  final String? message;

  const RewardLoadingStateChanged({
    required this.isLoading,
    this.message,
  });

  @override
  List<Object?> get props => [isLoading, message];
}

// Export and Import Events

/// Event to export reward data
class RewardDataExportRequested extends RewardEvent {
  final String userId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? categoryId;
  final ExportFormat format;

  const RewardDataExportRequested({
    required this.userId,
    this.startDate,
    this.endDate,
    this.categoryId,
    required this.format,
  });

  @override
  List<Object?> get props => [userId, startDate, endDate, categoryId, format];
}

/// Event to import reward data
class RewardDataImportRequested extends RewardEvent {
  final String userId;
  final String filePath;
  final ImportFormat format;

  const RewardDataImportRequested({
    required this.userId,
    required this.filePath,
    required this.format,
  });

  @override
  List<Object?> get props => [userId, filePath, format];
}

// Analytics and Statistics Events

/// Event to load reward statistics
class RewardStatisticsLoaded extends RewardEvent {
  final String userId;
  final DateTime? startDate;
  final DateTime? endDate;

  const RewardStatisticsLoaded({
    required this.userId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [userId, startDate, endDate];
}

/// Event to load reward trends
class RewardTrendsLoaded extends RewardEvent {
  final String userId;
  final TrendPeriod period;

  const RewardTrendsLoaded({
    required this.userId,
    required this.period,
  });

  @override
  List<Object?> get props => [userId, period];
}

// Enums for events

enum ExportFormat {
  csv,
  json,
  pdf,
}

enum ImportFormat {
  csv,
  json,
}

enum TrendPeriod {
  week,
  month,
  quarter,
  year,
}