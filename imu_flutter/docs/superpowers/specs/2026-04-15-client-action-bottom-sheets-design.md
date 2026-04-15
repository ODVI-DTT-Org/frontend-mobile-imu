# Client Action Bottom Sheets Design

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Redesign Record Touchpoint, Record Visit Only, and Record Loan Release bottom sheets with compact, modern Material 3 styling and remove loan release validation restrictions.

**Architecture:** Replace existing bottom sheet widgets with new compact auto-height designs using Material 3 components and efficient 2-column layouts.

**Tech Stack:** Flutter 3.19+, Material 3, Riverpod

---

## Overview

This redesign focuses on three client action bottom sheets in the client detail page:
1. **Record Touchpoint** - Full touchpoint recording with all fields
2. **Record Visit Only** - Simplified visit tracking with auto-set reason/status
3. **Record Loan Release** - Loan release with product/loan type selection

## Requirements

### Functional Requirements

1. **Remove loan release validation restrictions:**
   - Allow "Record Visit Only" when loan is released
   - Allow "Release Loan" when loan is already released (additional releases)
   - Keep "Record Touchpoint" disabled when loan is released

2. **Implement auto-height bottom sheets:**
   - Minimum height: 40% of screen
   - Maximum height: 80% of screen
   - Content-based sizing with `isScrollControlled: true`

3. **Compact, modern design:**
   - Tight spacing (8-12px padding vs 16-24px)
   - Small typography (12-14px vs 16-18px)
   - 2-column layout for time and odometer fields
   - No close button in header (tap outside/swipe down to dismiss)

### Field Requirements

#### Record Touchpoint
- **Time In/Out:** Time picker (2-column layout)
- **Odometer Arrival/Departure:** Number input (2-column layout)
- **Reason:** Dropdown selector
- **Status:** Dropdown selector
- **Remarks:** Multi-line text input
- **Photo:** Camera capture button

#### Record Visit Only
- **Time In/Out:** Time picker (2-column layout)
- **Odometer Arrival/Departure:** Number input (2-column layout)
- **Photo:** Camera capture button
- **Reason:** Auto-set to "Client not available" (read-only badge)
- **Status:** Auto-set to "Incomplete" (read-only badge)

#### Record Loan Release
- **Time In/Out:** Time picker (2-column layout)
- **Odometer Arrival/Departure:** Number input (2-column layout)
- **Product Type:** Dropdown (PUSU, LIKA, SUB2K)
- **Loan Type:** Dropdown (NEW, ADDITIONAL, RENEWAL, PRETERM)
- **UDI Number:** Text input
- **Remarks:** Multi-line text input
- **Photo:** Camera capture button
- **Reason:** Auto-set to "New Loan Release" (read-only badge)
- **Status:** Auto-set to "Completed" (read-only badge)

## Design Specifications

### Typography Scale
- **Header (Client Name):** 16px semi-bold
- **Header (Pension Type):** 12px regular
- **Field Labels:** 12px medium (gray-600)
- **Field Values:** 14px regular
- **Button Text:** 14px semi-bold
- **Badge Text:** 11px medium

### Spacing & Layout
- **Horizontal Padding:** 12px
- **Vertical Section Spacing:** 8px
- **Field Spacing:** 4px
- **Button Height:** 48px
- **Input Field Height:** 40px
- **Border Radius (Sheet):** 12px top corners
- **Border Radius (Inputs):** 4px

