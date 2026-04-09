/// PowerSync Migration Runner
/// Executes SQL migration files from the migrations directory
library;

import 'package:powersync/powersync.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart' show rootBundle;
import '../../../core/utils/logger.dart' show appLogger;

/// Migration runner for executing SQL files
class MigrationRunner {
  /// Execute a migration from a SQL file
  static Future<void> executeMigration(
    PowerSyncDatabase database,
    String migrationFileName,
  ) async {
    try {
      appLogger.i('Executing migration: $migrationFileName');

      // Load SQL from assets
      final sql = await rootBundle.loadString(
        'assets/migrations/$migrationFileName',
      );

      // Split by semicolon and execute each statement
      final statements = sql
          .split(';')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      for (final statement in statements) {
        await database.execute(statement);
        appLogger.d('Executed: ${statement.substring(0, 50)}...');
      }

      appLogger.i('Migration completed: $migrationFileName');
    } catch (e) {
      appLogger.e('Migration failed: $migrationFileName - $e');
      rethrow;
    }
  }

  /// Rollback a migration using a rollback SQL file
  static Future<void> rollbackMigration(
    PowerSyncDatabase database,
    String rollbackFileName,
  ) async {
    try {
      appLogger.w('Rolling back migration: $rollbackFileName');

      // Load SQL from assets
      final sql = await rootBundle.loadString(
        'assets/migrations/$rollbackFileName',
      );

      // Split by semicolon and execute each statement
      final statements = sql
          .split(';')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      for (final statement in statements) {
        await database.execute(statement);
        appLogger.d('Executed: ${statement.substring(0, 50)}...');
      }

      appLogger.i('Rollback completed: $rollbackFileName');
    } catch (e) {
      appLogger.e('Rollback failed: $rollbackFileName - $e');
      rethrow;
    }
  }
}
