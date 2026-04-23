import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/sync/powersync_service.dart';
import '../../../../services/local_storage/hive_service.dart';
import '../../../../shared/providers/app_providers.dart' show currentUserIdProvider;
import '../../../../core/utils/logger.dart';
import '../models/client_model.dart';

/// Notifier for managing client favorite status with optimistic updates.
/// This prevents the star button from "unticking" during PowerSync sync cycles.
class ClientFavoritesNotifier extends StateNotifier<Set<String>> {
  final Ref _ref;
  bool _isUpdating = false;

  ClientFavoritesNotifier(this._ref) : super({}) {
    _initializeFromDatabase();
  }

  /// Initialize state from PowerSync database and watch for changes.
  /// Only update state from DB when not in the middle of a manual update.
  void _initializeFromDatabase() {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      state = {};
      return;
    }

    // Load initial state
    PowerSyncService.database.then((db) {
      db.getAll(
        'SELECT client_id FROM client_favorites WHERE user_id = ?',
        [userId],
      ).then((rows) {
        final ids = rows.map((r) => r['client_id'] as String).toSet();
        if (!_isUpdating) {
          state = ids;
          logDebug('[ClientFavoritesNotifier] Initialized with ${ids.length} favorites');
        }
      });
    });

    // Watch for changes from PowerSync (but ignore during manual updates)
    PowerSyncService.database.asStream().asyncExpand((db) {
      return db.watch(
        'SELECT client_id FROM client_favorites WHERE user_id = ?',
        parameters: [userId],
      );
    }).listen((rows) {
      if (_isUpdating) {
        logDebug('[ClientFavoritesNotifier] Ignoring stream update during manual operation');
        return;
      }
      final ids = rows.map((r) => r['client_id'] as String).toSet();
      state = ids;
      logDebug('[ClientFavoritesNotifier] Stream updated with ${ids.length} favorites');
    });
  }

  /// Optimistically add client to favorites.
  /// Manual check prevents duplicate entries at application level.
  Future<void> add(String clientId) async {
    // Manual check #1: Check if already in state (optimistic)
    if (state.contains(clientId)) {
      logDebug('[ClientFavoritesNotifier] $clientId already in favorites (state check), skipping add');
      return;
    }

    _isUpdating = true;
    final previousState = state;

    // Optimistic update
    state = {...state, clientId};
    logDebug('[ClientFavoritesNotifier] Optimistically added $clientId, now ${state.length} favorites');

    try {
      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final db = await PowerSyncService.database;

      // Manual check #2: Check if already exists in database before insert
      final existing = await db.getAll(
        'SELECT id FROM client_favorites WHERE user_id = ? AND client_id = ?',
        [userId, clientId],
      );

      if (existing.isNotEmpty) {
        logDebug('[ClientFavoritesNotifier] $clientId already exists in database, skipping insert');
        // Don't revert - the optimistic state is correct
        return;
      }

      // Safe to proceed with insert
      // PowerSync auto-generates id - no need to specify it
      await db.execute(
        'INSERT OR IGNORE INTO client_favorites (user_id, client_id, created_at) VALUES (?, ?, ?)',
        [userId, clientId, DateTime.now().toIso8601String()],
      );

      logDebug('[ClientFavoritesNotifier] Successfully inserted $clientId into database');
    } catch (e) {
      // Revert on error
      state = previousState;
      logError('[ClientFavoritesNotifier] Failed to add $clientId, reverted state: $e');
      rethrow;
    } finally {
      // Allow stream updates after a short delay to ensure sync cycle completes
      Future.delayed(const Duration(seconds: 3), () {
        _isUpdating = false;
        logDebug('[ClientFavoritesNotifier] Resuming stream updates');
      });
    }
  }

  /// Optimistically remove client from favorites.
  /// Manual check prevents unnecessary database operations.
  Future<void> remove(String clientId) async {
    // Manual check #1: Check if NOT in state (optimistic)
    if (!state.contains(clientId)) {
      logDebug('[ClientFavoritesNotifier] $clientId not in favorites (state check), skipping remove');
      return;
    }

    _isUpdating = true;
    final previousState = state;

    // Optimistic update
    state = state.where((id) => id != clientId).toSet();
    logDebug('[ClientFavoritesNotifier] Optimistically removed $clientId, now ${state.length} favorites');

    try {
      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final db = await PowerSyncService.database;

      // Manual check #2: Verify the record exists before attempting delete
      final existing = await db.getAll(
        'SELECT id FROM client_favorites WHERE user_id = ? AND client_id = ?',
        [userId, clientId],
      );

      if (existing.isEmpty) {
        logDebug('[ClientFavoritesNotifier] $clientId not found in database, skipping delete');
        // Don't revert - the optimistic state is correct
        return;
      }

      // Safe to proceed with delete
      await db.execute(
        'DELETE FROM client_favorites WHERE user_id = ? AND client_id = ?',
        [userId, clientId],
      );

      logDebug('[ClientFavoritesNotifier] Successfully removed $clientId from database');
    } catch (e) {
      // Revert on error
      state = previousState;
      logError('[ClientFavoritesNotifier] Failed to remove $clientId, reverted state: $e');
      rethrow;
    } finally {
      // Allow stream updates after a short delay
      Future.delayed(const Duration(seconds: 3), () {
        _isUpdating = false;
        logDebug('[ClientFavoritesNotifier] Resuming stream updates');
      });
    }
  }

  /// Check if a client is favorited.
  bool contains(String clientId) => state.contains(clientId);
}

