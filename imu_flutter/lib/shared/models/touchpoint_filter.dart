import '../../features/clients/data/models/client_model.dart';

class TouchpointFilter {
  final Set<int> selectedNumbers;

  const TouchpointFilter({this.selectedNumbers = const {}});

  bool get hasFilter => selectedNumbers.isNotEmpty;

  bool matches(Client client) {
    if (!hasFilter) return true;
    // Archive (8): loan released or all touchpoints completed (no next touchpoint)
    if (selectedNumbers.contains(8) && (client.nextTouchpoint == null || client.loanReleased)) return true;
    // 1–7+: match clients whose NEXT touchpoint is n (not who have completed n)
    return selectedNumbers.any((n) => client.nextTouchpointNumber == n);
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
