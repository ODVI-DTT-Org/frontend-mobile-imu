# Client Attribute Filtering - Data Flow Visual Representation

## 1. OVERVIEW ARCHITECTURE

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CLIENT FILTERING SYSTEM                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐          │
│  │    PowerSync  │───▶│   Providers  │───▶│      UI     │          │
│  │   (Database) │    │  (State Mgmt)│    │  (Widgets)   │          │
│  └──────────────┘    └──────────────┘    └──────────────┘          │
│         │                    │                    │                  │
│         │                    ▼                    ▼                  │
│         │              ┌──────────┐        ┌──────────┐             │
│         └──────────────│ Filters  │        │  Chips  │             │
│                        │ Bottom  │        │ Display │             │
│                        │  Sheet  │        │         │             │
│                        └──────────┘        └──────────┘             │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

## 2. DATA FLOW - FILTER OPTIONS FETCHING

```
┌─────────────────────────────────────────────────────────────────────┐
│                    STEP 1: FETCH FILTER OPTIONS                      │
└─────────────────────────────────────────────────────────────────────┘

User opens filter bottom sheet
        │
        ▼
┌───────────────────────────────────────────┐
│  UI: ClientAttributeFilterBottomSheet    │
│  Watches: clientFilterOptionsProvider     │
└───────────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────────┐
│  Provider: clientFilterOptionsProvider    │
│  Type: FutureProvider.autoDispose         │
└───────────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────────┐
│  Service: ClientFilterOptionsService      │
│  Method: fetchOptions()                   │
└───────────────────────────────────────────┘
        │
        ├─── PowerSync (Primary) ─────────────────────┐
        │                                           │
        ▼                                           ▼
┌──────────────────────────────┐      ┌──────────────────────────────┐
│  SELECT DISTINCT Queries     │      │  API Fallback               │
│  (4 separate queries)        │      │  /api/filters/batch         │
├──────────────────────────────┤      └──────────────────────────────┘
│ • client_type                │                  ▲
│ • market_type                │                  │
│ • pension_type               │           PowerSync fails
│ • product_type               │           or returns empty
└──────────────────────────────┘
        │
        ▼
┌──────────────────────────────┐
│  Parse to Enums              │
│  • ClientType                │
│  • MarketType                │
│  • PensionType               │
│  • ProductType (special)     │
└──────────────────────────────┘
        │
        ▼
┌──────────────────────────────┐
│  Return: ClientFilterOptions│
│  {                           │
│    clientTypes: [...],       │
│    marketTypes: [...],       │
│    pensionTypes: [...],      │
│    productTypes: [...]       │
│  }                           │
└──────────────────────────────┘
```

## 3. DATA FLOW - APPLYING FILTERS

```
┌─────────────────────────────────────────────────────────────────────┐
│                    STEP 2: USER SELECTS FILTERS                     │
└─────────────────────────────────────────────────────────────────────┘

User taps filter chip in bottom sheet
        │
        ▼
┌───────────────────────────────────────────┐
│  UI: RadioListTile Selection              │
│  Updates: _selected{FilterType}           │
└───────────────────────────────────────────┘
        │
        ▼
User taps "Apply" button
        │
        ▼
┌───────────────────────────────────────────┐
│  Create: ClientAttributeFilter           │
│  {                                       │
│    clientType: ClientType.potential,     │
│    marketType: MarketType.residential,   │
│    pensionType: PensionType.sss,         │
│    productType: ProductType.sssPensioner │
│  }                                       │
└───────────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────────┐
│  Update: clientAttributeFilterProvider    │
│  Provider: StateProvider                  │
│  Triggers: Rebuild of dependent providers │
└───────────────────────────────────────────┘
        │
        ├─── assignedClientsProvider (Affected) ─────┐
│                                               │
        ├─── onlineClientsProvider (Affected) ───────┤
│                                               │
        ▼                                               ▼
```

## 4. DATA FLOW - ASSIGNED CLIENTS MODE

