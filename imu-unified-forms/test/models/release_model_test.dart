import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/models/release_model.dart';

void main() {
  group('Release Model', () {
    test('should create Release from row map', () {
      // Arrange
      final row = {
        'id': 'release-123',
        'client_id': 'client-123',
        'user_id': 'user-456',
        'visit_id': 'visit-789',
        'product_type': 'PUSU',
        'loan_type': 'NEW',
        'amount': 50000.0,
        'approval_notes': 'Client meets all requirements',
        'status': 'pending',
        'created_at': '2024-01-15T09:00:00.000Z',
        'updated_at': '2024-01-15T09:00:00.000Z',
      };

      // Act
      final release = Release.fromRow(row);

      // Assert
      expect(release.id, equals('release-123'));
      expect(release.clientId, equals('client-123'));
      expect(release.userId, equals('user-456'));
      expect(release.visitId, equals('visit-789'));
      expect(release.productType, equals('PUSU'));
      expect(release.loanType, equals('NEW'));
      expect(release.amount, equals(50000.0));
      expect(release.approvalNotes, equals('Client meets all requirements'));
      expect(release.status, equals('pending'));
    });

    test('should create Release with null approval notes', () {
      // Arrange
      final row = {
        'id': 'release-123',
        'client_id': 'client-123',
        'user_id': 'user-456',
        'visit_id': 'visit-789',
        'product_type': 'LIKA',
        'loan_type': 'RENEWAL',
        'amount': 75000.0,
        'approval_notes': null,
        'status': 'approved',
        'created_at': '2024-01-15T09:00:00.000Z',
        'updated_at': '2024-01-15T10:00:00.000Z',
      };

      // Act
      final release = Release.fromRow(row);

      // Assert
      expect(release.approvalNotes, isNull);
      expect(release.status, equals('approved'));
    });

    test('should convert Release to row map', () {
      // Arrange
      final release = Release(
        id: 'release-123',
        clientId: 'client-123',
        userId: 'user-456',
        visitId: 'visit-789',
        productType: 'SUB2K',
        loanType: 'ADDITIONAL',
        amount: 100000.0,
        approvalNotes: 'Approved by manager',
        status: 'approved',
        createdAt: DateTime.parse('2024-01-15T09:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
      );

      // Act
      final row = release.toRow();

      // Assert
      expect(row['id'], equals('release-123'));
      expect(row['client_id'], equals('client-123'));
      expect(row['user_id'], equals('user-456'));
      expect(row['visit_id'], equals('visit-789'));
      expect(row['product_type'], equals('SUB2K'));
      expect(row['loan_type'], equals('ADDITIONAL'));
      expect(row['amount'], equals(100000.0));
      expect(row['approval_notes'], equals('Approved by manager'));
      expect(row['status'], equals('approved'));
    });

    test('should copy Release with new values', () {
      // Arrange
      final original = Release(
        id: 'release-123',
        clientId: 'client-123',
        userId: 'user-456',
        visitId: 'visit-789',
        productType: 'PUSU',
        loanType: 'NEW',
        amount: 50000.0,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final copy = original.copyWith(
        status: 'approved',
        approvalNotes: 'All documents verified',
      );

      // Assert
      expect(copy.id, equals(original.id));
      expect(copy.productType, equals(original.productType));
      expect(copy.status, equals('approved'));
      expect(copy.approvalNotes, equals('All documents verified'));
      expect(copy.amount, equals(original.amount));
    });

    test('should handle numeric amount conversion', () {
      // Arrange
      final row = {
        'id': 'release-123',
        'client_id': 'client-123',
        'user_id': 'user-456',
        'visit_id': 'visit-789',
        'product_type': 'PUSU',
        'loan_type': 'PRETERM',
        'amount': 50000, // int instead of double
        'approval_notes': null,
        'status': 'pending',
        'created_at': '2024-01-15T09:00:00.000Z',
        'updated_at': '2024-01-15T09:00:00.000Z',
      };

      // Act
      final release = Release.fromRow(row);

      // Assert
      expect(release.amount, equals(50000.0)); // Should convert to double
    });
  });
}
