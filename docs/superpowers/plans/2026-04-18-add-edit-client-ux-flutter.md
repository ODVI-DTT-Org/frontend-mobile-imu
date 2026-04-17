# Add/Edit Client UX — Flutter Mobile Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align Add Client and Edit Client pages in the Flutter app to a consistent 5-section layout with role-based save button labels.

**Architecture:** `add_client_page.dart` is restructured in-place (sections renamed/reorganised). A new `edit_client_page.dart` replaces the inline Scaffold in the router and the modal push in `client_detail_page.dart`. `EditClientFormV2` is retired.

**Tech Stack:** Flutter, Riverpod, go_router, lucide_icons, HiveService, clientApiServiceProvider, currentUserRoleProvider, UserRole enum.

---

## File Map

| Action | File |
|--------|------|
| Modify | `lib/features/clients/presentation/pages/add_client_page.dart` |
| Create | `lib/features/clients/presentation/pages/edit_client_page.dart` |
| Modify | `lib/core/router/app_router.dart` |
| Modify | `lib/features/clients/presentation/pages/client_detail_page.dart` |
| Delete | `lib/features/clients/presentation/widgets/edit_client_form_v2.dart` |
| Modify | `test/widget/clients/add_client_page_test.dart` (create if absent) |

Working directory for all commands: `frontend-mobile-imu/imu_flutter/`

---

## Task 1: Restructure `add_client_page.dart` sections

**Files:**
- Modify: `lib/features/clients/presentation/pages/add_client_page.dart`
- Test: `test/widget/clients/add_client_page_test.dart`

- [ ] **Step 1: Write failing widget tests**

Create `test/widget/clients/add_client_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/features/clients/presentation/pages/add_client_page.dart';
import 'package:imu_flutter/shared/providers/app_providers.dart';
import 'package:imu_flutter/core/models/user_role.dart';

void main() {
  Widget buildPage({UserRole role = UserRole.admin}) {
    return ProviderScope(
      overrides: [
        currentUserRoleProvider.overrideWithValue(role),
      ],
      child: const MaterialApp(home: AddClientPage()),
    );
  }

  testWidgets('shows Personal section header', (tester) async {
    await tester.pumpWidget(buildPage());
    expect(find.text('Personal'), findsOneWidget);
  });

  testWidgets('shows Contact section header', (tester) async {
    await tester.pumpWidget(buildPage());
    expect(find.text('Contact'), findsOneWidget);
  });

  testWidgets('shows Professional section header', (tester) async {
    await tester.pumpWidget(buildPage());
    expect(find.text('Professional'), findsOneWidget);
  });

  testWidgets('shows Product section header', (tester) async {
    await tester.pumpWidget(buildPage());
    expect(find.text('Product'), findsOneWidget);
  });

  testWidgets('shows Notes section header', (tester) async {
    await tester.pumpWidget(buildPage());
    expect(find.text('Notes'), findsOneWidget);
  });

  testWidgets('does NOT show old section names', (tester) async {
    await tester.pumpWidget(buildPage());
    expect(find.text('Basic Information'), findsNothing);
    expect(find.text('Contact Details'), findsNothing);
    expect(find.text('Employment Information'), findsNothing);
    expect(find.text('Location'), findsNothing);
    expect(find.text('Remarks'), findsNothing);
  });

  testWidgets('admin sees Save Client button', (tester) async {
    await tester.pumpWidget(buildPage(role: UserRole.admin));
    expect(find.text('Save Client'), findsOneWidget);
  });

  testWidgets('caravan sees Submit for Approval button', (tester) async {
    await tester.pumpWidget(buildPage(role: UserRole.caravan));
    expect(find.text('Submit for Approval'), findsOneWidget);
  });

  testWidgets('tele sees Submit for Approval button', (tester) async {
    await tester.pumpWidget(buildPage(role: UserRole.tele));
    expect(find.text('Submit for Approval'), findsOneWidget);
  });

  testWidgets('shows Cancel button', (tester) async {
    await tester.pumpWidget(buildPage());
    expect(find.text('Cancel'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
flutter test test/widget/clients/add_client_page_test.dart
```

Expected: multiple FAILs (section names not found, buttons not found).

- [ ] **Step 3: Replace `_expandedSections` map and rename `_toggleSection`**

In `lib/features/clients/presentation/pages/add_client_page.dart`, find and replace the `_expandedSections` field:

```dart
// BEFORE
final Map<String, bool> _expandedSections = {
  'basic': true,
  'contact': true,
  'employment': false,
  'product': true,
  'location': true,
  'remarks': false,
};

// AFTER
final Map<String, bool> _expandedSections = {
  'personal': true,
  'contact': true,
  'professional': false,
  'product': false,
  'notes': false,
};
```

- [ ] **Step 4: Add the role-based button label to `build()`**

In the `build()` method, add after `final colorScheme = theme.colorScheme;`:

```dart
final role = ref.watch(currentUserRoleProvider);
final saveLabel = role == UserRole.admin ? 'Save Client' : 'Submit for Approval';
```

Add `import '../../../../core/models/user_role.dart';` at the top of the file if not already present.

- [ ] **Step 5: Replace the bottom button section in `build()`**

Find the existing submit button in `build()`:

