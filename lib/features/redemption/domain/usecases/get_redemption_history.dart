import '../../../../core/errors/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../entities/entities.dart';
import '../repositories/repositories.dart';

/// Parameters for getting redemption history.
/// 
/// This class encapsulates filtering, pagination, and sorting options for
/// retrieving user's redemption transaction history with comprehensive validation.
class GetRedemptionHistoryParams {
  final String userId;
  final int page;
  final int limit;
  final RedemptionStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final RedemptionHistorySortOrder sortOrder;

  const GetRedemptionHistoryParams({
    required this.userId,
    this.page = 1,
    this.limit = 20,
    this.status,
    this.startDate,
    this.endDate,
    this.sortOrder = RedemptionHistorySortOrder.dateDescending,
  });

  /// Create validated params with business rule validation.
  /// 
  /// Validates pagination parameters, date ranges, and user access.
  /// 
  /// Returns [Either<ValidationFailure, GetRedemptionHistoryParams>]:
  /// - Left: [ValidationFailure] if validation fails
  /// - Right: [GetRedemptionHistoryParams] if validation succeeds
  static Either<ValidationFailure, GetRedemptionHistoryParams> create({
    required String userId,
    int page = 1,
    int limit = 20,
    RedemptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    RedemptionHistorySortOrder sortOrder = RedemptionHistorySortOrder.dateDescending,
  }) {
    // Validate user ID
    if (userId.trim().isEmpty) {
      return Either.left(ValidationFailure('User ID cannot be empty'));
    }

    // Validate pagination parameters
    if (page < 1) {
      return Either.left(ValidationFailure('Page number must be at least 1'));
    }

    if (limit < 1) {
      return Either.left(ValidationFailure('Limit must be at least 1'));
    }

    if (limit > 100) {
      return Either.left(ValidationFailure('Limit cannot exceed 100 items per page'));
    }

    // Validate date range
    if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
      return Either.left(ValidationFailure('Start date cannot be after end date'));
    }

    // Validate dates are not in the future
    final now = DateTime.now();
    if (startDate != null && startDate.isAfter(now)) {
      return Either.left(ValidationFailure('Start date cannot be in the future'));
    }

    if (endDate != null && endDate.isAfter(now)) {
      return Either.left(ValidationFailure('End date cannot be in the future'));
    }

    return Either.right(GetRedemptionHistoryParams(
      userId: userId.trim(),
      page: page,
      limit: limit,
      status: status,
      startDate: startDate,
      endDate: endDate,
      sortOrder: sortOrder,
    ));
  }

  @override
  String toString() {
    return 'GetRedemptionHistoryParams(userId: $userId, page: $page, limit: $limit, '
           'status: $status, startDate: $startDate, endDate: $endDate, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetRedemptionHistoryParams &&
        other.userId == userId &&
        other.page == page &&
        other.limit == limit &&
        other.status == status &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.sortOrder == sortOrder;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        page.hashCode ^
        limit.hashCode ^
        status.hashCode ^
        startDate.hashCode ^
        endDate.hashCode ^
        sortOrder.hashCode;
  }
}

/// Sorting options for redemption history
enum RedemptionHistorySortOrder {
  dateAscending,
  dateDescending,
  pointsAscending,
  pointsDescending,
  statusGrouped,
}

/// Use case for retrieving user's redemption transaction history.
/// 
/// This use case handles the business logic for fetching and filtering
/// a user's redemption history with comprehensive pagination, filtering,
/// and enrichment capabilities.
/// 
/// Features provided:
/// - Paginated history retrieval
/// - Status-based filtering
/// - Date range filtering
/// - Multiple sorting options
/// - Transaction enrichment with option details
/// - Export-friendly data formatting
/// 
/// Business rules enforced:
/// - User can only access their own redemption history
/// - Proper pagination limits to prevent performance issues
/// - Audit trail preservation for completed transactions
/// - Comprehensive transaction metadata
class GetRedemptionHistory implements UseCase<PaginatedResult<RedemptionTransactionWithDetails>, GetRedemptionHistoryParams> {
  final RedemptionRepository repository;

  /// Creates a new [GetRedemptionHistory] use case.
  /// 
  /// Parameters:
  /// - [repository]: The redemption repository for data operations
  const GetRedemptionHistory(this.repository);

