import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/usecases/usecases.dart';
import 'redemption_event.dart';
import 'redemption_state.dart';

/// BLoC for managing redemption operations and transaction history
/// 
/// This BLoC handles:
/// - Points redemption processes
/// - Transaction validation
/// - Redemption history management
/// - Transaction status updates
/// - Error handling and retry logic
class RedemptionBloc extends Bloc<RedemptionEvent, RedemptionState> {
  final RedeemPoints redeemPointsUseCase;
  final GetRedemptionHistory getRedemptionHistoryUseCase;
  final ValidateRedemption validateRedemptionUseCase;
  final GetAvailablePoints getAvailablePointsUseCase;
  final GetRedemptionStats getRedemptionStatsUseCase;
  final CancelRedemption cancelRedemptionUseCase;

  RedemptionBloc({
    required this.redeemPointsUseCase,
    required this.getRedemptionHistoryUseCase,
    required this.validateRedemptionUseCase,
    required this.getAvailablePointsUseCase,
    required this.getRedemptionStatsUseCase,
    required this.cancelRedemptionUseCase,
  }) : super(const RedemptionInitial()) {
    on<RedemptionValidationRequested>(_onValidationRequested);
    on<RedeemPointsRequested>(_onRedeemPointsRequested);
    on<RedemptionHistoryRequested>(_onRedemptionHistoryRequested);
    on<RedemptionHistoryRefreshed>(_onRedemptionHistoryRefreshed);
    on<RedemptionHistoryFiltered>(_onRedemptionHistoryFiltered);
    on<RedemptionHistoryFiltersCleared>(_onRedemptionHistoryFiltersCleared);
    on<RedemptionCancellationRequested>(_onRedemptionCancellationRequested);
    on<RedemptionRetryRequested>(_onRedemptionRetryRequested);
    on<RedemptionTransactionDetailsRequested>(_onRedemptionTransactionDetailsRequested);
    on<RedemptionNotificationRead>(_onRedemptionNotificationRead);
    on<RedemptionStateReset>(_onRedemptionStateReset);
    on<RedemptionStatsRequested>(_onRedemptionStatsRequested);
    on<AvailablePointsRequested>(_onAvailablePointsRequested);
  }

  /// Handles redemption validation requests
  /// 
  /// This method validates if a redemption request can be processed
  /// before actually attempting the redemption using the ValidateRedemption use case.
  Future<void> _onValidationRequested(
    RedemptionValidationRequested event,
    Emitter<RedemptionState> emit,
  ) async {
    emit(RedemptionValidating(
      optionId: event.optionId,
      quantity: event.quantity,
    ));

    try {
      // First, get available points to calculate required points and validate
      final availablePointsParams = GetAvailablePointsParams.create(
        userId: 'current_user', // In real app, get from auth service
      );

      if (availablePointsParams.isLeft) {
        emit(RedemptionValidationFailure(
          message: availablePointsParams.left.message,
          optionId: event.optionId,
          quantity: event.quantity,
        ));
        return;
      }

      final pointsResult = await getAvailablePointsUseCase(availablePointsParams.right);
      
      await pointsResult.fold(
        (failure) async {
          emit(RedemptionValidationFailure(
            message: failure.message,
            optionId: event.optionId,
            quantity: event.quantity,
          ));
        },
        (userBalance) async {
          // Calculate required points (mock calculation - in real app, get from option data)
          final requiredPoints = 1000 * event.quantity; // Mock: 1000 points per item
          
          // Create validation parameters
          final params = ValidateRedemptionParams.create(
            userId: 'current_user',
            pointsToRedeem: requiredPoints,
            optionId: event.optionId,
          );

          if (params.isLeft) {
            emit(RedemptionValidationFailure(
              message: params.left.message,
              optionId: event.optionId,
              quantity: event.quantity,
            ));
            return;
          }

          // Execute validation using the use case
          final validationResult = await validateRedemptionUseCase(params.right);

          validationResult.fold(
            (failure) {
              emit(RedemptionValidationFailure(
                message: failure.message,
                optionId: event.optionId,
                quantity: event.quantity,
              ));
            },
            (canRedeem) {
              if (canRedeem) {
                emit(RedemptionValidationSuccess(
                  optionId: event.optionId,
                  quantity: event.quantity,
                  requiredPoints: requiredPoints,
                  userBalance: userBalance,
                  estimatedValue: requiredPoints * 0.01,
                ));
              } else {
                emit(RedemptionValidationFailure(
                  message: 'Insufficient points. Required: $requiredPoints, Available: $userBalance',
                  optionId: event.optionId,
                  quantity: event.quantity,
                ));
              }
            },
          );
        },
      );
    } catch (e) {
      emit(RedemptionValidationFailure(
        message: 'Validation failed: ${e.toString()}',
        optionId: event.optionId,
        quantity: event.quantity,
      ));
    }
  }

