# Touchpoint Filter Chips Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a horizontally scrollable row of touchpoint filter chips (1st–7th + Archive) below the search bar on the Clients page and Client Selector modal, supporting multi-select with session persistence.

**Architecture:** New standalone `TouchpointFilter` model + `touchpointFilterProvider` following the existing `clientAttributeFilterProvider` pattern. Local filtering applied after existing filters in both `assignedClientsProvider` (full Hive cache) and `onlineClientsProvider` (loaded page results). Widget placed immediately below each search bar in both target files.

**Tech Stack:** Flutter, Dart, Riverpod 2 (StateNotifierProvider), SharedPreferences (via FilterPreferencesService), lucide_icons, flutter_test

---

## File Map

| Action | Path |
|--------|------|
| Modify | `lib/services/filter_preferences_service.dart` |
| Create | `lib/shared/models/touchpoint_filter.dart` |
| Create | `lib/shared/providers/touchpoint_filter_provider.dart` |
| Create | `lib/shared/widgets/filters/touchpoint_filter_chips.dart` |
| Modify | `lib/shared/providers/app_providers.dart` |
| Modify | `lib/features/clients/presentation/pages/clients_page.dart` |
| Modify | `lib/shared/widgets/client_selector_modal.dart` |
| Create | `test/unit/models/touchpoint_filter_test.dart` |

---

## Task 1: Persist touchpoint filter numbers in FilterPreferencesService

**Files:**
- Modify: `lib/services/filter_preferences_service.dart`

- [ ] **Step 1: Add key constant and two methods**

Open `lib/services/filter_preferences_service.dart`. After the `_keyProductType` constant line, add:

```dart
  // Touchpoint filter key
  static const String _keyTouchpointNumbers = 'filter_touchpoint_numbers';
```

After the `clearAttributeFilters()` method (before the `// BULK OPERATIONS` section ends), add these two methods:

```dart
  // ============================================
  // TOUCHPOINT FILTER
  // ============================================

  /// Touchpoint Numbers Filter (1–7 = touchpoint positions, 8 = archive)
  List<int> getTouchpointNumbers() {
    final jsonString = _prefs?.getString(_keyTouchpointNumbers);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.cast<int>();
    } catch (e) {
      return [];
    }
  }

  Future<void> setTouchpointNumbers(List<int> value) async {
    await init();
    if (value.isEmpty) {
      await _prefs?.remove(_keyTouchpointNumbers);
    } else {
      await _prefs?.setString(_keyTouchpointNumbers, json.encode(value));
    }
  }
```

In `clearAll()`, after the last `await _prefs?.remove(_keyProductType);` line, add:

```dart
    await _prefs?.remove(_keyTouchpointNumbers);
```

- [ ] **Step 2: Commit**

```bash
cd imu_flutter
git add lib/services/filter_preferences_service.dart
git commit -m "feat: add touchpoint numbers persistence to FilterPreferencesService"
```

---

## Task 2: Create TouchpointFilter model with tests

**Files:**
- Create: `lib/shared/models/touchpoint_filter.dart`
- Create: `test/unit/models/touchpoint_filter_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/unit/models/touchpoint_filter_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/shared/models/touchpoint_filter.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

Client _client({required int touchpointNumber}) => Client(
  id: '1',
  firstName: 'Test',
  lastName: 'Client',
  clientType: ClientType.potential,
  productType: ProductType.pnpPension,
  pensionType: PensionType.sss,
  createdAt: DateTime.now(),
  touchpointNumber: touchpointNumber,
);

void main() {
  group('TouchpointFilter', () {
    test('empty filter has no filter active', () {
      const filter = TouchpointFilter();
      expect(filter.hasFilter, false);
    });

    test('filter with selected numbers is active', () {
      const filter = TouchpointFilter(selectedNumbers: {1, 3});
      expect(filter.hasFilter, true);
    });

    test('matches returns true when no filter selected', () {
      const filter = TouchpointFilter();
      expect(filter.matches(_client(touchpointNumber: 1)), true);
      expect(filter.matches(_client(touchpointNumber: 5)), true);
    });

    test('matches returns true when client touchpoint is in selected set', () {
      const filter = TouchpointFilter(selectedNumbers: {2, 4});
      expect(filter.matches(_client(touchpointNumber: 2)), true);
      expect(filter.matches(_client(touchpointNumber: 4)), true);
    });

    test('matches returns false when client touchpoint is not in selected set', () {
      const filter = TouchpointFilter(selectedNumbers: {2, 4});
      expect(filter.matches(_client(touchpointNumber: 1)), false);
      expect(filter.matches(_client(touchpointNumber: 3)), false);
    });

    test('archive (8) matches clients with touchpointNumber > 7', () {
      const filter = TouchpointFilter(selectedNumbers: {8});
      expect(filter.matches(_client(touchpointNumber: 8)), true);
      expect(filter.matches(_client(touchpointNumber: 10)), true);
      expect(filter.matches(_client(touchpointNumber: 7)), false);
    });

    test('toggle adds number when absent', () {
      const filter = TouchpointFilter(selectedNumbers: {1});
      final updated = filter.toggle(3);
      expect(updated.selectedNumbers, {1, 3});
    });

    test('toggle removes number when present', () {
      const filter = TouchpointFilter(selectedNumbers: {1, 3});
      final updated = filter.toggle(1);
      expect(updated.selectedNumbers, {3});
    });

    test('clear returns filter with empty set', () {
      const filter = TouchpointFilter(selectedNumbers: {1, 2, 3});
      final cleared = filter.clear();
      expect(cleared.hasFilter, false);
      expect(cleared.selectedNumbers, isEmpty);
    });

    test('toList returns sorted list of selected numbers', () {
      const filter = TouchpointFilter(selectedNumbers: {5, 1, 3});
      expect(filter.toList(), [1, 3, 5]);
    });
  });
}
```