```dart
// BEFORE — single full-width submit button
SizedBox(
  width: double.infinity,
  height: 50,
  child: ElevatedButton(
    onPressed: _isSaving ? null : _handleSubmit,
    style: ElevatedButton.styleFrom(...),
    child: _isSaving
        ? const SizedBox(...)
        : const Text('SUBMIT', ...),
  ),
),
```

Replace with Cancel + Save row:

```dart
// AFTER — Cancel + role-based Save button
Row(
  children: [
    Expanded(
      child: OutlinedButton(
        onPressed: _isSaving ? null : () => context.pop(),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Cancel',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      flex: 2,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                saveLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    ),
  ],
),
```

- [ ] **Step 6: Rename and restructure section methods in `build()`**

Replace all six `_buildSectionHeader(...)` + section-builder calls in the `ListView` children with the new 5-section layout:

```dart
// Personal section
_buildSectionHeader(
  title: 'Personal',
  icon: LucideIcons.user,
  sectionKey: 'personal',
  color: colorScheme.primary,
),
const SizedBox(height: 12),
_buildPersonalSection(colorScheme),

const SizedBox(height: 24),

// Contact section (phone/email/facebook + location)
_buildSectionHeader(
  title: 'Contact',
  icon: LucideIcons.phone,
  sectionKey: 'contact',
  color: colorScheme.primary,
),
const SizedBox(height: 12),
_buildContactSection(colorScheme),

const SizedBox(height: 24),

// Professional section
_buildSectionHeader(
  title: 'Professional',
  icon: LucideIcons.briefcase,
  sectionKey: 'professional',
  color: colorScheme.primary,
),
const SizedBox(height: 12),
_buildProfessionalSection(colorScheme),

const SizedBox(height: 24),

// Product section
_buildSectionHeader(
  title: 'Product',
  icon: LucideIcons.creditCard,
  sectionKey: 'product',
  color: colorScheme.primary,
),
const SizedBox(height: 12),
_buildProductSection(colorScheme),

const SizedBox(height: 24),

// Notes section
_buildSectionHeader(
  title: 'Notes',
  icon: LucideIcons.messageSquare,
  sectionKey: 'notes',
  color: colorScheme.primary,
),
const SizedBox(height: 12),
_buildNotesSection(colorScheme),

const SizedBox(height: 32),
```

- [ ] **Step 7: Add `_buildPersonalSection` method**

Add this method (replaces `_buildBasicInfoSection` — remove Client Type, keep Name + Birth Date):

```dart
Widget _buildPersonalSection(ColorScheme colorScheme) {
  if (!_expandedSections['personal']!) return const SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'First Name *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (value) =>
                  value?.trim().isEmpty == true ? 'Required' : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _middleNameController,
              decoration: const InputDecoration(
                labelText: 'Middle Name',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (value) =>
                  value?.trim().isEmpty == true ? 'Required' : null,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _birthDate ?? DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            setState(() => _birthDate = picked);
          }
        },
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Birth Date',
            border: OutlineInputBorder(),
            isDense: true,
            suffixIcon: Icon(LucideIcons.calendar, size: 20),
          ),
          baseStyle: TextStyle(
            fontSize: 16,
            color: _birthDate != null ? Colors.black : Colors.grey,
          ),
          child: Text(
            _birthDate != null
                ? '${_birthDate!.month}/${_birthDate!.day}/${_birthDate!.year}'
                : 'Select birth date',
          ),
        ),
      ),
    ],
  );
}
```

- [ ] **Step 8: Add `_buildContactSection` method**

Add this method (Phone + Email + Facebook from old contact section, plus Region/Province/Municipality/Barangay from old location section):

