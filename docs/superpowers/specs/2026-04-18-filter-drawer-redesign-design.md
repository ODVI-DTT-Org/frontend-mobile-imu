# Filter Drawer Redesign — Design Spec

**Date:** 2026-04-18
**Project:** IMU Flutter Mobile App
**Scope:** Clients page + Client selector modal
**Status:** Approved for implementation

---

## Overview

Redesign the client filter UX from bottom sheets with `ExpansionTile` + radio buttons into a right-side filter drawer. The drawer consolidates location and attribute filters in one place. Active filters are summarized as removable chips below the search bar.

---

## Goals

1. Replace location filter bottom sheet with two stacked dropdowns (province → municipality cascade)
2. Replace attribute filter bottom sheet with compact `FilterChip` groups
3. Surface both in a slide-in drawer from the right (covers ~80% screen width)
4. Fix location data: All Clients mode must use all PSGC provinces/municipalities
5. Show active filter summary chips below the search bar for quick removal

## Non-Goals

- Redesigning the search bar itself

---

## Section 1: Filter Drawer

### Structure

A `Drawer` (or custom `AnimatedPositioned` panel) slides in from the right, covering ~80% of screen width. A dark scrim covers the remaining left portion. The drawer closes on scrim tap or the `✕` button.

```
┌─────────────────────────┐
│  Filters        [✕]     │  ← header
├─────────────────────────┤
│  Location               │
│  [Select Province ▾]    │
│  [Select Municipality ▾]│  ← disabled until province selected
├─────────────────────────┤
│  Client Type            │
│  [Potential] [Existing] │
│                         │
│  Market Type            │
│  [Residential] [Comm.]  │
│  [Industrial]           │
│                         │
│  Pension Type           │
│  [SSS][GSIS][Priv.][No] │
│                         │
│  Product Type           │
│  [BFP Active][BFP Pen]  │
│  [PNP Pen][NAPOLCOM]    │
│  [BFP STP]              │
├─────────────────────────┤
│  [Clear All]  [Apply]   │  ← sticky footer
└─────────────────────────┘
```

### Behavior
- Opened via filter icon button in the app bar
- `Apply` applies filters and closes the drawer
- `Clear All` resets all filters (location + attributes) but keeps drawer open
- Scrim tap closes without applying (cancels pending changes)

---

## Section 2: Location Dropdowns

### Province Dropdown
- **All Clients mode:** all PSGC provinces (from `provincesProvider`)
- **Assigned Clients mode:** only assigned provinces (from `assignedAreasProvider`)
- Tapping opens a searchable modal list (full-height bottom sheet with search input)
- Placeholder: "Select Province"

### Municipality Dropdown
- Disabled and grayed out until a province is selected
- Loads municipalities filtered strictly to the selected province (`municipalitiesByProvinceProvider`)
- Tapping opens a searchable modal list with checkboxes
- "All Municipalities" option at the top (default when province selected, no specific municipality chosen)
- Placeholder: "All Municipalities" (when province selected but no municipality chosen)

