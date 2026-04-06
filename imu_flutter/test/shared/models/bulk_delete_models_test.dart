import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/shared/models/bulk_delete_models.dart';

void main() {
  group('BulkDeleteResult', () {
    test('isSuccessful returns true when no errors', () {
      final result = BulkDeleteResult(
        successCount: 10,
        errorCount: 0,
        errors: [],
      );
      expect(result.isSuccessful, true);
      expect(result.isPartialFailure, false);
      expect(result.isCompleteFailure, false);
    });

    test('isPartialFailure returns true when mixed results', () {
      final result = BulkDeleteResult(
        successCount: 7,
        errorCount: 3,
        errors: [],
      );
      expect(result.isSuccessful, false);
      expect(result.isPartialFailure, true);
      expect(result.isCompleteFailure, false);
    });

    test('isCompleteFailure returns true when all fail', () {
      final result = BulkDeleteResult(
        successCount: 0,
        errorCount: 10,
        errors: [],
      );
      expect(result.isSuccessful, false);
      expect(result.isPartialFailure, false);
      expect(result.isCompleteFailure, true);
    });

    test('fromJson parses itinerary response correctly', () {
      final json = {
        'success': true,
        'deleted': 5,
        'failed': 2,
        'errors': [
          {'id': 'uuid1', 'error': 'Not found'},
          {'id': 'uuid2', 'error': 'Permission denied'},
        ],
      };

      final result = BulkDeleteResult.fromJson(json);
      expect(result.successCount, 5);
      expect(result.errorCount, 2);
      expect(result.errors.length, 2);
      expect(result.errors.first.id, 'uuid1');
    });

    test('fromJson parses My Day response correctly', () {
      final json = {
        'success': true,
        'removed': 8,
        'failed': 1,
        'errors': [
          {'id': 'uuid1', 'error': 'Not found'},
        ],
      };

      final result = BulkDeleteResult.fromJson(json);
      expect(result.successCount, 8);
      expect(result.errorCount, 1);
      expect(result.errors.length, 1);
    });

    test('fromJson handles missing errors array', () {
      final json = {
        'success': true,
        'deleted': 5,
        'failed': 0,
      };

      final result = BulkDeleteResult.fromJson(json);
      expect(result.successCount, 5);
      expect(result.errorCount, 0);
      expect(result.errors.length, 0);
    });

    test('toJson serializes correctly', () {
      final result = BulkDeleteResult(
        successCount: 5,
        errorCount: 2,
        errors: [
          BulkDeleteError(id: 'uuid1', error: 'Not found'),
          BulkDeleteError(id: 'uuid2', error: 'Permission denied'),
        ],
        message: 'Some items failed',
      );

      final json = result.toJson();
      expect(json['successCount'], 5);
      expect(json['errorCount'], 2);
      expect(json['errors'].length, 2);
      expect(json['message'], 'Some items failed');
    });

    test('toJson omits message when null', () {
      final result = BulkDeleteResult(
        successCount: 5,
        errorCount: 0,
        errors: [],
      );

      final json = result.toJson();
      expect(json['successCount'], 5);
      expect(json['errorCount'], 0);
      expect(json['message'], null);
    });
  });

  group('BulkDeleteError', () {
    test('fromJson creates error with id and error', () {
      final json = {'id': 'test-id', 'error': 'Not found'};
      final error = BulkDeleteError.fromJson(json);
      expect(error.id, 'test-id');
      expect(error.error, 'Not found');
      expect(error.itemName, null);
    });

    test('fromJson includes item name when present', () {
      final json = {
        'id': 'test-id',
        'error': 'Not found',
        'item_name': 'Test Visit',
      };
      final error = BulkDeleteError.fromJson(json);
      expect(error.itemName, 'Test Visit');
    });

    test('fromJson handles missing error field', () {
      final json = {'id': 'test-id'};
      final error = BulkDeleteError.fromJson(json);
      expect(error.id, 'test-id');
      expect(error.error, 'Unknown error');
    });

    test('toJson serializes all fields', () {
      final error = BulkDeleteError(
        id: 'test-id',
        error: 'Not found',
        itemName: 'Test Visit',
      );
      final json = error.toJson();
      expect(json['id'], 'test-id');
      expect(json['error'], 'Not found');
      expect(json['item_name'], 'Test Visit');
    });

    test('toJson omits item_name when null', () {
      final error = BulkDeleteError(
        id: 'test-id',
        error: 'Not found',
      );
      final json = error.toJson();
      expect(json['id'], 'test-id');
      expect(json['error'], 'Not found');
      expect(json['item_name'], null);
    });
  });

  group('BulkDeleteStatus', () {
    test('has correct enum values', () {
      expect(BulkDeleteStatus.deleting, isA<BulkDeleteStatus>());
      expect(BulkDeleteStatus.completed, isA<BulkDeleteStatus>());
      expect(BulkDeleteStatus.partialFailure, isA<BulkDeleteStatus>());
      expect(BulkDeleteStatus.error, isA<BulkDeleteStatus>());
    });
  });
}