/// Provider for the favorites notifier.
final clientFavoritesNotifierProvider = StateNotifierProvider<ClientFavoritesNotifier, Set<String>>((ref) {
  return ClientFavoritesNotifier(ref);
});

/// Live set of favorited client IDs for the current user, from PowerSync SQLite.
/// NOTE: This is now deprecated in favor of clientFavoritesNotifierProvider for optimistic updates.
/// Kept for backward compatibility with favoritedClientListProvider.
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

      // PowerSync auto-generates id - no need to specify it
      // Optimistic local insert - PowerSync will upload this automatically
      await db.execute(
        'INSERT OR IGNORE INTO client_favorites (user_id, client_id, created_at) VALUES (?, ?, ?)',
        [userId, clientId, DateTime.now().toIso8601String()],
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
/// Uses the shared state from clientFavoritesNotifierProvider for consistency.
/// Hybrid approach: Try PowerSync first (for all clients), fall back to Hive cache (assigned clients).
/// This works both online (PowerSync has data) and offline (Hive cache as fallback).
/// Uses FutureProvider with ref.watch() to automatically update when favorite IDs change.
final favoritedClientListProvider = FutureProvider<List<Client>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  // Watch the notifier state (single source of truth for favorite IDs)
  // ref.watch() ensures this provider rebuilds when favorite IDs change
  final favoriteIds = ref.watch(clientFavoritesNotifierProvider);

  if (favoriteIds.isEmpty) {
    logDebug('[favoritedClientListProvider] No favorites found');
    return [];
  }

  logDebug('[favoritedClientListProvider] Found ${favoriteIds.length} favorited IDs: $favoriteIds');

  // Try to get clients from PowerSync first
  try {
    final db = await PowerSyncService.database;
    final placeholders = List.filled(favoriteIds.length, '?').join(',');
    final result = await db.getAll(
      'SELECT * FROM clients WHERE id IN ($placeholders) AND deleted_at IS NULL',
      favoriteIds.toList(),
    );

    if (result.isNotEmpty) {
      final clients = result.map((r) => Client.fromRow(Map<String, dynamic>.from(r))).toList();
      logDebug('[favoritedClientListProvider] Found ${clients.length} clients in PowerSync');
      return clients..sort((a, b) => a.fullName.compareTo(b.fullName));
    }
  } catch (e) {
    logError('[favoritedClientListProvider] Error querying PowerSync clients: $e');
  }

  // Fallback: Load from Hive cache (assigned clients only)
  logDebug('[favoritedClientListProvider] PowerSync has no clients, falling back to Hive cache');
  final hiveService = HiveService();
  final rawClients = hiveService.getAllClients();
  final allClients = rawClients.map((json) => Client.fromJson(json)).toList();

  // Filter by favorited IDs
  final favoritedClients = allClients
      .where((c) => favoriteIds.contains(c.id))
      .toList()
    ..sort((a, b) => a.fullName.compareTo(b.fullName));

  logDebug('[favoritedClientListProvider] Found ${favoritedClients.length} clients in Hive cache (assigned only)');

  return favoritedClients;
});
