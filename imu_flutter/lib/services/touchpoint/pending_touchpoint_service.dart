import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:imu_flutter/models/pending_touchpoint.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class PendingTouchpointService {
  static const String _boxName = 'pending_touchpoints';
  final Uuid _uuid = const Uuid();

  // For testing - allow injection of mock box
  Box<Map>? _testBox;

  Future<Box<Map>> _getBox() async {
    if (_testBox != null) {
      return _testBox!;
    }

    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<Map>(_boxName);
    }
    return Hive.box<Map>(_boxName);
  }

  // Test constructor
  PendingTouchpointService.test(Box<Map> mockBox) : _testBox = mockBox;

  PendingTouchpointService();

  Future<void> addPendingTouchpoint(
    String clientId,
    Touchpoint touchpoint, {
    String? photoPath,
    String? audioPath,
  }) async {
    final box = await _getBox();
    final id = _uuid.v4();

    final pending = PendingTouchpoint(
      id: id,
      clientId: clientId,
      touchpoint: touchpoint,
      createdAt: DateTime.now(),
      photoPath: photoPath,
      audioPath: audioPath,
    );

    await box.put(id, pending.toJson());
  }

  Future<List<PendingTouchpoint>> getPendingTouchpoints() async {
    final box = await _getBox();
    final items = box.values;

    return items.map((json) {
      return PendingTouchpoint.fromJson(json as Map<String, dynamic>);
    }).toList();
  }

  Future<List<PendingTouchpoint>> getPendingTouchpointsForClient(String clientId) async {
    final all = await getPendingTouchpoints();
    return all.where((p) => p.clientId == clientId).toList();
  }

  Future<void> removePendingTouchpoint(String pendingId) async {
    final box = await _getBox();
    await box.delete(pendingId);
  }

  Future<int> getPendingCount() async {
    final box = await _getBox();
    return box.length;
  }

  Stream<int> watchPendingCount() async* {
    final box = await _getBox();
    yield box.length;
    // Watch for changes in the box
    yield* box.watch().map((_) => box.length);
  }
}
