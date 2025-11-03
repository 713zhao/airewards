import 'package:equatable/equatable.dart';

import '../../../../core/models/paginated_result.dart';
import '../../domain/entities/entities.dart';

/// Base class for all redemption BLoC states.
/// 
/// All redemption states extend this class to provide type safety
/// and consistent structure for the redemption state management.
abstract class RedemptionState extends Equatable {
  const RedemptionState();

  @override
  List<Object?> get props => [];
}

/// Initial state when the redemption BLoC is first created.
/// 
/// This is the default state before any redemption data is loaded
/// or any operations are performed.
class RedemptionInitial extends RedemptionState {
  const RedemptionInitial();
}

/// State indicating that a redemption operation is in progress.
/// 
/// This state shows loading indicators and progress information
/// during various redemption operations.
class RedemptionLoading extends RedemptionState {
  final String message;
  final RedemptionOperationType operationType;
  final bool showProgress;
  final double? progress;

  const RedemptionLoading({
    required this.message,
    this.operationType = RedemptionOperationType.loadOptions,
    this.showProgress = true,
    this.progress,
  });

  @override
  List<Object?> get props => [message, operationType, showProgress, progress];
}

/// State containing loaded redemption data and user information.
/// 
/// This is the main state containing all redemption options, user balance,
/// categories, and other necessary data for the redemption interface.
class RedemptionLoaded extends RedemptionState {
  final PaginatedResult<RedemptionOption> options;
  final int userPointBalance;
  final List<RedemptionCategory> categories;
  final List<RedemptionTransaction> recentTransactions;
  final DateTime lastUpdated;
  final bool hasNextPage;
  final String? currentSearchQuery;
  final RedemptionCategory? currentCategoryFilter;
  final int? currentMinPoints;
  final int? currentMaxPoints;
  final bool isRealTimeEnabled;

  const RedemptionLoaded({
    required this.options,
    required this.userPointBalance,
    required this.categories,
    required this.recentTransactions,
    required this.lastUpdated,
    required this.hasNextPage,
    this.currentSearchQuery,
    this.currentCategoryFilter,
    this.currentMinPoints,
    this.currentMaxPoints,
    this.isRealTimeEnabled = false,
  });

  /// Creates a copy with updated options for pagination
  RedemptionLoaded withAddedOptions(
    List<RedemptionOption> newOptions,
    bool hasMore,
  ) {
    final updatedItems = List<RedemptionOption>.from(options.items)
      ..addAll(newOptions);
    
    final updatedOptions = PaginatedResult<RedemptionOption>(
      items: updatedItems,
      totalCount: options.totalCount + newOptions.length,
      currentPage: options.currentPage + 1,
      hasNextPage: hasMore,
    );

    return copyWith(
      options: updatedOptions,
      hasNextPage: hasMore,
      lastUpdated: DateTime.now(),
    );
  }

  /// Creates a copy with updated user balance
  RedemptionLoaded withUpdatedBalance(int newBalance) {
    return copyWith(
      userPointBalance: newBalance,
      lastUpdated: DateTime.now(),
    );
  }

  /// Creates a copy with updated categories
  RedemptionLoaded withUpdatedCategories(List<RedemptionCategory> newCategories) {
    return copyWith(
      categories: newCategories,
      lastUpdated: DateTime.now(),
    );
  }

  /// Creates a copy with updated transactions
  RedemptionLoaded withUpdatedTransactions(List<RedemptionTransaction> newTransactions) {
    return copyWith(
      recentTransactions: newTransactions,
      lastUpdated: DateTime.now(),
    );
  }

  /// Creates a copy with applied search query
  RedemptionLoaded withSearchQuery(String? query) {
    return copyWith(
      currentSearchQuery: query,
      lastUpdated: DateTime.now(),
    );
  }

  /// Creates a copy with applied category filter
  RedemptionLoaded withCategoryFilter(RedemptionCategory? category) {
    return copyWith(
      currentCategoryFilter: category,
      lastUpdated: DateTime.now(),
    );
  }

  /// Creates a copy with applied point range filter
  RedemptionLoaded withPointRangeFilter({
    int? minPoints,
    int? maxPoints,
  }) {
    return copyWith(
      currentMinPoints: minPoints,
      currentMaxPoints: maxPoints,
      lastUpdated: DateTime.now(),
    );
  }

  /// Creates a copy with cleared filters
  RedemptionLoaded withClearedFilters() {
    return copyWith(
      currentSearchQuery: null,
      currentCategoryFilter: null,
      currentMinPoints: null,
      currentMaxPoints: null,
      lastUpdated: DateTime.now(),
    );
  }