```
┌─────────────────────────────────────────────────────────────────────┐
│              STEP 3A: FILTERING - ASSIGNED CLIENTS MODE              │
└─────────────────────────────────────────────────────────────────────┘

Provider: assignedClientsProvider
        │
        ▼
┌───────────────────────────────────────────┐
│  Watch: clientAttributeFilterProvider     │
│  Get active filter state                  │
└───────────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────────┐
│  Load from Hive Cache                     │
│  hiveService.getAllClients()              │
└───────────────────────────────────────────┘
        │
        ├─── Empty AND Online? ────────────┐
        │                                 │
        ▼                                 ▼
┌──────────────────────────┐    ┌──────────────────────────┐
│  Immediate API Fetch    │    │  Background Refresh     │
│  fetchAssignedClients(  │    │  (Don't wait)            │
│    attribute filters    │    │                          │
│  )                      │    └──────────────────────────┘
└──────────────────────────┘                  │
        │                                   │
        ▼                                   ▼
┌───────────────────────────────────────────┐
│  Apply Filters Locally                    │
│  1. Location Filter (province/municipality)│
│  2. Attribute Filter (AND logic)          │
│     ┌─────────────────────────────────┐  │
│     │ filter.matches(client)         │  │
│     │ • clientType == filter.clientType│  │
│     │ • marketType == filter.marketType│  │
│     │ • pensionType == filter.pensionType│ │
│     │ • productType == filter.productType│ │
│     │ ALL must match (AND logic)      │  │
│     └─────────────────────────────────┘  │
└───────────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────────┐
│  Apply Search & Pagination                │
│  • Fuzzy search on name                   │
│  • Local pagination (10 per page)         │
└───────────────────────────────────────────┘
        │
        ▼
Return: PaginatedClientResponse
```

## 5. DATA FLOW - ALL CLIENTS MODE

```
┌─────────────────────────────────────────────────────────────────────┐
│               STEP 3B: FILTERING - ALL CLIENTS MODE                  │
└─────────────────────────────────────────────────────────────────────┘

Provider: onlineClientsProvider
        │
        ▼
┌───────────────────────────────────────────┐
│  Check: isOnlineProvider                   │
│  Must be online to fetch                   │
└───────────────────────────────────────────┘
        │
        ├─── Offline? ──▶ Throw Exception      │
        │
        ▼
┌───────────────────────────────────────────┐
│  Watch: clientAttributeFilterProvider     │
│  Convert to API parameters                │
└───────────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────────┐
│  toQueryParams()                          │
│  • client_type: "POTENTIAL"               │
│  • market_type: "RESIDENTIAL"             │
│  • pension_type: "SSS"                    │
│  • product_type: "SSS_PENSIONER"          │
└───────────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────────┐
│  API Call: fetchClients(                  │
│    attribute filter params                │
│  )                                        │
└───────────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────────┐
│  Backend: /api/clients                    │
│  • Validate parameters (Zod)              │
│  • Apply WHERE clause filters             │
│  • Server-side filtering                  │
│  • Return paginated results               │
└───────────────────────────────────────────┘
        │
        ▼
Return: PaginatedClientResponse
```

## 6. STATE MANAGEMENT FLOW

