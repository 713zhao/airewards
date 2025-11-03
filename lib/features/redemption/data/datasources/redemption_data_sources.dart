import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../models/models.dart';

/// Abstract interface for remote redemption data operations.
/// 
/// This interface defines all remote API operations for redemption functionality,
/// including CRUD operations, synchronization, and real-time updates.
/// 
/// Implementations should handle:
/// - Network connectivity and error handling
/// - API authentication and authorization
/// - Data serialization and deserialization
/// - Rate limiting and retry logic
/// - Response caching for performance
abstract class RedemptionRemoteDataSource {
  /// Retrieves all available redemption options from the remote server.
  /// 
  /// This method fetches the latest redemption options with current availability,
  /// pricing, and promotional information.
  /// 
  /// Returns [Either<Failure, List<RedemptionOptionModel>>]:
  /// - Left: [NetworkFailure] for connectivity issues
  /// - Left: [ServerFailure] for API errors
  /// - Right: List of available redemption options
  /// 
  /// Features:
  /// - Real-time availability checking
  /// - Promotional pricing updates
  /// - Category-based filtering
  /// - Inventory synchronization
  Future<Either<Failure, List<RedemptionOptionModel>>> getRedemptionOptions();

  /// Retrieves a specific redemption option by ID.
  /// 
  /// Parameters:
  /// - [optionId]: Unique identifier for the redemption option
  /// 
  /// Returns [Either<Failure, RedemptionOptionModel>]:
  /// - Left: [NotFoundFailure] if option doesn't exist
  /// - Left: [NetworkFailure] for connectivity issues
  /// - Right: Detailed redemption option information
  Future<Either<Failure, RedemptionOptionModel>> getRedemptionOption(String optionId);

  /// Processes a point redemption transaction on the remote server.
  /// 
  /// This method handles the complete redemption flow including:
  /// - Point balance verification
  /// - Inventory deduction
  /// - Transaction creation
  /// - Notification triggering
  /// 
  /// Parameters:
  /// - [userId]: User performing the redemption
  /// - [optionId]: Redemption option being redeemed
  /// - [pointsUsed]: Number of points to redeem
  /// - [notes]: Optional redemption notes
  /// 
  /// Returns [Either<Failure, RedemptionTransactionModel>]:
  /// - Left: [InsufficientPointsFailure] if user lacks points
  /// - Left: [ValidationFailure] for business rule violations
  /// - Left: [NetworkFailure] for connectivity issues
  /// - Right: Created redemption transaction
  Future<Either<Failure, RedemptionTransactionModel>> redeemPoints({
    required String userId,
    required String optionId,
    required int pointsUsed,
    String? notes,
  });

