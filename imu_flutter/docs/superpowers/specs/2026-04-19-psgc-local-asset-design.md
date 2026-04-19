# PSGC Local Asset Design

**Date:** 2026-04-19  
**Status:** Approved  

---

## Problem

The `PSGCSelector` widget (used in Add/Edit Address) makes cascading REST API calls to the backend for regions, provinces, municipalities, and barangays. This breaks the offline-first architecture — field agents with no connectivity cannot select an address location.

The comment in `psgc_repository.dart` confirms this was intentional: "The psgc table was removed from PowerSync; data is served by the backend." PSGC data is static reference data (changes rarely, ~once every few years), so serving it from the backend is unnecessary overhead.

---

## Solution

Bundle PSGC data as a JSON asset shipped with the app. Load it into memory once on first use. Replace all `PsgcRepository` HTTP calls with in-memory filtering.

---

## Architecture

```
assets/data/psgc.json       ← flat array of ~42K barangay records, committed to repo
       ↓
PsgcAssetService            ← loads JSON from rootBundle once, caches in memory
       ↓
PsgcRepository (updated)    ← delegates to PsgcAssetService, keeps same public interface
       ↓
PSGCSelector (minor update) ← removes per-cascade loading spinners; cascade is now instant
```

---

## Data Format

`assets/data/psgc.json` — flat array:

```json
[
  {
    "id": "123456789",
    "region": "Region I - Ilocos Region",
    "province": "Ilocos Norte",
    "municipality": "Adams",
    "municipality_kind": "Municipality",
    "barangay": "Bacsil",
    "zip_code": "2901",
    "pin_location": null
  }
]
```

Keys are snake_case to match `PsgcBarangay.fromJson()`. Note: the existing `/api/psgc/all` endpoint returns camelCase (`municipalityKind`, `zipCode`) — the export script must convert to snake_case before writing the asset file.

~42,000 records. Flutter compresses assets at build time; estimated footprint ~1–1.5 MB compressed.

**Generation:** Use the existing `/api/psgc/all` endpoint (or query directly):
```sql
SELECT id, region, province, mun_city AS municipality, mun_city_kind AS municipality_kind,
       barangay, zip_code, pin_location
FROM psgc
ORDER BY region, province, mun_city, barangay;
```

Save output as snake_case JSON and commit to `assets/data/psgc.json`.

The file is committed to the repo and treated as a static asset. When PSGC data needs updating, re-run the export and commit the new file.

---

## Components

### 1. `assets/data/psgc.json`
Static asset bundled with the app. Registered in `pubspec.yaml` under `flutter.assets`.

### 2. `PsgcAssetService` (new)
`lib/features/psgc/data/services/psgc_asset_service.dart`

- Loads `psgc.json` from `rootBundle` on first call (lazy), parses into `List<PsgcBarangay>`, caches in a static field for the process lifetime
- Initial `loadIfNeeded()` is `async`; all filtering after that is synchronous
- Sync filtering methods (called only after load):
  - `List<String> distinctRegions()`
  - `List<String> provincesForRegion(String region)`
  - `List<PsgcMunicipality> municipalitiesForProvince(String province)`
  - `List<PsgcBarangay> barangaysForMunicipality(String municipality)`
  - `List<PsgcMunicipality> searchMunicipalities(String query)` — filters in-memory, min 2 chars
  - `List<PsgcBarangay> searchBarangays(String query, {String? municipality})` — filters in-memory, min 2 chars

### 3. `PsgcRepository` (updated)
`lib/features/psgc/data/repositories/psgc_repository.dart`

- Remove all `http.get` calls and `JwtAuthService` dependency
- Each method calls `await _assetService.loadIfNeeded()` then delegates to the sync filter
- `PsgcRepository` is responsible for converting raw strings → `PsgcRegion` / `PsgcProvince` typed models (the asset service returns strings/barangays; the repo wraps them to preserve the public interface)
- All existing public method signatures preserved: `getRegions()`, `getProvincesByRegion()`, `getMunicipalitiesByProvince()`, `getBarangaysByMunicipality()`, `searchMunicipalities()`, `searchBarangays()`

### 4. `PSGCSelector` (minor update)
`lib/shared/widgets/psgc_selector.dart`

- Remove `isLoadingProvinces`, `isLoadingMunicipalities`, `isLoadingBarangays` states — after the initial asset load, all cascade calls resolve in the same microtask tick
- Keep `isLoadingRegions` for the one-time asset parse on first open; all subsequent `PSGCSelector` opens are instant
- `useEffect` hooks for cascade steps remain `async` (repo methods are still `Future`-returning) but no longer show spinners — data arrives before the next frame

---

## UX Change

**Before:** Each cascade step (select region → wait for provinces, select province → wait for municipalities, etc.) shows a loading spinner.

**After:** Only the very first open of `PSGCSelector` shows a brief loading state while the JSON is parsed. After that, all cascade steps are instant. Subsequent opens are instant too (data is cached in memory).

---

## Files Changed

| File | Action |
|------|--------|
| `pubspec.yaml` | Add `assets/data/psgc.json` |
| `assets/data/psgc.json` | New — generated from backend DB |
| `lib/features/psgc/data/services/psgc_asset_service.dart` | New |
| `lib/features/psgc/data/repositories/psgc_repository.dart` | Replace HTTP calls with asset service |
| `lib/shared/widgets/psgc_selector.dart` | Remove per-level loading states |

---

## Out of Scope

- Changing `PSGCSelector`'s visual structure or cascade order
- Updating PSGC data automatically (manual re-export + commit when data changes)
- Removing the backend `/psgc` endpoints (other consumers may use them)
