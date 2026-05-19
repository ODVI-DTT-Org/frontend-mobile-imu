# Add/Edit Client Wizard Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the single-scroll Add Client and Edit Client pages with a 5-step Wizard+Tabs hybrid — tappable step pills, Back/Next nav, per-step validation.

**Architecture:** Each page keeps its own `ConsumerStatefulWidget` state but the scrollable section-cards are replaced by a `Column(StepPillsRow + IndexedStack(5 Form steps) + StepNavBar)`. Step navigation state (`_currentStep`, `_completedSteps`, 5 per-step `GlobalKey<FormState>`) is added to the existing state classes. No new files are needed.

**Tech Stack:** Flutter, Riverpod (`ConsumerStatefulWidget`), `go_router`, `lucide_icons`, existing PSGC repository providers.

---

## Context

Files to modify (both in `imu_flutter/lib/features/clients/presentation/pages/`):
- `add_client_page.dart` — currently ~1300 lines, single scroll with collapsible sections
- `edit_client_page.dart` — currently ~1282 lines, same structure but pre-populates from a Client

Key field moves vs current layout:
- **Client Type** chips: move from Product section → Step 1 Personal
- **Location dropdowns** (PSGC): split out of Contact section → Step 3 Location
- **PAN**: move from Product section → Step 4 Work
- **Employment Status**: drop (not in spec)
- **Loan Type**: add `validator: (v) => v == null ? 'Required' : null` (now required)
- **Barangay**: add `validator: (v) => v == null ? 'Required' : null` (now required)

Step layout:
| Step | Fields |
|---|---|
| 1 Personal | First Name*, Last Name* (row), Middle Name, Birth Date, Client Type* (chips) |
| 2 Contact | Phone*, Email, Facebook |
| 3 Location | Region*, Province*, Municipality*, Barangay* (PSGC cascade) |
| 4 Work | Agency, Position+Department (row), PAN, Payroll Date+Tenure (row) |
| 5 Product+Notes | Product Type*, Pension Type*, Market Type*, Loan Type*, Remarks |

---

## Task 1: Rewrite `add_client_page.dart`

**Files:**
- Modify: `imu_flutter/lib/features/clients/presentation/pages/add_client_page.dart`

- [ ] **Step 1: Replace state class fields**

Remove from `_AddClientPageState`:
```dart
// REMOVE these 3 lines:
final _scrollController = ScrollController();
final _employmentStatusController = TextEditingController();
final Map<String, bool> _expandedSections = { ... };
```

Add after the existing field declarations:
```dart
  // Wizard navigation
  int _currentStep = 0;
  final Set<int> _completedSteps = {};
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();
  final _step4Key = GlobalKey<FormState>();
  final _step5Key = GlobalKey<FormState>();
```

- [ ] **Step 2: Update dispose()**

Remove `_scrollController.dispose();` and `_employmentStatusController.dispose();` from the dispose method. The result:

```dart
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
    _payrollDateController.dispose();
    _tenureController.dispose();
    _panController.dispose();
    _remarksController.dispose();
    super.dispose();
  }
```

- [ ] **Step 3: Replace `_handleSubmit` to validate all 5 steps**

Replace the first `if (!_formKey.currentState!.validate())` guard with:

```dart
  Future<void> _handleSubmit() async {
    final allValid = [_step1Key, _step2Key, _step3Key, _step4Key, _step5Key]
        .every((key) => key.currentState?.validate() ?? false);
    if (!allValid) {
      HapticUtils.error();
      if (mounted) AppNotification.showError(context, 'Please fill in all required fields');
      return;
    }
    // rest of method unchanged from here (HapticUtils.mediumImpact(), setState isSaving, etc.)
```

- [ ] **Step 4: Remove helpers that are no longer needed**

Delete these two methods entirely:
- `void _toggleSection(String section)` 
- `Widget _buildSectionHeader({...})`

- [ ] **Step 5: Add navigation methods**

Add after `_showErrorSnackBar`:

