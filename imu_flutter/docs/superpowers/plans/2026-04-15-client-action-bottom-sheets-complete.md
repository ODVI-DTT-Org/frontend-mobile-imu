# Client Action Bottom Sheets - Complete Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement compact, modern Material 3 bottom sheets for Record Touchpoint, Record Visit Only, and Record Loan Release with auto-height sizing, 2-column layouts, and complete form validation.

**Architecture:** Create reusable base bottom sheet widget with shared form components, implement three specialized bottom sheets using flutter_hooks for state management, integrate with existing touchpoint/visit APIs, handle photo capture and form validation.

**Tech Stack:** Flutter 3.19+, Material 3, flutter_hooks, Riverpod, image_picker

---

## File Structure

**Files to create:**
- `lib/features/clients/presentation/widgets/client_action_bottom_sheet.dart` - Base bottom sheet widget with drag handle, header, submit button
- `lib/features/clients/presentation/widgets/form_fields/time_picker_field.dart` - Reusable time picker field with label
- `lib/features/clients/presentation/widgets/form_fields/odometer_field.dart` - Reusable odometer number input field
- `lib/features/clients/presentation/widgets/form_fields/auto_set_badge.dart` - Read-only badge for auto-set values
- `lib/features/clients/presentation/widgets/record_touchpoint_bottom_sheet.dart` - Record Touchpoint bottom sheet
- `lib/features/clients/presentation/widgets/record_visit_only_bottom_sheet.dart` - Record Visit Only bottom sheet
- `lib/features/clients/presentation/widgets/record_loan_release_bottom_sheet.dart` - Record Loan Release bottom sheet

**Files to modify:**
- `lib/features/clients/presentation/pages/client_detail_page.dart` - Update handler methods to use new bottom sheets

---

## Task 1: Create ClientActionBottomSheet Base Widget

**Files:**
- Create: `lib/features/clients/presentation/widgets/client_action_bottom_sheet.dart`

- [ ] **Step 1: Create base bottom sheet widget file**

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart' show LucideIcons;

/// Base widget for client action bottom sheets with consistent styling
class ClientActionBottomSheet extends StatelessWidget {
  final String clientName;
  final String pensionType;
  final Widget content;
  final String submitButtonText;
  final VoidCallback onSubmit;
  final bool isSubmitting;

  const ClientActionBottomSheet({
    super.key,
    required this.clientName,
    required this.pensionType,
    required this.content,
    required this.submitButtonText,
    required this.onSubmit,
    this.isSubmitting = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.4,
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header - Client Name and Pension Type
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clientName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pensionType,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Form Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: content,
            ),
          ),

          // Submit Button
          Container(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + bottomPadding),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: isSubmitting ? null : onSubmit,
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        submitButtonText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify file compiles**

Run: `cd mobile/imu_flutter && flutter analyze lib/features/clients/presentation/widgets/client_action_bottom_sheet.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
cd mobile/imu_flutter && git add lib/features/clients/presentation/widgets/client_action_bottom_sheet.dart
git commit -m "feat: add ClientActionBottomSheet base widget

- Create reusable bottom sheet with drag handle and header
- Auto-height sizing (40%-80% of screen)
- Consistent Material 3 styling
- Submit button with loading state

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 2: Create TimePickerField Component

**Files:**
- Create: `lib/features/clients/presentation/widgets/form_fields/time_picker_field.dart`

- [ ] **Step 1: Create time picker field widget**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons/lucide_icons.dart' show LucideIcons;

/// Reusable time picker field with label
class TimePickerField extends HookWidget {
  final String label;
  final TimeOfDay? initialTime;
  final ValueChanged<TimeOfDay?> onTimeChanged;

  const TimePickerField({
    super.key,
    required this.label,
    this.initialTime,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedTime = useState<TimeOfDay?>(initialTime);

    Future<void> pickTime() async {
      final now = TimeOfDay.now();
      final picked = await showTimePicker(
        context: context,
        initialTime: selectedTime.value ?? now,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              timePickerTheme: TimePickerThemeData(
                backgroundColor: Colors.white,
                hourMinuteColor: MaterialStateColor.resolveWith((states) =>
                  states.contains(MaterialState.selected)
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent),
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        selectedTime.value = picked;
        onTimeChanged(picked);
      }
    }

    String formatTime(TimeOfDay? time) {
      if (time == null) return 'Select time';
      final hour = time.hourOfPeriod.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.period == DayPeriod.am ? 'AM' : 'PM';
      return '$hour:$minute $period';
    }

    return InkWell(
      onTap: pickTime,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.clock,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const Spacer(),
            Text(
              formatTime(selectedTime.value),
              style: TextStyle(
                fontSize: 14,
                color: selectedTime.value != null
                  ? const Color(0xFF0F172A)
                  : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify file compiles**

Run: `cd mobile/imu_flutter && flutter analyze lib/features/clients/presentation/widgets/form_fields/time_picker_field.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
cd mobile/imu_flutter && git add lib/features/clients/presentation/widgets/form_fields/time_picker_field.dart
git commit -m "feat: add TimePickerField component

- Reusable time picker with Material 3 styling
- 40px height with icon and label
- Shows formatted time (HH:MM AM/PM)
- Integrates with showTimePicker

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 3: Create OdometerField Component

**Files:**
- Create: `lib/features/clients/presentation/widgets/form_fields/odometer_field.dart`

- [ ] **Step 1: Create odometer field widget**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons/lucide_icons.dart' show LucideIcons;

/// Reusable odometer number input field
class OdometerField extends HookWidget {
  final String label;
  final String? initialValue;
  final ValueChanged<String?> onChanged;

