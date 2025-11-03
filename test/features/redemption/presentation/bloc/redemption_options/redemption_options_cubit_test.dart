import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ai_rewards_system/core/utils/either.dart';
import 'package:ai_rewards_system/core/errors/failures.dart';
import 'package:ai_rewards_system/features/redemption/domain/entities/entities.dart';
import 'package:ai_rewards_system/features/redemption/domain/usecases/usecases.dart';
import 'package:ai_rewards_system/features/redemption/presentation/bloc/redemption_options/redemption_options_cubit.dart';
import 'package:ai_rewards_system/features/redemption/presentation/bloc/redemption_options/redemption_options_state.dart';

// Mock classes
class MockGetRedemptionOptions extends Mock implements GetRedemptionOptions {}

void main() {
  group('RedemptionOptionsCubit', () {
    late RedemptionOptionsCubit cubit;
    late MockGetRedemptionOptions mockGetRedemptionOptions;

    // Test data
    final testDateTime = DateTime.parse('2024-01-15T10:30:00Z');
    final testOption1 = RedemptionOption(
      id: 'option_1',
      title: 'Coffee Reward',
      description: 'Get a free coffee',
      categoryId: 'food',
      requiredPoints: 500,
      isActive: true,
      createdAt: testDateTime,
    );

    final testOption2 = RedemptionOption(
      id: 'option_2',
      title: 'Movie Ticket',
      description: 'Get a free movie ticket',
      categoryId: 'entertainment',
      requiredPoints: 1000,
      isActive: true,
      createdAt: testDateTime,
    );

    final testOptionWithContext1 = RedemptionOptionWithContext(
      option: testOption1,
      isPopular: true,
      difficulty: RedemptionDifficulty.easy,
      estimatedValue: 5.0,
    );

    final testOptionWithContext2 = RedemptionOptionWithContext(
      option: testOption2,
      isPopular: false,
      difficulty: RedemptionDifficulty.medium,
      estimatedValue: 10.0,
    );

    final testOptions = [testOptionWithContext1, testOptionWithContext2];

    setUp(() {
      mockGetRedemptionOptions = MockGetRedemptionOptions();
      cubit = RedemptionOptionsCubit(
        getRedemptionOptionsUseCase: mockGetRedemptionOptions,
      );

      // Register fallback values for mocktail
      registerFallbackValue(
        const GetRedemptionOptionsParams(
          categoryId: null,
          minPoints: null,
          maxPoints: null,
        ),
      );
    });

    tearDown(() {
      cubit.close();
    });

    group('initial state', () {
      test('should be RedemptionOptionsInitial', () {
        expect(cubit.state, equals(const RedemptionOptionsInitial()));
      });

      test('should have empty available options', () {
        expect(cubit.availableOptions, isEmpty);
      });

      test('should have empty available categories', () {
        expect(cubit.availableCategories, isEmpty);
      });

      test('should have zero points range', () {
        expect(cubit.pointsRange, equals(const PointsRange(min: 0, max: 0)));
      });

      test('should have no active filters', () {
        expect(cubit.hasActiveFilters, false);
      });
    });

    group('loadRedemptionOptions', () {
      blocTest<RedemptionOptionsCubit, RedemptionOptionsState>(
        'should emit [loading, loaded] when successful',
        build: () {
          when(() => mockGetRedemptionOptions(any()))
              .thenAnswer((_) async => Either.right(testOptions));
          return cubit;
        },
        act: (cubit) => cubit.loadRedemptionOptions(),
        expect: () => [
          const RedemptionOptionsLoading(),
          RedemptionOptionsLoaded(
            options: testOptions,
            isRefreshing: false,
          ),
        ],
        verify: (_) {
          verify(() => mockGetRedemptionOptions(any())).called(1);
        },
      );

      blocTest<RedemptionOptionsCubit, RedemptionOptionsState>(
        'should emit [loading, empty] when no options available',
        build: () {
          when(() => mockGetRedemptionOptions(any()))
              .thenAnswer((_) async => Either.right([]));
          return cubit;
        },
        act: (cubit) => cubit.loadRedemptionOptions(),
        expect: () => [
          const RedemptionOptionsLoading(),
          const RedemptionOptionsEmpty(
            message: 'No redemption options are currently available. Please check back later.',
            hasFilters: false,
          ),
        ],
      );

      blocTest<RedemptionOptionsCubit, RedemptionOptionsState>(
        'should emit [loading, error] when use case fails',
        build: () {
          when(() => mockGetRedemptionOptions(any()))
              .thenAnswer((_) async => Either.left(NetworkFailure('Network error')));
          return cubit;
        },
        act: (cubit) => cubit.loadRedemptionOptions(),
        expect: () => [
          const RedemptionOptionsLoading(),
          const RedemptionOptionsError(
            message: 'Network error',
            canRetry: true,
          ),
        ],
      );

      blocTest<RedemptionOptionsCubit, RedemptionOptionsState>(
        'should not reload if already loaded and not forcing refresh',
        build: () {
          when(() => mockGetRedemptionOptions(any()))
              .thenAnswer((_) async => Either.right(testOptions));
          return cubit;
        },
        seed: () => RedemptionOptionsLoaded(
          options: testOptions,
          isRefreshing: false,
        ),
        act: (cubit) => cubit.loadRedemptionOptions(),
        expect: () => [],
        verify: (_) {
          verifyNever(() => mockGetRedemptionOptions(any()));
        },
      );

      blocTest<RedemptionOptionsCubit, RedemptionOptionsState>(
        'should show refresh indicator when force refreshing',
        build: () {
          when(() => mockGetRedemptionOptions(any()))
              .thenAnswer((_) async => Either.right(testOptions));
          return cubit;
        },
        seed: () => RedemptionOptionsLoaded(
          options: testOptions,
          isRefreshing: false,
        ),
        act: (cubit) => cubit.loadRedemptionOptions(forceRefresh: true),
        expect: () => [
          RedemptionOptionsLoaded(
            options: testOptions,
            isRefreshing: true,
          ),
          RedemptionOptionsLoaded(
            options: testOptions,
            isRefreshing: false,
          ),
        ],
      );
    });

    group('refreshRedemptionOptions', () {
      blocTest<RedemptionOptionsCubit, RedemptionOptionsState>(
        'should force refresh options',
        build: () {
          when(() => mockGetRedemptionOptions(any()))
              .thenAnswer((_) async => Either.right(testOptions));
          return cubit;
        },
        act: (cubit) => cubit.refreshRedemptionOptions(),
        expect: () => [
          const RedemptionOptionsLoading(),
          RedemptionOptionsLoaded(
            options: testOptions,
            isRefreshing: false,
          ),
        ],
      );
    });

    group('filtering', () {
      final loadedState = RedemptionOptionsLoaded(
        options: testOptions,
        isRefreshing: false,
      );

      blocTest<RedemptionOptionsCubit, RedemptionOptionsState>(
        'filterByCategory should update selected category',
        build: () => cubit,
        seed: () => loadedState,
        act: (cubit) => cubit.filterByCategory('food'),
        expect: () => [
          RedemptionOptionsLoaded(
            options: testOptions,
            selectedCategory: 'food',
            isRefreshing: false,
          ),
        ],
      );

      blocTest<RedemptionOptionsCubit, RedemptionOptionsState>(
        'filterByPointsRange should update points filters',
        build: () => cubit,
        seed: () => loadedState,
        act: (cubit) => cubit.filterByPointsRange(minPoints: 100, maxPoints: 800),
        expect: () => [
          RedemptionOptionsLoaded(
            options: testOptions,
            minPoints: 100,
            maxPoints: 800,
            isRefreshing: false,
          ),
        ],
      );

      blocTest<RedemptionOptionsCubit, RedemptionOptionsState>(
        'searchRedemptionOptions should update search query',
        build: () => cubit,
        seed: () => loadedState,
        act: (cubit) => cubit.searchRedemptionOptions('coffee'),
        expect: () => [
          RedemptionOptionsLoaded(
            options: testOptions,
            searchQuery: 'coffee',
            isRefreshing: false,
          ),
        ],
      );

      blocTest<RedemptionOptionsCubit, RedemptionOptionsState>(
        'clearFilters should reset all filters',
        build: () => cubit,
        seed: () => RedemptionOptionsLoaded(
          options: testOptions,
          selectedCategory: 'food',
          minPoints: 100,
          maxPoints: 800,
          searchQuery: 'coffee',
          isRefreshing: false,
        ),
        act: (cubit) => cubit.clearFilters(),
        expect: () => [
          RedemptionOptionsLoaded(
            options: testOptions,
            selectedCategory: null,
            minPoints: null,
            maxPoints: null,
            searchQuery: null,
            isRefreshing: false,
          ),
        ],
      );

      blocTest<RedemptionOptionsCubit, RedemptionOptionsState>(
        'applyFilters should set multiple filters at once',
        build: () => cubit,
        seed: () => loadedState,
        act: (cubit) => cubit.applyFilters(
          category: 'food',
          minPoints: 100,
          maxPoints: 800,
          searchQuery: 'coffee',
        ),
        expect: () => [
          RedemptionOptionsLoaded(
            options: testOptions,
            selectedCategory: 'food',
            minPoints: 100,
            maxPoints: 800,
            searchQuery: 'coffee',
            isRefreshing: false,
          ),
        ],
      );
    });

    group('retry', () {
      blocTest<RedemptionOptionsCubit, RedemptionOptionsState>(
        'should force refresh when retrying',
        build: () {
          when(() => mockGetRedemptionOptions(any()))
              .thenAnswer((_) async => Either.right(testOptions));
          return cubit;
        },
        act: (cubit) => cubit.retry(),
        expect: () => [
          const RedemptionOptionsLoading(),
          RedemptionOptionsLoaded(
            options: testOptions,
            isRefreshing: false,
          ),
        ],
      );
    });

    group('getters', () {
      test('availableOptions should return filtered options when loaded', () {
        // Arrange
        final loadedState = RedemptionOptionsLoaded(
          options: testOptions,
          isRefreshing: false,
        );
        
        // Act
        cubit.emit(loadedState);

        // Assert
        expect(cubit.availableOptions, equals(testOptions));
      });

      test('availableCategories should return unique categories when loaded', () {
        // Arrange
        final loadedState = RedemptionOptionsLoaded(
          options: testOptions,
          isRefreshing: false,
        );
        
        // Act
        cubit.emit(loadedState);

        // Assert
        expect(cubit.availableCategories, containsAll(['food', 'entertainment']));
      });

      test('pointsRange should return correct range when loaded', () {
        // Arrange
        final loadedState = RedemptionOptionsLoaded(
          options: testOptions,
          isRefreshing: false,
        );
        
        // Act
        cubit.emit(loadedState);

        // Assert
        expect(cubit.pointsRange.min, 500);
        expect(cubit.pointsRange.max, 1000);
      });

      test('hasActiveFilters should return true when filters are applied', () {
        // Arrange
        final loadedStateWithFilters = RedemptionOptionsLoaded(
          options: testOptions,
          selectedCategory: 'food',
          isRefreshing: false,
        );
        
        // Act
        cubit.emit(loadedStateWithFilters);

        // Assert
        expect(cubit.hasActiveFilters, true);
      });

      test('filteredCount should return correct count', () {
        // Arrange
        final loadedState = RedemptionOptionsLoaded(
          options: testOptions,
          isRefreshing: false,
        );
        
        // Act
        cubit.emit(loadedState);

        // Assert
        expect(cubit.filteredCount, 2);
      });

      test('totalCount should return correct total', () {
        // Arrange
        final loadedState = RedemptionOptionsLoaded(
          options: testOptions,
          isRefreshing: false,
        );
        
        // Act
        cubit.emit(loadedState);

        // Assert
        expect(cubit.totalCount, 2);
      });
    });

    group('filtering when not loaded', () {
      blocTest<RedemptionOptionsCubit, RedemptionOptionsState>(
        'filterByCategory should load options with filter when not loaded',
        build: () {
          when(() => mockGetRedemptionOptions(any()))
              .thenAnswer((_) async => Either.right(testOptions));
          return cubit;
        },
        act: (cubit) => cubit.filterByCategory('food'),
        expect: () => [
          const RedemptionOptionsLoading(),
          RedemptionOptionsLoaded(
            options: testOptions,
            isRefreshing: false,
          ),
        ],
      );

      blocTest<RedemptionOptionsCubit, RedemptionOptionsState>(
        'filterByPointsRange should load options with filter when not loaded',
        build: () {
          when(() => mockGetRedemptionOptions(any()))
              .thenAnswer((_) async => Either.right(testOptions));
          return cubit;
        },
        act: (cubit) => cubit.filterByPointsRange(minPoints: 100, maxPoints: 800),
        expect: () => [
          const RedemptionOptionsLoading(),
          RedemptionOptionsLoaded(
            options: testOptions,
            isRefreshing: false,
          ),
        ],
      );

      blocTest<RedemptionOptionsCubit, RedemptionOptionsState>(
        'searchRedemptionOptions should load options with search when not loaded',
        build: () {
          when(() => mockGetRedemptionOptions(any()))
              .thenAnswer((_) async => Either.right(testOptions));
          return cubit;
        },
        act: (cubit) => cubit.searchRedemptionOptions('coffee'),
        expect: () => [
          const RedemptionOptionsLoading(),
          RedemptionOptionsLoaded(
            options: testOptions,
            isRefreshing: false,
          ),
        ],
      );
    });
  });
}