  /// Handles points redemption requests
  /// 
  /// This method processes the actual redemption after validation.
  Future<void> _onRedeemPointsRequested(
    RedeemPointsRequested event,
    Emitter<RedemptionState> emit,
  ) async {
    // Only process if we're in a valid state
    if (state is! RedemptionValidationSuccess) {
      emit(const RedemptionFailure(
        message: 'Please validate the redemption before proceeding',
        canRetry: false,
      ));
      return;
    }

    final validationState = state as RedemptionValidationSuccess;
    
    emit(RedemptionProcessing(
      optionId: event.optionId,
      quantity: event.quantity,
      requiredPoints: validationState.requiredPoints,
    ));

    try {
      // Create redemption parameters
      final params = RedeemPointsParams.create(
        userId: 'current_user', // In real app, get from auth service
        optionId: event.optionId,
        pointsToRedeem: validationState.requiredPoints,
        notes: event.note,
      );

      if (params.isLeft) {
        emit(RedemptionFailure(
          message: params.left.message,
          canRetry: true,
        ));
        return;
      }

      // Execute redemption
      final result = await redeemPointsUseCase(params.right);

      result.fold(
        (failure) {
          emit(RedemptionFailure(
            message: failure.message,
            errorCode: failure.runtimeType.toString(),
            canRetry: true,
          ));
        },
        (transaction) {
          emit(RedemptionSuccess(
            transaction: transaction,
            newPointsBalance: validationState.userBalance - validationState.requiredPoints,
          ));
        },
      );
    } catch (e) {
      emit(RedemptionFailure(
        message: 'Unexpected error during redemption: ${e.toString()}',
        canRetry: true,
      ));
    }
  }

  /// Handles redemption history requests
  /// 
  /// This method loads the user's redemption transaction history.
  Future<void> _onRedemptionHistoryRequested(
    RedemptionHistoryRequested event,
    Emitter<RedemptionState> emit,
  ) async {
    emit(RedemptionHistoryLoading(isRefreshing: event.forceRefresh));

    try {
      // Create history parameters
      final params = GetRedemptionHistoryParams.create(
        userId: 'current_user', // In real app, get from auth service
        startDate: event.startDate,
        endDate: event.endDate,
        status: event.statusFilter,
      );

      if (params.isLeft) {
        emit(RedemptionHistoryError(
          message: params.left.message,
          canRetry: true,
        ));
        return;
      }

      final result = await getRedemptionHistoryUseCase(params.right);

      result.fold(
        (failure) {
          emit(RedemptionHistoryError(
            message: failure.message,
            canRetry: true,
          ));
        },
        (paginatedResult) {
          final transactions = paginatedResult.items.map((item) => item.transaction).toList();
          
          if (transactions.isEmpty) {
            emit(const RedemptionHistoryEmpty(
              message: 'No redemption history found',
              hasFilters: false,
            ));
          } else {
            emit(RedemptionHistoryLoaded(
              transactions: transactions,
              startDateFilter: event.startDate,
              endDateFilter: event.endDate,
              statusFilter: event.statusFilter,
              isRefreshing: false,
            ));
          }
        },
      );
    } catch (e) {
      emit(RedemptionHistoryError(
        message: 'Unexpected error loading history: ${e.toString()}',
        canRetry: true,
      ));
    }
  }

  /// Handles redemption history refresh requests
  /// 
  /// This method forces a refresh of the redemption history.
  Future<void> _onRedemptionHistoryRefreshed(
    RedemptionHistoryRefreshed event,
    Emitter<RedemptionState> emit,
  ) async {
    // Get current filters if in loaded state
    DateTime? startDate;
    DateTime? endDate;
    RedemptionStatus? statusFilter;

    if (state is RedemptionHistoryLoaded) {
      final currentState = state as RedemptionHistoryLoaded;
      startDate = currentState.startDateFilter;
      endDate = currentState.endDateFilter;
      statusFilter = currentState.statusFilter;
    }

    // Trigger a refresh with current filters
    add(RedemptionHistoryRequested(
      startDate: startDate,
      endDate: endDate,
      statusFilter: statusFilter,
      forceRefresh: true,
    ));
  }

