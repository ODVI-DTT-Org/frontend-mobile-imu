import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/touchpoint_filter.dart';
import '../../services/filter_preferences_service.dart';

final touchpointFilterProvider =
    StateNotifierProvider<TouchpointFilterNotifier, TouchpointFilter>((ref) {
  return TouchpointFilterNotifier();
});

class TouchpointFilterNotifier extends StateNotifier<TouchpointFilter> {
  final FilterPreferencesService _prefs = FilterPreferencesService();

  TouchpointFilterNotifier() : super(const TouchpointFilter()) {
    _loadFromPreferences();
  }

  Future<void> _loadFromPreferences() async {
    final numbers = _prefs.getTouchpointNumbers();
    if (numbers.isNotEmpty) {
      state = TouchpointFilter(selectedNumbers: Set<int>.from(numbers));
    }
  }

  void toggle(int n) {
    state = state.toggle(n);
    _prefs.setTouchpointNumbers(state.toList());
  }

  void clear() {
    state = const TouchpointFilter();
    _prefs.setTouchpointNumbers([]);
  }
}