- [ ] **Step 2: Run to verify tests fail**

```bash
flutter test test/unit/models/touchpoint_filter_test.dart
```

Expected: FAIL — `touchpoint_filter.dart` not found.

- [ ] **Step 3: Create the model**

Create `lib/shared/models/touchpoint_filter.dart`:

```dart
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
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
flutter test test/unit/models/touchpoint_filter_test.dart
```

Expected: All 10 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/models/touchpoint_filter.dart test/unit/models/touchpoint_filter_test.dart
git commit -m "feat: add TouchpointFilter model with unit tests"
```

---

## Task 3: Create TouchpointFilterProvider

**Files:**
- Create: `lib/shared/providers/touchpoint_filter_provider.dart`

- [ ] **Step 1: Create the provider**

Create `lib/shared/providers/touchpoint_filter_provider.dart`:

```dart
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
```

- [ ] **Step 2: Commit**

```bash
git add lib/shared/providers/touchpoint_filter_provider.dart
git commit -m "feat: add touchpointFilterProvider with persistence"
```

---

## Task 4: Create TouchpointFilterChips widget

**Files:**
- Create: `lib/shared/widgets/filters/touchpoint_filter_chips.dart`

- [ ] **Step 1: Create the widget**

Create `lib/shared/widgets/filters/touchpoint_filter_chips.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/touchpoint_filter_provider.dart';
import '../../../core/utils/haptic_utils.dart';

class TouchpointFilterChips extends ConsumerWidget {
  const TouchpointFilterChips({super.key});

  static const _chips = [
    _ChipDef(n: 1, label: '1st', icon: LucideIcons.mapPin),
    _ChipDef(n: 2, label: '2nd', icon: LucideIcons.phone),
    _ChipDef(n: 3, label: '3rd', icon: LucideIcons.phone),
    _ChipDef(n: 4, label: '4th', icon: LucideIcons.mapPin),
    _ChipDef(n: 5, label: '5th', icon: LucideIcons.phone),
    _ChipDef(n: 6, label: '6th', icon: LucideIcons.phone),
    _ChipDef(n: 7, label: '7th', icon: LucideIcons.mapPin),
    _ChipDef(n: 8, label: 'Archive', icon: LucideIcons.archive),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(touchpointFilterProvider);

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final chip = _chips[index];
          final isActive = filter.selectedNumbers.contains(chip.n);
          return _TouchpointChip(
            chip: chip,
            isActive: isActive,
            onTap: () {
              HapticUtils.lightImpact();
              ref.read(touchpointFilterProvider.notifier).toggle(chip.n);
            },
          );
        },
      ),
    );
  }
}

class _ChipDef {
  final int n;
  final String label;
  final IconData icon;
  const _ChipDef({required this.n, required this.label, required this.icon});
}

class _TouchpointChip extends StatelessWidget {
  final _ChipDef chip;
  final bool isActive;
  final VoidCallback onTap;