```dart
  List<GlobalKey<FormState>> get _stepKeys =>
      [_step1Key, _step2Key, _step3Key, _step4Key, _step5Key];

  void _goToStep(int step) {
    HapticUtils.lightImpact();
    setState(() => _currentStep = step);
  }

  void _nextStep() {
    if (!_stepKeys[_currentStep].currentState!.validate()) {
      HapticUtils.error();
      return;
    }
    HapticUtils.lightImpact();
    setState(() {
      _completedSteps.add(_currentStep);
      _currentStep++;
    });
  }

  void _prevStep() {
    HapticUtils.lightImpact();
    setState(() => _currentStep--);
  }
```

- [ ] **Step 6: Add `_buildStepPillsRow()`**

Add this method:

```dart
  Widget _buildStepPillsRow() {
    const labels = ['👤 Personal', '📞 Contact', '📍 Location', '💼 Work', '💳 Product'];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: List.generate(5, (i) {
            final isDone = _completedSteps.contains(i);
            final isActive = _currentStep == i;
            return GestureDetector(
              onTap: () => _goToStep(i),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF6366F1)
                      : isDone
                          ? const Color(0xFFEDE9FE)
                          : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isDone ? '✓ ${labels[i].substring(3)}' : labels[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isActive
                        ? Colors.white
                        : isDone
                            ? const Color(0xFF5B21B6)
                            : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
```

- [ ] **Step 7: Add `_buildStepNavBar(String saveLabel)`**

Add this method:

```dart
  Widget _buildStepNavBar(String saveLabel) {
    const nextLabels = ['Contact', 'Location', 'Work', 'Product'];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _isSaving ? null : _prevStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('← Back', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (_currentStep < 4)
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Next: ${nextLabels[_currentStep]} →',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (_currentStep == 4)
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(saveLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }
```

- [ ] **Step 8: Add step content builders**

Add these 5 methods. They replace the old `_buildPersonalSection`, `_buildContactSection`, etc.