### Color Scheme (Material 3)
- **Primary Color:** App brand color
- **Surface:** White (dark mode: gray-900)
- **Input Background:** Light gray (dark mode: gray-800)
- **Input Border:** Gray-300 (dark mode: gray-700)
- **Badge Background:** Green-100 (green: #dcfce7)
- **Badge Text:** Green-800 (green: #166534)
- **Submit Button:** Primary filled button

### Component Structure

#### Header (Minimal)
```
Container (12px padding)
├── Drag Handle (40px width, 4px height)
├── Client Name (16px semi-bold)
└── Pension Type (12px regular, gray-600)
```

#### Form Fields (2-Column Layout)
```
Row (MainAxisAlignment.spaceBetween)
├── Time In (Flexible)
│   ├── Label (12px)
│   └── TimePickerButton (40px height)
└── Time Out (Flexible)
    ├── Label (12px)
    └── TimePickerButton (40px height)
```

#### Auto-Set Badges
```
Container (Padding: 4px horizontal, 8px vertical)
├── Background: Green-100
├── Border Radius: 4px
└── Text: Green-800, 11px medium
```

## Implementation Components

### 1. ClientActionBottomSheet Base Widget
```dart
class ClientActionBottomSheet extends StatelessWidget {
  final String clientName;
  final String pensionType;
  final Widget content;
  final String submitButtonText;
  final VoidCallback onSubmit;
  final bool isSubmitting;
}
```

### 2. RecordTouchpointBottomSheet
```dart
class RecordTouchpointBottomSheet extends HookWidget {
  final Client client;
  final Future<bool> Function(Map<String, dynamic>) onSubmit;
}
```

### 3. RecordVisitOnlyBottomSheet
```dart
class RecordVisitOnlyBottomSheet extends HookWidget {
  final Client client;
  final Future<bool> Function(Map<String, dynamic>) onSubmit;
}
```

### 4. RecordLoanReleaseBottomSheet
```dart
class RecordLoanReleaseBottomSheet extends HookWidget {
  final Client client;
  final Future<bool> Function(Map<String, dynamic>) onSubmit;
}
```

## Data Flow

### User Flow
1. User taps action button in client detail page
2. Bottom sheet slides up (auto-height)
3. User fills in required fields
4. User taps submit button
5. Form validation occurs
6. Data submitted to API
7. Bottom sheet closes
8. Success notification shown
9. Client data refreshed

### Validation Flow
- **Time In/Out:** Validate Time Out > Time In
- **Odometer:** Validate Departure > Arrival
- **Photo:** Optional for Visit Only, required for Touchpoint/Loan Release
- **UDI Number:** Required for Loan Release, format validation

## Success Criteria

### Functional
- ✅ Bottom sheets work when loan is released (except Record Touchpoint)
- ✅ Auto-height sizing works correctly (40%-80%)
- ✅ Form validation prevents invalid submissions
- ✅ Photo capture integrates with camera
- ✅ API submission handles success/error states

### UX/UI
- ✅ Compact design feels modern and efficient
- ✅ 2-column layout saves vertical space
- ✅ Touch targets are 48px minimum
- ✅ Text is readable at 12-14px
- ✅ Auto-set badges are clearly visible
- ✅ Loading states are shown during submission

### Performance
- ✅ Bottom sheets open within 100ms
- ✅ Form submission completes within 2s
- ✅ Photo capture doesn't block UI

## Edge Cases

### Loan Released State
- **Record Touchpoint:** Show disabled state, tap shows error notification
- **Record Visit Only:** Allow, show normal bottom sheet
- **Release Loan:** Allow, show normal bottom sheet for additional releases

### Form Validation Errors
- Time Out before Time In → Show inline error
- Odometer Departure before Arrival → Show inline error
- Missing required fields → Disable submit button
- Network errors → Show error notification, keep sheet open

### Photo Capture
- Camera permission denied → Show error with settings link
- Photo capture fails → Show error notification, keep sheet open
- Photo too large → Compress automatically before upload

## Testing Requirements

### Unit Tests
- Form validation logic
- Auto-set badge display logic
- 2-column layout responsiveness

### Widget Tests
- Bottom sheet renders correctly
- Form fields accept input
- Submit button enables/disables correctly
- Auto-set badges display correctly

### Integration Tests
- Complete form submission flow
- Photo capture integration
- API submission with real data
- Error handling and recovery

---

## Migration Notes

### Breaking Changes
- Existing bottom sheet widgets will be completely replaced
- Quick action button handlers need validation updates

### Backward Compatibility
- No API changes needed
- Existing touchpoint/visit data structure unchanged

---

**Next Steps:**
1. Implement ClientActionBottomSheet base widget
2. Create three specialized bottom sheet widgets
3. Update client detail page validation logic
4. Add comprehensive tests
5. Test on real devices with camera access
