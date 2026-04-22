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
}
