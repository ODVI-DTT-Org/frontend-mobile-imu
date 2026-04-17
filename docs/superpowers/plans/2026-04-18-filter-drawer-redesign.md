# Filter Drawer Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current filter bottom sheets on the Clients page and Client selector modal with a right-side filter drawer featuring location dropdowns (province → municipality cascade) and compact multi-select attribute chips.

**Architecture:** Multi-select `ClientAttributeFilter` model (lists instead of single values) feeds a `FilterDrawer` widget that slides in from the right. The drawer manages local draft state and only commits on Apply. An `ActiveFilterChipsRow` below the search bar shows active filters with inline removal. Backend `buildClientFilters` switches from `=` to `= ANY()` to support multi-value queries.

**Tech Stack:** Flutter/Dart, Riverpod 2.0, SharedPreferences, Hono + PostgreSQL (backend), lucide_icons, flutter_test

---

## File Map

### Backend (backend-imu)
| File | Change |
|------|--------|
| `src/routes/clients.ts` | `buildClientFilters` — change `=` to `= ANY()` for client_type, product_type, market_type, pension_type |

### Flutter — Models & Services
| File | Change |
|------|--------|
| `lib/shared/models/client_attribute_filter.dart` | Rewrite: fields become `List<T>?`, update `toQueryParams`, `matches`, `activeFilterCount`, `copyWith`, equality |
| `lib/services/filter_preferences_service.dart` | Add list-based getters/setters for attribute types; keep location methods unchanged |
| `test/unit/models/client_attribute_filter_test.dart` | Rewrite for multi-select semantics |

### Flutter — Providers
| File | Change |
|------|--------|
| `lib/shared/providers/client_attribute_filter_provider.dart` | Rewrite notifier: `updateFilter`, `toggleClientType`, `toggleMarketType`, `togglePensionType`, `toggleProductType`, `clear`; update `_loadFromPreferences` and `_persistFilter` |

### Flutter — New Widgets
| File | Purpose |
|------|---------|
| `lib/shared/widgets/filters/searchable_picker_sheet.dart` | Reusable searchable list bottom sheet for provinces and municipalities |
| `lib/shared/widgets/filters/location_dropdown_section.dart` | Province + municipality stacked dropdowns using searchable picker |
| `lib/shared/widgets/filters/attribute_chips_section.dart` | Compact multi-select filter chips grouped by category |
| `lib/shared/widgets/filters/active_filter_chips_row.dart` | Horizontal scrollable row of active filter chips with inline removal |
| `lib/shared/widgets/filters/filter_drawer.dart` | Main right-side drawer combining location + attribute sections + footer |

### Flutter — Modified Pages
| File | Change |
|------|--------|
| `lib/features/clients/presentation/pages/clients_page.dart` | Replace two filter icon buttons + two bottom sheets with `FilterDrawer` + `ActiveFilterChipsRow` |
| `lib/shared/widgets/client_selector_modal.dart` | Same replacement; fix `showAllPsgcAreas` to pass `!showAssignedFilter` |
| `lib/shared/widgets/unified_client_selector_bottom_sheet.dart` | Fix `showAllPsgcAreas: true` when not in assigned mode |

### Flutter — Deleted
| File | Reason |
|------|--------|
| `lib/shared/widgets/location_filter_bottom_sheet.dart` | Replaced by location_dropdown_section + searchable_picker_sheet |
| `lib/shared/widgets/client_attribute_filter_bottom_sheet.dart` | Replaced by attribute_chips_section in filter_drawer |
| `lib/shared/widgets/filters/client_attribute_filter_bottom_sheet_dropdown.dart` | Superseded |

---

## Task 1: Backend — Multi-value filter support

**Files:**
- Modify: `backend-imu/src/routes/clients.ts` (function `buildClientFilters`, lines ~30–100)

- [ ] **Step 1: Write the failing test**

In `backend-imu`, there's no unit test file for `buildClientFilters`. Test manually via curl after the change. First, confirm current behaviour rejects multi-value:

```bash
cd /home/claude-team/loi/imu2/backend-imu
curl -s "http://localhost:3000/api/clients?client_type=POTENTIAL,EXISTING&limit=1" | jq '.total // .error'
```
Expected: returns 0 results or error (single-value exact match fails on comma-separated input).

- [ ] **Step 2: Update `buildClientFilters` in `src/routes/clients.ts`**

Replace the four attribute filter conditions inside `buildClientFilters`. Change from exact match to `= ANY()`:

```typescript
// BEFORE (client_type example — same pattern for product_type, market_type, pension_type):
if (q.client_type && q.client_type !== 'all') {
  conditions.push(`c.client_type = $${idx}`);
  params.push(q.client_type);
  idx++;
}

// AFTER — replace ALL FOUR blocks (client_type, product_type, market_type, pension_type):
if (q.client_type && q.client_type !== 'all') {
  const values = q.client_type.split(',').map((v: string) => v.trim()).filter(Boolean);
  conditions.push(`c.client_type = ANY($${idx}::text[])`);
  params.push(values);
  idx++;
}

if (q.product_type && q.product_type !== 'all') {
  const values = q.product_type.split(',').map((v: string) => v.trim()).filter(Boolean);
  conditions.push(`c.product_type = ANY($${idx}::text[])`);
  params.push(values);
  idx++;
}

if (q.market_type && q.market_type !== 'all') {
  const values = q.market_type.split(',').map((v: string) => v.trim()).filter(Boolean);
  conditions.push(`c.market_type = ANY($${idx}::text[])`);
  params.push(values);
  idx++;
}

if (q.pension_type && q.pension_type !== 'all') {
  const values = q.pension_type.split(',').map((v: string) => v.trim()).filter(Boolean);
  conditions.push(`c.pension_type = ANY($${idx}::text[])`);
  params.push(values);
  idx++;
}
```

- [ ] **Step 3: Verify single-value still works**

```bash
curl -s "http://localhost:3000/api/clients?client_type=POTENTIAL&limit=5" | jq '.total'
```
Expected: a non-zero number (same as before the change).

- [ ] **Step 4: Verify multi-value now works**

```bash
curl -s "http://localhost:3000/api/clients?client_type=POTENTIAL,EXISTING&limit=5" | jq '.total'
```
Expected: total >= the single-value result (returns union of both types).

- [ ] **Step 5: Commit**

```bash
cd /home/claude-team/loi/imu2/backend-imu
git add src/routes/clients.ts
git commit -m "feat: support multi-value filter params using ANY() in buildClientFilters"
```

---

