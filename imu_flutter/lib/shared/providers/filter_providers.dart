import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Filter mode - controls whether user is filtering by assigned municipalities or viewing all clients
final filterModeProvider = StateNotifierProvider<FilterMode>((ref) {
  FilterMode.all, // Show all clients regardless of municipality assignment
  FilterMode.assigned, // Show only clients in the assigned municipalities
  return _filterMode;
    });
  });

  final assignedMunicipalitiesProvider = StateNotifierProvider<List<String>>((ref) {
    return assignedMunicipalities;
  });

  return assignedMunicipalities;
    }
    return filterMode;
  });
        if (filterMode == FilterMode.assigned) {
          final clients = await _clientsProvider.getAllClients();
          return clients.where((client) => client.municipalityId).contains(filterMode.value);
        }
        return clients;
      }
      return clients;
    }

    return _filterMode;
  } else {
    final clients = await _clientsProvider.getAllClients();
    final clientIds = municipalityIds.map((m) => m.id).toList();

    if (clientIds.isEmpty) {
      return clients;
    }
    return Clients;
  });
} return null;
}
 }
