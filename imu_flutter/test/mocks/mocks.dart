import 'package:mocktail/mocktail.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:imu_flutter/services/api/client_api_service.dart';
import 'package:imu_flutter/services/api/touchpoint_api_service.dart';
import 'package:imu_flutter/services/local_storage/hive_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Mock PocketBase client
class MockPocketBase extends Mock implements PocketBase {}

/// Mock RecordService
class MockRecordService extends Mock implements RecordService {}

/// Mock RecordModel
class MockRecordModel extends Mock implements RecordModel {}

/// Mock ResultList for RecordModel (most common use case)
class MockResultList extends Mock implements ResultList<RecordModel> {}

/// Mock ClientApiService
class MockClientApiService extends Mock implements ClientApiService {}

/// Mock TouchpointApiService
class MockTouchpointApiService extends Mock implements TouchpointApiService {}

/// Mock HiveService
class MockHiveService extends Mock implements HiveService {}

/// Mock Box
class MockBox<T> extends Mock implements Box<T> {}

/// Mock AuthStore
class MockAuthStore extends Mock implements AuthStore {}

/// Mock Collection - for PocketBase collection operations
class MockCollection extends Mock implements RecordService {}
