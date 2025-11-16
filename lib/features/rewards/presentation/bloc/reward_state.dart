import 'package:equatable/equatable.dart';

import '../../../../core/models/paginated_result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/reward_repository.dart';

/// Base class for all reward states
sealed class RewardState extends Equatable {
  const RewardState();

  @override
  List<Object?> get props => [];

  /// Helper to check if rewards are loading
  bool get isLoading => this is RewardLoading;

  /// Helper to check if there's an error
  bool get hasError => this is RewardError;

  /// Helper to get current reward entries if available
  List<RewardEntry> get entryList => this is RewardLoaded
      ? (this as RewardLoaded).entries.items
      : [];

  /// Helper to get current total points if available
  int get totalPoints => this is RewardLoaded
      ? (this as RewardLoaded).totalPoints
      : 0;

  /// Helper to get current categories if available
  List<RewardCategory> get categories => this is RewardLoaded
      ? (this as RewardLoaded).categories
      : [];
}

/// Initial reward state before any operations
class RewardInitial extends RewardState {
  const RewardInitial();
}

/// State when reward operations are in progress
class RewardLoading extends RewardState {
  final String? message;
  final RewardOperationType operationType;
  final bool showProgress;

  const RewardLoading({
    this.message,
    this.operationType = RewardOperationType.loadEntries,
    this.showProgress = true,
  });

  @override
  List<Object?> get props => [message, operationType, showProgress];
}

/// State when rewards data is successfully loaded
class RewardLoaded extends RewardState {
  final PaginatedResult<RewardEntry> entries;
  @override
  final int totalPoints;
  @override
  final List<RewardCategory> categories;
  final DateTime lastUpdated;
  final bool hasNextPage;
  final String? currentSearchQuery;
  final String? currentCategoryFilter;
  final RewardType? currentTypeFilter;
  final DateTime? currentStartDate;
  final DateTime? currentEndDate;
  final List<String> selectedEntryIds;
  final bool isRealTimeEnabled;

  const RewardLoaded({
    required this.entries,
    required this.totalPoints,
    required this.categories,
    required this.lastUpdated,
    this.hasNextPage = false,
    this.currentSearchQuery,
    this.currentCategoryFilter,
    this.currentTypeFilter,
    this.currentStartDate,
    this.currentEndDate,
    this.selectedEntryIds = const [],
    this.isRealTimeEnabled = false,
  });

  @override
  List<Object?> get props => [
    entries,
    totalPoints,
    categories,
    lastUpdated,
    hasNextPage,
    currentSearchQuery,
    currentCategoryFilter,
    currentTypeFilter,
    currentStartDate,
    currentEndDate,
    selectedEntryIds,
    isRealTimeEnabled,
  ];

  /// Create a copy with updated properties
  RewardLoaded copyWith({
    PaginatedResult<RewardEntry>? entries,
    int? totalPoints,
    List<RewardCategory>? categories,
    DateTime? lastUpdated,
    bool? hasNextPage,
    String? currentSearchQuery,
    String? currentCategoryFilter,
    RewardType? currentTypeFilter,
    DateTime? currentStartDate,
    DateTime? currentEndDate,
    List<String>? selectedEntryIds,
    bool? isRealTimeEnabled,
  }) {
    return RewardLoaded(
      entries: entries ?? this.entries,
      totalPoints: totalPoints ?? this.totalPoints,
      categories: categories ?? this.categories,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      currentSearchQuery: currentSearchQuery ?? this.currentSearchQuery,
      currentCategoryFilter: currentCategoryFilter ?? this.currentCategoryFilter,
      currentTypeFilter: currentTypeFilter ?? this.currentTypeFilter,
      currentStartDate: currentStartDate ?? this.currentStartDate,
      currentEndDate: currentEndDate ?? this.currentEndDate,
      selectedEntryIds: selectedEntryIds ?? this.selectedEntryIds,
      isRealTimeEnabled: isRealTimeEnabled ?? this.isRealTimeEnabled,
    );
  }

