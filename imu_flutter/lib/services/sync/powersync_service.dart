import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../core/utils/logger.dart';

/// PowerSync database schema matching PostgreSQL tables
const Schema _powerSyncSchema = Schema([
  Table('clients', [
    Column.text('first_name'),
    Column.text('last_name'),
    Column.text('middle_name'),
    Column.text('birth_date'),
    Column.text('email'),
    Column.text('phone'),
    Column.text('agency_name'),
    Column.text('department'),
    Column.text('position'),
    Column.text('employment_status'),
    Column.text('payroll_date'),
    Column.integer('tenure'),
    Column.text('client_type'),
    Column.text('product_type'),
    Column.text('market_type'),
    Column.text('pension_type'),
    Column.text('pan'),
    Column.text('facebook_link'),
    Column.text('remarks'),
    Column.text('agency_id'),
    Column.text('caravan_id'),
    Column.integer('is_starred'),
  ]),
  Table('addresses', [
    Column.text('client_id'),
    Column.text('type'),
    Column.text('street'),
    Column.text('barangay'),
    Column.text('city'),
    Column.text('province'),
    Column.text('postal_code'),
    Column.real('latitude'),
    Column.real('longitude'),
    Column.integer('is_primary'),
  ]),
  Table('phone_numbers', [
    Column.text('client_id'),
    Column.text('type'),
    Column.text('number'),
    Column.text('label'),
    Column.integer('is_primary'),
  ]),
  Table('touchpoints', [
    Column.text('client_id'),
    Column.text('caravan_id'),
    Column.integer('touchpoint_number'),
    Column.text('type'),
    Column.text('date'),
    Column.text('address'),
    Column.text('time_arrival'),
    Column.text('time_departure'),
    Column.text('odometer_arrival'),
    Column.text('odometer_departure'),
    Column.text('reason'),
    Column.text('next_visit_date'),
    Column.text('notes'),
    Column.text('photo_url'),
    Column.text('audio_url'),
    Column.real('latitude'),
    Column.real('longitude'),
  ]),
  Table('itineraries', [
    Column.text('caravan_id'),
    Column.text('client_id'),
    Column.text('scheduled_date'),
    Column.text('scheduled_time'),
    Column.text('status'),
    Column.text('priority'),
    Column.text('notes'),
  ]),
  Table('user_profiles', [
    Column.text('user_id'),
    Column.text('name'),
    Column.text('email'),
    Column.text('role'),
    Column.text('avatar_url'),
  ]),
]);

/// PowerSync service managing the local SQLite database
class PowerSyncService {
  static PowerSyncDatabase? _database;
  static const String _databaseName = 'imu_powersync.db';

  /// Get the database path
  static Future<String> _getDatabasePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, _databaseName);
  }

  /// Initialize and get the PowerSync database
  static Future<PowerSyncDatabase> get database async {
    if (_database != null) return _database!;

    final dbPath = await _getDatabasePath();
    logDebug('Opening PowerSync database at: $dbPath');

    final db = PowerSyncDatabase(
      schema: _powerSyncSchema,
      path: dbPath,
    );
    await db.initialize();

    _database = db;
    logDebug('PowerSync database initialized');
    return db;
  }

  /// Get sync status stream
  static Stream<SyncStatus> get syncStatus {
    if (_database == null) {
      return Stream.value(SyncStatus());
    }
    // Return a simple status stream based on connection state
    return Stream.periodic(
      const Duration(seconds: 1),
      (_) => SyncStatus(
        connected: _database?.connected ?? false,
        pendingUploads: 0,
      ),
    );
  }

  /// Check if connected to PowerSync service
  static bool get isConnected => _database?.connected ?? false;

  /// Get pending upload count
  static int get pendingUploadCount => 0; // Simplified for now

  /// Close the database
  static Future<void> close() async {
    await _database?.close();
    _database = null;
    logDebug('PowerSync database closed');
  }
}

/// Sync status data class
class SyncStatus {
  final bool connected;
  final bool uploading;
  final bool downloading;
  final DateTime? lastSyncAt;
  final int pendingUploads;

  SyncStatus({
    this.connected = false,
    this.uploading = false,
    this.downloading = false,
    this.lastSyncAt,
    this.pendingUploads = 0,
  });
}

/// Riverpod provider for PowerSync database
final powerSyncDatabaseProvider = FutureProvider<PowerSyncDatabase>((ref) async {
  return await PowerSyncService.database;
});

/// Provider for sync status stream
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  return PowerSyncService.syncStatus;
});
