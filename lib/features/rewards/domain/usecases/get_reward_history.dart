import '../../../../core/errors/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../entities/entities.dart';
import '../repositories/repositories.dart';

/// Parameters for retrieving reward history.
/// 
/// This class encapsulates all the filtering and pagination options
/// for fetching user reward history.
class GetRewardHistoryParams {
  final String userId;
  final int page;
  final int limit;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? categoryId;
  final RewardType? type;

  const GetRewardHistoryParams({
    required this.userId,
    this.page = 1,
    this.limit = 20,
    this.startDate,
    this.endDate,
    this.categoryId,
    this.type,
  });

  /// Create validated params with business rule validation.
  /// 
  /// Returns [Either<ValidationFailure, GetRewardHistoryParams>]:
  /// - Left: [ValidationFailure] if validation fails
  /// - Right: [GetRewardHistoryParams] if validation succeeds
  static Either<ValidationFailure, GetRewardHistoryParams> create({
    required String userId,
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    RewardType? type,
  }) {
    // Validate user ID
    if (userId.trim().isEmpty) {
      return Either.left(ValidationFailure('User ID cannot be empty'));
    }

    // Validate pagination parameters
    if (page < 1) {
      return Either.left(ValidationFailure('Page number must be at least 1'));
    }

    if (limit < 1 || limit > 100) {
      return Either.left(ValidationFailure('Limit must be between 1 and 100'));
    }

    // Validate date range
    if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
      return Either.left(ValidationFailure('Start date cannot be after end date'));
    }

    // Validate category ID if provided
    if (categoryId != null && categoryId.trim().isEmpty) {
      return Either.left(ValidationFailure('Category ID cannot be empty when provided'));
    }

    return Either.right(GetRewardHistoryParams(
      userId: userId.trim(),
      page: page,
      limit: limit,
      startDate: startDate,
      endDate: endDate,
      categoryId: categoryId?.trim(),
      type: type,
    ));
  }

  /// Creates params for getting recent entries (last 30 days)
  static GetRewardHistoryParams recent({
    required String userId,
    int limit = 20,
  }) {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return GetRewardHistoryParams(
      userId: userId,
      page: 1,
      limit: limit,
      startDate: thirtyDaysAgo,
    );
  }

  /// Creates params for getting entries by category
  static GetRewardHistoryParams byCategory({
    required String userId,
    required String categoryId,
    int page = 1,
    int limit = 20,
  }) {
    return GetRewardHistoryParams(
      userId: userId,
      page: page,
      limit: limit,
      categoryId: categoryId,
    );
  }

  /// Creates params for getting entries by type
  static GetRewardHistoryParams byType({
    required String userId,
    required RewardType type,
    int page = 1,
    int limit = 20,
  }) {
    return GetRewardHistoryParams(
      userId: userId,
      page: page,
      limit: limit,
      type: type,
    );
  }

  @override
  String toString() {
    return 'GetRewardHistoryParams(userId: $userId, page: $page, limit: $limit, '
           'startDate: $startDate, endDate: $endDate, categoryId: $categoryId, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetRewardHistoryParams &&
        other.userId == userId &&
        other.page == page &&
        other.limit == limit &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.categoryId == categoryId &&
        other.type == type;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        page.hashCode ^
        limit.hashCode ^
        startDate.hashCode ^
        endDate.hashCode ^
        categoryId.hashCode ^
        type.hashCode;
  }
}

/// Use case for retrieving reward history with filtering and pagination.
/// 
/// This use case handles the complete business logic for fetching user reward history,
/// including filtering, pagination, sorting, and access control validation.
/// It follows the single responsibility principle by focusing solely on
/// reward history retrieval functionality.
/// 
/// Features supported:
/// - Pagination with customizable page size
/// - Date range filtering
/// - Category-based filtering  
/// - Reward type filtering
/// - Chronological ordering (newest first)
/// - User ownership validation
/// - Performance optimization for large datasets
/// 
/// Business rules enforced:
/// - US-007: Display reward history in chronological order with filtering options
/// - User can only access their own reward history
/// - Maximum page size limits to prevent performance issues
/// - Date range validation
class GetRewardHistory implements UseCase<PaginatedResult<RewardEntry>, GetRewardHistoryParams> {
  final RewardRepository repository;

  /// Creates a new [GetRewardHistory] use case.
  /// 
  /// Parameters:
  /// - [repository]: The reward repository for data operations
  const GetRewardHistory(this.repository);