```
┌─────────────────────────────────────────────────────────────────────┐
│                    PROVIDER DEPENDENCY GRAPH                         │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                         ROOT PROVIDERS                                │
│  • powerSyncDatabaseProvider (PowerSync instance)                   │
│  • clientApiServiceProvider (API client)                            │
│  • isOnlineProvider (Network status)                                │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        FILTER PROVIDERS                               │
│  ┌────────────────────────────────────────────────────────────────┐│
│  │ clientAttributeFilterProvider (StateProvider)                  ││
│  │ • Stores active filter selections                               ││
│  │ • Updated when user applies filters                             ││
│  │ • No persistence (session-only)                                 ││
│  └────────────────────────────────────────────────────────────────┘│
│  ┌────────────────────────────────────────────────────────────────┐│
│  │ clientFilterOptionsProvider (FutureProvider.autoDispose)      ││
│  │ • Fetches available filter options                             ││
│  │ • PowerSync → API fallback                                     ││
│  │ • Auto-disposes when navigation changes                        ││
│  └────────────────────────────────────────────────────────────────┘│
│  ┌────────────────────────────────────────────────────────────────┐│
│  │ activeFilterCountProvider (Provider)                          ││
│  │ • Calculates total active filter count                        ││
│  │ • Location + Attributes                                       ││
│  │ • Used for badge display                                       ││
│  └────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        DATA PROVIDERS                                 │
│  ┌────────────────────────────────────────────────────────────────┐│
│  │ assignedClientsProvider (FutureProvider)                       ││
│  │ Watches: clientAttributeFilterProvider                         ││
│  │ • Hive cache + API refresh                                     ││
│  │ • Local filtering (offline-capable)                            ││
│  └────────────────────────────────────────────────────────────────┘│
│  ┌────────────────────────────────────────────────────────────────┐│
│  │ onlineClientsProvider (FutureProvider)                         ││
│  │ Watches: clientAttributeFilterProvider                         ││
│  │ • API-only (requires online)                                   ││
│  │ • Server-side filtering                                        ││
│  └────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                           UI WIDGETS                                  │
│  • ClientAttributeFilterBottomSheet (Filter selection UI)          │
│  • ClientFilterChips (Active filter display)                       │
│  • ClientFilterIconButton (Filter trigger with badge)              │
└─────────────────────────────────────────────────────────────────────┘
```

## 7. FILTER APPLICATION LOGIC

```
┌─────────────────────────────────────────────────────────────────────┐
│                   AND LOGIC - FILTER MATCHING                         │
└─────────────────────────────────────────────────────────────────────┘

Client matches if ALL conditions are true:

┌─────────────────────────────────────────────────────────────────────┐
│  MATCH CHECK: filter.matches(client)                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐│
│  │ IF filter.clientType != null THEN                               ││
│  │   RETURN client.clientType == filter.clientType                ││
│  │   Example: POTENTIAL == POTENTIAL ✓                            ││
│  └────────────────────────────────────────────────────────────────┘│
│                              AND                                    │
│  ┌────────────────────────────────────────────────────────────────┐│
│  │ IF filter.marketType != null THEN                              ││
│  │   RETURN client.marketType == filter.marketType                ││
│  │   Example: RESIDENTIAL == RESIDENTIAL ✓                        ││
│  └────────────────────────────────────────────────────────────────┘│
│                              AND                                    │
│  ┌────────────────────────────────────────────────────────────────┐│
│  │ IF filter.pensionType != null THEN                             ││
│  │   RETURN client.pensionType == filter.pensionType               ││
│  │   Example: SSS == SSS ✓                                        ││
│  └────────────────────────────────────────────────────────────────┘│
│                              AND                                    │
│  ┌────────────────────────────────────────────────────────────────┐│
│  │ IF filter.productType != null THEN                             ││
│  │   RETURN client.productType == filter.productType               ││
│  │   Example: SSS_PENSIONER == SSS_PENSIONER ✓                    ││
│  └────────────────────────────────────────────────────────────────┘│
│                                                                       │
│  RESULT: true ONLY if ALL active filters match                       │
└─────────────────────────────────────────────────────────────────────┘

COMBINED FILTERING (Search + Location + Attributes):

┌─────────────────────────────────────────────────────────────────────┐
│  filterClients(                                                      │
│    clients: [all clients],                                          │
│    searchQuery: "Juan",                                            │
│    locationFilter: Pangasinan/Dagupan,                             │
│    attributeFilter: POTENTIAL + RESIDENTIAL + SSS                  │
│  )                                                                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  RETURN clients WHERE:                                               │
│    name CONTAINS "Juan"              AND                             │
│    province == "Pangasinan"           AND                             │
│    municipality IN ["Dagupan"]      AND                             │
│    clientType == POTENTIAL           AND                             │
│    marketType == RESIDENTIAL         AND                             │
│    pensionType == SSS                AND                             │
│    productType == SSS_PENSIONER                                       │
│                                                                       │
│  Result: Only clients matching ALL 7 conditions                      │
└─────────────────────────────────────────────────────────────────────┘
```

