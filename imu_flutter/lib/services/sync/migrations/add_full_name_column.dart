/// PowerSync Migration: Add full_name column to clients table
/// Version: 049
/// Date: 2026-04-09
///
/// This migration adds a computed `full_name` column to the clients table
/// for efficient offline search, matching the backend database schema.
///
/// Changes:
/// - Adds full_name TEXT column to clients table
/// - Creates INSERT trigger to auto-populate full_name
/// - Creates UPDATE trigger to maintain full_name on name changes
/// - Creates optimized indexes for case-insensitive search
/// - Backfills existing records with computed full_name values
library;

import 'package:powersync/powersync.dart';
import '../../../core/utils/logger.dart' show appLogger;

/// Migration class for adding full_name column
class AddFullNameColumnMigration {
  /// Migration SQL statements
  static const List<String> migrationSql = [
    // Step 1: Add full_name column
    '''
    ALTER TABLE clients ADD COLUMN full_name TEXT
    ''',

    // Step 2: Create INSERT trigger for automatic full_name population
    '''
    CREATE TRIGGER IF NOT EXISTS clients_insert_full_name_trigger
    AFTER INSERT ON clients
    BEGIN
      UPDATE clients
      SET full_name = last_name || ', ' || first_name ||
                  CASE WHEN middle_name IS NOT NULL AND middle_name != ''
                       THEN ' ' || middle_name
                       ELSE ''
                  END
      WHERE id = NEW.id;
    END
    ''',

    // Step 3: Create UPDATE trigger to maintain full_name when names change
    '''
    CREATE TRIGGER IF NOT EXISTS clients_update_full_name_trigger
    AFTER UPDATE OF first_name, last_name, middle_name ON clients
    BEGIN
      UPDATE clients
      SET full_name = last_name || ', ' || first_name ||
                  CASE WHEN middle_name IS NOT NULL AND middle_name != ''
                       THEN ' ' || middle_name
                       ELSE ''
                  END
      WHERE id = NEW.id;
    END
    ''',

    // Step 4: Create index for case-insensitive search (LOWER function)
    '''
    CREATE INDEX IF NOT EXISTS idx_clients_full_name_lower
    ON clients(LOWER(full_name))
    ''',

    // Step 5: Create index for natural case-insensitive search
    '''
    CREATE INDEX IF NOT EXISTS idx_clients_full_name_nocase
    ON clients(full_name COLLATE NOCASE)
    ''',

    // Step 6: Backfill existing records with computed full_name
    '''
    UPDATE clients
    SET full_name = last_name || ', ' || first_name ||
                CASE WHEN middle_name IS NOT NULL AND middle_name != ''
                     THEN ' ' || middle_name
                     ELSE ''
                END
    WHERE full_name IS NULL OR full_name = ''
    ''',
  ];

  /// Execute the migration
  static Future<void> execute(PowerSyncDatabase database) async {
    try {
      appLogger.i('Starting migration: Add full_name column to clients table');

      for (final sql in migrationSql) {
        await database.execute(sql);
        appLogger.d('Executed SQL: ${sql.trim().split('\n')[0]}...');
      }

      appLogger.i('Migration completed successfully: full_name column added');

      // Verify the migration
      await _verifyMigration(database);

    } catch (e) {
      appLogger.e('Migration failed: $e');
      rethrow;
    }
  }

