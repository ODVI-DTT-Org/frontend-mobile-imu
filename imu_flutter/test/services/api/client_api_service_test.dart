import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:imu_flutter/services/api/client_api_service.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

import '../../mocks/mocks.dart';

void main() {
  late ClientApiService clientApiService;
  late MockPocketBase mockPocketBase;
  late MockCollection mockCollection;

  setUp(() {
    mockPocketBase = MockPocketBase();
    mockCollection = MockCollection();

    when(() => mockPocketBase.collection(any)).thenReturn(mockCollection);

    clientApiService = ClientApiService(pb: mockPocketBase);
  });

  group('ClientApiService', () {
    late Map<String, dynamic> clientJson;
    late Map<String, dynamic> existingClientJson;

    setUp(() {
      clientJson = {
        'id': 'client-1',
        'first_name': 'John',
        'last_name': 'Doe',
        'email': 'john@example.com',
        'client_type': 'EXISTING',
        'product_type': 'SSS Pensioner',
        'pension_type': 'SSS',
        'market_type': 'Residential',
        'phone_numbers': [
          {'number': '+639123456789', 'type': 'mobile'}
        ],
        'addresses': [
          {
            'street': '123 Main St',
            'city': 'Makati',
            'postal_code': '1200',
            'country': 'Philippines',
            'full_address': '123 Main St, Makati 1200'
          }
        ],
        'is_starred': false,
        'completed_touchpoints': 3,
        'created': '2024-01-01T00:00:00.000Z',
        'updated': '2024-01-02T00:00:00.000Z',
      };

      existingClientJson = {
        'id': 'client-2',
        'first_name': 'Jane',
        'last_name': 'Smith',
        'email': 'jane@example.com',
        'client_type': 'POTENTIAL',
        'product_type': 'GSIS Pensioner',
        'pension_type': 'GSIS',
        'market_type': 'Commercial',
        'phone_numbers': [],
        'addresses': [],
        'is_starred': true,
        'completed_touchpoints': 0,
        'created': '2024-01-01T00:00:00.000Z',
        'updated': '2024-01-02T00:00:00.000Z',
      };
    });

    test('fetchClients returns list of clients', () async {
      // Arrange
      final record1 = MockRecordModel();
      final record2 = MockRecordModel();
      final resultList = MockRecordModelList();

      when(() => record1.data).thenReturn(clientJson);
      when(() => record1.id).thenReturn('client-1');
      when(() => record2.data).thenReturn(existingClientJson);
      when(() => record2.id).thenReturn('client-2');
      when(() => resultList.items).thenReturn([record1, record2]);

      when(() => mockCollection.getList(
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
        sort: any(named: 'sort'),
      )).thenAnswer((_) async => resultList);

      // Act
      final result = await clientApiService.fetchClients();

      // Assert
      expect(result.length, equals(2));
      expect(result.first.id, equals('client-1'));
      expect(result.last.id, equals('client-2'));
    });

    test('fetchClient returns single client', () async {
      // Arrange
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
      expect(result!.id, equals('client-1'));
      expect(result.fullName, equals('John Doe'));
    });

    test('createClient creates new client', () async {
      // Arrange
      final newClientData = Client(
        id: '',
        firstName: 'New',
        lastName: 'Client',
        email: 'new@example.com',
        clientType: ClientType.potential,
        productType: 'SSS Pensioner',
        pensionType: 'SSS',
        marketType: 'Residential',
        phoneNumbers: [],
        addresses: [],
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
        'product_type': 'SSS Pensioner',
        'pension_type': 'SSS',
        'market_type': 'Residential',
        'phone_numbers': [],
        'addresses': [],
        'is_starred': false,
        'completed_touchpoints': 0,
        'created': DateTime.now().toIso8601String(),
      });
      when(() => createdRecord.id).thenReturn('new-client-1');

      when(() => mockCollection.create(
        body: any(named: 'body'),
      )).thenAnswer((_) async => createdRecord);

      // Act
      final result = await clientApiService.createClient(newClientData);

      // Assert
      expect(result.id, isNotEmpty);
      expect(result.firstName, equals('New'));
    });

    test('updateClient updates existing client', () async {
      // Arrange
      final updatedClient = Client(
        id: 'client-1',
        firstName: 'John',
        lastName: 'Updated',
        email: 'john.updated@example.com',
        clientType: ClientType.existing,
        productType: 'SSS Pensioner',
        pensionType: 'SSS',
        marketType: 'Residential',
        phoneNumbers: [],
        addresses: [],
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
        'product_type': 'SSS Pensioner',
        'pension_type': 'SSS',
        'market_type': 'Residential',
        'phone_numbers': [],
        'addresses': [],
        'is_starred': false,
        'completed_touchpoints': 3,
        'created': '2024-01-01T00:00:00.000Z',
        'updated': DateTime.now().toIso8601String(),
      });
      when(() => updatedRecord.id).thenReturn('client-1');

      when(() => mockCollection.update(
        any(),
        body: any(named: 'body'),
      )).thenAnswer((_) async => updatedRecord);

      // Act
      final result = await clientApiService.updateClient(updatedClient);

      // Assert
      expect(result.lastName, equals('Updated'));
    });

    test('deleteClient removes client', () async {
      // Arrange
      when(() => mockCollection.delete(any()))
        .thenAnswer((_) async {});

      // Act
      await clientApiService.deleteClient('client-1');

      // Assert
      verify(() => mockCollection.delete('client-1')).called(1);
    });
  });
}
