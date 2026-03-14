import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:imu_flutter/services/api/client_api_service.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

import '../../mocks/mocks.dart';

class MockRecordService extends Mock implements RecordService {}

void main() {
  late ClientApiService clientApiService;
  late MockPocketBase mockPocketBase;
  late MockRecordService mockRecordService;

  setUp(() {
    mockPocketBase = MockPocketBase();
    mockRecordService = MockRecordService();

    when(() => mockPocketBase.collection('clients')).thenReturn(mockRecordService);

    clientApiService = ClientApiService(pb: mockPocketBase);
  });

  group('ClientApiService', () {
    test('fetchClients retrieves clients list', () async {
      // Arrange
      final mockRecord = MockRecordModel();
      when(() => mockRecord.id).thenReturn('client-1');
      when(() => mockRecord.data).thenReturn({
        'id': 'client-1',
        'first_name': 'John',
        'last_name': 'Doe',
        'email': 'john@example.com',
        'client_type': 'EXISTING',
        'product_type': 'SSS_PENSIONER',
        'pension_type': 'SSS',
        'market_type': 'RESIDENTIAL',
        'phone': '+639123456789',
        'is_starred': false,
        'created': '2024-01-01T00:00:00.000Z',
      });

      // Use List<RecordModel> instead of ResultList
      when(() => mockRecordService.getFullList())
          .thenAnswer((_) async => [mockRecord]);

      // Act
      final result = await clientApiService.fetchClients();

      // Assert
      expect(result.length, equals(1));
      expect(result.first.lastName, equals('Doe'));
    });

    test('updateClient updates client', () async {
      // Arrange
      final updatedRecord = MockRecordModel();
      when(() => updatedRecord.id).thenReturn('client-1');
      when(() => updatedRecord.data).thenReturn({
        'id': 'client-1',
        'first_name': 'John',
        'last_name': 'Updated',
        'email': 'john.updated@example.com',
        'client_type': 'EXISTING',
        'product_type': 'SSS_PENSIONER',
        'pension_type': 'SSS',
        'market_type': 'RESIDENTIAL',
        'phone': '+639123456789',
        'is_starred': false,
        'created': '2024-01-01T00:00:00.000Z',
        'updated': '2024-01-02T00:00:00.000Z',
      });
      when(() => mockRecordService.update('client-1', body: any(named: 'body')))
          .thenAnswer((_) async => updatedRecord);

      // Act
      final updatedClient = Client(
        id: 'client-1',
        firstName: 'John',
        lastName: 'Updated',
        email: 'john.updated@example.com',
        clientType: ClientType.existing,
        productType: ProductType.sssPensioner,
        pensionType: PensionType.sss,
        marketType: MarketType.residential,
        createdAt: DateTime(2024, 1, 1),
      );
      final result = await clientApiService.updateClient(updatedClient);

      // Assert
      expect(result.lastName, equals('Updated'));
    });

    test('deleteClient removes client', () async {
      // Arrange
      when(() => mockRecordService.delete('client-1')).thenAnswer((_) async {});

      // Act
      await clientApiService.deleteClient('client-1');

      // Assert
      verify(() => mockRecordService.delete('client-1')).called(1);
    });
  });
}
