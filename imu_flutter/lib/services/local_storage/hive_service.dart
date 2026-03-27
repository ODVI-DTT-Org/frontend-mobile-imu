import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Local storage service using Hive for offline-first data persistence
class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  static const String _clientsBox = 'clients';
  static const String _touchpointsBox = 'touchpoints';
  static const String _settingsBox = 'settings';
  static const String _pendingSyncBox = 'pending_sync';
  static const String _cacheBox = 'cache';
  static const String _attendanceBox = 'attendance';
  static const String _agenciesBox = 'agencies';
  static const String _groupsBox = 'groups';
  static const String _itinerariesBox = 'itineraries';

  bool _isInitialized = false;

  /// Initialize Hive
  Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    // Open all boxes
    await Future.wait([
      Hive.openBox<String>(_clientsBox),
      Hive.openBox<String>(_touchpointsBox),
      Hive.openBox<String>(_settingsBox),
      Hive.openBox<String>(_pendingSyncBox),
      Hive.openBox<String>(_cacheBox),
      Hive.openBox<String>(_attendanceBox),
      Hive.openBox<String>(_agenciesBox),
      Hive.openBox<String>(_groupsBox),
      Hive.openBox<String>(_itinerariesBox),
    ]);

    _isInitialized = true;
    debugPrint('HiveService initialized');
  }

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  // ==================== Clients ====================

  /// Save a client
  Future<void> saveClient(String id, Map<String, dynamic> client) async {
    final box = Hive.box<String>(_clientsBox);
    await box.put(id, jsonEncode(client));
  }

  /// Add a client (alias for saveClient with auto-ID extraction)
  Future<void> addClient(Map<String, dynamic> client) async {
    final id = client['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();
    await saveClient(id, client);
  }

  /// Get a client by ID
  Map<String, dynamic>? getClient(String id) {
    final box = Hive.box<String>(_clientsBox);
    final data = box.get(id);
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  /// Get all clients
  List<Map<String, dynamic>> getAllClients() {
    final box = Hive.box<String>(_clientsBox);
    return box.values
        .map((data) => jsonDecode(data) as Map<String, dynamic>)
        .toList();
  }

  /// Update a client (alias for saveClient)
  Future<void> updateClient(Map<String, dynamic> client) async {
    final id = client['id'] as String?;
    if (id == null) throw ArgumentError('Client ID is required');
    await saveClient(id, client);
  }

  /// Delete a client
  Future<void> deleteClient(String id) async {
    final box = Hive.box<String>(_clientsBox);
    await box.delete(id);
  }

  /// Search clients by name
  List<Map<String, dynamic>> searchClients(String query) {
    final clients = getAllClients();
    if (query.isEmpty) return clients;

    final lowerQuery = query.toLowerCase();
    return clients.where((client) {
      final name = (client['fullName'] ?? '').toString().toLowerCase();
      return name.contains(lowerQuery);
    }).toList();
  }

  /// Filter clients by type
  List<Map<String, dynamic>> filterClientsByType(String clientType) {
    final clients = getAllClients();
    return clients.where((c) => c['clientType'] == clientType).toList();
  }

  // ==================== Touchpoints ====================

  /// Save a touchpoint
  Future<void> saveTouchpoint(String id, Map<String, dynamic> touchpoint) async {
    final box = Hive.box<String>(_touchpointsBox);
    await box.put(id, jsonEncode(touchpoint));
  }

  /// Add a touchpoint (alias for saveTouchpoint with auto-ID extraction)
  Future<void> addTouchpoint(Map<String, dynamic> touchpoint) async {
    final id = touchpoint['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();
    await saveTouchpoint(id, touchpoint);
  }

  /// Update a touchpoint (alias for saveTouchpoint)
  Future<void> updateTouchpoint(Map<String, dynamic> touchpoint) async {
    final id = touchpoint['id'] as String?;
    if (id == null) throw ArgumentError('Touchpoint ID is required');
    await saveTouchpoint(id, touchpoint);
  }

  /// Get touchpoints for a client
  List<Map<String, dynamic>> getTouchpointsForClient(String clientId) {
    final box = Hive.box<String>(_touchpointsBox);
    return box.values
        .map((data) => jsonDecode(data) as Map<String, dynamic>)
        .where((t) => t['clientId'] == clientId)
        .toList()
      ..sort((a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String));
  }

  /// Delete a touchpoint
  Future<void> deleteTouchpoint(String id) async {
    final box = Hive.box<String>(_touchpointsBox);
    await box.delete(id);
  }

  // ==================== Pending Sync ====================

  /// Add item to pending sync queue
  Future<void> addToPendingSync({
    required String id,
    required String operation, // 'create', 'update', 'delete'
    required String entityType, // 'client', 'touchpoint'
    required Map<String, dynamic> data,
  }) async {
    final box = Hive.box<String>(_pendingSyncBox);
    final pendingItem = {
      'id': id,
      'operation': operation,
      'entityType': entityType,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await box.put('${entityType}_$id', jsonEncode(pendingItem));
  }

  /// Get all pending sync items
  List<Map<String, dynamic>> getPendingSyncItems() {
    final box = Hive.box<String>(_pendingSyncBox);
    return box.values
        .map((data) => jsonDecode(data) as Map<String, dynamic>)
        .toList();
  }

  /// Remove item from pending sync queue
  Future<void> removeFromPendingSync(String entityType, String id) async {
    final box = Hive.box<String>(_pendingSyncBox);
    await box.delete('${entityType}_$id');
  }

  /// Clear all pending sync items
  Future<void> clearPendingSync() async {
    final box = Hive.box<String>(_pendingSyncBox);
    await box.clear();
  }

  /// Get pending sync count
  int getPendingSyncCount() {
    final box = Hive.box<String>(_pendingSyncBox);
    return box.length;
  }

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

  // ==================== Cache ====================

  /// Cache data with expiry
  Future<void> cacheData(
    String key,
    Map<String, dynamic> data, {
    Duration expiry = const Duration(hours: 24),
  }) async {
    final box = Hive.box<String>(_cacheBox);
    final cacheItem = {
      'data': data,
      'expiry': DateTime.now().add(expiry).toIso8601String(),
    };
    await box.put(key, jsonEncode(cacheItem));
  }

  /// Get cached data
  Map<String, dynamic>? getCachedData(String key) {
    final box = Hive.box<String>(_cacheBox);
    final data = box.get(key);
    if (data != null) {
      final decoded = jsonDecode(data) as Map<String, dynamic>;
      final expiry = DateTime.parse(decoded['expiry'] as String);
      if (DateTime.now().isBefore(expiry)) {
        return decoded['data'] as Map<String, dynamic>;
      } else {
        // Remove expired cache
        box.delete(key);
      }
    }
    return null;
  }

  /// Clear all cache
  Future<void> clearCache() async {
    final box = Hive.box<String>(_cacheBox);
    await box.clear();
  }

  /// Get cache size in bytes
  int getCacheSize() {
    final box = Hive.box<String>(_cacheBox);
    int size = 0;
    for (final value in box.values) {
      size += value.length;
    }
    return size;
  }

  /// Get cache size formatted
  String getCacheSizeFormatted() {
    final bytes = getCacheSize();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // ==================== Agencies ====================

  /// Save an agency
  Future<void> saveAgency(String id, Map<String, dynamic> agency) async {
    final box = Hive.box<String>(_agenciesBox);
    await box.put(id, jsonEncode(agency));
  }

  /// Add an agency (alias for saveAgency with auto-ID extraction)
  Future<void> addAgency(Map<String, dynamic> agency) async {
    final id = agency['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();
    await saveAgency(id, agency);
  }

  /// Get an agency by ID
  Future<Map<String, dynamic>?> getAgency(String id) async {
    final box = Hive.box<String>(_agenciesBox);
    final data = box.get(id);
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  /// Get all agencies
  List<Map<String, dynamic>> getAllAgencies() {
    final box = Hive.box<String>(_agenciesBox);
    return box.values
        .map((data) => jsonDecode(data) as Map<String, dynamic>)
        .toList();
  }

  /// Update an agency (alias for saveAgency)
  Future<void> updateAgency(Map<String, dynamic> agency) async {
    final id = agency['id'] as String?;
    if (id == null) throw ArgumentError('Agency ID is required');
    await saveAgency(id, agency);
  }

  /// Delete an agency
  Future<void> deleteAgency(String id) async {
    final box = Hive.box<String>(_agenciesBox);
    await box.delete(id);
  }

  // ==================== Groups ====================

  /// Save a group
  Future<void> saveGroup(String id, Map<String, dynamic> group) async {
    final box = Hive.box<String>(_groupsBox);
    await box.put(id, jsonEncode(group));
  }

  /// Add a group (alias for saveGroup with auto-ID extraction)
  Future<void> addGroup(Map<String, dynamic> group) async {
    final id = group['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();
    await saveGroup(id, group);
  }

  /// Get a group by ID
  Future<Map<String, dynamic>?> getGroup(String id) async {
    final box = Hive.box<String>(_groupsBox);
    final data = box.get(id);
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  /// Get all groups
  List<Map<String, dynamic>> getAllGroups() {
    final box = Hive.box<String>(_groupsBox);
    return box.values
        .map((data) => jsonDecode(data) as Map<String, dynamic>)
        .toList();
  }

  /// Update a group (alias for saveGroup)
  Future<void> updateGroup(Map<String, dynamic> group) async {
    final id = group['id'] as String?;
    if (id == null) throw ArgumentError('Group ID is required');
    await saveGroup(id, group);
  }

  /// Delete a group
  Future<void> deleteGroup(String id) async {
    final box = Hive.box<String>(_groupsBox);
    await box.delete(id);
  }

  // ==================== Itineraries ====================

  /// Save an itinerary
  Future<void> saveItinerary(String id, Map<String, dynamic> itinerary) async {
    final box = Hive.box<String>(_itinerariesBox);
    await box.put(id, jsonEncode(itinerary));
  }

  /// Add an itinerary (alias for saveItinerary with auto-ID extraction)
  Future<void> addItinerary(Map<String, dynamic> itinerary) async {
    final id = itinerary['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();
    await saveItinerary(id, itinerary);
  }

  /// Get an itinerary by ID
  Future<Map<String, dynamic>?> getItinerary(String id) async {
    final box = Hive.box<String>(_itinerariesBox);
    final data = box.get(id);
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  /// Get all itineraries
  List<Map<String, dynamic>> getAllItineraries() {
    final box = Hive.box<String>(_itinerariesBox);
    return box.values
        .map((data) => jsonDecode(data) as Map<String, dynamic>)
        .toList();
  }

  /// Get itineraries by date
  List<Map<String, dynamic>> getItinerariesByDate(DateTime date) {
    final allItineraries = getAllItineraries();
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return allItineraries.where((i) {
      final scheduledDate = i['scheduled_date'] as String?;
      return scheduledDate == dateStr;
    }).toList();
  }

  /// Update an itinerary (alias for saveItinerary)
  Future<void> updateItinerary(Map<String, dynamic> itinerary) async {
    final id = itinerary['id'] as String?;
    if (id == null) throw ArgumentError('Itinerary ID is required');
    await saveItinerary(id, itinerary);
  }

  /// Delete an itinerary
  Future<void> deleteItinerary(String id) async {
    final box = Hive.box<String>(_itinerariesBox);
    await box.delete(id);
  }

  // ==================== Clear All ====================

  /// Clear all data
  Future<void> clearAllData() async {
    await Future.wait([
      Hive.box<String>(_clientsBox).clear(),
      Hive.box<String>(_touchpointsBox).clear(),
      Hive.box<String>(_cacheBox).clear(),
    ]);
    // Keep settings
  }
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
