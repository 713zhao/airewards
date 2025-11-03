import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:injectable/injectable.dart';
import 'database_migrations.dart';

/// Comprehensive SQLite database helper for the AI Rewards System.
/// 
/// This class provides a centralized interface for all database operations
/// following Clean Architecture principles. It handles database initialization,
/// migrations, transactions, and provides type-safe CRUD operations.
/// 
/// Key features:
/// - Automatic migrations and schema versioning
/// - Transaction support for atomic operations
/// - Connection pooling and performance optimization
/// - Comprehensive error handling and logging
/// - Index management for query performance
/// - Backup and recovery support
/// 
/// Database schema includes:
/// - Users table for authentication data
/// - Reward entries for point earning history
/// - Categories for reward organization
/// - Redemption options for available rewards
/// - Redemption transactions for redemption history
/// - Sync queue for offline operation management
@lazySingleton
class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;
  
  // Database configuration
  static const String _databaseName = 'ai_rewards.db';
  static const int _databaseVersion = 1;

  // Table names - centralized for consistency
  static const String tableUsers = 'users';
  static const String tableRewardEntries = 'reward_entries';
  static const String tableCategories = 'categories';
  static const String tableRedemptionOptions = 'redemption_options';
  static const String tableRedemptionTransactions = 'redemption_transactions';
  static const String tableSyncQueue = 'sync_queue';
  
  /// Private constructor for singleton pattern
  DatabaseHelper._privateConstructor();
  
  /// Singleton instance getter
  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._privateConstructor();
    return _instance!;
  }
  
  /// Gets the database instance, initializing if necessary
  Future<Database> get database async {
    _database ??= await _initializeDatabase();
    return _database!;
  }

  /// Initialize the database with schema and migrations
  Future<Database> _initializeDatabase() async {
    try {
      final documentsDirectory = await getDatabasesPath();
      final path = join(documentsDirectory, _databaseName);
      
      // Enable Write-Ahead Logging for better concurrent access
      final database = await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onDowngrade: _onDowngrade,
        onConfigure: _onConfigure,
        onOpen: _onOpen,
      );
      
      return database;
    } catch (e) {
      throw DatabaseException('Failed to initialize database: $e');
    }
  }

  /// Configure database settings before opening
  Future<void> _onConfigure(Database db) async {
    // Enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');
    
    // Enable Write-Ahead Logging for better performance
    await db.execute('PRAGMA journal_mode = WAL');
    
    // Set synchronous mode for better performance with safety
    await db.execute('PRAGMA synchronous = NORMAL');
    
    // Set cache size for better query performance (negative value = KB)
    await db.execute('PRAGMA cache_size = -2000'); // 2MB cache
    
    // Set temp store in memory for better performance
    await db.execute('PRAGMA temp_store = MEMORY');
  }

  /// Create initial database schema
  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    
    try {
      // Create all tables
      await _createUsersTable(batch);
      await _createRewardEntriesTable(batch);
      await _createCategoriesTable(batch);
      await _createRedemptionOptionsTable(batch);
      await _createRedemptionTransactionsTable(batch);
      await _createSyncQueueTable(batch);
      
      // Create indexes for performance
      await _createIndexes(batch);
      
      // Insert default data
      await _insertDefaultData(batch);
      
      // Execute all operations atomically
      await batch.commit();
      
      print('Database created successfully with version $version');
    } catch (e) {
      print('Error creating database: $e');
      rethrow;
    }
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');
    
    try {
      final migrations = DatabaseMigrations.getMigrations(oldVersion, newVersion);
      
      for (final migration in migrations) {
        print('Applying migration: ${migration.description}');
        await migration.apply(db);
      }
      
      print('Database upgrade completed successfully');
    } catch (e) {
      print('Error upgrading database: $e');
      rethrow;
    }
  }

  /// Handle database downgrades (usually not recommended in production)
  Future<void> _onDowngrade(Database db, int oldVersion, int newVersion) async {
    print('WARNING: Downgrading database from version $oldVersion to $newVersion');
    // In production, you might want to prevent downgrades or handle them carefully
    throw DatabaseException('Database downgrade not supported');
  }

  /// Called when database is opened
  Future<void> _onOpen(Database db) async {
    print('Database opened successfully');
    
    // Verify database integrity
    final result = await db.rawQuery('PRAGMA integrity_check');
    if (result.first['integrity_check'] != 'ok') {
      throw DatabaseException('Database integrity check failed');
    }
    
    // Verify foreign key constraints are working
    final fkResult = await db.rawQuery('PRAGMA foreign_key_check');
    if (fkResult.isNotEmpty) {
      throw DatabaseException('Foreign key constraints validation failed');
    }
  }

  /// Create users table for authentication data
  Future<void> _createUsersTable(Batch batch) async {
    batch.execute('''
      CREATE TABLE $tableUsers (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL UNIQUE,
        display_name TEXT,
        photo_url TEXT,
        provider TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        last_login_at INTEGER,
        is_active INTEGER NOT NULL DEFAULT 1,
        total_points INTEGER NOT NULL DEFAULT 0,
        sync_status INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL,
        version INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  /// Create reward entries table for point earning history
  Future<void> _createRewardEntriesTable(Batch batch) async {
    batch.execute('''
      CREATE TABLE $tableRewardEntries (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        points INTEGER NOT NULL,
        category_id TEXT NOT NULL,
        reward_type INTEGER NOT NULL,
        earned_date INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        sync_status INTEGER NOT NULL DEFAULT 0,
        version INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES $tableUsers (id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES $tableCategories (id) ON DELETE RESTRICT
      )
    ''');
  }

  /// Create categories table for reward organization
  Future<void> _createCategoriesTable(Batch batch) async {
    batch.execute('''
      CREATE TABLE $tableCategories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        color_value INTEGER NOT NULL,
        icon_code_point INTEGER NOT NULL,
        icon_font_family TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        sync_status INTEGER NOT NULL DEFAULT 0,
        version INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  /// Create redemption options table for available rewards
  Future<void> _createRedemptionOptionsTable(Batch batch) async {
    batch.execute('''
      CREATE TABLE $tableRedemptionOptions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        required_points INTEGER NOT NULL,
        category_id TEXT,
        image_url TEXT,
        terms_conditions TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        expires_at INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        sync_status INTEGER NOT NULL DEFAULT 0,
        version INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (category_id) REFERENCES $tableCategories (id) ON DELETE SET NULL
      )
    ''');
  }

  /// Create redemption transactions table for redemption history
  Future<void> _createRedemptionTransactionsTable(Batch batch) async {
    batch.execute('''
      CREATE TABLE $tableRedemptionTransactions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        option_id TEXT NOT NULL,
        points_used INTEGER NOT NULL,
        status INTEGER NOT NULL,
        notes TEXT,
        redeemed_at INTEGER NOT NULL,
        completed_at INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        sync_status INTEGER NOT NULL DEFAULT 0,
        version INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES $tableUsers (id) ON DELETE CASCADE,
        FOREIGN KEY (option_id) REFERENCES $tableRedemptionOptions (id) ON DELETE RESTRICT
      )
    ''');
  }

  /// Create sync queue table for offline operation management
  Future<void> _createSyncQueueTable(Batch batch) async {
    batch.execute('''
      CREATE TABLE $tableSyncQueue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation_type TEXT NOT NULL,
        data_json TEXT NOT NULL,
        priority INTEGER NOT NULL DEFAULT 0,
        retry_count INTEGER NOT NULL DEFAULT 0,
        max_retries INTEGER NOT NULL DEFAULT 3,
        last_error TEXT,
        created_at INTEGER NOT NULL,
        scheduled_at INTEGER NOT NULL,
        UNIQUE(entity_type, entity_id, operation_type)
      )
    ''');
  }

  /// Create performance indexes
  Future<void> _createIndexes(Batch batch) async {
    // Users table indexes
    batch.execute('CREATE INDEX idx_users_email ON $tableUsers (email)');
    batch.execute('CREATE INDEX idx_users_provider ON $tableUsers (provider)');
    batch.execute('CREATE INDEX idx_users_sync_status ON $tableUsers (sync_status)');
    
    // Reward entries table indexes
    batch.execute('CREATE INDEX idx_reward_entries_user_id ON $tableRewardEntries (user_id)');
    batch.execute('CREATE INDEX idx_reward_entries_category_id ON $tableRewardEntries (category_id)');
    batch.execute('CREATE INDEX idx_reward_entries_earned_date ON $tableRewardEntries (earned_date DESC)');
    batch.execute('CREATE INDEX idx_reward_entries_sync_status ON $tableRewardEntries (sync_status)');
    batch.execute('CREATE INDEX idx_reward_entries_user_date ON $tableRewardEntries (user_id, earned_date DESC)');
    
    // Categories table indexes
    batch.execute('CREATE INDEX idx_categories_name ON $tableCategories (name)');
    batch.execute('CREATE INDEX idx_categories_sync_status ON $tableCategories (sync_status)');
    
    // Redemption options table indexes
    batch.execute('CREATE INDEX idx_redemption_options_active ON $tableRedemptionOptions (is_active)');
    batch.execute('CREATE INDEX idx_redemption_options_category ON $tableRedemptionOptions (category_id)');
    batch.execute('CREATE INDEX idx_redemption_options_points ON $tableRedemptionOptions (required_points)');
    batch.execute('CREATE INDEX idx_redemption_options_expires ON $tableRedemptionOptions (expires_at)');
    batch.execute('CREATE INDEX idx_redemption_options_sync_status ON $tableRedemptionOptions (sync_status)');
    
    // Redemption transactions table indexes
    batch.execute('CREATE INDEX idx_redemption_transactions_user_id ON $tableRedemptionTransactions (user_id)');
    batch.execute('CREATE INDEX idx_redemption_transactions_option_id ON $tableRedemptionTransactions (option_id)');
    batch.execute('CREATE INDEX idx_redemption_transactions_status ON $tableRedemptionTransactions (status)');
    batch.execute('CREATE INDEX idx_redemption_transactions_redeemed_at ON $tableRedemptionTransactions (redeemed_at DESC)');
    batch.execute('CREATE INDEX idx_redemption_transactions_user_date ON $tableRedemptionTransactions (user_id, redeemed_at DESC)');
    batch.execute('CREATE INDEX idx_redemption_transactions_sync_status ON $tableRedemptionTransactions (sync_status)');
    
    // Sync queue table indexes
    batch.execute('CREATE INDEX idx_sync_queue_entity ON $tableSyncQueue (entity_type, entity_id)');
    batch.execute('CREATE INDEX idx_sync_queue_priority ON $tableSyncQueue (priority DESC, created_at)');
    batch.execute('CREATE INDEX idx_sync_queue_scheduled ON $tableSyncQueue (scheduled_at)');
  }

  /// Insert default categories and essential data
  Future<void> _insertDefaultData(Batch batch) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Default categories
    final defaultCategories = [
      {
        'id': 'cat_exercise',
        'name': 'Exercise',
        'description': 'Physical activities and workouts',
        'color_value': 0xFF4CAF50,
        'icon_code_point': 0xe566, // fitness_center
        'icon_font_family': 'MaterialIcons',
        'is_default': 1,
        'created_at': now,
        'updated_at': now,
        'sync_status': 1,
        'version': 1,
      },
      {
        'id': 'cat_learning',
        'name': 'Learning',
        'description': 'Educational activities and skill development',
        'color_value': 0xFF2196F3,
        'icon_code_point': 0xe80c, // school
        'icon_font_family': 'MaterialIcons',
        'is_default': 1,
        'created_at': now,
        'updated_at': now,
        'sync_status': 1,
        'version': 1,
      },
      {
        'id': 'cat_productivity',
        'name': 'Productivity',
        'description': 'Work and productivity achievements',
        'color_value': 0xFFFF9800,
        'icon_code_point': 0xe8f4, // work
        'icon_font_family': 'MaterialIcons',
        'is_default': 1,
        'created_at': now,
        'updated_at': now,
        'sync_status': 1,
        'version': 1,
      },
      {
        'id': 'cat_social',
        'name': 'Social',
        'description': 'Social activities and community involvement',
        'color_value': 0xFFE91E63,
        'icon_code_point': 0xe7fb, // people
        'icon_font_family': 'MaterialIcons',
        'is_default': 1,
        'created_at': now,
        'updated_at': now,
        'sync_status': 1,
        'version': 1,
      },
      {
        'id': 'cat_health',
        'name': 'Health',
        'description': 'Health and wellness activities',
        'color_value': 0xFFF44336,
        'icon_code_point': 0xe3e0, // favorite
        'icon_font_family': 'MaterialIcons',
        'is_default': 1,
        'created_at': now,
        'updated_at': now,
        'sync_status': 1,
        'version': 1,
      },
      {
        'id': 'cat_general',
        'name': 'General',
        'description': 'General activities and achievements',
        'color_value': 0xFF9C27B0,
        'icon_code_point': 0xe886, // star
        'icon_font_family': 'MaterialIcons',
        'is_default': 1,
        'created_at': now,
        'updated_at': now,
        'sync_status': 1,
        'version': 1,
      },
    ];
    
    for (final category in defaultCategories) {
      batch.insert(tableCategories, category);
    }
  }

  /// Execute a transaction with proper error handling
  Future<T> executeTransaction<T>(
    Future<T> Function(Transaction txn) action,
  ) async {
    final db = await database;
    try {
      return await db.transaction(action);
    } catch (e) {
      throw DatabaseException('Transaction failed: $e');
    }
  }

  /// Execute multiple operations in a batch for better performance
  Future<List<dynamic>> executeBatch(
    Future<void> Function(Batch batch) operations,
  ) async {
    final db = await database;
    final batch = db.batch();
    
    try {
      await operations(batch);
      return await batch.commit();
    } catch (e) {
      throw DatabaseException('Batch operation failed: $e');
    }
  }

  /// Insert a record with conflict resolution
  Future<int> insertRecord(
    String table,
    Map<String, dynamic> values, {
    ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.abort,
  }) async {
    final db = await database;
    try {
      return await db.insert(table, values, conflictAlgorithm: conflictAlgorithm);
    } catch (e) {
      throw DatabaseException('Insert failed: $e');
    }
  }

  /// Update records with where clause
  Future<int> updateRecord(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
    ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.abort,
  }) async {
    final db = await database;
    try {
      return await db.update(
        table,
        values,
        where: where,
        whereArgs: whereArgs,
        conflictAlgorithm: conflictAlgorithm,
      );
    } catch (e) {
      throw DatabaseException('Update failed: $e');
    }
  }

  /// Delete records with where clause
  Future<int> deleteRecord(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    try {
      return await db.delete(table, where: where, whereArgs: whereArgs);
    } catch (e) {
      throw DatabaseException('Delete failed: $e');
    }
  }

  /// Query records with comprehensive options
  Future<List<Map<String, dynamic>>> queryRecords(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    try {
      return await db.query(
        table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      throw DatabaseException('Query failed: $e');
    }
  }

  /// Execute raw SQL query
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    try {
      return await db.rawQuery(sql, arguments);
    } catch (e) {
      throw DatabaseException('Raw query failed: $e');
    }
  }

  /// Execute raw SQL command
  Future<int> rawExecute(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    try {
      return await db.rawUpdate(sql, arguments);
    } catch (e) {
      throw DatabaseException('Raw execute failed: $e');
    }
  }

  /// Get database size in bytes
  Future<int> getDatabaseSize() async {
    final documentsDirectory = await getDatabasesPath();
    final path = join(documentsDirectory, _databaseName);
    final file = File(path);
    
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// Get table information for debugging
  Future<List<Map<String, dynamic>>> getTableInfo(String tableName) async {
    return await rawQuery('PRAGMA table_info($tableName)');
  }

  /// Get index information for a table
  Future<List<Map<String, dynamic>>> getIndexInfo(String tableName) async {
    return await rawQuery('PRAGMA index_list($tableName)');
  }

  /// Analyze database for query optimization
  Future<void> analyzeDatabase() async {
    await rawExecute('ANALYZE');
  }

  /// Vacuum database to reclaim space
  Future<void> vacuumDatabase() async {
    await rawExecute('VACUUM');
  }

  /// Backup database to a file
  Future<void> backupDatabase(String backupPath) async {
    final db = await database;
    await db.close();
    
    try {
      final documentsDirectory = await getDatabasesPath();
      final currentPath = join(documentsDirectory, _databaseName);
      final currentFile = File(currentPath);
      
      if (await currentFile.exists()) {
        await currentFile.copy(backupPath);
      }
    } finally {
      // Reopen the database
      _database = await _initializeDatabase();
    }
  }

  /// Restore database from backup
  Future<void> restoreDatabase(String backupPath) async {
    final backupFile = File(backupPath);
    if (!await backupFile.exists()) {
      throw DatabaseException('Backup file does not exist: $backupPath');
    }

    await close();
    
    try {
      final documentsDirectory = await getDatabasesPath();
      final currentPath = join(documentsDirectory, _databaseName);
      
      await backupFile.copy(currentPath);
      _database = await _initializeDatabase();
    } catch (e) {
      throw DatabaseException('Failed to restore database: $e');
    }
  }

  /// Close the database connection
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Delete the database file (use with caution)
  Future<void> deleteDatabase() async {
    await close();
    final documentsDirectory = await getDatabasesPath();
    final path = join(documentsDirectory, _databaseName);
    await databaseFactory.deleteDatabase(path);
  }

  /// Get database statistics for monitoring
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final size = await getDatabaseSize();
    final userCount = await rawQuery('SELECT COUNT(*) as count FROM $tableUsers');
    final rewardEntryCount = await rawQuery('SELECT COUNT(*) as count FROM $tableRewardEntries');
    final categoryCount = await rawQuery('SELECT COUNT(*) as count FROM $tableCategories');
    final redemptionOptionCount = await rawQuery('SELECT COUNT(*) as count FROM $tableRedemptionOptions');
    final redemptionTransactionCount = await rawQuery('SELECT COUNT(*) as count FROM $tableRedemptionTransactions');
    final syncQueueCount = await rawQuery('SELECT COUNT(*) as count FROM $tableSyncQueue');
    
    return {
      'size_bytes': size,
      'size_mb': (size / (1024 * 1024)).toStringAsFixed(2),
      'user_count': userCount.first['count'],
      'reward_entry_count': rewardEntryCount.first['count'],
      'category_count': categoryCount.first['count'],
      'redemption_option_count': redemptionOptionCount.first['count'],
      'redemption_transaction_count': redemptionTransactionCount.first['count'],
      'sync_queue_count': syncQueueCount.first['count'],
    };
  }
}

/// Custom exception for database operations
class DatabaseException implements Exception {
  final String message;
  const DatabaseException(this.message);
  
  @override
  String toString() => 'DatabaseException: $message';
}