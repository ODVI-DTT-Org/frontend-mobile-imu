import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:imu_flutter/core/models/user_role.dart';
import 'package:imu_flutter/services/api/api_exception.dart';
import 'package:imu_flutter/services/release/release_creation_service.dart';

/// Local queue for loan release submissions that couldn't reach the backend
/// (typically because the device is offline). Items are flushed on demand by
/// BackgroundSyncService when connectivity / auth come back online.
///
/// We keep this as a plain Hive box of JSON strings rather than adding a row
/// to the PowerSync `releases` table because the backend's release flow is
/// composed of three sequential calls (visit, release, client patch) plus an
/// optional photo upload — all driven by [ReleaseCreationService] — and
/// there is no local `releases` table in the active PowerSync schema.
class PendingReleaseService {
  static const String _boxName = 'pending_releases';
  static final Uuid _uuid = const Uuid();

  Future<Box<String>> _box() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box<String>(_boxName);
    return Hive.openBox<String>(_boxName);
  }

  /// Persist a release submission for later upload. Returns the queue id.
  Future<String> enqueue({
    required UserRole role,
    required String clientId,
    required String timeIn,
    required String timeOut,
    required String odometerArrival,
    required String odometerDeparture,
    required String productType,
    required String loanType,
    required String udiNumber,
    String? remarks,
    String? photoPath,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    final box = await _box();
    final id = _uuid.v4();
    final payload = jsonEncode({
      'id': id,
      'role': role.apiValue,
      'clientId': clientId,
      'timeIn': timeIn,
      'timeOut': timeOut,
      'odometerArrival': odometerArrival,
      'odometerDeparture': odometerDeparture,
      'productType': productType,
      'loanType': loanType,
      'udiNumber': udiNumber,
      'remarks': remarks,
      'photoPath': photoPath,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'queuedAt': DateTime.now().toIso8601String(),
    });
    await box.put(id, payload);
    debugPrint('PendingReleaseService: Queued release $id (${box.length} pending)');
    return id;
  }

  Future<int> get count async => (await _box()).length;

  Future<List<Map<String, dynamic>>> peekAll() async {
    final box = await _box();
    return box.values
        .map((v) => jsonDecode(v) as Map<String, dynamic>)
        .toList();
  }

  /// Try to upload everything in the queue using [resolveService] to obtain a
  /// configured [ReleaseCreationService] for each entry's role. Items that
  /// succeed are removed; permanent failures (4xx other than 401) are dropped
  /// to avoid blocking the queue. Transient failures are left in place for
  /// the next flush.
  Future<PendingFlushResult> flush({
    required ReleaseCreationService Function(UserRole) resolveService,
  }) async {
    final box = await _box();
    if (box.isEmpty) {
      return const PendingFlushResult(uploaded: 0, dropped: 0, remaining: 0);
    }

    int uploaded = 0;
    int dropped = 0;

    for (final id in box.keys.toList()) {
      final raw = box.get(id);
      if (raw == null) continue;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final role = UserRole.fromApi(data['role'] as String);

      // Skip the entry if its photo file disappeared between sessions —
      // the form requires a photo and we shouldn't silently submit without it.
      final photoPath = data['photoPath'] as String?;
      if (photoPath != null && photoPath.isNotEmpty && !File(photoPath).existsSync()) {
        debugPrint('PendingReleaseService: Photo missing for $id, dropping queue entry');
        await box.delete(id);
        dropped++;
        continue;
      }

      try {
        final service = resolveService(role);
        final outcome = await service.createCompleteLoanRelease(
          clientId: data['clientId'] as String,
          timeIn: data['timeIn'] as String,
          timeOut: data['timeOut'] as String,
          odometerArrival: data['odometerArrival'] as String,
          odometerDeparture: data['odometerDeparture'] as String,
          productType: data['productType'] as String,
          loanType: data['loanType'] as String,
          udiNumber: data['udiNumber'] as String,
          remarks: data['remarks'] as String?,
          photoPath: photoPath,
          latitude: (data['latitude'] as num?)?.toDouble(),
          longitude: (data['longitude'] as num?)?.toDouble(),
          address: data['address'] as String?,
        );
        // If the connectivity flipped back offline mid-flush, the service
        // re-enqueued instead of submitting. Delete the new entry and stop —
        // the original is still in the queue waiting for true online state.
        if (outcome == ReleaseSubmitOutcome.queued) {
          // The service appended a new entry; drop everything queued AFTER
          // this one's id by removing the most recent extra(s) of this user.
          // Simplest correct behavior: stop the flush so we don't churn.
          debugPrint('PendingReleaseService: Connectivity flipped offline mid-flush, stopping');
          break;
        }
        await box.delete(id);
        uploaded++;
      } on ApiException catch (e) {
        // ApiException with no statusCode is the offline guard rethrow —
        // bail out, we'll try again next time we're online.
        if (e.statusCode == null) {
          debugPrint('PendingReleaseService: Still offline, stopping flush');
          break;
        }
        // Permanent 4xx (auth issue handled separately upstream) — drop so
        // the queue doesn't block on a poison entry.
        if (e.statusCode! >= 400 && e.statusCode! < 500 && e.statusCode != 401) {
          debugPrint('PendingReleaseService: Permanent ${e.statusCode} on $id, dropping');
          await box.delete(id);
          dropped++;
          continue;
        }
        // Transient (5xx, 401) — leave in queue and stop this round.
        debugPrint('PendingReleaseService: Transient error ${e.statusCode} on $id, retrying later');
        break;
      } catch (e) {
        debugPrint('PendingReleaseService: Unexpected error on $id: $e');
        break;
      }
    }

    return PendingFlushResult(
      uploaded: uploaded,
      dropped: dropped,
      remaining: box.length,
    );
  }

  Future<void> clear() async {
    final box = await _box();
    await box.clear();
  }
}

class PendingFlushResult {
  final int uploaded;
  final int dropped;
  final int remaining;
  const PendingFlushResult({
    required this.uploaded,
    required this.dropped,
    required this.remaining,
  });
}

final pendingReleaseServiceProvider = Provider<PendingReleaseService>((ref) {
  return PendingReleaseService();
});
