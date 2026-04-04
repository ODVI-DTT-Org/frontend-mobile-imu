import 'package:flutter_test/flutter_test.dart';
import 'package:powersync/powersync.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';

void main() {
  group('PowerSync Schema Validation', () {
    late Schema schema;

    setUpAll(() {
      schema = powerSyncSchema;
    });

    test('psgc table should not have custom id column', () {
      // Find the psgc table in the schema
      final psgcTable = schema.tables.firstWhere(
        (table) => table.name == 'psgc',
        orElse: () => throw Exception('psgc table not found'),
      );

      // Verify that 'id' column is NOT defined (PowerSync adds it automatically)
      final hasIdColumn = psgcTable.columns.any(
        (column) => column.name == 'id',
      );

      expect(
        hasIdColumn,
        false,
        reason: 'psgc table should not define custom id column - PowerSync adds it automatically',
      );
    });

    test('psgc table should have all required columns', () {
      final psgcTable = schema.tables.firstWhere(
        (table) => table.name == 'psgc',
        orElse: () => throw Exception('psgc table not found'),
      );

      // Check for required columns
      final columnNames = psgcTable.columns.map((c) => c.name).toList();

      expect(columnNames, contains('region'));
      expect(columnNames, contains('province'));
      expect(columnNames, contains('mun_city_kind'));
      expect(columnNames, contains('mun_city'));
      expect(columnNames, contains('barangay'));
      expect(columnNames, contains('pin_location'));
      expect(columnNames, contains('zip_code'));
    });

    test('touchpoint_reasons table should not have custom id column', () {
      final touchpointReasonsTable = schema.tables.firstWhere(
        (table) => table.name == 'touchpoint_reasons',
        orElse: () => throw Exception('touchpoint_reasons table not found'),
      );

      final hasIdColumn = touchpointReasonsTable.columns.any(
        (column) => column.name == 'id',
      );

      expect(
        hasIdColumn,
        false,
        reason: 'touchpoint_reasons table should not define custom id column',
      );
    });

    test('all tables should have at least one column', () {
      for (final table in schema.tables) {
        expect(
          table.columns.isNotEmpty,
          true,
          reason: 'Table ${table.name} should have at least one column',
        );
      }
    });

    test('schema should not have duplicate table names', () {
      final tableNames = schema.tables.map((t) => t.name).toList();
      final uniqueNames = tableNames.toSet();

      expect(
        uniqueNames.length,
        tableNames.length,
        reason: 'Schema should not have duplicate table names',
      );
    });

    test('schema should contain all required tables', () {
      final tableNames = schema.tables.map((t) => t.name).toSet();

      // Verify all core tables exist
      expect(tableNames, contains('clients'));
      expect(tableNames, contains('addresses'));
      expect(tableNames, contains('phone_numbers'));
      expect(tableNames, contains('touchpoints'));
      expect(tableNames, contains('itineraries'));
      expect(tableNames, contains('user_profiles'));
      expect(tableNames, contains('user_locations'));
      expect(tableNames, contains('approvals'));
      expect(tableNames, contains('psgc'));
      expect(tableNames, contains('touchpoint_reasons'));
    });
  });
}
