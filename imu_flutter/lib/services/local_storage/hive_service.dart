import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Local storage service using Hive — settings only.
/// All entity data (clients, groups, attendance, etc.) lives in PowerSync SQLite.
class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  static const String _settingsBox = 'settings';

  bool _isInitialized = false;

  /// Initialize Hive
  Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();
    await Hive.openBox<String>(_settingsBox);

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
