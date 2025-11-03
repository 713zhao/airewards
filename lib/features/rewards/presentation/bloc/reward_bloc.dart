import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/reward_repository.dart';
import '../../domain/usecases/usecases.dart';
import 'reward_event.dart';
import 'reward_state.dart';

/// BLoC for managing reward state and operations.
/// 
/// This BLoC handles all reward-related events including CRUD operations,
/// search and filtering, pagination, real-time updates, batch operations,
/// and synchronization. It provides comprehensive error handling, loading
/// states, and optimistic updates for better UX.
/// 
/// Key features:
/// - CRUD operations for reward entries and categories
/// - Real-time point balance updates with streaming
/// - Advanced search and filtering with debouncing
/// - Pagination support for large datasets
/// - Batch operations for multiple entries
/// - Offline/online synchronization
/// - Import/export functionality
/// - Comprehensive error handling and retry mechanisms
@injectable
class RewardBloc extends Bloc<RewardEvent, RewardState> {
  final RewardRepository _rewardRepository;
  final AddRewardEntry _addRewardEntry;
  final GetRewardHistory _getRewardHistory;
  final UpdateRewardEntry _updateRewardEntry;
  final DeleteRewardEntry _deleteRewardEntry;

  // Stream subscriptions for real-time updates
  StreamSubscription<int>? _pointsSubscription;
  
  // Debouncing for search operations
  final _searchSubject = BehaviorSubject<String>();
  StreamSubscription<String>? _searchSubscription;
  
  // Current state tracking
  String? _currentUserId;
  Timer? _syncTimer;
  
  // Constants
  static const Duration _searchDebounceTime = Duration(milliseconds: 300);
  static const Duration _autoSyncInterval = Duration(minutes: 5);
  
  RewardBloc({
    required RewardRepository rewardRepository,
    required AddRewardEntry addRewardEntry,
    required GetRewardHistory getRewardHistory,
    required UpdateRewardEntry updateRewardEntry,
    required DeleteRewardEntry deleteRewardEntry,
  })  : _rewardRepository = rewardRepository,
        _addRewardEntry = addRewardEntry,
        _getRewardHistory = getRewardHistory,
        _updateRewardEntry = updateRewardEntry,
        _deleteRewardEntry = deleteRewardEntry,
        super(const RewardInitial()) {
    
    // Register event handlers
    on<RewardEntriesLoaded>(_onRewardEntriesLoaded);
    on<RewardEntriesLoadMore>(_onRewardEntriesLoadMore);
    on<RewardEntryAdded>(_onRewardEntryAdded);
    on<RewardEntryUpdated>(_onRewardEntryUpdated);
    on<RewardEntryDeleted>(_onRewardEntryDeleted);
    on<RewardEntryRestored>(_onRewardEntryRestored);
    on<RewardPointsLoaded>(_onRewardPointsLoaded);
    on<RewardPointsWatchStarted>(_onRewardPointsWatchStarted);
    on<RewardPointsWatchStopped>(_onRewardPointsWatchStopped);
    on<RewardPointsUpdated>(_onRewardPointsUpdated);
    on<RewardCategoriesLoaded>(_onRewardCategoriesLoaded);
    on<RewardCategoryAdded>(_onRewardCategoryAdded);
    on<RewardCategoryUpdated>(_onRewardCategoryUpdated);
    on<RewardCategoryDeleted>(_onRewardCategoryDeleted);
    on<RewardEntriesSearched>(_onRewardEntriesSearched);
    on<RewardSearchCleared>(_onRewardSearchCleared);
    on<RewardDateFilterApplied>(_onRewardDateFilterApplied);
    on<RewardCategoryFilterApplied>(_onRewardCategoryFilterApplied);
    on<RewardTypeFilterApplied>(_onRewardTypeFilterApplied);
    on<RewardBatchOperationRequested>(_onRewardBatchOperationRequested);
    on<RewardEntriesSelectionChanged>(_onRewardEntriesSelectionChanged);
    on<RewardEntriesSelectAll>(_onRewardEntriesSelectAll);
    on<RewardEntriesDeselectAll>(_onRewardEntriesDeselectAll);
    on<RewardSyncRequested>(_onRewardSyncRequested);
    on<RewardCacheCleared>(_onRewardCacheCleared);
    on<RewardViewRefreshed>(_onRewardViewRefreshed);
    on<RewardStateReset>(_onRewardStateReset);
    on<RewardOperationRetried>(_onRewardOperationRetried);
    on<RewardErrorCleared>(_onRewardErrorCleared);
    on<RewardLoadingStateChanged>(_onRewardLoadingStateChanged);
    // Export, import, statistics, and trends handlers omitted for now
    
    // Set up search debouncing
    _initializeSearchDebouncing();
  }