### Cascading Rules
- When province changes → municipality selection resets to "All Municipalities"
- When switching Assigned ↔ All Clients toggle → location filter **persists**
- If persisted province is not available in the current mode (e.g. Assigned mode doesn't include it) → show province grayed with label "(not in assigned areas)" and disable municipality dropdown

---

## Section 3: Attribute Filter Chips

### Layout
`Wrap` widget per category so chips flow to the next line naturally. No horizontal scrolling.

```dart
visualDensity: VisualDensity.compact
labelStyle: TextStyle(fontSize: 12)
```

### Categories
| Category | Options |
|----------|---------|
| Client Type | Potential, Existing |
| Market Type | Residential, Commercial, Industrial |
| Pension Type | SSS, GSIS, Private, None |
| Product Type | BFP Active, BFP Pension, PNP Pension, NAPOLCOM, BFP STP |

### Chip States
- **Unselected:** outlined border, gray label
- **Selected:** filled blue (`Theme.primaryColor`) background, white label
- **Multi-select within category:** multiple chips can be active simultaneously (OR logic within category)
- **AND logic across categories:** client must match at least one value in every active category
- Tapping a selected chip deselects it

---

## Section 4: Active Filter Summary (Below Search Bar)

A horizontal scrollable row of read-only chips appears below the search bar when any filter is active.

### Chip formats
- Location: `📍 Cebu` or `📍 Cebu • Mandaue, Lapu-Lapu` (truncated if too long)
- Attribute: one chip per active value (e.g. `Existing`, `SSS`, `BFP Active`)

### Behavior
- Each chip has a `✕` delete icon — tapping removes that filter immediately (no drawer needed)
- `Clear all` text button appears at the end when 3+ filters are active
- Row is hidden when no filters are active

---

## Section 5: Filter Badge (App Bar)

- Icon: `LucideIcons.slidersHorizontal`
- Badge count = number of active attribute filters + 1 if province set + 1 if specific municipalities set
- Badge only shown when count > 0
- Same button used in both Clients page app bar and client selector modal header

---

## Affected Files

### New Files
| File | Purpose |
|------|---------|
| `lib/shared/widgets/filters/filter_drawer.dart` | Main drawer widget (location + attribute sections + footer) |
| `lib/shared/widgets/filters/location_dropdown_section.dart` | Province + municipality dropdown section |
| `lib/shared/widgets/filters/attribute_chips_section.dart` | Compact filter chips grouped by category |
| `lib/shared/widgets/filters/searchable_picker_sheet.dart` | Reusable searchable list bottom sheet (for province + municipality) |
| `lib/shared/widgets/filters/active_filter_chips_row.dart` | Summary chips row below search bar |

### Modified Files
| File | Change |
|------|--------|
| `lib/features/clients/presentation/pages/clients_page.dart` | Replace filter icon buttons + bottom sheets with drawer trigger + active chips row |
| `lib/shared/widgets/client_selector_modal.dart` | Same replacement — drawer trigger + active chips row; fix `showAllPsgcAreas` wiring |
| `lib/shared/widgets/unified_client_selector_bottom_sheet.dart` | Pass `showAllPsgcAreas` correctly based on assigned/all toggle |
| `lib/shared/models/client_attribute_filter.dart` | Change fields to `List<...>?`, update `toQueryParams()`, `matches()`, `activeFilterCount` |
| `lib/shared/providers/client_attribute_filter_provider.dart` | Update notifier methods to accept lists; update SharedPreferences serialization |
| **`backend-imu/src/routes/clients.ts`** | Change `=` to `ANY($1::text[])` for client_type, market_type, pension_type, product_type |

### Deleted / Superseded
| File | Reason |
|------|--------|
| `lib/shared/widgets/location_filter_bottom_sheet.dart` | Replaced by `location_dropdown_section.dart` + `searchable_picker_sheet.dart` |
| `lib/shared/widgets/client_attribute_filter_bottom_sheet.dart` | Replaced by `attribute_chips_section.dart` |
| `lib/shared/widgets/filters/client_attribute_filter_bottom_sheet_dropdown.dart` | Superseded |

---

## Data & State

### Model Changes Required (multi-select)

`ClientAttributeFilter` fields change from single nullable values to nullable lists:

```dart
// Before
ClientType? clientType;
MarketType? marketType;
PensionType? pensionType;
ProductType? productType;

// After
List<ClientType>? clientTypes;
List<MarketType>? marketTypes;
List<PensionType>? pensionTypes;
List<ProductType>? productTypes;
```

**`toQueryParams()` changes:** emit comma-separated values per field:
```
client_type=POTENTIAL,EXISTING
pension_type=SSS,GSIS
```

**`matches(Client)` changes:** OR within category — client matches if its value is in the list.

**`activeFilterCount` changes:** count total selected values across all categories.

**SharedPreferences:** store as JSON-encoded lists instead of single strings. Keys unchanged.

### Provider Changes

`clientAttributeFilterProvider` notifier methods updated to accept lists. No structural changes to the provider itself.

### Backend Changes Required

`src/routes/clients.ts` — the current filter conditions use exact match (`c.client_type = $1`). Change to `IN` for each filter field when multiple values are passed:

```sql
-- Before
c.client_type = $1

-- After (when comma-separated values received)
c.client_type = ANY($1::text[])
```

Parse comma-separated query param into an array before building the SQL condition. Apply same change to `product_type`, `market_type`, and `pension_type`. Single values continue to work (array of one).

### Unchanged

`locationFilterProvider`, `provincesProvider`, `municipalitiesByProvinceProvider`, `assignedAreasProvider` — no changes.

### Drawer Draft State

The drawer manages local draft state (pending selections) and only commits to providers on `Apply`. `Clear All` resets local draft state. Scrim tap closes without applying (discards local draft state).