  /// Retrieves user's redemption history from the remote server.
  /// 
  /// This method provides paginated access to user's redemption transactions
  /// with comprehensive filtering and sorting capabilities.
  /// 
  /// Parameters:
  /// - [userId]: User whose history to retrieve
  /// - [page]: Page number for pagination (1-based)
  /// - [limit]: Number of items per page
  /// - [status]: Optional status filter
  /// - [startDate]: Optional start date filter
  /// - [endDate]: Optional end date filter
  /// 
  /// Returns [Either<Failure, PaginatedResult<RedemptionTransactionModel>>]:
  /// - Left: [NetworkFailure] for connectivity issues
  /// - Left: [AuthFailure] for unauthorized access
  /// - Right: Paginated redemption history
  Future<Either<Failure, PaginatedResult<RedemptionTransactionModel>>> getRedemptionHistory({
    required String userId,
    required int page,
    required int limit,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Retrieves user's current point balance from the remote server.
  /// 
  /// Parameters:
  /// - [userId]: User whose points to retrieve
  /// 
  /// Returns [Either<Failure, int>]:
  /// - Left: [NetworkFailure] for connectivity issues
  /// - Left: [NotFoundFailure] if user doesn't exist
  /// - Right: Current point balance
  Future<Either<Failure, int>> getUserPoints(String userId);

  /// Cancels a pending redemption transaction.
  /// 
  /// This method handles the cancellation flow including:
  /// - Transaction status verification
  /// - Point refund processing
  /// - Inventory restoration
  /// - Notification updates
  /// 
  /// Parameters:
  /// - [transactionId]: Transaction to cancel
  /// - [reason]: Reason for cancellation
  /// 
  /// Returns [Either<Failure, RedemptionTransactionModel>]:
  /// - Left: [ValidationFailure] if transaction cannot be cancelled
  /// - Left: [NotFoundFailure] if transaction doesn't exist
  /// - Right: Updated transaction with cancelled status
  Future<Either<Failure, RedemptionTransactionModel>> cancelRedemption({
    required String transactionId,
    required String reason,
  });

  /// Retrieves redemption statistics for a user.
  /// 
  /// Parameters:
  /// - [userId]: User to get statistics for
  /// - [startDate]: Optional start date for statistics period
  /// - [endDate]: Optional end date for statistics period
  /// 
  /// Returns [Either<Failure, RedemptionStatsModel>]:
  /// - Left: [NetworkFailure] for connectivity issues
  /// - Right: Comprehensive redemption statistics
  Future<Either<Failure, RedemptionStatsModel>> getRedemptionStats({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Synchronizes local data with remote server.
  /// 
  /// This method performs a comprehensive sync operation including:
  /// - Option availability updates
  /// - Transaction status updates
  /// - Point balance reconciliation
  /// - Conflict resolution
  /// 
  /// Parameters:
  /// - [lastSyncTime]: Last successful sync timestamp
  /// 
  /// Returns [Either<Failure, RedemptionSyncResult>]:
  /// - Left: [NetworkFailure] for connectivity issues
  /// - Right: Sync results with updated data
  Future<Either<Failure, RedemptionSyncResult>> syncRedemptionData({
    DateTime? lastSyncTime,
  });

  /// Updates redemption option availability and inventory.
  /// 
  /// Parameters:
  /// - [optionId]: Option to update
  /// - [availableQuantity]: New available quantity
  /// - [isActive]: Whether option is active
  /// 
  /// Returns [Either<Failure, RedemptionOptionModel>]:
  /// - Left: [ValidationFailure] for invalid updates
  /// - Left: [AuthFailure] for insufficient permissions
  /// - Right: Updated redemption option
  Future<Either<Failure, RedemptionOptionModel>> updateRedemptionOption({
    required String optionId,
    int? availableQuantity,
    bool? isActive,
  });

  /// Searches redemption options with advanced criteria.
  /// 
  /// Parameters:
  /// - [query]: Search query string
  /// - [category]: Optional category filter
  /// - [minPoints]: Minimum points required
  /// - [maxPoints]: Maximum points required
  /// - [isActive]: Whether to include only active options
  /// 
  /// Returns [Either<Failure, List<RedemptionOptionModel>>]:
  /// - Left: [NetworkFailure] for connectivity issues
  /// - Right: Matching redemption options
  Future<Either<Failure, List<RedemptionOptionModel>>> searchRedemptionOptions({
    required String query,
    String? category,
    int? minPoints,
    int? maxPoints,
    bool isActive = true,
  });

  /// Gets real-time updates for redemption data.
  /// 
  /// This method establishes a WebSocket or Server-Sent Events connection
  /// for real-time updates on redemption options and transactions.
  /// 
  /// Parameters:
  /// - [userId]: User to get updates for
  /// 
  /// Returns [Stream<RedemptionUpdateEvent>]:
  /// - Stream of real-time redemption updates
  Stream<RedemptionUpdateEvent> getRedemptionUpdates(String userId);

  /// Validates redemption eligibility before processing.
  /// 
  /// This method performs comprehensive validation including:
  /// - User eligibility checks
  /// - Point balance verification
  /// - Option availability confirmation
  /// - Business rule validation
  /// 
  /// Parameters:
  /// - [userId]: User attempting redemption
  /// - [optionId]: Option being redeemed
  /// - [pointsUsed]: Points to be used
  /// 
  /// Returns [Either<Failure, RedemptionEligibilityResult>]:
  /// - Left: [ValidationFailure] for eligibility failures
  /// - Right: Eligibility result with details
  Future<Either<Failure, RedemptionEligibilityResult>> validateRedemptionEligibility({
    required String userId,
    required String optionId,
    required int pointsUsed,
  });
}

/// Abstract interface for local redemption data operations.
/// 
/// This interface defines all local storage operations for redemption functionality,
/// including caching, offline support, and data persistence.
/// 
/// Implementations should handle:
/// - SQLite database operations
/// - Data encryption for sensitive information
/// - Offline data management
/// - Cache invalidation strategies
/// - Data migration and versioning
abstract class RedemptionLocalDataSource {
  /// Retrieves cached redemption options from local storage.
  /// 
  /// Returns [Either<Failure, List<RedemptionOptionModel>>]:
  /// - Left: [CacheFailure] if cache is empty or corrupted
  /// - Right: List of cached redemption options
  Future<Either<Failure, List<RedemptionOptionModel>>> getCachedRedemptionOptions();

  /// Caches redemption options to local storage.
  /// 
  /// Parameters:
  /// - [options]: Redemption options to cache
  /// 
  /// Returns [Either<Failure, void>]:
  /// - Left: [CacheFailure] if caching fails
  /// - Right: Success
  Future<Either<Failure, void>> cacheRedemptionOptions(List<RedemptionOptionModel> options);

  /// Retrieves a cached redemption option by ID.
  /// 
  /// Parameters:
  /// - [optionId]: Unique identifier for the redemption option
  /// 
  /// Returns [Either<Failure, RedemptionOptionModel>]:
  /// - Left: [CacheFailure] if option not found in cache
  /// - Right: Cached redemption option
  Future<Either<Failure, RedemptionOptionModel>> getCachedRedemptionOption(String optionId);

  /// Stores a redemption transaction locally.
  /// 
  /// This method handles both successful transactions and pending offline transactions.
  /// 
  /// Parameters:
  /// - [transaction]: Transaction to store
  /// 
  /// Returns [Either<Failure, void>]:
  /// - Left: [CacheFailure] if storage fails
  /// - Right: Success
  Future<Either<Failure, void>> storeRedemptionTransaction(RedemptionTransactionModel transaction);

  /// Retrieves user's cached redemption history.
  /// 
  /// Parameters:
  /// - [userId]: User whose history to retrieve
  /// - [page]: Page number for pagination
  /// - [limit]: Number of items per page
  /// 
  /// Returns [Either<Failure, PaginatedResult<RedemptionTransactionModel>>]:
  /// - Left: [CacheFailure] if no cached data available
  /// - Right: Paginated cached redemption history
  Future<Either<Failure, PaginatedResult<RedemptionTransactionModel>>> getCachedRedemptionHistory({
    required String userId,
    required int page,
    required int limit,
  });

  /// Retrieves cached user point balance.
  /// 
  /// Parameters:
  /// - [userId]: User whose points to retrieve
  /// 
  /// Returns [Either<Failure, int>]:
  /// - Left: [CacheFailure] if no cached balance available
  /// - Right: Cached point balance
  Future<Either<Failure, int>> getCachedUserPoints(String userId);

  /// Caches user point balance.
  /// 
  /// Parameters:
  /// - [userId]: User whose points to cache
  /// - [points]: Point balance to cache
  /// 
  /// Returns [Either<Failure, void>]:
  /// - Left: [CacheFailure] if caching fails
  /// - Right: Success
  Future<Either<Failure, void>> cacheUserPoints(String userId, int points);

  /// Retrieves pending offline redemption transactions.
  /// 
  /// These are transactions initiated while offline that need to be
  /// synchronized with the remote server when connectivity is restored.
  /// 
  /// Returns [Either<Failure, List<RedemptionTransactionModel>>]:
  /// - Left: [CacheFailure] if retrieval fails
  /// - Right: List of pending offline transactions
  Future<Either<Failure, List<RedemptionTransactionModel>>> getPendingOfflineRedemptions();

  /// Marks a pending transaction as synchronized.
  /// 
  /// Parameters:
  /// - [localTransactionId]: Local ID of the synchronized transaction
  /// - [remoteTransaction]: Updated transaction from remote server
  /// 
  /// Returns [Either<Failure, void>]:
  /// - Left: [CacheFailure] if update fails
  /// - Right: Success
  Future<Either<Failure, void>> markTransactionAsSynced({
    required String localTransactionId,
    required RedemptionTransactionModel remoteTransaction,
  });

  /// Clears expired cache data.
  /// 
  /// This method removes outdated cached data based on configurable TTL values.
  /// 
  /// Parameters:
  /// - [olderThan]: Remove data older than this duration
  /// 
  /// Returns [Either<Failure, void>]:
  /// - Left: [CacheFailure] if cleanup fails
  /// - Right: Success
  Future<Either<Failure, void>> clearExpiredCache({Duration? olderThan});

  /// Gets cache statistics and metadata.
  /// 
  /// Returns [Either<Failure, CacheStats>]:
  /// - Left: [CacheFailure] if stats retrieval fails
  /// - Right: Cache statistics and metadata
  Future<Either<Failure, CacheStats>> getCacheStats();

  /// Updates a cached redemption option.
  /// 
  /// Parameters:
  /// - [option]: Updated redemption option
  /// 
  /// Returns [Either<Failure, void>]:
  /// - Left: [CacheFailure] if update fails
  /// - Right: Success
  Future<Either<Failure, void>> updateCachedRedemptionOption(RedemptionOptionModel option);

  /// Removes a cached redemption option.
  /// 
  /// Parameters:
  /// - [optionId]: ID of option to remove
  /// 
  /// Returns [Either<Failure, void>]:
  /// - Left: [CacheFailure] if removal fails
  /// - Right: Success
  Future<Either<Failure, void>> removeCachedRedemptionOption(String optionId);
}

/// Real-time update event for redemption data
class RedemptionUpdateEvent {
  final RedemptionUpdateType type;
  final String entityId;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  const RedemptionUpdateEvent({
    required this.type,
    required this.entityId,
    required this.data,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'RedemptionUpdateEvent(type: $type, entityId: $entityId, timestamp: $timestamp)';
  }
}

/// Types of real-time redemption updates
enum RedemptionUpdateType {
  optionUpdated,
  optionDeleted,
  transactionStatusChanged,
  inventoryChanged,
  pointsUpdated,
}

/// Result of redemption eligibility validation
class RedemptionEligibilityResult {
  final bool isEligible;
  final List<String> violations;
  final int userPointBalance;
  final bool optionAvailable;
  final int? estimatedProcessingTime;

  const RedemptionEligibilityResult({
    required this.isEligible,
    required this.violations,
    required this.userPointBalance,
    required this.optionAvailable,
    this.estimatedProcessingTime,
  });

  @override
  String toString() {
    return 'RedemptionEligibilityResult(isEligible: $isEligible, violations: $violations)';
  }
}

/// Result of data synchronization operation
class RedemptionSyncResult {
  final int optionsUpdated;
  final int transactionsUpdated;
  final int conflictsResolved;
  final DateTime syncTimestamp;
  final List<String> errors;

  const RedemptionSyncResult({
    required this.optionsUpdated,
    required this.transactionsUpdated,
    required this.conflictsResolved,
    required this.syncTimestamp,
    required this.errors,
  });

  @override
  String toString() {
    return 'RedemptionSyncResult(optionsUpdated: $optionsUpdated, '
           'transactionsUpdated: $transactionsUpdated, '
           'conflictsResolved: $conflictsResolved)';
  }
}

/// Cache statistics and metadata
class CacheStats {
  final int totalOptions;
  final int totalTransactions;
  final int pendingOfflineTransactions;
  final DateTime? lastCacheUpdate;
  final int cacheSize; // in bytes
  final double hitRate; // 0.0 to 1.0

  const CacheStats({
    required this.totalOptions,
    required this.totalTransactions,
    required this.pendingOfflineTransactions,
    this.lastCacheUpdate,
    required this.cacheSize,
    required this.hitRate,
  });

  @override
  String toString() {
    return 'CacheStats(totalOptions: $totalOptions, '
           'totalTransactions: $totalTransactions, '
           'cacheSize: ${(cacheSize / 1024).toStringAsFixed(1)}KB, '
           'hitRate: ${(hitRate * 100).toStringAsFixed(1)}%)';
  }
}