  /// Initialize search debouncing
  void _initializeSearchDebouncing() {
    _searchSubscription = _searchSubject
        .debounceTime(_searchDebounceTime)
        .distinct()
        .listen((query) {
      if (_currentUserId != null) {
        add(RewardEntriesSearched(
          userId: _currentUserId!,
          query: query,
        ));
      }
    });
  }

  /// Load reward entries with filtering and pagination
  Future<void> _onRewardEntriesLoaded(
    RewardEntriesLoaded event,
    Emitter<RewardState> emit,
  ) async {
    _currentUserId = event.userId;
    
    if (!event.forceRefresh && state is RewardLoaded) {
      // Return cached data if available and not forcing refresh
      return;
    }

    emit(const RewardLoading(
      message: 'Loading rewards...',
      operationType: RewardOperationType.loadEntries,
    ));

    try {
      // Load entries, points, and categories in parallel
      final futures = await Future.wait([
        _loadRewardEntries(event),
        _loadTotalPoints(event.userId),
        _loadCategories(),
      ]);

      final entriesResult = futures[0] as Either<Failure, PaginatedResult<RewardEntry>>;
      final pointsResult = futures[1] as Either<Failure, int>;
      final categoriesResult = futures[2] as Either<Failure, List<RewardCategory>>;

      // Check for failures
      final entriesFailure = entriesResult.fold((f) => f, (_) => null);
      if (entriesFailure != null) {
        emit(RewardError(
          message: entriesFailure.message,
          errorType: _mapFailureToErrorType(entriesFailure),
          failedOperation: RewardOperationType.loadEntries,
        ));
        return;
      }

      final totalPoints = pointsResult.fold((_) => 0, (points) => points);
      final categories = categoriesResult.fold((_) => <RewardCategory>[], (cats) => cats);

      final entries = entriesResult.fold((_) => null, (result) => result)!;

      emit(RewardLoaded(
        entries: entries,
        totalPoints: totalPoints,
        categories: categories,
        lastUpdated: DateTime.now(),
        hasNextPage: entries.hasNextPage,
        currentSearchQuery: event.searchQuery,
        currentCategoryFilter: event.categoryId,
        currentTypeFilter: event.type,
        currentStartDate: event.startDate,
        currentEndDate: event.endDate,
      ));

      // Start auto-sync if not already running
      _startAutoSync();

    } catch (e) {
      emit(RewardError(
        message: 'Failed to load rewards: ${e.toString()}',
        errorType: RewardErrorType.generic,
        failedOperation: RewardOperationType.loadEntries,
      ));
    }
  }

  /// Load more reward entries for pagination
  Future<void> _onRewardEntriesLoadMore(
    RewardEntriesLoadMore event,
    Emitter<RewardState> emit,
  ) async {
    if (state is! RewardLoaded) return;

    final currentState = state as RewardLoaded;
    if (!currentState.hasNextPage) return;

    emit(const RewardLoading(
      message: 'Loading more rewards...',
      operationType: RewardOperationType.loadMoreEntries,
      showProgress: false,
    ));

    try {
      final nextPage = currentState.entries.currentPage + 1;
      final loadMoreEvent = RewardEntriesLoaded(
        userId: event.userId,
        page: nextPage,
        categoryId: event.categoryId,
        searchQuery: event.searchQuery,
      );

      final result = await _loadRewardEntries(loadMoreEvent);

      result.fold(
        (failure) {
          emit(RewardError(
            message: failure.message,
            errorType: _mapFailureToErrorType(failure),
            failedOperation: RewardOperationType.loadMoreEntries,
          ));
        },
        (newEntries) {
          emit(currentState.withAddedEntries(newEntries.items, newEntries.hasNextPage));
        },
      );

    } catch (e) {
      emit(RewardError(
        message: 'Failed to load more rewards: ${e.toString()}',
        errorType: RewardErrorType.generic,
        failedOperation: RewardOperationType.loadMoreEntries,
      ));
    }
  }

