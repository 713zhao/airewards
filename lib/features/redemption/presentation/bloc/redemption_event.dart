import 'package:equatable/equatable.dart';

import '../../domain/entities/entities.dart';

/// Base class for all redemption-related events.
/// 
/// All redemption events extend this class to provide type safety and
/// consistent structure for the redemption BLoC event system.
abstract class RedemptionEvent extends Equatable {
  const RedemptionEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load available redemption options.
/// 
/// This event triggers the loading of all available redemption options
/// that the user can redeem their points for, including filtering
/// and pagination support.
class RedemptionOptionsLoaded extends RedemptionEvent {
  final String userId;
  final int page;
  final int limit;
  final RedemptionCategory? category;
  final int? minPoints;
  final int? maxPoints;
  final bool forceRefresh;

  const RedemptionOptionsLoaded({
    required this.userId,
    this.page = 1,
    this.limit = 20,
    this.category,
    this.minPoints,
    this.maxPoints,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [
    userId,
    page, 
    limit,
    category,
    minPoints,
    maxPoints,
    forceRefresh,
  ];
}

/// Event to load more redemption options for pagination.
class RedemptionOptionsLoadMore extends RedemptionEvent {
  final String userId;
  final RedemptionCategory? category;
  final int? minPoints;
  final int? maxPoints;

  const RedemptionOptionsLoadMore({
    required this.userId,
    this.category,
    this.minPoints,
    this.maxPoints,
  });

  @override
  List<Object?> get props => [userId, category, minPoints, maxPoints];
}

/// Event to initiate a redemption process.
/// 
/// This event starts the redemption flow, including point validation,
/// availability checks, and confirmation dialog display.
class RedemptionRequested extends RedemptionEvent {
  final String userId;
  final String optionId;
  final int quantity;
  final bool skipConfirmation;

  const RedemptionRequested({
    required this.userId,
    required this.optionId,
    required this.quantity,
    this.skipConfirmation = false,
  });

  @override
  List<Object?> get props => [userId, optionId, quantity, skipConfirmation];
}

/// Event to confirm a pending redemption after validation.
/// 
/// This event is triggered when the user confirms the redemption
/// in the confirmation dialog, proceeding with the actual transaction.
class RedemptionConfirmed extends RedemptionEvent {
  final String userId;
  final String optionId;
  final int quantity;
  final int totalPointsCost;

  const RedemptionConfirmed({
    required this.userId,
    required this.optionId,
    required this.quantity,
    required this.totalPointsCost,
  });

  @override
  List<Object?> get props => [userId, optionId, quantity, totalPointsCost];
}

/// Event to cancel a pending redemption.
/// 
/// This event cancels the current redemption process and returns
/// to the normal redemption options view.
class RedemptionCancelled extends RedemptionEvent {
  const RedemptionCancelled();
}

/// Event to load user's redemption history.
/// 
/// This event retrieves the user's past redemption transactions
/// with filtering and pagination support.
class RedemptionHistoryLoaded extends RedemptionEvent {
  final String userId;
  final int page;
  final int limit;
  final DateTime? startDate;
  final DateTime? endDate;
  final RedemptionStatus? status;
  final bool forceRefresh;

  const RedemptionHistoryLoaded({
    required this.userId,
    this.page = 1,
    this.limit = 20,
    this.startDate,
    this.endDate,
    this.status,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [
    userId,
    page,
    limit,
    startDate,
    endDate,
    status,
    forceRefresh,
  ];
}

/// Event to load more redemption history entries for pagination.
class RedemptionHistoryLoadMore extends RedemptionEvent {
  final String userId;
  final DateTime? startDate;
  final DateTime? endDate;
  final RedemptionStatus? status;

  const RedemptionHistoryLoadMore({
    required this.userId,
    this.startDate,
    this.endDate,
    this.status,
  });

  @override
  List<Object?> get props => [userId, startDate, endDate, status];
}

/// Event to check user's current point balance.
/// 
/// This event validates that the user has sufficient points
/// for a potential redemption and updates the balance display.
class RedemptionPointBalanceChecked extends RedemptionEvent {
  final String userId;
  final bool forceRefresh;

  const RedemptionPointBalanceChecked({
    required this.userId,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [userId, forceRefresh];
}

/// Event to validate redemption eligibility.
/// 
/// This event performs comprehensive validation for a redemption
/// request, including point balance, availability, and user eligibility.
class RedemptionEligibilityChecked extends RedemptionEvent {
  final String userId;
  final String optionId;
  final int quantity;

  const RedemptionEligibilityChecked({
    required this.userId,
    required this.optionId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [userId, optionId, quantity];
}

/// Event to filter redemption options by category.
/// 
/// This event applies category filtering to the redemption options
/// and refreshes the display with filtered results.
class RedemptionCategoryFilterApplied extends RedemptionEvent {
  final String userId;
  final RedemptionCategory? category;

  const RedemptionCategoryFilterApplied({
    required this.userId,
    this.category,
  });

  @override
  List<Object?> get props => [userId, category];
}

/// Event to filter redemption options by point range.
/// 
/// This event applies point range filtering to show only
/// redemption options within the specified point costs.
class RedemptionPointRangeFilterApplied extends RedemptionEvent {
  final String userId;
  final int? minPoints;
  final int? maxPoints;

  const RedemptionPointRangeFilterApplied({
    required this.userId,
    this.minPoints,
    this.maxPoints,
  });

  @override
  List<Object?> get props => [userId, minPoints, maxPoints];
}

/// Event to search redemption options.
/// 
/// This event performs a search across redemption option names
/// and descriptions with debouncing support.
class RedemptionOptionsSearched extends RedemptionEvent {
  final String userId;
  final String query;

  const RedemptionOptionsSearched({
    required this.userId,
    required this.query,
  });

  @override
  List<Object?> get props => [userId, query];
}

/// Event to clear search and filters.
/// 
/// This event resets all active search and filter criteria
/// and reloads the complete redemption options list.
class RedemptionSearchCleared extends RedemptionEvent {
  final String userId;

  const RedemptionSearchCleared({
    required this.userId,
  });

  @override
  List<Object?> get props => [userId];
}

/// Event to refresh redemption data.
/// 
/// This event forces a refresh of all redemption-related data
/// including options, user balance, and history.
class RedemptionDataRefreshed extends RedemptionEvent {
  final String userId;

  const RedemptionDataRefreshed({
    required this.userId,
  });

  @override
  List<Object?> get props => [userId];
}

/// Event to retry failed redemption operations.
/// 
/// This event retries the last failed redemption operation
/// based on the error state information.
class RedemptionOperationRetried extends RedemptionEvent {
  const RedemptionOperationRetried();
}

/// Event to clear error states.
/// 
/// This event clears the current error state and returns
/// to the appropriate previous state.
class RedemptionErrorCleared extends RedemptionEvent {
  const RedemptionErrorCleared();
}

/// Event to reset the redemption BLoC state.
/// 
/// This event completely resets the BLoC to its initial state
/// and clears all cached data and subscriptions.
class RedemptionStateReset extends RedemptionEvent {
  const RedemptionStateReset();
}

/// Event to track redemption transaction status.
/// 
/// This event updates the status of an ongoing redemption
/// transaction based on backend notifications.
class RedemptionStatusUpdated extends RedemptionEvent {
  final String transactionId;
  final RedemptionStatus newStatus;
  final String? statusMessage;
  final DateTime timestamp;

  const RedemptionStatusUpdated({
    required this.transactionId,
    required this.newStatus,
    this.statusMessage,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [transactionId, newStatus, statusMessage, timestamp];
}

/// Event to load redemption categories.
/// 
/// This event loads all available redemption categories
/// for filtering and organization purposes.
class RedemptionCategoriesLoaded extends RedemptionEvent {
  final bool forceRefresh;

  const RedemptionCategoriesLoaded({
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [forceRefresh];
}