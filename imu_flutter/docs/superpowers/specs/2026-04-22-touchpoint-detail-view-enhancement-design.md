# Touchpoint Detail View Enhancement

**Date:** 2026-04-22
**Status:** Draft
**Author:** Claude
**Related Files:**
- `lib/shared/widgets/touchpoint_history_dialog.dart`

---

## Overview

Enhance the touchpoint detail view (displayed when user taps "View Details" on a touchpoint) to show:
1. **Photo** - Display captured photo at the bottom of the view
2. **Location address** - Show the GPS-captured address (without coordinates)

Current implementation shows status, reason, remarks, GPS coordinates, and timestamps. This enhancement adds photo display and simplifies location display to address-only.

---

## Layout Structure

### Modal Bottom Sheet
- Height: 60% of screen height
- Background: White with rounded top corners
- Draggable handle at top

### Content Sections (Top to Bottom)

1. **Header**
   - Touchpoint number icon (mapPin for Visit, phone for Call)
   - "Touchpoint #N"
   - Type • Date (e.g., "Visit • Jan 15, 2026")
   - Close button (X)

2. **Status Section**
   - Icon: `badgeCheck`
   - Label: "Status"
   - Value: Touchpoint status (Interested, Undecided, Not Interested, Completed)

3. **Reason Section**
   - Icon: `messageCircle`
   - Label: "Reason"
   - Value: Touchpoint reason (e.g., "Follow Up")

4. **Location Section** (NEW LABEL, SIMPLIFIED)
   - Icon: `mapPin`
   - Label: "Location"
   - Value: GPS address from `timeInGpsAddress` or `address` field
   - **Note:** No coordinates displayed. No Time In/Out labels.
   - If no address: Show "(No location data)" or skip section

5. **Remarks Section**
   - Icon: `alignLeft`
   - Label: "Remarks"
   - Value: Touchpoint remarks text
   - Only shown if remarks exist and are not empty

6. **Photo Section** (NEW)
   - Positioned at BOTTOM of content
   - Full-width image (rounded corners)
   - Height: 200px (aspect-ratio preserved)
   - If photo exists: Display from `photoPath`
   - If no photo: Show placeholder box with camera icon

---

## Data Fields Used

| Field | Source | Description |
|-------|--------|-------------|
| `touchpointNumber` | Touchpoint | Display number (1st, 2nd, 3rd...) |
| `type` | Touchpoint | Visit or Call |
| `date` | Touchpoint | Date of touchpoint |
| `status` | Touchpoint | Client interest status |
| `reason` | Touchpoint | Touchpoint reason |
| `address` | Touchpoint | Legacy address field |
| `timeInGpsAddress` | Touchpoint | GPS-captured address at Time In |
| `timeOutGpsAddress` | Touchpoint | GPS-captured address at Time Out |
| `remarks` | Touchpoint | Notes from visit/call |
| `photoPath` | Touchpoint | Path to captured photo |

---

## Display Logic

### Location Address Priority
1. First priority: `timeInGpsAddress` (most accurate, GPS-captured)
2. Fallback: `address` field (legacy, manually entered)
3. If both empty: Skip section or show "(No location data)"

### Photo Display
- If `photoPath` is not null/empty:
  - Display image using `Image.file()` or `Image.network()` depending on path
  - Full width, rounded corners, max height 200px
- If `photoPath` is null/empty:
  - Show placeholder container:
    - Gray background (`Colors.grey[200]`)
    - Camera icon centered (`LucideIcons.camera`, gray)
    - "No photo" text below icon

### Remarks Display
- Only show if `remarks` is not null AND not empty
- Skip entire section if no remarks

---

## Components

### `_TouchpointHistoryItem._showTouchpointDetails()`

**Current implementation** (lines 496-640):
```dart
void _showTouchpointDetails(BuildContext context, Touchpoint touchpoint) {
  showModalBottomSheet(
    // Current implementation shows:
    // - Status, Reason, Remarks
    // - Address (legacy field)
    // - GPS Location (coordinates)
    // - Time In/Out
  );
}
```

**Modified implementation**:
- Keep modal structure
- Reorganize sections
- Add photo section at bottom
- Simplify location to address-only

---

## UI Specifications

### Colors
- Background: `Colors.white`
- Header text: `Colors.grey[800]` (18pt, bold)
- Subheader text: `Colors.grey[600]` (14pt)
- Section icons: `Colors.grey[700]` (16pt)
- Section labels: `Colors.grey[600]` (12pt)
- Section values: `Colors.black` (14pt, 500 weight)
- Photo placeholder: `Colors.grey[200]`

### Spacing
- Section padding: 16px horizontal
- Vertical spacing between sections: 16px
- Photo container: 16px horizontal padding, 8px top padding
- Photo height: 200px max
- Border radius: 8px for photo

### Icons (LucideIcons)
- Status: `badgeCheck`
- Reason: `messageCircle`
- Location: `mapPin`
- Remarks: `alignLeft`
- Camera placeholder: `camera`

---

## Error Handling

1. **Photo loading fails**: Show placeholder box with "Unable to load photo"
2. **Invalid path**: Treat as no photo, show placeholder
3. **Network photo**: Use `Image.network()` with error builder

---

## Testing Checklist

- [ ] Detail view opens correctly from "View Details" button
- [ ] Status displays correctly for all statuses
- [ ] Reason displays correctly for all reasons
- [ ] Location shows GPS address when available
- [ ] Location falls back to legacy address when GPS unavailable
- [ ] Location section hidden when no address data
- [ ] Photo displays when `photoPath` exists
- [ ] Photo placeholder shows when no photo
- [ ] Photo aspect ratio preserved
- [ ] Remarks shown when present
- [ ] Remarks hidden when empty
- [ ] Modal closes with X button
- [ ] Modal closes with drag-down gesture
- [ ] Works for Visit touchpoints
- [ ] Works for Call touchpoints
- [ ] Works with legacy data (no GPS addresses, no photos)
- [ ] Works with new data (GPS addresses, photos)

---

## Implementation Notes

1. **Photo file loading**: Determine if photos are stored locally or on server
   - Check existing photo display code in app for pattern
   - May need to use `Image.file()` for local, `Image.network()` for remote

2. **Address field deprecation**: The legacy `address` field is replaced by GPS addresses
   - Use as fallback only
   - Consider future deprecation

3. **Time In/Out removal**: Current implementation shows Time In/Out timestamps
   - This design removes those for simplicity
   - Add back later if users request it

---

## Future Enhancements (Out of Scope)

- Tap photo to expand to full screen
- Long-press photo to save/share
- Navigation button to open address in maps
- Display Time In/Out timestamps
- Audio playback (audioPath field exists)
- Edit touchpoint from detail view
- Delete touchpoint from detail view

---

## Files to Modify

1. `lib/shared/widgets/touchpoint_history_dialog.dart`
   - Modify `_showTouchpointDetails()` method
   - Add photo display widget
   - Simplify location display logic

---

## Related Documentation

- `CLAUDE.md` - Project context and patterns
- `docs/deep-analysis-on-project.md` - Full project architecture
- `lib/features/clients/data/models/client_model.dart` - Touchpoint model
