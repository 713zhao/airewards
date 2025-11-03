import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ai_rewards_system/features/shared/data/datasources/local/database_helper.dart';

void main() {
  group('DatabaseHelper', () {
    late DatabaseHelper databaseHelper;

    setUpAll(() {
      // Initialize sqflite_ffi for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() {
      databaseHelper = DatabaseHelper.instance;
    });

    tearDown(() async {
      // Clean up after each test
      await databaseHelper.close();
      await databaseHelper.deleteDatabase();
    });

    test('should initialize database successfully', () async {
      // Act
      final db = await databaseHelper.database;

      // Assert
      expect(db, isNotNull);
      expect(db.isOpen, isTrue);
    });

    test('should create all required tables', () async {
      // Act
      final db = await databaseHelper.database;
      
      // Check that all tables exist
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'"
      );
      
      final tableNames = tables.map((table) => table['name'] as String).toList();
      
      // Assert
      expect(tableNames, contains(DatabaseHelper.tableUsers));
      expect(tableNames, contains(DatabaseHelper.tableRewardEntries));
      expect(tableNames, contains(DatabaseHelper.tableCategories));
      expect(tableNames, contains(DatabaseHelper.tableRedemptionOptions));
      expect(tableNames, contains(DatabaseHelper.tableRedemptionTransactions));
      expect(tableNames, contains(DatabaseHelper.tableSyncQueue));
    });

    test('should create default categories', () async {
      // Act
      final db = await databaseHelper.database;
      final categories = await db.query(DatabaseHelper.tableCategories);
      
      // Assert
      expect(categories.length, equals(6));
      
      // Check for specific default categories
      final categoryNames = categories.map((cat) => cat['name'] as String).toList();
      expect(categoryNames, contains('Exercise'));
      expect(categoryNames, contains('Learning'));
      expect(categoryNames, contains('Productivity'));
      expect(categoryNames, contains('Social'));
      expect(categoryNames, contains('Health'));
      expect(categoryNames, contains('General'));
    });

    test('should perform CRUD operations correctly', () async {
      // Arrange
      final testData = {
        'id': 'test_user_1',
        'email': 'test@example.com',
        'display_name': 'Test User',
        'provider': 'email',
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'is_active': 1,
        'total_points': 0,
        'sync_status': 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'version': 1,
      };

      // Act & Assert - Insert
      final insertResult = await databaseHelper.insertRecord(
        DatabaseHelper.tableUsers,
        testData,
      );
      expect(insertResult, isPositive);

      // Act & Assert - Query
      final queryResult = await databaseHelper.queryRecords(
        DatabaseHelper.tableUsers,
        where: 'id = ?',
        whereArgs: ['test_user_1'],
      );
      expect(queryResult.length, equals(1));
      expect(queryResult.first['email'], equals('test@example.com'));

      // Act & Assert - Update
      final updateResult = await databaseHelper.updateRecord(
        DatabaseHelper.tableUsers,
        {'display_name': 'Updated User'},
        where: 'id = ?',
        whereArgs: ['test_user_1'],
      );
      expect(updateResult, equals(1));

      // Verify update
      final updatedQuery = await databaseHelper.queryRecords(
        DatabaseHelper.tableUsers,
        where: 'id = ?',
        whereArgs: ['test_user_1'],
      );
      expect(updatedQuery.first['display_name'], equals('Updated User'));

      // Act & Assert - Delete
      final deleteResult = await databaseHelper.deleteRecord(
        DatabaseHelper.tableUsers,
        where: 'id = ?',
        whereArgs: ['test_user_1'],
      );
      expect(deleteResult, equals(1));

      // Verify deletion
      final deletedQuery = await databaseHelper.queryRecords(
        DatabaseHelper.tableUsers,
        where: 'id = ?',
        whereArgs: ['test_user_1'],
      );
      expect(deletedQuery.length, equals(0));
    });

    test('should handle transactions correctly', () async {
      // Arrange
      final testData1 = {
        'id': 'test_user_1',
        'email': 'test1@example.com',
        'display_name': 'Test User 1',
        'provider': 'email',
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'is_active': 1,
        'total_points': 0,
        'sync_status': 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'version': 1,
      };

      final testData2 = {
        'id': 'test_user_2',
        'email': 'test2@example.com',
        'display_name': 'Test User 2',
        'provider': 'email',
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'is_active': 1,
        'total_points': 0,
        'sync_status': 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'version': 1,
      };

      // Act - Execute transaction
      await databaseHelper.executeTransaction((txn) async {
        await txn.insert(DatabaseHelper.tableUsers, testData1);
        await txn.insert(DatabaseHelper.tableUsers, testData2);
        return true;
      });

      // Assert
      final users = await databaseHelper.queryRecords(DatabaseHelper.tableUsers);
      expect(users.length, equals(2));
    });

    test('should get database statistics', () async {
      // Act
      final db = await databaseHelper.database;
      final stats = await databaseHelper.getDatabaseStats();
      
      // Assert
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats, containsPair('user_count', 0));
      expect(stats, containsPair('category_count', 6)); // Default categories
      expect(stats, containsPair('reward_entry_count', 0));
      expect(stats, containsPair('redemption_option_count', 0));
      expect(stats, containsPair('redemption_transaction_count', 0));
      expect(stats, containsPair('sync_queue_count', 0));
      expect(stats, contains('size_bytes'));
      expect(stats, contains('size_mb'));
    });
  });
}