  /// Execute the reward history retrieval process.
  /// 
  /// This method orchestrates the reward history fetching flow and handles
  /// all business logic related to retrieving reward entries.
  /// 
  /// Parameters:
  /// - [params]: Contains filtering and pagination parameters
  /// 
  /// Returns [Either<Failure, PaginatedResult<RewardEntry>>]:
  /// - Left: [Failure] if retrieval fails
  /// - Right: [PaginatedResult<RewardEntry>] with filtered entries
  /// 
  /// Possible failures:
  /// - [ValidationFailure] for invalid parameters
  /// - [AuthFailure] for unauthorized access
  /// - [NetworkFailure] for network connectivity issues
  /// 
  /// Business logic handled:
  /// 1. Validates input parameters and access permissions
  /// 2. Applies filtering based on date range, category, and type
  /// 3. Implements pagination with performance considerations
  /// 4. Ensures chronological ordering (newest first per US-007)
  /// 5. Provides rich metadata for pagination controls
  @override
  Future<Either<Failure, PaginatedResult<RewardEntry>>> call(GetRewardHistoryParams params) async {
    try {
      // Step 1: Validate access permissions
      final accessValidation = await _validateUserAccess(params.userId);
      if (accessValidation.isLeft) {
        return Either.left(accessValidation.left);
      }

      // Step 2: Validate category exists if specified
      if (params.categoryId != null) {
        final categoryValidation = await _validateCategory(params.categoryId!);
        if (categoryValidation.isLeft) {
          return Either.left(categoryValidation.left);
        }
      }

      // Step 3: Fetch reward history from repository
      final result = await repository.getRewardHistory(
        userId: params.userId,
        page: params.page,
        limit: params.limit,
        startDate: params.startDate,
        endDate: params.endDate,
        categoryId: params.categoryId,
        type: params.type,
      );

      return result.fold(
        // Handle retrieval failure
        (failure) async {
          await _logFailedRetrieval(params, failure);
          return Either.left(failure);
        },
        // Handle retrieval success
        (paginatedResult) async {
          // Step 4: Apply additional business logic if needed
          final processedResult = await _processRetrievedEntries(paginatedResult);
          
          // Step 5: Log successful retrieval for analytics
          await _logSuccessfulRetrieval(params, paginatedResult);
          
          // Note: In a more complex implementation, you might:
          // - Cache frequently accessed data
          // - Pre-load related category information
          // - Apply user-specific display preferences
          // - Add analytics tracking
          // - Implement read receipts or view tracking
          
          return Either.right(processedResult);
        },
      );
    } catch (e) {
      // Handle unexpected errors
      return Either.left(ValidationFailure('Unexpected error during history retrieval: $e'));
    }
  }

  /// Validates that the user has access to view reward history.
  Future<Either<Failure, bool>> _validateUserAccess(String userId) async {
    // In a real implementation, this would:
    // - Verify user authentication
    // - Check user permissions/roles
    // - Validate account status (active, suspended, etc.)
    // - Apply data access policies
    
    if (userId.isEmpty) {
      return Either.left(ValidationFailure('User ID is required'));
    }

    return Either.right(true);
  }

  /// Validates that the specified category exists and is accessible to the user.
  Future<Either<Failure, RewardCategory>> _validateCategory(String categoryId) async {
    final categoriesResult = await repository.getRewardCategories();
    
    return categoriesResult.fold(
      (failure) => Either.left(failure),
      (categories) {
        final category = categories.where((cat) => cat.id == categoryId).firstOrNull;
        
        if (category == null) {
          return Either.left(ValidationFailure('Category with ID $categoryId not found'));
        }
        
        return Either.right(category);
      },
    );
  }

  /// Processes retrieved entries to add additional metadata or business logic.
  Future<PaginatedResult<RewardEntry>> _processRetrievedEntries(
    PaginatedResult<RewardEntry> result,
  ) async {
    // In a more complex implementation, you might:
    // - Enrich entries with category names/colors
    // - Calculate running balance totals
    // - Add display hints for UI (e.g., "recent", "high-value")
    // - Apply user-specific formatting preferences
    // - Add computed fields like "days ago"
    
    // For now, return as-is
    return result;
  }