  /// Verify that the migration was successful
  static Future<void> _verifyMigration(PowerSyncDatabase database) async {
    try {
      // Check if full_name column exists
      final columnCheck = await database.get('''
        PRAGMA table_info(clients)
      ''');

      final hasFullNameColumn = (columnCheck as List?)
          ?.any((row) => row['name'] == 'full_name') ?? false;

      if (!hasFullNameColumn) {
        throw Exception('Migration verification failed: full_name column not found');
      }

      // Check if triggers exist
      final triggerCheck = await database.getAll('''
        SELECT name FROM sqlite_master
        WHERE type = 'trigger'
        AND name LIKE '%full_name%'
        ORDER BY name
      ''');

      final insertTriggerExists = triggerCheck
          .any((row) => row['name'].toString().contains('insert_full_name'));
      final updateTriggerExists = triggerCheck
          .any((row) => row['name'].toString().contains('update_full_name'));

      if (!insertTriggerExists || !updateTriggerExists) {
        throw Exception('Migration verification failed: triggers not found');
      }

      // Check if indexes exist
      final indexCheck = await database.getAll('''
        SELECT name FROM sqlite_master
        WHERE type = 'index'
        AND tbl_name = 'clients'
        AND name LIKE '%full_name%'
        ORDER BY name
      ''');

      final hasLowerIndex = indexCheck
          .any((row) => row['name'].toString().contains('full_name_lower'));
      final hasNocaseIndex = indexCheck
          .any((row) => row['name'].toString().contains('full_name_nocase'));

      if (!hasLowerIndex && !hasNocaseIndex) {
        throw Exception('Migration verification failed: indexes not found');
      }

      // Check a sample of records to ensure full_name is populated
      final sampleCheck = await database.get('''
        SELECT COUNT(*) as populated_count
        FROM clients
        WHERE full_name IS NOT NULL AND full_name != ''
      ''');

      final totalCount = await database.get('SELECT COUNT(*) as total FROM clients');
      final total = totalCount?['total'] as int? ?? 0;
      final populated = sampleCheck?['populated_count'] as int? ?? 0;

      if (total > 0 && populated == 0) {
        throw Exception('Migration verification failed: full_name not populated');
      }

      appLogger.i('Migration verification successful:');
      appLogger.i('  - full_name column exists: $hasFullNameColumn');
      appLogger.i('  - INSERT trigger exists: $insertTriggerExists');
      appLogger.i('  - UPDATE trigger exists: $updateTriggerExists');
      appLogger.i('  - LOWER index exists: $hasLowerIndex');
      appLogger.i('  - NOCASE index exists: $hasNocaseIndex');
      appLogger.i('  - Records with full_name: $populated/$total');

    } catch (e) {
      appLogger.e('Migration verification failed: $e');
      rethrow;
    }
  }

  /// Rollback the migration (for testing/development)
  static Future<void> rollback(PowerSyncDatabase database) async {
    try {
      appLogger.w('Rolling back migration: Add full_name column');

      // Drop indexes
      await database.execute('DROP INDEX IF EXISTS idx_clients_full_name_lower');
      await database.execute('DROP INDEX IF EXISTS idx_clients_full_name_nocase');

      // Drop triggers
      await database.execute('DROP TRIGGER IF EXISTS clients_update_full_name_trigger');
      await database.execute('DROP TRIGGER IF EXISTS clients_insert_full_name_trigger');

      // Drop column
      await database.execute('ALTER TABLE clients DROP COLUMN full_name');

      appLogger.i('Rollback completed successfully');

    } catch (e) {
      appLogger.e('Rollback failed: $e');
      rethrow;
    }
  }

  /// Get migration status information
  static Future<MigrationStatus> getMigrationStatus(PowerSyncDatabase database) async {
    try {
      final columnCheck = await database.get('''
        SELECT COUNT(*) as has_column
        FROM pragma_table_info('clients')
        WHERE name = 'full_name'
      ''');

      final triggerCheck = await database.getAll('''
        SELECT COUNT(*) as trigger_count
        FROM sqlite_master
        WHERE type = 'trigger'
        AND name LIKE '%full_name%'
      ''');

      final indexCheck = await database.getAll('''
        SELECT COUNT(*) as index_count
        FROM sqlite_master
        WHERE type = 'index'
        AND tbl_name = 'clients'
        AND name LIKE '%full_name%'
      ''');

      final hasColumn = (columnCheck?['has_column'] as int? ?? 0) > 0;
      final triggerCount = triggerCheck?['trigger_count'] as int? ?? 0;
      final indexCount = indexCheck?['index_count'] as int? ?? 0;

      return MigrationStatus(
        columnName: 'full_name',
        isAdded: hasColumn,
        insertTriggerEnabled: triggerCount >= 1,
        updateTriggerEnabled: triggerCount >= 2,
        indexesCreated: indexCount,
        isComplete: hasColumn && triggerCount >= 2 && indexCount >= 2,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      appLogger.e('Failed to get migration status: $e');
      return MigrationStatus.error();
    }
  }

  /// Check if migration is needed
  static Future<bool> isMigrationNeeded(PowerSyncDatabase database) async {
    try {
      final status = await getMigrationStatus(database);
      return !status.isComplete;
    } catch (e) {
      appLogger.e('Failed to check migration status: $e');
      return true; // Assume migration is needed if check fails
    }
  }
}

/// Migration status information
class MigrationStatus {
  final String columnName;
  final bool isAdded;
  final bool insertTriggerEnabled;
  final bool updateTriggerEnabled;
  final int indexesCreated;
  final bool isComplete;
  final DateTime lastUpdated;

