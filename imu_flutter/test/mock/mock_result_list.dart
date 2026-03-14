import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:imu_flutter/services/api/sync_queue_service.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

class MockResultList<T> extends Mock implements ResultList<T> {
  @override
  List<T> get items => [];

  @override
  int get length => items.length;

  @override
  int get page => 1;

  @override
  int get perPage => 1;

  @override
  int get totalPages => 1;
}