## Task 2: Rewrite ClientAttributeFilter model

**Files:**
- Modify: `lib/shared/models/client_attribute_filter.dart`
- Modify: `test/unit/models/client_attribute_filter_test.dart`

- [ ] **Step 1: Write failing tests**

Replace the entire content of `test/unit/models/client_attribute_filter_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/shared/models/client_attribute_filter.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

void main() {
  group('ClientAttributeFilter', () {
    test('none() returns filter with no values set', () {
      final filter = ClientAttributeFilter.none();
      expect(filter.clientTypes, isNull);
      expect(filter.marketTypes, isNull);
      expect(filter.pensionTypes, isNull);
      expect(filter.productTypes, isNull);
    });

    test('hasFilter returns false when no filters set', () {
      expect(ClientAttributeFilter.none().hasFilter, false);
    });

    test('hasFilter returns true when any filter list is non-empty', () {
      final filter = ClientAttributeFilter(clientTypes: [ClientType.potential]);
      expect(filter.hasFilter, true);
    });

    test('activeFilterCount sums total selected values across all categories', () {
      final filter = ClientAttributeFilter(
        clientTypes: [ClientType.potential, ClientType.existing],
        pensionTypes: [PensionType.sss],
      );
      expect(filter.activeFilterCount, 3);
    });

    test('matches returns true when no filters set', () {
      final filter = ClientAttributeFilter.none();
      final client = _makeClient(ClientType.potential, MarketType.residential, PensionType.sss, ProductType.pnpPension);
      expect(filter.matches(client), true);
    });

    test('matches returns true when client value is in list (OR within category)', () {
      final filter = ClientAttributeFilter(
        clientTypes: [ClientType.potential, ClientType.existing],
      );
      final client = _makeClient(ClientType.existing, MarketType.residential, PensionType.sss, ProductType.pnpPension);
      expect(filter.matches(client), true);
    });

    test('matches returns false when client value is NOT in list', () {
      final filter = ClientAttributeFilter(
        pensionTypes: [PensionType.sss, PensionType.gsis],
      );
      final client = _makeClient(ClientType.potential, MarketType.residential, PensionType.private, ProductType.pnpPension);
      expect(filter.matches(client), false);
    });

    test('matches uses AND across categories', () {
      final filter = ClientAttributeFilter(
        clientTypes: [ClientType.potential],
        marketTypes: [MarketType.residential],
      );
      // Correct client type, wrong market type
      final client = _makeClient(ClientType.potential, MarketType.commercial, PensionType.sss, ProductType.pnpPension);
      expect(filter.matches(client), false);
    });

    test('toQueryParams emits comma-separated uppercase values', () {
      final filter = ClientAttributeFilter(
        clientTypes: [ClientType.potential, ClientType.existing],
        marketTypes: [MarketType.residential],
        pensionTypes: [PensionType.sss, PensionType.gsis],
        productTypes: [ProductType.pnpPension, ProductType.bfpActive],
      );
      final params = filter.toQueryParams();
      expect(params['client_type'], 'POTENTIAL,EXISTING');
      expect(params['market_type'], 'RESIDENTIAL');
      expect(params['pension_type'], 'SSS,GSIS');
      expect(params['product_type'], 'PNP PENSION,BFP ACTIVE');
    });

    test('toQueryParams excludes empty lists', () {
      final filter = ClientAttributeFilter(clientTypes: [ClientType.potential]);
      final params = filter.toQueryParams();
      expect(params['client_type'], 'POTENTIAL');
      expect(params.containsKey('market_type'), false);
      expect(params.containsKey('pension_type'), false);
      expect(params.containsKey('product_type'), false);
    });

    test('toQueryParams returns empty map when no filters', () {
      expect(ClientAttributeFilter.none().toQueryParams(), isEmpty);
    });

    test('copyWith preserves unspecified fields', () {
      final filter = ClientAttributeFilter(clientTypes: [ClientType.potential]);
      final updated = filter.copyWith(pensionTypes: [PensionType.sss]);
      expect(updated.clientTypes, [ClientType.potential]);
      expect(updated.pensionTypes, [PensionType.sss]);
    });

    test('equality: two filters with same lists are equal', () {
      final a = ClientAttributeFilter(clientTypes: [ClientType.potential, ClientType.existing]);
      final b = ClientAttributeFilter(clientTypes: [ClientType.potential, ClientType.existing]);
      expect(a, equals(b));
    });
  });
}

Client _makeClient(ClientType ct, MarketType mt, PensionType pt, ProductType pdt) {
  return Client(
    id: '1',
    firstName: 'Test',
    lastName: 'User',
    clientType: ct,
    marketType: mt,
    pensionType: pt,
    productType: pdt,
    createdAt: DateTime.now(),
  );
}
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
cd /home/claude-team/loi/imu2/frontend-mobile-imu/imu_flutter
flutter test test/unit/models/client_attribute_filter_test.dart
```
Expected: multiple compile errors about `clientTypes` not existing.

- [ ] **Step 3: Rewrite the model**

Replace entire content of `lib/shared/models/client_attribute_filter.dart`:

