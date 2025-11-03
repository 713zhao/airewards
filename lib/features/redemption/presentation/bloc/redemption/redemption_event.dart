import 'package:equatable/equatable.dart';
import '../../../domain/entities/entities.dart';

/// Base class for redemption events
/// 
/// This abstract class defines all possible events that can be
/// triggered in the redemption flow, including redeeming points
/// and loading transaction history.
abstract class RedemptionEvent extends Equatable {
  const RedemptionEvent();
}

/// Event to initiate a points redemption
/// 
/// This event starts the redemption process for a specific
/// redemption option with the specified quantity.
class RedeemPointsRequested extends RedemptionEvent {
  final String optionId;
  final int quantity;
  final String? note;

  const RedeemPointsRequested({
    required this.optionId,
    required this.quantity,
    this.note,
  });

  @override
  List<Object?> get props => [optionId, quantity, note];

  @override
  String toString() => 'RedeemPointsRequested(optionId: $optionId, quantity: $quantity, note: $note)';
}

/// Event to load redemption history
/// 
/// This event triggers loading of the user's redemption
/// transaction history with optional filtering.
class RedemptionHistoryRequested extends RedemptionEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final RedemptionStatus? statusFilter;
  final bool forceRefresh;

  const RedemptionHistoryRequested({
    this.startDate,
    this.endDate,
    this.statusFilter,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [startDate, endDate, statusFilter, forceRefresh];

  @override
  String toString() => 'RedemptionHistoryRequested(startDate: $startDate, endDate: $endDate, statusFilter: $statusFilter, forceRefresh: $forceRefresh)';
}

/// Event to refresh redemption history
/// 
/// This event forces a refresh of the redemption history
/// from the remote data source.
class RedemptionHistoryRefreshed extends RedemptionEvent {
  const RedemptionHistoryRefreshed();

  @override
  List<Object> get props => [];
}

/// Event to cancel a pending redemption
/// 
/// This event allows users to cancel redemptions that are
/// still in pending or processing status.
class RedemptionCancellationRequested extends RedemptionEvent {
  final String transactionId;
  final String? cancellationReason;

  const RedemptionCancellationRequested({
    required this.transactionId,
    this.cancellationReason,
  });

  @override
  List<Object?> get props => [transactionId, cancellationReason];

  @override
  String toString() => 'RedemptionCancellationRequested(transactionId: $transactionId, reason: $cancellationReason)';
}

/// Event to retry a failed redemption
/// 
/// This event allows users to retry redemptions that failed
/// due to temporary issues like network connectivity.
class RedemptionRetryRequested extends RedemptionEvent {
  final String transactionId;

  const RedemptionRetryRequested({
    required this.transactionId,
  });

  @override
  List<Object> get props => [transactionId];

  @override
  String toString() => 'RedemptionRetryRequested(transactionId: $transactionId)';
}

/// Event to filter redemption history
/// 
/// This event applies client-side filtering to the loaded
/// redemption history based on various criteria.
class RedemptionHistoryFiltered extends RedemptionEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final RedemptionStatus? statusFilter;
  final String? searchQuery;

  const RedemptionHistoryFiltered({
    this.startDate,
    this.endDate,
    this.statusFilter,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [startDate, endDate, statusFilter, searchQuery];

  @override
  String toString() => 'RedemptionHistoryFiltered(startDate: $startDate, endDate: $endDate, statusFilter: $statusFilter, searchQuery: $searchQuery)';
}

/// Event to clear redemption history filters
/// 
/// This event removes all applied filters and shows
/// the complete redemption history.
class RedemptionHistoryFiltersCleared extends RedemptionEvent {
  const RedemptionHistoryFiltersCleared();

  @override
  List<Object> get props => [];
}

/// Event to load transaction details
/// 
/// This event loads detailed information for a specific
/// redemption transaction, including tracking and status updates.
class RedemptionTransactionDetailsRequested extends RedemptionEvent {
  final String transactionId;

  const RedemptionTransactionDetailsRequested({
    required this.transactionId,
  });

  @override
  List<Object> get props => [transactionId];

  @override
  String toString() => 'RedemptionTransactionDetailsRequested(transactionId: $transactionId)';
}

/// Event to mark a notification as read
/// 
/// This event marks redemption-related notifications as read
/// to update the UI state and notification counters.
class RedemptionNotificationRead extends RedemptionEvent {
  final String transactionId;

  const RedemptionNotificationRead({
    required this.transactionId,
  });

  @override
  List<Object> get props => [transactionId];

  @override
  String toString() => 'RedemptionNotificationRead(transactionId: $transactionId)';
}

/// Event to validate redemption request
/// 
/// This event performs pre-redemption validation to check
/// if the user has sufficient points and the option is available.
class RedemptionValidationRequested extends RedemptionEvent {
  final String optionId;
  final int quantity;

  const RedemptionValidationRequested({
    required this.optionId,
    required this.quantity,
  });

  @override
  List<Object> get props => [optionId, quantity];

  @override
  String toString() => 'RedemptionValidationRequested(optionId: $optionId, quantity: $quantity)';
}

/// Event to reset redemption state
/// 
/// This event resets the redemption state to initial,
/// clearing any error messages or transaction states.
class RedemptionStateReset extends RedemptionEvent {
  const RedemptionStateReset();

  @override
  List<Object> get props => [];
}

/// Event to request redemption statistics
/// 
/// This event loads analytics and statistics about the user's
/// redemption activity for display in dashboards or reports.
class RedemptionStatsRequested extends RedemptionEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final bool forceRefresh;

  const RedemptionStatsRequested({
    this.startDate,
    this.endDate,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [startDate, endDate, forceRefresh];

  @override
  String toString() => 'RedemptionStatsRequested(startDate: $startDate, endDate: $endDate, forceRefresh: $forceRefresh)';
}

/// Event to request available points information
/// 
/// This event loads the user's current available points balance
/// and related information for display and validation.
class AvailablePointsRequested extends RedemptionEvent {
  final bool forceRefresh;

  const AvailablePointsRequested({
    this.forceRefresh = false,
  });

  @override
  List<Object> get props => [forceRefresh];

  @override
  String toString() => 'AvailablePointsRequested(forceRefresh: $forceRefresh)';
}