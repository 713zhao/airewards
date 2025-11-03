import 'package:equatable/equatable.dart';
import '../../../domain/entities/entities.dart';

/// Base state class for redemption operations
/// 
/// This abstract class defines the possible states for redemption
/// operations including points redemption and transaction management.
abstract class RedemptionState extends Equatable {
  const RedemptionState();
}

/// Initial state when no redemption operations have been initiated
class RedemptionInitial extends RedemptionState {
  const RedemptionInitial();

  @override
  List<Object> get props => [];
}

/// State when redemption validation is in progress
/// 
/// This state shows when the system is validating a redemption
/// request before processing it.
class RedemptionValidating extends RedemptionState {
  final String optionId;
  final int quantity;

  const RedemptionValidating({
    required this.optionId,
    required this.quantity,
  });

  @override
  List<Object> get props => [optionId, quantity];
}

/// State when redemption validation is successful
/// 
/// This state confirms that the redemption request is valid
/// and can proceed to processing.
class RedemptionValidationSuccess extends RedemptionState {
  final String optionId;
  final int quantity;
  final int requiredPoints;
  final int userBalance;
  final double estimatedValue;

  const RedemptionValidationSuccess({
    required this.optionId,
    required this.quantity,
    required this.requiredPoints,
    required this.userBalance,
    required this.estimatedValue,
  });

  @override
  List<Object> get props => [
    optionId,
    quantity,
    requiredPoints,
    userBalance,
    estimatedValue,
  ];

  /// Whether the user has sufficient points for this redemption
  bool get hasSufficientPoints => userBalance >= requiredPoints;

  /// Points remaining after this redemption
  int get pointsAfterRedemption => userBalance - requiredPoints;
}

/// State when redemption validation fails
/// 
/// This state indicates that the redemption request cannot
/// be processed due to validation errors.
class RedemptionValidationFailure extends RedemptionState {
  final String message;
  final String optionId;
  final int quantity;

  const RedemptionValidationFailure({
    required this.message,
    required this.optionId,
    required this.quantity,
  });

  @override
  List<Object> get props => [message, optionId, quantity];
}

/// State when redemption is being processed
/// 
/// This state shows that the redemption request is being
/// processed by the system.
class RedemptionProcessing extends RedemptionState {
  final String optionId;
  final int quantity;
  final int requiredPoints;

  const RedemptionProcessing({
    required this.optionId,
    required this.quantity,
    required this.requiredPoints,
  });

  @override
  List<Object> get props => [optionId, quantity, requiredPoints];
}

/// State when redemption is successful
/// 
/// This state indicates that the redemption has been successfully
/// processed and contains the transaction details.
class RedemptionSuccess extends RedemptionState {
  final RedemptionTransaction transaction;
  final int newPointsBalance;

  const RedemptionSuccess({
    required this.transaction,
    required this.newPointsBalance,
  });

  @override
  List<Object> get props => [transaction, newPointsBalance];
}

/// State when redemption fails
/// 
/// This state indicates that the redemption processing failed
/// and contains error information.
class RedemptionFailure extends RedemptionState {
  final String message;
  final String? errorCode;
  final bool canRetry;

  const RedemptionFailure({
    required this.message,
    this.errorCode,
    this.canRetry = true,
  });

  @override
  List<Object?> get props => [message, errorCode, canRetry];
}

/// State when loading redemption history
/// 
/// This state shows that the system is loading the user's
/// redemption transaction history.
class RedemptionHistoryLoading extends RedemptionState {
  final bool isRefreshing;

  const RedemptionHistoryLoading({this.isRefreshing = false});

  @override
  List<Object> get props => [isRefreshing];
}

/// State when redemption history is loaded
/// 
/// This state contains the loaded redemption history with
/// optional filtering applied.
class RedemptionHistoryLoaded extends RedemptionState {
  final List<RedemptionTransaction> transactions;
  final DateTime? startDateFilter;
  final DateTime? endDateFilter;
  final RedemptionStatus? statusFilter;
  final String? searchQuery;
  final bool isRefreshing;

  const RedemptionHistoryLoaded({
    required this.transactions,
    this.startDateFilter,
    this.endDateFilter,
    this.statusFilter,
    this.searchQuery,
    this.isRefreshing = false,
  });

