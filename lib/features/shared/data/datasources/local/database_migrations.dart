import 'package:sqflite/sqflite.dart';

/// Database migration system for the AI Rewards System.
/// 
/// This class manages database schema evolution through versioned migrations.
/// It ensures that database upgrades are applied safely and can handle
/// complex schema changes while preserving user data.
/// 
/// Key features:
/// - Sequential migration execution
/// - Data preservation during schema changes
/// - Rollback support for critical migrations
/// - Validation of migration success
/// - Performance optimization during migrations
class DatabaseMigrations {
  /// Get all migrations needed to upgrade from [fromVersion] to [toVersion]
  static List<DatabaseMigration> getMigrations(int fromVersion, int toVersion) {
    final migrations = <DatabaseMigration>[];
    
    // Add migrations in order from oldest to newest
    // Example: if upgrading from version 1 to 3, apply migrations 2 and 3
    for (int version = fromVersion + 1; version <= toVersion; version++) {
      final migration = _getMigrationForVersion(version);
      if (migration != null) {
        migrations.add(migration);
      }
    }
    
    return migrations;
  }

  /// Get the migration for a specific version
  static DatabaseMigration? _getMigrationForVersion(int version) {
    switch (version) {
      case 2:
        return _MigrationV2();
      case 3:
        return _MigrationV3();
      case 4:
        return _MigrationV4();
      // Add more migrations as needed
      default:
        return null;
    }
  }

  /// Validate that all required migrations exist for the version range
  static bool validateMigrationPath(int fromVersion, int toVersion) {
    for (int version = fromVersion + 1; version <= toVersion; version++) {
      if (_getMigrationForVersion(version) == null) {
        return false;
      }
    }
    return true;
  }
}

/// Abstract base class for database migrations
abstract class DatabaseMigration {
  /// The target version this migration upgrades to
  int get targetVersion;
  
  /// Human-readable description of what this migration does
  String get description;
  
  /// Whether this migration can be safely rolled back
  bool get canRollback => false;
  
  /// Apply the migration to the database
  Future<void> apply(Database db);
  
  /// Rollback the migration (if supported)
  Future<void> rollback(Database db) {
    throw UnsupportedError('Migration to version $targetVersion does not support rollback');
  }
  
  /// Validate that the migration was applied successfully
  Future<bool> validate(Database db) async {
    // Default implementation - subclasses can override for specific validation
    return true;
  }
}

/// Migration to version 2 - Example: Add user preferences table
class _MigrationV2 extends DatabaseMigration {
  @override
  int get targetVersion => 2;
  
  @override
  String get description => 'Add user preferences and notification settings';
  
  @override
  bool get canRollback => true;
  
