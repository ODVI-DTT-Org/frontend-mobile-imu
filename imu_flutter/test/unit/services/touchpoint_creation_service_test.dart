import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:imu_flutter/services/touchpoint/touchpoint_creation_service.dart';
import 'package:imu_flutter/services/connectivity_service.dart';
import 'package:imu_flutter/services/api/touchpoint_api_service.dart';
import 'package:imu_flutter/services/touchpoint/pending_touchpoint_service.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'dart:io' as io;

class MockConnectivityService extends Mock implements ConnectivityService {}
class MockTouchpointApiService extends Mock implements TouchpointApiService {}
class MockPendingTouchpointService extends Mock implements PendingTouchpointService {}

void main() {
  // Initialize Flutter bindings for tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TouchpointCreationService', () {
    late TouchpointCreationService service;
    late MockConnectivityService mockConnectivity;
    late MockTouchpointApiService mockApi;
    late MockPendingTouchpointService mockPending;

    setUpAll(() {
      // Register fallback values for mocktail
      registerFallbackValue(Touchpoint(
        id: 'fallback',
        clientId: 'fallback',
        touchpointNumber: 1,
        type: TouchpointType.visit,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        reason: TouchpointReason.loanInquiry,
        status: TouchpointStatus.interested,
      ));
      registerFallbackValue(io.File('fallback.txt'));
    });

    setUp(() {
      mockConnectivity = MockConnectivityService();
      mockApi = MockTouchpointApiService();
      mockPending = MockPendingTouchpointService();

      // Set up default behaviors
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockApi.createTouchpoint(any<Touchpoint>())).thenAnswer((_) async => null);
      when(() => mockApi.createTouchpointWithPhoto(any<Touchpoint>(), photoFile: any<io.File?>(named: 'photoFile'))).thenAnswer((_) async => null);
      when(() => mockPending.addPendingTouchpoint(any<String>(), any<Touchpoint>(), photoPath: any(named: 'photoPath'), audioPath: any(named: 'audioPath'))).thenAnswer((_) async {});

      service = TouchpointCreationService(
        mockConnectivity,
        mockApi,
        mockPending,
      );
    });

    test('should call API when online', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);

      final touchpoint = Touchpoint(
        id: 'tp-1',
        clientId: 'client-1',
        touchpointNumber: 1,
        type: TouchpointType.visit,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        reason: TouchpointReason.loanInquiry,
        status: TouchpointStatus.interested,
      );

      await service.createTouchpoint('client-1', touchpoint);

      verify(() => mockApi.createTouchpoint(touchpoint)).called(1);
      verifyNever(() => mockPending.addPendingTouchpoint(any<String>(), any<Touchpoint>(), photoPath: any(named: 'photoPath'), audioPath: any(named: 'audioPath')));
    });

    test('should call API with photo when online and has photo', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);

      final touchpoint = Touchpoint(
        id: 'tp-1',
        clientId: 'client-1',
        touchpointNumber: 1,
        type: TouchpointType.visit,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        reason: TouchpointReason.loanInquiry,
        status: TouchpointStatus.interested,
      );

      final photo = io.File('test_photo.jpg');

      await service.createTouchpoint('client-1', touchpoint, photo: photo);

      verify(() => mockApi.createTouchpointWithPhoto(touchpoint, photoFile: photo)).called(1);
      verifyNever(() => mockPending.addPendingTouchpoint(any<String>(), any<Touchpoint>(), photoPath: any(named: 'photoPath'), audioPath: any(named: 'audioPath')));
    });

    test('should store in pending when offline', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);

      final touchpoint = Touchpoint(
        id: 'tp-1',
        clientId: 'client-1',
        touchpointNumber: 1,
        type: TouchpointType.visit,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        reason: TouchpointReason.loanInquiry,
        status: TouchpointStatus.interested,
      );

      await service.createTouchpoint('client-1', touchpoint);

      verifyNever(() => mockApi.createTouchpoint(any<Touchpoint>()));
      verifyNever(() => mockApi.createTouchpointWithPhoto(any<Touchpoint>(), photoFile: any(named: 'photoFile')));
      verify(() => mockPending.addPendingTouchpoint('client-1', touchpoint, photoPath: null, audioPath: null)).called(1);
    });

    test('should store in pending when offline with photo', () async {
      // Skip this test in unit tests because it requires platform plugins for file operations
      // This functionality is tested in integration tests
    }, skip: 'Requires platform plugins for file operations - tested in integration tests');
  });
}
