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
    if (filter.province == null) return true;

    // Province must match
    if (client.province != filter.province) return false;

    // If municipalities specified, client must be in one of them
    if (filter.municipalities != null && filter.municipalities!.isNotEmpty) {
      return filter.municipalities!.contains(client.municipality);
    }

    return true;
  }
}