  /// Add a new reward entry
  Future<void> _onRewardEntryAdded(
    RewardEntryAdded event,
    Emitter<RewardState> emit,
  ) async {
    if (state is! RewardLoaded) {
      emit(const RewardError(
        message: 'Cannot add entry: invalid state',
        errorType: RewardErrorType.generic,
      ));
      return;
    }

    final currentState = state as RewardLoaded;

    // Optimistic update
    emit(currentState.withAddedEntry(event.entry));

    emit(const RewardLoading(
      message: 'Adding reward...',
      operationType: RewardOperationType.addEntry,
      showProgress: false,
    ));

    try {
      final result = await _addRewardEntry(AddRewardEntryParams(
        userId: event.entry.userId,
        points: event.entry.points,
        description: event.entry.description,
        categoryId: event.entry.categoryId,
        type: event.entry.type,
      ));

      result.fold(
        (failure) {
          // Revert optimistic update
          emit(currentState.withRemovedEntry(event.entry.id));
          emit(RewardError(
            message: failure.message,
            errorType: _mapFailureToErrorType(failure),
            failedOperation: RewardOperationType.addEntry,
          ));
        },
        (addedEntry) {
          // Update with actual entry (may have different ID from server)
          final updatedState = currentState.withRemovedEntry(event.entry.id);
          final finalState = updatedState.withAddedEntry(addedEntry);
          
          // Update points
          final newTotal = finalState.totalPoints + addedEntry.points;
          emit(finalState.withUpdatedPoints(newTotal));

          if (event.showSuccessMessage) {
            emit(const RewardOperationSuccess(
              message: 'Reward added successfully!',
              operationType: RewardOperationType.addEntry,
            ));
          }
        },
      );

    } catch (e) {
      // Revert optimistic update
      emit(currentState.withRemovedEntry(event.entry.id));
      emit(RewardError(
        message: 'Failed to add reward: ${e.toString()}',
        errorType: RewardErrorType.generic,
        failedOperation: RewardOperationType.addEntry,
      ));
    }
  }

  /// Update an existing reward entry
  Future<void> _onRewardEntryUpdated(
    RewardEntryUpdated event,
    Emitter<RewardState> emit,
  ) async {
    if (state is! RewardLoaded) {
      emit(const RewardError(
        message: 'Cannot update entry: invalid state',
        errorType: RewardErrorType.generic,
      ));
      return;
    }

    final currentState = state as RewardLoaded;
    
    // Find original entry for rollback
    final originalEntry = currentState.entryList.firstWhere(
      (entry) => entry.id == event.entry.id,
      orElse: () => throw Exception('Entry not found'),
    );

    // Optimistic update
    emit(currentState.withUpdatedEntry(event.entry));

    emit(const RewardLoading(
      message: 'Updating reward...',
      operationType: RewardOperationType.updateEntry,
      showProgress: false,
    ));

    try {
      final result = await _updateRewardEntry(UpdateRewardEntryParams(
        entryId: event.entry.id,
        userId: event.entry.userId,
        points: event.entry.points,
        description: event.entry.description,
        categoryId: event.entry.categoryId,
        type: event.entry.type,
      ));

      result.fold(
        (failure) {
          // Revert optimistic update
          emit(currentState.withUpdatedEntry(originalEntry));
          emit(RewardError(
            message: failure.message,
            errorType: _mapFailureToErrorType(failure),
            failedOperation: RewardOperationType.updateEntry,
          ));
        },
        (updatedEntry) {
          final updatedState = currentState.withUpdatedEntry(updatedEntry);
          
          // Update points if changed
          final pointsDifference = updatedEntry.points - originalEntry.points;
          final newTotal = updatedState.totalPoints + pointsDifference;
          emit(updatedState.withUpdatedPoints(newTotal));

          if (event.showSuccessMessage) {
            emit(const RewardOperationSuccess(
              message: 'Reward updated successfully!',
              operationType: RewardOperationType.updateEntry,
            ));
          }
        },
      );

    } catch (e) {
      // Revert optimistic update
      emit(currentState.withUpdatedEntry(originalEntry));
      emit(RewardError(
        message: 'Failed to update reward: ${e.toString()}',
        errorType: RewardErrorType.generic,
        failedOperation: RewardOperationType.updateEntry,
      ));
    }
  }