  /// Gets available options based on user's point balance
  List<RedemptionOption> get availableOptions {
    return options.items
        .where((option) => option.requiredPoints <= userPointBalance)
        .toList();
  }

  /// Gets unavailable options (insufficient points)
  List<RedemptionOption> get unavailableOptions {
    return options.items
        .where((option) => option.requiredPoints > userPointBalance)
        .toList();
  }

  /// Checks if user has sufficient points for a specific option
  bool canAfford(String optionId) {
    final option = options.items.firstWhere(
      (opt) => opt.id == optionId,
      orElse: () => throw ArgumentError('Option not found: $optionId'),
    );
    return userPointBalance >= option.requiredPoints;
  }

  /// Gets the point deficit for an unaffordable option
  int getPointDeficit(String optionId) {
    final option = options.items.firstWhere(
      (opt) => opt.id == optionId,
      orElse: () => throw ArgumentError('Option not found: $optionId'),
    );
    final deficit = option.requiredPoints - userPointBalance;
    return deficit > 0 ? deficit : 0;
  }

  RedemptionLoaded copyWith({
    PaginatedResult<RedemptionOption>? options,
    int? userPointBalance,
    List<RedemptionCategory>? categories,
    List<RedemptionTransaction>? recentTransactions,
    DateTime? lastUpdated,
    bool? hasNextPage,
    String? currentSearchQuery,
    RedemptionCategory? currentCategoryFilter,
    int? currentMinPoints,
    int? currentMaxPoints,
    bool? isRealTimeEnabled,
  }) {
    return RedemptionLoaded(
      options: options ?? this.options,
      userPointBalance: userPointBalance ?? this.userPointBalance,
      categories: categories ?? this.categories,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      currentSearchQuery: currentSearchQuery ?? this.currentSearchQuery,
      currentCategoryFilter: currentCategoryFilter ?? this.currentCategoryFilter,
      currentMinPoints: currentMinPoints ?? this.currentMinPoints,
      currentMaxPoints: currentMaxPoints ?? this.currentMaxPoints,
      isRealTimeEnabled: isRealTimeEnabled ?? this.isRealTimeEnabled,
    );
  }

  @override
  List<Object?> get props => [
    options,
    userPointBalance,
    categories,
    recentTransactions,
    lastUpdated,
    hasNextPage,
    currentSearchQuery,
    currentCategoryFilter,
    currentMinPoints,
    currentMaxPoints,
    isRealTimeEnabled,
  ];
}

/// State indicating a redemption operation error.
/// 
/// This state contains error information and allows for
/// retry mechanisms and user feedback.
class RedemptionError extends RedemptionState {
  final String message;
  final RedemptionErrorType errorType;
  final RedemptionOperationType? failedOperation;
  final bool canRetry;
  final String? optionId;
  final int? attemptedQuantity;

  const RedemptionError({
    required this.message,
    required this.errorType,
    this.failedOperation,
    this.canRetry = true,
    this.optionId,
    this.attemptedQuantity,
  });

  @override
  List<Object?> get props => [
    message,
    errorType,
    failedOperation,
    canRetry,
    optionId,
    attemptedQuantity,
  ];
}

/// State indicating a pending redemption requiring user confirmation.
/// 
/// This state shows a confirmation dialog with redemption details
/// before the user commits to the redemption.
class RedemptionPendingConfirmation extends RedemptionState {
  final RedemptionOption option;
  final int quantity;
  final int totalPointsCost;
  final int remainingPointsAfter;
  final String confirmationMessage;
  final DateTime expiresAt;

  const RedemptionPendingConfirmation({
    required this.option,
    required this.quantity,
    required this.totalPointsCost,
    required this.remainingPointsAfter,
    required this.confirmationMessage,
    required this.expiresAt,
  });

  /// Checks if the confirmation has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Gets remaining time until expiration
  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());

  @override
  List<Object?> get props => [
    option,
    quantity,
    totalPointsCost,
    remainingPointsAfter,
    confirmationMessage,
    expiresAt,
  ];
}

/// State indicating a redemption is being processed.
/// 
/// This state shows the progress of an ongoing redemption
/// transaction with status updates.
class RedemptionProcessing extends RedemptionState {
  final String transactionId;
  final RedemptionOption option;
  final int quantity;
  final int totalPointsCost;
  final RedemptionStatus status;
  final String statusMessage;
  final double? progress;
  final DateTime startedAt;

  const RedemptionProcessing({
    required this.transactionId,
    required this.option,
    required this.quantity,
    required this.totalPointsCost,
    required this.status,
    required this.statusMessage,
    this.progress,
    required this.startedAt,
  });

  /// Gets elapsed time since processing started
  Duration get elapsedTime => DateTime.now().difference(startedAt);