```dart
import 'package:collection/collection.dart';
import '../../features/clients/data/models/client_model.dart';

class ClientAttributeFilter {
  final List<ClientType>? clientTypes;
  final List<MarketType>? marketTypes;
  final List<PensionType>? pensionTypes;
  final List<ProductType>? productTypes;

  const ClientAttributeFilter({
    this.clientTypes,
    this.marketTypes,
    this.pensionTypes,
    this.productTypes,
  });

  bool get hasFilter =>
      (clientTypes?.isNotEmpty ?? false) ||
      (marketTypes?.isNotEmpty ?? false) ||
      (pensionTypes?.isNotEmpty ?? false) ||
      (productTypes?.isNotEmpty ?? false);

  int get activeFilterCount {
    return (clientTypes?.length ?? 0) +
        (marketTypes?.length ?? 0) +
        (pensionTypes?.length ?? 0) +
        (productTypes?.length ?? 0);
  }

  static ClientAttributeFilter none() => const ClientAttributeFilter();

  /// OR within category, AND across categories
  bool matches(Client client) {
    if (clientTypes != null && clientTypes!.isNotEmpty) {
      if (!clientTypes!.contains(client.clientType)) return false;
    }
    if (marketTypes != null && marketTypes!.isNotEmpty) {
      if (!marketTypes!.contains(client.marketType)) return false;
    }
    if (pensionTypes != null && pensionTypes!.isNotEmpty) {
      if (!pensionTypes!.contains(client.pensionType)) return false;
    }
    if (productTypes != null && productTypes!.isNotEmpty) {
      if (!productTypes!.contains(client.productType)) return false;
    }
    return true;
  }

  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (clientTypes != null && clientTypes!.isNotEmpty) {
      params['client_type'] = clientTypes!.map((t) => t.name.toUpperCase()).join(',');
    }
    if (marketTypes != null && marketTypes!.isNotEmpty) {
      params['market_type'] = marketTypes!.map((t) => t.name.toUpperCase()).join(',');
    }
    if (pensionTypes != null && pensionTypes!.isNotEmpty) {
      params['pension_type'] = pensionTypes!.map((t) => t.name.toUpperCase()).join(',');
    }
    if (productTypes != null && productTypes!.isNotEmpty) {
      params['product_type'] = productTypes!.map((t) => _productTypeApiValue(t)).join(',');
    }
    return params;
  }

  String _productTypeApiValue(ProductType type) {
    switch (type) {
      case ProductType.bfpActive: return 'BFP ACTIVE';
      case ProductType.bfpPension: return 'BFP PENSION';
      case ProductType.pnpPension: return 'PNP PENSION';
      case ProductType.napolcom: return 'NAPOLCOM';
      case ProductType.bfpStp: return 'BFP STP';
    }
  }

  ClientAttributeFilter copyWith({
    List<ClientType>? clientTypes,
    List<MarketType>? marketTypes,
    List<PensionType>? pensionTypes,
    List<ProductType>? productTypes,
  }) {
    return ClientAttributeFilter(
      clientTypes: clientTypes ?? this.clientTypes,
      marketTypes: marketTypes ?? this.marketTypes,
      pensionTypes: pensionTypes ?? this.pensionTypes,
      productTypes: productTypes ?? this.productTypes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    const listEq = ListEquality();
    return other is ClientAttributeFilter &&
        listEq.equals(other.clientTypes, clientTypes) &&
        listEq.equals(other.marketTypes, marketTypes) &&
        listEq.equals(other.pensionTypes, pensionTypes) &&
        listEq.equals(other.productTypes, productTypes);
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(clientTypes ?? []),
        Object.hashAll(marketTypes ?? []),
        Object.hashAll(pensionTypes ?? []),
        Object.hashAll(productTypes ?? []),
      );

  @override
  String toString() =>
      'ClientAttributeFilter(clientTypes: $clientTypes, marketTypes: $marketTypes, '
      'pensionTypes: $pensionTypes, productTypes: $productTypes)';
}
```

> Note: `collection` package is already in `pubspec.yaml` (used elsewhere). If not, run `flutter pub add collection`.

- [ ] **Step 4: Run tests**