  /// Handles redemption history filtering
  /// 
  /// This method applies filters to the loaded redemption history.
  Future<void> _onRedemptionHistoryFiltered(
    RedemptionHistoryFiltered event,
    Emitter<RedemptionState> emit,
  ) async {
    final currentState = state;
    
    if (currentState is RedemptionHistoryLoaded) {
      final updatedState = currentState.copyWith(
        startDateFilter: event.startDate,
        endDateFilter: event.endDate,
        statusFilter: event.statusFilter,
        searchQuery: event.searchQuery,
      );

      if (updatedState.filteredTransactions.isEmpty && updatedState.hasActiveFilters) {
        emit(const RedemptionHistoryEmpty(
          message: 'No transactions match the selected filters',
          hasFilters: true,
        ));
      } else {
        emit(updatedState);
      }
    } else {
      // If not in loaded state, trigger a new load with filters
      add(RedemptionHistoryRequested(
        startDate: event.startDate,
        endDate: event.endDate,
        statusFilter: event.statusFilter,
      ));
    }
  }

  /// Handles clearing redemption history filters
  /// 
  /// This method removes all applied filters from the history view.
  Future<void> _onRedemptionHistoryFiltersCleared(
    RedemptionHistoryFiltersCleared event,
    Emitter<RedemptionState> emit,
  ) async {
    final currentState = state;
    
    if (currentState is RedemptionHistoryLoaded) {
      emit(currentState.copyWith(
        startDateFilter: null,
        endDateFilter: null,
        statusFilter: null,
        searchQuery: null,
      ));
    }
  }

  /// Handles redemption cancellation requests
  /// 
  /// This method cancels a pending redemption transaction using the CancelRedemption use case.
  Future<void> _onRedemptionCancellationRequested(
    RedemptionCancellationRequested event,
    Emitter<RedemptionState> emit,
  ) async {
    try {
      // Create cancellation parameters
      final params = CancelRedemptionParams.create(
        userId: 'current_user', // In real app, get from auth service
        transactionId: event.transactionId,
        reason: event.cancellationReason ?? 'User requested cancellation',
      );

      if (params.isLeft) {
        emit(RedemptionFailure(
          message: params.left.message,
          canRetry: true,
        ));
        return;
      }

      // Execute cancellation using the use case
      final result = await cancelRedemptionUseCase(params.right);

      result.fold(
        (failure) {
          emit(RedemptionFailure(
            message: failure.message,
            canRetry: true,
          ));
        },
        (success) {
          // Update the history if currently loaded
          if (state is RedemptionHistoryLoaded) {
            add(const RedemptionHistoryRefreshed());
          }
          
          // Could emit a specific cancellation success state if needed
          // For now, just refresh the current state
        },
      );
    } catch (e) {
      emit(RedemptionFailure(
        message: 'Failed to cancel redemption: ${e.toString()}',
        canRetry: true,
      ));
    }
  }

  /// Handles redemption retry requests
  /// 
  /// This method retries a failed redemption transaction.
  Future<void> _onRedemptionRetryRequested(
    RedemptionRetryRequested event,
    Emitter<RedemptionState> emit,
  ) async {
    try {
      // In a real implementation, this would:
      // 1. Retrieve the original transaction details
      // 2. Re-validate the redemption parameters
      // 3. Attempt the redemption again
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      // For now, just refresh the history
      if (state is RedemptionHistoryLoaded) {
        add(const RedemptionHistoryRefreshed());
      }
    } catch (e) {
      emit(RedemptionFailure(
        message: 'Failed to retry redemption: ${e.toString()}',
        canRetry: true,
      ));
    }
  }

  /// Handles transaction details requests
  /// 
  /// This method loads detailed information for a specific transaction.
  Future<void> _onRedemptionTransactionDetailsRequested(
    RedemptionTransactionDetailsRequested event,
    Emitter<RedemptionState> emit,
  ) async {
    emit(RedemptionTransactionDetailsLoading(
      transactionId: event.transactionId,
    ));

    try {
      // In a real implementation, this would call a get transaction details use case
      await Future.delayed(const Duration(milliseconds: 500));
      
      // For now, simulate loading transaction details
      // This would be replaced with actual use case call
      emit(RedemptionTransactionDetailsError(
        message: 'Transaction details not implemented yet',
        transactionId: event.transactionId,
      ));
    } catch (e) {
      emit(RedemptionTransactionDetailsError(
        message: 'Failed to load transaction details: ${e.toString()}',
        transactionId: event.transactionId,
      ));
    }
  }

  /// Handles marking notifications as read
  /// 
  /// This method marks redemption notifications as read.
  Future<void> _onRedemptionNotificationRead(
    RedemptionNotificationRead event,
    Emitter<RedemptionState> emit,
  ) async {
    // In a real implementation, this would update notification status
    // For now, this is a no-op as we don't have notification management yet
  }