  const _TouchpointChip({
    required this.chip,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0F172A) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF0F172A) : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              chip.icon,
              size: 12,
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              chip.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/shared/widgets/filters/touchpoint_filter_chips.dart
git commit -m "feat: add TouchpointFilterChips widget"
```

---

## Task 5: Wire touchpoint filter into app_providers.dart

**Files:**
- Modify: `lib/shared/providers/app_providers.dart`

- [ ] **Step 1: Add import**

In `lib/shared/providers/app_providers.dart`, after line 103 (`import 'client_attribute_filter_provider.dart' show clientAttributeFilterProvider;`), add:

```dart
import 'touchpoint_filter_provider.dart' show touchpointFilterProvider;
import '../models/touchpoint_filter.dart';
```

- [ ] **Step 2: Watch filter in onlineClientsProvider**

In `onlineClientsProvider` (around line 276), after the `final attributeFilter = ref.watch(clientAttributeFilterProvider);` line, add:

```dart
  final touchpointFilter = ref.watch(touchpointFilterProvider);
```

Before the existing `debugPrint(... Got ... clients from API ...)` and `return response;` lines (around line 323), insert:

```dart
    // Apply touchpoint filter locally on loaded results
    if (touchpointFilter.hasFilter) {
      final filteredItems = response.items
          .where((client) => touchpointFilter.matches(client))
          .toList();
      return ClientsResponse(
        items: filteredItems,
        page: response.page,
        perPage: response.perPage,
        totalItems: filteredItems.length,
        totalPages: response.totalPages,
      );
    }
```

Leave the existing `debugPrint` and `return response;` lines in place after the new block.

- [ ] **Step 3: Watch filter in assignedClientsProvider**

In `assignedClientsProvider` (around line 340), after the `final attributeFilter = ref.watch(clientAttributeFilterProvider);` line, add:

```dart
  final touchpointFilter = ref.watch(touchpointFilterProvider);
```

After the attribute filter block (around line 448, after `debugPrint('assignedClientsProvider: After attribute filter...')`), add:

```dart
  // Apply touchpoint filter locally
  if (touchpointFilter.hasFilter) {
    cachedClients = cachedClients
        .where((client) => touchpointFilter.matches(client))
        .toList();
    debugPrint('assignedClientsProvider: After touchpoint filter - ${cachedClients.length} clients');
  }
```

- [ ] **Step 4: Run tests to verify no regressions**

```bash
flutter test test/unit/providers/
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/providers/app_providers.dart
git commit -m "feat: apply touchpoint filter in assignedClientsProvider and onlineClientsProvider"
```

---

## Task 6: Add TouchpointFilterChips to clients_page.dart

**Files:**
- Modify: `lib/features/clients/presentation/pages/clients_page.dart`

- [ ] **Step 1: Add import**

At the top of `lib/features/clients/presentation/pages/clients_page.dart`, after the existing filter imports (near `attribute_filter_chip.dart`), add:

```dart
import '../../../../shared/widgets/filters/touchpoint_filter_chips.dart';
```

- [ ] **Step 2: Add widget below search bar in data state (line ~423)**

Find the search bar `Container` block ending around line 423 (the one after `// Search Bar` comment). It ends with `),` closing the `Container`. Immediately after that closing `),`, add:

```dart
                const SizedBox(height: 8),
                const TouchpointFilterChips(),
```

The section should look like:

```dart
                // Search Bar
                Container(
                  margin: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 17),
                  child: TextField(
                    // ... existing content ...
                  ),
                ),

                const SizedBox(height: 8),
                const TouchpointFilterChips(),

                // Active filter chips
                const LocationFilterChips(),
```

- [ ] **Step 3: Add widget below search bar in loading state (line ~647)**

Find the second search bar `Container` block (the one after `// Search Bar (always visible)` comment) ending around line 647. Immediately after its closing `),`, add:

```dart
              const SizedBox(height: 8),
              const TouchpointFilterChips(),
```

The section should look like:

```dart
              // Search Bar (always visible)
              Container(
                margin: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 17),
                child: TextField(
                  // ... existing content ...
                ),
              ),

              const SizedBox(height: 8),
              const TouchpointFilterChips(),

              const SizedBox(height: 12),
```

- [ ] **Step 4: Compile check**

```bash
flutter analyze lib/features/clients/presentation/pages/clients_page.dart
```

Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/clients/presentation/pages/clients_page.dart
git commit -m "feat: add TouchpointFilterChips below search bar in clients_page"
```

---

## Task 7: Add TouchpointFilterChips to client_selector_modal.dart

**Files:**
- Modify: `lib/shared/widgets/client_selector_modal.dart`

- [ ] **Step 1: Add import**

At the top of `lib/shared/widgets/client_selector_modal.dart`, after the existing filter widget imports, add:

```dart
import 'filters/touchpoint_filter_chips.dart';
```

- [ ] **Step 2: Add widget below search bar in data state (line ~857)**

Find the search bar `Container` block after `// Search bar` comment (around line 823). It ends with `),` closing the outer `Container`. Immediately after that closing `),`, add:

```dart
                  const SizedBox(height: 4),
                  const TouchpointFilterChips(),
```

The section should look like:

```dart
                  // Search bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: TextField(
                      // ... existing content ...
                    ),
                  ),

                  const SizedBox(height: 4),
                  const TouchpointFilterChips(),

                  // Active filter chips (using new widget)
                  ClientFilterChips(
```

- [ ] **Step 3: Add widget below search bar in loading state (line ~1104)**

Find the second search bar `Container` block (around line 1078, after the second `// Search bar` comment). Immediately after its closing `),`, add:

```dart
                  const SizedBox(height: 4),
                  const TouchpointFilterChips(),
```

The section should look like:

```dart
                  // Search bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: TextField(
                      // ... existing content ...
                    ),
                  ),

                  const SizedBox(height: 4),
                  const TouchpointFilterChips(),

                  // Filter toggle
                  if (widget.showAssignedFilter)
```

- [ ] **Step 4: Compile check**

```bash
flutter analyze lib/shared/widgets/client_selector_modal.dart
```

Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/client_selector_modal.dart
git commit -m "feat: add TouchpointFilterChips below search bar in client_selector_modal"
```

---

## Task 8: Full compile and test

- [ ] **Step 1: Run full test suite**

```bash
flutter test
```

Expected: All tests PASS.

- [ ] **Step 2: Run analyzer**

```bash
flutter analyze
```

Expected: No errors, no warnings on new files.

- [ ] **Step 3: Push to remote**

```bash
git push origin main
```