  MigrationStatus({
    required this.columnName,
    required this.isAdded,
    required this.insertTriggerEnabled,
    required this.updateTriggerEnabled,
    required this.indexesCreated,
    required this.isComplete,
    required this.lastUpdated,
  });

  /// Create error status
  factory MigrationStatus.error() {
    return MigrationStatus(
      columnName: 'full_name',
      isAdded: false,
      insertTriggerEnabled: false,
      updateTriggerEnabled: false,
      indexesCreated: 0,
      isComplete: false,
      lastUpdated: DateTime.now(),
    );
  }

  /// Get status message
  String get statusMessage {
    if (isComplete) {
      return 'Migration complete: All triggers and indexes configured';
    }

    final missing = <String>[];
    if (!isAdded) missing.add('full_name column');
    if (!insertTriggerEnabled) missing.add('INSERT trigger');
    if (!updateTriggerEnabled) missing.add('UPDATE trigger');
    if (indexesCreated < 2) missing.add('search indexes');

    if (missing.isEmpty) {
      return 'Migration partially complete';
    }

    return 'Missing: ${missing.join(', ')}';
  }

  @override
  String toString() =>
      'MigrationStatus(column: $columnName, complete: $isComplete, ' +
      'triggers: ${insertTriggerEnabled && updateTriggerEnabled}, ' +
      'indexes: $indexesCreated/$indexesCreated)';

  /// Convert to JSON for logging/monitoring
  Map<String, dynamic> toJson() => {
    return {
      'column_name': columnName,
      'is_added': isAdded,
      'insert_trigger_enabled': insertTriggerEnabled,
      'update_trigger_enabled': updateTriggerEnabled,
      'indexes_created': indexesCreated,
      'is_complete': isComplete,
      'last_updated': lastUpdated.toIso8601String(),
      'status_message': statusMessage,
    };
  }
}

/// Migration helper functions
class MigrationHelper {
  /// Run all pending migrations
  static Future<void> runMigrations(PowerSyncDatabase database) async {
    try {
      appLogger.i('Running PowerSync database migrations...');

      // Check if migration is needed
      final needsMigration = await AddFullNameColumnMigration.isMigrationNeeded(database);

      if (!needsMigration) {
        appLogger.i('Migration 049 (add_full_name_column) already applied');
        return;
      }

      // Execute migration
      await AddFullNameColumnMigration.execute(database);

      appLogger.i('All migrations completed successfully');

    } catch (e) {
      appLogger.e('Migration failed: $e');
      rethrow;
    }
  }

  /// Get all migration statuses
  static Future<List<MigrationStatus>> getMigrationStatuses(PowerSyncDatabase database) async {
    try {
      final status = await AddFullNameColumnMigration.getMigrationStatus(database);
      return [status];
    } catch (e) {
      appLogger.e('Failed to get migration statuses: $e');
      return [MigrationStatus.error()];
    }
  }

  /// Verify database schema matches expected schema
  static Future<bool> verifySchema(PowerSyncDatabase database) async {
    try {
      final status = await AddFullNameColumnMigration.getMigrationStatus(database);
      return status.isComplete;
    } catch (e) {
      appLogger.e('Schema verification failed: $e');
      return false;
    }
  }
}