```dart
Widget _buildContactSection(ColorScheme colorScheme) {
  if (!_expandedSections['contact']!) return const SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        controller: _phoneController,
        decoration: const InputDecoration(
          labelText: 'Phone Number',
          hintText: '+63 912 345 6789',
          prefixIcon: Icon(LucideIcons.phone),
          border: OutlineInputBorder(),
          isDense: true,
        ),
        keyboardType: TextInputType.phone,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _emailController,
        decoration: const InputDecoration(
          labelText: 'Email',
          hintText: 'email@example.com',
          prefixIcon: Icon(LucideIcons.mail),
          border: OutlineInputBorder(),
          isDense: true,
        ),
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _facebookController,
        decoration: const InputDecoration(
          labelText: 'Facebook Profile',
          hintText: 'Facebook profile URL',
          prefixIcon: Icon(LucideIcons.facebook),
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
      const SizedBox(height: 24),
      // Region
      DropdownButtonFormField<PsgcRegion>(
        value: _selectedRegion,
        decoration: InputDecoration(
          labelText: 'Region *',
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: _regions.isEmpty
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
        ),
        items: _regions.map((region) => DropdownMenuItem<PsgcRegion>(
          value: region,
          child: Text(region.name),
        )).toList(),
        onChanged: (region) async {
          setState(() {
            _selectedRegion = region;
            _selectedProvince = null;
            _selectedMunicipality = null;
            _selectedBarangay = null;
            _provinces = [];
            _municipalities = [];
            _barangays = [];
            _isLoadingProvinces = region != null;
          });
          if (region != null) {
            try {
              final psgcRepository = await ref.read(psgcRepositoryProvider.future);
              final provinces = await psgcRepository.getProvincesByRegion(region.name);
              if (mounted) {
                setState(() {
                  _provinces = provinces;
                  _isLoadingProvinces = false;
                });
              }
            } catch (e) {
              if (mounted) setState(() => _isLoadingProvinces = false);
            }
          }
        },
        validator: (value) => value == null ? 'Required' : null,
      ),
      const SizedBox(height: 16),
      // Province
      IgnorePointer(
        ignoring: _selectedRegion == null || _isLoadingProvinces,
        child: DropdownButtonFormField<PsgcProvince>(
          value: _selectedProvince,
          decoration: InputDecoration(
            labelText: 'Province *',
            border: const OutlineInputBorder(),
            isDense: true,
            filled: _selectedRegion == null,
            fillColor: _selectedRegion == null ? Colors.grey.shade100 : null,
            suffixIcon: _isLoadingProvinces
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : null,
            hintText: _selectedRegion == null ? 'Select region first' : null,
          ),
          items: _provinces.isEmpty && _selectedRegion != null && !_isLoadingProvinces
              ? [const DropdownMenuItem<PsgcProvince>(value: null, enabled: false, child: Text('No provinces available', style: TextStyle(color: Colors.grey)))]
              : _provinces.map((p) => DropdownMenuItem<PsgcProvince>(value: p, child: Text(p.name))).toList(),
          onChanged: _selectedRegion == null ? null : (province) async {
            setState(() {
              _selectedProvince = province;
              _selectedMunicipality = null;
              _selectedBarangay = null;
              _municipalities = [];
              _barangays = [];
              _isLoadingMunicipalities = province != null;
            });
            if (province != null) {
              try {
                final psgcRepository = await ref.read(psgcRepositoryProvider.future);
                final municipalities = await psgcRepository.getMunicipalitiesByProvince(province.name);
                if (mounted) setState(() { _municipalities = municipalities; _isLoadingMunicipalities = false; });
              } catch (e) {
                if (mounted) setState(() => _isLoadingMunicipalities = false);
              }
            }
          },
          validator: (value) => _selectedRegion != null && value == null ? 'Required' : null,
        ),
      ),
      const SizedBox(height: 16),
      // Municipality
      IgnorePointer(
        ignoring: _selectedProvince == null || _isLoadingMunicipalities,
        child: DropdownButtonFormField<PsgcMunicipality>(
          value: _selectedMunicipality,
          decoration: InputDecoration(
            labelText: 'Municipality/City *',
            border: const OutlineInputBorder(),
            isDense: true,
            filled: _selectedProvince == null,
            fillColor: _selectedProvince == null ? Colors.grey.shade100 : null,
            suffixIcon: _isLoadingMunicipalities
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : null,
            hintText: _selectedProvince == null ? 'Select province first' : null,
          ),
          items: _municipalities.isEmpty && _selectedProvince != null && !_isLoadingMunicipalities
              ? [const DropdownMenuItem<PsgcMunicipality>(value: null, enabled: false, child: Text('No municipalities available', style: TextStyle(color: Colors.grey)))]
              : _municipalities.map((m) => DropdownMenuItem<PsgcMunicipality>(value: m, child: Text(m.displayName))).toList(),
          onChanged: _selectedProvince == null ? null : (municipality) async {
            setState(() {
              _selectedMunicipality = municipality;
              _selectedBarangay = null;
              _barangays = [];
              _isLoadingBarangays = municipality != null;
            });
            if (municipality != null) {
              await _loadBarangays(municipality.name);
            }
          },
          validator: (value) => _selectedProvince != null && value == null ? 'Required' : null,
        ),
      ),
      const SizedBox(height: 16),
      // Barangay
      IgnorePointer(
        ignoring: _selectedMunicipality == null || _isLoadingBarangays,
        child: DropdownButtonFormField<PsgcBarangay>(
          value: _selectedBarangay,
          decoration: InputDecoration(
            labelText: 'Barangay *',
            border: const OutlineInputBorder(),
            isDense: true,
            filled: _selectedMunicipality == null,
            fillColor: _selectedMunicipality == null ? Colors.grey.shade100 : null,
            suffixIcon: _isLoadingBarangays
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : null,
            hintText: _selectedMunicipality == null ? 'Select municipality first' : null,
          ),
          items: _barangays.isEmpty && _selectedMunicipality != null && !_isLoadingBarangays
              ? [const DropdownMenuItem<PsgcBarangay>(value: null, enabled: false, child: Text('No barangays available', style: TextStyle(color: Colors.grey)))]
              : _barangays.map((b) => DropdownMenuItem<PsgcBarangay>(value: b, child: Text(b.barangay ?? 'Unknown'))).toList(),
          onChanged: _selectedMunicipality == null ? null : (barangay) {
            HapticUtils.lightImpact();
            setState(() => _selectedBarangay = barangay);
          },
          validator: (value) => _selectedMunicipality != null && value == null ? 'Required' : null,
        ),
      ),
    ],
  );
}
```

- [ ] **Step 9: Rename `_buildEmploymentSection` → `_buildProfessionalSection`**