  /// Delete a reward entry
  Future<void> _onRewardEntryDeleted(
    RewardEntryDeleted event,
    Emitter<RewardState> emit,
  ) async {
    if (state is! RewardLoaded) {
      emit(const RewardError(
        message: 'Cannot delete entry: invalid state',
        errorType: RewardErrorType.generic,
      ));
      return;
    }

    final currentState = state as RewardLoaded;
    
    // Find entry for rollback
    final entryToDelete = currentState.entryList.firstWhere(
      (entry) => entry.id == event.entryId,
      orElse: () => throw Exception('Entry not found'),
    );

    // Optimistic update
    emit(currentState.withRemovedEntry(event.entryId));

    emit(const RewardLoading(
      message: 'Deleting reward...',
      operationType: RewardOperationType.deleteEntry,
      showProgress: false,
    ));

    try {
      final result = await _deleteRewardEntry(DeleteRewardEntryParams(
        entryId: event.entryId,
        userId: event.userId,
      ));

      result.fold(
        (failure) {
          // Revert optimistic update
          emit(currentState.withAddedEntry(entryToDelete));
          emit(RewardError(
            message: failure.message,
            errorType: _mapFailureToErrorType(failure),
            failedOperation: RewardOperationType.deleteEntry,
          ));
        },
        (_) {
          final updatedState = currentState.withRemovedEntry(event.entryId);
          
          // Update points
          final newTotal = updatedState.totalPoints - entryToDelete.points;
          emit(updatedState.withUpdatedPoints(newTotal));

          if (event.showSuccessMessage) {
            emit(const RewardOperationSuccess(
              message: 'Reward deleted successfully!',
              operationType: RewardOperationType.deleteEntry,
            ));
          }
        },
      );

    } catch (e) {
      // Revert optimistic update
      emit(currentState.withAddedEntry(entryToDelete));
      emit(RewardError(
        message: 'Failed to delete reward: ${e.toString()}',
        errorType: RewardErrorType.generic,
        failedOperation: RewardOperationType.deleteEntry,
      ));
    }
  }

  /// Restore a deleted reward entry (placeholder implementation)
  Future<void> _onRewardEntryRestored(
    RewardEntryRestored event,
    Emitter<RewardState> emit,
  ) async {
    // Placeholder - would implement undo functionality
    emit(const RewardOperationSuccess(
      message: 'Restore functionality not yet implemented',
      operationType: RewardOperationType.restoreEntry,
    ));
  }

  /// Load total points for user
  Future<void> _onRewardPointsLoaded(
    RewardPointsLoaded event,
    Emitter<RewardState> emit,
  ) async {
    if (state is! RewardLoaded && !event.forceRefresh) {
      return;
    }

    try {
      final result = await _loadTotalPoints(event.userId);
      
      result.fold(
        (failure) {
          emit(RewardError(
            message: failure.message,
            errorType: _mapFailureToErrorType(failure),
            failedOperation: RewardOperationType.loadPoints,
          ));
        },
        (totalPoints) {
          if (state is RewardLoaded) {
            final currentState = state as RewardLoaded;
            emit(currentState.withUpdatedPoints(totalPoints));
          }
        },
      );

    } catch (e) {
      emit(RewardError(
        message: 'Failed to load points: ${e.toString()}',
        errorType: RewardErrorType.generic,
        failedOperation: RewardOperationType.loadPoints,
      ));
    }
  }

