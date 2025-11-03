import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/redemption_repository.dart';
import '../../domain/usecases/usecases.dart';
import 'redemption_event.dart';
import 'redemption_state.dart';

/// BLoC for managing redemption state and operations.
/// 
/// This BLoC handles all redemption-related events including loading options,
/// processing redemptions, managing user balance, validation, and history.
/// It provides comprehensive error handling, loading states, and real-time
/// updates for a seamless redemption experience.
/// 
/// Key features:
/// - Loading and filtering of redemption options
/// - Point balance validation and management
/// - Redemption flow with confirmation dialogs
/// - Transaction processing and status tracking
/// - Redemption history with pagination
/// - Real-time balance updates
/// - Comprehensive error handling and retry mechanisms
@injectable
class RedemptionBloc extends Bloc<RedemptionEvent, RedemptionState> {
  final RedemptionRepository _redemptionRepository;
  final RedeemPoints _redeemPoints;
  final ValidateRedemption _validateRedemption;
  final GetRedemptionHistory _getRedemptionHistory;
  final GetRedemptionStats _getRedemptionStats;

  // Stream subscriptions for real-time updates
  StreamSubscription<int>? _balanceSubscription;
  StreamSubscription<RedemptionStatus>? _statusSubscription;
  
  // Debouncing for search operations
  final _searchSubject = BehaviorSubject<String>();
  StreamSubscription<String>? _searchSubscription;
  
  // Current state tracking
  String? _currentUserId;
  Timer? _refreshTimer;
  
  // Constants
  static const Duration _searchDebounceTime = Duration(milliseconds: 300);
  static const Duration _autoRefreshInterval = Duration(minutes: 10);
  static const Duration _confirmationTimeout = Duration(minutes: 5);
  