  /// Add new entries to the existing list (for pagination)
  RewardLoaded withAddedEntries(List<RewardEntry> newEntries, bool hasMore) {
    final allEntries = List<RewardEntry>.from(entries.items)..addAll(newEntries);
    final newPaginatedResult = PaginatedResult<RewardEntry>(
      items: allEntries,
      currentPage: entries.currentPage + 1,
      totalCount: entries.totalCount + newEntries.length,
      hasNextPage: hasMore,
    );

    return copyWith(
      entries: newPaginatedResult,
      hasNextPage: hasMore,
      lastUpdated: DateTime.now(),
    );
  }

  /// Update an existing entry in the list
  RewardLoaded withUpdatedEntry(RewardEntry updatedEntry) {
    final updatedEntries = entries.items.map((entry) {
      return entry.id == updatedEntry.id ? updatedEntry : entry;
    }).toList();

    final newPaginatedResult = PaginatedResult<RewardEntry>(
      items: updatedEntries,
      currentPage: entries.currentPage,
      totalCount: entries.totalCount,
      hasNextPage: entries.hasNextPage,
    );

    return copyWith(
      entries: newPaginatedResult,
      lastUpdated: DateTime.now(),
    );
  }

  /// Remove an entry from the list
  RewardLoaded withRemovedEntry(String entryId) {
    final filteredEntries = entries.items.where((entry) => entry.id != entryId).toList();
    
    final newPaginatedResult = PaginatedResult<RewardEntry>(
      items: filteredEntries,
      currentPage: entries.currentPage,
      totalCount: entries.totalCount - 1,
      hasNextPage: entries.hasNextPage,
    );

    return copyWith(
      entries: newPaginatedResult,
      lastUpdated: DateTime.now(),
    );
  }

  /// Add a new entry to the beginning of the list
  RewardLoaded withAddedEntry(RewardEntry newEntry) {
    final allEntries = <RewardEntry>[newEntry, ...entries.items];
    
    final newPaginatedResult = PaginatedResult<RewardEntry>(
      items: allEntries,
      currentPage: entries.currentPage,
      totalCount: entries.totalCount + 1,
      hasNextPage: entries.hasNextPage,
    );

    return copyWith(
      entries: newPaginatedResult,
      lastUpdated: DateTime.now(),
    );
  }

  /// Update total points (from real-time updates)
  RewardLoaded withUpdatedPoints(int newTotalPoints) {
    return copyWith(
      totalPoints: newTotalPoints,
      lastUpdated: DateTime.now(),
    );
  }

  /// Update categories
  RewardLoaded withUpdatedCategories(List<RewardCategory> newCategories) {
    return copyWith(
      categories: newCategories,
      lastUpdated: DateTime.now(),
    );
  }

  /// Update selection
  RewardLoaded withUpdatedSelection(List<String> newSelection) {
    return copyWith(
      selectedEntryIds: newSelection,
    );
  }

  /// Apply filters
  RewardLoaded withFilters({
    String? searchQuery,
    String? categoryId,
    RewardType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return copyWith(
      currentSearchQuery: searchQuery,
      currentCategoryFilter: categoryId,
      currentTypeFilter: type,
      currentStartDate: startDate,
      currentEndDate: endDate,
    );
  }

  /// Clear all filters
  RewardLoaded withClearedFilters() {
    return copyWith(
      currentSearchQuery: null,
      currentCategoryFilter: null,
      currentTypeFilter: null,
      currentStartDate: null,
      currentEndDate: null,
    );
  }
}

/// State when a reward error occurs
class RewardError extends RewardState {
  final String message;
  final RewardErrorType errorType;
  final bool canRetry;
  final RewardOperationType? failedOperation;
  final dynamic originalException;

  const RewardError({
    required this.message,
    this.errorType = RewardErrorType.generic,
    this.canRetry = true,
    this.failedOperation,
    this.originalException,
  });

  @override
  List<Object?> get props => [
    message,
    errorType,
    canRetry,
    failedOperation,
    originalException,
  ];
}

/// State for successful operations that don't change the main data
class RewardOperationSuccess extends RewardState {
  final String message;
  final RewardOperationType operationType;
  final Map<String, dynamic>? data;

