import 'package:powersync/powersync.dart';

/// PowerSync database schema V2 with normalized touchpoints
///
/// This schema adds:
/// - visits table: Physical client visits with GPS, odometer, photos
/// - calls table: Phone call touchpoints
/// - releases table: Loan release applications
/// - Updated touchpoints table: Now references visits/calls via foreign keys
const Schema powerSyncSchemaV2 = Schema([
  // ==================== CLIENT DATA ====================
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
    Column.integer('psgc_id'),
    Column.text('province'),
    Column.text('municipality'),
    Column.text('region'),
    Column.text('barangay'),
    Column.integer('is_starred'),
    Column.integer('loan_released'),
    Column.text('udi'),
    Column.text('full_address'),
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

  // ==================== NORMALIZED TABLES ====================

  /// Visits table: Physical client visits with GPS, odometer, photos
  Table('visits', [
    Column.text('client_id'),
    Column.text('user_id'),
    Column.text('type'), // regular_visit | release_loan
    Column.text('time_in'),
    Column.text('time_out'),
    Column.text('odometer_arrival'),
    Column.text('odometer_departure'),
    Column.text('photo_url'),
    Column.text('notes'),
    Column.text('reason'),
    Column.text('status'),
    Column.text('address'),
    Column.real('latitude'),
    Column.real('longitude'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  /// Calls table: Phone call touchpoints
  Table('calls', [
    Column.text('client_id'),
    Column.text('user_id'),
    Column.text('phone_number'),
    Column.text('dial_time'),
    Column.integer('duration'),
    Column.text('notes'),
    Column.text('reason'),
    Column.text('status'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  /// Releases table: Loan release applications
  Table('releases', [
    Column.text('client_id'),
    Column.text('user_id'),
    Column.text('visit_id'), // Foreign key to visits table
    Column.text('product_type'), // PUSU | LIKA | SUB2K
    Column.text('loan_type'), // NEW | ADDITIONAL | RENEWAL | PRETERM
    Column.real('amount'),
    Column.text('approval_notes'),
    Column.text('status'), // pending | approved | rejected | disbursed
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  /// Touchpoints table (V2): Now references visits/calls via foreign keys
  /// Maintains touchpoint sequence (1-7) for client journey tracking
  Table('touchpoints', [
    Column.text('client_id'),
    Column.text('user_id'),
    Column.text('visit_id'), // Foreign key to visits (nullable)
    Column.text('call_id'), // Foreign key to calls (nullable)
    Column.integer('touchpoint_number'), // 1-7 (sequential)
    Column.text('type'), // Visit | Call
    Column.text('rejection_reason'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  // ==================== LEGACY DATA (for compatibility) ====================

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

  Table('user_profiles', [
    Column.text('user_id'),
    Column.text('name'),
    Column.text('email'),
    Column.text('role'),
    Column.text('area_manager_id'),
    Column.text('assistant_area_manager_id'),
    Column.text('avatar_url'),
  ]),

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

  Table('psgc', [
    Column.text('region'),
    Column.text('province'),
    Column.text('mun_city_kind'),
    Column.text('mun_city'),
    Column.text('barangay'),
    Column.text('pin_location'),
    Column.text('zip_code'),
  ]),

  Table('touchpoint_reasons', [
    Column.text('reason_code'),
    Column.text('label'),
    Column.text('touchpoint_type'),
    Column.text('role'),
    Column.text('category'),
    Column.integer('sort_order'),
    Column.integer('is_active'),
  ]),

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

/// SQL queries for optimized batch data fetching
///
/// These queries follow the service-layer pattern:
/// - Query visits/calls separately, not nested
/// - Use GROUP BY for aggregations
/// - Filter by user_id and client_id
class PowerSyncQueries {
  /// Batch fetch visits for multiple clients
  static const batchVisitsByClients = '''
    SELECT * FROM visits
    WHERE client_id IN (?)
    ORDER BY created_at DESC
  ''';

  /// Batch fetch calls for multiple clients
  static const batchCallsByClients = '''
    SELECT * FROM calls
    WHERE client_id IN (?)
    ORDER BY created_at DESC
  ''';

  /// Batch fetch releases for multiple clients
  static const batchReleasesByClients = '''
    SELECT * FROM releases
    WHERE client_id IN (?)
    ORDER BY created_at DESC
  ''';

  /// Batch fetch touchpoints with counts
  static const batchTouchpointCounts = '''
    SELECT
      client_id,
      COUNT(*) as count
    FROM touchpoints
    WHERE client_id IN (?)
    GROUP BY client_id
  ''';

  /// Get latest touchpoint for each client
  static const latestTouchpointPerClient = '''
    SELECT
      t1.*
    FROM touchpoints t1
    INNER JOIN (
      SELECT
        client_id,
        MAX(created_at) as latest_date
      FROM touchpoints
      WHERE client_id IN (?)
      GROUP BY client_id
    ) t2 ON t1.client_id = t2.client_id AND t1.created_at = t2.latest_date
  ''';

  /// Get touchpoints for a specific client
  static const touchpointsByClient = '''
    SELECT * FROM touchpoints
    WHERE client_id = ?
    ORDER BY touchpoint_number ASC
  ''';

  /// Get visits for a specific client
  static const visitsByClient = '''
    SELECT * FROM visits
    WHERE client_id = ?
    ORDER BY created_at DESC
  ''';

  /// Get calls for a specific client
  static const callsByClient = '''
    SELECT * FROM calls
    WHERE client_id = ?
    ORDER BY created_at DESC
  ''';

  /// Get releases for a specific client
  static const releasesByClient = '''
    SELECT * FROM releases
    WHERE client_id = ?
    ORDER BY created_at DESC
  ''';

  /// Get pending releases count
  static const pendingReleasesCount = '''
    SELECT COUNT(*) as count FROM releases
    WHERE status = 'pending'
  ''';
}