```dart
  Widget _buildStep1Personal() {
    return Form(
      key: _step1Key,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Personal Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name *',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name *',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _middleNameController,
              decoration: const InputDecoration(
                labelText: 'Middle Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            InkWell(
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
                  suffixIcon: Icon(LucideIcons.calendar, size: 20),
                ),
                child: Text(
                  _birthDate != null
                      ? '${_birthDate!.month}/${_birthDate!.day}/${_birthDate!.year}'
                      : 'Select birth date',
                  style: TextStyle(
                    color: _birthDate != null ? Colors.black87 : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Client Type *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ClientTypeButton(
                    label: 'Potential',
                    isSelected: _clientType == 'POTENTIAL',
                    colorScheme: Theme.of(context).colorScheme,
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
                    colorScheme: Theme.of(context).colorScheme,
                    onTap: () {
                      HapticUtils.selectionClick();
                      setState(() => _clientType = 'EXISTING');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2Contact() {
    return Form(
      key: _step2Key,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Contact Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                hintText: '+63 912 345 6789',
                prefixIcon: Icon(LucideIcons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'email@example.com',
                prefixIcon: Icon(LucideIcons.mail),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _facebookController,
              decoration: const InputDecoration(
                labelText: 'Facebook Profile',
                hintText: 'Facebook profile URL or name',
                prefixIcon: Icon(LucideIcons.facebook),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3Location() {
    return Form(
      key: _step3Key,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Location',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            DropdownButtonFormField<PsgcRegion>(
              value: _selectedRegion,
              decoration: InputDecoration(
                labelText: 'Region *',
                border: const OutlineInputBorder(),
                suffixIcon: _regions.isEmpty
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : null,
              ),
              items: _regions
                  .map((r) => DropdownMenuItem(value: r, child: Text(r.name)))
                  .toList(),
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
                    final psgcRepository = ref.read(psgcRepositoryProvider);
                    final provinces =
                        await psgcRepository.getProvincesByRegion(region.name);
                    if (mounted) {
                      setState(() {
                        _provinces = provinces;
                        _isLoadingProvinces = false;
                      });
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() => _isLoadingProvinces = false);
                      _showErrorDialog('Failed to load provinces', e);
                    }
                  }
                }
              },
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            IgnorePointer(
              ignoring: _selectedRegion == null || _isLoadingProvinces,
              child: DropdownButtonFormField<PsgcProvince>(
                value: _selectedProvince,
                decoration: InputDecoration(
                  labelText: 'Province *',
                  border: const OutlineInputBorder(),
                  filled: _selectedRegion == null,
                  fillColor: _selectedRegion == null ? Colors.grey.shade100 : null,
                  hintText: _selectedRegion == null ? 'Select region first' : null,
                  suffixIcon: _isLoadingProvinces
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : null,
                ),
                items: _provinces.isEmpty && _selectedRegion != null && !_isLoadingProvinces
                    ? [const DropdownMenuItem<PsgcProvince>(
                        value: null, enabled: false,
                        child: Text('No provinces available',
                            style: TextStyle(color: Colors.grey)))]
                    : _provinces
                        .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                        .toList(),
                onChanged: _selectedRegion == null
                    ? null
                    : (province) async {
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
                            final psgcRepository = ref.read(psgcRepositoryProvider);
                            final municipalities = await psgcRepository
                                .getMunicipalitiesByProvince(province.name);
                            if (mounted) {
                              setState(() {
                                _municipalities = municipalities;
                                _isLoadingMunicipalities = false;
                              });
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() => _isLoadingMunicipalities = false);
                              _showErrorDialog('Failed to load municipalities', e);
                            }
                          }
                        }
                      },
                validator: (v) => v == null ? 'Required' : null,
              ),
            ),
            const SizedBox(height: 16),
            IgnorePointer(
              ignoring: _selectedProvince == null || _isLoadingMunicipalities,
              child: DropdownButtonFormField<PsgcMunicipality>(
                value: _selectedMunicipality,
                decoration: InputDecoration(
                  labelText: 'Municipality / City *',
                  border: const OutlineInputBorder(),
                  filled: _selectedProvince == null,
                  fillColor: _selectedProvince == null ? Colors.grey.shade100 : null,
                  hintText: _selectedProvince == null ? 'Select province first' : null,
                  suffixIcon: _isLoadingMunicipalities
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : null,
                ),
                items: _municipalities.isEmpty &&
                        _selectedProvince != null &&
                        !_isLoadingMunicipalities
                    ? [const DropdownMenuItem<PsgcMunicipality>(
                        value: null, enabled: false,
                        child: Text('No municipalities available',
                            style: TextStyle(color: Colors.grey)))]
                    : _municipalities
                        .map((m) => DropdownMenuItem(
                            value: m, child: Text(m.displayName)))
                        .toList(),
                onChanged: _selectedProvince == null
                    ? null
                    : (municipality) async {
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
                validator: (v) => v == null ? 'Required' : null,
              ),
            ),
            const SizedBox(height: 16),
            IgnorePointer(
              ignoring: _selectedMunicipality == null || _isLoadingBarangays,
              child: DropdownButtonFormField<PsgcBarangay>(
                value: _selectedBarangay,
                decoration: InputDecoration(
                  labelText: 'Barangay *',
                  border: const OutlineInputBorder(),
                  filled: _selectedMunicipality == null,
                  fillColor:
                      _selectedMunicipality == null ? Colors.grey.shade100 : null,
                  hintText:
                      _selectedMunicipality == null ? 'Select municipality first' : null,
                  suffixIcon: _isLoadingBarangays
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : null,
                ),
                items: _barangays.isEmpty &&
                        _selectedMunicipality != null &&
                        !_isLoadingBarangays
                    ? [const DropdownMenuItem<PsgcBarangay>(
                        value: null, enabled: false,
                        child: Text('No barangays available',
                            style: TextStyle(color: Colors.grey)))]
                    : _barangays
                        .map((b) => DropdownMenuItem(
                            value: b, child: Text(b.barangay ?? 'Unknown')))
                        .toList(),
                onChanged: _selectedMunicipality == null
                    ? null
                    : (barangay) {
                        HapticUtils.lightImpact();
                        setState(() => _selectedBarangay = barangay);
                      },
                validator: (v) => v == null ? 'Required' : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep4Work() {
    return Form(
      key: _step4Key,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Work & Employment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _agencyNameController,
              decoration: const InputDecoration(
                labelText: 'Agency Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _positionController,
                    decoration: const InputDecoration(
                      labelText: 'Position',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _departmentController,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _panController,
              decoration: const InputDecoration(
                labelText: 'PAN (Pension Account No.)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _payrollDateController,
                    decoration: const InputDecoration(
                      labelText: 'Payroll Date',
                      hintText: 'YYYY-MM-DD',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _tenureController,
                    decoration: const InputDecoration(
                      labelText: 'Tenure (months)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep5ProductNotes() {
    return Form(
      key: _step5Key,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Product & Notes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _productType,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Product Type *',
                border: OutlineInputBorder(),
              ),
              items: const ['BFP ACTIVE', 'BFP PENSION', 'BFP STP', 'NAPOLCOM', 'PNP PENSION']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (v) {
                if (v != null) { HapticUtils.lightImpact(); setState(() => _productType = v); }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _pensionType,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Pension Type *',
                border: OutlineInputBorder(),
              ),
              items: const [
                'PNP - RETIREE OPTIONAL', 'PNP - RETIREE COMPULSORY', 'PNP - RETIREE',
                'BFP - RETIREE', 'BFP STP - RETIREE', 'PNP - TRANSFEREE',
                'BFP - SURVIVOR', 'PNP - SURVIVOR', 'PNP - TPPD', 'BFP - TPPD',
                'PNP - MINOR', 'BFP - MINOR', 'PNP - POSTHUMOUS MINOR',
                'PNP - POSTHUMOUS SPOUSE', 'OTHERS',
              ]
                  .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (v) {
                if (v != null) { HapticUtils.lightImpact(); setState(() => _pensionType = v); }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _marketType,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Market Type *',
                border: OutlineInputBorder(),
              ),
              items: const ['VIRGIN', 'EXISTING', 'FULLY PAID']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) {
                if (v != null) { HapticUtils.lightImpact(); setState(() => _marketType = v); }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _loanType,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Loan Type *',
                border: OutlineInputBorder(),
              ),
              items: const ['NEW', 'ADDITIONAL', 'RENEWAL', 'PRETERM']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) {
                if (v != null) { HapticUtils.lightImpact(); setState(() => _loanType = v); }
              },
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _remarksController,
              decoration: const InputDecoration(
                labelText: 'Remarks / Notes',
                hintText: 'Add any notes about this client...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }
```

