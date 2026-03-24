import 'package:mocktail/mocktail.dart';
import 'package:imu_flutter/services/api/client_api_service.dart';
import 'package:imu_flutter/services/api/touchpoint_api_service.dart';
import 'package:imu_flutter/services/local_storage/hive_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Mock ClientApiService
class MockClientApiService extends Mock implements ClientApiService {}

/// Mock TouchpointApiService
class MockTouchpointApiService extends Mock implements TouchpointApiService {}

/// Mock HiveService
class MockHiveService extends Mock implements HiveService {}

/// Mock Box
class MockBox<T> extends Mock implements Box<T> {}
