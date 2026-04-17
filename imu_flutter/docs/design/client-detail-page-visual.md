# Client Detail Page - Visual Representation

> **Screen Size:** 393 x 852 px (iPhone 13 Pro baseline)
> **Platform:** Flutter Mobile App
> **Date:** 2026-04-17

---

## Screen 1: Initial View (Collapsed State)

```
┌──────────────────────────────────────────────────────┐
│ ← Client Details            ✏️  🗑️  📍               │ [App Bar]
├──────────────────────────────────────────────────────┤
│  ┌───┐                                               │
│  │   │  Juan Dela Cruz                               │
│  └───┘  [Potential] [BFP_ACTIVE]                     │ [Hero Card]
│                                                       │
│  🎂 January 15, 1965 (59 years old)                  │
│  📅 Created: March 1, 2024                           │
│                                                       │
│  [3/7 • visit]  ⭐  📍 Sampaloc, Manila              │
├──────────────────────────────────────────────────────┤
│                                                       │
│   ┌──────────┐  ┌──────────┐  ┌──────────┐          │ [Quick Actions]
│   │ VISIT    │  │TOUCHPOINT│  │ RELEASE  │          │
│   │ ONLY     │  │          │  │ LOAN     │          │
│   └──────────┘  └──────────┘  └──────────┘          │
│                                                       │
├──────────────────────────────────────────────────────┤
│ ▼ CLIENT INFORMATION                     46 fields   │ [Expansion Panel]
├──────────────────────────────────────────────────────┤
│ ▼ CONTACT INFORMATION                    4 sections  │ [Expansion Panel]
├──────────────────────────────────────────────────────┤
│ ▼ CMS VISIT HISTORY                       Read only   │ [Expansion Panel]
├──────────────────────────────────────────────────────┤
│ ▼ TOUCHPOINT HISTORY                      7 steps     │ [Expansion Panel]
├──────────────────────────────────────────────────────┤
│                                                       │
│  (scroll to see more content)                        │
│                                                       │
└──────────────────────────────────────────────────────┘
```

---

## Screen 2: CLIENT INFORMATION Expanded

```
┌──────────────────────────────────────────────────────┐
│ ← Client Details            ✏️  🗑️  📍               │
├──────────────────────────────────────────────────────┤
│  ┌───┐                                               │
│  │   │  Juan Dela Cruz                               │
│  └───┘  [Potential] [BFP_ACTIVE]                     │
│                                                       │
│  🎂 January 15, 1965 (59 years old)                  │
│  📅 Created: March 1, 2024                           │
│                                                       │
│  [3/7 • visit]  ⭐  📍 Sampaloc, Manila              │
├──────────────────────────────────────────────────────┤
│   ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│   │ VISIT    │  │TOUCHPOINT│  │ RELEASE  │          │
│   │ ONLY     │  │          │  │ LOAN     │          │
│   └──────────┘  └──────────┘  └──────────┘          │
├──────────────────────────────────────────────────────┤
│ ▲ CLIENT INFORMATION                     46 fields   │
├──────────────────────────────────────────────────────┤
│                                                    │
│ ╺═ Personal Information                           │ [Subsection]
│    Full Name:      Juan Dela Cruz                  │
│    First Name:     Juan                            │
│    Middle Name:    —                               │
│    Last Name:      Dela Cruz                       │
│    Birth Date:     January 15, 1965                │
│    Age:            59 years old                    │
│                                                    │
│ ╺═ Employment Details                             │
│    Agency Name:     —                              │
│    Department:      —                              │
│    Position:        —                              │
│    Employment Status: —                            │
│    Tenure:          —                              │
│                                                    │
│ ╺═ Classification                                 │
│    Client Type:     Potential                      │
│    Product Type:    BFP_ACTIVE                     │
│    Market Type:     —                              │
│    Pension Type:    —                              │
│                                                    │
│ ╺═ Location                                       │
│    Region:          NCR                            │
│    Province:        Metro Manila                   │
│    Municipality:    Sampaloc                       │
│    Barangay:        —                              │
│                                                    │
│ ╺═ UDI                                            │
│    UDI:             —                              │
│    Account Code:    —                              │
│                                                    │
│ ╺═ Loan Information                               │
│    Loan Released:   No                             │
│    Loan Released At: —                             │
│                                                    │
│ ╺═ Legacy PCNICMS Information                      │
│    Applicable RA:   —                              │
│    Status:          Active                         │
│                                                    │
│ ╺═ System Information                             │
│    Client ID:       123e4567-e89b...               │
│    Assigned User:   Juan Dela Cruz (Agent)         │
│    Is Starred:      Yes                            │
│    Created At:      March 1, 2024                  │
│                                                    │
├──────────────────────────────────────────────────────┤
│ ▼ CONTACT INFORMATION                    4 sections  │
├──────────────────────────────────────────────────────┤
│ ▼ CMS VISIT HISTORY                       Read only   │
├──────────────────────────────────────────────────────┤
│ ▼ TOUCHPOINT HISTORY                      7 steps     │
└──────────────────────────────────────────────────────┘
```

