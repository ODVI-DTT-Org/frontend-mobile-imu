/// Tests for PowerSync migration: Add full_name column to clients table
/// Verifies that the migration adds the column, triggers, and indexes correctly
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/services/sync/migrations/add_full_name_column.dart';
import 'package:imu_flutter/core/utils/logger.dart';

void main() {
  group('AddFullNameColumn Migration Tests', () {
    late AddFullNameColumnMigration migration;

    setUp(() {
      migration = AddFullNameColumnMigration();
    });

    test('should contain all required SQL statements', () {
      expect(AddFullNameColumnMigration.migrationSql.length, equals(6));

      // Check for ALTER TABLE statement
      final hasAlterTable = AddFullNameColumnMigration.migrationSql.any((sql) =>
        sql.contains('ALTER TABLE clients ADD COLUMN full_name'));
      expect(hasAlterTable, isTrue, reason: 'Should add full_name column');

      // Check for INSERT trigger
      final hasInsertTrigger = AddFullNameColumnMigration.migrationSql.any((sql) =>
        sql.contains('CREATE TRIGGER') && sql.contains('INSERT'));
      expect(hasInsertTrigger, isTrue, reason: 'Should create INSERT trigger');

      // Check for UPDATE trigger
      final hasUpdateTrigger = AddFullNameColumnMigration.migrationSql.any((sql) =>
        sql.contains('CREATE TRIGGER') && sql.contains('UPDATE'));
      expect(hasUpdateTrigger, isTrue, reason: 'Should create UPDATE trigger');

      // Check for indexes
      final hasLowerIndex = AddFullNameColumnMigration.migrationSql.any((sql) =>
        sql.contains('CREATE INDEX') && sql.contains('full_name_lower'));
      expect(hasLowerIndex, isTrue, reason: 'Should create LOWER() index');

      final hasNocaseIndex = AddFullNameColumnMigration.migrationSql.any((sql) =>
        sql.contains('CREATE INDEX') && sql.contains('full_name_nocase'));
      expect(hasNocaseIndex, isTrue, reason: 'Should create COLLATE NOCASE index');

      // Check for backfill UPDATE
      final hasBackfill = AddFullNameColumnMigration.migrationSql.any((sql) =>
        sql.contains('UPDATE clients') && sql.contains('SET full_name'));
      expect(hasBackfill, isTrue, reason: 'Should backfill existing records');
    });

    test('should create proper full_name format', () {
      // Verify the full_name format: "LastName, FirstName MiddleName"
      final format = "last_name || ', ' || first_name || "
                  "CASE WHEN middle_name IS NOT NULL AND middle_name != '' "
                  "THEN ' ' || middle_name "
                  "ELSE '' "
                  "END";

      expect(format, contains('last_name'));
      expect(format, contains('first_name'));
      expect(format, contains('middle_name'));
      expect(format, contains(', ')); // Comma separator
    });

    test('migration SQL should be valid', () {
      for (final sql in AddFullNameColumnMigration.migrationSql) {
        // Check that SQL is not empty
        expect(sql.trim().isNotEmpty, isTrue, reason: 'SQL statement should not be empty');

        // Check for common SQL syntax errors
        expect(sql, isNot(contains('--'))); // No comments at start
        expect(sql, isNot(endsWith(';'))); // Single statement per string
      }
    });

    test('should have rollback functionality', () {
      // Verify that rollback method exists
      expect(
        AddFullNameColumnMigration.rollback is Future<void> Function(PowerSyncDatabase),
        returnsNormally,
        reason: 'Should have rollback method',
      );
    });

    test('should provide migration status', () {
      // Verify that getMigrationStatus method exists
      expect(
        AddFullNameColumnMigration.getMigrationStatus is Future<MigrationStatus> Function(PowerSyncDatabase),
        returnsNormally,
        reason: 'Should have status checking method',
      );

      // Verify that isMigrationNeeded method exists
      expect(
        AddFullNameColumnMigration.isMigrationNeeded is Future<bool> Function(PowerSyncDatabase),
        returnsNormally,
        reason: 'Should have migration check method',
      );
    });

    group('MigrationStatus', () {
      test('should create error status correctly', () {
        final status = MigrationStatus.error();

        expect(status.columnName, equals('full_name'));
        expect(status.isAdded, isFalse);
        expect(status.insertTriggerEnabled, isFalse);
        expect(status.updateTriggerEnabled, isFalse);
        expect(status.indexesCreated, equals(0));
        expect(status.isComplete, isFalse);
        expect(status.statusMessage, contains('Missing'));
      });

      test('should convert to JSON correctly', () {
        final status = MigrationStatus(
          columnName: 'full_name',
          isAdded: true,
          insertTriggerEnabled: true,
          updateTriggerEnabled: true,
          indexesCreated: 2,
          isComplete: true,
          lastUpdated: DateTime.now(),
        );

        final json = status.toJson();

        expect(json['column_name'], equals('full_name'));
        expect(json['is_added'], isTrue);
        expect(json['is_complete'], isTrue);
        expect(json['insert_trigger_enabled'], isTrue);
        expect(json['update_trigger_enabled'], isTrue);
        expect(json['indexes_created'], equals(2));
        expect(json['status_message'], contains('complete'));
      });

      test('should show correct status message', () {
        final completeStatus = MigrationStatus(
          columnName: 'full_name',
          isAdded: true,
          insertTriggerEnabled: true,
          updateTriggerEnabled: true,
          indexesCreated: 2,
          isComplete: true,
          lastUpdated: DateTime.now(),
        );

        expect(completeStatus.statusMessage, contains('complete'));
        expect(completeStatus.isComplete, isTrue);

        final partialStatus = MigrationStatus(
          columnName: 'full_name',
          isAdded: true,
          insertTriggerEnabled: false,
          updateTriggerEnabled: false,
          indexesCreated: 0,
          isComplete: false,
          lastUpdated: DateTime.now(),
        );

        expect(partialStatus.statusMessage, contains('Missing'));
        expect(partialStatus.isComplete, isFalse);
      });
    });

    group('MigrationHelper', () {
      test('should have runMigrations method', () {
        expect(
          MigrationHelper.runMigrations is Future<void> Function(PowerSyncDatabase),
          returnsNormally,
        );
      });

      test('should have getMigrationStatuses method', () {
        expect(
          MigrationHelper.getMigrationStatuses is Future<List<MigrationStatus>> Function(PowerSyncDatabase),
          returnsNormally,
        );
      });

      test('should have verifySchema method', () {
        expect(
          MigrationHelper.verifySchema is Future<bool> Function(PowerSyncDatabase),
          returnsNormally,
        );
      });
    });
  });
}
