/// Shared data layer exports for local database operations.
/// 
/// This barrel file provides access to the SQLite database infrastructure
/// including the database helper, migration system, and related utilities.
/// 
/// Key exports:
/// - [DatabaseHelper] - Main database interface with CRUD operations
/// - [DatabaseMigrations] - Migration system for schema evolution
/// - [DatabaseMigration] - Base class for individual migrations
/// - [MigrationManager] - Utilities for migration management
/// - [DatabaseException] - Custom exception for database operations

export 'database_helper.dart';
export 'database_migrations.dart';