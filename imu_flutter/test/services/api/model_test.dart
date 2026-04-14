import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

void main() {
  group('Client Model Tests', () {
    test('Client can be created with required fields', () {
      final client = Client(
        id: 'test-id',
        firstName: 'John',
        lastName: 'Doe',
        clientType: ClientType.potential,
        productType: ProductType.pnpPension,
        pensionType: PensionType.sss,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(client.id, equals('test-id'));
      expect(client.firstName, equals('John'));
      expect(client.lastName, equals('Doe'));
      expect(client.fullName, equals('John Doe'));
      expect(client.clientType, equals(ClientType.potential));
      expect(client.productType, equals(ProductType.pnpPension));
      expect(client.pensionType, equals(PensionType.sss));
    });

    test('Client fullName includes middle name when present', () {
      final client = Client(
        id: 'test-id',
        firstName: 'John',
        middleName: 'William',
        lastName: 'Doe',
        clientType: ClientType.existing,
        productType: ProductType.pnpPension,
        pensionType: PensionType.gsis,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(client.fullName, equals('John William Doe'));
    });

    test('TouchpointType enum has expected values', () {
      expect(TouchpointType.values.length, equals(2));
      expect(TouchpointType.values, contains(TouchpointType.visit));
      expect(TouchpointType.values, contains(TouchpointType.call));
    });

    test('TouchpointReason enum has expected values', () {
      expect(TouchpointReason.values.length, greaterThan(10));
      expect(TouchpointReason.values, contains(TouchpointReason.interested));
      expect(TouchpointReason.values, contains(TouchpointReason.notInterested));
    });
  });

  group('Address Model Tests', () {
    test('Address can be created with required fields', () {
      final address = Address(
        id: 'addr-1',
        street: '123 Main St',
        city: 'Makati',
        province: 'Metro Manila',
        zipCode: '1200',
      );

      expect(address.id, equals('addr-1'));
      expect(address.street, equals('123 Main St'));
      expect(address.city, equals('Makati'));
      expect(address.province, equals('Metro Manila'));
      expect(address.zipCode, equals('1200'));
    });
  });

  group('PhoneNumber Model Tests', () {
    test('PhoneNumber can be created with required fields', () {
      final phone = PhoneNumber(
        id: 'phone-1',
        number: '+639123456789',
        label: 'Mobile',
      );

      expect(phone.id, equals('phone-1'));
      expect(phone.number, equals('+639123456789'));
      expect(phone.label, equals('Mobile'));
    });
  });
}
