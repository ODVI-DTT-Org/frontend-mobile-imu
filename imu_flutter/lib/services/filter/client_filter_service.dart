// lib/services/filter/client_filter_service.dart
import '../../features/clients/data/models/client_model.dart';
import '../../shared/models/location_filter.dart';
import '../../shared/models/client_attribute_filter.dart';

class ClientFilterService {
  /// Filter clients using AND logic for all filter types
  /// Combines search query + location filter + attribute filter
  List<Client> filterClients({
    required List<Client> clients,
    required String searchQuery,
    required LocationFilter locationFilter,
    required ClientAttributeFilter attributeFilter,
  }) {
    return clients.where((client) {
      // Search query match
      final matchesSearch = searchQuery.isEmpty ||
          client.fullName.toLowerCase().contains(searchQuery.toLowerCase());

      // Location filter match
      final matchesLocation = !locationFilter.hasFilter ||
          _matchesLocation(client, locationFilter);

      // Attribute filter match (AND logic)
      final matchesAttributes = !attributeFilter.hasFilter ||
          attributeFilter.matches(client);

      // ALL conditions must be true (AND logic)
      return matchesSearch && matchesLocation && matchesAttributes;
    }).toList();
  }

  bool _matchesLocation(Client client, LocationFilter filter) {
    if (!filter.matchesClientAddress(
      fullAddress: client.tableFullAddress,
      region: client.region,
      province: client.province,
      municipality: client.municipality,
      barangay: client.barangay,
      addressBarangay: client.addresses.isNotEmpty ? client.addresses.first.barangay : null,
      addressCity: client.addresses.isNotEmpty ? client.addresses.first.municipality : null,
      addressProvince: client.addresses.isNotEmpty ? client.addresses.first.province : null,
    )) {
      return false;
    }

    if (filter.province == null) {
      return filter.barangays == null || filter.barangays!.isEmpty
          ? true
          : _containsIgnoreCase(filter.barangays!, client.barangay);
    }

    // Province must match
    if (!_equalsIgnoreCase(client.province, filter.province)) return false;

    // If municipalities specified, client must be in one of them
    if (filter.municipalities != null && filter.municipalities!.isNotEmpty) {
      if (!_containsIgnoreCase(filter.municipalities!, client.municipality)) return false;
    }

    if (filter.barangays != null && filter.barangays!.isNotEmpty) {
      return _containsIgnoreCase(filter.barangays!, client.barangay);
    }

    return true;
  }

  bool _equalsIgnoreCase(String? a, String? b) {
    if (a == null || b == null) return false;
    return a.toUpperCase() == b.toUpperCase();
  }

  bool _containsIgnoreCase(List<String> values, String? candidate) {
    if (candidate == null) return false;
    final upper = candidate.toUpperCase();
    return values.any((value) => value.toUpperCase() == upper);
  }
}