---

## Screen 3: CONTACT INFORMATION Expanded

```
┌──────────────────────────────────────────────────────┐
│ ← Client Details            ✏️  🗑️  📍               │
├──────────────────────────────────────────────────────┤
│  ┌───┐                                               │
│  │   │  Juan Dela Cruz                               │
│  └───┘  [Potential] [BFP_ACTIVE]                     │
│                                                       │
│  🎂 January 15, 1965 (59 years old)                  │
│  📅 Created: March 1, 2024                           │
│                                                       │
│  [3/7 • visit]  ⭐  📍 Sampaloc, Manila              │
├──────────────────────────────────────────────────────┤
│   ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│   │ VISIT    │  │TOUCHPOINT│  │ RELEASE  │          │
│   │ ONLY     │  │          │  │ LOAN     │          │
│   └──────────┘  └──────────┘  └──────────┘          │
├──────────────────────────────────────────────────────┤
│ ▼ CLIENT INFORMATION                     46 fields   │
├──────────────────────────────────────────────────────┤
│ ▲ CONTACT INFORMATION                    4 sections  │
├──────────────────────────────────────────────────────┤
│                                                    │
│ ╺═ Phone Numbers                                  │
│    📱 Primary:  +63 912 345 6789    [📞]  [💬]    │
│    📱 Secondary: +63 912 345 6790    [📞]  [💬]    │
│                                                    │
│    ┌──────────────────────────────────────┐        │
│    │  [+ Add Phone Number]                 │        │
│    └──────────────────────────────────────┘        │
│                                                    │
│ ╺═ Email                                          │
│    ✉️ juan.delacruz@email.com              [📧]    │
│                                                    │
│    ┌──────────────────────────────────────┐        │
│    │  [+ Add Email]                        │        │
│    └──────────────────────────────────────┘        │
│                                                    │
│ ╺═ Addresses                                      │
│    📍 Primary: 123 Main St, Sampaloc, Manila    │
│       NCR                               [🗺️]     │
│                                                    │
│    ┌──────────────────────────────────────┐        │
│    │  [+ Add Address]                      │        │
│    └──────────────────────────────────────┘        │
│                                                    │
│ ╺═ Social Media                                   │
│    🔗 facebook.com/client.name              [🔗]   │
│                                                    │
├──────────────────────────────────────────────────────┤
│ ▼ CMS VISIT HISTORY                       Read only   │
├──────────────────────────────────────────────────────┤
│ ▼ TOUCHPOINT HISTORY                      7 steps     │
└──────────────────────────────────────────────────────┘
```

---

## Screen 4: TOUCHPOINT HISTORY Expanded

```
┌──────────────────────────────────────────────────────┐
│ ← Client Details            ✏️  🗑️  📍               │
├──────────────────────────────────────────────────────┤
│  ┌───┐                                               │
│  │   │  Juan Dela Cruz                               │
│  └───┘  [Potential] [BFP_ACTIVE]                     │
│                                                       │
│  🎂 January 15, 1965 (59 years old)                  │
│  📅 Created: March 1, 2024                           │
│                                                       │
│  [3/7 • visit]  ⭐  📍 Sampaloc, Manila              │
├──────────────────────────────────────────────────────┤
│   ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│   │ VISIT    │  │TOUCHPOINT│  │ RELEASE  │          │
│   │ ONLY     │  │          │  │ LOAN     │          │
│   └──────────┘  └──────────┘  └──────────┘          │
├──────────────────────────────────────────────────────┤
│ ▼ CLIENT INFORMATION                     46 fields   │
├──────────────────────────────────────────────────────┤
│ ▼ CONTACT INFORMATION                    4 sections  │
├──────────────────────────────────────────────────────┤
│ ▼ CMS VISIT HISTORY                       Read only   │
├──────────────────────────────────────────────────────┤
│ ▲ TOUCHPOINT HISTORY                      7 steps     │
├──────────────────────────────────────────────────────┤
│                                                    │
│ ╺═ 7-Step Touchpoint Sequence                      │
│                                                    │
│    ┌────────────────────────────────────────┐     │
│    │ TP1: Visit         ✅ Completed        │     │
│    │ March 1, 2024      Agent: Juan D.     │     │
│    │ Status: Interested                     │     │
│    └────────────────────────────────────────┘     │
│                                                    │
│    ┌────────────────────────────────────────┐     │
│    │ TP2: Call          ✅ Completed        │     │
│    │ March 5, 2024      Agent: Maria S.    │     │
│    │ Status: Undecided                     │     │
│    └────────────────────────────────────────┘     │
│                                                    │
│    ┌────────────────────────────────────────┐     │
│    │ TP3: Call          ⏳ Pending          │     │
│    │ Scheduled: March 10, 2024             │     │
│    └────────────────────────────────────────┘     │
│                                                    │
│    ┌────────────────────────────────────────┐     │
│    │ TP4: Visit         ⏸ Not Started      │     │
│    └────────────────────────────────────────┘     │
│                                                    │
│    ┌────────────────────────────────────────┐     │
│    │ TP5: Call          ⏸ Not Started      │     │
│    └────────────────────────────────────────┘     │
│                                                    │
│    ┌────────────────────────────────────────┐     │
│    │ TP6: Call          ⏸ Not Started      │     │
│    └────────────────────────────────────────┘     │
│                                                    │
│    ┌────────────────────────────────────────┐     │
│    │ TP7: Visit         ⏸ Not Started      │     │
│    └────────────────────────────────────────┘     │
│                                                    │
└──────────────────────────────────────────────────────┘
```

