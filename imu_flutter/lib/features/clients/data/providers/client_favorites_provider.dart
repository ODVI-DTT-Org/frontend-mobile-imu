import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../services/sync/powersync_service.dart';
import '../../../../services/local_storage/hive_service.dart';
import '../../../../shared/providers/app_providers.dart' show currentUserIdProvider;
import '../../../../core/utils/logger.dart';
import '../models/client_model.dart';

/// Live set of favorited client IDs for the current user, from PowerSync SQLite.
final clientFavoritesProvider = StreamProvider<Set<String>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value({});
  return PowerSyncService.database.asStream().asyncExpand((db) {
    return db.watch(
      'SELECT client_id FROM client_favorites WHERE user_id = ?',
      parameters: [userId],
    ).map((rows) => rows.map((r) => r['client_id'] as String).toSet());
  });
});

/// Service for starring/unstarring clients with optimistic local SQLite updates.
/// PowerSync handles all API uploads automatically.
class ClientFavoritesService {
  final Ref _ref;

  ClientFavoritesService(this._ref);

  Future<void> starClient(String clientId) async {
    logDebug('[ClientFavoritesService] Starting starClient for clientId: $clientId');

    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      logError('[ClientFavoritesService] Cannot star client - userId is null');
      throw Exception('User not logged in');
    }

    logDebug('[ClientFavoritesService] userId: $userId');

    try {
      final db = await PowerSyncService.database;
      logDebug('[ClientFavoritesService] Database obtained, executing INSERT');

      // PowerSync requires an id column for all tables
      // Generate a UUID for the local record
      final id = const Uuid().v4();
      logDebug('[ClientFavoritesService] Generated id: $id');

      // Optimistic local insert - PowerSync will upload this automatically
      await db.execute(
        'INSERT OR IGNORE INTO client_favorites (id, user_id, client_id, created_at) VALUES (?, ?, ?, ?)',
        [id, userId, clientId, DateTime.now().toIso8601String()],
      );

      logDebug('[ClientFavoritesService] INSERT executed successfully for clientId: $clientId');
    } catch (e, stackTrace) {
      logError(
        '[ClientFavoritesService] Failed to star client $clientId',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<void> unstarClient(String clientId) async {
    logDebug('[ClientFavoritesService] Starting unstarClient for clientId: $clientId');

    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      logError('[ClientFavoritesService] Cannot unstar client - userId is null');
      throw Exception('User not logged in');
    }

    logDebug('[ClientFavoritesService] userId: $userId');

    try {
      final db = await PowerSyncService.database;
      logDebug('[ClientFavoritesService] Database obtained, executing DELETE');

      // Optimistic local delete - PowerSync will upload this automatically
      final result = await db.execute(
        'DELETE FROM client_favorites WHERE user_id = ? AND client_id = ?',
        [userId, clientId],
      );

      logDebug('[ClientFavoritesService] DELETE executed successfully for clientId: $clientId, rows affected: $result');
    } catch (e, stackTrace) {
      logError(
        '[ClientFavoritesService] Failed to unstar client $clientId',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}

final clientFavoritesServiceProvider = Provider<ClientFavoritesService>((ref) {
  return ClientFavoritesService(ref);
});

/// Starred clients for the current user.
/// Gets favorited IDs from PowerSync, then filters Hive cached clients by those IDs.
/// This works because clients are stored in Hive (not PowerSync), while favorites are in PowerSync.
final favoritedClientListProvider = StreamProvider<List<Client>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  // Get favorited client IDs from PowerSync
  return PowerSyncService.database.asStream().asyncExpand((db) {
    return db.watch(
      'SELECT client_id FROM client_favorites WHERE user_id = ?',
      parameters: [userId],
    );
  }).map((rows) {
    // Extract favorited client IDs
    final favoriteIds = rows.map((r) => r['client_id'] as String).toSet();

    // Load all clients from Hive cache
    final hiveService = HiveService();
    final rawClients = hiveService.getAllClients();
    final allClients = rawClients.map((json) => Client.fromJson(json)).toList();

    // Filter clients by favorited IDs and sort by name
    final favoritedClients = allClients
        .where((c) => favoriteIds.contains(c.id))
        .toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));

    logDebug('[favoritedClientListProvider] Found ${favoritedClients.length} favorited clients out of ${allClients.length} total clients');

    return favoritedClients;
  });
});
