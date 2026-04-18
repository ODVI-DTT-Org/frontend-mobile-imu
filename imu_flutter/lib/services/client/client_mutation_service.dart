import 'package:uuid/uuid.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';
import 'package:imu_flutter/core/utils/logger.dart';

enum ClientMutationResult { success, requiresApproval, queued }

/// Mutates clients by writing directly to local SQLite.
/// PowerSync CRUD queue handles delivery to the backend when online.
class ClientMutationService {
  final _uuid = const Uuid();

  Future<ClientMutationResult> createClient(Client client) async {
    final db = await PowerSyncService.database;
    final id = client.id ?? _uuid.v4();
    final now = DateTime.now().toIso8601String();

    logDebug('ClientMutationService: Creating client $id in SQLite');

    await db.execute(
      '''INSERT OR REPLACE INTO clients
         (id, first_name, last_name, middle_name, birth_date, email, phone,
          agency_name, department, position, employment_status, payroll_date,
          tenure, client_type, product_type, market_type, pension_type,
          loan_type, pan, facebook_link, remarks, agency_id, psgc_id,
          province, municipality, region, barangay, is_starred,
          loan_released, udi, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        id,
        client.firstName,
        client.lastName,
        client.middleName,
        client.birthDate?.toIso8601String(),
        client.email,
        client.phone,
        client.agencyName,
        client.department,
        client.position,
        client.employmentStatus,
        client.payrollDate,
        client.tenure,
        client.clientType.name,
        client.productType.name,
        client.marketType?.name,
        client.pensionType.name,
        client.loanType?.name,
        client.pan,
        client.facebookLink,
        client.remarks,
        client.agencyId,
        client.psgcId,
        client.province,
        client.municipality,
        client.region,
        client.barangay,
        client.isStarred ? 1 : 0,
        client.loanReleased ? 1 : 0,
        client.udi,
        now,
      ],
    );

    return ClientMutationResult.success;
  }

  Future<ClientMutationResult> updateClient(Client client) async {
    final db = await PowerSyncService.database;
    logDebug('ClientMutationService: Updating client ${client.id} in SQLite');

    await db.execute(
      '''UPDATE clients SET
         first_name=?, last_name=?, middle_name=?, birth_date=?, email=?,
         phone=?, agency_name=?, department=?, position=?,
         employment_status=?, payroll_date=?, tenure=?, client_type=?,
         product_type=?, market_type=?, pension_type=?, loan_type=?,
         pan=?, facebook_link=?, remarks=?, agency_id=?, psgc_id=?,
         province=?, municipality=?, region=?, barangay=?, is_starred=?,
         loan_released=?, udi=?, updated_at=?
         WHERE id=?''',
      [
        client.firstName,
        client.lastName,
        client.middleName,
        client.birthDate?.toIso8601String(),
        client.email,
        client.phone,
        client.agencyName,
        client.department,
        client.position,
        client.employmentStatus,
        client.payrollDate,
        client.tenure,
        client.clientType.name,
        client.productType.name,
        client.marketType?.name,
        client.pensionType.name,
        client.loanType?.name,
        client.pan,
        client.facebookLink,
        client.remarks,
        client.agencyId,
        client.psgcId,
        client.province,
        client.municipality,
        client.region,
        client.barangay,
        client.isStarred ? 1 : 0,
        client.loanReleased ? 1 : 0,
        client.udi,
        DateTime.now().toIso8601String(),
        client.id,
      ],
    );

    return ClientMutationResult.success;
  }

  Future<ClientMutationResult> deleteClient(String clientId) async {
    final db = await PowerSyncService.database;
    logDebug('ClientMutationService: Deleting client $clientId from SQLite');

    await db.execute('DELETE FROM clients WHERE id = ?', [clientId]);

    return ClientMutationResult.success;
  }
}
