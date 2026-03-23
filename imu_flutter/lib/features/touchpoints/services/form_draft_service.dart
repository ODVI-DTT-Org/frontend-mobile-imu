import 'package:hive/hive.dart';

const int kFormDraftVersion = 1;
const int kDraftExpirationDays = 7;

class FormDraftService {
  static const String _boxName = 'form_drafts';
  static Box<Map>? _box;

  static Future<void> initialize() async {
    _box = await Hive.openBox<Map>(_boxName);
    await _cleanupExpiredDrafts();
  }

  static String _key(String clientId, int touchpointNumber) =>
      'draft_${clientId}_$touchpointNumber';

  static Future<void> saveDraft({
    required String clientId,
    required int touchpointNumber,
    required Map<String, dynamic> timeIn,
    required Map<String, dynamic> timeOut,
    required Map<String, dynamic> formFields,
  }) async {
    final box = _box!;
    await box.put(_key(clientId, touchpointNumber), {
      'version': kFormDraftVersion,
      'savedAt': DateTime.now().toIso8601String(),
      'timeIn': timeIn,
      'timeOut': timeOut,
      'formFields': formFields,
    });
  }

  static Future<Map<String, dynamic>?> getDraft({
    required String clientId,
    required int touchpointNumber,
  }) async {
    final box = _box!;
    final draft = box.get(_key(clientId, touchpointNumber));

    if (draft == null) return null;

    // Check version compatibility
    final version = draft['version'] as int? ?? 0;
    if (version < kFormDraftVersion) {
      await deleteDraft(clientId: clientId, touchpointNumber: touchpointNumber);
      return null;
    }

    return Map<String, dynamic>.from(draft);
  }

  static Future<void> deleteDraft({
    required String clientId,
    required int touchpointNumber,
  }) async {
    final box = _box!;
    await box.delete(_key(clientId, touchpointNumber));
  }

  static Future<void> _cleanupExpiredDrafts() async {
    final box = _box!;
    final expirationDate = DateTime.now().subtract(Duration(days: kDraftExpirationDays));

    final keysToDelete = <dynamic>[];

    for (final key in box.keys) {
      final draft = box.get(key);
      if (draft == null) continue;

      final savedAtStr = draft['savedAt'] as String?;
      if (savedAtStr == null) {
        keysToDelete.add(key);
        continue;
      }

      final savedAt = DateTime.tryParse(savedAtStr);
      if (savedAt == null || savedAt.isBefore(expirationDate)) {
        keysToDelete.add(key);
      }
    }

    for (final key in keysToDelete) {
      await box.delete(key);
    }
  }
}
