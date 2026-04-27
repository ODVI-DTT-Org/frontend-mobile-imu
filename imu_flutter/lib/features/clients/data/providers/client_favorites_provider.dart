import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../services/sync/powersync_service.dart';
import '../../../../services/local_storage/hive_service.dart';
import '../../../../services/api/client_api_service.dart';
import '../../../../shared/providers/app_providers.dart' show currentUserIdProvider, isOnlineProvider;
import '../../../../core/utils/logger.dart';
import '../models/client_model.dart';

/// State shape for the favorites notifier.
class FavoritesState {
  final Set<String> ids;
  final bool isInitialSyncing;
  const FavoritesState({required this.ids, required this.isInitialSyncing});

  FavoritesState copyWith({Set<String>? ids, bool? isInitialSyncing}) =>
      FavoritesState(
        ids: ids ?? this.ids,
        isInitialSyncing: isInitialSyncing ?? this.isInitialSyncing,
      );

  static const empty = FavoritesState(ids: <String>{}, isInitialSyncing: false);
}

class ClientFavoritesNotifier extends StateNotifier<FavoritesState> {
  final Ref _ref;
  bool _isUpdating = false;

  ClientFavoritesNotifier(this._ref)
      : super(const FavoritesState(ids: <String>{}, isInitialSyncing: true)) {
    _initializeFromDatabase();
  }

  void _initializeFromDatabase() {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      state = FavoritesState.empty;
      return;
    }

    // Watch the favorites table; emit non-empty cancels initial-syncing.
    PowerSyncService.database.asStream().asyncExpand((db) {
      return db.watch(
        'SELECT client_id FROM client_favorites WHERE user_id = ?',
        parameters: [userId],
      );
    }).listen((rows) {
      if (_isUpdating) return;
      final ids = rows.map((r) => r['client_id'] as String).toSet();
      state = FavoritesState(ids: ids, isInitialSyncing: false);
    });

    // Belt-and-braces: if waitForInitialSync resolves and the stream is
    // still empty, drop the syncing flag (we know sync is done; an empty
    // result is now authoritative).
    PowerSyncService.waitForInitialSync().then((_) {
      if (mounted && state.isInitialSyncing) {
        state = state.copyWith(isInitialSyncing: false);
      }
    }).catchError((e) {
      logError('[ClientFavoritesNotifier] waitForInitialSync error: $e');
      if (mounted) state = state.copyWith(isInitialSyncing: false);
    });
  }

  Future<void> add(Client client) async {
    if (state.ids.contains(client.id)) return;
    _isUpdating = true;
    final previous = state;
    state = state.copyWith(ids: {...state.ids, client.id});
    try {
      await _ref.read(clientFavoritesServiceProvider).starClient(client);
    } catch (e) {
      state = previous;
      rethrow;
    } finally {
      Future.delayed(const Duration(seconds: 3), () {
        _isUpdating = false;
      });
    }
  }

  Future<void> remove(String clientId) async {
    if (!state.ids.contains(clientId)) return;
    _isUpdating = true;
    final previous = state;
    state = state.copyWith(ids: state.ids.where((id) => id != clientId).toSet());
    try {
      await _ref.read(clientFavoritesServiceProvider).unstarClient(clientId);
    } catch (e) {
      state = previous;
      rethrow;
    } finally {
      Future.delayed(const Duration(seconds: 3), () {
        _isUpdating = false;
      });
    }
  }

  bool contains(String clientId) => state.ids.contains(clientId);
}

/// Provider for the favorites notifier.
final clientFavoritesNotifierProvider =
    StateNotifierProvider<ClientFavoritesNotifier, FavoritesState>((ref) {
  return ClientFavoritesNotifier(ref);
});

/// Service for starring/unstarring clients.
/// PowerSync handles all API uploads automatically.
class ClientFavoritesService {
  final Ref _ref;

  ClientFavoritesService(this._ref);

  /// Star a client. Writes to PowerSync `client_favorites` (which uploads to
  /// the backend via the connector) AND caches the full client record into
  /// Hive immediately so the Favorites tab can render it offline.
  Future<void> starClient(Client client) async {
    logDebug('[ClientFavoritesService] Starting starClient for clientId: ${client.id}');

    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      logError('[ClientFavoritesService] Cannot star client - userId is null');
      throw Exception('User not logged in');
    }

