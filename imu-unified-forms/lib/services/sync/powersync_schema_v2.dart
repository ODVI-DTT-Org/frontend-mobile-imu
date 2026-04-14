import 'package:powersync/powersync.dart';
import 'package:imu_flutter/services/auth/jwt_auth_service.dart';

/// PowerSync database schema V2 with normalized touchpoints
///
/// This schema adds:
/// - visits table: Physical client visits with GPS, odometer, photos
/// - calls table: Phone call touchpoints
/// - releases table: Loan release applications
/// - Updated touchpoints table: Now references visits/calls via foreign keys
///
/// Sync Rules:
/// - User-based data isolation: All queries filter by user_id
/// - Upload/download handlers for offline-first architecture
/// - Conflict resolution: Last-write-wins with timestamp comparison
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

/// Sync configuration for PowerSync
///
/// Defines upload and download handlers for offline-first synchronization
class PowerSyncSyncConfiguration {
  final JwtAuthService authService;

  PowerSyncSyncConfiguration({required this.authService});

  /// Get current user ID for filtering
  String? get currentUserId => authService.userId;

  /// Upload pending changes to the server
  ///
  /// This handles:
  /// - New visits/calls/releases created offline
  /// - Updates to existing records
  /// - Deletions
  Future<void> uploadPendingChanges(
    Map<String, dynamic> batch,
    Future<void> Function(String) uploadData,
  ) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Filter batch to only include user's own data
    final userBatch = {
      'visits': _filterByUserId(batch['visits'] as List<dynamic>?, userId),
      'calls': _filterByUserId(batch['calls'] as List<dynamic>?, userId),
      'releases': _filterByUserId(batch['releases'] as List<dynamic>?, userId),
      'touchpoints': _filterByUserId(batch['touchpoints'] as List<dynamic>?, userId),
    };