  const RewardOperationSuccess({
    required this.message,
    required this.operationType,
    this.data,
  });

  @override
  List<Object?> get props => [message, operationType, data];
}

/// State when performing batch operations
class RewardBatchOperationInProgress extends RewardState {
  final List<RewardBatchOperation> operations;
  final int completed;
  final int total;
  final String? currentOperationMessage;

  const RewardBatchOperationInProgress({
    required this.operations,
    required this.completed,
    required this.total,
    this.currentOperationMessage,
  });

  @override
  List<Object?> get props => [operations, completed, total, currentOperationMessage];

  double get progress => total > 0 ? completed / total : 0.0;
  bool get isComplete => completed >= total;
}

/// State when sync operations are in progress
class RewardSyncInProgress extends RewardState {
  final SyncStatus status;
  final int? uploadProgress;
  final int? downloadProgress;
  final String? statusMessage;

  const RewardSyncInProgress({
    required this.status,
    this.uploadProgress,
    this.downloadProgress,
    this.statusMessage,
  });

  @override
  List<Object?> get props => [status, uploadProgress, downloadProgress, statusMessage];
}

/// State when sync is completed
class RewardSyncCompleted extends RewardState {
  final SyncResult result;
  final DateTime completedAt;

  const RewardSyncCompleted({
    required this.result,
    required this.completedAt,
  });

  @override
  List<Object?> get props => [result, completedAt];
}

/// State for export operations
class RewardExportInProgress extends RewardState {
  final ExportFormat format;
  final int progress;
  final String? statusMessage;

  const RewardExportInProgress({
    required this.format,
    required this.progress,
    this.statusMessage,
  });

  @override
  List<Object?> get props => [format, progress, statusMessage];
}

/// State when export is completed
class RewardExportCompleted extends RewardState {
  final String filePath;
  final ExportFormat format;
  final int exportedCount;

  const RewardExportCompleted({
    required this.filePath,
    required this.format,
    required this.exportedCount,
  });

  @override
  List<Object?> get props => [filePath, format, exportedCount];
}

/// State for import operations
class RewardImportInProgress extends RewardState {
  final ImportFormat format;
  final int progress;
  final String? statusMessage;

  const RewardImportInProgress({
    required this.format,
    required this.progress,
    this.statusMessage,
  });

  @override
  List<Object?> get props => [format, progress, statusMessage];
}

/// State when import is completed
class RewardImportCompleted extends RewardState {
  final ImportFormat format;
  final int importedCount;
  final List<String> errors;

  const RewardImportCompleted({
    required this.format,
    required this.importedCount,
    this.errors = const [],
  });

  @override
  List<Object?> get props => [format, importedCount, errors];

  bool get hasErrors => errors.isNotEmpty;
}

/// State for displaying statistics
class RewardStatisticsLoaded extends RewardState {
  final RewardStatistics statistics;
  final DateTime calculatedAt;

  const RewardStatisticsLoaded({
    required this.statistics,
    required this.calculatedAt,
  });

  @override
  List<Object?> get props => [statistics, calculatedAt];
}

// Enums for reward states

/// Enum for different types of reward operations
enum RewardOperationType {
  loadEntries,
  loadMoreEntries,
  addEntry,
  updateEntry,
  deleteEntry,
  restoreEntry,
  loadPoints,
  loadCategories,
  addCategory,
  updateCategory,
  deleteCategory,
  search,
  filter,
  batchOperation,
  sync,
  export,
  import,
  loadStatistics,
  clearCache,
}

/// Enum for different types of reward errors
enum RewardErrorType {
  generic,
  network,
  database,
  validation,
  permission,
  notFound,
  conflict,
  quotaExceeded,
  offline,
  sync,
  export,
  import,
}

/// Enum for sync status
enum SyncStatus {
  uploading,
  downloading,
  processing,
  resolving,
}

/// Enum for export formats (from event file)
enum ExportFormat {
  csv,
  json,
  pdf,
}

/// Enum for import formats (from event file)
enum ImportFormat {
  csv,
  json,
}

/// Data class for reward statistics
class RewardStatistics {
  final int totalEntries;
  final int totalPoints;
  final int totalCategories;
  final Map<String, int> pointsByCategory;
  final Map<RewardType, int> entriesByType;
  final Map<String, int> entriesByMonth;
  final double averagePointsPerEntry;
  final RewardEntry? highestPointEntry;
  final RewardEntry? mostRecentEntry;
  final DateTime? firstEntryDate;