## 8. DATA TRANSFORMATIONS

```
┌─────────────────────────────────────────────────────────────────────┐
│                  ENUM VALUE TRANSFORMATIONS                           │
└─────────────────────────────────────────────────────────────────────┘

DATABASE FORMAT (PowerSync/Backend):
┌─────────────────┬────────────────────────────────────────┐
│ Filter Type     │ Database Value                          │
├─────────────────┼────────────────────────────────────────┤
│ clientType      │ POTENTIAL, EXISTING                    │
│ marketType      │ RESIDENTIAL, COMMERCIAL, INDUSTRIAL     │
│ pensionType     │ SSS, GSIS, PRIVATE, NONE                │
│ productType     │ SSS_PENSIONER, GSIS_PENSIONER, PRIVATE  │
└─────────────────┴────────────────────────────────────────┘

        ↓ PARSING (Database → Dart Enum)

DART ENUM FORMAT (Mobile App):
┌─────────────────┬────────────────────────────────────────┐
│ Filter Type     │ Dart Enum Value                         │
├─────────────────┼────────────────────────────────────────┤
│ ClientType      │ potential, existing                     │
│ MarketType      │ residential, commercial, industrial     │
│ PensionType     │ sss, gsis, private, none                │
│ ProductType     │ sssPensioner, gsisPensioner, private     │
└─────────────────┴────────────────────────────────────────┘

        ↓ DISPLAY FORMATTING (Enum → UI Label)

UI LABEL FORMAT (User Display):
┌─────────────────┬────────────────────────────────────────┐
│ Filter Type     │ Display Label                           │
├─────────────────┼────────────────────────────────────────┤
│ ClientType      │ Potential, Existing                     │
│ MarketType      │ Residential, Commercial, Industrial     │
│ PensionType     │ SSS, GSIS, Private, None                │
│ ProductType     │ SSS Pensioner, GSIS Pensioner, Private  │
└─────────────────┴────────────────────────────────────────┘

        ↓ API SERIALIZATION (Enum → Backend)

API PARAMETER FORMAT (Backend Request):
┌─────────────────┬────────────────────────────────────────┐
│ Filter Type     │ API Query Parameter                    │
├─────────────────┼────────────────────────────────────────┤
│ clientType      │ client_type=POTENTIAL                   │
│ marketType      │ market_type=RESIDENTIAL                 │
│ pensionType     │ pension_type=SSS                        │
│ productType     │ product_type=SSS_PENSIONER               │
└─────────────────┴────────────────────────────────────────┘
```

## 9. PERFORMANCE CONSIDERATIONS

```
┌─────────────────────────────────────────────────────────────────────┐
│                     PERFORMANCE OPTIMIZATIONS                          │
└─────────────────────────────────────────────────────────────────────┘

POWERSYNC FILTER FETCHING:
┌─────────────────────────────────────────────────────────────────────┐
│  • 4 separate SELECT DISTINCT queries (not JOIN)                     │
│  • Each query scans only one column                                  │
│  • Indexed on filter columns (if DB indexes exist)                   │
│  • Results cached in provider (autoDispose after navigation)         │
│  • API fallback only if PowerSync fails/empty                        │
└─────────────────────────────────────────────────────────────────────┘

LOCAL FILTERING (Assigned Clients):
┌─────────────────────────────────────────────────────────────────────┐
│  • In-memory filtering (fast)                                        │
│  • AND logic short-circuits (fails fast on first mismatch)           │
│  • Fuzzy search only if search query exists                          │
│  • Pagination applied AFTER filtering                               │
└─────────────────────────────────────────────────────────────────────┘

REMOTE FILTERING (All Clients):
┌─────────────────────────────────────────────────────────────────────┐
│  • Server-side filtering (reduces data transfer)                     │
│  • Parameterized queries (SQL injection safe)                       │
│  • Backend pagination (10-100 per page)                              │
│  • No network request if device offline                              │
└─────────────────────────────────────────────────────────────────────┘

STATE MANAGEMENT:
┌─────────────────────────────────────────────────────────────────────┐
│  • AutoDispose providers (prevent memory leaks)                      │
│  • Watch-specific dependencies (only rebuild when needed)            │
│  • Session-only state (no persistence overhead)                     │
└─────────────────────────────────────────────────────────────────────┘
```