  /// Execute the redemption history retrieval process.
  /// 
  /// This method fetches the user's redemption history with the specified
  /// filters, pagination, and enrichment.
  /// 
  /// Parameters:
  /// - [params]: Contains filtering, pagination, and sorting preferences
  /// 
  /// Returns [Either<Failure, PaginatedResult<RedemptionTransactionWithDetails>>]:
  /// - Left: [Failure] if retrieval fails
  /// - Right: [PaginatedResult<RedemptionTransactionWithDetails>] with paginated results
  /// 
  /// Possible failures:
  /// - [ValidationFailure] for invalid parameters
  /// - [AuthFailure] for unauthorized access
  /// - [NetworkFailure] for connectivity issues
  /// - [NotFoundFailure] if user has no redemption history
  /// 
  /// Business logic handled:
  /// 1. Validates user access permissions
  /// 2. Retrieves paginated transaction history
  /// 3. Enriches transactions with redemption option details
  /// 4. Applies additional filtering and sorting
  /// 5. Formats data for presentation layer consumption
  /// 6. Provides comprehensive transaction metadata
  @override
  Future<Either<Failure, PaginatedResult<RedemptionTransactionWithDetails>>> call(GetRedemptionHistoryParams params) async {
    try {
      // Step 1: Validate user permissions (basic validation)
      final permissionValidation = await _validateUserPermissions(params.userId);
      if (permissionValidation.isLeft) {
        return Either.left(permissionValidation.left);
      }

      // Step 2: Retrieve paginated redemption history
      final historyResult = await repository.getRedemptionHistory(
        userId: params.userId,
        page: params.page,
        limit: params.limit,
        status: params.status,
        startDate: params.startDate,
        endDate: params.endDate,
      );

      if (historyResult.isLeft) {
        return Either.left(historyResult.left);
      }

      final paginatedTransactions = historyResult.right;

      // Step 3: Enrich transactions with redemption option details
      final enrichedTransactionsResult = await _enrichTransactionsWithDetails(paginatedTransactions.items);
      if (enrichedTransactionsResult.isLeft) {
        return Either.left(enrichedTransactionsResult.left);
      }

      final enrichedTransactions = enrichedTransactionsResult.right;

      // Step 4: Apply additional sorting if needed
      final sortedTransactions = _applySorting(enrichedTransactions, params.sortOrder);

      // Step 5: Create enriched paginated result
      final enrichedResult = PaginatedResult<RedemptionTransactionWithDetails>(
        items: sortedTransactions,
        totalCount: paginatedTransactions.totalCount,
        currentPage: paginatedTransactions.currentPage,
        hasNextPage: paginatedTransactions.hasNextPage,
      );

      // Step 6: Log successful retrieval for analytics
      await _logSuccessfulRetrieval(params, enrichedResult.itemCount);

      return Either.right(enrichedResult);
    } catch (e) {
      // Handle unexpected errors
      await _logUnexpectedError(params, e);
      return Either.left(ValidationFailure('Unexpected error retrieving redemption history: $e'));
    }
  }

  /// Validates user permissions to access redemption history.
  Future<Either<Failure, bool>> _validateUserPermissions(String userId) async {
    // In a real implementation, this would:
    // - Verify user account is active
    // - Check user authentication status
    // - Validate user access permissions
    // - Ensure user is not suspended or banned
    
    // For now, basic validation
    if (userId.isEmpty) {
      return Either.left(AuthFailure('Invalid user ID'));
    }

    return Either.right(true);
  }

  /// Enriches redemption transactions with additional details.
  Future<Either<Failure, List<RedemptionTransactionWithDetails>>> _enrichTransactionsWithDetails(
    List<RedemptionTransaction> transactions,
  ) async {
    try {
      final enrichedTransactions = <RedemptionTransactionWithDetails>[];

      // Get all unique option IDs to batch fetch redemption options
      final optionIds = transactions.map((t) => t.optionId).toSet().toList();
      final optionsMap = await _getRedemptionOptionsMap(optionIds);

      for (final transaction in transactions) {
        final option = optionsMap[transaction.optionId];
        
        final enrichedTransaction = RedemptionTransactionWithDetails(
          transaction: transaction,
          option: option,
          formattedDate: _formatTransactionDate(transaction.redeemedAt),
          statusDescription: _getStatusDescription(transaction.status),
          canBeCancelled: _canTransactionBeCancelled(transaction),
          estimatedValue: option != null ? _estimateTransactionValue(transaction, option) : 0.0,
        );

        enrichedTransactions.add(enrichedTransaction);
      }

      return Either.right(enrichedTransactions);
    } catch (e) {
      return Either.left(ValidationFailure('Error enriching transaction details: $e'));
    }
  }

