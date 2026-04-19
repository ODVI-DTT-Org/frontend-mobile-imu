# Unified Recording Bottom Sheets Design Spec

**Date:** 2026-04-19
**Status:** Approved for Implementation
**Scope:** Flutter mobile app (`imu_flutter/`)

---

## Overview

Redesign the three recording bottom sheets — Record Touchpoint, Record Visit, Record Loan Release — into a unified, modern design inspired by the Grab app. All three sheets share a common base widget and visual language, differing only in their field sets.

## Goals

1. Unified visual design across all three recording bottom sheets
2. Modern Grab-style grouped card sections
3. Complete field validation with red borders and disabled submit
4. GPS location required on all three sheets
5. Fix Record Visit to have editable Reason and Status fields (was incorrectly locked)

## Non-Goals

- Changing the backend API or data models
- Redesigning any screens outside these three bottom sheets
- Adding new touchpoint types or reasons

---

## Architecture: Approach B — Shared Base + Three Thin Sheets

Create a new `UnifiedActionBottomSheet` base widget that owns:
- Header (drag handle, action title, client info)
- Card layout engine
- Validation engine (submit-attempted flag, error state)
- GPS acquisition
- Submit button (disabled/enabled/loading states)
- Keyboard-safe scrollable content area

Each of the three sheets is a thin wrapper (~80 lines) that declares only its specific fields and form data.

### File Structure

```
lib/features/record_forms/presentation/widgets/
├── unified_action_bottom_sheet.dart     ← new base widget
├── record_touchpoint_bottom_sheet.dart  ← refactored thin wrapper
├── record_visit_bottom_sheet.dart       ← refactored thin wrapper
└── record_loan_release_bottom_sheet.dart← refactored thin wrapper

lib/features/record_forms/presentation/widgets/shared/
├── schedule_card.dart                   ← Time In/Out + Odometer fields
├── location_card.dart                   ← GPS status card
├── details_card.dart                    ← Reason + Status dropdowns
├── notes_card.dart                      ← Remarks field
├── photo_card.dart                      ← Camera capture + thumbnail
└── loan_details_card.dart               ← Product Type, Loan Type, UDI (release only)
```

### Files Replaced / Deleted

The following old files in `lib/features/clients/presentation/widgets/` are replaced by the new wrappers above and must be deleted:
- `record_touchpoint_bottom_sheet.dart` → replaced
- `record_visit_only_bottom_sheet.dart` → replaced (note: renamed, "only" dropped)
- `record_loan_release_bottom_sheet.dart` → replaced
- `client_action_bottom_sheet.dart` → replaced by `unified_action_bottom_sheet.dart`

All call sites that `showModalBottomSheet` the old widgets must be updated to point to the new widgets.

---

## Section 1: Shared Base Structure

### Header
```
▬▬▬▬▬▬▬                    ← drag handle, centered, 48px top margin
[Icon] [Action Title]        ← e.g. "📋 Record Touchpoint"
[Client Full Name]           ← 18px, w600, slate-900
[Pension Type · TP # of 7]  ← 13px, grey-600
─────────────────────────── ← divider
```

- Action title changes per sheet (📋 Touchpoint / 🏠 Visit / 💰 Loan Release)
- Touchpoint context shows "Touchpoint N of 7" for touchpoint and visit sheets
- Loan Release shows "Touchpoint 7 of 7" (always final touchpoint)

### Layout
- Sheet max height: 92% of screen (`isScrollControlled: true`)
- Content: `SingleChildScrollView` with padding
- Cards: 16px horizontal padding, 12px vertical padding, 12px border radius
- Fields: 48px height minimum (WCAG touch target), 8px border radius
- Card section labels: 12px, w500, grey-600, uppercase

### Keyboard Handling
- `isScrollControlled: true` on `showModalBottomSheet`
- Content area padding = `MediaQuery.of(context).viewInsets.bottom`
- Focused field auto-scrolls into view
- Submit button always pinned above keyboard

### Submit Button
```
Disabled (grey):  all fields not yet filled — shown from the start
Enabled (green):  all required fields valid
Loading:          ⟳ spinner, green background, non-interactive
```

---

## Section 2: The Three Sheets

### Sheet 1 — Record Touchpoint