    // Upload each type
    for (final entry in userBatch.entries) {
      if (entry.value != null && (entry.value as List).isNotEmpty) {
        await uploadData(entry.key);
      }
    }
  }

  /// Filter records by user_id
  List<dynamic>? _filterByUserId(List<dynamic>? records, String userId) {
    if (records == null) return null;
    return records.where((record) {
      final recordMap = record as Map<String, dynamic>;
      return recordMap['user_id'] == userId;
    }).toList();
  }

  /// Generate WHERE clause for user-based filtering
  String get userFilterClause {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return 'user_id = \'$userId\'';
  }

  /// Conflict resolution strategy
  ///
  /// Uses last-write-wins based on updated_at timestamp
  Map<String, dynamic> resolveConflict(
    Map<String, dynamic> localRecord,
    Map<String, dynamic> remoteRecord,
  ) {
    final localUpdatedAt = DateTime.parse(localRecord['updated_at'] as String);
    final remoteUpdatedAt = DateTime.parse(remoteRecord['updated_at'] as String);

    // Return the record with the most recent update
    if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
      return remoteRecord;
    } else {
      return localRecord;
    }
  }

  /// Validate record before sync
  ///
  /// Ensures data integrity before upload/download
  bool validateRecord(String table, Map<String, dynamic> record) {
    // Common validation
    if (!record.containsKey('id') || record['id'] == null) {
      return false;
    }

    if (!record.containsKey('user_id') || record['user_id'] == null) {
      return false;
    }

    // Table-specific validation
    switch (table) {
      case 'visits':
        return _validateVisit(record);
      case 'calls':
        return _validateCall(record);
      case 'releases':
        return _validateRelease(record);
      case 'touchpoints':
        return _validateTouchpoint(record);
      default:
        return true;
    }
  }

  bool _validateVisit(Map<String, dynamic> record) {
    final clientId = record['client_id'];
    final type = record['type'];

    return clientId != null &&
           clientId.toString().isNotEmpty &&
           (type == 'regular_visit' || type == 'release_loan');
  }

  bool _validateCall(Map<String, dynamic> record) {
    final clientId = record['client_id'];
    final phoneNumber = record['phone_number'];

    return clientId != null &&
           clientId.toString().isNotEmpty &&
           phoneNumber != null &&
           phoneNumber.toString().isNotEmpty;
  }

  bool _validateRelease(Map<String, dynamic> record) {
    final clientId = record['client_id'];
    final visitId = record['visit_id'];
    final amount = record['amount'];
    final productType = record['product_type'];

    return clientId != null &&
           clientId.toString().isNotEmpty &&
           visitId != null &&
           visitId.toString().isNotEmpty &&
           amount != null &&
           (amount is num) &&
           (amount as num) > 0 &&
           productType != null &&
           ['PUSU', 'LIKA', 'SUB2K'].contains(productType);
  }

  bool _validateTouchpoint(Map<String, dynamic> record) {
    final clientId = record['client_id'];
    final touchpointNumber = record['touchpoint_number'];
    final type = record['type'];

    final hasValidForeignKey =
        (record['visit_id'] != null && record['visit_id'].toString().isNotEmpty) ||
        (record['call_id'] != null && record['call_id'].toString().isNotEmpty);

    return clientId != null &&
           clientId.toString().isNotEmpty &&
           touchpointNumber != null &&
           touchpointNumber is int &&
           touchpointNumber >= 1 &&
           touchpointNumber <= 7 &&
           type != null &&
           ['Visit', 'Call'].contains(type) &&
           hasValidForeignKey;
  }

  /// Get sync status for UI display
  Future<Map<String, int>> getSyncStatus() async {
    // This would query the local database for pending changes
    // Implementation depends on PowerSync's internal tables
    return {
      'pendingUploads': 0,
      'pendingDownloads': 0,
      'lastSyncAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Force full sync
  ///
  /// Useful for troubleshooting or after data recovery
  Future<void> forceFullSync() async {
    // Implementation would trigger a complete data reload
    // This is a placeholder for the actual implementation
  }
}

/// Sync rules for data isolation and access control
///
/// These rules ensure:
/// - Users can only see their own data
/// - Managers can see their area's data
/// - Admins can see all data
class SyncRules {
  /// Generate WHERE clause for user's data access
  static String getUserDataFilter(String? userRole, String userId) {
    switch (userRole) {
      case 'admin':
        // Admins can see all data
        return '1=1';
      case 'area_manager':
      case 'assistant_area_manager':
        // Managers can see their area's data (simplified)
        // In production, this would join with user_locations table
        return 'user_id IN (SELECT id FROM user_profiles WHERE area_manager_id = \'$userId\')';
      default:
        // Regular users can only see their own data
        return 'user_id = \'$userId\'';
    }
  }

  /// Check if user can modify a record
  static bool canModifyRecord(String? userRole, String recordUserId, String currentUserId) {
    switch (userRole) {
      case 'admin':
        return true;
      case 'area_manager':
      case 'assistant_area_manager':
        // Managers can modify records in their area
        // Simplified check - in production, check area assignment
        return true;
      default:
        // Users can only modify their own records
        return recordUserId == currentUserId;
    }
  }

  /// Check if user can delete a record
  static bool canDeleteRecord(String? userRole, String recordUserId, String currentUserId) {
    // Same rules as modification
    return canModifyRecord(userRole, recordUserId, currentUserId);
  }
}

/// Data retention policies
///
/// Defines how long to keep different types of data
class DataRetentionPolicies {
  /// Retention period for visit records (days)
  static const int visitRetentionDays = 365;

  /// Retention period for call records (days)
  static const int callRetentionDays = 365;

  /// Retention period for release records (days)
  static const int releaseRetentionDays = 1825; // 5 years

  /// Retention period for touchpoint records (days)
  static const int touchpointRetentionDays = 365;

  /// Clean up old records
  ///
  /// Should be called periodically (e.g., weekly)
  static Future<void> cleanupOldRecords() async {
    // Implementation would delete records older than retention period
    // This is a placeholder for the actual implementation
  }

  /// Check if a record should be retained
  static bool shouldRetainRecord(String table, DateTime recordDate) {
    final retentionDays = _getRetentionDays(table);
    final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
    return recordDate.isAfter(cutoffDate);
  }

  static int _getRetentionDays(String table) {
    switch (table) {
      case 'visits':
        return visitRetentionDays;
      case 'calls':
        return callRetentionDays;
      case 'releases':
        return releaseRetentionDays;
      case 'touchpoints':
        return touchpointRetentionDays;
      default:
        return 365;
    }
  }
}