  @override
  Future<void> apply(Database db) async {
    final batch = db.batch();
    
    try {
      // Add new table for user preferences
      batch.execute('''
        CREATE TABLE user_preferences (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          theme_mode TEXT NOT NULL DEFAULT 'system',
          notifications_enabled INTEGER NOT NULL DEFAULT 1,
          biometric_enabled INTEGER NOT NULL DEFAULT 0,
          language_code TEXT NOT NULL DEFAULT 'en',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
      
      // Add index for performance
      batch.execute('CREATE INDEX idx_user_preferences_user_id ON user_preferences (user_id)');
      
      // Add new columns to existing users table
      batch.execute('ALTER TABLE users ADD COLUMN last_sync_at INTEGER');
      batch.execute('ALTER TABLE users ADD COLUMN preferences_version INTEGER NOT NULL DEFAULT 1');
      
      await batch.commit();
      
      print('Migration V2: User preferences table created successfully');
    } catch (e) {
      print('Migration V2 failed: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> rollback(Database db) async {
    final batch = db.batch();
    
    try {
      // Drop the preferences table
      batch.execute('DROP TABLE IF EXISTS user_preferences');
      
      // Note: SQLite doesn't support dropping columns, so we can't remove
      // the added columns from users table in rollback. This is why
      // careful planning of migrations is important.
      
      await batch.commit();
      
      print('Migration V2: Rollback completed');
    } catch (e) {
      print('Migration V2 rollback failed: $e');
      rethrow;
    }
  }
  
  @override
  Future<bool> validate(Database db) async {
    try {
      // Check if the table exists
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='user_preferences'"
      );
      
      if (result.isEmpty) {
        print('Migration V2 validation failed: user_preferences table not found');
        return false;
      }
      
      // Check if the index exists
      final indexResult = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND name='idx_user_preferences_user_id'"
      );
      
      if (indexResult.isEmpty) {
        print('Migration V2 validation failed: index not found');
        return false;
      }
      
      print('Migration V2 validation passed');
      return true;
    } catch (e) {
      print('Migration V2 validation error: $e');
      return false;
    }
  }
}

/// Migration to version 3 - Example: Add achievement system
class _MigrationV3 extends DatabaseMigration {
  @override
  int get targetVersion => 3;
  
  @override
  String get description => 'Add achievement system and user badges';
  
  @override
  Future<void> apply(Database db) async {
    final batch = db.batch();
    
    try {
      // Create achievements table
      batch.execute('''
        CREATE TABLE achievements (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT NOT NULL,
          category TEXT NOT NULL,
          requirement_type TEXT NOT NULL,
          requirement_value INTEGER NOT NULL,
          reward_points INTEGER NOT NULL DEFAULT 0,
          icon_code_point INTEGER NOT NULL,
          icon_font_family TEXT NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
      
      // Create user achievements table (earned achievements)
      batch.execute('''
        CREATE TABLE user_achievements (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          achievement_id TEXT NOT NULL,
          earned_at INTEGER NOT NULL,
          progress_value INTEGER NOT NULL DEFAULT 0,
          is_completed INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (achievement_id) REFERENCES achievements (id) ON DELETE CASCADE,
          UNIQUE(user_id, achievement_id)
        )
      ''');
      
      // Add indexes
      batch.execute('CREATE INDEX idx_achievements_category ON achievements (category)');
      batch.execute('CREATE INDEX idx_achievements_active ON achievements (is_active)');
      batch.execute('CREATE INDEX idx_user_achievements_user_id ON user_achievements (user_id)');
      batch.execute('CREATE INDEX idx_user_achievements_earned_at ON user_achievements (earned_at DESC)');
      batch.execute('CREATE INDEX idx_user_achievements_completed ON user_achievements (is_completed, user_id)');
      
      // Add achievement tracking columns to reward entries
      batch.execute('ALTER TABLE reward_entries ADD COLUMN achievement_id TEXT');
      batch.execute('CREATE INDEX idx_reward_entries_achievement ON reward_entries (achievement_id)');
      
      await batch.commit();
      
      // Insert default achievements
      await _insertDefaultAchievements(db);
      
      print('Migration V3: Achievement system created successfully');
    } catch (e) {
      print('Migration V3 failed: $e');
      rethrow;
    }
  }
  
  Future<void> _insertDefaultAchievements(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = db.batch();
    
    final defaultAchievements = [
      {
        'id': 'ach_first_reward',
        'name': 'First Steps',
        'description': 'Earned your first reward points',
        'category': 'beginner',
        'requirement_type': 'total_points',
        'requirement_value': 1,
        'reward_points': 10,
        'icon_code_point': 0xe886, // star
        'icon_font_family': 'MaterialIcons',
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'ach_hundred_points',
        'name': 'Century Club',
        'description': 'Earned 100 total points',
        'category': 'milestone',
        'requirement_type': 'total_points',
        'requirement_value': 100,
        'reward_points': 25,
        'icon_code_point': 0xe837, // emoji_events
        'icon_font_family': 'MaterialIcons',
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'ach_daily_streak_7',
        'name': 'Week Warrior',
        'description': 'Earned points for 7 consecutive days',
        'category': 'streak',
        'requirement_type': 'daily_streak',
        'requirement_value': 7,
        'reward_points': 50,
        'icon_code_point': 0xe8e8, // whatshot
        'icon_font_family': 'MaterialIcons',
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'ach_first_redemption',
        'name': 'Spender',
        'description': 'Made your first redemption',
        'category': 'redemption',
        'requirement_type': 'total_redemptions',
        'requirement_value': 1,
        'reward_points': 15,
        'icon_code_point': 0xe8cc, // shopping_cart
        'icon_font_family': 'MaterialIcons',
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      },
    ];
    
    for (final achievement in defaultAchievements) {
      batch.insert('achievements', achievement);
    }
    
    await batch.commit();
  }
  
  @override
  Future<bool> validate(Database db) async {
    try {
      // Validate achievements table exists with correct columns
      final achievementsInfo = await db.rawQuery('PRAGMA table_info(achievements)');
      final expectedColumns = ['id', 'name', 'description', 'category', 'requirement_type', 'requirement_value'];
      
      for (final column in expectedColumns) {
        if (!achievementsInfo.any((info) => info['name'] == column)) {
          print('Migration V3 validation failed: missing column $column in achievements table');
          return false;
        }
      }
      
      // Validate user_achievements table exists
      final userAchievementsResult = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='user_achievements'"
      );
      
      if (userAchievementsResult.isEmpty) {
        print('Migration V3 validation failed: user_achievements table not found');
        return false;
      }
      
      // Validate default achievements were inserted
      final achievementCount = await db.rawQuery('SELECT COUNT(*) as count FROM achievements');
      final count = achievementCount.first['count'] as int;
      
      if (count < 4) {
        print('Migration V3 validation failed: expected at least 4 default achievements, found $count');
        return false;
      }
      
      print('Migration V3 validation passed');
      return true;
    } catch (e) {
      print('Migration V3 validation error: $e');
      return false;
    }
  }
}

/// Migration to version 4 - Example: Add analytics and app usage tracking
class _MigrationV4 extends DatabaseMigration {
  @override
  int get targetVersion => 4;
  
