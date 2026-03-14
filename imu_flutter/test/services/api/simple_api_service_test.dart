import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:imu_flutter/services/api/client_api_service.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

import '../../mocks/mocks.dart';

void main() {
  group('ClientApiService', () {
    late MockPocketBase mockPocketBase;
    late MockCollection mockCollection;
    late ClientApiService clientApiService;

    setUp(() {
      mockPocketBase = MockPocketBase();
      mockCollection = MockCollection();

      when(() => mockPocketBase.collection(any())).thenReturn(mockCollection);

      clientApiService = ClientApiService(pb: mockPocketBase);
    });

    test('fetchClients returns list of clients', () async {
      // Arrange
      final clientJson = {
        'id': 'client-1',
        'first_name': 'John',
        'last_name': 'Doe',
        'email': 'john@example.com',
        'client_type': 'EXISTING',
        'product_type': 'sssPensioner',
        'pension_type': 'sss',
        'market_type': 'residential',
        'created': '2024-01-01T00:00:00.000Z',
        'updated': '2024-01-02T00:00:00.000Z',
      };

      final record1 = MockRecordModel();
      when(() => record1.data).thenReturn(clientJson);
      when(() => record1.id).thenReturn('client-1');

      when(() => mockCollection.getList(
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
        filter: any(named: 'filter'),
        sort: any(named: 'sort'),
        expand: any(named: 'expand'),
      )).thenAnswer((_) async {
        final result = ResultList();
        result.items = [record1];
        return result;
      });

      // Act
      final result = await clientApiService.fetchClients();

      // Assert
      expect(result.length, equals(1));
      expect(result.first.id, equals('client-1'));
    });

    test('fetchClient returns single client', () async {
      // Arrange
      final clientJson = {
        'id': 'client-1',
        'first_name': 'John',
        'last_name': 'Doe',
        'email': 'john@example.com',
        'client_type': 'EXISTING',
        'product_type': 'sssPensioner',
        'pension_type': 'sss',
        'market_type': 'residential',
        'created': '2024-01-01T00:00:00.000Z',
      };

      final record = MockRecordModel();
      when(() => record.data).thenReturn(clientJson);
      when(() => record.id).thenReturn('client-1');

      when(() => mockCollection.getOne(
        any(),
        expand: any(named: 'expand'),
      )).thenAnswer((_) async => record);

      // Act
      final result = await clientApiService.fetchClient('client-1');

      // Assert
      expect(result, isNotNull);
      expect(result.id, equals('client-1'));
      expect(result.fullName, equals('John Doe'));
    });

    test('createClient creates new client', () async {
      // Arrange
      final newClient = Client(
        id: '',
        firstName: 'New',
        lastName: 'Client',
        email: 'new@example.com',
        clientType: ClientType.potential,
        productType: ProductType.sssPensioner,
        pensionType: PensionType.sss,
        addresses: [],
        phoneNumbers: [],
        touchpoints: [],
        createdAt: DateTime.now(),
      );

      final createdRecord = MockRecordModel();
      when(() => createdRecord.data).thenReturn({
        'id': 'new-client-1',
        'first_name': 'New',
        'last_name': 'Client',
        'email': 'new@example.com',
        'client_type': 'POTENTIAL',
        'product_type': 'sssPensioner',
        'pension_type': 'sss',
        'created': DateTime.now().toIso8601String(),
      });
      when(() => createdRecord.id).thenReturn('new-client-1');

      when(() => mockCollection.create(body: any(named: 'body')))
          .thenAnswer((_) async => createdRecord);

      // Act
      final result = await clientApiService.createClient(newClient);

      // Assert
      expect(result.id, isNotEmpty);
    });

    test('updateClient updates existing client', () async {
      // Arrange
      final updatedClient = Client(
        id: 'client-1',
        firstName: 'John',
        lastName: 'Updated',
        email: 'john.updated@example.com',
        clientType: ClientType.existing,
        productType: ProductType.sssPensioner,
        pensionType: PensionType.sss,
        addresses: [],
        phoneNumbers: [],
        touchpoints: [],
        createdAt: DateTime.now(),
      );

      final updatedRecord = MockRecordModel();
      when(() => updatedRecord.data).thenReturn({
        'id': 'client-1',
        'first_name': 'John',
        'last_name': 'Updated',
        'email': 'john.updated@example.com',
        'client_type': 'EXISTING',
        'product_type': 'sssPensioner',
        'pension_type': 'sss',
        'created': '2024-01-01T00:00:00.000Z',
        'updated': DateTime.now().toIso8601String(),
      });
      when(() => updatedRecord.id).thenReturn('client-1');

      when(() => mockCollection.update(any(), body: any(named: 'body')))
          .thenAnswer((_) async => updatedRecord);

      // Act
      final result = await clientApiService.updateClient(updatedClient);

      // Assert
      expect(result.lastName, equals('Updated'));
    });

    test('deleteClient removes client', () async {
      // Arrange
      when(() => mockCollection.delete(any())).thenAnswer((_) async {});

      // Act
      await clientApiService.deleteClient('client-1');

      // Assert
      verify(() => mockCollection.delete('client-1')).called(1);
    });
  });
}
