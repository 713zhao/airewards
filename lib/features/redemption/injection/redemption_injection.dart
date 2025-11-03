import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import '../../../core/utils/either.dart';
import '../../../core/errors/failures.dart';
import '../../../core/models/paginated_result.dart';
import '../data/datasources/redemption_data_sources.dart';
import '../data/models/models.dart';
import '../data/repositories/redemption_repository_impl.dart';
import '../domain/entities/entities.dart';
import '../domain/repositories/redemption_repository.dart';
import '../domain/usecases/usecases.dart';
import '../presentation/bloc/redemption/redemption_bloc.dart';
import '../presentation/bloc/redemption_options/redemption_options_cubit.dart';

/// Dependency injection configuration for the redemption feature.
/// 
/// This module configures all dependencies for the redemption feature including:
/// - Data sources (local and remote)
/// - Repository implementations
/// - Use cases
/// - BLoC/Cubit instances
/// 
/// The module follows Clean Architecture principles by properly separating
/// concerns and ensuring dependencies flow inward (from data layer to domain).
@module
abstract class RedemptionInjectionModule {
  
  // ===== DATA SOURCES =====
  
  /// Provides local data source for offline redemption data
  /// 
  /// This singleton handles local storage, caching, and offline operations
  /// for redemption options and transactions.
  @lazySingleton
  RedemptionLocalDataSource get redemptionLocalDataSource =>
      MockRedemptionLocalDataSource();

  /// Provides remote data source for online redemption data
  /// 
  /// This singleton handles API communication, real-time updates,
  /// and server synchronization for redemption data.
  @lazySingleton
  RedemptionRemoteDataSource get redemptionRemoteDataSource =>
      MockRedemptionRemoteDataSource();

  // ===== REPOSITORIES =====
  
  /// Repository implementation is now registered automatically via @LazySingleton annotation
  /// The RedemptionRepositoryImpl class uses the @injectable annotation
  /// and will be registered automatically during code generation.

  // ===== USE CASES =====
  
  /// Provides use case for redeeming points
  /// 
  /// This factory creates a new instance for each request to ensure
  /// proper isolation of redemption operations.
  @factory
  RedeemPoints redeemPoints(RedemptionRepository repository) =>
      RedeemPoints(repository);

  /// Provides use case for getting redemption options
  /// 
  /// This factory creates instances for fetching and filtering
  /// available redemption options.
  @factory
  GetRedemptionOptions getRedemptionOptions(RedemptionRepository repository) =>
      GetRedemptionOptions(repository);

  /// Provides use case for getting redemption history
  /// 
  /// This factory creates instances for retrieving user's
  /// redemption transaction history with filtering and pagination.
  @factory
  GetRedemptionHistory getRedemptionHistory(RedemptionRepository repository) =>
      GetRedemptionHistory(repository);

  // ===== PRESENTATION LAYER =====
  
  /// Provides cubit for redemption options management
  /// 
  /// This factory creates cubit instances for managing redemption
  /// options state, filtering, and UI interactions.
  @factory
  RedemptionOptionsCubit redemptionOptionsCubit(
    GetRedemptionOptions getRedemptionOptionsUseCase,
  ) =>
      RedemptionOptionsCubit(
        getRedemptionOptionsUseCase: getRedemptionOptionsUseCase,
      );

  /// Provides BLoC for redemption transactions
  /// 
  /// This factory creates BLoC instances for managing redemption
  /// transactions, history, and related state management.
  @factory
  RedemptionBloc redemptionBloc(
    RedeemPoints redeemPointsUseCase,
    GetRedemptionHistory getRedemptionHistoryUseCase,
  ) =>
      RedemptionBloc(
        redeemPointsUseCase: redeemPointsUseCase,
        getRedemptionHistoryUseCase: getRedemptionHistoryUseCase,
      );
}

/// Extension methods for easy access to redemption dependencies
/// 
/// These extensions provide convenient access to redemption-related
/// dependencies from anywhere in the application.
extension RedemptionServiceLocator on GetIt {
  
  // ===== DATA LAYER =====
  
  /// Gets the redemption local data source
  RedemptionLocalDataSource get redemptionLocalDataSource =>
      get<RedemptionLocalDataSource>();

  /// Gets the redemption remote data source
  RedemptionRemoteDataSource get redemptionRemoteDataSource =>
      get<RedemptionRemoteDataSource>();

  /// Gets the redemption repository
  RedemptionRepository get redemptionRepository =>
      get<RedemptionRepository>();

  // ===== DOMAIN LAYER =====
  
