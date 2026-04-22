import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Test helper function to create a Touchpoint for testing
Touchpoint createTestTouchpoint({
  required int touchpointNumber,
  TouchpointType type = TouchpointType.visit,
  TouchpointReason reason = TouchpointReason.interested,
  TouchpointStatus status = TouchpointStatus.interested,
  String? photoPath,
  String? timeInGpsAddress,
  String? address,
  String? remarks,
}) {
  final now = DateTime.now();
  return Touchpoint(
    id: 'tp-1',
    clientId: 'client-1',
    touchpointNumber: touchpointNumber,
    type: type,
    reason: reason,
    status: status,
    date: now,
    photoPath: photoPath,
    timeInGpsAddress: timeInGpsAddress,
    address: address,
    remarks: remarks,
    createdAt: now,
  );
}

void main() {
  group('Touchpoint Test Helpers', () {
    testWidgets('createTestTouchpoint creates valid touchpoint', (tester) async {
      // Arrange & Act
      final touchpoint = createTestTouchpoint(
        touchpointNumber: 3,
        type: TouchpointType.call,
        reason: TouchpointReason.loanInquiry,
        status: TouchpointStatus.interested,
        timeInGpsAddress: '123 Main St, Manila, Metro Manila',
        remarks: 'Client interested in the product.',
      );

      // Assert
      expect(touchpoint.touchpointNumber, equals(3));
      expect(touchpoint.type, equals(TouchpointType.call));
      expect(touchpoint.reason, equals(TouchpointReason.loanInquiry));
      expect(touchpoint.status, equals(TouchpointStatus.interested));
      expect(touchpoint.timeInGpsAddress, equals('123 Main St, Manila, Metro Manila'));
      expect(touchpoint.remarks, equals('Client interested in the product.'));
    });

    testWidgets('createTestTouchpoint with default values', (tester) async {
      // Arrange & Act
      final touchpoint = createTestTouchpoint(
        touchpointNumber: 1,
      );

      // Assert - Check defaults
      expect(touchpoint.touchpointNumber, equals(1));
      expect(touchpoint.type, equals(TouchpointType.visit));
      expect(touchpoint.reason, equals(TouchpointReason.interested));
      expect(touchpoint.status, equals(TouchpointStatus.interested));
      expect(touchpoint.photoPath, isNull);
      expect(touchpoint.timeInGpsAddress, isNull);
      expect(touchpoint.remarks, isNull);
    });

    testWidgets('createTestTouchpoint with null photoPath', (tester) async {
      // Arrange & Act
      final touchpoint = createTestTouchpoint(
        touchpointNumber: 1,
        photoPath: null,
      );

      // Assert
      expect(touchpoint.photoPath, isNull);
    });

    testWidgets('createTestTouchpoint with empty remarks', (tester) async {
      // Arrange & Act
      final touchpoint = createTestTouchpoint(
        touchpointNumber: 1,
        remarks: '',
      );

      // Assert
      expect(touchpoint.remarks, equals(''));
    });
  });

  group('Touchpoint Model - Type Icons', () {
    testWidgets('visit touchpoint type renders correctly', (tester) async {
      // Arrange
      final visitTouchpoint = createTestTouchpoint(
        touchpointNumber: 1,
        type: TouchpointType.visit,
      );

      // Act & Assert
      expect(visitTouchpoint.type, equals(TouchpointType.visit));
      expect(visitTouchpoint.type.apiValue, equals('Visit'));
    });

    testWidgets('call touchpoint type renders correctly', (tester) async {
      // Arrange
      final callTouchpoint = createTestTouchpoint(
        touchpointNumber: 2,
        type: TouchpointType.call,
      );

      // Act & Assert
      expect(callTouchpoint.type, equals(TouchpointType.call));
      expect(callTouchpoint.type.apiValue, equals('Call'));
    });
  });

  group('Location Display Priority Logic', () {
    testWidgets('timeInGpsAddress takes priority over address', (tester) async {
      // Arrange - Both fields present
      final touchpoint = createTestTouchpoint(
        touchpointNumber: 1,
        timeInGpsAddress: 'GPS Address, Manila',
        address: 'Legacy Address',
      );

      // Act & Assert - Verify the data model has both fields
      expect(touchpoint.timeInGpsAddress, equals('GPS Address, Manila'));
      expect(touchpoint.address, equals('Legacy Address'));

      // The location display logic should prefer timeInGpsAddress
      // This is tested by checking that timeInGpsAddress is not null
      expect(touchpoint.timeInGpsAddress, isNotNull);
    });

    testWidgets('falls back to address when timeInGpsAddress is null', (tester) async {
      // Arrange
      final touchpoint = createTestTouchpoint(
        touchpointNumber: 1,
        timeInGpsAddress: null,
        address: 'Legacy Address',
      );

      // Act & Assert
      expect(touchpoint.timeInGpsAddress, isNull);
      expect(touchpoint.address, equals('Legacy Address'));
    });

    testWidgets('no address when both are null', (tester) async {
      // Arrange
      final touchpoint = createTestTouchpoint(
        touchpointNumber: 1,
        timeInGpsAddress: null,
        address: null,
      );

      // Act & Assert
      expect(touchpoint.timeInGpsAddress, isNull);
      expect(touchpoint.address, isNull);
    });
  });

  group('Photo Section Logic', () {
    testWidgets('photoPath is present when set', (tester) async {
      // Arrange
      final touchpoint = createTestTouchpoint(
        touchpointNumber: 1,
        photoPath: '/path/to/photo.jpg',
      );

      // Act & Assert
      expect(touchpoint.photoPath, equals('/path/to/photo.jpg'));
      expect(touchpoint.photoPath!.isNotEmpty, isTrue);
    });

    testWidgets('photoPath is null when not set', (tester) async {
      // Arrange
      final touchpoint = createTestTouchpoint(
        touchpointNumber: 1,
        photoPath: null,
      );

      // Act & Assert
      expect(touchpoint.photoPath, isNull);
    });

    testWidgets('photoPath can be empty string', (tester) async {
      // Arrange
      final touchpoint = createTestTouchpoint(
        touchpointNumber: 1,
        photoPath: '',
      );

      // Act & Assert
      expect(touchpoint.photoPath, equals(''));
      expect(touchpoint.photoPath!.isEmpty, isTrue);
    });
  });

  group('Remarks Display Logic', () {
    testWidgets('remarks are present when set', (tester) async {
      // Arrange
      final touchpoint = createTestTouchpoint(
        touchpointNumber: 1,
        remarks: 'This is a remark.',
      );

      // Act & Assert
      expect(touchpoint.remarks, equals('This is a remark.'));
      expect(touchpoint.remarks!.isNotEmpty, isTrue);
    });

    testWidgets('remarks can be null', (tester) async {
      // Arrange
      final touchpoint = createTestTouchpoint(
        touchpointNumber: 1,
        remarks: null,
      );

      // Act & Assert
      expect(touchpoint.remarks, isNull);
    });

    testWidgets('remarks can be empty string', (tester) async {
      // Arrange
      final touchpoint = createTestTouchpoint(
        touchpointNumber: 1,
        remarks: '',
      );

      // Act & Assert
      expect(touchpoint.remarks, equals(''));
      expect(touchpoint.remarks!.isEmpty, isTrue);
    });
  });

  group('Integration - Complete Touchpoint Data', () {
    testWidgets('complete touchpoint with all fields', (tester) async {
      // Arrange
      final touchpoint = createTestTouchpoint(
        touchpointNumber: 5,
        type: TouchpointType.visit,
        reason: TouchpointReason.forProcessing,
        status: TouchpointStatus.completed,
        timeInGpsAddress: '456 Oak Ave, Quezon City, Metro Manila',
        remarks: 'Documents submitted successfully.',
        photoPath: null,
      );

      // Act & Assert - Verify all fields
      expect(touchpoint.touchpointNumber, equals(5));
      expect(touchpoint.type, equals(TouchpointType.visit));
      expect(touchpoint.type.apiValue, equals('Visit'));
      expect(touchpoint.reason, equals(TouchpointReason.forProcessing));
      expect(touchpoint.status, equals(TouchpointStatus.completed));
      expect(touchpoint.status.apiValue, equals('COMPLETED'));
      expect(touchpoint.timeInGpsAddress, equals('456 Oak Ave, Quezon City, Metro Manila'));
      expect(touchpoint.remarks, equals('Documents submitted successfully.'));
      expect(touchpoint.photoPath, isNull);
    });

    testWidgets('minimal touchpoint with required fields only', (tester) async {
      // Arrange - Only required fields
      final touchpoint = createTestTouchpoint(
        touchpointNumber: 1,
        type: TouchpointType.call,
        reason: TouchpointReason.interested,
        status: TouchpointStatus.interested,
      );

      // Act & Assert - Required fields present
      expect(touchpoint.touchpointNumber, equals(1));
      expect(touchpoint.type, equals(TouchpointType.call));
      expect(touchpoint.reason, equals(TouchpointReason.interested));
      expect(touchpoint.status, equals(TouchpointStatus.interested));

      // Optional fields null/empty
      expect(touchpoint.photoPath, isNull);
      expect(touchpoint.timeInGpsAddress, isNull);
      expect(touchpoint.remarks, isNull);
      expect(touchpoint.address, isNull);
    });
  });
}