  /// Start watching real-time points updates
  Future<void> _onRewardPointsWatchStarted(
    RewardPointsWatchStarted event,
    Emitter<RewardState> emit,
  ) async {
    await _pointsSubscription?.cancel();
    
    try {
      _pointsSubscription = _rewardRepository.watchTotalPoints(event.userId).listen(
        (totalPoints) => add(RewardPointsUpdated(
          newTotal: totalPoints,
          timestamp: DateTime.now(),
        )),
        onError: (error) {
          dev.log('Points watch stream error: $error', name: 'RewardBloc');
        },
      );

      if (state is RewardLoaded) {
        final currentState = state as RewardLoaded;
        emit(currentState.copyWith(isRealTimeEnabled: true));
      }

    } catch (e) {
      emit(RewardError(
        message: 'Failed to start points watching: ${e.toString()}',
        errorType: RewardErrorType.generic,
      ));
    }
  }

  /// Stop watching real-time points updates
  Future<void> _onRewardPointsWatchStopped(
    RewardPointsWatchStopped event,
    Emitter<RewardState> emit,
  ) async {
    await _pointsSubscription?.cancel();
    _pointsSubscription = null;

    if (state is RewardLoaded) {
      final currentState = state as RewardLoaded;
      emit(currentState.copyWith(isRealTimeEnabled: false));
    }
  }

  /// Handle real-time points updates
  void _onRewardPointsUpdated(
    RewardPointsUpdated event,
    Emitter<RewardState> emit,
  ) {
    if (state is RewardLoaded) {
      final currentState = state as RewardLoaded;
      emit(currentState.withUpdatedPoints(event.newTotal));
    }
  }

  /// Load reward categories
  Future<void> _onRewardCategoriesLoaded(
    RewardCategoriesLoaded event,
    Emitter<RewardState> emit,
  ) async {
    if (state is! RewardLoaded && !event.forceRefresh) {
      return;
    }

    try {
      final result = await _loadCategories();
      
      result.fold(
        (failure) {
          emit(RewardError(
            message: failure.message,
            errorType: _mapFailureToErrorType(failure),
            failedOperation: RewardOperationType.loadCategories,
          ));
        },
        (categories) {
          if (state is RewardLoaded) {
            final currentState = state as RewardLoaded;
            emit(currentState.withUpdatedCategories(categories));
          }
        },
      );

    } catch (e) {
      emit(RewardError(
        message: 'Failed to load categories: ${e.toString()}',
        errorType: RewardErrorType.generic,
        failedOperation: RewardOperationType.loadCategories,
      ));
    }
  }

  /// Add a new reward category
  Future<void> _onRewardCategoryAdded(
    RewardCategoryAdded event,
    Emitter<RewardState> emit,
  ) async {
    emit(const RewardLoading(
      message: 'Adding category...',
      operationType: RewardOperationType.addCategory,
    ));

    try {
      final result = await _rewardRepository.addRewardCategory(event.category);
      
      result.fold(
        (failure) {
          emit(RewardError(
            message: failure.message,
            errorType: _mapFailureToErrorType(failure),
            failedOperation: RewardOperationType.addCategory,
          ));
        },
        (addedCategory) {
          if (state is RewardLoaded) {
            final currentState = state as RewardLoaded;
            final updatedCategories = List<RewardCategory>.from(currentState.categories)
              ..add(addedCategory);
            emit(currentState.withUpdatedCategories(updatedCategories));
          }

          emit(const RewardOperationSuccess(
            message: 'Category added successfully!',
            operationType: RewardOperationType.addCategory,
          ));
        },
      );

    } catch (e) {
      emit(RewardError(
        message: 'Failed to add category: ${e.toString()}',
        errorType: RewardErrorType.generic,
        failedOperation: RewardOperationType.addCategory,
      ));
    }
  }

