# Figma Screen Alignment - Vertical Slice Plan

This document outlines the vertical slices needed to align four screens with the Figma wireframe designs.

---

## Phase 1: Agencies Screen

### Current State
- Simple list view with search
- No tabs for filtering
- No "Add Prospect Agency" button

### Target State (Per Figma)
- Header with centered title "Agencies"
- Tab list: "Open Agencies", "For Implementation", "For Reimplementation"
- "Add Prospect Agency" button (floating or in header)
- Agency cards with proper styling

### Vertical Slices

| Slice | Description | Est. Time |
|-------|-------------|-----------|
| 1.1 | Add header with centered "Agencies" title and back navigation | 30 min |
| 1.2 | Add 3 tabs (Open Agencies, For Implementation, For Reimplementation) with pill-style design | 45 min |
| 1.3 | Add "Add Prospect Agency" FAB or header button | 20 min |
| 1.4 | Update agency card design to match Figma (add status badges) | 30 min |
| 1.5 | Add agency status field to model and filter logic | 30 min |

**Total: ~3 hours**

---

## Phase 2: My Day Screen

### Current State
- Has summary card with progress circle
- Task cards grouped by status (In Progress, Pending, Completed)
- Call modal for call tasks

### Target State (Per Figma - Node 973:3620)
Based on Figma analysis:
- Clean header with date display
- Task progress/summary section
- Task list organized by time or priority
- Quick action buttons

### Vertical Slices

| Slice | Description | Est. Time |
|-------|-------------|-----------|
| 2.1 | Redesign header to match Figma (centered title, date format) | 20 min |
| 2.2 | Redesign summary card layout and styling | 45 min |
| 2.3 | Update task card design to match Figma specifications | 1 hour |
| 2.4 | Add quick action buttons/shortcuts | 30 min |
| 2.5 | Update empty state design | 20 min |

**Total: ~3 hours**

---

## Phase 3: Itinerary Screen

### Current State
- Has date picker with pill tabs (Yesterday/Today/Tomorrow)
- Visit cards with client info

### Target State (Per Figma - Node 973:3619)
Based on Figma analysis:
- Header with date navigation
- Day-by-day itinerary view
- Visit/meeting cards with detailed info
- Time-based organization

### Vertical Slices

| Slice | Description | Est. Time |
|-------|-------------|-----------|
| 3.1 | Redesign header to match Figma (centered title, calendar button) | 20 min |
| 3.2 | Update date tab styling to match Figma | 30 min |
| 3.3 | Redesign visit card layout and content | 1 hour |
| 3.4 | Add visit status indicators and badges | 30 min |
| 3.5 | Update empty state for no visits | 20 min |

**Total: ~3 hours**

---

## Phase 4: Call Screen

### Current State
- Has call log list with filter tabs (All, Outgoing, Incoming, Missed)
- Shows call details with duration

### Target State (Per User Request)
- Tab list: "Client Contacts" and "Call Logs"
- Client Contacts tab: List of client contacts to call
- Call Logs tab: Current call history view

### Vertical Slices

| Slice | Description | Est. Time |
|-------|-------------|-----------|
| 4.1 | Add top-level tabs (Client Contacts / Call Logs) | 30 min |
| 4.2 | Create Client Contacts tab content with client list | 1 hour |
| 4.3 | Move existing call log to "Call Logs" tab | 20 min |
| 4.4 | Add quick-call functionality to client contacts | 30 min |
| 4.5 | Update styling to match other screens | 30 min |

**Total: ~3 hours**

---

## Implementation Order

1. **Agencies Screen** (Phase 1) - Smallest changes, quick win
2. **Call Screen** (Phase 4) - Clear requirements, straightforward
3. **Itinerary Screen** (Phase 3) - Medium complexity
4. **My Day Screen** (Phase 2) - Most complex redesign

---

## Design Specifications (Common)

### Colors
- Primary: `#0F172A` (dark navy)
- Background: `#FFFFFF` (white)
- Card Border: `Colors.grey.shade200`
- Success: `#22C55E` (green)
- Warning: `#F59E0B` (amber)
- Error: `#EF4444` (red)

### Typography
- Header Title: 18px, FontWeight.w600
- Section Headers: 16px, FontWeight.w600
- Body Text: 14px, FontWeight.normal
- Caption: 12px, FontWeight.normal
- Labels/Badges: 10-12px, FontWeight.w500

### Spacing
- Screen padding: 17px horizontal (mobile), 32px (tablet)
- Card margin: 12px bottom
- Card padding: 16px
- Section spacing: 16-24px

### Tab Style (Pill)
- Selected: Dark background (#0F172A), white text
- Unselected: Light gray background, gray text
- Border radius: 8px
- Padding: 10px vertical

---

## Next Steps

Please review this plan and let me know:
1. Which phase to start with?
2. Any specific design details from Figma I should focus on?
3. Should I proceed slice by slice with verification after each?