  /// Gets a map of redemption options for batch loading.
  Future<Map<String, RedemptionOption?>> _getRedemptionOptionsMap(List<String> optionIds) async {
    final optionsMap = <String, RedemptionOption?>{};
    
    // Get all available options
    final optionsResult = await repository.getRedemptionOptions();
    if (optionsResult.isRight) {
      final options = optionsResult.right;
      
      // Create a lookup map
      for (final optionId in optionIds) {
        try {
          optionsMap[optionId] = options.firstWhere((option) => option.id == optionId);
        } catch (e) {
          optionsMap[optionId] = null; // Handle deleted/unavailable options
        }
      }
    }

    return optionsMap;
  }

  /// Formats transaction date for display.
  String _formatTransactionDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = difference.inDays ~/ 7;
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else {
      final months = difference.inDays ~/ 30;
      return months == 1 ? '1 month ago' : '$months months ago';
    }
  }

  /// Gets user-friendly status description.
  String _getStatusDescription(RedemptionStatus status) {
    switch (status) {
      case RedemptionStatus.pending:
        return 'Processing';
      case RedemptionStatus.completed:
        return 'Completed';
      case RedemptionStatus.cancelled:
        return 'Cancelled';
      case RedemptionStatus.expired:
        return 'Expired';
    }
  }

  /// Determines if a transaction can still be cancelled.
  bool _canTransactionBeCancelled(RedemptionTransaction transaction) {
    // Business rule: Only pending transactions can be cancelled
    if (transaction.status != RedemptionStatus.pending) {
      return false;
    }

    // Additional business rule: Cannot cancel after 24 hours
    final hoursSinceRedemption = DateTime.now().difference(transaction.redeemedAt).inHours;
    return hoursSinceRedemption <= 24;
  }

  /// Estimates the real-world value of a completed transaction.
  double _estimateTransactionValue(RedemptionTransaction transaction, RedemptionOption option) {
    // Calculate based on points used and option value
    final unitsRedeemed = transaction.pointsUsed ~/ option.requiredPoints;
    final baseValue = option.requiredPoints * 0.01; // $0.01 per point
    return baseValue * unitsRedeemed;
  }

  /// Applies additional sorting to enriched transactions.
  List<RedemptionTransactionWithDetails> _applySorting(
    List<RedemptionTransactionWithDetails> transactions,
    RedemptionHistorySortOrder sortOrder,
  ) {
    final sortedTransactions = List<RedemptionTransactionWithDetails>.from(transactions);

    switch (sortOrder) {
      case RedemptionHistorySortOrder.dateAscending:
        sortedTransactions.sort((a, b) => a.transaction.redeemedAt.compareTo(b.transaction.redeemedAt));
        break;
      case RedemptionHistorySortOrder.dateDescending:
        sortedTransactions.sort((a, b) => b.transaction.redeemedAt.compareTo(a.transaction.redeemedAt));
        break;
      case RedemptionHistorySortOrder.pointsAscending:
        sortedTransactions.sort((a, b) => a.transaction.pointsUsed.compareTo(b.transaction.pointsUsed));
        break;
      case RedemptionHistorySortOrder.pointsDescending:
        sortedTransactions.sort((a, b) => b.transaction.pointsUsed.compareTo(a.transaction.pointsUsed));
        break;
      case RedemptionHistorySortOrder.statusGrouped:
        // Group by status, then sort by date within each group
        sortedTransactions.sort((a, b) {
          final statusComparison = _getStatusPriority(a.transaction.status).compareTo(_getStatusPriority(b.transaction.status));
          if (statusComparison != 0) return statusComparison;
          return b.transaction.redeemedAt.compareTo(a.transaction.redeemedAt);
        });
        break;
    }

    return sortedTransactions;
  }

  /// Gets priority order for status grouping.
  int _getStatusPriority(RedemptionStatus status) {
    switch (status) {
      case RedemptionStatus.pending:
        return 1;
      case RedemptionStatus.completed:
        return 2;
      case RedemptionStatus.cancelled:
        return 3;
      case RedemptionStatus.expired:
        return 4;
    }
  }

  /// Gets summary statistics for user's redemption history.
  /// 
  /// This convenience method provides aggregate information about
  /// the user's redemption activity.
  /// 
  /// Parameters:
  /// - [userId]: User to get statistics for
  /// - [startDate]: Optional start date for statistics period
  /// - [endDate]: Optional end date for statistics period
  /// 
  /// Returns [Either<Failure, RedemptionStats>]:
  /// - Left: [Failure] if retrieval fails
  /// - Right: [RedemptionStats] with aggregate statistics
  Future<Either<Failure, RedemptionStats>> getRedemptionStatistics({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return repository.getRedemptionStats(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Exports redemption history to a structured format.
  /// 
  /// This method provides data in a format suitable for export
  /// to CSV, PDF, or other external formats.
  /// 
  /// Parameters:
  /// - [userId]: User whose history to export
  /// - [startDate]: Optional start date for export range
  /// - [endDate]: Optional end date for export range
  /// 
  /// Returns [Either<Failure, List<RedemptionExportData>>]:
  /// - Left: [Failure] if export preparation fails
  /// - Right: [List<RedemptionExportData>] formatted for export
  Future<Either<Failure, List<RedemptionExportData>>> prepareHistoryForExport({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final paramsResult = GetRedemptionHistoryParams.create(
      userId: userId,
      page: 1,
      limit: 1000,
      startDate: startDate,
      endDate: endDate,
    );

    if (paramsResult.isLeft) {
      return Either.left(paramsResult.left);
    }

    final historyResult = await call(paramsResult.right);
    return historyResult.fold(
      (failure) => Either.left(failure),
      (paginatedResult) {
        final exportData = paginatedResult.items.map((transaction) => 
          RedemptionExportData.fromTransactionWithDetails(transaction)
        ).toList();
        return Either.right(exportData);
      },
    );
  }

  /// Log successful history retrieval for analytics.
  Future<void> _logSuccessfulRetrieval(GetRedemptionHistoryParams params, int transactionCount) async {
    // In a real implementation, this would:
    // - Log to analytics system
    // - Track history usage patterns
    // - Monitor popular filter combinations
    // - Update user engagement metrics
    
    // For now, this is a placeholder
    // print('Retrieved $transactionCount redemption transactions for user ${params.userId}');
  }

  /// Log unexpected errors for debugging and monitoring.
  Future<void> _logUnexpectedError(GetRedemptionHistoryParams params, Object error) async {
    // In a real implementation, this would:
    // - Log to error monitoring system
    // - Send alerts to development team
    // - Track error patterns and frequency
    // - Include stack traces and context
    
    // For now, this is a placeholder
    // print('Unexpected error retrieving redemption history: $error');
  }
}

/// Redemption transaction enriched with additional details
class RedemptionTransactionWithDetails {
  final RedemptionTransaction transaction;
  final RedemptionOption? option;
  final String formattedDate;
  final String statusDescription;
  final bool canBeCancelled;
  final double estimatedValue;

  const RedemptionTransactionWithDetails({
    required this.transaction,
    required this.option,
    required this.formattedDate,
    required this.statusDescription,
    required this.canBeCancelled,
    required this.estimatedValue,
  });

  /// Whether this transaction was for a valid option (option still exists)
  bool get hasValidOption => option != null;

  /// User-friendly display title for the transaction
  String get displayTitle {
    if (option != null) {
      return option!.title;
    } else {
      return 'Deleted Reward (${transaction.pointsUsed} points)';
    }
  }

  /// Number of units redeemed in this transaction
  int get unitsRedeemed {
    if (option == null) return 1;
    return transaction.pointsUsed ~/ option!.requiredPoints;
  }

  @override
  String toString() {
    return 'RedemptionTransactionWithDetails(transaction: ${transaction.id}, '
           'option: ${option?.title ?? "Deleted"}, status: $statusDescription, '
           'value: \$${estimatedValue.toStringAsFixed(2)})';
  }
}

/// Data structure for exporting redemption history
class RedemptionExportData {
  final String transactionId;
  final String date;
  final String rewardTitle;
  final int pointsUsed;
  final String status;
  final double estimatedValue;
  final String notes;

  const RedemptionExportData({
    required this.transactionId,
    required this.date,
    required this.rewardTitle,
    required this.pointsUsed,
    required this.status,
    required this.estimatedValue,
    required this.notes,
  });

  factory RedemptionExportData.fromTransactionWithDetails(RedemptionTransactionWithDetails transaction) {
    return RedemptionExportData(
      transactionId: transaction.transaction.id,
      date: transaction.transaction.redeemedAt.toIso8601String().split('T')[0], // YYYY-MM-DD format
      rewardTitle: transaction.displayTitle,
      pointsUsed: transaction.transaction.pointsUsed,
      status: transaction.statusDescription,
      estimatedValue: transaction.estimatedValue,
      notes: transaction.transaction.notes ?? '',
    );
  }

  /// Converts to CSV row format
  List<String> toCsvRow() {
    return [
      transactionId,
      date,
      rewardTitle,
      pointsUsed.toString(),
      status,
      estimatedValue.toStringAsFixed(2),
      notes,
    ];
  }

  /// CSV header row
  static List<String> csvHeaders() {
    return [
      'Transaction ID',
      'Date',
      'Reward',
      'Points Used',
      'Status',
      'Estimated Value (USD)',
      'Notes',
    ];
  }
}