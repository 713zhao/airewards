import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import '../../../core/errors/failures.dart';
import '../../../core/models/paginated_result.dart';
import '../../../core/utils/either.dart';
import '../data/datasources/redemption_data_sources.dart' as data;
import '../data/models/models.dart';
import '../domain/entities/entities.dart';
import '../domain/repositories/redemption_repository.dart';
import '../domain/usecases/usecases.dart';
import '../presentation/bloc/redemption/redemption_bloc.dart';
import '../presentation/bloc/redemption_options/redemption_options_cubit.dart';

/// Dependency injection configuration for the redemption feature.
///
/// The real production implementations for redemption data sources and
/// repository are still under construction. To keep the application compiling
/// and allow other modules to evolve, this module wires lightweight in-memory
/// mock implementations that satisfy the current interfaces.
@module
abstract class RedemptionInjectionModule {
  /// Provides a mock local data source that stores nothing but keeps
  /// the contract intact for callers.
  @lazySingleton
  data.RedemptionLocalDataSource get redemptionLocalDataSource =>
    MockRedemptionLocalDataSource();

  /// Provides a mock remote data source returning empty payloads.
  @lazySingleton
  data.RedemptionRemoteDataSource get redemptionRemoteDataSource =>
    MockRedemptionRemoteDataSource();
}

/// Helper class for registering redemption dependencies manually.
class RedemptionDependencyRegistration {
  /// Registers the mock implementations so that feature code can resolve
  /// dependencies without hitting unimplemented constructors.
  static void registerAll(GetIt getIt) {
    if (!getIt.isRegistered<data.RedemptionLocalDataSource>()) {
      getIt.registerLazySingleton<data.RedemptionLocalDataSource>(
        () => MockRedemptionLocalDataSource(),
      );
    }

    if (!getIt.isRegistered<data.RedemptionRemoteDataSource>()) {
      getIt.registerLazySingleton<data.RedemptionRemoteDataSource>(
        () => MockRedemptionRemoteDataSource(),
      );
    }

    if (!getIt.isRegistered<RedemptionRepository>()) {
      getIt.registerLazySingleton<RedemptionRepository>(
        () => MockRedemptionRepository(),
      );
    }

    // Domain use cases
    if (!getIt.isRegistered<RedeemPoints>()) {
      getIt.registerFactory<RedeemPoints>(
        () => RedeemPoints(getIt<RedemptionRepository>()),
      );
    }

    if (!getIt.isRegistered<GetRedemptionOptions>()) {
      getIt.registerFactory<GetRedemptionOptions>(
        () => GetRedemptionOptions(getIt<RedemptionRepository>()),
      );
    }

    if (!getIt.isRegistered<GetRedemptionHistory>()) {
      getIt.registerFactory<GetRedemptionHistory>(
        () => GetRedemptionHistory(getIt<RedemptionRepository>()),
      );
    }

    if (!getIt.isRegistered<ValidateRedemption>()) {
      getIt.registerFactory<ValidateRedemption>(
        () => ValidateRedemption(getIt<RedemptionRepository>()),
      );
    }

    if (!getIt.isRegistered<GetAvailablePoints>()) {
      getIt.registerFactory<GetAvailablePoints>(
        () => GetAvailablePoints(getIt<RedemptionRepository>()),
      );
    }

    if (!getIt.isRegistered<GetRedemptionStats>()) {
      getIt.registerFactory<GetRedemptionStats>(
        () => GetRedemptionStats(getIt<RedemptionRepository>()),
      );
    }

    if (!getIt.isRegistered<CancelRedemption>()) {
      getIt.registerFactory<CancelRedemption>(
        () => CancelRedemption(getIt<RedemptionRepository>()),
      );
    }

    // Presentation layer
    if (!getIt.isRegistered<RedemptionOptionsCubit>()) {
      getIt.registerFactory<RedemptionOptionsCubit>(
        () => RedemptionOptionsCubit(
          getRedemptionOptionsUseCase: getIt<GetRedemptionOptions>(),
        ),
      );
    }

    if (!getIt.isRegistered<RedemptionBloc>()) {
      getIt.registerFactory<RedemptionBloc>(
        () => RedemptionBloc(
          redeemPointsUseCase: getIt<RedeemPoints>(),
          getRedemptionHistoryUseCase: getIt<GetRedemptionHistory>(),
          validateRedemptionUseCase: getIt<ValidateRedemption>(),
          getAvailablePointsUseCase: getIt<GetAvailablePoints>(),
          getRedemptionStatsUseCase: getIt<GetRedemptionStats>(),
          cancelRedemptionUseCase: getIt<CancelRedemption>(),
        ),
      );
    }
  }