  /// Gets the redeem points use case
  RedeemPoints get redeemPoints =>
      get<RedeemPoints>();

  /// Gets the get redemption options use case
  GetRedemptionOptions get getRedemptionOptions =>
      get<GetRedemptionOptions>();

  /// Gets the get redemption history use case
  GetRedemptionHistory get getRedemptionHistory =>
      get<GetRedemptionHistory>();

  // ===== PRESENTATION LAYER =====
  
  /// Gets a new redemption options cubit instance
  RedemptionOptionsCubit get redemptionOptionsCubit =>
      get<RedemptionOptionsCubit>();

  /// Gets a new redemption BLoC instance
  RedemptionBloc get redemptionBloc =>
      get<RedemptionBloc>();
}

/// Helper class for registering redemption dependencies manually
/// 
/// This class provides manual registration methods for scenarios
/// where @injectable annotations are not available or suitable.
class RedemptionDependencyRegistration {
  
  /// Registers all redemption dependencies manually
  /// 
  /// This method is useful for testing scenarios or when
  /// automatic dependency injection is not available.
  /// 
  /// Parameters:
  /// - [getIt]: The GetIt instance to register dependencies with
  /// - [useTestImplementations]: Whether to use test implementations
  static void registerAll(GetIt getIt, {bool useTestImplementations = false}) {
    // Register data sources
    if (!getIt.isRegistered<RedemptionLocalDataSource>()) {
      getIt.registerLazySingleton<RedemptionLocalDataSource>(
        () => MockRedemptionLocalDataSource(),
      );
    }

    if (!getIt.isRegistered<RedemptionRemoteDataSource>()) {
      getIt.registerLazySingleton<RedemptionRemoteDataSource>(
        () => useTestImplementations
            ? MockRedemptionRemoteDataSource()
            : RedemptionRemoteDataSourceImpl(),
      );
    }

    // Register repository
    if (!getIt.isRegistered<RedemptionRepository>()) {
      getIt.registerLazySingleton<RedemptionRepository>(
        () => RedemptionRepositoryImpl(
          localDataSource: getIt<RedemptionLocalDataSource>(),
          remoteDataSource: getIt<RedemptionRemoteDataSource>(),
        ),
      );
    }

    // Register use cases
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

    // Register presentation layer
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
        ),
      );
    }
  }

  /// Unregisters all redemption dependencies
  /// 
  /// This method is useful for cleaning up during testing
  /// or when resetting the dependency injection container.
  /// 
  /// Parameters:
  /// - [getIt]: The GetIt instance to unregister dependencies from
  static void unregisterAll(GetIt getIt) {
    // Unregister in reverse order of dependencies
    if (getIt.isRegistered<RedemptionBloc>()) {
      getIt.unregister<RedemptionBloc>();
    }

    if (getIt.isRegistered<RedemptionOptionsCubit>()) {
      getIt.unregister<RedemptionOptionsCubit>();
    }

    if (getIt.isRegistered<RedeemPoints>()) {
      getIt.unregister<RedeemPoints>();
    }

    if (getIt.isRegistered<GetRedemptionOptions>()) {
      getIt.unregister<GetRedemptionOptions>();
    }

    if (getIt.isRegistered<GetRedemptionHistory>()) {
      getIt.unregister<GetRedemptionHistory>();
    }

    if (getIt.isRegistered<RedemptionRepository>()) {
      getIt.unregister<RedemptionRepository>();
    }

    if (getIt.isRegistered<RedemptionLocalDataSource>()) {
      getIt.unregister<RedemptionLocalDataSource>();
    }

    if (getIt.isRegistered<RedemptionRemoteDataSource>()) {
      getIt.unregister<RedemptionRemoteDataSource>();
    }
  }

  /// Checks if all redemption dependencies are registered
  /// 
  /// This method is useful for validating the DI setup during
  /// application startup or in tests.
  /// 
  /// Parameters:
  /// - [getIt]: The GetIt instance to check
  /// 
  /// Returns: true if all dependencies are registered, false otherwise
  static bool areAllDependenciesRegistered(GetIt getIt) {
    return getIt.isRegistered<RedemptionLocalDataSource>() &&
           getIt.isRegistered<RedemptionRemoteDataSource>() &&
           getIt.isRegistered<RedemptionRepository>() &&
           getIt.isRegistered<RedeemPoints>() &&
           getIt.isRegistered<GetRedemptionOptions>() &&
           getIt.isRegistered<GetRedemptionHistory>() &&
           getIt.isRegistered<RedemptionOptionsCubit>() &&
           getIt.isRegistered<RedemptionBloc>();
  }

  /// Gets a health check summary of registered dependencies
  /// 
  /// This method provides detailed information about which
  /// redemption dependencies are registered and which are missing.
  /// 
  /// Parameters:
  /// - [getIt]: The GetIt instance to check
  /// 
  /// Returns: Map with dependency names and registration status
  static Map<String, bool> getDependencyHealthCheck(GetIt getIt) {
    return {
      'RedemptionLocalDataSource': getIt.isRegistered<RedemptionLocalDataSource>(),
      'RedemptionRemoteDataSource': getIt.isRegistered<RedemptionRemoteDataSource>(),
      'RedemptionRepository': getIt.isRegistered<RedemptionRepository>(),
      'RedeemPoints': getIt.isRegistered<RedeemPoints>(),
      'GetRedemptionOptions': getIt.isRegistered<GetRedemptionOptions>(),
      'GetRedemptionHistory': getIt.isRegistered<GetRedemptionHistory>(),
      'RedemptionOptionsCubit': getIt.isRegistered<RedemptionOptionsCubit>(),
      'RedemptionBloc': getIt.isRegistered<RedemptionBloc>(),
    };
  }
}