  const RewardStatistics({
    required this.totalEntries,
    required this.totalPoints,
    required this.totalCategories,
    required this.pointsByCategory,
    required this.entriesByType,
    required this.entriesByMonth,
    required this.averagePointsPerEntry,
    this.highestPointEntry,
    this.mostRecentEntry,
    this.firstEntryDate,
  });
}

/// Extension methods for RewardErrorType
extension RewardErrorTypeExtension on RewardErrorType {
  /// Get user-friendly error message
  String get userMessage {
    switch (this) {
      case RewardErrorType.network:
        return 'Network connection error. Please check your internet connection.';
      case RewardErrorType.database:
        return 'Database error occurred. Please try again.';
      case RewardErrorType.validation:
        return 'Invalid data provided. Please check your input.';
      case RewardErrorType.permission:
        return 'Permission denied. Please check your account permissions.';
      case RewardErrorType.notFound:
        return 'Reward entry not found.';
      case RewardErrorType.conflict:
        return 'Data conflict detected. Please refresh and try again.';
      case RewardErrorType.quotaExceeded:
        return 'Storage quota exceeded. Please free up space.';
      case RewardErrorType.offline:
        return 'You are offline. Some features may not be available.';
      case RewardErrorType.sync:
        return 'Synchronization failed. Will retry automatically.';
      case RewardErrorType.export:
        return 'Export operation failed. Please try again.';
      case RewardErrorType.import:
        return 'Import operation failed. Please check your file.';
      case RewardErrorType.generic:
        return 'An error occurred. Please try again.';
    }
  }

  /// Check if error is recoverable
  bool get isRecoverable {
    switch (this) {
      case RewardErrorType.network:
      case RewardErrorType.offline:
      case RewardErrorType.sync:
      case RewardErrorType.generic:
        return true;
      case RewardErrorType.permission:
      case RewardErrorType.quotaExceeded:
        return false;
      default:
        return true;
    }
  }
}

/// Extension methods for RewardOperationType
extension RewardOperationTypeExtension on RewardOperationType {
  /// Get user-friendly operation name
  String get displayName {
    switch (this) {
      case RewardOperationType.loadEntries:
        return 'Loading Rewards';
      case RewardOperationType.loadMoreEntries:
        return 'Loading More Rewards';
      case RewardOperationType.addEntry:
        return 'Adding Reward';
      case RewardOperationType.updateEntry:
        return 'Updating Reward';
      case RewardOperationType.deleteEntry:
        return 'Deleting Reward';
      case RewardOperationType.restoreEntry:
        return 'Restoring Reward';
      case RewardOperationType.loadPoints:
        return 'Loading Points';
      case RewardOperationType.loadCategories:
        return 'Loading Categories';
      case RewardOperationType.addCategory:
        return 'Adding Category';
      case RewardOperationType.updateCategory:
        return 'Updating Category';
      case RewardOperationType.deleteCategory:
        return 'Deleting Category';
      case RewardOperationType.search:
        return 'Searching';
      case RewardOperationType.filter:
        return 'Filtering';
      case RewardOperationType.batchOperation:
        return 'Batch Operation';
      case RewardOperationType.sync:
        return 'Syncing';
      case RewardOperationType.export:
        return 'Exporting';
      case RewardOperationType.import:
        return 'Importing';
      case RewardOperationType.loadStatistics:
        return 'Loading Statistics';
      case RewardOperationType.clearCache:
        return 'Clearing Cache';
    }
  }
}