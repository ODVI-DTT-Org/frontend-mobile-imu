import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:imu_flutter/services/api/conflict_resolver_service.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

import '../../mocks/mocks.dart';

void main() {
  // Register fallback values for mocktail
  setUpAll(() {
    registerFallbackValue(Client(
      id: 'fallback',
      firstName: 'Fallback',
      middleName: null,
      lastName: 'Client',
      clientType: ClientType.existing,
      productType: ProductType.private,
      pensionType: PensionType.private,
      createdAt: DateTime.now(),
    ));
    registerFallbackValue(Touchpoint(
      id: 'fallback',
      clientId: 'fallback',
      touchpointNumber: 1,
      type: TouchpointType.visit,
      date: DateTime.now(),
      reason: TouchpointReason.interested,
      status: TouchpointStatus.interested,
      createdAt: DateTime.now(),
    ));
  });

  late ConflictResolverService conflictResolver;
  late MockHiveService mockHiveService;
  late MockClientApiService mockClientApi;
  late MockTouchpointApiService mockTouchpointApi;

  setUp(() {
    mockHiveService = MockHiveService();
    mockClientApi = MockClientApiService();
    mockTouchpointApi = MockTouchpointApiService();

    when(() => mockHiveService.isInitialized).thenReturn(true);

    // Mock update methods to return success
    when(() => mockClientApi.updateClient(any())).thenAnswer((_) async => Client(
      id: '1',
      firstName: 'Test',
      middleName: null,
      lastName: 'Client',
      clientType: ClientType.existing,
      productType: ProductType.private,
      pensionType: PensionType.private,
      createdAt: DateTime.now(),
    ));
    when(() => mockTouchpointApi.updateTouchpoint(any())).thenAnswer((_) async => Touchpoint(
      id: 'tp-1',
      clientId: '1',
      touchpointNumber: 1,
      type: TouchpointType.visit,
      date: DateTime.now(),
      reason: TouchpointReason.interested,
      status: TouchpointStatus.interested,
      createdAt: DateTime.now(),
    ));
    when(() => mockHiveService.updateClient(any())).thenAnswer((_) async {});
    when(() => mockHiveService.updateTouchpoint(any())).thenAnswer((_) async {});

    conflictResolver = ConflictResolverService(
      hiveService: mockHiveService,
      clientApi: mockClientApi,
      touchpointApi: mockTouchpointApi,
    );
  });

  group('ConflictResolverService', () {
    test('detectConflicts returns empty list when data is identical', () async {
      // Arrange
      final localData = [
        {'id': '1', 'name': 'Test', 'updated': '2024-01-01T00:00:00.000Z'},
      ];
      final serverData = [
        {'id': '1', 'name': 'Test', 'updated': '2024-01-01T00:00:00.000Z'},
      ];

      // Act
      final conflicts = await conflictResolver.detectConflicts(
        entityType: 'client',
        localItems: localData,
        serverItems: serverData,
      );

      // Assert
      expect(conflicts, isEmpty);
    });

    test('detectConflicts finds conflict when server is newer', () async {
      // Arrange
      final localData = [
        {'id': '1', 'name': 'Test', 'updated': '2024-01-01T00:00:00.000Z'},
      ];
      final serverData = [
        {'id': '1', 'name': 'Updated Test', 'updated': '2024-01-02T00:00:00.000Z'},
      ];

      // Act
      final conflicts = await conflictResolver.detectConflicts(
        entityType: 'client',
        localItems: localData,
        serverItems: serverData,
      );

      // Assert
      expect(conflicts.length, equals(1));
      expect(conflicts.first.conflictType, equals('update_conflict'));
    });

    test('detectConflicts finds no conflict when local is newer', () async {
      // Arrange
      final localData = [
        {'id': '1', 'name': 'Test Updated', 'updated': '2024-01-03T00:00:00.000Z'},
      ];
      final serverData = [
        {'id': '1', 'name': 'Test', 'updated': '2024-01-01T00:00:00.000Z'},
      ];

      // Act
      final conflicts = await conflictResolver.detectConflicts(
        entityType: 'client',
        localItems: localData,
        serverItems: serverData,
      );

      // Assert - local wins automatically, no conflict to resolve
      expect(conflicts, isEmpty);
    });

    test('resolveConflict with serverWins updates local', () async {
      // Arrange
      final conflict = SyncConflict(
        id: 'conflict-1',
        entityType: 'client',
        operation: 'update',
        localData: {'id': '1', 'name': 'Local'},
        serverData: {'id': '1', 'name': 'Server'},
        detectedAt: DateTime.now(),
        conflictType: 'update_conflict',
      );

      // Act
      final result = await conflictResolver.resolveConflict(
        conflict,
        strategy: ConflictResolution.serverWins,
      );

      // Assert
      expect(result.resolved, isTrue);
      expect(result.resolution, equals(ConflictResolution.serverWins));
      expect(result.resolvedData?['name'], equals('Server'));
    });

    test('resolveConflict with localWins keeps local data', () async {
      // Arrange
      final conflict = SyncConflict(
        id: 'conflict-1',
        entityType: 'client',
        operation: 'update',
        localData: {'id': '1', 'name': 'Local', 'notes': 'User notes'},
        serverData: {'id': '1', 'name': 'Server', 'notes': 'Server notes'},
        detectedAt: DateTime.now(),
        conflictType: 'update_conflict',
      );

      // Act
      final result = await conflictResolver.resolveConflict(
        conflict,
        strategy: ConflictResolution.localWins,
      );

      // Assert
      expect(result.resolved, isTrue);
      expect(result.resolution, equals(ConflictResolution.localWins));
      expect(result.resolvedData?['name'], equals('Local'));
      expect(result.resolvedData?['notes'], equals('User notes'));
    });

    test('resolveConflict with merge combines data', () async {
      // Arrange
      final conflict = SyncConflict(
        id: 'conflict-1',
        entityType: 'client',
        operation: 'update',
        localData: {
          'id': '1',
          'name': 'Local Name',
          'notes': 'Local notes',
          'system_field': 'Local system',
        },
        serverData: {
          'id': '1',
          'name': 'Server Name',
          'notes': 'Server notes',
          'system_field': 'Server system',
        },
        detectedAt: DateTime.now(),
        conflictType: 'update_conflict',
      );

      // Act
      final result = await conflictResolver.resolveConflict(
        conflict,
        strategy: ConflictResolution.merge,
      );

      // Assert
      expect(result.resolved, isTrue);
      expect(result.resolution, equals(ConflictResolution.merge));
      // Merge should exist
      expect(result.resolvedData, isNotNull);
    });

    test('resolveConflict with askUser returns unresolved', () async {
      // Arrange
      final conflict = SyncConflict(
        id: 'conflict-1',
        entityType: 'client',
        operation: 'update',
        localData: {'id': '1', 'name': 'Local'},
        serverData: {'id': '1', 'name': 'Server'},
        detectedAt: DateTime.now(),
        conflictType: 'update_conflict',
      );

      // Act
      final result = await conflictResolver.resolveConflict(
        conflict,
        strategy: ConflictResolution.askUser,
      );

      // Assert
      expect(result.resolved, isFalse);
      expect(result.resolution, equals(ConflictResolution.askUser));
    });

    test('detectConflicts handles multiple items', () async {
      // Arrange
      final localData = [
        {'id': '1', 'name': 'Test 1', 'updated': '2024-01-01T00:00:00.000Z'},
        {'id': '2', 'name': 'Test 2', 'updated': '2024-01-02T00:00:00.000Z'},
        {'id': '3', 'name': 'Test 3', 'updated': '2024-01-03T00:00:00.000Z'},
      ];
      final serverData = [
        {'id': '1', 'name': 'Test 1', 'updated': '2024-01-01T00:00:00.000Z'}, // No conflict
        {'id': '2', 'name': 'Test 2 Updated', 'updated': '2024-01-03T00:00:00.000Z'}, // Conflict
        {'id': '3', 'name': 'Test 3', 'updated': '2024-01-02T00:00:00.000Z'}, // No conflict (local newer)
      ];

      // Act
      final conflicts = await conflictResolver.detectConflicts(
        entityType: 'client',
        localItems: localData,
        serverItems: serverData,
      );

      // Assert
      expect(conflicts.length, equals(1));
      expect(conflicts.first.localData['id'], equals('2'));
    });
  });
}