---

## Screen 5: CMS VISIT HISTORY Expanded

```
┌──────────────────────────────────────────────────────┐
│ ← Client Details            ✏️  🗑️  📍               │
├──────────────────────────────────────────────────────┤
│  ┌───┐                                               │
│  │   │  Juan Dela Cruz                               │
│  └───┘  [Potential] [BFP_ACTIVE]                     │
│                                                       │
│  🎂 January 15, 1965 (59 years old)                  │
│  📅 Created: March 1, 2024                           │
│                                                       │
│  [3/7 • visit]  ⭐  📍 Sampaloc, Manila              │
├──────────────────────────────────────────────────────┤
│   ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│   │ VISIT    │  │TOUCHPOINT│  │ RELEASE  │          │
│   │ ONLY     │  │          │  │ LOAN     │          │
│   └──────────┘  └──────────┘  └──────────┘          │
├──────────────────────────────────────────────────────┤
│ ▼ CLIENT INFORMATION                     46 fields   │
├──────────────────────────────────────────────────────┤
│ ▼ CONTACT INFORMATION                    4 sections  │
├──────────────────────────────────────────────────────┤
│ ▲ CMS VISIT HISTORY              Read Only (Legacy)  │
├──────────────────────────────────────────────────────┤
│                                                    │
│ ╺═ Historical CMS Visits (Old System)             │
│                                                    │
│    ┌────────────────────────────────────────┐     │
│    │ 📅 March 15, 2024                     │     │
│    │    Regular Visit                        │     │
│    │    Agent: Juan Dela Cruz                │     │
│    │    Remarks: Client showed interest...  │     │
│    │                                         │     │
│    │    [View Details →]                     │     │
│    └────────────────────────────────────────┘     │
│                                                    │
│    ┌────────────────────────────────────────┐     │
│    │ 📅 March 10, 2024                     │     │
│    │    Release Loan                        │     │
│    │    Agent: Maria Santos                 │     │
│    │    Remarks: Loan approved for...       │     │
│    │                                         │     │
│    │    [View Details →]                     │     │
│    └────────────────────────────────────────┘     │
│                                                    │
│    ┌────────────────────────────────────────┐     │
│    │ 📅 March 5, 2024                      │     │
│    │    Regular Visit                        │     │
│    │    Agent: Juan Dela Cruz                │     │
│    │    Remarks: Follow up visit...          │     │
│    │                                         │     │
│    │    [View Details →]                     │     │
│    └────────────────────────────────────────┘     │
│                                                    │
├──────────────────────────────────────────────────────┤
│ ▼ TOUCHPOINT HISTORY                      7 steps     │
└──────────────────────────────────────────────────────┘
```

---

## Component Detail Views

### App Bar Button States

**Edit Button (✏️):**
- All roles can edit (with restrictions)
- Caravan/Tele: Can edit own clients only
- Managers: Can edit any client in area
- Admin: Can edit any client

**Delete Button (🗑️):**
- Admin only
- Shows confirmation dialog: "Are you sure you want to delete this client?"
- Cannot undo (soft delete with deleted_at timestamp)

**Navigate Button (📍):**
- All roles can view
- Opens map with client location
- Falls back to Google Maps/Waze/Apple Maps

---

### Quick Actions - State Variations

