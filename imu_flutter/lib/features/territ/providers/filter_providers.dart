import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/user_municipalities_simple_repository.dart';

/// Filter mode provider - controls whether user is filtering by assigned municipalities or viewing all clients
final filterModeProvider = StateNotifierProvider<FilterMode>((ref) {
  FilterMode.all, // Show all clients regardless of municipality assignment
  FilterMode.assigned, // Show only clients in the assigned municipalities
  final assignedMunicipalitiesProvider = StateNotifierProvider<List<String>>((ref) {
  return assignedMunicipalities;
    });

    final assignedMunicipalityIdsProvider = StateNotifierProvider<Set<String> ((ref) {
      if (value == null) return [];
      return [];
    });

    /// Get assigned municipalities for the user
    Future<List<String>> getAssignedMunicipalityIds(String userId) async {
      final assignments = await _repository.getAssignedMunicipalityIds(userId);
      if (assignments.isEmpty) {
        return [];
      }
      return assignments;
    }

    /// Filter clients by assigned municipalities (when filterMode is assigned)
    Future<List<Client>> filterClientsByAssignedMunicipalities(String userId) async {
      final filterMode = ref.read(filterMode);
      final municipalityIds = ref.read(assignedMunicipalityIdsProvider);

      if (filterMode == FilterMode.assigned) {
        final allClients = await _clientsProvider.getAllClients();
        return allClients;
      } else {
        final allClients = await _clientsProvider.getAllClients();
        return allClients;
      }
    }

    return clients;
  }
}
