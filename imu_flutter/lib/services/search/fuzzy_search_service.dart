import 'package:imu_flutter/features/clients/data/models/client_model.dart';

/// Search service for offline client name matching.
/// Each word in the query must appear as a substring in at least one name
/// field (firstName, lastName, middleName). All words must match (AND logic),
/// but they can match different fields (e.g. "maria cruz" hits firstName
/// and lastName independently).
class FuzzySearchService {
  final List<Client> _clients;

  FuzzySearchService(this._clients);

  List<Client> searchByName(String query) {
    if (query.trim().isEmpty) return _clients;

    final terms = query
        .toLowerCase()
        .replaceAll(',', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .split(' ')
        .where((t) => t.isNotEmpty)
        .toList();

    return _clients.where((client) => _allTermsMatch(client, terms)).toList();
  }

  bool _allTermsMatch(Client client, List<String> terms) {
    final fields = [
      client.firstName.toLowerCase(),
      client.lastName.toLowerCase(),
      if (client.middleName != null && client.middleName!.isNotEmpty)
        client.middleName!.toLowerCase(),
    ];
    // Every search term must match at least one name field
    return terms.every((term) => fields.any((f) => f.contains(term)));
  }
}