```bash
flutter test test/unit/models/client_attribute_filter_test.dart
```
Expected: all tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/models/client_attribute_filter.dart test/unit/models/client_attribute_filter_test.dart
git commit -m "feat: rewrite ClientAttributeFilter for multi-select list support"
```

---

## Task 3: Update FilterPreferencesService for list storage

**Files:**
- Modify: `lib/services/filter_preferences_service.dart`

- [ ] **Step 1: Write failing test**

Create `test/unit/services/filter_preferences_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:imu_flutter/services/filter_preferences_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FilterPreferencesService — attribute lists', () {
    test('getClientTypes returns empty list by default', () async {
      final svc = FilterPreferencesService();
      expect(await svc.getClientTypes(), isEmpty);
    });

    test('setClientTypes and getClientTypes round-trips a list', () async {
      final svc = FilterPreferencesService();
      await svc.setClientTypes(['potential', 'existing']);
      expect(await svc.getClientTypes(), ['potential', 'existing']);
    });

    test('setClientTypes with empty list clears the key', () async {
      final svc = FilterPreferencesService();
      await svc.setClientTypes(['potential']);
      await svc.setClientTypes([]);
      expect(await svc.getClientTypes(), isEmpty);
    });

    test('clearAttributeFilters clears all attribute list keys', () async {
      final svc = FilterPreferencesService();
      await svc.setClientTypes(['potential']);
      await svc.setMarketTypes(['residential']);
      await svc.clearAttributeFilters();
      expect(await svc.getClientTypes(), isEmpty);
      expect(await svc.getMarketTypes(), isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
flutter test test/unit/services/filter_preferences_service_test.dart
```
Expected: compile errors — `getClientTypes` / `setClientTypes` do not exist.

- [ ] **Step 3: Add list methods to FilterPreferencesService**

In `lib/services/filter_preferences_service.dart`, replace the four single-string attribute getter/setter pairs with list-based equivalents. Keep the existing location filter methods unchanged. Replace the `_keyClientType`, `_keyMarketType`, `_keyPensionType`, `_keyProductType` keys and their methods:

```dart
// Replace these four sections in the CLIENT ATTRIBUTE FILTERS region:

/// Client Types Filter (multi-select)
Future<List<String>> getClientTypes() async {
  await init();
  final json = _prefs?.getString(_keyClientType);
  if (json == null || json.isEmpty) return [];
  try {
    return (jsonDecode(json) as List).cast<String>();
  } catch (_) {
    return [];
  }
}

Future<void> setClientTypes(List<String> values) async {
  await init();
  if (values.isEmpty) {
    await _prefs?.remove(_keyClientType);
  } else {
    await _prefs?.setString(_keyClientType, jsonEncode(values));
  }
}

/// Market Types Filter (multi-select)
Future<List<String>> getMarketTypes() async {
  await init();
  final json = _prefs?.getString(_keyMarketType);
  if (json == null || json.isEmpty) return [];
  try {
    return (jsonDecode(json) as List).cast<String>();
  } catch (_) {
    return [];
  }
}

Future<void> setMarketTypes(List<String> values) async {
  await init();
  if (values.isEmpty) {
    await _prefs?.remove(_keyMarketType);
  } else {
    await _prefs?.setString(_keyMarketType, jsonEncode(values));
  }
}

/// Pension Types Filter (multi-select)
Future<List<String>> getPensionTypes() async {
  await init();
  final json = _prefs?.getString(_keyPensionType);
  if (json == null || json.isEmpty) return [];
  try {
    return (jsonDecode(json) as List).cast<String>();
  } catch (_) {
    return [];
  }
}

Future<void> setPensionTypes(List<String> values) async {
  await init();
  if (values.isEmpty) {
    await _prefs?.remove(_keyPensionType);
  } else {
    await _prefs?.setString(_keyPensionType, jsonEncode(values));
  }
}

/// Product Types Filter (multi-select)
Future<List<String>> getProductTypes() async {
  await init();
  final json = _prefs?.getString(_keyProductType);
  if (json == null || json.isEmpty) return [];
  try {
    return (jsonDecode(json) as List).cast<String>();
  } catch (_) {
    return [];
  }
}

Future<void> setProductTypes(List<String> values) async {
  await init();
  if (values.isEmpty) {
    await _prefs?.remove(_keyProductType);
  } else {
    await _prefs?.setString(_keyProductType, jsonEncode(values));
  }
}
```

Also remove the old single-string methods (`getClientType`, `setClientType`, `getMarketType`, etc.) — they are no longer used.

- [ ] **Step 4: Run tests**

```bash
flutter test test/unit/services/filter_preferences_service_test.dart
```
Expected: all PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/services/filter_preferences_service.dart test/unit/services/filter_preferences_service_test.dart
git commit -m "feat: update FilterPreferencesService to store attribute filter lists as JSON"
```

---

## Task 4: Rewrite clientAttributeFilterProvider

**Files:**
- Modify: `lib/shared/providers/client_attribute_filter_provider.dart`

- [ ] **Step 1: Rewrite the provider**

Replace entire content of `lib/shared/providers/client_attribute_filter_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client_attribute_filter.dart';
import '../models/location_filter.dart';
import '../../features/clients/data/models/client_model.dart';
import '../../services/filter_preferences_service.dart';
import 'location_filter_providers.dart' show locationFilterProvider;

final clientAttributeFilterProvider =
    StateNotifierProvider<ClientAttributeFilterNotifier, ClientAttributeFilter>((ref) {
  return ClientAttributeFilterNotifier();
});

class ClientAttributeFilterNotifier extends StateNotifier<ClientAttributeFilter> {
  final FilterPreferencesService _prefs = FilterPreferencesService();

  ClientAttributeFilterNotifier() : super(ClientAttributeFilter.none()) {
    _loadFromPreferences();
  }

  Future<void> _loadFromPreferences() async {
    final clientTypeStrs = await _prefs.getClientTypes();
    final marketTypeStrs = await _prefs.getMarketTypes();
    final pensionTypeStrs = await _prefs.getPensionTypes();
    final productTypeStrs = await _prefs.getProductTypes();

    List<T> parseEnums<T extends Enum>(List<String> strs, List<T> values) =>
        strs
            .map((s) {
              try {
                return values.firstWhere((e) => e.name.toLowerCase() == s.toLowerCase());
              } catch (_) {
                return null;
              }
            })
            .whereType<T>()
            .toList();

    final clientTypes = parseEnums(clientTypeStrs, ClientType.values);
    final marketTypes = parseEnums(marketTypeStrs, MarketType.values);
    final pensionTypes = parseEnums(pensionTypeStrs, PensionType.values);
    final productTypes = parseEnums(productTypeStrs, ProductType.values);

    if (clientTypes.isNotEmpty || marketTypes.isNotEmpty ||
        pensionTypes.isNotEmpty || productTypes.isNotEmpty) {
      state = ClientAttributeFilter(
        clientTypes: clientTypes.isEmpty ? null : clientTypes,
        marketTypes: marketTypes.isEmpty ? null : marketTypes,
        pensionTypes: pensionTypes.isEmpty ? null : pensionTypes,
        productTypes: productTypes.isEmpty ? null : productTypes,
      );
    }
  }

  void updateFilter(ClientAttributeFilter newFilter) {
    state = newFilter;
    _persistFilter(newFilter);
  }

  void toggleClientType(ClientType type) {
    final current = List<ClientType>.from(state.clientTypes ?? []);
    current.contains(type) ? current.remove(type) : current.add(type);
    updateFilter(state.copyWith(clientTypes: current.isEmpty ? null : current));
  }

  void toggleMarketType(MarketType type) {
    final current = List<MarketType>.from(state.marketTypes ?? []);
    current.contains(type) ? current.remove(type) : current.add(type);
    updateFilter(state.copyWith(marketTypes: current.isEmpty ? null : current));
  }

  void togglePensionType(PensionType type) {
    final current = List<PensionType>.from(state.pensionTypes ?? []);
    current.contains(type) ? current.remove(type) : current.add(type);
    updateFilter(state.copyWith(pensionTypes: current.isEmpty ? null : current));
  }

  void toggleProductType(ProductType type) {
    final current = List<ProductType>.from(state.productTypes ?? []);
    current.contains(type) ? current.remove(type) : current.add(type);
    updateFilter(state.copyWith(productTypes: current.isEmpty ? null : current));
  }

  void clear() {
    state = ClientAttributeFilter.none();
    _prefs.clearAttributeFilters();
  }

  void _persistFilter(ClientAttributeFilter filter) {
    _prefs.setClientTypes(filter.clientTypes?.map((t) => t.name).toList() ?? []);
    _prefs.setMarketTypes(filter.marketTypes?.map((t) => t.name).toList() ?? []);
    _prefs.setPensionTypes(filter.pensionTypes?.map((t) => t.name).toList() ?? []);
    _prefs.setProductTypes(filter.productTypes?.map((t) => t.name).toList() ?? []);
  }
}

final activeFilterCountProvider = Provider<int>((ref) {
  final locationFilter = ref.watch(locationFilterProvider);
  final attributeFilter = ref.watch(clientAttributeFilterProvider);

  int count = 0;
  if (locationFilter.province != null) {
    count += 1;
    if (locationFilter.municipalities != null && locationFilter.municipalities!.isNotEmpty) {
      count += locationFilter.municipalities!.length;
    }
  }
  count += attributeFilter.activeFilterCount;
  return count;
});
```

- [ ] **Step 2: Run all unit tests**

```bash
flutter test test/unit/
```
Expected: all PASS (compile errors will surface any call sites still using old single-value setters).

- [ ] **Step 3: Fix any call-site compile errors**

If any file still calls `setClientType(type)` (single value) or `state.clientType`, update those calls to `toggleClientType(type)` or `state.clientTypes`. Common locations to check:
- `lib/shared/widgets/client_attribute_filter_bottom_sheet.dart` (will be deleted in Task 11 — ignore)
- `lib/shared/widgets/filters/client_attribute_filter_bottom_sheet_dropdown.dart` (will be deleted — ignore)

- [ ] **Step 4: Commit**

```bash
git add lib/shared/providers/client_attribute_filter_provider.dart
git commit -m "feat: update clientAttributeFilterProvider for multi-select toggle methods"
```

---

## Task 5: SearchablePickerSheet widget

**Files:**
- Create: `lib/shared/widgets/filters/searchable_picker_sheet.dart`
- Create: `test/unit/widget/filters/searchable_picker_sheet_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/unit/widget/filters/searchable_picker_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/shared/widgets/filters/searchable_picker_sheet.dart';

void main() {
  group('SearchablePickerSheet', () {
    testWidgets('shows all items initially', (tester) async {
      final items = ['Cebu', 'Metro Manila', 'Davao'];
      String? selected;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SearchablePickerSheet(
            title: 'Province',
            items: items,
            selectedItems: const {},
            multiSelect: false,
            onConfirm: (s) => selected = s.isNotEmpty ? s.first : null,
          ),
        ),
      ));

      expect(find.text('Cebu'), findsOneWidget);
      expect(find.text('Metro Manila'), findsOneWidget);
      expect(find.text('Davao'), findsOneWidget);
    });

    testWidgets('filters items on search input', (tester) async {
      final items = ['Cebu', 'Metro Manila', 'Davao'];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SearchablePickerSheet(
            title: 'Province',
            items: items,
            selectedItems: const {},
            multiSelect: false,
            onConfirm: (_) {},
          ),
        ),
      ));

      await tester.enterText(find.byType(TextField), 'cebu');
      await tester.pump();

      expect(find.text('Cebu'), findsOneWidget);
      expect(find.text('Metro Manila'), findsNothing);
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
flutter test test/unit/widget/filters/searchable_picker_sheet_test.dart
```
Expected: compile error — file not found.

- [ ] **Step 3: Create the widget**

Create `lib/shared/widgets/filters/searchable_picker_sheet.dart`:

```dart
import 'package:flutter/material.dart';

class SearchablePickerSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final Set<String> selectedItems;
  final bool multiSelect;
  final bool showAllOption;
  final void Function(Set<String> selected) onConfirm;

  const SearchablePickerSheet({
    super.key,
    required this.title,
    required this.items,
    required this.selectedItems,
    required this.multiSelect,
    required this.onConfirm,
    this.showAllOption = false,
  });

  static Future<Set<String>?> show({
    required BuildContext context,
    required String title,
    required List<String> items,
    required Set<String> selectedItems,
    required bool multiSelect,
    bool showAllOption = false,
  }) async {
    Set<String>? result;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => SearchablePickerSheet(
          title: title,
          items: items,
          selectedItems: selectedItems,
          multiSelect: multiSelect,
          showAllOption: showAllOption,
          onConfirm: (s) {
            result = s;
            Navigator.pop(ctx);
          },
        ),
      ),
    );
    return result;
  }

  @override
  State<SearchablePickerSheet> createState() => _SearchablePickerSheetState();
}

class _SearchablePickerSheetState extends State<SearchablePickerSheet> {
  late Set<String> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selectedItems);
  }

  List<String> get _filtered {
    if (_query.isEmpty) return widget.items;
    final q = _query.toLowerCase();
    return widget.items.where((item) => item.toLowerCase().contains(q)).toList();
  }

  void _toggle(String item) {
    setState(() {
      if (widget.multiSelect) {
        _selected.contains(item) ? _selected.remove(item) : _selected.add(item);
      } else {
        _selected = {item};
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(child: Text(widget.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            children: [
              if (widget.showAllOption)
                ListTile(
                  dense: true,
                  title: const Text('All', style: TextStyle(fontWeight: FontWeight.w500)),
                  leading: widget.multiSelect
                      ? Checkbox(value: _selected.isEmpty, onChanged: (_) => setState(() => _selected.clear()))
                      : Radio<bool>(value: true, groupValue: _selected.isEmpty, onChanged: (_) => setState(() => _selected.clear())),
                ),
              ..._filtered.map((item) => ListTile(
                dense: true,
                title: Text(item),
                leading: widget.multiSelect
                    ? Checkbox(value: _selected.contains(item), onChanged: (_) => _toggle(item))
                    : Radio<String>(value: item, groupValue: _selected.isEmpty ? null : _selected.first, onChanged: (_) => _toggle(item)),
                onTap: () => _toggle(item),
              )),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => widget.onConfirm(_selected),
                child: const Text('Confirm'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/unit/widget/filters/searchable_picker_sheet_test.dart
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/filters/searchable_picker_sheet.dart test/unit/widget/filters/searchable_picker_sheet_test.dart
git commit -m "feat: add SearchablePickerSheet reusable bottom sheet for province/municipality selection"
```

---

## Task 6: LocationDropdownSection widget

**Files:**
- Create: `lib/shared/widgets/filters/location_dropdown_section.dart`

- [ ] **Step 1: Create the widget**

Create `lib/shared/widgets/filters/location_dropdown_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/location_filter.dart';
import '../../../shared/providers/location_filter_providers.dart';
import '../../../features/psgc/data/repositories/psgc_repository.dart';
import 'searchable_picker_sheet.dart';

class LocationDropdownSection extends ConsumerWidget {
  final LocationFilter draftFilter;
  final bool showAllPsgc;
  final void Function(LocationFilter) onChanged;

  const LocationDropdownSection({
    super.key,
    required this.draftFilter,
    required this.showAllPsgc,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provincesAsync = showAllPsgc
        ? ref.watch(provincesProvider)
        : ref.watch(assignedAreasProvider).whenData((areas) =>
            areas.provinces.map((p) => PsgcProvince(name: p, code: p, region: '')).toList());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('Location', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
        ),
        provincesAsync.when(
          data: (provinces) => _ProvinceDropdown(
            provinces: provinces.map((p) => p.name).toList(),
            selected: draftFilter.province,
            onTap: (selected) async {
              final result = await SearchablePickerSheet.show(
                context: context,
                title: 'Province',
                items: provinces.map((p) => p.name).toList(),
                selectedItems: selected != null ? {selected} : {},
                multiSelect: false,
              );
              if (result != null) {
                final newProvince = result.isEmpty ? null : result.first;
                onChanged(LocationFilter(province: newProvince, municipalities: null));
              }
            },
          ),
          loading: () => const _DropdownButton(label: 'Loading...', enabled: false, onTap: null),
          error: (_, __) => const _DropdownButton(label: 'Failed to load', enabled: false, onTap: null),
        ),
        const SizedBox(height: 8),
        _MunicipalityDropdown(
          province: draftFilter.province,
          selectedMunicipalities: draftFilter.municipalities?.toSet() ?? {},
          ref: ref,
          onTap: draftFilter.province == null ? null : () async {
            final munsAsync = ref.read(municipalitiesByProvinceProvider(draftFilter.province!));
            final muns = munsAsync.value?.map((m) => m.name).toList() ?? [];
            final result = await SearchablePickerSheet.show(
              context: context,
              title: 'Municipality',
              items: muns,
              selectedItems: draftFilter.municipalities?.toSet() ?? {},
              multiSelect: true,
              showAllOption: true,
            );
            if (result != null) {
              onChanged(LocationFilter(
                province: draftFilter.province,
                municipalities: result.isEmpty ? null : result.toList(),
              ));
            }
          },
        ),
      ],
    );
  }
}

class _ProvinceDropdown extends StatelessWidget {
  final List<String> provinces;
  final String? selected;
  final void Function(String?) onTap;
  const _ProvinceDropdown({required this.provinces, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _DropdownButton(
      label: selected ?? 'Select Province',
      hint: selected == null,
      enabled: true,
      onTap: () => onTap(selected),
    );
  }
}

class _MunicipalityDropdown extends ConsumerWidget {
  final String? province;
  final Set<String> selectedMunicipalities;
  final WidgetRef ref;
  final VoidCallback? onTap;

  const _MunicipalityDropdown({
    required this.province,
    required this.selectedMunicipalities,
    required this.ref,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String label;
    if (province == null) {
      label = 'Select Municipality';
    } else if (selectedMunicipalities.isEmpty) {
      label = 'All Municipalities';
    } else if (selectedMunicipalities.length == 1) {
      label = selectedMunicipalities.first;
    } else {
      label = '${selectedMunicipalities.length} municipalities';
    }

    return _DropdownButton(
      label: label,
      hint: province == null || selectedMunicipalities.isEmpty,
      enabled: province != null,
      onTap: onTap,
    );
  }
}

class _DropdownButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool hint;
  final VoidCallback? onTap;

  const _DropdownButton({required this.label, required this.enabled, required this.onTap, this.hint = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: enabled ? theme.colorScheme.outline : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          color: enabled ? null : Colors.grey[100],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: hint || !enabled ? Colors.grey[500] : null,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down, size: 18, color: enabled ? null : Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
```

Also add import at the top of `location_dropdown_section.dart`:
```dart
import '../../../features/psgc/data/models/psgc_models.dart';
```

- [ ] **Step 2: Run flutter analyze**

```bash
flutter analyze lib/shared/widgets/filters/location_dropdown_section.dart
```
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/shared/widgets/filters/location_dropdown_section.dart
git commit -m "feat: add LocationDropdownSection with province/municipality cascade dropdowns"
```

---

## Task 7: AttributeChipsSection widget

**Files:**
- Create: `lib/shared/widgets/filters/attribute_chips_section.dart`

- [ ] **Step 1: Create the widget**

Create `lib/shared/widgets/filters/attribute_chips_section.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../features/clients/data/models/client_model.dart';
import '../../../shared/models/client_attribute_filter.dart';
import '../filters/client_attribute_filter_helpers.dart';

class AttributeChipsSection extends StatelessWidget {
  final ClientAttributeFilter draftFilter;
  final void Function(ClientAttributeFilter) onChanged;

  const AttributeChipsSection({
    super.key,
    required this.draftFilter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChipGroup<ClientType>(
          label: 'Client Type',
          values: ClientType.values,
          selected: draftFilter.clientTypes?.toSet() ?? {},
          labelOf: (t) => formatClientType(t),
          onToggle: (t) {
            final updated = _toggle(draftFilter.clientTypes, t);
            onChanged(draftFilter.copyWith(clientTypes: updated.isEmpty ? null : updated));
          },
        ),
        const SizedBox(height: 12),
        _ChipGroup<MarketType>(
          label: 'Market Type',
          values: MarketType.values,
          selected: draftFilter.marketTypes?.toSet() ?? {},
          labelOf: (t) => formatMarketType(t),
          onToggle: (t) {
            final updated = _toggle(draftFilter.marketTypes, t);
            onChanged(draftFilter.copyWith(marketTypes: updated.isEmpty ? null : updated));
          },
        ),
        const SizedBox(height: 12),
        _ChipGroup<PensionType>(
          label: 'Pension Type',
          values: PensionType.values,
          selected: draftFilter.pensionTypes?.toSet() ?? {},
          labelOf: (t) => formatPensionType(t),
          onToggle: (t) {
            final updated = _toggle(draftFilter.pensionTypes, t);
            onChanged(draftFilter.copyWith(pensionTypes: updated.isEmpty ? null : updated));
          },
        ),
        const SizedBox(height: 12),
        _ChipGroup<ProductType>(
          label: 'Product Type',
          values: ProductType.values,
          selected: draftFilter.productTypes?.toSet() ?? {},
          labelOf: (t) => formatProductType(t),
          onToggle: (t) {
            final updated = _toggle(draftFilter.productTypes, t);
            onChanged(draftFilter.copyWith(productTypes: updated.isEmpty ? null : updated));
          },
        ),
      ],
    );
  }

  List<T> _toggle<T>(List<T>? current, T value) {
    final list = List<T>.from(current ?? []);
    list.contains(value) ? list.remove(value) : list.add(value);
    return list;
  }
}

class _ChipGroup<T> extends StatelessWidget {
  final String label;
  final List<T> values;
  final Set<T> selected;
  final String Function(T) labelOf;
  final void Function(T) onToggle;

  const _ChipGroup({
    required this.label,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: values.map((value) {
            final isSelected = selected.contains(value);
            return FilterChip(
              label: Text(labelOf(value)),
              selected: isSelected,
              onSelected: (_) => onToggle(value),
              visualDensity: VisualDensity.compact,
              labelStyle: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : null,
              ),
              selectedColor: theme.colorScheme.primary,
              checkmarkColor: Colors.white,
              showCheckmark: false,
              side: BorderSide(
                color: isSelected ? theme.colorScheme.primary : Colors.grey[350]!,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            );
          }).toList(),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Run flutter analyze**

```bash
flutter analyze lib/shared/widgets/filters/attribute_chips_section.dart
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/shared/widgets/filters/attribute_chips_section.dart
git commit -m "feat: add AttributeChipsSection with compact multi-select filter chips"
```

---

## Task 8: ActiveFilterChipsRow widget

**Files:**
- Create: `lib/shared/widgets/filters/active_filter_chips_row.dart`

- [ ] **Step 1: Create the widget**

Create `lib/shared/widgets/filters/active_filter_chips_row.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/clients/data/models/client_model.dart';
import '../../../shared/models/client_attribute_filter.dart';
import '../../../shared/models/location_filter.dart';
import '../../../shared/providers/client_attribute_filter_provider.dart';
import '../../../shared/providers/location_filter_providers.dart';
import '../filters/client_attribute_filter_helpers.dart';

class ActiveFilterChipsRow extends ConsumerWidget {
  const ActiveFilterChipsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationFilterProvider);
    final attrs = ref.watch(clientAttributeFilterProvider);
    final attrNotifier = ref.read(clientAttributeFilterProvider.notifier);
    final locationNotifier = ref.read(locationFilterProvider.notifier);

    final chips = <Widget>[];

    // Location chip
    if (location.province != null) {
      final label = location.municipalities == null || location.municipalities!.isEmpty
          ? location.province!
          : '${location.province} • ${location.municipalities!.length > 1 ? "${location.municipalities!.length} cities" : location.municipalities!.first}';
      chips.add(_ActiveChip(
        label: label,
        icon: Icons.location_on,
        onRemove: () => locationNotifier.clear(),
      ));
    }

    // Attribute chips
    for (final t in attrs.clientTypes ?? []) {
      chips.add(_ActiveChip(
        label: formatClientType(t),
        onRemove: () => attrNotifier.toggleClientType(t),
      ));
    }
    for (final t in attrs.marketTypes ?? []) {
      chips.add(_ActiveChip(
        label: formatMarketType(t),
        onRemove: () => attrNotifier.toggleMarketType(t),
      ));
    }
    for (final t in attrs.pensionTypes ?? []) {
      chips.add(_ActiveChip(
        label: formatPensionType(t),
        onRemove: () => attrNotifier.togglePensionType(t),
      ));
    }
    for (final t in attrs.productTypes ?? []) {
      chips.add(_ActiveChip(
        label: formatProductType(t),
        onRemove: () => attrNotifier.toggleProductType(t),
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    if (chips.length >= 3) {
      chips.add(
        TextButton(
          onPressed: () {
            attrNotifier.clear();
            locationNotifier.clear();
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            visualDensity: VisualDensity.compact,
          ),
          child: const Text('Clear all', style: TextStyle(fontSize: 12)),
        ),
      );
    }

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: chips.map((c) => Padding(padding: const EdgeInsets.only(right: 6), child: c)).toList(),
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onRemove;

  const _ActiveChip({required this.label, required this.onRemove, this.icon});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      avatar: icon != null ? Icon(icon, size: 14) : null,
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onRemove,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
    );
  }
}
```

- [ ] **Step 2: Check `locationFilterProvider.notifier` has a `clear()` method**

```bash
grep -n "void clear\|Future clear" /home/claude-team/loi/imu2/frontend-mobile-imu/imu_flutter/lib/shared/providers/location_filter_providers.dart
```

If `clear()` doesn't exist, add it to the `LocationFilterNotifier`:

```dart
void clear() {
  state = const LocationFilter();
  _prefs.clearLocationFilters();
}
```

- [ ] **Step 3: Run flutter analyze**

```bash
flutter analyze lib/shared/widgets/filters/active_filter_chips_row.dart
```
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/shared/widgets/filters/active_filter_chips_row.dart lib/shared/providers/location_filter_providers.dart
git commit -m "feat: add ActiveFilterChipsRow for inline active filter display and removal"
```

---

## Task 9: FilterDrawer widget

**Files:**
- Create: `lib/shared/widgets/filters/filter_drawer.dart`

- [ ] **Step 1: Create the widget**

Create `lib/shared/widgets/filters/filter_drawer.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/client_attribute_filter.dart';
import '../../../shared/models/location_filter.dart';
import '../../../shared/providers/client_attribute_filter_provider.dart';
import '../../../shared/providers/location_filter_providers.dart';
import 'location_dropdown_section.dart';
import 'attribute_chips_section.dart';

class FilterDrawer extends ConsumerStatefulWidget {
  final bool showAllPsgc;

  const FilterDrawer({super.key, required this.showAllPsgc});

  @override
  ConsumerState<FilterDrawer> createState() => _FilterDrawerState();
}

class _FilterDrawerState extends ConsumerState<FilterDrawer> {
  late ClientAttributeFilter _draftAttrs;
  late LocationFilter _draftLocation;

  @override
  void initState() {
    super.initState();
    _draftAttrs = ref.read(clientAttributeFilterProvider);
    _draftLocation = ref.read(locationFilterProvider);
  }

  void _applyAndClose() {
    ref.read(clientAttributeFilterProvider.notifier).updateFilter(_draftAttrs);
    ref.read(locationFilterProvider.notifier).updateFilter(_draftLocation);
    Navigator.pop(context);
  }

  void _clearAll() {
    setState(() {
      _draftAttrs = ClientAttributeFilter.none();
      _draftLocation = const LocationFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        elevation: 8,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.82,
          height: double.infinity,
          child: Column(
            children: [
              // Header
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LocationDropdownSection(
                        draftFilter: _draftLocation,
                        showAllPsgc: widget.showAllPsgc,
                        onChanged: (f) => setState(() => _draftLocation = f),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),
                      AttributeChipsSection(
                        draftFilter: _draftAttrs,
                        onChanged: (f) => setState(() => _draftAttrs = f),
                      ),
                    ],
                  ),
                ),
              ),
              // Sticky footer
              const Divider(height: 1),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clearAll,
                          child: const Text('Clear All'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _applyAndClose,
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Call this to open the filter drawer from any page.
void showFilterDrawer(BuildContext context, {required bool showAllPsgc}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close filters',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => FilterDrawer(showAllPsgc: showAllPsgc),
    transitionBuilder: (_, anim, __, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
        child: child,
      );
    },
  );
}
```

- [ ] **Step 2: Verify `locationFilterProvider.notifier` has `updateFilter`**

```bash
grep -n "void updateFilter\|Future updateFilter" /home/claude-team/loi/imu2/frontend-mobile-imu/imu_flutter/lib/shared/providers/location_filter_providers.dart
```

If missing, add:
```dart
void updateFilter(LocationFilter newFilter) {
  state = newFilter;
  _persistFilter(newFilter);
}
```

- [ ] **Step 3: Run flutter analyze**

```bash
flutter analyze lib/shared/widgets/filters/filter_drawer.dart
```
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/shared/widgets/filters/filter_drawer.dart
git commit -m "feat: add FilterDrawer right-side panel with location dropdowns and attribute chips"
```

---

## Task 10: Wire FilterDrawer into Clients page

**Files:**
- Modify: `lib/features/clients/presentation/pages/clients_page.dart`

- [ ] **Step 1: Find and replace filter button in app bar**

Search for the filter icon button in the app bar:

```bash
grep -n "ClientFilterIconButton\|_showLocationFilter\|_showAttributeFilter\|showModalBottomSheet" /home/claude-team/loi/imu2/frontend-mobile-imu/imu_flutter/lib/features/clients/presentation/pages/clients_page.dart | head -20
```

Replace any calls to `_showLocationFilterBottomSheet` and the filter icon button with `showFilterDrawer`:

```dart
// Remove the _showLocationFilterBottomSheet method entirely.
// Replace ClientFilterIconButton or any filter icon button in the app bar with:
IconButton(
  icon: Consumer(
    builder: (context, ref, _) {
      final count = ref.watch(activeFilterCountProvider);
      return Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.tune),
          if (count > 0)
            Positioned(
              right: -4, top: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 9)),
              ),
            ),
        ],
      );
    },
  ),
  onPressed: () => showFilterDrawer(context, showAllPsgc: !_showAssignedClientsOnly),
),
```

- [ ] **Step 2: Add ActiveFilterChipsRow below the search bar**

Find the search bar widget in `clients_page.dart`. Add `const ActiveFilterChipsRow()` directly below it, wrapped in a `const SizedBox(height: 8)` spacer above the client list.

Add import:
```dart
import '../../../../shared/widgets/filters/active_filter_chips_row.dart';
import '../../../../shared/widgets/filters/filter_drawer.dart';
import '../../../../shared/providers/client_attribute_filter_provider.dart';
```

- [ ] **Step 3: Remove now-unused imports**

Remove imports for:
- `location_filter_bottom_sheet.dart`
- `client_attribute_filter_bottom_sheet.dart`
- `client_filter_icon_button.dart`
- `location_filter_icon.dart`
- `client_filter_chips.dart`
- `location_filter_chips.dart`

- [ ] **Step 4: Run flutter analyze**

```bash
flutter analyze lib/features/clients/presentation/pages/clients_page.dart
```
Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/clients/presentation/pages/clients_page.dart
git commit -m "feat: wire FilterDrawer and ActiveFilterChipsRow into Clients page"
```

---

## Task 11: Wire FilterDrawer into Client Selector Modal

**Files:**
- Modify: `lib/shared/widgets/client_selector_modal.dart`
- Modify: `lib/shared/widgets/unified_client_selector_bottom_sheet.dart`

- [ ] **Step 1: Fix showAllPsgcAreas in client_selector_modal.dart**

Find the `_showLocationFilterBottomSheet` call at lines ~683–700 in `client_selector_modal.dart`:

```bash
sed -n '680,700p' /home/claude-team/loi/imu2/frontend-mobile-imu/imu_flutter/lib/shared/widgets/client_selector_modal.dart
```

Replace the two filter icon buttons and `_showLocationFilterBottomSheet` / `_showAttributeFilterBottomSheet` methods with `showFilterDrawer`. The `showAllPsgc` flag should be `!widget.showAssignedFilter`:

```dart
// In the app bar / header row, replace filter icon buttons with:
IconButton(
  icon: Consumer(
    builder: (context, ref, _) {
      final count = ref.watch(activeFilterCountProvider);
      return Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.tune),
          if (count > 0)
            Positioned(
              right: -4, top: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 9)),
              ),
            ),
        ],
      );
    },
  ),
  onPressed: () => showFilterDrawer(context, showAllPsgc: !widget.showAssignedFilter),
),
```

Add `const ActiveFilterChipsRow()` below the search bar in the modal.

- [ ] **Step 2: Fix unified_client_selector_bottom_sheet.dart**

Find the `LocationFilterBottomSheet` call (line ~64):

```bash
sed -n '58,75p' /home/claude-team/loi/imu2/frontend-mobile-imu/imu_flutter/lib/shared/widgets/unified_client_selector_bottom_sheet.dart
```

Replace the `showModalBottomSheet` call for location filter with `showFilterDrawer`. Pass `showAllPsgc` based on the widget's assigned/all mode.

- [ ] **Step 3: Remove now-unused imports from both files**

Same imports as Task 10 — remove bottom sheet, icon button, and chip imports no longer used.

- [ ] **Step 4: Run flutter analyze on both files**

```bash
flutter analyze lib/shared/widgets/client_selector_modal.dart lib/shared/widgets/unified_client_selector_bottom_sheet.dart
```
Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/client_selector_modal.dart lib/shared/widgets/unified_client_selector_bottom_sheet.dart
git commit -m "feat: wire FilterDrawer into ClientSelectorModal and fix showAllPsgc flag"
```