Rename the method signature only (the body is unchanged):

```dart
// BEFORE
Widget _buildEmploymentSection(ColorScheme colorScheme) {
  if (!_expandedSections['employment']!) return const SizedBox.shrink();

// AFTER
Widget _buildProfessionalSection(ColorScheme colorScheme) {
  if (!_expandedSections['professional']!) return const SizedBox.shrink();
```

- [ ] **Step 10: Update `_buildProductInfoSection` → `_buildProductSection` with Client Type + PAN**

Rename and add Client Type at the top, PAN before the closing brace:

```dart
Widget _buildProductSection(ColorScheme colorScheme) {
  if (!_expandedSections['product']!) return const SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Client Type (moved from Personal)
      const Text(
        'Client Type',
        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: _ClientTypeButton(
              label: 'Potential',
              isSelected: _clientType == 'POTENTIAL',
              colorScheme: colorScheme,
              onTap: () {
                HapticUtils.selectionClick();
                setState(() => _clientType = 'POTENTIAL');
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ClientTypeButton(
              label: 'Existing',
              isSelected: _clientType == 'EXISTING',
              colorScheme: colorScheme,
              onTap: () {
                HapticUtils.selectionClick();
                setState(() => _clientType = 'EXISTING');
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      // Product Type + Pension Type
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Product Type', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _productType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  items: const ['BFP ACTIVE', 'BFP PENSION', 'PNP PENSION', 'NAPOLCOM', 'BFP STP']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      HapticUtils.lightImpact();
                      setState(() => _productType = value);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pension Type', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _pensionType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  items: ['SSS', 'GSIS', 'Private', 'None']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      HapticUtils.lightImpact();
                      setState(() => _pensionType = value);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value: _marketType,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Market Type',
          border: OutlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        items: ['Residential', 'Commercial', 'Industrial']
            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
            .toList(),
        onChanged: (value) {
          if (value != null) {
            HapticUtils.lightImpact();
            setState(() => _marketType = value);
          }
        },
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value: _loanType,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Loan Type',
          border: OutlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        items: const ['NEW', 'ADDITIONAL', 'RENEWAL', 'PRETERM']
            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
            .toList(),
        onChanged: (value) {
          if (value != null) {
            HapticUtils.lightImpact();
            setState(() => _loanType = value);
          }
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _panController,
        decoration: const InputDecoration(
          labelText: 'PAN',
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
    ],
  );
}
```

- [ ] **Step 11: Rename `_buildRemarksSection` → `_buildNotesSection`**

```dart
// BEFORE
Widget _buildRemarksSection(ColorScheme colorScheme) {
  if (!_expandedSections['remarks']!) return const SizedBox.shrink();

// AFTER
Widget _buildNotesSection(ColorScheme colorScheme) {
  if (!_expandedSections['notes']!) return const SizedBox.shrink();
```

- [ ] **Step 12: Delete unused `_buildBasicInfoSection`, `_buildContactDetailsSection`, `_buildLocationSection`, `_buildRemarksSection` methods**

These four methods are now replaced by the new methods above. Delete them from the file.

- [ ] **Step 13: Run tests**

```bash
flutter test test/widget/clients/add_client_page_test.dart
```

Expected: All tests pass.

- [ ] **Step 14: Run analyzer**

```bash
flutter analyze lib/features/clients/presentation/pages/add_client_page.dart
```

Expected: No issues.

- [ ] **Step 15: Commit**

```bash
cd frontend-mobile-imu/imu_flutter
git add lib/features/clients/presentation/pages/add_client_page.dart \
        test/widget/clients/add_client_page_test.dart
git commit -m "feat: restructure add client page to 5-section layout with role-based save button"
```

---

## Task 2: Create `edit_client_page.dart`

**Files:**
- Create: `lib/features/clients/presentation/pages/edit_client_page.dart`
- Test: `test/widget/clients/edit_client_page_test.dart`

- [ ] **Step 1: Write failing widget tests**

Create `test/widget/clients/edit_client_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/features/clients/presentation/pages/edit_client_page.dart';
import 'package:imu_flutter/shared/providers/app_providers.dart';
import 'package:imu_flutter/core/models/user_role.dart';

void main() {
  Widget buildPage({UserRole role = UserRole.admin}) {
    return ProviderScope(
      overrides: [
        currentUserRoleProvider.overrideWithValue(role),
      ],
      child: const MaterialApp(
        home: EditClientPage(clientId: 'test-id'),
      ),
    );
  }

  testWidgets('AppBar shows Edit Client title', (tester) async {
    await tester.pumpWidget(buildPage());
    expect(find.text('Edit Client'), findsOneWidget);
  });

  testWidgets('shows Personal section', (tester) async {
    await tester.pumpWidget(buildPage());
    await tester.pump();
    expect(find.text('Personal'), findsOneWidget);
  });

  testWidgets('shows Contact section', (tester) async {
    await tester.pumpWidget(buildPage());
    await tester.pump();
    expect(find.text('Contact'), findsOneWidget);
  });

  testWidgets('shows Professional section', (tester) async {
    await tester.pumpWidget(buildPage());
    await tester.pump();
    expect(find.text('Professional'), findsOneWidget);
  });

  testWidgets('shows Product section', (tester) async {
    await tester.pumpWidget(buildPage());
    await tester.pump();
    expect(find.text('Product'), findsOneWidget);
  });

  testWidgets('shows Notes section', (tester) async {
    await tester.pumpWidget(buildPage());
    await tester.pump();
    expect(find.text('Notes'), findsOneWidget);
  });

  testWidgets('admin sees Save Changes button', (tester) async {
    await tester.pumpWidget(buildPage(role: UserRole.admin));
    await tester.pump();
    expect(find.text('Save Changes'), findsOneWidget);
  });

  testWidgets('caravan sees Submit for Approval button', (tester) async {
    await tester.pumpWidget(buildPage(role: UserRole.caravan));
    await tester.pump();
    expect(find.text('Submit for Approval'), findsOneWidget);
  });

  testWidgets('shows Cancel button', (tester) async {
    await tester.pumpWidget(buildPage());
    await tester.pump();
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('shows delete icon in AppBar', (tester) async {
    await tester.pumpWidget(buildPage());
    await tester.pump();
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
flutter test test/widget/clients/edit_client_page_test.dart
```