  /// Update an existing reward category
  Future<void> _onRewardCategoryUpdated(
    RewardCategoryUpdated event,
    Emitter<RewardState> emit,
  ) async {
    emit(const RewardLoading(
      message: 'Updating category...',
      operationType: RewardOperationType.updateCategory,
    ));

    try {
      final result = await _rewardRepository.updateRewardCategory(event.category);
      
      result.fold(
        (failure) {
          emit(RewardError(
            message: failure.message,
            errorType: _mapFailureToErrorType(failure),
            failedOperation: RewardOperationType.updateCategory,
          ));
        },
        (updatedCategory) {
          if (state is RewardLoaded) {
            final currentState = state as RewardLoaded;
            final updatedCategories = currentState.categories.map((cat) {
              return cat.id == updatedCategory.id ? updatedCategory : cat;
            }).toList();
            emit(currentState.withUpdatedCategories(updatedCategories));
          }

          emit(const RewardOperationSuccess(
            message: 'Category updated successfully!',
            operationType: RewardOperationType.updateCategory,
          ));
        },
      );

    } catch (e) {
      emit(RewardError(
        message: 'Failed to update category: ${e.toString()}',
        errorType: RewardErrorType.generic,
        failedOperation: RewardOperationType.updateCategory,
      ));
    }
  }

  /// Delete a reward category
  Future<void> _onRewardCategoryDeleted(
    RewardCategoryDeleted event,
    Emitter<RewardState> emit,
  ) async {
    emit(const RewardLoading(
      message: 'Deleting category...',
      operationType: RewardOperationType.deleteCategory,
    ));

    try {
      final result = await _rewardRepository.deleteRewardCategory(
        categoryId: event.categoryId,
        reassignToCategoryId: event.reassignToCategoryId,
      );
      
      result.fold(
        (failure) {
          emit(RewardError(
            message: failure.message,
            errorType: _mapFailureToErrorType(failure),
            failedOperation: RewardOperationType.deleteCategory,
          ));
        },
        (_) {
          if (state is RewardLoaded) {
            final currentState = state as RewardLoaded;
            final updatedCategories = currentState.categories
                .where((cat) => cat.id != event.categoryId)
                .toList();
            emit(currentState.withUpdatedCategories(updatedCategories));
          }

          emit(const RewardOperationSuccess(
            message: 'Category deleted successfully!',
            operationType: RewardOperationType.deleteCategory,
          ));
        },
      );

    } catch (e) {
      emit(RewardError(
        message: 'Failed to delete category: ${e.toString()}',
        errorType: RewardErrorType.generic,
        failedOperation: RewardOperationType.deleteCategory,
      ));
    }
  }

  /// Search reward entries with debouncing
  void _onRewardEntriesSearched(
    RewardEntriesSearched event,
    Emitter<RewardState> emit,
  ) {
    _searchSubject.add(event.query);
  }

  /// Clear search and reset filters
  Future<void> _onRewardSearchCleared(
    RewardSearchCleared event,
    Emitter<RewardState> emit,
  ) async {
    if (state is RewardLoaded) {
      final currentState = state as RewardLoaded;
      emit(currentState.withClearedFilters());
      
      // Reload entries without filters
      add(RewardEntriesLoaded(
        userId: event.userId,
        forceRefresh: true,
      ));
    }
  }

  /// Apply date range filter
  Future<void> _onRewardDateFilterApplied(
    RewardDateFilterApplied event,
    Emitter<RewardState> emit,
  ) async {
    if (state is RewardLoaded) {
      final currentState = state as RewardLoaded;
      emit(currentState.withFilters(
        startDate: event.startDate,
        endDate: event.endDate,
      ));
      
      // Reload entries with date filter
      add(RewardEntriesLoaded(
        userId: event.userId,
        startDate: event.startDate,
        endDate: event.endDate,
        forceRefresh: true,
      ));
    }
  }

  /// Apply category filter
  Future<void> _onRewardCategoryFilterApplied(
    RewardCategoryFilterApplied event,
    Emitter<RewardState> emit,
  ) async {
    if (state is RewardLoaded) {
      final currentState = state as RewardLoaded;
      emit(currentState.withFilters(categoryId: event.categoryId));
      
      // Reload entries with category filter
      add(RewardEntriesLoaded(
        userId: event.userId,
        categoryId: event.categoryId,
        forceRefresh: true,
      ));
    }
  }

