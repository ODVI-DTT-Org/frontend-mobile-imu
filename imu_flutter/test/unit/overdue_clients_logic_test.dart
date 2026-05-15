import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/visits/data/models/missed_visit_model.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart'
    show Client, Touchpoint, TouchpointType, TouchpointReason, ClientType, ProductType, PensionType;

/// Pure function extracted from overdueClientsProvider for testability.
/// Given a list of clients, the set of client IDs already covered by missed
/// itineraries, and the set of client IDs with future scheduled itineraries,
/// returns the MissedVisit entries for overdue clients.
List<MissedVisit> computeOverdueClients({
  required List<Client> clients,
  required Set<String> missedItineraryClientIds,
  required Set<String> futureItineraryClientIds,
  DateTime? now,
}) {
  final effectiveNow = now ?? DateTime.now();
  final result = <MissedVisit>[];

  for (final client in clients) {
    if (client.id == null) continue;
    if (client.loanReleased) continue;
    if (client.nextTouchpoint == null) continue;
    if (missedItineraryClientIds.contains(client.id)) continue;
    if (futureItineraryClientIds.contains(client.id)) continue;

    DateTime lastActivity;
    if (client.touchpointSummary.isNotEmpty) {
      lastActivity = client.touchpointSummary
          .reduce((a, b) => a.date.isAfter(b.date) ? a : b)
          .date;
    } else {
      lastActivity = client.createdAt ?? effectiveNow;
    }

    if (effectiveNow.difference(lastActivity).inDays <= 7) continue;

    final nextTouchpointNum = client.touchpointNumber + 1;
    final touchpointTypeEnum = client.nextTouchpoint?.toLowerCase() == 'call'
        ? TouchpointType.call
        : TouchpointType.visit;

    result.add(MissedVisit(
      id: '${client.id}_$nextTouchpointNum',
      clientId: client.id!,
      clientName: client.fullName,
      touchpointNumber: nextTouchpointNum,
      touchpointType: touchpointTypeEnum,
      scheduledDate: lastActivity.add(const Duration(days: 7)),
      createdAt: effectiveNow,
      primaryPhone: client.phone,
      primaryAddress: client.fullAddress,
      source: MissedVisitSource.overdueClient,
    ));
  }

  return result;
}

/// Minimal Touchpoint factory for tests — all required fields supplied.
Touchpoint _tp({
  required String id,
  required String clientId,
  required DateTime date,
  int number = 1,
}) {
  return Touchpoint(
    id: id,
    clientId: clientId,
    touchpointNumber: number,
    type: TouchpointType.visit,
    reason: TouchpointReason.interested,
    date: date,
    createdAt: date,
  );
}

Client _makeClient({
  required String id,
  bool loanReleased = false,
  String? nextTouchpoint = 'Visit',
  List<Touchpoint> touchpointSummary = const [],
  DateTime? createdAt,
  int touchpointNumber = 0,
}) {
  return Client(
    id: id,
    firstName: 'Test',
    lastName: id,
    clientType: ClientType.potential,
    productType: ProductType.bfpActive,
    pensionType: PensionType.pnpRetireeOptional,
    loanReleased: loanReleased,
    nextTouchpoint: nextTouchpoint,
    touchpointSummary: touchpointSummary,
    createdAt: createdAt,
    touchpointNumber: touchpointNumber,
  );
}

void main() {
  final now = DateTime(2026, 5, 15);

  test('includes client overdue by 8 days with no touchpoints and old createdAt', () {
    final client = _makeClient(
      id: 'c1',
      createdAt: now.subtract(const Duration(days: 8)),
    );
    final result = computeOverdueClients(
      clients: [client],
      missedItineraryClientIds: {},
      futureItineraryClientIds: {},
      now: now,
    );
    expect(result.length, 1);
    expect(result.first.clientId, 'c1');
    expect(result.first.source, MissedVisitSource.overdueClient);
  });

  test('excludes client only 6 days since last touchpoint', () {
    final client = _makeClient(
      id: 'c2',
      touchpointSummary: [
        _tp(id: 't1', clientId: 'c2', date: now.subtract(const Duration(days: 6))),
      ],
    );
    final result = computeOverdueClients(
      clients: [client],
      missedItineraryClientIds: {},
      futureItineraryClientIds: {},
      now: now,
    );
    expect(result, isEmpty);
  });

  test('uses latest touchpoint date, not list order', () {
    final client = _makeClient(
      id: 'c3',
      touchpointSummary: [
        _tp(id: 't2', clientId: 'c3', date: now.subtract(const Duration(days: 20)), number: 1),
        _tp(id: 't3', clientId: 'c3', date: now.subtract(const Duration(days: 6)),  number: 2),
      ],
    );
    final result = computeOverdueClients(
      clients: [client],
      missedItineraryClientIds: {},
      futureItineraryClientIds: {},
      now: now,
    );
    expect(result, isEmpty); // latest was 6 days ago → not overdue
  });

  test('excludes loan-released clients', () {
    final client = _makeClient(
      id: 'c4',
      loanReleased: true,
      createdAt: now.subtract(const Duration(days: 20)),
    );
    final result = computeOverdueClients(
      clients: [client],
      missedItineraryClientIds: {},
      futureItineraryClientIds: {},
      now: now,
    );
    expect(result, isEmpty);
  });

  test('excludes clients with null nextTouchpoint (journey complete)', () {
    final client = _makeClient(
      id: 'c5',
      nextTouchpoint: null,
      createdAt: now.subtract(const Duration(days: 20)),
    );
    final result = computeOverdueClients(
      clients: [client],
      missedItineraryClientIds: {},
      futureItineraryClientIds: {},
      now: now,
    );
    expect(result, isEmpty);
  });

  test('excludes clients already covered by missed itinerary', () {
    final client = _makeClient(
      id: 'c6',
      createdAt: now.subtract(const Duration(days: 20)),
    );
    final result = computeOverdueClients(
      clients: [client],
      missedItineraryClientIds: {'c6'},
      futureItineraryClientIds: {},
      now: now,
    );
    expect(result, isEmpty);
  });

  test('excludes clients with a future scheduled itinerary', () {
    final client = _makeClient(
      id: 'c7',
      createdAt: now.subtract(const Duration(days: 20)),
    );
    final result = computeOverdueClients(
      clients: [client],
      missedItineraryClientIds: {},
      futureItineraryClientIds: {'c7'},
      now: now,
    );
    expect(result, isEmpty);
  });

  test('sets touchpointType to call when nextTouchpoint is call', () {
    final client = _makeClient(
      id: 'c8',
      nextTouchpoint: 'Call',
      createdAt: now.subtract(const Duration(days: 10)),
    );
    final result = computeOverdueClients(
      clients: [client],
      missedItineraryClientIds: {},
      futureItineraryClientIds: {},
      now: now,
    );
    expect(result.first.touchpointType, TouchpointType.call);
  });
}