  @override
  String get description => 'Add analytics and app usage tracking';
  
  @override
  Future<void> apply(Database db) async {
    final batch = db.batch();
    
    try {
      // Create app sessions table for usage tracking
      batch.execute('''
        CREATE TABLE app_sessions (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          started_at INTEGER NOT NULL,
          ended_at INTEGER,
          session_duration INTEGER,
          actions_count INTEGER NOT NULL DEFAULT 0,
          screens_visited TEXT, -- JSON array of screen names
          created_at INTEGER NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
      
      // Create user actions table for detailed analytics
      batch.execute('''
        CREATE TABLE user_actions (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          session_id TEXT NOT NULL,
          action_type TEXT NOT NULL,
          action_data TEXT, -- JSON data
          screen_name TEXT,
          timestamp INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (session_id) REFERENCES app_sessions (id) ON DELETE CASCADE
        )
      ''');
      
      // Add indexes for analytics queries
      batch.execute('CREATE INDEX idx_app_sessions_user_id ON app_sessions (user_id)');
      batch.execute('CREATE INDEX idx_app_sessions_started_at ON app_sessions (started_at DESC)');
      batch.execute('CREATE INDEX idx_user_actions_user_id ON user_actions (user_id)');
      batch.execute('CREATE INDEX idx_user_actions_session_id ON user_actions (session_id)');
      batch.execute('CREATE INDEX idx_user_actions_action_type ON user_actions (action_type)');
      batch.execute('CREATE INDEX idx_user_actions_timestamp ON user_actions (timestamp DESC)');
      
      // Add analytics columns to existing tables
      batch.execute('ALTER TABLE users ADD COLUMN total_sessions INTEGER NOT NULL DEFAULT 0');
      batch.execute('ALTER TABLE users ADD COLUMN total_session_duration INTEGER NOT NULL DEFAULT 0');
      batch.execute('ALTER TABLE reward_entries ADD COLUMN source_screen TEXT');
      batch.execute('ALTER TABLE redemption_transactions ADD COLUMN source_screen TEXT');
      
      await batch.commit();
      
      print('Migration V4: Analytics system created successfully');
    } catch (e) {
      print('Migration V4 failed: $e');
      rethrow;
    }
  }
  
  @override
  Future<bool> validate(Database db) async {
    try {
      // Validate app_sessions table exists
      final sessionsResult = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='app_sessions'"
      );
      
      if (sessionsResult.isEmpty) {
        print('Migration V4 validation failed: app_sessions table not found');
        return false;
      }
      
      // Validate user_actions table exists
      final actionsResult = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='user_actions'"
      );
      
      if (actionsResult.isEmpty) {
        print('Migration V4 validation failed: user_actions table not found');
        return false;
      }
      
      // Validate new columns were added to users table
      final usersInfo = await db.rawQuery('PRAGMA table_info(users)');
      final hasSessionsColumn = usersInfo.any((info) => info['name'] == 'total_sessions');
      
      if (!hasSessionsColumn) {
        print('Migration V4 validation failed: total_sessions column not found in users table');
        return false;
      }
      
      print('Migration V4 validation passed');
      return true;
    } catch (e) {
      print('Migration V4 validation error: $e');
      return false;
    }
  }
}

/// Utility class for migration management and troubleshooting
class MigrationManager {
  /// Check if database schema is up to date
  static Future<bool> isDatabaseUpToDate(Database db, int expectedVersion) async {
    final version = await db.getVersion();
    return version == expectedVersion;
  }
  
  /// Get current database schema version
  static Future<int> getCurrentVersion(Database db) async {
    return await db.getVersion();
  }
  
  /// Validate database schema integrity after migrations
  static Future<bool> validateSchemaIntegrity(Database db) async {
    try {
      // Check database integrity
      final integrityResult = await db.rawQuery('PRAGMA integrity_check');
      if (integrityResult.first['integrity_check'] != 'ok') {
        print('Schema integrity check failed');
        return false;
      }
      
      // Check foreign key constraints
      final fkResult = await db.rawQuery('PRAGMA foreign_key_check');
      if (fkResult.isNotEmpty) {
        print('Foreign key constraint check failed');
        return false;
      }
      
      // Verify all expected tables exist
      final expectedTables = [
        'users',
        'reward_entries',
        'categories',
        'redemption_options',
        'redemption_transactions',
        'sync_queue',
      ];
      
      for (final table in expectedTables) {
        final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='$table'"
        );
        if (result.isEmpty) {
          print('Expected table $table not found');
          return false;
        }
      }
      
      print('Database schema validation passed');
      return true;
    } catch (e) {
      print('Schema validation error: $e');
      return false;
    }
  }
  
  /// Get migration history (if tracking is implemented)
  static Future<List<Map<String, dynamic>>> getMigrationHistory(Database db) async {
    try {
      // This would require a migration_history table to be created
      // For now, return basic version info
      final version = await db.getVersion();
      return [
        {
          'version': version,
          'applied_at': DateTime.now().toIso8601String(),
          'status': 'current',
        }
      ];
    } catch (e) {
      print('Error getting migration history: $e');
      return [];
    }
  }
  
  /// Emergency rollback to a previous version (use with extreme caution)
  static Future<bool> emergencyRollback(Database db, int targetVersion) async {
    try {
      print('WARNING: Emergency rollback initiated to version $targetVersion');
      
      final currentVersion = await db.getVersion();
      if (targetVersion >= currentVersion) {
        print('Target version must be lower than current version');
        return false;
      }
      
      // This is a simplified rollback - in production, you'd need
      // more sophisticated rollback mechanisms
      await db.setVersion(targetVersion);
      
      print('Emergency rollback completed - database validation recommended');
      return true;
    } catch (e) {
      print('Emergency rollback failed: $e');
      return false;
    }
  }
}

/// Represents the result of a migration operation
class MigrationResult {
  final bool success;
  final String message;
  final int? targetVersion;
  final Duration? executionTime;
  final Exception? error;
  
  const MigrationResult({
    required this.success,
    required this.message,
    this.targetVersion,
    this.executionTime,
    this.error,
  });
  
  factory MigrationResult.success(String message, int targetVersion, Duration executionTime) {
    return MigrationResult(
      success: true,
      message: message,
      targetVersion: targetVersion,
      executionTime: executionTime,
    );
  }
  
  factory MigrationResult.failure(String message, Exception error) {
    return MigrationResult(
      success: false,
      message: message,
      error: error,
    );
  }
  
  @override
  String toString() {
    if (success) {
      return 'Migration SUCCESS: $message (v$targetVersion, ${executionTime?.inMilliseconds}ms)';
    } else {
      return 'Migration FAILED: $message - ${error.toString()}';
    }
  }
}