  const OdometerField({
    super.key,
    required this.label,
    this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: initialValue);

    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
        color: Colors.grey[50],
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
          prefixIcon: Icon(
            LucideIcons.gauge,
            size: 16,
            color: Colors.grey[600],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        style: const TextStyle(fontSize: 14),
        onChanged: onChanged,
      ),
    );
  }
}
```

- [ ] **Step 2: Verify file compiles**

Run: `cd mobile/imu_flutter && flutter analyze lib/features/clients/presentation/widgets/form_fields/odometer_field.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
cd mobile/imu_flutter && git add lib/features/clients/presentation/widgets/form_fields/odometer_field.dart
git commit -m "feat: add OdometerField component

- Reusable odometer input with Material 3 styling
- 40px height with icon and label
- Number keyboard type
- Integrates with TextField

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 4: Create AutoSetBadge Component

**Files:**
- Create: `lib/features/clients/presentation/widgets/form_fields/auto_set_badge.dart`

- [ ] **Step 1: Create auto-set badge widget**

```dart
import 'package:flutter/material.dart';

/// Read-only badge for auto-set field values
class AutoSetBadge extends StatelessWidget {
  final String label;
  final String value;

  const AutoSetBadge({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFdcfce7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF166534),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF166534),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify file compiles**

Run: `cd mobile/imu_flutter && flutter analyze lib/features/clients/presentation/widgets/form_fields/auto_set_badge.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
cd mobile/imu_flutter && git add lib/features/clients/presentation/widgets/form_fields/auto_set_badge.dart
git commit -m "feat: add AutoSetBadge component

- Read-only badge for auto-set field values
- Green-100 background with green-800 text
- Shows label and value inline
- Used for Reason and Status badges

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 5: Create RecordTouchpointBottomSheet

**Files:**
- Create: `lib/features/clients/presentation/widgets/record_touchpoint_bottom_sheet.dart`

- [ ] **Step 1: Create RecordTouchpointBottomSheet widget**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/features/clients/presentation/widgets/client_action_bottom_sheet.dart';
import 'package:imu_flutter/features/clients/presentation/widgets/form_fields/auto_set_badge.dart';
import 'package:imu_flutter/features/clients/presentation/widgets/form_fields/odometer_field.dart';
import 'package:imu_flutter/features/clients/presentation/widgets/form_fields/time_picker_field.dart';
import 'package:lucide_icons/lucide_icons.dart' show LucideIcons;

/// Bottom sheet for recording touchpoints with all fields
class RecordTouchpointBottomSheet extends HookWidget {
  final Client client;
  final Future<bool> Function(Map<String, dynamic>) onSubmit;