**State 1: All Buttons Enabled (Caravan Role)**
```
┌──────────┐  ┌──────────┐  ┌──────────┐
│ VISIT    │  │TOUCHPOINT│  │ RELEASE  │
│ ONLY     │  │          │  │ LOAN     │
└──────────┘  └──────────┘  └──────────┘
Next: Visit (TP4)
```

**State 2: Call Role (Tele)**
```
┌──────────────────┐  ┌──────────┐
│     TOUCHPOINT   │  │ RELEASE  │
│                  │  │ LOAN     │
└──────────────────┘  └──────────┘
Next: Call (TP3)
Visit Only disabled (not allowed for Tele)
```

**State 3: Loan Already Released**
```
┌──────────┐  ┌────────────────────┐
│ VISIT    │  │  ✅ Loan Released  │
│ ONLY     │  │  (disabled)        │
└──────────┘  └────────────────────┘
Release Loan disabled (already released)
```

**State 4: Cannot Create Touchpoint**
```
┌──────────────────────────────────────────┐
│  ⏸ Wait for Visit (TP1)                 │
│  Cannot create touchpoint yet            │
└──────────────────────────────────────────┘
All buttons disabled
```

---

### Expansion Panel States

**Collapsed (▼):**
- Shows section title
- Shows item count
- Tappable to expand

**Expanded (▲):**
- Shows section title
- Shows all content
- Tappable to collapse

---

## Color Scheme

**Primary Colors:**
- Background: `#FFFFFF` (white)
- Surface: `#F5F5F5` (light gray)
- Primary: `#1976D2` (blue)
- Secondary: `#424242` (dark gray)
- Success: `#4CAF50` (green)
- Warning: `#FF9800` (orange)
- Error: `#F44336` (red)

**Text Colors:**
- Primary: `#212121` (almost black)
- Secondary: `#757575` (medium gray)
- Disabled: `#BDBDBD` (light gray)
- Hint: `#9E9E9E` (very light gray)

**Badge Colors:**
- Potential: `#2196F3` (blue)
- Existing: `#4CAF50` (green)
- BFP_ACTIVE: `#FF9800` (orange)
- BFP_PENSION: `#9C27B0` (purple)
- PNP_PENSION: `#F44336` (red)
- NAPOLCOM: `#00BCD4` (cyan)
- BFP_STP: `#795548` (brown)

---

## Typography

**Font: Inter (Material 3)**

| Usage | Size | Weight | Line Height |
|-------|------|--------|-------------|
| App Bar Title | 20 | Medium | 28 |
| Section Title | 16 | Medium | 24 |
| Subsection Title | 14 | Medium | 20 |
| Body Text | 14 | Regular | 20 |
| Caption | 12 | Regular | 16 |
| Button Text | 14 | Medium | 20 |
| Badge Text | 12 | Medium | 16 |

---

## Spacing

| Element | Size |
|---------|------|
| Screen Padding | 16 |
| Card Padding | 16 |
| Section Spacing | 24 |
| Subsection Spacing | 16 |
| Field Spacing | 8 |
| Button Height | 48 |
| Touch Target | 48x48 minimum |

---

## Icons

**App Bar:**
- Edit: `edit` (Material Icons)
- Delete: `delete` (Material Icons)
- Navigate: `location_on` (Material Icons)

**Quick Actions:**
- Visit Only: `directions_walk` (Material Icons)
- Touchpoint: `assignment` (Material Icons)
- Release Loan: `account_balance` (Material Icons)

**Contact Actions:**
- Call: `phone` (Material Icons)
- SMS: `message` (Material Icons)
- Email: `email` (Material Icons)
- Map: `map` (Material Icons)
- Link: `open_in_new` (Material Icons)

**Status Indicators:**
- Completed: `check_circle` (green)
- Pending: `schedule` (orange)
- Not Started: `radio_button_unchecked` (gray)
- Starred: `star` (yellow)

---

## Touch Targets

All interactive elements meet WCAG AA guidelines:
- **Minimum size:** 48x48 px
- **Recommended size:** 48-56 px
- **Spacing:** 8 px between targets

---

## Responsive Layout

**Mobile (< 600px):**
- Single column layout
- Full-width buttons
- Vertical stacking

**Tablet (600-840px):**
- Two-column layout for fields
- Side-by-side buttons (if space permits)

**Desktop (> 840px):**
- Maximum width: 600px (centered)
- Same layout as mobile (constrained width)

---

**Document Version:** 1.0
**Last Updated:** 2026-04-17
**Related Documents:**
- client-detail-page-redesign.md (Complete specification)
- COMPLETE_SCHEMA.sql (Database schema)