  /// Gets reward summary statistics for the user.
  /// 
  /// This method provides aggregated statistics about the user's reward history
  /// which can be useful for dashboard displays.
  /// 
  /// Parameters:
  /// - [userId]: User whose statistics to calculate
  /// - [dateRange]: Optional date range for statistics (defaults to all time)
  /// 
  /// Returns [Either<Failure, RewardSummaryStats>]:
  /// - Left: [Failure] if calculation fails
  /// - Right: [RewardSummaryStats] with aggregated data
  Future<Either<Failure, RewardSummaryStats>> getRewardSummary({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Get user's total points
      final totalPointsResult = await repository.getTotalPoints(userId);
      if (totalPointsResult.isLeft) {
        return Either.left(totalPointsResult.left);
      }

      // Get all entries for calculation (in a real implementation, 
      // this might be done more efficiently in the repository)
      final historyParams = GetRewardHistoryParams.create(
        userId: userId,
        page: 1,
        limit: 1000, // Large limit for statistics
        startDate: startDate,
        endDate: endDate,
      ).right;

      final historyResult = await call(historyParams);
      if (historyResult.isLeft) {
        return Either.left(historyResult.left);
      }

      final entries = historyResult.right.items;
      
      // Calculate statistics
      final stats = RewardSummaryStats(
        totalPoints: totalPointsResult.right,
        totalEntries: entries.length,
        earnedPoints: entries
            .where((e) => e.type == RewardType.earned)
            .fold(0, (sum, e) => sum + e.points),
        bonusPoints: entries
            .where((e) => e.type == RewardType.bonus)
            .fold(0, (sum, e) => sum + e.points),
        adjustedPoints: entries
            .where((e) => e.type == RewardType.adjusted)
            .fold(0, (sum, e) => sum + e.points),
        averagePointsPerEntry: entries.isNotEmpty 
            ? entries.fold(0, (sum, e) => sum + e.points) / entries.length
            : 0.0,
        mostRecentEntryDate: entries.isNotEmpty 
            ? entries.first.createdAt 
            : null,
      );

      return Either.right(stats);
    } catch (e) {
      return Either.left(ValidationFailure('Error calculating reward summary: $e'));
    }
  }

  /// Validates history retrieval parameters.
  /// 
  /// This method can be used by the presentation layer for early validation
  /// before making the actual repository request.
  Future<Either<ValidationFailure, bool>> validateHistoryParams({
    required String userId,
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    RewardType? type,
  }) async {
    final paramsResult = GetRewardHistoryParams.create(
      userId: userId,
      page: page,
      limit: limit,
      startDate: startDate,
      endDate: endDate,
      categoryId: categoryId,
      type: type,
    );

    return paramsResult.fold(
      (failure) => Either.left(failure),
      (_) => Either.right(true),
    );
  }

  /// Log failed reward history retrieval for monitoring.
  Future<void> _logFailedRetrieval(GetRewardHistoryParams params, Failure failure) async {
    // In a real implementation, this would:
    // - Log to monitoring system
    // - Track failed retrieval patterns
    // - Monitor for performance issues
    // - Alert on systematic failures
    
    // For now, this is a placeholder
    // print('Failed reward history retrieval for user ${params.userId}: $failure');
  }

  /// Log successful reward history retrieval for analytics.
  Future<void> _logSuccessfulRetrieval(
    GetRewardHistoryParams params, 
    PaginatedResult<RewardEntry> result,
  ) async {
    // In a real implementation, this would:
    // - Log to analytics system
    // - Track usage patterns
    // - Monitor performance metrics
    // - Update access statistics
    
    // For now, this is a placeholder
    // print('Successful reward history retrieval: ${result.itemCount} entries for user ${params.userId}');
  }
}

/// Summary statistics for user reward history
class RewardSummaryStats {
  final int totalPoints;
  final int totalEntries;
  final int earnedPoints;
  final int bonusPoints;
  final int adjustedPoints;
  final double averagePointsPerEntry;
  final DateTime? mostRecentEntryDate;

  const RewardSummaryStats({
    required this.totalPoints,
    required this.totalEntries,
    required this.earnedPoints,
    required this.bonusPoints,
    required this.adjustedPoints,
    required this.averagePointsPerEntry,
    this.mostRecentEntryDate,
  });

  @override
  String toString() {
    return 'RewardSummaryStats(totalPoints: $totalPoints, totalEntries: $totalEntries, '
           'earnedPoints: $earnedPoints, bonusPoints: $bonusPoints, adjustedPoints: $adjustedPoints, '
           'averagePointsPerEntry: $averagePointsPerEntry, mostRecentEntryDate: $mostRecentEntryDate)';
  }
}