  @override
  List<Object?> get props => [
    transactionId,
    option,
    quantity,
    totalPointsCost,
    status,
    statusMessage,
    progress,
    startedAt,
  ];
}

/// State indicating a successful redemption completion.
/// 
/// This state shows success information and transaction details
/// after a redemption has been completed successfully.
class RedemptionSuccess extends RedemptionState {
  final RedemptionTransaction transaction;
  final int newPointBalance;
  final String successMessage;
  final DateTime completedAt;
  final String? confirmationCode;
  final Map<String, dynamic>? additionalInfo;

  const RedemptionSuccess({
    required this.transaction,
    required this.newPointBalance,
    required this.successMessage,
    required this.completedAt,
    this.confirmationCode,
    this.additionalInfo,
  });

  @override
  List<Object?> get props => [
    transaction,
    newPointBalance,
    successMessage,
    completedAt,
    confirmationCode,
    additionalInfo,
  ];
}

/// State containing loaded redemption history data.
/// 
/// This state displays the user's past redemption transactions
/// with filtering and pagination support.
class RedemptionHistoryLoaded extends RedemptionState {
  final PaginatedResult<RedemptionTransaction> transactions;
  final DateTime lastUpdated;
  final bool hasNextPage;
  final DateTime? currentStartDate;
  final DateTime? currentEndDate;
  final RedemptionStatus? currentStatusFilter;

  const RedemptionHistoryLoaded({
    required this.transactions,
    required this.lastUpdated,
    required this.hasNextPage,
    this.currentStartDate,
    this.currentEndDate,
    this.currentStatusFilter,
  });

  /// Creates a copy with additional transactions for pagination
  RedemptionHistoryLoaded withAddedTransactions(
    List<RedemptionTransaction> newTransactions,
    bool hasMore,
  ) {
    final updatedItems = List<RedemptionTransaction>.from(transactions.items)
      ..addAll(newTransactions);
    
    final updatedTransactions = PaginatedResult<RedemptionTransaction>(
      items: updatedItems,
      totalCount: transactions.totalCount + newTransactions.length,
      currentPage: transactions.currentPage + 1,
      hasNextPage: hasMore,
    );

    return copyWith(
      transactions: updatedTransactions,
      hasNextPage: hasMore,
      lastUpdated: DateTime.now(),
    );
  }

  /// Creates a copy with applied date filter
  RedemptionHistoryLoaded withDateFilter({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return copyWith(
      currentStartDate: startDate,
      currentEndDate: endDate,
      lastUpdated: DateTime.now(),
    );
  }

  /// Creates a copy with applied status filter
  RedemptionHistoryLoaded withStatusFilter(RedemptionStatus? status) {
    return copyWith(
      currentStatusFilter: status,
      lastUpdated: DateTime.now(),
    );
  }

  /// Gets transactions for a specific status
  List<RedemptionTransaction> getTransactionsByStatus(RedemptionStatus status) {
    return transactions.items
        .where((transaction) => transaction.status == status)
        .toList();
  }

  /// Gets total points spent in loaded transactions
  int get totalPointsSpent {
    return transactions.items
        .where((transaction) => transaction.status == RedemptionStatus.completed)
        .fold(0, (sum, transaction) => sum + transaction.pointsUsed);
  }

  RedemptionHistoryLoaded copyWith({
    PaginatedResult<RedemptionTransaction>? transactions,
    DateTime? lastUpdated,
    bool? hasNextPage,
    DateTime? currentStartDate,
    DateTime? currentEndDate,
    RedemptionStatus? currentStatusFilter,
  }) {
    return RedemptionHistoryLoaded(
      transactions: transactions ?? this.transactions,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      currentStartDate: currentStartDate ?? this.currentStartDate,
      currentEndDate: currentEndDate ?? this.currentEndDate,
      currentStatusFilter: currentStatusFilter ?? this.currentStatusFilter,
    );
  }

  @override
  List<Object?> get props => [
    transactions,
    lastUpdated,
    hasNextPage,
    currentStartDate,
    currentEndDate,
    currentStatusFilter,
  ];
}

/// Enumeration of redemption operation types.
/// 
/// This enum identifies different types of operations
/// for loading states and error handling.
enum RedemptionOperationType {
  loadOptions,
  loadMoreOptions,
  loadBalance,
  loadHistory,
  loadMoreHistory,
  loadCategories,
  validateRedemption,
  processRedemption,
  checkEligibility,
  refresh,
}

/// Enumeration of redemption error types.
/// 
/// This enum categorizes different types of errors
/// for appropriate user messaging and handling.
enum RedemptionErrorType {
  network,
  insufficientPoints,
  optionUnavailable,
  optionExpired,
  quantityExceeded,
  validation,
  server,
  timeout,
  permission,
  generic,
}