Expected: All FAILs (file not found).

- [ ] **Step 3: Create `edit_client_page.dart`**

Create `lib/features/clients/presentation/pages/edit_client_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/utils/app_notification.dart';
import '../../../../services/local_storage/hive_service.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../data/models/client_model.dart';
import '../../../psgc/data/models/psgc_models.dart';
import '../../../psgc/data/repositories/psgc_repository.dart';

class EditClientPage extends ConsumerStatefulWidget {
  final String clientId;

  const EditClientPage({super.key, required this.clientId});

  @override
  ConsumerState<EditClientPage> createState() => _EditClientPageState();
}

class _EditClientPageState extends ConsumerState<EditClientPage> {
  final _formKey = GlobalKey<FormState>();
  final _hiveService = HiveService();
  final _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isSaving = false;
  Client? _client;

  // Form controllers
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _facebookController = TextEditingController();
  final _agencyNameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _positionController = TextEditingController();
  final _employmentStatusController = TextEditingController();
  final _payrollDateController = TextEditingController();
  final _tenureController = TextEditingController();
  final _panController = TextEditingController();
  final _remarksController = TextEditingController();

  // Location
  PsgcRegion? _selectedRegion;
  PsgcProvince? _selectedProvince;
  PsgcMunicipality? _selectedMunicipality;
  PsgcBarangay? _selectedBarangay;

  List<PsgcRegion> _regions = [];
  List<PsgcProvince> _provinces = [];
  List<PsgcMunicipality> _municipalities = [];
  List<PsgcBarangay> _barangays = [];

  bool _isLoadingProvinces = false;
  bool _isLoadingMunicipalities = false;
  bool _isLoadingBarangays = false;

  String _productType = 'BFP ACTIVE';
  String _pensionType = 'SSS';
  String _marketType = 'Residential';
  String _clientType = 'POTENTIAL';
  String? _loanType;
  DateTime? _birthDate;

  final Map<String, bool> _expandedSections = {
    'personal': true,
    'contact': true,
    'professional': false,
    'product': false,
    'notes': false,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadClient());
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _facebookController.dispose();
    _agencyNameController.dispose();
    _departmentController.dispose();
    _positionController.dispose();
    _employmentStatusController.dispose();
    _payrollDateController.dispose();
    _tenureController.dispose();
    _panController.dispose();
    _remarksController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadClient() async {
    setState(() => _isLoading = true);
    try {
      final isOnline = ref.read(isOnlineProvider);
      Client? client;

      if (isOnline) {
        final clientApi = ref.read(clientApiServiceProvider);
        client = await clientApi.fetchClient(widget.clientId);
      }

      if (client == null) {
        final localData = _hiveService.getClient(widget.clientId);
        if (localData != null) client = Client.fromJson(localData);
      }

      final psgcRepository = await ref.read(psgcRepositoryProvider.future);
      final regions = await psgcRepository.getRegions();

      if (mounted) {
        setState(() {
          _client = client;
          _regions = regions;
          _isLoading = false;
        });
        if (client != null) _populateForm(client, psgcRepository);
      }
    } catch (e, stack) {
      debugPrint('[EditClientPage] Error loading: $e\n$stack');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _populateForm(Client client, dynamic psgcRepository) {
    _firstNameController.text = client.firstName;
    _middleNameController.text = client.middleName ?? '';
    _lastNameController.text = client.lastName;
    _emailController.text = client.email ?? '';
    _phoneController.text = client.phone ?? '';
    _facebookController.text = client.facebookLink ?? '';
    _agencyNameController.text = client.agencyName ?? '';
    _departmentController.text = client.department ?? '';
    _positionController.text = client.position ?? '';
    _employmentStatusController.text = client.employmentStatus ?? '';
    _payrollDateController.text = client.payrollDate ?? '';
    _tenureController.text = client.tenure?.toString() ?? '';
    _panController.text = client.pan ?? '';
    _remarksController.text = client.remarks ?? '';
    _birthDate = client.birthDate;

    if (client.productType != null) {
      _productType = _productTypeToString(client.productType!);
    }
    if (client.pensionType != null) {
      _pensionType = _pensionTypeToString(client.pensionType!);
    }
    if (client.marketType != null) {
      _marketType = _marketTypeToString(client.marketType!);
    }
    if (client.clientType != null) {
      _clientType = client.clientType == ClientType.existing ? 'EXISTING' : 'POTENTIAL';
    }
    if (client.loanType != null) {
      _loanType = _loanTypeToString(client.loanType!);
    }
  }

  String _productTypeToString(ProductType t) {
    switch (t) {
      case ProductType.bfpActive: return 'BFP ACTIVE';
      case ProductType.bfpPension: return 'BFP PENSION';
      case ProductType.pnpPension: return 'PNP PENSION';
      case ProductType.napolcom: return 'NAPOLCOM';
      case ProductType.bfpStp: return 'BFP STP';
    }
  }

  String _pensionTypeToString(PensionType t) {
    switch (t) {
      case PensionType.sss: return 'SSS';
      case PensionType.gsis: return 'GSIS';
      case PensionType.private: return 'Private';
      case PensionType.none: return 'None';
    }
  }

  String _marketTypeToString(MarketType t) {
    switch (t) {
      case MarketType.residential: return 'Residential';
      case MarketType.commercial: return 'Commercial';
      case MarketType.industrial: return 'Industrial';
    }
  }

  String? _loanTypeToString(LoanType t) {
    switch (t) {
      case LoanType.firstLoan: return 'NEW';
      case LoanType.additional: return 'ADDITIONAL';
      case LoanType.renewal: return 'RENEWAL';
      case LoanType.preterm: return 'PRETERM';
    }
  }

  ProductType _parseProductType(String value) {
    switch (value) {
      case 'BFP ACTIVE': return ProductType.bfpActive;
      case 'BFP PENSION': return ProductType.bfpPension;
      case 'PNP PENSION': return ProductType.pnpPension;
      case 'NAPOLCOM': return ProductType.napolcom;
      case 'BFP STP': return ProductType.bfpStp;
      default: return ProductType.bfpActive;
    }
  }

  PensionType _parsePensionType(String value) {
    switch (value) {
      case 'SSS': return PensionType.sss;
      case 'GSIS': return PensionType.gsis;
      case 'Private': return PensionType.private;
      default: return PensionType.none;
    }
  }

  MarketType _parseMarketType(String value) {
    switch (value) {
      case 'Residential': return MarketType.residential;
      case 'Commercial': return MarketType.commercial;
      default: return MarketType.industrial;
    }
  }

  ClientType _parseClientType(String value) {
    return value.toLowerCase() == 'existing' ? ClientType.existing : ClientType.potential;
  }

  LoanType? _parseLoanType(String? value) {
    if (value == null) return null;
    switch (value.toUpperCase()) {
      case 'NEW': return LoanType.firstLoan;
      case 'ADDITIONAL': return LoanType.additional;
      case 'RENEWAL': return LoanType.renewal;
      case 'PRETERM': return LoanType.preterm;
      default: return null;
    }
  }

  void _toggleSection(String section) {
    HapticUtils.lightImpact();
    setState(() => _expandedSections[section] = !_expandedSections[section]!);
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      HapticUtils.error();
      AppNotification.showError(context, 'Please fix the errors before saving');
      return;
    }

    HapticUtils.mediumImpact();
    setState(() => _isSaving = true);

    try {
      final updated = _client!.copyWith(
        firstName: _firstNameController.text.trim(),
        middleName: _middleNameController.text.trim().isEmpty ? null : _middleNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        facebookLink: _facebookController.text.trim().isEmpty ? null : _facebookController.text.trim(),
        agencyName: _agencyNameController.text.trim().isEmpty ? null : _agencyNameController.text.trim(),
        department: _departmentController.text.trim().isEmpty ? null : _departmentController.text.trim(),
        position: _positionController.text.trim().isEmpty ? null : _positionController.text.trim(),
        employmentStatus: _employmentStatusController.text.trim().isEmpty ? null : _employmentStatusController.text.trim(),
        payrollDate: _payrollDateController.text.trim().isEmpty ? null : _payrollDateController.text.trim(),
        tenure: _tenureController.text.trim().isEmpty ? null : int.tryParse(_tenureController.text.trim()),
        pan: _panController.text.trim().isEmpty ? null : _panController.text.trim(),
        remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
        birthDate: _birthDate,
        productType: _parseProductType(_productType),
        pensionType: _parsePensionType(_pensionType),
        marketType: _parseMarketType(_marketType),
        clientType: _parseClientType(_clientType),
        loanType: _parseLoanType(_loanType),
        region: _selectedRegion?.name ?? _client!.region,
        province: _selectedProvince?.name ?? _client!.province,
        municipality: _selectedMunicipality?.name ?? _client!.municipality,
        barangay: _selectedBarangay?.barangay ?? _client!.barangay,
        updatedAt: DateTime.now(),
      );

      final isOnline = ref.read(isOnlineProvider);

      if (isOnline) {
        final clientApi = ref.read(clientApiServiceProvider);
        await clientApi.updateClient(updated);
        if (mounted) {
          AppNotification.showSuccess(context, 'Client updated successfully');
          context.pop(true);
        }
      } else {
        await _hiveService.saveClient(widget.clientId, updated.toJson());
        if (mounted) {
          AppNotification.showWarning(context, 'Offline: Changes will sync when connected');
          context.pop(true);
        }
      }
    } catch (e, stack) {
      debugPrint('[EditClientPage] Error saving: $e\n$stack');
      HapticUtils.error();
      if (mounted) AppNotification.showError(context, 'Failed to save changes: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Client'),
        content: const Text('Are you sure you want to delete this client? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final clientApi = ref.read(clientApiServiceProvider);
        await clientApi.deleteClient(widget.clientId);
        if (mounted) {
          AppNotification.showSuccess(context, 'Client deleted');
          context.pop(true);
        }
      } catch (e) {
        if (mounted) AppNotification.showError(context, 'Failed to delete client: $e');
      }
    }
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required String sectionKey,
    required Color color,
  }) {
    final isExpanded = _expandedSections[sectionKey]!;
    return InkWell(
      onTap: () => _toggleSection(sectionKey),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color),
              ),
            ),
            Icon(isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalSection(ColorScheme colorScheme) {
    if (!_expandedSections['personal']!) return const SizedBox.shrink();

    int? age;
    if (_birthDate != null) {
      final now = DateTime.now();
      age = now.year - _birthDate!.year;
      if (now.month < _birthDate!.month || (now.month == _birthDate!.month && now.day < _birthDate!.day)) {
        age--;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name *', border: OutlineInputBorder(), isDense: true),
                validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _middleNameController,
                decoration: const InputDecoration(labelText: 'Middle Name', border: OutlineInputBorder(), isDense: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name *', border: OutlineInputBorder(), isDense: true),
                validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _birthDate ?? DateTime(1980),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _birthDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Birth Date',
                    border: OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: Icon(LucideIcons.calendar, size: 20),
                  ),
                  baseStyle: TextStyle(fontSize: 16, color: _birthDate != null ? Colors.black : Colors.grey),
                  child: Text(
                    _birthDate != null
                        ? '${_birthDate!.month}/${_birthDate!.day}/${_birthDate!.year}'
                        : 'Select birth date',
                  ),
                ),
              ),
            ),
            if (age != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Age',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  child: Text(
                    '$age years',
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // _buildContactSection, _buildProfessionalSection, _buildProductSection, _buildNotesSection
  // are identical to those in add_client_page.dart — same layout, same field list.
  // Copy them verbatim, replacing only the section-key guard at the top.
  // Example for contact:
  Widget _buildContactSection(ColorScheme colorScheme) {
    if (!_expandedSections['contact']!) return const SizedBox.shrink();
    // ... identical body to add_client_page._buildContactSection ...
    return const SizedBox.shrink(); // placeholder — replace with full body
  }

  Widget _buildProfessionalSection(ColorScheme colorScheme) {
    if (!_expandedSections['professional']!) return const SizedBox.shrink();
    // ... identical body to add_client_page._buildProfessionalSection ...
    return const SizedBox.shrink();
  }

  Widget _buildProductSection(ColorScheme colorScheme) {
    if (!_expandedSections['product']!) return const SizedBox.shrink();
    // ... identical body to add_client_page._buildProductSection ...
    return const SizedBox.shrink();
  }

  Widget _buildNotesSection(ColorScheme colorScheme) {
    if (!_expandedSections['notes']!) return const SizedBox.shrink();
    return TextFormField(
      controller: _remarksController,
      decoration: const InputDecoration(
        labelText: 'Remarks',
        hintText: 'Additional notes about this client...',
        border: OutlineInputBorder(),
      ),
      maxLines: 4,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final role = ref.watch(currentUserRoleProvider);
    final saveLabel = role == UserRole.admin ? 'Save Changes' : 'Submit for Approval';

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Edit Client')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Client'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete Client',
            onPressed: _handleDelete,
          ),
        ],
      ),
      body: Column(
        children: [
          // Created-at metadata line
          if (_client?.createdAt != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: Colors.grey.shade50,
              child: Text(
                'Created ${DateFormat('MMM d, yyyy').format(_client!.createdAt!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionHeader(title: 'Personal', icon: LucideIcons.user, sectionKey: 'personal', color: colorScheme.primary),
                  const SizedBox(height: 12),
                  _buildPersonalSection(colorScheme),
                  const SizedBox(height: 24),
                  _buildSectionHeader(title: 'Contact', icon: LucideIcons.phone, sectionKey: 'contact', color: colorScheme.primary),
                  const SizedBox(height: 12),
                  _buildContactSection(colorScheme),
                  const SizedBox(height: 24),
                  _buildSectionHeader(title: 'Professional', icon: LucideIcons.briefcase, sectionKey: 'professional', color: colorScheme.primary),
                  const SizedBox(height: 12),
                  _buildProfessionalSection(colorScheme),
                  const SizedBox(height: 24),
                  _buildSectionHeader(title: 'Product', icon: LucideIcons.creditCard, sectionKey: 'product', color: colorScheme.primary),
                  const SizedBox(height: 12),
                  _buildProductSection(colorScheme),
                  const SizedBox(height: 24),
                  _buildSectionHeader(title: 'Notes', icon: LucideIcons.messageSquare, sectionKey: 'notes', color: colorScheme.primary),
                  const SizedBox(height: 12),
                  _buildNotesSection(colorScheme),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : () => context.pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isSaving
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(saveLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientTypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _ClientTypeButton({
    required this.label,
    required this.isSelected,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? colorScheme.primary : Colors.grey[300]!),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
```

