import 'package:imu_flutter/services/api/client_api_service.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';
import 'package:imu_flutter/core/utils/logger.dart';
import 'package:imu_flutter/services/error_logging_helper.dart';

/// Service for initial sync of assigned clients from API to PowerSync SQLite
///
/// This bypasses the PowerSync sync mechanism to load all assigned clients
/// on first login, avoiding the 1000-row PowerSync limit.
class InitialSyncService {
  /// Sync all assigned clients from API to PowerSync SQLite
  ///
  /// Returns the total number of clients synced
  /// [onProgress] callback receives (current, total) counts
  /// [onError] callback receives error messages
  static Future<int> syncAssignedClients({
    required Function(int current, int total) onProgress,
    required Function(String error) onError,
  }) async {
    final clientApi = ClientApiService();
    int totalFetched = 0;
    int totalCount = 0;
    int page = 1;
    const int perPage = 100;

    try {
      logInfo('[InitialSync] Starting initial sync of assigned clients...');

      do {
        logDebug('[InitialSync] Fetching page $page...');

        // Fetch page from API
        final response = await clientApi.fetchClients(
          page: page,
          perPage: perPage,
        );

        totalCount = response.totalItems.toInt();
        final clients = response.items;

        logDebug('[InitialSync] Fetched ${clients.length} clients (total: $totalCount)');

        // Insert clients to PowerSync SQLite in batches
        await _insertClientsToPowerSync(clients);

        totalFetched += clients.length;
        onProgress(totalFetched, totalCount);

        logDebug('[InitialSync] Synced $totalFetched/$totalCount clients');

        page++;

        // Small delay to avoid overwhelming the database
        if (clients.length == perPage) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      } while (totalFetched < totalCount);

      logInfo('[InitialSync] ✅ Initial sync complete: $totalFetched clients synced');
      return totalFetched;

    } catch (e, stackTrace) {
      logError('[InitialSync] ❌ Failed to sync clients', e);

      // Log error but don't block login
      await ErrorLoggingHelper.logNonCriticalError(
        operation: 'Initial clients sync',
        error: e,
        stackTrace: stackTrace,
        context: {
          'page': page,
          'totalFetched': totalFetched,
          'totalCount': totalCount,
        },
      );

      onError('Failed to sync clients: ${e.toString()}');
      rethrow;
    }
  }

  /// Insert a batch of clients to PowerSync SQLite directly
  static Future<void> _insertClientsToPowerSync(List<Client> clients) async {
    try {
      for (final client in clients) {
        // Convert Client model to PowerSync format
        final clientData = _clientToPowerSyncMap(client);

        // Use INSERT OR REPLACE to handle duplicates
        await PowerSyncService.execute(
          '''
          INSERT OR REPLACE INTO clients (
            id, first_name, last_name, middle_name, birth_date, email, phone,
            agency_name, department, position, employment_status, payroll_date,
            tenure, client_type, product_type, market_type, pension_type,
            pan, facebook_link, remarks, agency_id, psgc_id, province,
            municipality, region, barangay, is_starred, loan_released, udi, full_address
          ) VALUES (
            ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
          )
          ''',
          [
            clientData['id'],
            clientData['first_name'],
            clientData['last_name'],
            clientData['middle_name'],
            clientData['birth_date'],
            clientData['email'],
            clientData['phone'],
            clientData['agency_name'],
            clientData['department'],
            clientData['position'],
            clientData['employment_status'],
            clientData['payroll_date'],
            clientData['tenure'],
            clientData['client_type'],
            clientData['product_type'],
            clientData['market_type'],
            clientData['pension_type'],
            clientData['pan'],
            clientData['facebook_link'],
            clientData['remarks'],
            clientData['agency_id'],
            clientData['psgc_id'],
            clientData['province'],
            clientData['municipality'],
            clientData['region'],
            clientData['barangay'],
            clientData['is_starred'],
            clientData['loan_released'],
            clientData['udi'],
            clientData['full_address'],
          ],
        );
      }

      logDebug('[InitialSync] Inserted ${clients.length} clients to PowerSync');

    } catch (e) {
      logError('[InitialSync] Failed to insert clients to PowerSync', e);
      rethrow;
    }
  }

  /// Convert Client model to PowerSync map format
  static Map<String, dynamic> _clientToPowerSyncMap(Client client) {
    return {
      'id': client.id,
      'first_name': client.firstName,
      'last_name': client.lastName,
      'middle_name': client.middleName,
      'birth_date': client.birthDate?.toIso8601String().split('T')[0], // YYYY-MM-DD
      'email': client.email,
      'phone': client.phone,
      'agency_name': client.agencyName,
      'department': client.department,
      'position': client.position,
      'employment_status': client.employmentStatus,
      'payroll_date': client.payrollDate,
      'tenure': client.tenure,
      'client_type': client.clientType,
      'product_type': client.productType?.name,
      'market_type': client.marketType?.name,
      'pension_type': client.pensionType?.name,
      'pan': client.pan,
      'facebook_link': client.facebookLink,
      'remarks': client.remarks,
      'agency_id': client.agencyId,
      'psgc_id': client.psgcId,
      'province': client.province,
      'municipality': client.municipality,
      'region': client.region,
      'barangay': client.barangay,
      'is_starred': client.isStarred ? 1 : 0,
      'loan_released': client.loanReleased ? 1 : 0,
      'udi': client.udi,
      'full_address': _buildFullAddress(client),
    };
  }

  /// Build full address string from client components
  static String _buildFullAddress(Client client) {
    final parts = <String>[];
    if (client.barangay?.isNotEmpty == true) parts.add(client.barangay!);
    if (client.municipality?.isNotEmpty == true) parts.add(client.municipality!);
    if (client.province?.isNotEmpty == true) parts.add(client.province!);
    return parts.join(', ');
  }

  /// Check if initial sync is needed (local clients table is empty)
  static Future<bool> needsInitialSync() async {
    try {
      logDebug('[InitialSync] Checking if initial sync is needed...');

      final result = await PowerSyncService.query(
        'SELECT COUNT(*) as count FROM clients',
      );

      final count = result.first['count'] as int? ?? 0;
      final needsSync = count == 0;

      logDebug('[InitialSync] Local clients count: $count, needs sync: $needsSync');
      return needsSync;

    } catch (e) {
      logError('[InitialSync] Failed to check local clients count', e);
      // Assume sync is needed if we can't check
      return true;
    }
  }

  /// Get local clients count
  static Future<int> getLocalClientsCount() async {
    try {
      final result = await PowerSyncService.query(
        'SELECT COUNT(*) as count FROM clients',
      );
      return result.first['count'] as int? ?? 0;
    } catch (e) {
      logError('[InitialSync] Failed to get local clients count', e);
      return 0;
    }
  }
}