  /// Apply type filter
  Future<void> _onRewardTypeFilterApplied(
    RewardTypeFilterApplied event,
    Emitter<RewardState> emit,
  ) async {
    if (state is RewardLoaded) {
      final currentState = state as RewardLoaded;
      emit(currentState.withFilters(type: event.type));
      
      // Reload entries with type filter
      add(RewardEntriesLoaded(
        userId: event.userId,
        type: event.type,
        forceRefresh: true,
      ));
    }
  }

  /// Handle batch operations
  Future<void> _onRewardBatchOperationRequested(
    RewardBatchOperationRequested event,
    Emitter<RewardState> emit,
  ) async {
    emit(RewardBatchOperationInProgress(
      operations: event.operations,
      completed: 0,
      total: event.operations.length,
      currentOperationMessage: 'Starting batch operation...',
    ));

    try {
      final result = await _rewardRepository.batchOperations(event.operations);
      
      result.fold(
        (failure) {
          emit(RewardError(
            message: failure.message,
            errorType: _mapFailureToErrorType(failure),
            failedOperation: RewardOperationType.batchOperation,
          ));
        },
        (results) {
          emit(const RewardOperationSuccess(
            message: 'Batch operation completed successfully!',
            operationType: RewardOperationType.batchOperation,
          ));
          
          // Refresh the view to show updated data
          if (_currentUserId != null) {
            add(RewardViewRefreshed(userId: _currentUserId!));
          }
        },
      );

    } catch (e) {
      emit(RewardError(
        message: 'Failed to perform batch operation: ${e.toString()}',
        errorType: RewardErrorType.generic,
        failedOperation: RewardOperationType.batchOperation,
      ));
    }
  }

  /// Update selection
  void _onRewardEntriesSelectionChanged(
    RewardEntriesSelectionChanged event,
    Emitter<RewardState> emit,
  ) {
    if (state is RewardLoaded) {
      final currentState = state as RewardLoaded;
      emit(currentState.withUpdatedSelection(event.selectedEntryIds));
    }
  }

  /// Select all visible entries
  void _onRewardEntriesSelectAll(
    RewardEntriesSelectAll event,
    Emitter<RewardState> emit,
  ) {
    if (state is RewardLoaded) {
      final currentState = state as RewardLoaded;
      final allIds = currentState.entryList.map((entry) => entry.id).toList();
      emit(currentState.withUpdatedSelection(allIds));
    }
  }

  /// Deselect all entries
  void _onRewardEntriesDeselectAll(
    RewardEntriesDeselectAll event,
    Emitter<RewardState> emit,
  ) {
    if (state is RewardLoaded) {
      final currentState = state as RewardLoaded;
      emit(currentState.withUpdatedSelection([]));
    }
  }

  /// Request sync with server
  Future<void> _onRewardSyncRequested(
    RewardSyncRequested event,
    Emitter<RewardState> emit,
  ) async {
    if (event.showProgress) {
      emit(const RewardSyncInProgress(
        status: SyncStatus.uploading,
        statusMessage: 'Syncing rewards...',
      ));
    }

    try {
      final result = await _rewardRepository.syncWithServer();
      
      result.fold(
        (failure) {
          emit(RewardError(
            message: failure.message,
            errorType: RewardErrorType.sync,
            failedOperation: RewardOperationType.sync,
          ));
        },
        (syncResult) {
          emit(RewardSyncCompleted(
            result: syncResult,
            completedAt: DateTime.now(),
          ));
        },
      );

    } catch (e) {
      emit(RewardError(
        message: 'Failed to sync rewards: ${e.toString()}',
        errorType: RewardErrorType.sync,
        failedOperation: RewardOperationType.sync,
      ));
    }
  }

  /// Clear cache and reload
  Future<void> _onRewardCacheCleared(
    RewardCacheCleared event,
    Emitter<RewardState> emit,
  ) async {
    emit(const RewardLoading(
      message: 'Clearing cache...',
      operationType: RewardOperationType.clearCache,
    ));

    // Force reload of all data
    add(RewardEntriesLoaded(
      userId: event.userId,
      forceRefresh: true,
    ));
  }

