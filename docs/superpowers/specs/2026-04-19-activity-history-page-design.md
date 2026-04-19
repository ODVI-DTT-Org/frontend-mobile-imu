# Activity History Page — Design Spec

**Date:** 2026-04-19
**Status:** Approved
**Scope:** Flutter mobile app only

---

## Overview

A new "My Activity" page giving field agents a full chronological feed of everything they have done — touchpoints created, visits logged, calls logged, and approval submissions (client add/edit/delete, address changes, phone changes, loan releases). Users can see the status of each action (pending, completed, approved, rejected, failed, syncing) and filter by activity type and date range.

---

## Entry Point

A new 8th tile on the home grid:

```
Icon:  LucideIcons.history
Label: My Activity
Route: /activity
```

No bottom navigation changes. The existing `PendingApprovalsPage` (currently unnavigable) is retired — its functionality is superseded by this page with the Approvals type filter active.

---

## Data Sources

All data is read from local SQLite via PowerSync — fully offline capable. No new backend endpoints required.

| Activity Type | Table | Key fields used |
|---|---|---|
| Touchpoint created | `touchpoints` | `user_id`, `created_at`, `type`, `reason`, `touchpoint_number`, `client_id` |
| Visit logged | `visits` | `user_id`, `created_at`, `source`, `client_id` |
| Call logged | `calls` | `user_id`, `created_at`, `type`, `client_id` |
| Approval submitted | `approvals` | `user_id`, `type`, `status`, `reason`, `created_at`, `client_id` |

**Approval subtypes (all from `approvals` table):**

| Subtype | `type` | `reason` |
|---|---|---|
| Add client | `client` | `Client Creation Request` |
| Edit client | `client` | `Client Edit Request` |
| Delete client | `client_delete` | `Client Deletion Request` |
| Add address | `address_add` | — |
| Edit address | `address_edit` | — |
| Delete address | `address_delete` | — |
| Add phone | `phone_add` | — |
| Edit phone | `phone_edit` | — |
| Delete phone | `phone_delete` | — |
| Loan release | `loan_release` / `loan_release_v2` | — |

**Status resolution:**
- Approvals → use `approvals.status` column: `pending` / `approved` / `rejected`
- Touchpoints, visits, calls → check PowerSync pending upload queue:
  - Row still in queue → `syncing`
  - Row errored in queue → `failed`
  - Otherwise → `completed`

---

## Unified Data Model

```dart
enum ActivityType { approval, touchpoint, visit, call }

enum ActivityStatus { pending, syncing, completed, approved, rejected, failed }

enum ActivitySubtype {
  // Approvals
  clientCreate,
  clientEdit,
  clientDelete,
  addressAdd,
  addressEdit,
  addressDelete,
  phoneAdd,
  phoneEdit,
  phoneDelete,
  loanRelease,
  // Touchpoints
  touchpointVisit,
  touchpointCall,
  // Visits / Calls
  visit,
  call,
}

class ActivityItem {
  final String id;
  final ActivityType type;
  final ActivitySubtype subtype;
  final String? clientName;   // resolved via JOIN on local clients table
  final String? detail;       // e.g. "Touchpoint #3 • Visit", rejection reason
  final ActivityStatus status;
  final DateTime createdAt;
}
```

---

## UI Structure

### AppBar
```
← My Activity                    [filter icon]
```
Filter icon opens a right-side sheet.

### Active filter chips (below AppBar, only shown when filters are active)
```
[Approvals ×]  [Last 7 days ×]
```
Each chip is dismissible (tapping × resets that filter to default). Chips only appear for **non-default** selections — "All types" and "Last 7 days" do not produce chips since they are the default state.

### Feed
Flat chronological list, most recent first, grouped by date header ("Today", "Yesterday", "Mon Apr 14", etc.).

**Activity card:**
```
┌──────────────────────────────────────┐
│ [icon]  Add Client          2h ago   │
│         Juan dela Cruz               │
│         Client Creation Request      │
│                           [PENDING]  │
└──────────────────────────────────────┘
```

- **Icon** — type-specific Lucide icon (phone, map-pin, user-plus, pencil, trash, file-text, etc.)
- **Title** — human-readable action + client name
- **Subtitle** — reason or detail line
- **Timestamp** — relative time ("2h ago", "Yesterday 3:42 PM")
- **Status badge** — color-coded pill:
  - 🟡 `PENDING` — amber
  - 🔵 `SYNCING` — blue
  - 🟢 `COMPLETED` / `APPROVED` — green
  - 🔴 `REJECTED` / `FAILED` — red

### Load more
```
[ Load 7 more days ]
```
Button at the bottom of the list. Extends the date window by 7 days and re-queries.

### Empty state
Shown when no activity matches the current filters within the date window.

---

## Filter Side Sheet

Slides in from the right. Contains two sections:

**Activity Type** (single-select radio):
- All (default)
- Approvals
- Touchpoints
- Visits
- Calls

**Date Range** (single-select radio):
- Last 7 days (default)
- Today only
- Last 30 days
- Custom range → inline date range picker (from / to)

Actions at the bottom: `[Clear]` `[Apply]`

---

## State Management

**New provider: `activityFeedProvider`** — `StateNotifier<ActivityFeedState>`

```dart
class ActivityFeedState {
  final List<ActivityItem> items;
  final bool isLoading;
  final String? error;
  final DateTimeRange dateRange;  // default: last 7 days
  final ActivityType? typeFilter; // null = All
  final bool hasMore;
}
```

**`ActivityRepository`** — handles raw SQLite queries, one method per table, each using a LEFT JOIN on the local `clients` table to resolve `clientName`. Results merged and sorted by the notifier. Injected into the notifier.

**Data flow:**
1. On page open, notifier queries 4 tables filtered by `dateRange` and `typeFilter`
2. Results merged into single list sorted by `createdAt` DESC
3. PowerSync queue checked for sync status of non-approval rows
4. `loadMore()` extends `dateRange` by 7 days and re-queries
5. Filters applied via `applyFilters(type, dateRange)` which triggers a fresh query

---

## File Structure

```
lib/features/activity/
  data/
    models/activity_item.dart
    repositories/activity_repository.dart
  presentation/
    pages/activity_page.dart
    widgets/activity_card.dart
    widgets/activity_filter_sheet.dart
  providers/
    activity_feed_provider.dart
```

---

## Integration Changes

| File | Change |
|---|---|
| `lib/core/router/app_router.dart` | Add `/activity` route → `ActivityPage` |
| `lib/features/home/presentation/pages/home_page.dart` | Add 8th grid tile: history icon, "My Activity", `/activity` |
| `lib/features/approvals/presentation/pages/pending_approvals_page.dart` | Delete — superseded |

---

## Implementation-Time Verification

Before implementing the repository queries, verify:
- **`approvals` in PowerSync publication** — check migration `081_add_tables_to_powersync_publication.sql` confirms `approvals` is published to caravan/tele devices. If not, a new migration is needed before approval items can appear in the feed.
- **PowerSync pending queue API** — confirm the Flutter PowerSync SDK exposes a way to query pending/failed upload rows (e.g. `db.getAll('SELECT * FROM ps_crud WHERE ...')`). If not, syncing/failed status falls back to always showing "completed" for non-approval items.

---

## Out of Scope

- Tapping a card to open the original record (future slice)
- Push notifications for approval status changes (separate feature)
- Admin view of other users' activity (admin dashboard, not this page)
- Retry failed actions from this page (future slice)