// ===== MOCK IMPLEMENTATIONS FOR TESTING =====

/// Mock implementation of local data source for testing
class MockRedemptionLocalDataSource implements RedemptionLocalDataSource {
  @override
  Future<void> cacheRedemptionOptions(List<RedemptionOption> options) async {
    // Mock implementation for testing
  }

  @override
  Future<List<RedemptionOption>> getCachedRedemptionOptions() async {
    return []; // Mock implementation
  }

  @override
  Future<void> cacheRedemptionTransaction(RedemptionTransaction transaction) async {
    // Mock implementation for testing
  }

  @override
  Future<List<RedemptionTransaction>> getCachedRedemptionHistory(String userId) async {
    return []; // Mock implementation
  }

  @override
  Future<void> clearCache() async {
    // Mock implementation for testing
  }

  @override
  Future<void> init() async {
    // Mock implementation for testing
  }

  @override
  Future<bool> isOnline() async {
    return false; // Mock offline for testing
  }

  @override
  Future<DateTime?> getLastSyncTimestamp() async {
    return null; // Mock implementation
  }

  @override
  Future<void> setLastSyncTimestamp(DateTime timestamp) async {
    // Mock implementation for testing
  }
}

/// Mock implementation of remote data source for testing
class MockRedemptionRemoteDataSource implements RedemptionRemoteDataSource {
  @override
  Future<List<RedemptionOption>> getRedemptionOptions({
    String? categoryId,
    int? minPoints,
    int? maxPoints,
  }) async {
    return []; // Mock implementation
  }

  @override
  Future<List<RedemptionOption>> getRedemptionOptionsByCategory({
    required String categoryId,
  }) async {
    return []; // Mock implementation
  }

  @override
  Future<RedemptionTransaction> redeemPoints({
    required String userId,
    required String optionId,
    required int pointsToRedeem,
    String? notes,
  }) async {
    throw UnimplementedError('Mock implementation');
  }

  @override
  Future<PaginatedResult<RedemptionTransactionWithDetails>> getRedemptionHistory({
    required String userId,
    int page = 1,
    int limit = 20,
    RedemptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return const PaginatedResult(
      items: [],
      totalCount: 0,
      page: 1,
      limit: 20,
      hasMore: false,
    );
  }

  @override
  Future<RedemptionStatistics> getRedemptionStatistics({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return const RedemptionStatistics(
      totalRedemptions: 0,
      totalPointsRedeemed: 0,
      averageRedemptionValue: 0.0,
      mostPopularCategory: null,
      redemptionsByStatus: {},
    );
  }

  @override
  Future<List<RedemptionOption>> searchRedemptionOptions({
    required String query,
    String? categoryId,
    int? minPoints,
    int? maxPoints,
  }) async {
    return []; // Mock implementation
  }

  @override
  Future<void> syncRedemptionData({
    required DateTime lastSyncTimestamp,
  }) async {
    // Mock implementation for testing
  }

  @override
  Future<void> subscribeToRealtimeUpdates({
    required void Function(RedemptionOption) onOptionUpdated,
    required void Function(RedemptionTransaction) onTransactionUpdated,
  }) async {
    // Mock implementation for testing
  }

  @override
  Future<void> unsubscribeFromRealtimeUpdates() async {
    // Mock implementation for testing
  }
}