> **Note on section body methods:** The `_buildContactSection`, `_buildProfessionalSection`, and `_buildProductSection` bodies in `edit_client_page.dart` are **identical** to their counterparts in `add_client_page.dart`. Copy them verbatim from the completed Task 1 file — do not rewrite from scratch. Only the PSGC pre-selection logic in `_buildContactSection` needs an extra initialisation step: when `_client` has existing region/province/municipality values, call the PSGC repository to load the child lists and set `_selectedRegion`, `_selectedProvince`, `_selectedMunicipality`, `_selectedBarangay` in `_populateForm`.

- [ ] **Step 4: Add `intl` import resolution**

Check `pubspec.yaml` for `intl` dependency. If absent, add `intl: ^0.18.0` under `dependencies` and run:

```bash
flutter pub get
```

If `intl` is already present (check with `grep intl pubspec.yaml`), skip this step.

- [ ] **Step 5: Run tests**

```bash
flutter test test/widget/clients/edit_client_page_test.dart
```

Expected: All pass.

- [ ] **Step 6: Run analyzer**

```bash
flutter analyze lib/features/clients/presentation/pages/edit_client_page.dart
```

Expected: No issues.

- [ ] **Step 7: Commit**

```bash
git add lib/features/clients/presentation/pages/edit_client_page.dart \
        test/widget/clients/edit_client_page_test.dart
git commit -m "feat: add edit client full-page with 5-section layout and role-based save button"
```

