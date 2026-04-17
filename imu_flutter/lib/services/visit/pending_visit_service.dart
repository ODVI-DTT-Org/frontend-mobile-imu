import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'models/pending_visit.dart';

class PendingVisitService {
  static const String _boxName = 'pending_visits';
  final Uuid _uuid = const Uuid();

  Future<Box<Map>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<Map>(_boxName);
    }
    return Hive.box<Map>(_boxName);
  }

  Future<void> addPendingVisit({
    required String clientId,
    required String timeIn,
    required String timeOut,
    required String odometerArrival,
    required String odometerDeparture,
    String? photoPath,
    String? notes,
    String type = 'regular_visit',
  }) async {
    final box = await _getBox();
    final id = _uuid.v4();
    final pending = PendingVisit(
      id: id,
      clientId: clientId,
      timeIn: timeIn,
      timeOut: timeOut,
      odometerArrival: odometerArrival,
      odometerDeparture: odometerDeparture,
      photoPath: photoPath,
      notes: notes,
      type: type,
      createdAt: DateTime.now(),
    );
    await box.put(id, pending.toJson());
  }

  Future<List<PendingVisit>> getPendingVisits() async {
    final box = await _getBox();
    return box.values
        .map((v) => PendingVisit.fromJson(Map<String, dynamic>.from(v as Map)))
        .toList();
  }

  Future<void> removePendingVisit(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  Future<int> getPendingCount() async {
    final box = await _getBox();
    return box.length;
  }
}