  /// Unregisters the mock implementations.
  static void unregisterAll(GetIt getIt) {
    if (getIt.isRegistered<RedemptionBloc>()) {
      getIt.unregister<RedemptionBloc>();
    }
    if (getIt.isRegistered<RedemptionOptionsCubit>()) {
      getIt.unregister<RedemptionOptionsCubit>();
    }
    if (getIt.isRegistered<CancelRedemption>()) {
      getIt.unregister<CancelRedemption>();
    }
    if (getIt.isRegistered<GetRedemptionStats>()) {
      getIt.unregister<GetRedemptionStats>();
    }
    if (getIt.isRegistered<GetAvailablePoints>()) {
      getIt.unregister<GetAvailablePoints>();
    }
    if (getIt.isRegistered<ValidateRedemption>()) {
      getIt.unregister<ValidateRedemption>();
    }
    if (getIt.isRegistered<GetRedemptionHistory>()) {
      getIt.unregister<GetRedemptionHistory>();
    }
    if (getIt.isRegistered<GetRedemptionOptions>()) {
      getIt.unregister<GetRedemptionOptions>();
    }
    if (getIt.isRegistered<RedeemPoints>()) {
      getIt.unregister<RedeemPoints>();
    }
    if (getIt.isRegistered<RedemptionRepository>()) {
      getIt.unregister<RedemptionRepository>();
    }
    if (getIt.isRegistered<data.RedemptionRemoteDataSource>()) {
      getIt.unregister<data.RedemptionRemoteDataSource>();
    }
    if (getIt.isRegistered<data.RedemptionLocalDataSource>()) {
      getIt.unregister<data.RedemptionLocalDataSource>();
    }
  }
}

/// In-memory mock implementation of the local data source contract.
class MockRedemptionLocalDataSource implements data.RedemptionLocalDataSource {
  @override
  Future<Either<Failure, void>> cacheRedemptionOptions(
    List<RedemptionOptionModel> options,
  ) async => Either.right(null);

  @override
  Future<Either<Failure, void>> cacheUserPoints(String userId, int points) async =>
      Either.right(null);

  @override
  Future<Either<Failure, PaginatedResult<RedemptionTransactionModel>>>
    getCachedRedemptionHistory({
    required String userId,
    required int page,
    required int limit,
  }) async {
    return Either.right(
      PaginatedResult<RedemptionTransactionModel>(
        items: const <RedemptionTransactionModel>[],
        totalCount: 0,
        currentPage: 1,
        hasNextPage: false,
      ),
    );
  }

  @override
  Future<Either<Failure, RedemptionOptionModel>> getCachedRedemptionOption(
    String optionId,
  ) async => Either.left(const CacheFailure('No cached option available'));

  @override
  Future<Either<Failure, List<RedemptionOptionModel>>> getCachedRedemptionOptions()
      async => Either.right(const <RedemptionOptionModel>[]);

  @override
  Future<Either<Failure, int>> getCachedUserPoints(String userId) async =>
      Either.right(0);

  @override
  Future<Either<Failure, List<RedemptionTransactionModel>>>
      getPendingOfflineRedemptions() async =>
          Either.right(const <RedemptionTransactionModel>[]);

  @override
  Future<Either<Failure, void>> markTransactionAsSynced({
    required String localTransactionId,
    required RedemptionTransactionModel remoteTransaction,
  }) async => Either.right(null);

  @override
  Future<Either<Failure, void>> clearExpiredCache({Duration? olderThan}) async =>
      Either.right(null);

  @override
  Future<Either<Failure, data.CacheStats>> getCacheStats() async =>
      Either.right(const data.CacheStats(
        totalOptions: 0,
        totalTransactions: 0,
        pendingOfflineTransactions: 0,
        cacheSize: 0,
        hitRate: 0.0,
      ));

  @override
  Future<Either<Failure, void>> removeCachedRedemptionOption(String optionId) async =>
      Either.right(null);

  @override
  Future<Either<Failure, void>> storeRedemptionTransaction(
    RedemptionTransactionModel transaction,
  ) async => Either.right(null);

  @override
  Future<Either<Failure, void>> updateCachedRedemptionOption(
    RedemptionOptionModel option,
  ) async => Either.right(null);
}

/// In-memory mock implementation of the remote data source contract.
class MockRedemptionRemoteDataSource implements data.RedemptionRemoteDataSource {
  @override
  Future<Either<Failure, RedemptionTransactionModel>> cancelRedemption({
    required String transactionId,
    required String reason,
  }) async => Either.left(const CacheFailure('Remote cancel not implemented'));

