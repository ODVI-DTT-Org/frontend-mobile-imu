import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/features/clients/data/providers/client_favorites_provider.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/services/local_storage/hive_service.dart';
import 'package:imu_flutter/shared/providers/app_providers.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';
import 'package:imu_flutter/services/auth/jwt_auth_service.dart';

// Basic unit tests for client favorites changes.
// Full integration tests require a real PowerSync + Hive environment.

void main() {
  group('FavoritesResult', () {
    test('creates with clients and unresolved count', () {
      final result = FavoritesResult(clients: [], unresolvedCount: 0);
      expect(result.clients, isEmpty);
      expect(result.unresolvedCount, equals(0));
    });

    test('stores clients list correctly', () {
      final client = Client(
        id: 'test-id',
        firstName: 'Juan',
        lastName: 'dela Cruz',
      );
      final result = FavoritesResult(clients: [client], unresolvedCount: 0);
      expect(result.clients.length, equals(1));
      expect(result.unresolvedCount, equals(0));
    });
  });

  group('FavoritesState', () {
    test('defaults to empty ids and not syncing', () {
      final state = FavoritesState.empty;
      expect(state.ids, isEmpty);
      expect(state.isInitialSyncing, isFalse);
    });

    test('copyWith preserves unchanged fields', () {
      final state = FavoritesState(ids: {'a', 'b'}, isInitialSyncing: true);
      final next = state.copyWith(isInitialSyncing: false);
      expect(next.ids, equals({'a', 'b'}));
      expect(next.isInitialSyncing, isFalse);
    });

    test('copyWith updates specified fields', () {
      final state = FavoritesState(ids: {'a'}, isInitialSyncing: false);
      final next = state.copyWith(ids: {'a', 'b'});
      expect(next.ids, equals({'a', 'b'}));
      expect(next.isInitialSyncing, isFalse);
    });
  });
}
