import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../core/utils/logger.dart';
import '../../core/config/app_config.dart';
import '../error_logging_helper.dart';
import 'powersync_connector.dart';

/// PowerSync database schema matching PostgreSQL tables
const Schema _powerSyncSchema = Schema([
  // Client data - Note: PowerSync automatically adds an 'id' column
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
    Column.text('loan_type'), // NEW: Loan type field
    Column.text('pan'),
    Column.text('facebook_link'),
    Column.text('remarks'),
    Column.text('agency_id'),
    Column.integer('psgc_id'), // INTEGER in database schema
    Column.text('province'),
    Column.text('municipality'),
    Column.text('region'),
    Column.text('barangay'),
    Column.integer('is_starred'),
    Column.integer('loan_released'),
    Column.text('udi'),
    Column.text('full_address'),
    // Audit fields - NEW
    Column.text('created_by'), // User ID of who created the client
    Column.text('deleted_by'), // User ID of who soft-deleted the client
    Column.text('deleted_at'), // Soft delete timestamp
    Column.text('created_at'), // Creation timestamp
    Column.text('updated_at'), // Update timestamp
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
    Column.text('user_id'),
    Column.integer('touchpoint_number'),
    Column.text('type'),
    Column.text('date'),
    Column.text('address'),
    Column.text('time_arrival'),
    Column.text('time_departure'),
    Column.text('odometer_arrival'),
    Column.text('odometer_departure'),
    Column.text('reason'),
    Column.text('status'),
    Column.text('next_visit_date'),
    Column.text('notes'),
    Column.text('photo_url'),
    Column.text('audio_url'),
    Column.real('latitude'),
    Column.real('longitude'),
    Column.text('time_in'),
    Column.real('time_in_gps_lat'),
    Column.real('time_in_gps_lng'),
    Column.text('time_in_gps_address'),
    Column.text('time_out'),
    Column.real('time_out_gps_lat'),
    Column.real('time_out_gps_lng'),
    Column.text('time_out_gps_address'),
    Column.text('rejection_reason'),
    Column.text('updated_at'), // NEW: Last update timestamp
  ]),
  Table('itineraries', [
    Column.text('user_id'),
    Column.text('client_id'),
    Column.text('scheduled_date'),
    Column.text('scheduled_time'),
    Column.text('status'),
    Column.text('priority'),
    Column.text('notes'),
    Column.text('created_by'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),
  // User profile data
  Table('user_profiles', [
    Column.text('user_id'),
    Column.text('name'),
    Column.text('email'),
    Column.text('role'),
    Column.text('area_manager_id'),
    Column.text('assistant_area_manager_id'),
    Column.text('avatar_url'),
  ]),
  // User location assignments - province and municipality columns
  Table('user_locations', [
    Column.text('user_id'),
    Column.text('province'),
    Column.text('municipality'),
    Column.text('assigned_at'),
    Column.text('assigned_by'),
    Column.text('deleted_at'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),
  // Approvals (for caravan/tele approval workflow)
  Table('approvals', [
    Column.text('type'),
    Column.text('status'),
    Column.text('client_id'),
    Column.text('user_id'),
    Column.integer('touchpoint_number'),
    Column.text('role'),
    Column.text('reason'),
    Column.text('notes'),
    Column.text('updated_client_information'),
    Column.text('updated_udi'),
    Column.text('udi_number'),
    Column.text('approved_by'),
    Column.text('approved_at'),
    Column.text('rejected_by'),
    Column.text('rejected_at'),
    Column.text('rejection_reason'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),
  // PSGC geographic data (single table with all locations)
  // Note: PowerSync automatically adds an 'id' column, so we don't define it here
  Table('psgc', [
    Column.text('region'),
    Column.text('province'),
    Column.text('mun_city_kind'),
    Column.text('mun_city'),
    Column.text('barangay'),
    Column.text('pin_location'),
    Column.text('zip_code'),
  ]),
  // Touchpoint reasons (global data)
  // Note: PowerSync automatically adds an 'id' column, so we don't define it here
  Table('touchpoint_reasons', [
    Column.text('reason_code'),
    Column.text('label'),
    Column.text('touchpoint_type'),
    Column.text('role'),
    Column.text('category'),
    Column.integer('sort_order'),
    Column.integer('is_active'),
  ]),
  // Error logs for non-critical error queuing
  Table('error_logs', [
    Column.text('code'),
    Column.text('message'),
    Column.text('platform'),
    Column.text('stack_trace'),
    Column.text('user_id'),
    Column.text('request_id'),
    Column.text('fingerprint'),
    Column.text('app_version'),
    Column.text('os_version'),
    Column.text('device_info'),
    Column.text('details'),
    Column.integer('is_synced'),
    Column.text('created_at'),
  ]),
]);

/// PowerSync service managing the local SQLite database
class PowerSyncService {
  static PowerSyncDatabase? _database;
  static const String _databaseName = 'imu_powersync.db';
  static bool _isConnected = false;
  static IMUPowerSyncConnector? _currentConnector;
  static bool _isConnecting = false;

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

  /// Connect to PowerSync with the provided connector
  static Future<void> connect(IMUPowerSyncConnector connector) async {
    // Prevent multiple simultaneous connection attempts
    if (_isConnecting) {
      logDebug('PowerSync connection already in progress, waiting...');
      while (_isConnecting) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (_isConnected) {
        logDebug('PowerSync already connected after waiting');
        return;
      }
    }

    // If already connected with the same connector, do nothing
    if (_isConnected && _currentConnector == connector) {
      logDebug('Already connected to PowerSync with the same connector');
      return;
    }

    // If connected with a different connector, disconnect first
    if (_isConnected && _currentConnector != connector) {
      logDebug('Disconnecting from PowerSync (different connector)');
      await disconnect();
    }

    _isConnecting = true;
    try {
      logDebug('[PowerSync Connect] Starting connection...');
      logDebug('[PowerSync Connect] PowerSync URL: ${AppConfig.powerSyncUrl}');
      logDebug('[PowerSync Connect] Database path: ${await _getDatabasePath()}');

      final db = await database;
      logDebug('[PowerSync Connect] Database instance created');

      await db.connect(connector: connector);
      _currentConnector = connector;
      _isConnected = true;
      _isConnecting = false;
      logDebug('✅ [PowerSync Connect] Connected to PowerSync successfully');
    } catch (e, stackTrace) {
      _isConnecting = false;
      logError('❌ [PowerSync Connect] Failed to connect to PowerSync', e);
      logError('[PowerSync Connect] Error type: ${e.runtimeType}');
      logError('[PowerSync Connect] Error message: ${e.toString()}');

      // Check if it's a SyncResponseException
      if (e.toString().contains('SyncResponseException')) {
        logError('[PowerSync Connect] PowerSync service returned error response');
        logError('[PowerSync Connect] This usually means:');
        logError('[PowerSync Connect] 1. Database connection failed');
        logError('[PowerSync Connect] 2. Sync configuration has errors');
        logError('[PowerSync Connect] 3. PowerSync service internal error');
      }

      await ErrorLoggingHelper.logCriticalError(
        operation: 'PowerSync connect',
        error: e,
        stackTrace: stackTrace,
        context: {
          'powersyncUrl': AppConfig.powerSyncUrl,
          'errorType': e.runtimeType.toString(),
          'errorMessage': e.toString(),
        },
      );
      rethrow;
    }
  }

  /// Disconnect from PowerSync
  static Future<void> disconnect() async {
    if (!_isConnected || _database == null) return;

    try {
      await _database!.disconnect();
      _isConnected = false;
      _currentConnector = null;
      logDebug('Disconnected from PowerSync');
    } catch (e) {
      logError('Failed to disconnect from PowerSync', e);
    }
  }

  /// Close and clear PowerSync database (for logout/user switch)
  static Future<void> closeAndClear() async {
    try {
      // Disconnect if connected
      if (_isConnected && _database != null) {
        await _database!.disconnect();
        _isConnected = false;
      }

      // Close the database completely
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      // Clear the current connector
      _currentConnector = null;

      logDebug('PowerSync database closed and cleared');
    } catch (e) {
      logError('Failed to close PowerSync database', e);
      // Ensure database is nulled even if close fails
      _database = null;
      _currentConnector = null;
    }
  }

  /// Get sync status stream
  static Stream<SyncStatus> get syncStatus {
    if (_database == null) {
      return Stream.value(SyncStatus());
    }
    // Return the actual sync status stream from the database
    return _database!.statusStream.map((status) => SyncStatus(
      connected: status.connected,
      uploading: status.uploading,
      downloading: status.downloading,
      lastSyncAt: DateTime.now(),
      pendingUploads: 0,
    ),);
  }

  /// Wait for initial sync to complete (with timeout)
  static Future<void> waitForInitialSync({Duration timeout = const Duration(seconds: 30)}) async {
    final db = await database;

    if (!db.connected) {
      logDebug('PowerSync not connected, skipping initial sync wait');
      return;
    }

    logDebug('Waiting for initial PowerSync sync...');

    // Create a completer that will complete when sync finishes or times out
    final completer = Completer<void>();
    StreamSubscription? subscription;

    // Timeout timer
    final timeoutTimer = Timer(timeout, () {
      subscription?.cancel();
      if (!completer.isCompleted) {
        logWarning('Initial sync timed out after ${timeout.inSeconds} seconds');
        completer.complete();
      }
    });

    // Listen to sync status
    subscription = db.statusStream.listen((status) {
      if (status.connected && !status.downloading) {
        // Sync has completed or is not downloading
        logDebug('Initial sync completed');
        timeoutTimer.cancel();
        subscription?.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    return completer.future;
  }

  /// Check if connected to PowerSync service
  static bool get isConnected {
    // Check if we have a database and it's connected
    if (_database == null) return false;
    if (!_isConnected) return false;
    // Only return true if the database is actually connected
    return _database!.connected;
  }

  /// Get pending upload count
  static Future<int> get pendingUploadCount async {
    if (_database == null) return 0;
    try {
      final batch = await _database!.getCrudBatch();
      return batch?.crud.length ?? 0;
    } catch (e) {
      logError('Failed to get pending upload count', e);
      return 0;
    }
  }

  /// Execute a SQL query
  static Future<List<Map<String, dynamic>>> query(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    final db = await database;
    return await db.getAll(sql, parameters);
  }

  /// Execute a SQL statement
  static Future<void> execute(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    final db = await database;
    await db.execute(sql, parameters);
  }

  /// Close the database
  static Future<void> close() async {
    await disconnect();
    await _database?.close();
    _database = null;
    _isConnected = false;
    _currentConnector = null;
    _isConnecting = false;
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

/// Provider for PowerSync service
final powerSyncServiceProvider = Provider<PowerSyncService>((ref) {
  return PowerSyncService();
});

/// Get the PowerSync schema (for testing)
Schema get powerSyncSchema => _powerSyncSchema;
