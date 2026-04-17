import '../../features/clients/data/models/client_model.dart';

class TouchpointFilter {
  final Set<int> selectedNumbers;

  const TouchpointFilter({this.selectedNumbers = const {}});

  bool get hasFilter => selectedNumbers.isNotEmpty;

  bool matches(Client client) {
    if (!hasFilter) return true;
    if (selectedNumbers.contains(8) && client.touchpointNumber > 7) return true;
    return selectedNumbers.any((n) => n <= 7 && client.touchpointNumber == n);
  }

  TouchpointFilter toggle(int n) {
    final updated = Set<int>.from(selectedNumbers);
    if (updated.contains(n)) {
      updated.remove(n);
    } else {
      updated.add(n);
    }
    return TouchpointFilter(selectedNumbers: updated);
  }

  TouchpointFilter clear() => const TouchpointFilter();

  List<int> toList() => selectedNumbers.toList()..sort();
}