## 10. ERROR HANDLING FLOW

```
┌─────────────────────────────────────────────────────────────────────┐
│                      ERROR HANDLING & FALLBACKS                       │
└─────────────────────────────────────────────────────────────────────┘

FILTER OPTIONS FETCH:
┌─────────────────────────────────────────────────────────────────────┐
│  PowerSync Failure                                                  │
│       │                                                              │
│       ├─── Parsing Error? ──▶ Log warning, continue with other filters│
│       │                                                              │
│       ├─── Empty Results? ──▶ Try API fallback                      │
│       │                                                              │
│       └─── API Fails Too? ──▶ Show empty state with retry button     │
└─────────────────────────────────────────────────────────────────────┘

CLIENT LIST FETCH:
┌─────────────────────────────────────────────────────────────────────┐
│  Assigned Clients Mode                                              │
│       │                                                              │
│       ├─── Hive Empty + Online? ──▶ Immediate API fetch             │
│       │                                                              │
│       ├─── API Fails? ──▶ Return empty list, show error state        │
│       │                                                              │
│       └─── Background Refresh Fails? ──▶ Use cached data (silent)    │
│                                                                       │
│  All Clients Mode                                                    │
│       │                                                              │
│       ├─── Offline? ──▶ Throw error, show "Go Online" message       │
│       │                                                              │
│       ├─── API Validation Error? ──▶ Show validation error message  │
│       │                                                              │
│       └─── API Server Error? ──▶ Show error state, retry option     │
└─────────────────────────────────────────────────────────────────────┘

FILTER APPLICATION:
┌─────────────────────────────────────────────────────────────────────┐
│  Invalid Filter Value                                                │
│       │                                                              │
│       └─── Backend Zod Validation ──▶ Return 400 error              │
│                                                                       │
│  Empty Results                                                      │
│       │                                                              │
│       └─── No Clients Match ──▶ Return empty list, show "No results" │
└─────────────────────────────────────────────────────────────────────┘
```

## 11. COMPLETE USER JOURNEY

```
┌─────────────────────────────────────────────────────────────────────┐
│                     USER JOURNEY - END TO END                          │
└─────────────────────────────────────────────────────────────────────┘

1. USER OPENS CLIENTS PAGE
   │
   ├─▶ Load assignedClientsProvider
   │   └─▶ Fetch from Hive cache (fast)
   │
   └─▶ Display client list

2. USER TAPS FILTER ICON (sliders)
   │
   ├─▶ Open ClientAttributeFilterBottomSheet
   │
   └─▶ Watch clientFilterOptionsProvider
       │
       ├─▶ PowerSync: SELECT DISTINCT queries
       │   └─▶ Parse to enums
       │   └─▶ Sort results
       │
       └─▶ Display filter options in radio buttons

3. USER SELECTS FILTER OPTIONS
   │
   ├─▶ Tap: Client Type → "Potential"
   │
   ├─▶ Tap: Market Type → "Residential"
   │
   ├─▶ Tap: Pension Type → "SSS"
   │
   └─▶ Tap: Product Type → "SSS Pensioner"

4. USER TAPS "APPLY" BUTTON
   │
   ├─▶ Create ClientAttributeFilter object
   │
   ├─▶ Update clientAttributeFilterProvider
   │
   └─▶ Trigger provider rebuild

5. PROVIDER REBUILD TRIGGERS
   │
   ├─▶ assignedClientsProvider rebuilds
   │   └─▶ Apply filters locally (offline-capable)
   │       └─▶ Filter: clientType == POTENTIAL
   │       └─▶ Filter: marketType == RESIDENTIAL
   │       └─▶ Filter: pensionType == SSS
   │       └─▶ Filter: productType == SSS_PENSIONER
   │       └─▶ Apply search + location filters
   │       └─▶ Paginate results
   │
   └─▶ UI rebuilds with filtered clients

6. FILTER CHIPS DISPLAY
   │
   └─▶ ClientFilterChips widget shows:
       ├─▶ "Potential" chip (X button to remove)
       ├─▶ "Residential" chip (X button to remove)
       ├─▶ "SSS" chip (X button to remove)
       ├─▶ "SSS Pensioner" chip (X button to remove)
       └─▶ "Clear all" button

7. USER REMOVES INDIVIDUAL FILTER
   │
   └─▶ Tap X on "Residential" chip
       └─▶ Update clientAttributeFilterProvider
           └─▶ Remove marketType filter
           └─▶ Provider rebuilds
           └─▶ Results update immediately

8. USER TAPS "CLEAR ALL"
   │
   └─▶ Reset clientAttributeFilterProvider to none()
       └─▶ All filters removed
       └─▶ Show all clients (respecting search + location)
```