    try {
      final db = await PowerSyncService.database;
      final id = const Uuid().v4();
      await db.execute(
        'INSERT OR IGNORE INTO client_favorites (id, user_id, client_id, created_at) VALUES (?, ?, ?, ?)',
        [id, userId, client.id, DateTime.now().toIso8601String()],
      );
      logDebug('[ClientFavoritesService] PowerSync insert succeeded for clientId: ${client.id}');

      // Cache the full client record into Hive (cache-on-favorite, Bug 2A fix)
      try {
        await HiveService().saveClient(client.toJson());
        logDebug('[ClientFavoritesService] Hive cache write succeeded for clientId: ${client.id}');
      } catch (e, stackTrace) {
        // Non-fatal: the favorite is recorded; Hive can re-sync later.
        logError('[ClientFavoritesService] Hive cache write failed for clientId: ${client.id}', e, stackTrace);
      }
    } catch (e, stackTrace) {
      logError('[ClientFavoritesService] Failed to star client ${client.id}', e, stackTrace);
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

    try {
      final db = await PowerSyncService.database;
      await db.execute(
        'DELETE FROM client_favorites WHERE user_id = ? AND client_id = ?',
        [userId, clientId],
      );
      logDebug('[ClientFavoritesService] DELETE executed successfully for clientId: $clientId');
    } catch (e, stackTrace) {
      logError('[ClientFavoritesService] Failed to unstar client $clientId', e, stackTrace);
      rethrow;
    }
  }
}

final clientFavoritesServiceProvider = Provider<ClientFavoritesService>((ref) {
  return ClientFavoritesService(ref);
});

/// Result type for favoritedClientListProvider — carries both the resolved
/// clients and a count of IDs we couldn't resolve (used for the "X favorites
/// couldn't load offline" footer).
class FavoritesResult {
  final List<Client> clients;
  final int unresolvedCount;
  const FavoritesResult({required this.clients, required this.unresolvedCount});
}

/// Starred clients for the current user.
/// Fallback chain: Hive → local PowerSync clients → POST /clients/by-ids.
/// Hive is checked first because cache-on-favorite (Bug 2A) populates it
/// at star time, and because it has embedded addresses/phones the UI uses.
final favoritedClientListProvider = FutureProvider<FavoritesResult>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return const FavoritesResult(clients: [], unresolvedCount: 0);
  }

  final favoriteState = ref.watch(clientFavoritesNotifierProvider);
  final favoriteIds = favoriteState.ids;
  if (favoriteIds.isEmpty) {
    return const FavoritesResult(clients: [], unresolvedCount: 0);
  }

  logDebug('[favoritedClientListProvider] Resolving ${favoriteIds.length} favorited IDs');

  final hive = HiveService();
  final found = <Client>[];
  final missingIds = <String>[];

  // Tier 1: Hive cache (primary source)
  for (final id in favoriteIds) {
    final json = hive.getClient(id);
    if (json != null) {
      found.add(Client.fromJson(json));
    } else {
      missingIds.add(id);
    }
  }

  // Tier 2: local PowerSync clients
  if (missingIds.isNotEmpty) {
    try {
      final db = await PowerSyncService.database;
      final placeholders = List.filled(missingIds.length, '?').join(',');
      final rows = await db.getAll(
        'SELECT * FROM clients WHERE id IN ($placeholders) AND deleted_at IS NULL',
        missingIds,
      );
      final stillMissing = <String>[];
      final foundFromPS = <String>{};
      for (final row in rows) {
        final c = Client.fromRow(Map<String, dynamic>.from(row));
        found.add(c);
        foundFromPS.add(c.id);
        // Cache forward into Hive so future reads are faster
        await hive.saveClient(c.toJson());
      }
      for (final id in missingIds) {
        if (!foundFromPS.contains(id)) stillMissing.add(id);
      }
      missingIds
        ..clear()
        ..addAll(stillMissing);
    } catch (e) {
      logError('[favoritedClientListProvider] PowerSync tier failed: $e');
      // Don't abort; fall through to API tier with the same missing list
    }
  }

  // Tier 3: REST API (only if online)
  if (missingIds.isNotEmpty) {
    final isOnline = ref.read(isOnlineProvider);
    if (isOnline) {
      try {
        final api = ref.read(clientApiServiceProvider);
        // Chunk if more than 100; backend caps at 100 per request
        for (var i = 0; i < missingIds.length; i += 100) {
          final chunk = missingIds.sublist(i, math.min(i + 100, missingIds.length));
          final fetched = await api.fetchClientsByIdsPost(chunk);
          for (final c in fetched) {
            found.add(c);
            await hive.saveClient(c.toJson());
            missingIds.remove(c.id);
          }
        }
      } catch (e) {
        logError('[favoritedClientListProvider] API tier failed: $e');
      }
    }
  }

  found.sort((a, b) => a.fullName.compareTo(b.fullName));
  return FavoritesResult(clients: found, unresolvedCount: missingIds.length);
});