  /// Refresh the entire view
  Future<void> _onRewardViewRefreshed(
    RewardViewRefreshed event,
    Emitter<RewardState> emit,
  ) async {
    add(RewardEntriesLoaded(
      userId: event.userId,
      forceRefresh: true,
    ));
  }

  /// Reset BLoC state
  void _onRewardStateReset(
    RewardStateReset event,
    Emitter<RewardState> emit,
  ) {
    _stopAllSubscriptions();
    emit(const RewardInitial());
  }

  /// Retry failed operations
  void _onRewardOperationRetried(
    RewardOperationRetried event,
    Emitter<RewardState> emit,
  ) {
    if (state is RewardError) {
      final errorState = state as RewardError;
      
      if (_currentUserId != null) {
        switch (errorState.failedOperation) {
          case RewardOperationType.loadEntries:
            add(RewardEntriesLoaded(userId: _currentUserId!));
            break;
          case RewardOperationType.loadPoints:
            add(RewardPointsLoaded(userId: _currentUserId!));
            break;
          case RewardOperationType.loadCategories:
            add(const RewardCategoriesLoaded());
            break;
          case RewardOperationType.sync:
            add(const RewardSyncRequested());
            break;
          default:
            emit(const RewardError(
              message: 'Cannot retry this operation',
              errorType: RewardErrorType.generic,
            ));
        }
      }
    }
  }

  /// Clear error state
  void _onRewardErrorCleared(
    RewardErrorCleared event,
    Emitter<RewardState> emit,
  ) {
    if (_currentUserId != null) {
      add(RewardEntriesLoaded(userId: _currentUserId!));
    } else {
      emit(const RewardInitial());
    }
  }

  /// Change loading state
  void _onRewardLoadingStateChanged(
    RewardLoadingStateChanged event,
    Emitter<RewardState> emit,
  ) {
    if (event.isLoading) {
      emit(RewardLoading(
        message: event.message ?? 'Loading...',
      ));
    } else if (state is RewardLoading) {
      // Return to previous state or initial
      emit(const RewardInitial());
    }
  }

  // Export/import and statistics methods to be implemented later

  // Helper methods

  /// Load reward entries using the use case
  Future<Either<Failure, PaginatedResult<RewardEntry>>> _loadRewardEntries(
    RewardEntriesLoaded event,
  ) async {
    return await _getRewardHistory(GetRewardHistoryParams(
      userId: event.userId,
      page: event.page,
      limit: event.limit,
      startDate: event.startDate,
      endDate: event.endDate,
      categoryId: event.categoryId,
      type: event.type,
    ));
  }

  /// Load total points from repository
  Future<Either<Failure, int>> _loadTotalPoints(String userId) async {
    return await _rewardRepository.getTotalPoints(userId);
  }

  /// Load categories from repository
  Future<Either<Failure, List<RewardCategory>>> _loadCategories() async {
    return await _rewardRepository.getRewardCategories();
  }

  /// Start automatic sync timer
  void _startAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_autoSyncInterval, (_) {
      add(const RewardSyncRequested(showProgress: false));
    });
  }

  /// Stop all active subscriptions and timers
  void _stopAllSubscriptions() {
    _pointsSubscription?.cancel();
    _searchSubscription?.cancel();
    _syncTimer?.cancel();
    _searchSubject.close();
  }

  /// Map failure to appropriate error type
  RewardErrorType _mapFailureToErrorType(Failure failure) {
    if (failure is NetworkFailure) {
      return RewardErrorType.network;
    } else if (failure is DatabaseFailure) {
      return RewardErrorType.database;
    } else if (failure is ValidationFailure) {
      return RewardErrorType.validation;
    } else if (failure is AuthFailure) {
      return RewardErrorType.permission;
    } else if (failure is CacheFailure) {
      return RewardErrorType.database;
    } else {
      return RewardErrorType.generic;
    }
  }

  @override
  Future<void> close() {
    _stopAllSubscriptions();
    return super.close();
  }
}