# Edit Client Form Component - Implementation Plan

**Date:** 2026-04-04
**Status:** Planning

---

## Overview

Create a reusable `EditClientForm` widget with improved UI/UX that can be used across the mobile app. The form will:
- Pre-load client values properly
- Submit edits for approval (caravan/tele) or direct update (admin)
- Have organized, categorized sections
- Better visual hierarchy
- Work offline with sync

---

## Design Requirements

### UI/UX Improvements

1. **Categorized Sections**
   - Basic Information (Name, Client Type)
   - Contact Details (Phone, Email, Facebook)
   - Product Information (Product Type, Pension Type, Market Type)
   - Address (Multiple addresses with add/remove)
   - Phone Numbers (Multiple numbers with labels)
   - Remarks

2. **Visual Hierarchy**
   - Section headers with icons
   - Collapsible sections (optional)
   - Clear field grouping
   - Better spacing and padding

3. **Better Form Experience**
   - Loading indicator with progress
   - Success/error feedback
   - Offline indicator
   - Save button with confirmation
   - Validation with clear error messages

4. **Responsive Design**
   - Works on mobile and tablet
   - Scrollable for long forms
   - Touch-friendly inputs

---

## Component Structure

### File: `lib/features/clients/presentation/widgets/edit_client_form.dart`

```dart
class EditClientForm extends ConsumerStatefulWidget {
  final String clientId;
  final Client? initialClient;
  final Function(Client)? onSave;
  final bool isModal; // Whether shown as modal or full page

  const EditClientForm({
    required this.clientId,
    this.initialClient,
    this.onSave,
    this.isModal = false,
  });
}

class _EditClientFormState extends ConsumerState<EditClientForm> {
  // Form state
  bool _isLoading = true;
  bool _isSaving = false;
  Client? _client;

  // Controllers
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _facebookController = TextEditingController();
  final _remarksController = TextEditingController();

  // Dropdown values
  String _productType = 'SSS Pensioner';
  String _pensionType = 'SSS';
  String _marketType = 'Residential';
  String _clientType = 'POTENTIAL';

  // Lists
  List<Address> _addresses = [];
  List<PhoneNumber> _phoneNumbers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadClient();
    });
  }

  Future<void> _loadClient() async { ... }
  Widget _buildBasicInfo() { ... }
  Widget _buildContactDetails() { ... }
  Widget _buildProductInfo() { ... }
  Widget _buildAddresses() { ... }
  Widget _buildPhoneNumbers() { ... }
  Widget _buildRemarks() { ... }
  Future<void> _handleSave() async { ... }
}
```

---

## Implementation Steps

### Step 1: Create the Component File
- Create `lib/features/clients/presentation/widgets/edit_client_form.dart`
- Define the widget structure
- Set up controllers and state

### Step 2: Implement Data Loading
- Load client from API or local storage
- Pre-populate all form fields
- Handle loading state
- Handle errors gracefully

### Step 3: Build UI Sections
- **Basic Info Section**: First, Middle, Last Name, Client Type toggle
- **Contact Details Section**: Email, Facebook, primary contact
- **Product Info Section**: Product Type, Pension Type, Market Type dropdowns
- **Address Section**: List of addresses with add/remove
- **Phone Numbers Section**: List of phone numbers with labels
- **Remarks Section**: Text area for notes

### Step 4: Implement Save Logic
- Validate all fields
- Build updated Client object
- Check connectivity
- Call API (online) or save locally (offline)
- Show success/error feedback
- Return result to parent

### Step 5: Update EditClientPage
- Replace current form with new `EditClientForm` widget
- Keep same route and navigation
- Test integration

### Step 6: Test Integration
- Test from Client Detail Page
- Test from My Day Page
- Test from Itinerary Page
- Test offline behavior
- Test approval workflow

---

## Data Flow

```
User clicks Edit → EditClientForm loads
                    ↓
            Load client data (API → Hive fallback)
                    ↓
            Pre-populate form fields
                    ↓
        User edits fields → Clicks Save
                    ↓
            Validate fields
                    ↓
        Build Client object
                    ↓
        Check connectivity
                    ↓
    ┌─── Online? ───┴── Offline?
    │                   │
    ↓                   ↓
Call API          Save to Hive
(creates approval)  (show warning)
    ↓                   ↓
Update Hive      Show success
    ↓
Show success
```

---

## Success Criteria

- [ ] Client values pre-loaded correctly
- [ ] All sections properly categorized
- [ ] Form validation works
- [ ] API submission creates approval request
- [ ] Offline mode saves locally with warning
- [ ] Success/error feedback shown
- [ ] Works from all three entry points
- [ ] No UI glitches or performance issues

---

## Files to Modify

1. **Create:** `lib/features/clients/presentation/widgets/edit_client_form.dart`
2. **Modify:** `lib/features/clients/presentation/pages/edit_client_page.dart`
3. **Update:** Router (if needed)

---

## Testing Checklist

- [ ] Pre-load values from API
- [ ] Pre-load values from Hive (offline)
- [ ] Edit all fields
- [ ] Save with valid data
- [ ] Save with invalid data (validation)
- [ ] Save offline
- [ ] Save online
- [ ] Check approval created in backend
- [ ] Test from Client Detail Page
- [ ] Test from My Day Page
- [ ] Test from Itinerary Page
- [ ] Test error handling
- [ ] Test loading state