---

## Task 3: Wire router and `client_detail_page.dart` to `EditClientPage`

**Files:**
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/features/clients/presentation/pages/client_detail_page.dart`

- [ ] **Step 1: Update `app_router.dart` — replace inline Scaffold with `EditClientPage`**

In `lib/core/router/app_router.dart`:

Add import at the top with the other client imports:
```dart
import '../../features/clients/presentation/pages/edit_client_page.dart';
```

Find the `/clients/:id/edit` GoRoute and replace its builder:

```dart
// BEFORE — inline Scaffold wrapping EditClientFormV2
GoRoute(
  path: '/clients/:id/edit',
  builder: (context, state) {
    final clientId = state.pathParameters['id']!;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Client'),
        actions: [ /* inline delete logic */ ],
      ),
      body: EditClientFormV2(
        clientId: clientId,
        onSave: (savedClient) {
          context.pop();
          return true;
        },
      ),
    );
  },
),

// AFTER — dedicated page
GoRoute(
  path: '/clients/:id/edit',
  builder: (context, state) {
    final clientId = state.pathParameters['id']!;
    return EditClientPage(clientId: clientId);
  },
),
```

Remove the import of `EditClientFormV2` from `app_router.dart`:

```dart
// DELETE this line:
import '../../features/clients/presentation/widgets/edit_client_form_v2.dart';
```

- [ ] **Step 2: Update `client_detail_page.dart` — replace `_editClient()` Navigator push with `context.push`**

In `lib/features/clients/presentation/pages/client_detail_page.dart`:

Find `Future<void> _editClient() async {` (around line 473).

Replace the entire method body with:

```dart
Future<void> _editClient() async {
  HapticUtils.lightImpact();
  final result = await context.push<bool>('/clients/${widget.clientId}/edit');
  if (result == true) {
    _loadClient();
    ref.invalidate(assignedClientsProvider);
  }
}
```

Remove the import of `EditClientFormV2` from `client_detail_page.dart`:

```dart
// DELETE this line:
import '../../../clients/presentation/widgets/edit_client_form_v2.dart';
```

- [ ] **Step 3: Run analyzer on modified files**

```bash
flutter analyze lib/core/router/app_router.dart \
                lib/features/clients/presentation/pages/client_detail_page.dart
```

Expected: No errors. If `clientApiServiceProvider` missing from client_detail_page imports, the original file already imports it — verify and leave untouched.

- [ ] **Step 4: Commit**

```bash
git add lib/core/router/app_router.dart \
        lib/features/clients/presentation/pages/client_detail_page.dart
git commit -m "feat: wire /clients/:id/edit route to EditClientPage, update client_detail_page navigation"
```

---

## Task 4: Delete `edit_client_form_v2.dart`

**Files:**
- Delete: `lib/features/clients/presentation/widgets/edit_client_form_v2.dart`

- [ ] **Step 1: Verify no remaining imports**

```bash
grep -r "edit_client_form_v2\|EditClientFormV2" lib/
```

Expected: No matches. If any remain, fix them before deleting.

- [ ] **Step 2: Delete the file**

```bash
rm lib/features/clients/presentation/widgets/edit_client_form_v2.dart
```

- [ ] **Step 3: Run full test suite**

```bash
flutter test
```

Expected: All tests pass, no compilation errors.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "chore: remove retired EditClientFormV2 widget"
```
