import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'models/pending_release.dart';

class PendingReleaseService {
  static const String _boxName = 'pending_releases';
  final Uuid _uuid = const Uuid();

  Future<Box<Map>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<Map>(_boxName);
    }
    return Hive.box<Map>(_boxName);
  }

  Future<void> addPendingRelease({
    required String clientId,
    required String timeIn,
    required String timeOut,
    required String odometerArrival,
    required String odometerDeparture,
    required String productType,
    required String loanType,
    int? udiNumber,
    String? remarks,
    String? photoPath,
  }) async {
    final box = await _getBox();
    final id = _uuid.v4();
    final pending = PendingRelease(
      id: id,
      clientId: clientId,
      timeIn: timeIn,
      timeOut: timeOut,
      odometerArrival: odometerArrival,
      odometerDeparture: odometerDeparture,
      productType: productType,
      loanType: loanType,
      udiNumber: udiNumber,
      remarks: remarks,
      photoPath: photoPath,
      createdAt: DateTime.now(),
    );
    await box.put(id, pending.toJson());
  }

  Future<List<PendingRelease>> getPendingReleases() async {
    final box = await _getBox();
    return box.values
        .map((v) => PendingRelease.fromJson(Map<String, dynamic>.from(v as Map)))
        .toList();
  }

  Future<void> removePendingRelease(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  Future<int> getPendingCount() async {
    final box = await _getBox();
    return box.length;
  }
}
