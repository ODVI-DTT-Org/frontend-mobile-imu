# Touchpoint Filter Chips — Design Spec

> **Created:** 2026-04-18
> **Status:** Approved
> **Scope:** Flutter mobile app — clients_page.dart + client_selector_modal.dart

---

## Problem

There is no way to quickly filter clients by which touchpoint they are currently on. Users must scroll through the full list to find clients at a specific stage of the 7-touchpoint sequence.

---

## Goal

Add a horizontally scrollable row of touchpoint filter chips — 1st through 7th plus Archive — displayed immediately below the search bar on both the Clients page and the Client Selector modal (all tabs). Supports multi-select. Persists across sessions.

---

## Touchpoint Sequence Reference

| Chip | Label | Icon | Data Condition |
|------|-------|------|----------------|
| 1 | 1st | mapPin (visit) | `touchpointNumber == 1` |
| 2 | 2nd | phone (call) | `touchpointNumber == 2` |
| 3 | 3rd | phone (call) | `touchpointNumber == 3` |
| 4 | 4th | mapPin (visit) | `touchpointNumber == 4` |
| 5 | 5th | phone (call) | `touchpointNumber == 5` |
| 6 | 6th | phone (call) | `touchpointNumber == 6` |
| 7 | 7th | mapPin (visit) | `touchpointNumber == 7` |
| 8 | Archive | archive | `touchpointNumber > 7` |

Icons from `lucide_icons`: `LucideIcons.mapPin` (visit), `LucideIcons.phone` (call), `LucideIcons.archive` (archive).

---

## Architecture

### Option Chosen: Standalone provider (Option B)

Mirrors the existing `clientAttributeFilterProvider` and `locationFilterProvider` pattern. Each filter type has one responsibility and its own provider.

---

## New Files

### `lib/shared/models/touchpoint_filter.dart`
- `TouchpointFilter` model with `Set<int> selectedNumbers` (1–7 = touchpoint position, 8 = archive)
- `hasFilter`, `toggle(int n)`, `clear()` methods
- `matches(Client client)` — returns true if `selectedNumbers` is empty OR client's touchpoint number is in set (archive: `touchpointNumber > 7` matches 8)
- `copyWith`

### `lib/shared/providers/touchpoint_filter_provider.dart`
- `StateNotifierProvider<TouchpointFilterNotifier, TouchpointFilter>`
- `toggle(int n)` — adds if absent, removes if present
- `clear()`
- Load/save via `FilterPreferencesService` key `filter_touchpoint_numbers` (JSON int list)

### `lib/shared/widgets/filters/touchpoint_filter_chips.dart`
- `ConsumerWidget` — reads `touchpointFilterProvider`
- Horizontally scrollable `ListView` of 8 chips
- Each chip: icon + ordinal label, filled/colored when active, outlined/grey when inactive
- No padding wrapper — caller controls vertical spacing
- Chip height: compact (matches existing filter chip style)

---

## Modified Files

### `lib/services/filter_preferences_service.dart`
- Add key `static const String _keyTouchpointNumbers = 'filter_touchpoint_numbers'`
- Add `List<int> getTouchpointNumbers()` — decode JSON int list
- Add `Future<void> setTouchpointNumbers(List<int> value)` — encode JSON int list, remove key if empty

### `lib/shared/providers/app_providers.dart`
- Watch `touchpointFilterProvider` alongside existing two filters in `assignedClientsProvider` and `onlineClientsProvider`
- Apply `touchpointFilter.matches(client)` locally after existing filters

### `lib/features/clients/presentation/pages/clients_page.dart`
- Import and place `TouchpointFilterChips` immediately below each tab's `TextField` search bar (appears in two spots — Assigned tab and All Clients tab)

### `lib/shared/widgets/client_selector_modal.dart`
- Same as above — place `TouchpointFilterChips` immediately below each tab's search field

---

## Filtering Behavior

| Mode | Behavior |
|------|----------|
| Assigned Clients | Full local cache filtered by `touchpointFilter.matches(client)` |
| All Clients (online) | Locally filtered on currently loaded page results (silent) |
| No chips selected | No filter applied — all clients shown |
| Multiple chips selected | OR logic — client matches if on any selected touchpoint |

---

## Persistence

Stored in `SharedPreferences` as a JSON int list under key `filter_touchpoint_numbers`. Loaded on app start by `TouchpointFilterNotifier` initializer. Cleared when user deselects all chips.

---

## Not In Scope

- Backend API filter param for `touchpoint_number` (future)
- Adding touchpoint chip count to the existing filter badge icon
- Chip animations beyond standard Flutter InkWell feedback