  @override
  Future<Either<Failure, PaginatedResult<RedemptionTransactionModel>>>
      getRedemptionHistory({
    required String userId,
    required int page,
    required int limit,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return Either.right(
      PaginatedResult<RedemptionTransactionModel>(
        items: const <RedemptionTransactionModel>[],
        totalCount: 0,
        currentPage: 1,
        hasNextPage: false,
      ),
    );
  }

  @override
  Future<Either<Failure, RedemptionOptionModel>> getRedemptionOption(
    String optionId,
  ) async => Either.left(const CacheFailure('Remote option not found'));

  @override
  Future<Either<Failure, List<RedemptionOptionModel>>> getRedemptionOptions()
      async => Either.right(const <RedemptionOptionModel>[]);

  @override
  Future<Either<Failure, RedemptionStatsModel>> getRedemptionStats({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async => Either.right(RedemptionStatsModel.empty(userId));

  @override
  Stream<data.RedemptionUpdateEvent> getRedemptionUpdates(String userId) =>
      const Stream<data.RedemptionUpdateEvent>.empty();

  @override
  Future<Either<Failure, int>> getUserPoints(String userId) async =>
      Either.right(0);

  @override
  Future<Either<Failure, RedemptionTransactionModel>> redeemPoints({
    required String userId,
    required String optionId,
    required int pointsUsed,
    String? notes,
  }) async => Either.left(const CacheFailure('Remote redeem not implemented'));

  @override
  Future<Either<Failure, List<RedemptionOptionModel>>> searchRedemptionOptions({
    required String query,
    String? category,
    int? minPoints,
    int? maxPoints,
    bool isActive = true,
  }) async => Either.right(const <RedemptionOptionModel>[]);

  @override
  Future<Either<Failure, data.RedemptionSyncResult>> syncRedemptionData({
    DateTime? lastSyncTime,
  }) async => Either.right(
        data.RedemptionSyncResult(
          optionsUpdated: 0,
          transactionsUpdated: 0,
          conflictsResolved: 0,
          syncTimestamp: DateTime.now(),
          errors: const [],
        ),
      );

  @override
  Future<Either<Failure, RedemptionOptionModel>> updateRedemptionOption({
    required String optionId,
    int? availableQuantity,
    bool? isActive,
  }) async => Either.left(const CacheFailure('Remote update not implemented'));

  @override
  Future<Either<Failure, data.RedemptionEligibilityResult>> validateRedemptionEligibility({
    required String userId,
    required String optionId,
    required int pointsUsed,
  }) async => Either.right(
        data.RedemptionEligibilityResult(
          isEligible: false,
          violations: const ['Mock data source does not validate redemptions'],
          userPointBalance: 0,
          optionAvailable: false,
        ),
      );
}

/// Repository mock returning deterministic placeholder values.
class MockRedemptionRepository implements RedemptionRepository {
  @override
  Future<Either<Failure, int>> getAvailablePoints(String userId) async =>
      Either.right(0);

  @override
  Future<Either<Failure, bool>> canRedeem(String userId, int points) async =>
      Either.right(points <= 0 ? false : true);

  @override
  Future<Either<Failure, RedemptionTransaction>> cancelRedemption({
    required String transactionId,
    required String userId,
    required String reason,
  }) async => Either.left(const CacheFailure('Cancel redemption not implemented'));

  @override
  Future<Either<Failure, List<RedemptionOption>>> getRedemptionOptions() async =>
      Either.right(const <RedemptionOption>[]);

  @override
  Future<Either<Failure, List<RedemptionOption>>> getRedemptionOptionsByCategory({
    String? categoryId,
  }) async => Either.right(const <RedemptionOption>[]);

  @override
  Future<Either<Failure, PaginatedResult<RedemptionTransaction>>> getRedemptionHistory({
    required String userId,
    int page = 1,
    int limit = 20,
    RedemptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return Either.right(
      PaginatedResult<RedemptionTransaction>(
        items: const <RedemptionTransaction>[],
        totalCount: 0,
        currentPage: 1,
        hasNextPage: false,
      ),
    );
  }

  @override
  Future<Either<Failure, RedemptionTransaction>> getRedemptionTransaction({
    required String transactionId,
    required String userId,
  }) async {
    final now = DateTime.now();
    return Either.right(
      RedemptionTransaction(
        id: transactionId,
        userId: userId,
        optionId: 'mock_option',
        pointsUsed: 0,
        redeemedAt: now,
        status: RedemptionStatus.pending,
        createdAt: now,
      ),
    );
  }

  @override
  Future<Either<Failure, RedemptionStats>> getRedemptionStats({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async =>
      Either.right(const RedemptionStats(
        totalTransactions: 0,
        completedTransactions: 0,
        cancelledTransactions: 0,
        totalPointsRedeemed: 0,
      ));

  @override
  Stream<int> watchAvailablePoints(String userId) => Stream.value(0);

  @override
  Future<Either<Failure, RedemptionTransaction>> redeemPoints(
    RedemptionRequest request,
  ) async =>
      Either.right(
        RedemptionTransaction.create(
          userId: request.userId,
          optionId: request.optionId,
          pointsUsed: request.pointsToRedeem,
          notes: request.notes,
        ),
      );

  @override
  Future<Either<Failure, RedemptionTransaction>> updateTransactionStatus({
    required String transactionId,
    required RedemptionStatus newStatus,
    String? notes,
    required String userId,
  }) async {
    final now = DateTime.now();
    return Either.right(
      RedemptionTransaction(
        id: transactionId,
        userId: userId,
        optionId: 'mock_option',
        pointsUsed: 0,
        redeemedAt: now,
        status: newStatus,
        notes: notes,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<Either<Failure, RedemptionSyncResult>> syncRedemptions() async =>
      Either.right(
        RedemptionSyncResult(
          transactionsSynced: 0,
          optionsSynced: 0,
          conflictedTransactions: const [],
          syncTimestamp: DateTime.now(),
        ),
      );
}