- [ ] **Step 9: Replace `build()` method**

Replace the entire `build()` method (from `@override Widget build(BuildContext context)` to the closing `}`) with:

```dart
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Add Client')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...'),
            ],
          ),
        ),
      );
    }

    final role = ref.watch(currentUserRoleProvider);
    final saveLabel = role == UserRole.admin ? 'Save Client' : 'Submit for Approval';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Add Client')),
      body: Column(
        children: [
          _buildStepPillsRow(),
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                _buildStep1Personal(),
                _buildStep2Contact(),
                _buildStep3Location(),
                _buildStep4Work(),
                _buildStep5ProductNotes(),
              ],
            ),
          ),
          _buildStepNavBar(saveLabel),
        ],
      ),
    );
  }
```

- [ ] **Step 10: Delete old section builder methods**

Delete these methods entirely — they are replaced by the step builders above:
- `Widget _buildPersonalSection(ColorScheme colorScheme)`
- `Widget _buildContactSection(ColorScheme colorScheme)`
- `Widget _buildProfessionalSection(ColorScheme colorScheme)`
- `Widget _buildProductSection(ColorScheme colorScheme)`
- `Widget _buildNotesSection(ColorScheme colorScheme)`

- [ ] **Step 11: Analyze and commit**

```bash
cd /home/claude-team/loi/imu/frontend-mobile-imu/imu_flutter
flutter analyze lib/features/clients/presentation/pages/add_client_page.dart
```

Expected: no errors. Fix any `unused import` or missing variable errors before committing.

```bash
git add imu_flutter/lib/features/clients/presentation/pages/add_client_page.dart
git commit -m "feat: redesign AddClientPage as 5-step wizard with pill navigation"
```

---

## Task 2: Rewrite `edit_client_page.dart`

**Files:**
- Modify: `imu_flutter/lib/features/clients/presentation/pages/edit_client_page.dart`

Apply the same structural changes as Task 1 with these differences for edit mode:

- [ ] **Step 1: Add wizard state fields** (same as Task 1 Step 1)