---

## Task 12: Delete superseded files and run full test suite

**Files:**
- Delete: `lib/shared/widgets/location_filter_bottom_sheet.dart`
- Delete: `lib/shared/widgets/client_attribute_filter_bottom_sheet.dart`
- Delete: `lib/shared/widgets/filters/client_attribute_filter_bottom_sheet_dropdown.dart`

- [ ] **Step 1: Confirm no remaining imports**

```bash
grep -rn "location_filter_bottom_sheet\|client_attribute_filter_bottom_sheet\|client_attribute_filter_bottom_sheet_dropdown" /home/claude-team/loi/imu2/frontend-mobile-imu/imu_flutter/lib/ --include="*.dart"
```
Expected: no results. If any imports remain, remove them first.

- [ ] **Step 2: Delete the files**

```bash
cd /home/claude-team/loi/imu2/frontend-mobile-imu/imu_flutter
rm lib/shared/widgets/location_filter_bottom_sheet.dart
rm lib/shared/widgets/client_attribute_filter_bottom_sheet.dart
rm lib/shared/widgets/filters/client_attribute_filter_bottom_sheet_dropdown.dart
```

- [ ] **Step 3: Run full test suite**

```bash
flutter test
```
Expected: all tests PASS with no compile errors.

- [ ] **Step 4: Run full analyzer**

```bash
flutter analyze
```
Expected: no errors (warnings about deprecated APIs are acceptable).

- [ ] **Step 5: Final commit**

```bash
cd /home/claude-team/loi/imu2/frontend-mobile-imu/imu_flutter
git add -A
git commit -m "chore: delete superseded filter bottom sheet widgets"
```

- [ ] **Step 6: Push both repos**

```bash
cd /home/claude-team/loi/imu2/frontend-mobile-imu && git push origin main
cd /home/claude-team/loi/imu2/backend-imu && git push origin main
```