  @override
  List<Object?> get props => [
    transactions,
    startDateFilter,
    endDateFilter,
    statusFilter,
    searchQuery,
    isRefreshing,
  ];

  /// Creates a copy with updated fields
  RedemptionHistoryLoaded copyWith({
    List<RedemptionTransaction>? transactions,
    DateTime? startDateFilter,
    DateTime? endDateFilter,
    RedemptionStatus? statusFilter,
    String? searchQuery,
    bool? isRefreshing,
  }) {
    return RedemptionHistoryLoaded(
      transactions: transactions ?? this.transactions,
      startDateFilter: startDateFilter ?? this.startDateFilter,
      endDateFilter: endDateFilter ?? this.endDateFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  /// Gets filtered transactions based on current filter criteria
  List<RedemptionTransaction> get filteredTransactions {
    var filtered = transactions.where((transaction) {
      // Apply date range filter
      if (startDateFilter != null && transaction.createdAt.isBefore(startDateFilter!)) {
        return false;
      }

      if (endDateFilter != null && transaction.createdAt.isAfter(endDateFilter!)) {
        return false;
      }

      // Apply status filter
      if (statusFilter != null && transaction.status != statusFilter) {
        return false;
      }

      // Apply search query filter
      if (searchQuery != null && searchQuery!.isNotEmpty) {
        final query = searchQuery!.toLowerCase();
        final optionIdMatch = transaction.optionId.toLowerCase().contains(query);
        final idMatch = transaction.id.toLowerCase().contains(query);
        final notesMatch = transaction.notes?.toLowerCase().contains(query) ?? false;
        
        if (!optionIdMatch && !idMatch && !notesMatch) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort by date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return filtered;
  }

  /// Whether any filters are currently active
  bool get hasActiveFilters {
    return startDateFilter != null ||
        endDateFilter != null ||
        statusFilter != null ||
        (searchQuery != null && searchQuery!.isNotEmpty);
  }

  /// Number of transactions before filtering
  int get totalTransactionCount => transactions.length;

  /// Number of transactions after filtering
  int get filteredTransactionCount => filteredTransactions.length;

  /// Total points redeemed across all transactions
  int get totalPointsRedeemed {
    return transactions.fold(0, (sum, transaction) => sum + transaction.pointsUsed);
  }

  /// Total points redeemed in filtered transactions
  int get filteredPointsRedeemed {
    return filteredTransactions.fold(0, (sum, transaction) => sum + transaction.pointsUsed);
  }

  /// Gets transactions grouped by status
  Map<RedemptionStatus, List<RedemptionTransaction>> get transactionsByStatus {
    final Map<RedemptionStatus, List<RedemptionTransaction>> grouped = {};
    
    for (final transaction in filteredTransactions) {
      grouped.putIfAbsent(transaction.status, () => []).add(transaction);
    }
    
    return grouped;
  }

  /// Gets transactions grouped by month
  Map<String, List<RedemptionTransaction>> get transactionsByMonth {
    final Map<String, List<RedemptionTransaction>> grouped = {};
    
    for (final transaction in filteredTransactions) {
      final monthKey = '${transaction.createdAt.year}-${transaction.createdAt.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(monthKey, () => []).add(transaction);
    }
    
    return grouped;
  }
}

/// State when redemption history is empty
/// 
/// This state indicates that there are no redemption transactions
/// to display, either due to no history or all being filtered out.
class RedemptionHistoryEmpty extends RedemptionState {
  final String message;
  final bool hasFilters;

  const RedemptionHistoryEmpty({
    required this.message,
    this.hasFilters = false,
  });

  @override
  List<Object> get props => [message, hasFilters];
}

/// State when loading redemption history fails
/// 
/// This state indicates that loading the redemption history
/// encountered an error.
class RedemptionHistoryError extends RedemptionState {
  final String message;
  final bool canRetry;

  const RedemptionHistoryError({
    required this.message,
    this.canRetry = true,
  });

  @override
  List<Object> get props => [message, canRetry];
}

/// State when transaction details are loading
/// 
/// This state shows that detailed information for a specific
/// transaction is being loaded.
class RedemptionTransactionDetailsLoading extends RedemptionState {
  final String transactionId;

  const RedemptionTransactionDetailsLoading({
    required this.transactionId,
  });

  @override
  List<Object> get props => [transactionId];
}

/// State when transaction details are loaded
/// 
/// This state contains detailed information about a specific
/// redemption transaction including tracking and status history.
class RedemptionTransactionDetailsLoaded extends RedemptionState {
  final RedemptionTransaction transaction;
  final List<RedemptionStatusUpdate> statusHistory;

  const RedemptionTransactionDetailsLoaded({
    required this.transaction,
    required this.statusHistory,
  });

  @override
  List<Object> get props => [transaction, statusHistory];

  /// Whether this transaction can be cancelled
  bool get canBeCancelled {
    return transaction.status == RedemptionStatus.pending;
  }

  /// Whether this transaction can be retried
  bool get canBeRetried {
    return transaction.status == RedemptionStatus.expired;
  }

  /// Latest status update
  RedemptionStatusUpdate? get latestStatusUpdate {
    if (statusHistory.isEmpty) return null;
    return statusHistory.last;
  }
}

/// State when loading transaction details fails
/// 
/// This state indicates that loading detailed transaction
/// information encountered an error.
class RedemptionTransactionDetailsError extends RedemptionState {
  final String message;
  final String transactionId;

  const RedemptionTransactionDetailsError({
    required this.message,
    required this.transactionId,
  });

  @override
  List<Object> get props => [message, transactionId];
}

/// State when loading redemption statistics
/// 
/// This state shows that the system is loading redemption
/// analytics and statistics data.
class RedemptionStatsLoading extends RedemptionState {
  const RedemptionStatsLoading();

  @override
  List<Object> get props => [];
}

/// State when redemption statistics are loaded
/// 
/// This state contains loaded redemption statistics and analytics
/// data for display in dashboards or reports.
class RedemptionStatsLoaded extends RedemptionState {
  final RedemptionStats stats;
  final DateTime? startDate;
  final DateTime? endDate;

  const RedemptionStatsLoaded({
    required this.stats,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [stats, startDate, endDate];

  /// Creates a copy with updated fields
  RedemptionStatsLoaded copyWith({
    RedemptionStats? stats,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return RedemptionStatsLoaded(
      stats: stats ?? this.stats,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

/// State when loading redemption statistics fails
/// 
/// This state indicates that loading redemption statistics
/// encountered an error.
class RedemptionStatsError extends RedemptionState {
  final String message;
  final bool canRetry;

  const RedemptionStatsError({
    required this.message,
    this.canRetry = true,
  });

  @override
  List<Object> get props => [message, canRetry];
}

/// State when loading available points
/// 
/// This state shows that the system is loading the user's
/// current available points information.
class AvailablePointsLoading extends RedemptionState {
  const AvailablePointsLoading();

  @override
  List<Object> get props => [];
}

/// State when available points are loaded
/// 
/// This state contains the user's current available points
/// and related balance information.
class AvailablePointsLoaded extends RedemptionState {
  final int availablePoints;
  final DateTime lastUpdated;

  const AvailablePointsLoaded({
    required this.availablePoints,
    required this.lastUpdated,
  });

  @override
  List<Object> get props => [availablePoints, lastUpdated];

  /// Creates a copy with updated fields
  AvailablePointsLoaded copyWith({
    int? availablePoints,
    DateTime? lastUpdated,
  }) {
    return AvailablePointsLoaded(
      availablePoints: availablePoints ?? this.availablePoints,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// State when loading available points fails
/// 
/// This state indicates that loading the available points
/// information encountered an error.
class AvailablePointsError extends RedemptionState {
  final String message;
  final bool canRetry;

  const AvailablePointsError({
    required this.message,
    this.canRetry = true,
  });

  @override
  List<Object> get props => [message, canRetry];
}

/// Helper class for redemption status updates
class RedemptionStatusUpdate extends Equatable {
  final RedemptionStatus status;
  final DateTime timestamp;
  final String? note;

  const RedemptionStatusUpdate({
    required this.status,
    required this.timestamp,
    this.note,
  });

  @override
  List<Object?> get props => [status, timestamp, note];

  @override
  String toString() => 'RedemptionStatusUpdate(status: $status, timestamp: $timestamp, note: $note)';
}