Same additions: `_currentStep`, `_completedSteps`, `_step1Key`–`_step5Key`.

Remove: no `_scrollController` (edit page also has one — delete it), remove `_employmentStatusController`.

- [ ] **Step 2: Update dispose()** (same removals as Task 1 Step 2)

- [ ] **Step 3: Update `_populateFormFields()` to pre-mark all steps done**

At the end of `_populateFormFields()`, add:

```dart
    // In edit mode all steps start completed so the user can jump freely
    setState(() {
      _completedSteps.addAll({0, 1, 2, 3, 4});
    });
```

- [ ] **Step 4: Update `_handleSave` to validate all 5 steps**

Replace the `if (!_formKey.currentState!.validate())` guard:

```dart
  Future<void> _handleSave() async {
    final allValid = [_step1Key, _step2Key, _step3Key, _step4Key, _step5Key]
        .every((key) => key.currentState?.validate() ?? false);
    if (!allValid) {
      HapticUtils.error();
      if (mounted) AppNotification.showError(context, 'Please fix the errors before saving');
      return;
    }
    // rest of method unchanged
```

- [ ] **Step 5: Add navigation methods** (identical to Task 1 Step 5)

Add `_stepKeys` getter, `_goToStep`, `_nextStep`, `_prevStep`.

- [ ] **Step 6: Add `_buildStepPillsRow()`** (identical to Task 1 Step 6)

- [ ] **Step 7: Add `_buildStepNavBar(String saveLabel)`**

Same as Task 1 Step 7, but `saveLabel` in edit mode is always `'Save Changes'`:

```dart
    final saveLabel = 'Save Changes';
```
(This change goes in `build()`, not in the nav bar method itself.)

- [ ] **Step 8: Add step content builders** (identical to Task 1 Step 8)

Copy the 5 `_buildStepN...()` methods from add_client_page.dart verbatim. They reference the same controller/state field names.

- [ ] **Step 9: Replace `build()` method**

```dart
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Edit Client')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...'),
            ],
          ),
        ),
      );
    }

    const saveLabel = 'Save Changes';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Edit Client')),
      body: Column(
        children: [
          _buildStepPillsRow(),
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                _buildStep1Personal(),
                _buildStep2Contact(),
                _buildStep3Location(),
                _buildStep4Work(),
                _buildStep5ProductNotes(),
              ],
            ),
          ),
          _buildStepNavBar(saveLabel),
        ],
      ),
    );
  }
```

- [ ] **Step 10: Delete old section builders** (same list as Task 1 Step 10)

Delete `_buildSectionHeader`, `_toggleSection`, `_buildPersonalSection`, `_buildContactSection`, `_buildProfessionalSection`, `_buildProductSection`, `_buildNotesSection`.

- [ ] **Step 11: Remove unused `_formKey`** 

Delete the line `final _formKey = GlobalKey<FormState>();` from the state class — it's replaced by the 5 per-step keys.

- [ ] **Step 12: Analyze and commit**

```bash
cd /home/claude-team/loi/imu/frontend-mobile-imu/imu_flutter
flutter analyze lib/features/clients/presentation/pages/edit_client_page.dart
```

Expected: no errors.

```bash
git add imu_flutter/lib/features/clients/presentation/pages/edit_client_page.dart
git commit -m "feat: redesign EditClientPage as 5-step wizard with pill navigation"
```

---

## Self-review notes

- **Spec coverage**: All 5 steps covered. All required fields (*) have validators. Client Type chip has a default so no validator needed — always valid.
- **Type consistency**: `_stepKeys` getter returns same 5 keys used in `_nextStep` and `_handleSubmit`/`_handleSave`. All `_buildStepN` methods referenced in `IndexedStack` match method names.
- **Edit mode pre-fill**: `_populateFormFields` marks all 5 steps completed → pills show ✓ and user can jump freely.
- **Employment Status**: removed from both pages (not in spec). `_employmentStatusController` removed from state and dispose.
- **PAN**: moved from Product section to Step 4 Work builder.
- **Barangay validator**: added `validator: (v) => v == null ? 'Required' : null` in Step 3.
- **Loan Type validator**: added `validator: (v) => v == null ? 'Required' : null` in Step 5.
