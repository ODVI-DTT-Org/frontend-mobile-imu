/// PowerSync database triggers for maintaining computed columns
/// Automatically populates full_name column for efficient search
library;

import 'package:powersync/powersync.dart';
import 'package:imu_flutter/core/utils/logger.dart' show appLogger;

/// SQL triggers to automatically maintain full_name column
class PowerSyncTriggers {
  /// Create triggers for automatic full_name population
  static const List<String> triggers = [
    // Trigger: Automatically populate full_name on INSERT
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

    // Trigger: Automatically populate full_name on UPDATE
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

    // Index: Optimize full_name searches with LOWER() index
    '''
    CREATE INDEX IF NOT EXISTS idx_clients_full_name_lower
    ON clients(LOWER(full_name))
    ''',

    // Index: Optimize full_name searches with COLLATE NOCASE
    '''
    CREATE INDEX IF NOT EXISTS idx_clients_full_name_nocase
    ON clients(full_name COLLATE NOCASE)
    ''',
  ];

  /// Initialize all triggers and indexes
  static Future<void> initializeTriggers(PowerSyncDatabase database) async {
    try {
      for (final trigger in triggers) {
        await database.execute(trigger);
        appLogger.i('PowerSync trigger/index created successfully');
      }

      appLogger.i('All PowerSync triggers and indexes initialized');
    } catch (e) {
      appLogger.e('Failed to initialize PowerSync triggers: $e');
      rethrow;
    }
  }

  /// Get SQL for populating full_name for existing records
  static String getBackfillFullNameSQL() {
    return '''
    UPDATE clients
    SET full_name = last_name || ', ' || first_name ||
                CASE WHEN middle_name IS NOT NULL AND middle_name != ''
                     THEN ' ' || middle_name
                     ELSE ''
                END
    WHERE full_name IS NULL OR full_name = ''
    ''';
  }

  /// Backfill full_name for existing records
  static Future<void> backfillFullNames(PowerSyncDatabase database) async {
    try {
      final result = await database.execute(getBackfillFullNameSQL());
      appLogger.i('Backfilled full_name for existing clients');
    } catch (e) {
      appLogger.e('Failed to backfill full_name: $e');
      rethrow;
    }
  }

  /// Check if triggers are properly set up
  static Future<bool> areTriggersEnabled(PowerSyncDatabase database) async {
    try {
      final result = await database.get('''
        SELECT COUNT(*) as trigger_count
        FROM sqlite_master
        WHERE type = 'trigger'
        AND name LIKE '%clients%_full_name_trigger'
      ''');

      final triggerCount = result?['trigger_count'] as int? ?? 0;
      return triggerCount >= 2; // Should have at least INSERT and UPDATE triggers
    } catch (e) {
      appLogger.e('Failed to check triggers: $e');
      return false;
    }
  }

  /// Get trigger status information
  static Future<PowerSyncTriggerStatus> getTriggerStatus(PowerSyncDatabase database) async {
    try {
      // Check triggers
      final triggers = await database.getAll('''
        SELECT name, sql
        FROM sqlite_master
        WHERE type = 'trigger'
        AND name LIKE '%clients%'
        ORDER BY name
      ''');

      // Check indexes
      final indexes = await database.getAll('''
        SELECT name
        FROM sqlite_master
        WHERE type = 'index'
        AND tbl_name = 'clients'
        AND name LIKE '%full_name%'
        ORDER BY name
      ''');

      final hasInsertTrigger = triggers.any((t) => t['name'].toString().contains('insert_full_name'));
      final hasUpdateTrigger = triggers.any((t) => t['name'].toString().contains('update_full_name'));
      final hasLowerIndex = indexes.any((i) => i['name'].toString().contains('full_name_lower'));
      final hasNocaseIndex = indexes.any((i) => i['name'].toString().contains('full_name_nocase'));

      return PowerSyncTriggerStatus(
        insertTriggerEnabled: hasInsertTrigger,
        updateTriggerEnabled: hasUpdateTrigger,
        lowerIndexEnabled: hasLowerIndex,
        nocaseIndexEnabled: hasNocaseIndex,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      appLogger.e('Failed to get trigger status: $e');
      return PowerSyncTriggerStatus(
        insertTriggerEnabled: false,
        updateTriggerEnabled: false,
        lowerIndexEnabled: false,
        nocaseIndexEnabled: false,
        lastUpdated: DateTime.now(),
      );
    }
  }
}

/// Status of PowerSync triggers and indexes
class PowerSyncTriggerStatus {
  final bool insertTriggerEnabled;
  final bool updateTriggerEnabled;
  final bool lowerIndexEnabled;
  final bool nocaseIndexEnabled;
  final DateTime lastUpdated;

  PowerSyncTriggerStatus({
    required this.insertTriggerEnabled,
    required this.updateTriggerEnabled,
    required this.lowerIndexEnabled,
    required this.nocaseIndexEnabled,
    required this.lastUpdated,
  });

  /// Check if all components are properly enabled
  bool get isFullyConfigured =>
      insertTriggerEnabled &&
      updateTriggerEnabled &&
      (lowerIndexEnabled || nocaseIndexEnabled);

  /// Get configuration status message
  String get statusMessage {
    if (isFullyConfigured) {
      return 'All triggers and indexes properly configured';
    }

    final missing = <String>[];
    if (!insertTriggerEnabled) missing.add('INSERT trigger');
    if (!updateTriggerEnabled) missing.add('UPDATE trigger');
    if (!lowerIndexEnabled && !nocaseIndexEnabled) missing.add('full_name indexes');

    return 'Missing: ${missing.join(', ')}';
  }

  @override
  String toString() =>
      'PowerSyncTriggerStatus(insert: $insertTriggerEnabled, update: $updateTriggerEnabled, indexes: ${lowerIndexEnabled || nocaseIndexEnabled})';