**Cards in order:**
1. SCHEDULE — Time In*, Time Out*, Odometer Arrival*, Odometer Departure*
2. LOCATION — GPS (auto-captured, required)
3. DETAILS — Reason* (editable, 28 options), Status* (editable)
4. NOTES — Remarks* (multiline, required)
5. PHOTO — Camera capture* (required, thumbnail after capture)

**Submit label:** "Record Touchpoint"

**Auto-calculations (UX convenience, not locked):**
- Time Out defaults to Time In + 5 minutes when Time In is set
- Odometer Departure defaults to Arrival + 5 km when Arrival is entered

---

### Sheet 2 — Record Visit

**Cards in order:**
1. SCHEDULE — Time In*, Time Out*, Odometer Arrival*, Odometer Departure*
2. LOCATION — GPS (auto-captured, required)
3. DETAILS — Reason* (editable), Status* (editable)
4. NOTES — Remarks* (multiline, required)
5. PHOTO — Camera capture* (required, thumbnail after capture)

**Submit label:** "Record Visit"

**Important:** Reason and Status are fully editable — this corrects the previous implementation where they were locked to "Client Not Available" / "Incomplete".

---

### Sheet 3 — Record Loan Release

**Cards in order:**
1. SCHEDULE — Time In*, Time Out*, Odometer Arrival*, Odometer Departure*
2. LOCATION — GPS (auto-captured, required)
3. LOAN DETAILS — Product Type* (editable), Loan Type* (editable), UDI Number* (numeric, required)
4. DETAILS — Reason (locked: "New Loan Release" 🔒), Status (locked: "Completed" 🔒)
5. NOTES — Remarks* (multiline, required)
6. PHOTO — Camera capture* (required, thumbnail after capture)

**Submit label:** "Record Loan Release"

**Locked fields:** Reason and Status are greyed-out dropdowns with a 🔒 icon. Non-interactive. Values always submitted as "New Loan Release" and "Completed".

---

## Section 3: Validation

### Strategy — Hybrid
- Submit button disabled from the start (grey) until all required fields are filled
- No red borders shown until user taps Submit at least once
- After first submit tap: red borders appear on all empty required fields and stay live
- As user fills each field: its red border clears immediately
- Submit button enables only when all required fields are valid

### Field Error Display
```
Field label
┌──────────────────────────┐  ← red border (2px, #EF4444)
│  ⚠ Required              │
└──────────────────────────┘
⚠ [Field name] is required    ← error text, 12px, red, below field
```

### GPS States
```
Acquiring:  📍 ⟳ Acquiring location...   (grey, non-blocking)
Acquired:   📍 ✅ 14.5995°N, 120.9842°E  (green)
            Brgy. Poblacion, Manila
Failed:     📍 ❌ GPS Unavailable         (red background card)
            Location access is required
            [ Enable Location Settings ]  ← opens app settings
```

GPS failure is a hard block — submit button stays disabled even if all other fields are filled. The "Enable Location Settings" button opens `openAppSettings()` from the `permission_handler` package.

### Photo States
```
Before capture:  [ 📷  Take Photo * ]         ← grey border
After capture:   ┌──────┬──────────────────┐
                 │ [img]│ ✅ Photo Captured │
                 │ 64px │ Tap to retake    │
                 └──────┴──────────────────┘  ← green border
Error state:     [ 📷  Take Photo * ]         ← red border + error text
```

---

## Color Reference

| Token          | Hex       | Usage                          |
|----------------|-----------|--------------------------------|
| Primary        | #0F172A   | Client name, body text         |
| Grey-600       | #64748B   | Labels, secondary text         |
| Border-default | #E5E7EB   | Field borders (unfilled)       |
| Error          | #EF4444   | Red borders, error text        |
| Success        | #22C55E   | Submit enabled, GPS acquired   |
| Green-50       | #F0FDF4   | Photo captured background      |
| Green-600      | #16A34A   | Photo captured icon/text       |
| Locked-bg      | #F9FAFB   | Greyed-out locked field bg     |
| Locked-text    | #9CA3AF   | Greyed-out locked field text   |

---

## GPS Data Captured

GPS is captured once when the bottom sheet opens. The single snapshot is stored as both Time In and Time Out GPS coordinates (same location for simplicity).

Fields populated:
- `timeInGpsLat`, `timeInGpsLng`, `timeInGpsAddress`
- `timeOutGpsLat`, `timeOutGpsLng`, `timeOutGpsAddress`

Uses `geolocator` package (already in pubspec) with `LocationAccuracy.high`.