  /// Handles state reset requests
  /// 
  /// This method resets the redemption state to initial.
  Future<void> _onRedemptionStateReset(
    RedemptionStateReset event,
    Emitter<RedemptionState> emit,
  ) async {
    emit(const RedemptionInitial());
  }

  /// Gets the current redemption status if available
  RedemptionStatus? get currentRedemptionStatus {
    final currentState = state;
    if (currentState is RedemptionSuccess) {
      return currentState.transaction.status;
    }
    return null;
  }

  /// Gets the current transaction if available
  RedemptionTransaction? get currentTransaction {
    final currentState = state;
    if (currentState is RedemptionSuccess) {
      return currentState.transaction;
    }
    if (currentState is RedemptionTransactionDetailsLoaded) {
      return currentState.transaction;
    }
    return null;
  }

  /// Gets the current transaction list if available
  List<RedemptionTransaction> get currentTransactions {
    final currentState = state;
    if (currentState is RedemptionHistoryLoaded) {
      return currentState.filteredTransactions;
    }
    return [];
  }

  /// Checks if currently in a loading state
  bool get isLoading {
    return state is RedemptionValidating ||
           state is RedemptionProcessing ||
           state is RedemptionHistoryLoading ||
           state is RedemptionTransactionDetailsLoading;
  }

  /// Checks if there are any active filters on history
  bool get hasActiveHistoryFilters {
    final currentState = state;
    if (currentState is RedemptionHistoryLoaded) {
      return currentState.hasActiveFilters;
    }
    return false;
  }

  /// Gets the total number of transactions
  int get totalTransactionCount {
    final currentState = state;
    if (currentState is RedemptionHistoryLoaded) {
      return currentState.totalTransactionCount;
    }
    return 0;
  }

  /// Gets the filtered transaction count
  int get filteredTransactionCount {
    final currentState = state;
    if (currentState is RedemptionHistoryLoaded) {
      return currentState.filteredTransactionCount;
    }
    return 0;
  }

  /// Handles redemption statistics requests
  /// 
  /// This method loads redemption analytics and statistics data.
  Future<void> _onRedemptionStatsRequested(
    RedemptionStatsRequested event,
    Emitter<RedemptionState> emit,
  ) async {
    if (state is! RedemptionStatsLoaded || event.forceRefresh) {
      emit(const RedemptionStatsLoading());
    }

    try {
      // Create stats parameters
      final params = GetRedemptionStatsParams.create(
        userId: 'current_user', // In real app, get from auth service
        startDate: event.startDate,
        endDate: event.endDate,
      );

      if (params.isLeft) {
        emit(RedemptionStatsError(
          message: params.left.message,
          canRetry: true,
        ));
        return;
      }

      // Execute stats retrieval using the use case
      final result = await getRedemptionStatsUseCase(params.right);

      result.fold(
        (failure) {
          emit(RedemptionStatsError(
            message: failure.message,
            canRetry: true,
          ));
        },
        (stats) {
          emit(RedemptionStatsLoaded(
            stats: stats,
            startDate: event.startDate,
            endDate: event.endDate,
          ));
        },
      );
    } catch (e) {
      emit(RedemptionStatsError(
        message: 'Failed to load redemption statistics: ${e.toString()}',
        canRetry: true,
      ));
    }
  }

  /// Handles available points requests
  /// 
  /// This method loads the user's current available points information.
  Future<void> _onAvailablePointsRequested(
    AvailablePointsRequested event,
    Emitter<RedemptionState> emit,
  ) async {
    if (state is! AvailablePointsLoaded || event.forceRefresh) {
      emit(const AvailablePointsLoading());
    }

    try {
      // Create available points parameters
      final params = GetAvailablePointsParams.create(
        userId: 'current_user', // In real app, get from auth service
      );

      if (params.isLeft) {
        emit(AvailablePointsError(
          message: params.left.message,
          canRetry: true,
        ));
        return;
      }

      // Execute points retrieval using the use case
      final result = await getAvailablePointsUseCase(params.right);

      result.fold(
        (failure) {
          emit(AvailablePointsError(
            message: failure.message,
            canRetry: true,
          ));
        },
        (availablePoints) {
          emit(AvailablePointsLoaded(
            availablePoints: availablePoints,
            lastUpdated: DateTime.now(),
          ));
        },
      );
    } catch (e) {
      emit(AvailablePointsError(
        message: 'Failed to load available points: ${e.toString()}',
        canRetry: true,
      ));
    }
  }
}