  const RecordTouchpointBottomSheet({
    super.key,
    required this.client,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final timeIn = useState<TimeOfDay?>(null);
    final timeOut = useState<TimeOfDay?>(null);
    final odometerArrival = useState<String?>(null);
    final odometerDeparture = useState<String?>(null);
    final reason = useState<String>('Follow-up');
    final status = useState<String>('Interested');
    final remarks = useTextEditingController();
    final photoPath = useState<String?>(null);
    final isSubmitting = useState<bool>(false);

    final imagePicker = useMemoized(() => ImagePicker());

    Future<void> pickPhoto() async {
      final picked = await imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (picked != null) {
        photoPath.value = picked.path;
      }
    }

    bool get canSubmit {
      return timeIn.value != null &&
          timeOut.value != null &&
          odometerArrival.value != null &&
          odometerDeparture.value != null &&
          !isSubmitting.value;
    }

    Future<void> handleSubmit() async {
      if (!canSubmit) return;

      isSubmitting.value = true;

      final data = <String, dynamic>{
        'client_id': client.id,
        'time_in': _formatTimeOfDay(timeIn.value!),
        'time_out': _formatTimeOfDay(timeOut.value!),
        'odometer_arrival': int.parse(odometerArrival.value!),
        'odometer_departure': int.parse(odometerDeparture.value!),
        'reason': reason.value,
        'status': status.value,
        'remarks': remarks.text.trim(),
        'photo_path': photoPath.value,
      };

      try {
        final success = await onSubmit(data);
        if (success && context.mounted) {
          Navigator.of(context).pop(true);
        }
      } finally {
        isSubmitting.value = false;
      }
    }

    String _formatTimeOfDay(TimeOfDay time) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }

    return ClientActionBottomSheet(
      clientName: client.fullName,
      pensionType: client.pensionType,
      submitButtonText: 'Record Touchpoint',
      isSubmitting: isSubmitting.value,
      onSubmit: canSubmit ? handleSubmit : () {},
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time In/Out - 2 Column Layout
          Row(
            children: [
              Expanded(
                child: TimePickerField(
                  label: 'Time In',
                  initialTime: timeIn.value,
                  onTimeChanged: (time) => timeIn.value = time,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TimePickerField(
                  label: 'Time Out',
                  initialTime: timeOut.value,
                  onTimeChanged: (time) => timeOut.value = time,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Odometer Arrival/Departure - 2 Column Layout
          Row(
            children: [
              Expanded(
                child: OdometerField(
                  label: 'Odometer Arrival',
                  initialValue: odometerArrival.value,
                  onChanged: (value) => odometerArrival.value = value,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OdometerField(
                  label: 'Odometer Departure',
                  initialValue: odometerDeparture.value,
                  onChanged: (value) => odometerDeparture.value = value,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Reason Dropdown
          Text(
            'Reason',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey[50],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: reason.value,
                isExpanded: true,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                items: const [
                  DropdownMenuItem(value: 'Follow-up', child: Text('Follow-up')),
                  DropdownMenuItem(value: 'Documentation', child: Text('Documentation')),
                  DropdownMenuItem(value: 'Payment Collection', child: Text('Payment Collection')),
                  DropdownMenuItem(value: 'Client not available', child: Text('Client not available')),
                ],
                onChanged: (value) => reason.value = value ?? reason.value,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Status Dropdown
          Text(
            'Status',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey[50],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: status.value,
                isExpanded: true,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                items: const [
                  DropdownMenuItem(value: 'Interested', child: Text('Interested')),
                  DropdownMenuItem(value: 'Undecided', child: Text('Undecided')),
                  DropdownMenuItem(value: 'Not Interested', child: Text('Not Interested')),
                  DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                ],
                onChanged: (value) => status.value = value ?? status.value,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Remarks
          Text(
            'Remarks',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: remarks,
            maxLines: 3,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            style: const TextStyle(fontSize: 14),
          ),

          const SizedBox(height: 8),

          // Photo Capture
          InkWell(
            onTap: pickPhoto,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(
                  color: photoPath.value != null
                    ? Colors.green[600]!
                    : Colors.grey[300]!,
                ),
                borderRadius: BorderRadius.circular(4),
                color: photoPath.value != null
                  ? Colors.green[50]
                  : Colors.grey[50],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    photoPath.value != null
                      ? LucideIcons.checkCircle
                      : LucideIcons.camera,
                    size: 20,
                    color: photoPath.value != null
                      ? Colors.green[600]
                      : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    photoPath.value != null
                      ? 'Photo captured'
                      : 'Take Photo',
                    style: TextStyle(
                      fontSize: 14,
                      color: photoPath.value != null
                        ? Colors.green[700]
                        : Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify file compiles**

Run: `cd mobile/imu_flutter && flutter analyze lib/features/clients/presentation/widgets/record_touchpoint_bottom_sheet.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
cd mobile/imu_flutter && git add lib/features/clients/presentation/widgets/record_touchpoint_bottom_sheet.dart
git commit -m "feat: add RecordTouchpointBottomSheet widget

- Complete touchpoint form with all fields
- 2-column layout for time and odometer fields
- Reason and status dropdowns
- Remarks text field
- Photo capture integration
- Form validation before submit

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 6: Create RecordVisitOnlyBottomSheet

**Files:**
- Create: `lib/features/clients/presentation/widgets/record_visit_only_bottom_sheet.dart`

- [ ] **Step 1: Create RecordVisitOnlyBottomSheet widget**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/features/clients/presentation/widgets/client_action_bottom_sheet.dart';
import 'package:imu_flutter/features/clients/presentation/widgets/form_fields/auto_set_badge.dart';
import 'package:imu_flutter/features/clients/presentation/widgets/form_fields/odometer_field.dart';
import 'package:imu_flutter/features/clients/presentation/widgets/form_fields/time_picker_field.dart';
import 'package:lucide_icons/lucide_icons.dart' show LucideIcons;

/// Bottom sheet for recording visit only with auto-set reason/status
class RecordVisitOnlyBottomSheet extends HookWidget {
  final Client client;
  final Future<bool> Function(Map<String, dynamic>) onSubmit;

  const RecordVisitOnlyBottomSheet({
    super.key,
    required this.client,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final timeIn = useState<TimeOfDay?>(null);
    final timeOut = useState<TimeOfDay?>(null);
    final odometerArrival = useState<String?>(null);
    final odometerDeparture = useState<String?>(null);
    final photoPath = useState<String?>(null);
    final isSubmitting = useState<bool>(false);

    final imagePicker = useMemoized(() => ImagePicker());

    Future<void> pickPhoto() async {
      final picked = await imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (picked != null) {
        photoPath.value = picked.path;
      }
    }

    bool get canSubmit {
      return timeIn.value != null &&
          timeOut.value != null &&
          odometerArrival.value != null &&
          odometerDeparture.value != null &&
          !isSubmitting.value;
    }

    Future<void> handleSubmit() async {
      if (!canSubmit) return;

      isSubmitting.value = true;

      final data = <String, dynamic>{
        'client_id': client.id,
        'time_in': _formatTimeOfDay(timeIn.value!),
        'time_out': _formatTimeOfDay(timeOut.value!),
        'odometer_arrival': int.parse(odometerArrival.value!),
        'odometer_departure': int.parse(odometerDeparture.value!),
        'reason': 'Client not available',
        'status': 'Incomplete',
        'photo_path': photoPath.value,
      };

      try {
        final success = await onSubmit(data);
        if (success && context.mounted) {
          Navigator.of(context).pop(true);
        }
      } finally {
        isSubmitting.value = false;
      }
    }

    String _formatTimeOfDay(TimeOfDay time) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }

    return ClientActionBottomSheet(
      clientName: client.fullName,
      pensionType: client.pensionType,
      submitButtonText: 'Record Visit',
      isSubmitting: isSubmitting.value,
      onSubmit: canSubmit ? handleSubmit : () {},
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Auto-set badges
          Row(
            children: const [
              AutoSetBadge(label: 'Reason:', value: 'Client not available'),
              SizedBox(width: 8),
              AutoSetBadge(label: 'Status:', value: 'Incomplete'),
            ],
          ),

          const SizedBox(height: 8),

          // Time In/Out - 2 Column Layout
          Row(
            children: [
              Expanded(
                child: TimePickerField(
                  label: 'Time In',
                  initialTime: timeIn.value,
                  onTimeChanged: (time) => timeIn.value = time,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TimePickerField(
                  label: 'Time Out',
                  initialTime: timeOut.value,
                  onTimeChanged: (time) => timeOut.value = time,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Odometer Arrival/Departure - 2 Column Layout
          Row(
            children: [
              Expanded(
                child: OdometerField(
                  label: 'Odometer Arrival',
                  initialValue: odometerArrival.value,
                  onChanged: (value) => odometerArrival.value = value,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OdometerField(
                  label: 'Odometer Departure',
                  initialValue: odometerDeparture.value,
                  onChanged: (value) => odometerDeparture.value = value,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Photo Capture (Optional)
          InkWell(
            onTap: pickPhoto,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(
                  color: photoPath.value != null
                    ? Colors.green[600]!
                    : Colors.grey[300]!,
                ),
                borderRadius: BorderRadius.circular(4),
                color: photoPath.value != null
                  ? Colors.green[50]
                  : Colors.grey[50],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    photoPath.value != null
                      ? LucideIcons.checkCircle
                      : LucideIcons.camera,
                    size: 20,
                    color: photoPath.value != null
                      ? Colors.green[600]
                      : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    photoPath.value != null
                      ? 'Photo captured (optional)'
                      : 'Take Photo (Optional)',
                    style: TextStyle(
                      fontSize: 14,
                      color: photoPath.value != null
                        ? Colors.green[700]
                        : Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify file compiles**

Run: `cd mobile/imu_flutter && flutter analyze lib/features/clients/presentation/widgets/record_visit_only_bottom_sheet.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
cd mobile/imu_flutter && git add lib/features/clients/presentation/widgets/record_visit_only_bottom_sheet.dart
git commit -m "feat: add RecordVisitOnlyBottomSheet widget

- Simplified visit form with auto-set reason/status
- Auto-set badges for 'Client not available' and 'Incomplete'
- 2-column layout for time and odometer fields
- Optional photo capture
- Minimal fields for quick visit recording

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 7: Create RecordLoanReleaseBottomSheet

**Files:**
- Create: `lib/features/clients/presentation/widgets/record_loan_release_bottom_sheet.dart`

- [ ] **Step 1: Create RecordLoanReleaseBottomSheet widget**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/features/clients/presentation/widgets/client_action_bottom_sheet.dart';
import 'package:imu_flutter/features/clients/presentation/widgets/form_fields/auto_set_badge.dart';
import 'package:imu_flutter/features/clients/presentation/widgets/form_fields/odometer_field.dart';
import 'package:imu_flutter/features/clients/presentation/widgets/form_fields/time_picker_field.dart';
import 'package:lucide_icons/lucide_icons.dart' show LucideIcons;

/// Bottom sheet for recording loan release with product/loan type selection
class RecordLoanReleaseBottomSheet extends HookWidget {
  final Client client;
  final Future<bool> Function(Map<String, dynamic>) onSubmit;

  const RecordLoanReleaseBottomSheet({
    super.key,
    required this.client,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final timeIn = useState<TimeOfDay?>(null);
    final timeOut = useState<TimeOfDay?>(null);
    final odometerArrival = useState<String?>(null);
    final odometerDeparture = useState<String?>(null);
    final productType = useState<String>('PUSU');
    final loanType = useState<String>('NEW');
    final udiNumber = useTextEditingController();
    final remarks = useTextEditingController();
    final photoPath = useState<String?>(null);
    final isSubmitting = useState<bool>(false);

    final imagePicker = useMemoized(() => ImagePicker());

    Future<void> pickPhoto() async {
      final picked = await imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (picked != null) {
        photoPath.value = picked.path;
      }
    }

    bool get canSubmit {
      return timeIn.value != null &&
          timeOut.value != null &&
          odometerArrival.value != null &&
          odometerDeparture.value != null &&
          udiNumber.text.trim().isNotEmpty &&
          !isSubmitting.value;
    }

    Future<void> handleSubmit() async {
      if (!canSubmit) return;

      isSubmitting.value = true;

      final data = <String, dynamic>{
        'client_id': client.id,
        'time_in': _formatTimeOfDay(timeIn.value!),
        'time_out': _formatTimeOfDay(timeOut.value!),
        'odometer_arrival': int.parse(odometerArrival.value!),
        'odometer_departure': int.parse(odometerDeparture.value!),
        'product_type': productType.value,
        'loan_type': loanType.value,
        'udi_number': udiNumber.text.trim(),
        'remarks': remarks.text.trim(),
        'photo_path': photoPath.value,
        'reason': 'New Loan Release',
        'status': 'Completed',
      };

      try {
        final success = await onSubmit(data);
        if (success && context.mounted) {
          Navigator.of(context).pop(true);
        }
      } finally {
        isSubmitting.value = false;
      }
    }

    String _formatTimeOfDay(TimeOfDay time) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }

    return ClientActionBottomSheet(
      clientName: client.fullName,
      pensionType: client.pensionType,
      submitButtonText: 'Release Loan',
      isSubmitting: isSubmitting.value,
      onSubmit: canSubmit ? handleSubmit : () {},
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Auto-set badges
          Row(
            children: const [
              AutoSetBadge(label: 'Reason:', value: 'New Loan Release'),
              SizedBox(width: 8),
              AutoSetBadge(label: 'Status:', value: 'Completed'),
            ],
          ),

          const SizedBox(height: 8),

          // Time In/Out - 2 Column Layout
          Row(
            children: [
              Expanded(
                child: TimePickerField(
                  label: 'Time In',
                  initialTime: timeIn.value,
                  onTimeChanged: (time) => timeIn.value = time,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TimePickerField(
                  label: 'Time Out',
                  initialTime: timeOut.value,
                  onTimeChanged: (time) => timeOut.value = time,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Odometer Arrival/Departure - 2 Column Layout
          Row(
            children: [
              Expanded(
                child: OdometerField(
                  label: 'Odometer Arrival',
                  initialValue: odometerArrival.value,
                  onChanged: (value) => odometerArrival.value = value,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OdometerField(
                  label: 'Odometer Departure',
                  initialValue: odometerDeparture.value,
                  onChanged: (value) => odometerDeparture.value = value,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Product Type Dropdown
          Text(
            'Product Type',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey[50],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: productType.value,
                isExpanded: true,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                items: const [
                  DropdownMenuItem(value: 'PUSU', child: Text('PUSU')),
                  DropdownMenuItem(value: 'LIKA', child: Text('LIKA')),
                  DropdownMenuItem(value: 'SUB2K', child: Text('SUB2K')),
                ],
                onChanged: (value) => productType.value = value ?? productType.value,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Loan Type Dropdown
          Text(
            'Loan Type',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey[50],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: loanType.value,
                isExpanded: true,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                items: const [
                  DropdownMenuItem(value: 'NEW', child: Text('NEW')),
                  DropdownMenuItem(value: 'ADDITIONAL', child: Text('ADDITIONAL')),
                  DropdownMenuItem(value: 'RENEWAL', child: Text('RENEWAL')),
                  DropdownMenuItem(value: 'PRETERM', child: Text('PRETERM')),
                ],
                onChanged: (value) => loanType.value = value ?? loanType.value,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // UDI Number
          Text(
            'UDI Number *',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: udiNumber,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.all(12),
              hintText: 'Enter UDI number',
            ),
            style: const TextStyle(fontSize: 14),
          ),

          const SizedBox(height: 8),

          // Remarks
          Text(
            'Remarks',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: remarks,
            maxLines: 2,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            style: const TextStyle(fontSize: 14),
          ),

          const SizedBox(height: 8),

          // Photo Capture
          InkWell(
            onTap: pickPhoto,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(
                  color: photoPath.value != null
                    ? Colors.green[600]!
                    : Colors.grey[300]!,
                ),
                borderRadius: BorderRadius.circular(4),
                color: photoPath.value != null
                  ? Colors.green[50]
                  : Colors.grey[50],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    photoPath.value != null
                      ? LucideIcons.checkCircle
                      : LucideIcons.camera,
                    size: 20,
                    color: photoPath.value != null
                      ? Colors.green[600]
                      : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    photoPath.value != null
                      ? 'Photo captured'
                      : 'Take Photo',
                    style: TextStyle(
                      fontSize: 14,
                      color: photoPath.value != null
                        ? Colors.green[700]
                        : Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify file compiles**

Run: `cd mobile/imu_flutter && flutter analyze lib/features/clients/presentation/widgets/record_loan_release_bottom_sheet.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
cd mobile/imu_flutter && git add lib/features/clients/presentation/widgets/record_loan_release_bottom_sheet.dart
git commit -m "feat: add RecordLoanReleaseBottomSheet widget

- Loan release form with product/loan type selection
- Auto-set badges for 'New Loan Release' and 'Completed'
- Product Type dropdown (PUSU, LIKA, SUB2K)
- Loan Type dropdown (NEW, ADDITIONAL, RENEWAL, PRETERM)
- UDI Number required field
- Remarks and photo capture

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 8: Update Client Detail Page - Import New Bottom Sheets

**Files:**
- Modify: `lib/features/clients/presentation/pages/client_detail_page.dart`

- [ ] **Step 1: Add imports for new bottom sheet widgets**

Add these imports after the existing widget imports (around line 45):

```dart
import '../../../clients/presentation/widgets/record_touchpoint_bottom_sheet.dart';
import '../../../clients/presentation/widgets/record_visit_only_bottom_sheet.dart';
import '../../../clients/presentation/widgets/record_loan_release_bottom_sheet.dart';
```

- [ ] **Step 2: Verify imports compile**

Run: `cd mobile/imu_flutter && flutter analyze lib/features/clients/presentation/pages/client_detail_page.dart`
Expected: No errors about missing imports

- [ ] **Step 3: Commit**

```bash
cd mobile/imu_flutter && git add lib/features/clients/presentation/pages/client_detail_page.dart
git commit -m "feat: import new bottom sheet widgets in client detail page

- Add RecordTouchpointBottomSheet import
- Add RecordVisitOnlyBottomSheet import
- Add RecordLoanReleaseBottomSheet import
- Prepare for handler method updates

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 9: Update _handleRecordTouchpoint Method

**Files:**
- Modify: `lib/features/clients/presentation/pages/client_detail_page.dart`

- [ ] **Step 1: Replace _handleRecordTouchpoint implementation**

Find the existing `_handleRecordTouchpoint` method (around line 1070) and replace with:

```dart
  /// Open Record Touchpoint bottom sheet
  Future<void> _handleRecordTouchpoint() async {
    if (_client == null) return;

    // Prevent touchpoint creation for loan released clients
    if (_client!.loanReleased) {
      if (mounted) {
        HapticUtils.error();
        AppNotification.showError(context, 'Cannot create touchpoints: Loan has been released');
      }
      return;
    }

    HapticUtils.lightImpact();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => RecordTouchpointBottomSheet(
        client: _client!,
        onSubmit: (data) async {
          try {
            // Submit to API
            final success = await ref.read(createTouchpointProvider.notifier)
              .createTouchpoint(_client!.id!, data);

            if (success && mounted) {
              AppNotification.showSuccess(context, 'Touchpoint recorded successfully');
              await _loadClient();
              ref.invalidate(clientTouchpointsProvider);
            }
            return success;
          } catch (e) {
            if (mounted) {
              AppNotification.showError(context, 'Failed to record touchpoint: $e');
            }
            return false;
          }
        },
      ),
    );

    if (result == true && mounted) {
      await _loadClient();
      ref.invalidate(clientTouchpointsProvider);
    }
  }
```

- [ ] **Step 2: Verify method compiles**

Run: `cd mobile/imu_flutter && flutter analyze lib/features/clients/presentation/pages/client_detail_page.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
cd mobile/imu_flutter && git add lib/features/clients/presentation/pages/client_detail_page.dart
git commit -m "feat: implement RecordTouchpointBottomSheet in handler

- Replace TODO with RecordTouchpointBottomSheet
- Add API integration via createTouchpointProvider
- Handle success/error states
- Refresh client data and touchpoints on success
- Keep loan released validation

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 10: Update _handleRecordVisitOnly Method

**Files:**
- Modify: `lib/features/clients/presentation/pages/client_detail_page.dart`

- [ ] **Step 1: Replace _handleRecordVisitOnly implementation**

Find the existing `_handleRecordVisitOnly` method (around line 1090) and replace with:

```dart
  /// Open Record Visit Only bottom sheet
  Future<void> _handleRecordVisitOnly() async {
    if (_client == null) return;

    HapticUtils.lightImpact();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => RecordVisitOnlyBottomSheet(
        client: _client!,
        onSubmit: (data) async {
          try {
            // Submit to API
            final success = await ref.read(createTouchpointProvider.notifier)
              .createTouchpoint(_client!.id!, data);

            if (success && mounted) {
              AppNotification.showSuccess(context, 'Visit recorded successfully');
              await _loadClient();
              ref.invalidate(clientTouchpointsProvider);
            }
            return success;
          } catch (e) {
            if (mounted) {
              AppNotification.showError(context, 'Failed to record visit: $e');
            }
            return false;
          }
        },
      ),
    );

    if (result == true && mounted) {
      await _loadClient();
      ref.invalidate(clientTouchpointsProvider);
    }
  }
```

- [ ] **Step 2: Verify method compiles**

Run: `cd mobile/imu_flutter && flutter analyze lib/features/clients/presentation/pages/client_detail_page.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
cd mobile/imu_flutter && git add lib/features/clients/presentation/pages/client_detail_page.dart
git commit -m "feat: implement RecordVisitOnlyBottomSheet in handler

- Replace TODO with RecordVisitOnlyBottomSheet
- Add API integration via createTouchpointProvider
- Handle success/error states
- Refresh client data and touchpoints on success
- Allow visits when loan is released

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 11: Update _handleReleaseLoanBottomSheet Method

**Files:**
- Modify: `lib/features/clients/presentation/pages/client_detail_page.dart`

- [ ] **Step 1: Replace _handleReleaseLoanBottomSheet implementation**

Find the existing `_handleReleaseLoanBottomSheet` method (around line 1110) and replace with:

```dart
  /// Open Release Loan bottom sheet
  Future<void> _handleReleaseLoanBottomSheet() async {
    if (_client == null) return;

    HapticUtils.lightImpact();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => RecordLoanReleaseBottomSheet(
        client: _client!,
        onSubmit: (data) async {
          try {
            // Submit to API
            final success = await ref.read(releaseLoanProvider.notifier)
              .releaseLoan(_client!.id!, data);

            if (success && mounted) {
              AppNotification.showSuccess(context, 'Loan released successfully');
              await _loadClient();
              ref.invalidate(clientTouchpointsProvider);
            }
            return success;
          } catch (e) {
            if (mounted) {
              AppNotification.showError(context, 'Failed to release loan: $e');
            }
            return false;
          }
        },
      ),
    );

    if (result == true && mounted) {
      await _loadClient();
      ref.invalidate(clientTouchpointsProvider);
    }
  }
```

- [ ] **Step 2: Verify method compiles**

Run: `cd mobile/imu_flutter && flutter analyze lib/features/clients/presentation/pages/client_detail_page.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
cd mobile/imu_flutter && git add lib/features/clients/presentation/pages/client_detail_page.dart
git commit -m "feat: implement RecordLoanReleaseBottomSheet in handler

- Replace TODO with RecordLoanReleaseBottomSheet
- Add API integration via releaseLoanProvider
- Handle success/error states
- Refresh client data and touchpoints on success
- Allow additional releases when loan is released

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 12: Build and Verify Complete Implementation

**Files:**
- Test: Flutter build compilation

- [ ] **Step 1: Run Flutter build**

Run: `cd mobile/imu_flutter && flutter build apk --debug`

Expected output:
```
✓ Built build\app\outputs\flutter-apk\app-debug.apk
```

- [ ] **Step 2: Verify no compilation errors**

Check that the build completes successfully with no errors about missing classes or undefined references

- [ ] **Step 3: Run Flutter analyze**

Run: `cd mobile/imu_flutter && flutter analyze`

Expected: No new errors (only pre-existing warnings)

- [ ] **Step 4: Commit final implementation**

```bash
cd mobile/imu_flutter && git add -A
git commit -m "feat: complete client action bottom sheets implementation

- All three bottom sheets implemented with compact Material 3 design
- Auto-height sizing (40%-80% of screen)
- 2-column layouts for time and odometer fields
- Form validation and API integration
- Photo capture support
- Loan release restrictions removed as specified
- Ready for testing

Implementation includes:
- ClientActionBottomSheet base widget
- TimePickerField, OdometerField, AutoSetBadge components
- RecordTouchpointBottomSheet with full form
- RecordVisitOnlyBottomSheet with auto-set badges
- RecordLoanReleaseBottomSheet with product/loan type selection
- Updated handler methods in client detail page

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Success Criteria

### Functional
- ✅ All three bottom sheets work when loan is released (except Record Touchpoint)
- ✅ Auto-height sizing works correctly (40%-80%)
- ✅ Form validation prevents invalid submissions
- ✅ Photo capture integrates with camera
- ✅ API submission handles success/error states

### UX/UI
- ✅ Compact design with 12px horizontal padding
- ✅ 2-column layout saves vertical space
- ✅ Touch targets are 48px minimum
- ✅ Text is readable at 12-14px
- ✅ Auto-set badges are clearly visible
- ✅ Loading states shown during submission

### Code Quality
- ✅ All files compile without errors
- ✅ No placeholder TODO comments
- ✅ Clean git history with atomic commits
- ✅ Reusable components created

---

## Testing Verification

### Manual Testing Checklist
- [ ] Open client detail page
- [ ] Tap "Record Touchpoint" → Should show bottom sheet with all fields
- [ ] Tap "Record Visit" → Should show bottom sheet with auto-set badges
- [ ] Tap "Release Loan" → Should show bottom sheet with product/loan types
- [ ] Test with released loan client → Visit and Release buttons work
- [ ] Test photo capture → Camera opens and captures photo
- [ ] Test form validation → Submit button disabled when fields empty
- [ ] Test API submission → Success notification shown, data refreshed

### Build Verification
- [ ] `flutter analyze` passes with no new errors
- [ ] `flutter build apk --debug` succeeds
- [ ] APK installs on device
- [ ] App launches without crashes

---

**Implementation Status:** ✅ Complete when all tasks finished and app compiles successfully

**Next Steps:** Test on real device, verify API integration, gather user feedback
