import 'package:uuid/uuid.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/services/api/client_api_service.dart';
import 'package:imu_flutter/services/client/models/pending_client_operation.dart';
import 'package:imu_flutter/services/client/pending_client_service.dart';
import 'package:imu_flutter/services/connectivity_service.dart';
import 'package:imu_flutter/services/local_storage/hive_service.dart';
import 'package:imu_flutter/core/utils/logger.dart';

enum ClientMutationResult { success, requiresApproval, queued }

class ClientMutationService {
  final ConnectivityService _connectivity;
  final ClientApiService _api;
  final PendingClientService _pending;
  final HiveService _hive;
  final _uuid = const Uuid();

  ClientMutationService(
    this._connectivity,
    this._api,
    this._pending,
    this._hive,
  );

  Future<ClientMutationResult> createClient(Client client) async {
    if (_connectivity.isOnline) {
      final result = await _api.createClient(client);
      if (result != null) {
        await _hive.saveClient(result.id!, result.toJson());
        return ClientMutationResult.success;
      }
      return ClientMutationResult.requiresApproval;
    }

    final tempId = _uuid.v4();
    final clientData = <String, dynamic>{...client.toJson(), 'id': tempId};
    await _hive.saveClient(tempId, clientData);
    await _pending.enqueue(PendingClientOperation(
      id: _uuid.v4(),
      operation: ClientOperationType.create,
      clientId: tempId,
      clientData: clientData,
      createdAt: DateTime.now(),
    ));
    logDebug('ClientMutationService: queued create for temp client $tempId');
    return ClientMutationResult.queued;
  }

  Future<ClientMutationResult> updateClient(Client client) async {
    // Optimistic update: persist to Hive immediately so UI stays current
    await _hive.saveClient(client.id!, client.toJson());

    if (_connectivity.isOnline) {
      final result = await _api.updateClient(client);
      if (result != null) {
        await _hive.saveClient(result.id!, result.toJson());
        return ClientMutationResult.success;
      }
      return ClientMutationResult.requiresApproval;
    }

    await _pending.enqueue(PendingClientOperation(
      id: _uuid.v4(),
      operation: ClientOperationType.update,
      clientId: client.id!,
      clientData: client.toJson(),
      createdAt: DateTime.now(),
    ));
    logDebug('ClientMutationService: queued update for client ${client.id}');
    return ClientMutationResult.queued;
  }

  Future<void> deleteClient(String clientId) async {
    // Remove from Hive immediately so it disappears from UI
    await _hive.deleteClient(clientId);

    if (_connectivity.isOnline) {
      await _api.deleteClient(clientId);
      return;
    }

    await _pending.enqueue(PendingClientOperation(
      id: _uuid.v4(),
      operation: ClientOperationType.delete,
      clientId: clientId,
      clientData: null,
      createdAt: DateTime.now(),
    ));
    logDebug('ClientMutationService: queued delete for client $clientId');
  }
}