## 12. BACKEND INTEGRATION FLOW

```
┌─────────────────────────────────────────────────────────────────────┐
│                   BACKEND API INTEGRATION                             │
└─────────────────────────────────────────────────────────────────────┘

MOBILE APP                         BACKEND API
    │                                   │
    │  1. GET /api/clients               │
    │     ?client_type=POTENTIAL         │
    │     &market_type=RESIDENTIAL       │
    │     &pension_type=SSS              │
    │     &product_type=SSS_PENSIONER    │
    │──────────────────────────────────▶│
    │                                   │
    │                          2. VALIDATE (Zod)
    │                          • client_type enum
    │                          • market_type enum
    │                          • pension_type enum
    │                          • product_type enum
    │                                   │
    │                          3. BUILD QUERY
    │                          SELECT * FROM clients c
    │                          WHERE c.client_type = $1
    │                            AND c.market_type = $2
    │                            AND c.pension_type = $3
    │                            AND c.product_type = $4
    │                            AND c.deleted_at IS NULL
    │                                   │
    │                          4. EXECUTE QUERY
    │                          • Parameterized (safe)
    │                          • Paginated (10-100)
    │                                   │
    │  5. RETURN JSON  ◀────────────────│
    │     {                               │
    │       items: [...],                │
    │       page: 1,                     │
    │       totalItems: 150,             │
    │       totalPages: 15               │
    │     }                               │
    │                                   │

VALIDATION SCHEMA (Backend):
┌─────────────────────────────────────────────────────────────────────┐
│  const clientFilterQuerySchema = z.object({                          │
│    client_type: z.enum(['all', 'POTENTIAL', 'EXISTING']),           │
│    market_type: z.enum(['all', 'RESIDENTIAL', 'COMMERCIAL',         │
│                              'INDUSTRIAL']),                         │
│    pension_type: z.enum(['all', 'SSS', 'GSIS', 'PRIVATE', 'NONE']), │
│    product_type: z.enum(['all', 'SSS_PENSIONER', 'GSIS_PENSIONER', │
│                              'PRIVATE']),                             │
│  });                                                                  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## SUMMARY

The client attribute filtering system uses a **multi-layered architecture**:

1. **Data Layer**: PowerSync (local) + API (remote)
2. **State Layer**: Riverpod providers with dependency injection
3. **Service Layer**: Business logic for filtering and fetching
4. **UI Layer**: Widgets for filter selection and display

**Key Features**:
- ✅ **Offline-first**: PowerSync queries work without internet
- ✅ **Fast local filtering**: In-memory AND logic for assigned clients
- ✅ **Server-side filtering**: Reduced data transfer for all clients
- ✅ **Consistent UX**: Title Case labels throughout
- ✅ **Type-safe**: Strong typing with Zod validation
- ✅ **Auto-dispose**: Memory-efficient state management

**Data Flow**: PowerSync → Provider → UI → User Interaction → State Update → Provider Rebuild → UI Update