  RedemptionBloc({
    required RedemptionRepository redemptionRepository,
    required RedeemPoints redeemPoints,
    required ValidateRedemption validateRedemption,
    required GetRedemptionHistory getRedemptionHistory,
    required GetRedemptionStats getRedemptionStats,
  })  : _redemptionRepository = redemptionRepository,
        _redeemPoints = redeemPoints,
        _validateRedemption = validateRedemption,
        _getRedemptionHistory = getRedemptionHistory,
        _getRedemptionStats = getRedemptionStats,
        super(const RedemptionInitial()) {
    
    // Register event handlers
    on<RedemptionOptionsLoaded>(_onRedemptionOptionsLoaded);
    on<RedemptionOptionsLoadMore>(_onRedemptionOptionsLoadMore);
    on<RedemptionRequested>(_onRedemptionRequested);
    on<RedemptionConfirmed>(_onRedemptionConfirmed);
    on<RedemptionCancelled>(_onRedemptionCancelled);
    on<RedemptionHistoryLoaded>(_onRedemptionHistoryLoaded);
    on<RedemptionHistoryLoadMore>(_onRedemptionHistoryLoadMore);
    on<RedemptionPointBalanceChecked>(_onRedemptionPointBalanceChecked);
    on<RedemptionEligibilityChecked>(_onRedemptionEligibilityChecked);
    on<RedemptionCategoryFilterApplied>(_onRedemptionCategoryFilterApplied);
    on<RedemptionPointRangeFilterApplied>(_onRedemptionPointRangeFilterApplied);
    on<RedemptionOptionsSearched>(_onRedemptionOptionsSearched);
    on<RedemptionSearchCleared>(_onRedemptionSearchCleared);
    on<RedemptionDataRefreshed>(_onRedemptionDataRefreshed);
    on<RedemptionOperationRetried>(_onRedemptionOperationRetried);
    on<RedemptionErrorCleared>(_onRedemptionErrorCleared);
    on<RedemptionStateReset>(_onRedemptionStateReset);
    on<RedemptionStatusUpdated>(_onRedemptionStatusUpdated);
    on<RedemptionCategoriesLoaded>(_onRedemptionCategoriesLoaded);
    
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
        add(RedemptionOptionsLoaded(
          userId: _currentUserId!,
          forceRefresh: true,
        ));
      }
    });
  }

  /// Load redemption options with filtering and user balance
  Future<void> _onRedemptionOptionsLoaded(
    RedemptionOptionsLoaded event,
    Emitter<RedemptionState> emit,
  ) async {
    _currentUserId = event.userId;
    
    if (!event.forceRefresh && state is RedemptionLoaded) {
      // Return cached data if available and not forcing refresh
      return;
    }

    emit(const RedemptionLoading(
      message: 'Loading redemption options...',
      operationType: RedemptionOperationType.loadOptions,
    ));

    try {
      // Load options, balance, categories, and recent transactions in parallel
      final futures = await Future.wait([
        _loadRedemptionOptions(event),
        _loadUserBalance(event.userId),
        _loadCategories(),
        _loadRecentTransactions(event.userId),
      ]);

      final optionsResult = futures[0] as Either<Failure, PaginatedResult<RedemptionOption>>;
      final balanceResult = futures[1] as Either<Failure, int>;
      final categoriesResult = futures[2] as Either<Failure, List<RedemptionCategory>>;
      final transactionsResult = futures[3] as Either<Failure, List<RedemptionTransaction>>;

      // Check for options failure
      final optionsFailure = optionsResult.fold((f) => f, (_) => null);
      if (optionsFailure != null) {
        emit(RedemptionError(
          message: optionsFailure.message,
          errorType: _mapFailureToErrorType(optionsFailure),
          failedOperation: RedemptionOperationType.loadOptions,
        ));
        return;
      }

      final balance = balanceResult.fold((_) => 0, (points) => points);
      final categories = categoriesResult.fold((_) => <RedemptionCategory>[], (cats) => cats);
      final transactions = transactionsResult.fold((_) => <RedemptionTransaction>[], (txns) => txns);
      final options = optionsResult.fold((_) => null, (result) => result)!;

      emit(RedemptionLoaded(
        options: options,
        userPointBalance: balance,
        categories: categories,
        recentTransactions: transactions,
        lastUpdated: DateTime.now(),
        hasNextPage: options.hasNextPage,
        currentCategoryFilter: event.category,
        currentMinPoints: event.minPoints,
        currentMaxPoints: event.maxPoints,
      ));

      // Start auto-refresh if not already running
      _startAutoRefresh();

    } catch (e) {
      emit(RedemptionError(
        message: 'Failed to load redemption options: ${e.toString()}',
        errorType: RedemptionErrorType.generic,
        failedOperation: RedemptionOperationType.loadOptions,
      ));
    }
  }

  /// Load more redemption options for pagination
  Future<void> _onRedemptionOptionsLoadMore(
    RedemptionOptionsLoadMore event,
    Emitter<RedemptionState> emit,
  ) async {
    if (state is! RedemptionLoaded) return;

    final currentState = state as RedemptionLoaded;
    if (!currentState.hasNextPage) return;

    emit(const RedemptionLoading(
      message: 'Loading more options...',
      operationType: RedemptionOperationType.loadMoreOptions,
      showProgress: false,
    ));

    try {
      final nextPage = currentState.options.currentPage + 1;
      final loadMoreEvent = RedemptionOptionsLoaded(
        userId: event.userId,
        page: nextPage,
        category: event.category,
        minPoints: event.minPoints,
        maxPoints: event.maxPoints,
      );

      final result = await _loadRedemptionOptions(loadMoreEvent);

      result.fold(
        (failure) {
          emit(RedemptionError(
            message: failure.message,
            errorType: _mapFailureToErrorType(failure),
            failedOperation: RedemptionOperationType.loadMoreOptions,
          ));
        },
        (newOptions) {
          emit(currentState.withAddedOptions(newOptions.items, newOptions.hasNextPage));
        },
      );

    } catch (e) {
      emit(RedemptionError(
        message: 'Failed to load more options: ${e.toString()}',
        errorType: RedemptionErrorType.generic,
        failedOperation: RedemptionOperationType.loadMoreOptions,
      ));
    }
  }

  /// Request a redemption (shows confirmation dialog)
  Future<void> _onRedemptionRequested(
    RedemptionRequested event,
    Emitter<RedemptionState> emit,
  ) async {
    if (state is! RedemptionLoaded) {
      emit(const RedemptionError(
        message: 'Cannot process redemption: invalid state',
        errorType: RedemptionErrorType.validation,
      ));
      return;
    }

    final currentState = state as RedemptionLoaded;

    emit(const RedemptionLoading(
      message: 'Validating redemption...',
      operationType: RedemptionOperationType.validateRedemption,
      showProgress: false,
    ));

    try {
      // Find the option
      final option = currentState.options.items.firstWhere(
        (opt) => opt.id == event.optionId,
        orElse: () => throw ArgumentError('Option not found'),
      );

      // Validate the redemption
      final validationResult = await _validateRedemption(ValidateRedemptionParams(
        userId: event.userId,
        optionId: event.optionId,
        quantity: event.quantity,
      ));

      validationResult.fold(
        (failure) {
          emit(RedemptionError(
            message: failure.message,
            errorType: _mapFailureToErrorType(failure),
            failedOperation: RedemptionOperationType.validateRedemption,
            optionId: event.optionId,
            attemptedQuantity: event.quantity,
          ));
        },
        (validation) {
          if (event.skipConfirmation) {
            // Skip confirmation and process directly
            add(RedemptionConfirmed(
              userId: event.userId,
              optionId: event.optionId,
              quantity: event.quantity,
              totalPointsCost: option.requiredPoints * event.quantity,
            ));
          } else {
            // Show confirmation dialog
            final totalCost = option.requiredPoints * event.quantity;
            final remainingPoints = currentState.userPointBalance - totalCost;

            emit(RedemptionPendingConfirmation(
              option: option,
              quantity: event.quantity,
              totalPointsCost: totalCost,
              remainingPointsAfter: remainingPoints,
              confirmationMessage: _buildConfirmationMessage(option, event.quantity, totalCost),
              expiresAt: DateTime.now().add(_confirmationTimeout),
            ));
          }
        },
      );

    } catch (e) {
      emit(RedemptionError(
        message: 'Failed to validate redemption: ${e.toString()}',
        errorType: RedemptionErrorType.validation,
        failedOperation: RedemptionOperationType.validateRedemption,
        optionId: event.optionId,
        attemptedQuantity: event.quantity,
      ));
    }
  }

  /// Confirm and process the redemption
  Future<void> _onRedemptionConfirmed(
    RedemptionConfirmed event,
    Emitter<RedemptionState> emit,
  ) async {
    if (state is! RedemptionPendingConfirmation && state is! RedemptionLoaded) {
      emit(const RedemptionError(
        message: 'Cannot confirm redemption: invalid state',
        errorType: RedemptionErrorType.validation,
      ));
      return;
    }

    // Get option details
    RedemptionOption option;
    if (state is RedemptionPendingConfirmation) {
      final pendingState = state as RedemptionPendingConfirmation;
      option = pendingState.option;
    } else {
      final loadedState = state as RedemptionLoaded;
      option = loadedState.options.items.firstWhere(
        (opt) => opt.id == event.optionId,
        orElse: () => throw ArgumentError('Option not found'),
      );
    }

    final transactionId = _generateTransactionId();

    emit(RedemptionProcessing(
      transactionId: transactionId,
      option: option,
      quantity: event.quantity,
      totalPointsCost: event.totalPointsCost,
      status: RedemptionStatus.processing,
      statusMessage: 'Processing your redemption...',
      startedAt: DateTime.now(),
    ));

    try {
      final result = await _redeemPoints(RedeemPointsParams(
        userId: event.userId,
        optionId: event.optionId,
        quantity: event.quantity,
      ));

      result.fold(
        (failure) {
          emit(RedemptionError(
            message: failure.message,
            errorType: _mapFailureToErrorType(failure),
            failedOperation: RedemptionOperationType.processRedemption,
            optionId: event.optionId,
            attemptedQuantity: event.quantity,
          ));
        },
        (transaction) {
          emit(RedemptionSuccess(
            transaction: transaction,
            newPointBalance: transaction.userBalanceAfter,
            successMessage: _buildSuccessMessage(option, event.quantity),
            completedAt: DateTime.now(),
            confirmationCode: transaction.confirmationCode,
          ));

          // Refresh data after successful redemption
          if (_currentUserId != null) {
            add(RedemptionDataRefreshed(userId: _currentUserId!));
          }
        },
      );

    } catch (e) {
      emit(RedemptionError(
        message: 'Failed to process redemption: ${e.toString()}',
        errorType: RedemptionErrorType.server,
        failedOperation: RedemptionOperationType.processRedemption,
        optionId: event.optionId,
        attemptedQuantity: event.quantity,
      ));
    }
  }

  /// Cancel pending redemption
  void _onRedemptionCancelled(
    RedemptionCancelled event,
    Emitter<RedemptionState> emit,
  ) {
    if (_currentUserId != null) {
      add(RedemptionOptionsLoaded(userId: _currentUserId!));
    } else {
      emit(const RedemptionInitial());
    }
  }

  /// Load redemption history
  Future<void> _onRedemptionHistoryLoaded(
    RedemptionHistoryLoaded event,
    Emitter<RedemptionState> emit,
  ) async {
    emit(const RedemptionLoading(
      message: 'Loading redemption history...',
      operationType: RedemptionOperationType.loadHistory,
    ));

    try {
      final result = await _getRedemptionHistory(GetRedemptionHistoryParams(
        userId: event.userId,
        page: event.page,
        limit: event.limit,
        startDate: event.startDate,
        endDate: event.endDate,
        status: event.status,
      ));

      result.fold(
        (failure) {
          emit(RedemptionError(
            message: failure.message,
            errorType: _mapFailureToErrorType(failure),
            failedOperation: RedemptionOperationType.loadHistory,
          ));
        },
        (transactions) {
          emit(RedemptionHistoryLoaded(
            transactions: transactions,
            lastUpdated: DateTime.now(),
            hasNextPage: transactions.hasNextPage,
            currentStartDate: event.startDate,
            currentEndDate: event.endDate,
            currentStatusFilter: event.status,
          ));
        },
      );

    } catch (e) {
      emit(RedemptionError(
        message: 'Failed to load redemption history: ${e.toString()}',
        errorType: RedemptionErrorType.generic,
        failedOperation: RedemptionOperationType.loadHistory,
      ));
    }
  }

  /// Load more redemption history entries
  Future<void> _onRedemptionHistoryLoadMore(
    RedemptionHistoryLoadMore event,
    Emitter<RedemptionState> emit,
  ) async {
    if (state is! RedemptionHistoryLoaded) return;

    final currentState = state as RedemptionHistoryLoaded;
    if (!currentState.hasNextPage) return;

    emit(const RedemptionLoading(
      message: 'Loading more history...',
      operationType: RedemptionOperationType.loadMoreHistory,
      showProgress: false,
    ));

    try {
      final nextPage = currentState.transactions.currentPage + 1;
      final result = await _getRedemptionHistory(GetRedemptionHistoryParams(
        userId: event.userId,
        page: nextPage,
        limit: 20, // Use default limit
        startDate: event.startDate,
        endDate: event.endDate,
        status: event.status,
      ));

      result.fold(
        (failure) {
          emit(RedemptionError(
            message: failure.message,
            errorType: _mapFailureToErrorType(failure),
            failedOperation: RedemptionOperationType.loadMoreHistory,
          ));
        },
        (newTransactions) {
          emit(currentState.withAddedTransactions(newTransactions.items, newTransactions.hasNextPage));
        },
      );

    } catch (e) {
      emit(RedemptionError(
        message: 'Failed to load more history: ${e.toString()}',
        errorType: RedemptionErrorType.generic,
        failedOperation: RedemptionOperationType.loadMoreHistory,
      ));
    }
  }

  /// Check user point balance
  Future<void> _onRedemptionPointBalanceChecked(
    RedemptionPointBalanceChecked event,
    Emitter<RedemptionState> emit,
  ) async {
    if (state is! RedemptionLoaded && !event.forceRefresh) {
      return;
    }

    try {
      final result = await _loadUserBalance(event.userId);
      
      result.fold(
        (failure) {
          emit(RedemptionError(
            message: failure.message,
            errorType: _mapFailureToErrorType(failure),
            failedOperation: RedemptionOperationType.loadBalance,
          ));
        },
        (balance) {
          if (state is RedemptionLoaded) {
            final currentState = state as RedemptionLoaded;
            emit(currentState.withUpdatedBalance(balance));
          }
        },
      );

    } catch (e) {
      emit(RedemptionError(
        message: 'Failed to check balance: ${e.toString()}',
        errorType: RedemptionErrorType.generic,
        failedOperation: RedemptionOperationType.loadBalance,
      ));
    }
  }

  /// Check redemption eligibility
  Future<void> _onRedemptionEligibilityChecked(
    RedemptionEligibilityChecked event,
    Emitter<RedemptionState> emit,
  ) async {
    emit(const RedemptionLoading(
      message: 'Checking eligibility...',
      operationType: RedemptionOperationType.checkEligibility,
      showProgress: false,
    ));

    try {
      final result = await _validateRedemption(ValidateRedemptionParams(
        userId: event.userId,
        optionId: event.optionId,
        quantity: event.quantity,
      ));

      result.fold(
        (failure) {
          emit(RedemptionError(
            message: failure.message,
            errorType: _mapFailureToErrorType(failure),
            failedOperation: RedemptionOperationType.checkEligibility,
            optionId: event.optionId,
            attemptedQuantity: event.quantity,
          ));
        },
        (_) {
          // Eligibility check passed - return to loaded state
          if (_currentUserId != null) {
            add(RedemptionOptionsLoaded(userId: _currentUserId!));
          }
        },
      );

    } catch (e) {
      emit(RedemptionError(
        message: 'Failed to check eligibility: ${e.toString()}',
        errorType: RedemptionErrorType.generic,
        failedOperation: RedemptionOperationType.checkEligibility,
        optionId: event.optionId,
        attemptedQuantity: event.quantity,
      ));
    }
  }

  /// Apply category filter
  Future<void> _onRedemptionCategoryFilterApplied(
    RedemptionCategoryFilterApplied event,
    Emitter<RedemptionState> emit,
  ) async {
    if (state is RedemptionLoaded) {
      final currentState = state as RedemptionLoaded;
      emit(currentState.withCategoryFilter(event.category));
      
      // Reload options with category filter
      add(RedemptionOptionsLoaded(
        userId: event.userId,
        category: event.category,
        forceRefresh: true,
      ));
    }
  }

  /// Apply point range filter
  Future<void> _onRedemptionPointRangeFilterApplied(
    RedemptionPointRangeFilterApplied event,
    Emitter<RedemptionState> emit,
  ) async {
    if (state is RedemptionLoaded) {
      final currentState = state as RedemptionLoaded;
      emit(currentState.withPointRangeFilter(
        minPoints: event.minPoints,
        maxPoints: event.maxPoints,
      ));
      
      // Reload options with point range filter
      add(RedemptionOptionsLoaded(
        userId: event.userId,
        minPoints: event.minPoints,
        maxPoints: event.maxPoints,
        forceRefresh: true,
      ));
    }
  }

  /// Search redemption options
  void _onRedemptionOptionsSearched(
    RedemptionOptionsSearched event,
    Emitter<RedemptionState> emit,
  ) {
    _searchSubject.add(event.query);
  }

  /// Clear search and filters
  Future<void> _onRedemptionSearchCleared(
    RedemptionSearchCleared event,
    Emitter<RedemptionState> emit,
  ) async {
    if (state is RedemptionLoaded) {
      final currentState = state as RedemptionLoaded;
      emit(currentState.withClearedFilters());
      
      // Reload options without filters
      add(RedemptionOptionsLoaded(
        userId: event.userId,
        forceRefresh: true,
      ));
    }
  }

  /// Refresh all redemption data
  Future<void> _onRedemptionDataRefreshed(
    RedemptionDataRefreshed event,
    Emitter<RedemptionState> emit,
  ) async {
    add(RedemptionOptionsLoaded(
      userId: event.userId,
      forceRefresh: true,
    ));
  }

  /// Retry failed operations
  void _onRedemptionOperationRetried(
    RedemptionOperationRetried event,
    Emitter<RedemptionState> emit,
  ) {
    if (state is RedemptionError) {
      final errorState = state as RedemptionError;
      
      if (_currentUserId != null) {
        switch (errorState.failedOperation) {
          case RedemptionOperationType.loadOptions:
            add(RedemptionOptionsLoaded(userId: _currentUserId!));
            break;
          case RedemptionOperationType.loadBalance:
            add(RedemptionPointBalanceChecked(userId: _currentUserId!));
            break;
          case RedemptionOperationType.loadHistory:
            add(RedemptionHistoryLoaded(userId: _currentUserId!));
            break;
          case RedemptionOperationType.validateRedemption:
          case RedemptionOperationType.processRedemption:
            if (errorState.optionId != null && errorState.attemptedQuantity != null) {
              add(RedemptionRequested(
                userId: _currentUserId!,
                optionId: errorState.optionId!,
                quantity: errorState.attemptedQuantity!,
              ));
            }
            break;
          default:
            emit(const RedemptionError(
              message: 'Cannot retry this operation',
              errorType: RedemptionErrorType.generic,
            ));
        }
      }
    }
  }

  /// Clear error state
  void _onRedemptionErrorCleared(
    RedemptionErrorCleared event,
    Emitter<RedemptionState> emit,
  ) {
    if (_currentUserId != null) {
      add(RedemptionOptionsLoaded(userId: _currentUserId!));
    } else {
      emit(const RedemptionInitial());
    }
  }

  /// Reset BLoC state
  void _onRedemptionStateReset(
    RedemptionStateReset event,
    Emitter<RedemptionState> emit,
  ) {
    _stopAllSubscriptions();
    emit(const RedemptionInitial());
  }

  /// Update redemption status from external notifications
  void _onRedemptionStatusUpdated(
    RedemptionStatusUpdated event,
    Emitter<RedemptionState> emit,
  ) {
    if (state is RedemptionProcessing) {
      final processingState = state as RedemptionProcessing;
      
      if (processingState.transactionId == event.transactionId) {
        emit(RedemptionProcessing(
          transactionId: processingState.transactionId,
          option: processingState.option,
          quantity: processingState.quantity,
          totalPointsCost: processingState.totalPointsCost,
          status: event.newStatus,
          statusMessage: event.statusMessage ?? _getStatusMessage(event.newStatus),
          progress: _getStatusProgress(event.newStatus),
          startedAt: processingState.startedAt,
        ));
      }
    }
  }

  /// Load redemption categories
  Future<void> _onRedemptionCategoriesLoaded(
    RedemptionCategoriesLoaded event,
    Emitter<RedemptionState> emit,
  ) async {
    if (state is! RedemptionLoaded && !event.forceRefresh) {
      return;
    }

    try {
      final result = await _loadCategories();
      
      result.fold(
        (failure) {
          emit(RedemptionError(
            message: failure.message,
            errorType: _mapFailureToErrorType(failure),
            failedOperation: RedemptionOperationType.loadOptions,
          ));
        },
        (categories) {
          if (state is RedemptionLoaded) {
            final currentState = state as RedemptionLoaded;
            emit(currentState.withUpdatedCategories(categories));
          }
        },
      );

    } catch (e) {
      emit(RedemptionError(
        message: 'Failed to load categories: ${e.toString()}',
        errorType: RedemptionErrorType.generic,
      ));
    }
  }

  // Helper methods

  /// Load redemption options from repository
  Future<Either<Failure, PaginatedResult<RedemptionOption>>> _loadRedemptionOptions(
    RedemptionOptionsLoaded event,
  ) async {
    return await _redemptionRepository.getRedemptionOptions(
      page: event.page,
      limit: event.limit,
      category: event.category,
      minPoints: event.minPoints,
      maxPoints: event.maxPoints,
    );
  }

  /// Load user balance from repository
  Future<Either<Failure, int>> _loadUserBalance(String userId) async {
    return await _redemptionRepository.getUserPointBalance(userId);
  }

  /// Load categories from repository
  Future<Either<Failure, List<RedemptionCategory>>> _loadCategories() async {
    return await _redemptionRepository.getRedemptionCategories();
  }

  /// Load recent transactions from repository
  Future<Either<Failure, List<RedemptionTransaction>>> _loadRecentTransactions(String userId) async {
    final result = await _redemptionRepository.getRedemptionHistory(
      userId: userId,
      page: 1,
      limit: 5, // Just get recent transactions
    );
    
    return result.fold(
      (failure) => Either.left(failure),
      (paginatedResult) => Either.right(paginatedResult.items),
    );
  }

  /// Generate unique transaction ID
  String _generateTransactionId() {
    return 'txn_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// Build confirmation message for redemption
  String _buildConfirmationMessage(RedemptionOption option, int quantity, int totalCost) {
    final plural = quantity > 1 ? 's' : '';
    return 'Redeem $quantity ${option.title}$plural for $totalCost points?';
  }

  /// Build success message for completed redemption
  String _buildSuccessMessage(RedemptionOption option, int quantity) {
    final plural = quantity > 1 ? 's' : '';
    return 'Successfully redeemed $quantity ${option.title}$plural!';
  }

  /// Get status message for redemption status
  String _getStatusMessage(RedemptionStatus status) {
    switch (status) {
      case RedemptionStatus.pending:
        return 'Redemption request received...';
      case RedemptionStatus.processing:
        return 'Processing your redemption...';
      case RedemptionStatus.completed:
        return 'Redemption completed successfully!';
      case RedemptionStatus.failed:
        return 'Redemption failed. Please try again.';
      case RedemptionStatus.cancelled:
        return 'Redemption was cancelled.';
    }
  }

  /// Get progress value for redemption status
  double? _getStatusProgress(RedemptionStatus status) {
    switch (status) {
      case RedemptionStatus.pending:
        return 0.2;
      case RedemptionStatus.processing:
        return 0.6;
      case RedemptionStatus.completed:
        return 1.0;
      case RedemptionStatus.failed:
      case RedemptionStatus.cancelled:
        return null;
    }
  }

  /// Start automatic refresh timer
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_autoRefreshInterval, (_) {
      if (_currentUserId != null) {
        add(RedemptionPointBalanceChecked(userId: _currentUserId!));
      }
    });
  }

  /// Stop all active subscriptions and timers
  void _stopAllSubscriptions() {
    _balanceSubscription?.cancel();
    _statusSubscription?.cancel();
    _searchSubscription?.cancel();
    _refreshTimer?.cancel();
    _searchSubject.close();
  }

  /// Map failure to appropriate error type
  RedemptionErrorType _mapFailureToErrorType(Failure failure) {
    if (failure is NetworkFailure) {
      return RedemptionErrorType.network;
    } else if (failure is ValidationFailure) {
      if (failure.message.contains('insufficient')) {
        return RedemptionErrorType.insufficientPoints;
      } else if (failure.message.contains('unavailable')) {
        return RedemptionErrorType.optionUnavailable;
      } else if (failure.message.contains('expired')) {
        return RedemptionErrorType.optionExpired;
      } else {
        return RedemptionErrorType.validation;
      }
    } else if (failure is AuthFailure) {
      return RedemptionErrorType.permission;
    } else if (failure is TimeoutFailure) {
      return RedemptionErrorType.timeout;
    } else if (failure is ServerFailure) {
      return RedemptionErrorType.server;
    } else {
      return RedemptionErrorType.generic;
    }
  }

  @override
  Future<void> close() {
    _stopAllSubscriptions();
    return super.close();
  }
}