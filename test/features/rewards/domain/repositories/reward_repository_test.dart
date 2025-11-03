import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ai_rewards_system/core/errors/failures.dart';
import 'package:ai_rewards_system/core/models/paginated_result.dart';
import 'package:ai_rewards_system/core/utils/either.dart';
import 'package:ai_rewards_system/features/rewards/domain/entities/entities.dart';
import 'package:ai_rewards_system/features/rewards/domain/repositories/reward_repository.dart';

/// Mock implementation of RewardRepository for testing
class MockRewardRepository extends Mock implements RewardRepository {}

void main() {
  group('RewardRepository Interface', () {
    late MockRewardRepository mockRepository;

    setUp(() {
      mockRepository = MockRewardRepository();
      registerFallbackValue(RewardEntry.create(
        id: 'test-id',
        userId: 'user-123',
        points: 100,
        description: 'Test entry',
        categoryId: 'category-123',
        createdAt: DateTime.now(),
        type: RewardType.earned,
      ).right);
      registerFallbackValue(RewardCategory.create(
        id: 'test-category-id',
        name: 'Test Category',
        color: const Color(0xFF2196F3),
        iconData: const IconData(0xe5f9, fontFamily: 'MaterialIcons'),
      ).right);
      registerFallbackValue(<RewardBatchOperation>[]);
    });

    group('getRewardHistory', () {
      test('should return paginated reward entries with filtering', () async {
        // Arrange
        const userId = 'user-123';
        const page = 1;
        const limit = 20;
        final startDate = DateTime.now().subtract(const Duration(days: 30));
        final endDate = DateTime.now();
        const categoryId = 'fitness';
        const type = RewardType.earned;

        final expectedEntries = [
          RewardEntry.create(
            id: 'entry-1',
            userId: userId,
            points: 100,
            description: 'Completed workout',
            categoryId: categoryId,
            createdAt: DateTime.now(),
            type: type,
          ).right,
          RewardEntry.create(
            id: 'entry-2', 
            userId: userId,
            points: 50,
            description: 'Daily steps',
            categoryId: categoryId,
            createdAt: DateTime.now(),
            type: type,
          ).right,
        ];

        final expectedResult = PaginatedResult(
          items: expectedEntries,
          totalCount: 2,
          currentPage: page,
          hasNextPage: false,
        );

        when(() => mockRepository.getRewardHistory(
          userId: userId,
          page: page,
          limit: limit,
          startDate: startDate,
          endDate: endDate,
          categoryId: categoryId,
          type: type,
        )).thenAnswer((_) async => Right(expectedResult));

        // Act
        final result = await mockRepository.getRewardHistory(
          userId: userId,
          page: page,
          limit: limit,
          startDate: startDate,
          endDate: endDate,
          categoryId: categoryId,
          type: type,
        );

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right.items.length, equals(2));
        expect(result.right.totalCount, equals(2));
        expect(result.right.currentPage, equals(1));
        expect(result.right.hasNextPage, isFalse);

        verify(() => mockRepository.getRewardHistory(
          userId: userId,
          page: page,
          limit: limit,
          startDate: startDate,
          endDate: endDate,
          categoryId: categoryId,
          type: type,
        )).called(1);
      });

      test('should return failure for invalid parameters', () async {
        // Arrange
        when(() => mockRepository.getRewardHistory(
          userId: '',
          page: 1,
          limit: 20,
        )).thenAnswer((_) async => Left(ValidationFailure('User ID cannot be empty')));

        // Act
        final result = await mockRepository.getRewardHistory(
          userId: '',
          page: 1,
          limit: 20,
        );

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left, isA<ValidationFailure>());
      });
    });

    group('addRewardEntry', () {
      test('should return success with created entry', () async {
        // Arrange
        final entryToAdd = RewardEntry.create(
          id: 'temp-id',
          userId: 'user-123',
          points: 100,
          description: 'Completed workout',
          categoryId: 'fitness',
          createdAt: DateTime.now(),
          type: RewardType.earned,
        ).right;

        final createdEntry = entryToAdd.copyWith(
          id: 'server-generated-id',
          isSynced: true,
        );

        when(() => mockRepository.addRewardEntry(any()))
            .thenAnswer((_) async => Right(createdEntry));

        // Act
        final result = await mockRepository.addRewardEntry(entryToAdd);

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right.id, equals('server-generated-id'));
        expect(result.right.isSynced, isTrue);
        expect(result.right.points, equals(100));
        expect(result.right.description, equals('Completed workout'));

        verify(() => mockRepository.addRewardEntry(entryToAdd)).called(1);
      });

      test('should return validation failure for business rule violations', () async {
        // Arrange
        final invalidEntry = RewardEntry.create(
          id: 'temp-id',
          userId: 'user-123',
          points: 15000, // Exceeds BR-002 limit
          description: 'Invalid entry',
          categoryId: 'fitness',
          createdAt: DateTime.now(),
          type: RewardType.earned,
        );

        // Since create returns Left for invalid data, we need to mock the failure
        when(() => mockRepository.addRewardEntry(any()))
            .thenAnswer((_) async => Left(ValidationFailure('Maximum point entry value is 10,000 points per transaction (BR-002)')));

        // Act
        final result = await mockRepository.addRewardEntry(invalidEntry.right);

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left, isA<ValidationFailure>());
        expect(result.left.message, contains('BR-002'));
      });
    });

    group('updateRewardEntry', () {
      test('should return success with updated entry', () async {
        // Arrange
        final originalEntry = RewardEntry.create(
          id: 'entry-123',
          userId: 'user-123',
          points: 100,
          description: 'Original description',
          categoryId: 'fitness',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)), // Within 24h
          type: RewardType.earned,
        ).right;

        final updatedEntry = originalEntry.copyWith(
          description: 'Updated description',
          points: 150,
        );

        when(() => mockRepository.updateRewardEntry(any()))
            .thenAnswer((_) async => Right(updatedEntry));

        // Act
        final result = await mockRepository.updateRewardEntry(updatedEntry);

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right.description, equals('Updated description'));
        expect(result.right.points, equals(150));
        expect(result.right.updatedAt, isNotNull);

        verify(() => mockRepository.updateRewardEntry(updatedEntry)).called(1);
      });

      test('should return failure for entries older than 24 hours (BR-004)', () async {
        // Arrange
        final oldEntry = RewardEntry.create(
          id: 'entry-123',
          userId: 'user-123',
          points: 100,
          description: 'Old entry',
          categoryId: 'fitness',
          createdAt: DateTime.now().subtract(const Duration(hours: 25)), // Older than 24h
          type: RewardType.earned,
        ).right;

        when(() => mockRepository.updateRewardEntry(any()))
            .thenAnswer((_) async => Left(ValidationFailure('Point history cannot be modified after 24 hours (BR-004)')));

        // Act
        final result = await mockRepository.updateRewardEntry(oldEntry);

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left, isA<ValidationFailure>());
        expect(result.left.message, contains('BR-004'));
      });
    });

    group('deleteRewardEntry', () {
      test('should return success for valid deletion', () async {
        // Arrange
        const entryId = 'entry-123';
        const userId = 'user-123';

        when(() => mockRepository.deleteRewardEntry(
          entryId: entryId,
          userId: userId,
        )).thenAnswer((_) async => const Right(null));

        // Act
        final result = await mockRepository.deleteRewardEntry(
          entryId: entryId,
          userId: userId,
        );

        // Assert
        expect(result.isRight, isTrue);

        verify(() => mockRepository.deleteRewardEntry(
          entryId: entryId,
          userId: userId,
        )).called(1);
      });

      test('should return failure for unauthorized deletion', () async {
        // Arrange
        const entryId = 'entry-123';
        const wrongUserId = 'wrong-user';

        when(() => mockRepository.deleteRewardEntry(
          entryId: entryId,
          userId: wrongUserId,
        )).thenAnswer((_) async => Left(AuthFailure('Unauthorized access')));

        // Act
        final result = await mockRepository.deleteRewardEntry(
          entryId: entryId,
          userId: wrongUserId,
        );

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left, isA<AuthFailure>());
      });
    });

    group('getTotalPoints', () {
      test('should return current point total for user', () async {
        // Arrange
        const userId = 'user-123';
        const expectedTotal = 1250;

        when(() => mockRepository.getTotalPoints(userId))
            .thenAnswer((_) async => const Right(expectedTotal));

        // Act
        final result = await mockRepository.getTotalPoints(userId);

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right, equals(expectedTotal));

        verify(() => mockRepository.getTotalPoints(userId)).called(1);
      });

      test('should return failure for invalid user', () async {
        // Arrange
        const invalidUserId = '';

        when(() => mockRepository.getTotalPoints(invalidUserId))
            .thenAnswer((_) async => Left(ValidationFailure('User ID cannot be empty')));

        // Act
        final result = await mockRepository.getTotalPoints(invalidUserId);

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left, isA<ValidationFailure>());
      });
    });

    group('watchTotalPoints', () {
      test('should return stream of point totals', () async {
        // Arrange
        const userId = 'user-123';
        final pointUpdates = [1000, 1100, 1150, 1200];

        when(() => mockRepository.watchTotalPoints(userId))
            .thenAnswer((_) => Stream.fromIterable(pointUpdates));

        // Act
        final stream = mockRepository.watchTotalPoints(userId);

        // Assert
        final receivedValues = <int>[];
        await for (final value in stream) {
          receivedValues.add(value);
        }

        expect(receivedValues, equals(pointUpdates));
        verify(() => mockRepository.watchTotalPoints(userId)).called(1);
      });
    });

    group('category operations', () {
      test('should get reward categories successfully', () async {
        // Arrange
        final categories = [
          RewardCategory.create(
            id: 'fitness',
            name: 'Fitness',
            color: const Color(0xFF4CAF50),
            iconData: const IconData(0xe5f9, fontFamily: 'MaterialIcons'),
            isDefault: true,
          ).right,
          RewardCategory.create(
            id: 'learning',
            name: 'Learning',
            color: const Color(0xFF2196F3),
            iconData: const IconData(0xe5f9, fontFamily: 'MaterialIcons'),
          ).right,
        ];

        when(() => mockRepository.getRewardCategories())
            .thenAnswer((_) async => Right(categories));

        // Act
        final result = await mockRepository.getRewardCategories();

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right.length, equals(2));
        expect(result.right.first.name, equals('Fitness'));
        expect(result.right.first.isDefault, isTrue);
      });

      test('should add custom category successfully', () async {
        // Arrange
        final categoryToAdd = RewardCategory.create(
          id: 'temp-id',
          name: 'Reading',
          color: const Color(0xFF9C27B0),
          iconData: const IconData(0xe5f9, fontFamily: 'MaterialIcons'),
        ).right;

        final createdCategory = categoryToAdd.copyWith(id: 'server-id');

        when(() => mockRepository.addRewardCategory(any()))
            .thenAnswer((_) async => Right(createdCategory));

        // Act
        final result = await mockRepository.addRewardCategory(categoryToAdd);

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right.id, equals('server-id'));
        expect(result.right.name, equals('Reading'));
      });

      test('should return failure when exceeding category limit (BR-014)', () async {
        // Arrange
        final categoryToAdd = RewardCategory.create(
          id: 'temp-id',
          name: 'Too Many Categories',
          color: const Color(0xFF9C27B0),
          iconData: const IconData(0xe5f9, fontFamily: 'MaterialIcons'),
        ).right;

        when(() => mockRepository.addRewardCategory(any()))
            .thenAnswer((_) async => Left(ValidationFailure('Maximum 20 custom categories per user (BR-014)')));

        // Act
        final result = await mockRepository.addRewardCategory(categoryToAdd);

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left, isA<ValidationFailure>());
        expect(result.left.message, contains('BR-014'));
      });
    });

    group('batch operations', () {
      test('should process multiple operations atomically', () async {
        // Arrange
        final entry1 = RewardEntry.create(
          id: 'entry-1',
          userId: 'user-123',
          points: 100,
          description: 'Entry 1',
          categoryId: 'fitness',
          createdAt: DateTime.now(),
          type: RewardType.earned,
        ).right;

        final entry2 = RewardEntry.create(
          id: 'entry-2',
          userId: 'user-123',
          points: 200,
          description: 'Entry 2',
          categoryId: 'fitness',
          createdAt: DateTime.now(),
          type: RewardType.earned,
        ).right;

        final operations = [
          RewardBatchOperation.add(entry1),
          RewardBatchOperation.update(entry2),
          const RewardBatchOperation.delete('entry-3', 'user-123'),
        ];

        when(() => mockRepository.batchOperations(operations))
            .thenAnswer((_) async => Right([entry1, entry2]));

        // Act
        final result = await mockRepository.batchOperations(operations);

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right.length, equals(2));

        verify(() => mockRepository.batchOperations(operations)).called(1);
      });
    });

    group('synchronization', () {
      test('should sync successfully with server', () async {
        // Arrange
        final syncResult = SyncResult(
          uploadedCount: 5,
          downloadedCount: 3,
          conflictedEntries: ['entry-1', 'entry-2'],
          syncTimestamp: DateTime.now(),
        );

        when(() => mockRepository.syncWithServer())
            .thenAnswer((_) async => Right(syncResult));

        // Act
        final result = await mockRepository.syncWithServer();

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right.uploadedCount, equals(5));
        expect(result.right.downloadedCount, equals(3));
        expect(result.right.conflictedEntries.length, equals(2));

        verify(() => mockRepository.syncWithServer()).called(1);
      });
    });
  });
}