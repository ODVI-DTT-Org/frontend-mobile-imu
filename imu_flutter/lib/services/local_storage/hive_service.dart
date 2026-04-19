import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Local storage service using Hive.
/// Settings box: user preferences.
/// Clients box: REST-fetched assigned clients (JSON-encoded), keyed by client ID.
class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  static const String _settingsBox = 'settings';
  static const String _clientsBox = 'clients';

  bool _isInitialized = false;

  /// Initialize Hive
  Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();
    await Hive.openBox<String>(_settingsBox);
    await Hive.openBox<String>(_clientsBox);

    _isInitialized = true;
    debugPrint('HiveService initialized');
  }

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  // ==================== Settings ====================

  /// Save a setting
  Future<void> saveSetting(String key, dynamic value) async {
    final box = Hive.box<String>(_settingsBox);
    await box.put(key, jsonEncode({'value': value}));
  }

  /// Get a setting
  T? getSetting<T>(String key, {T? defaultValue}) {
    final box = Hive.box<String>(_settingsBox);
    final data = box.get(key);
    if (data != null) {
      final decoded = jsonDecode(data) as Map<String, dynamic>;
      return decoded['value'] as T?;
    }
    return defaultValue;
  }

  // ==================== Clients Cache ====================

  Box<String> get _clients {
    if (!Hive.isBoxOpen(_clientsBox)) {
      throw StateError('HiveService not initialized. Call init() before accessing clients box.');
    }
    return Hive.box<String>(_clientsBox);
  }

  /// Save all clients (replaces entire cache)
  Future<void> saveAllClients(List<Map<String, dynamic>> clients) async {
    final box = _clients;
    await box.clear();
    final entries = {
      for (final c in clients)
        if (c['id'] != null) c['id'] as String: jsonEncode(c),
    };
    await box.putAll(entries);
    debugPrint('HiveService: Saved ${entries.length} clients to cache');
  }

  /// Get all cached clients as raw JSON maps
  List<Map<String, dynamic>> getAllClients() {
    if (!Hive.isBoxOpen(_clientsBox)) return [];
    return _clients.values
        .map((v) => jsonDecode(v) as Map<String, dynamic>)
        .toList();
  }

  /// Save (upsert) a single client
  Future<void> saveClient(Map<String, dynamic> client) async {
    final id = client['id'] as String?;
    if (id == null || !Hive.isBoxOpen(_clientsBox)) return;
    await _clients.put(id, jsonEncode(client));
  }

  /// Get a single cached client by ID
  Map<String, dynamic>? getClient(String id) {
    if (!Hive.isBoxOpen(_clientsBox)) return null;
    final data = _clients.get(id);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  /// Remove a single client from cache
  Future<void> removeClient(String id) async {
    if (!Hive.isBoxOpen(_clientsBox)) return;
    await _clients.delete(id);
  }

  /// Clear entire clients cache
  Future<void> clearClients() async {
    if (!Hive.isBoxOpen(_clientsBox)) return;
    await _clients.clear();
    debugPrint('HiveService: Clients cache cleared');
  }

  /// How many clients are currently cached
  int get cachedClientCount =>
      Hive.isBoxOpen(_clientsBox) ? _clients.length : 0;
}

/// Sync status enum
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  offline,
}

/// Sync result
class SyncResult {
  final bool success;
  final int syncedCount;
  final int failedCount;
  final String? errorMessage;

  SyncResult({
    required this.success,
    this.syncedCount = 0,
    this.failedCount = 0,
    this.errorMessage,
  });
}
