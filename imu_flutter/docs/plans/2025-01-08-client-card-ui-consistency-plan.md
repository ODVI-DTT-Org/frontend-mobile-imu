# Client Card UI Consistency & Naming Convention Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Unify client card design across My Day and Itinerary pages while fixing client naming convention to "Last, First Middle" format throughout the mobile app.

**Architecture:** Create shared ClientListCard widget that both My Day and Itinerary pages will use, replacing their current card implementations. Fix Client.fullName getter and audit all name displays for consistency.

**Tech Stack:** Flutter 3.2+, Dart, Riverpod state management, Lucide icons

---

## File Structure Map

**New File:**
- `lib/shared/widgets/client/client_list_card.dart` - Shared client card widget for My Day/Itinerary

**Modified Files:**
- `lib/features/clients/data/models/client_model.dart` - Update fullName getter
- `lib/features/my_day/presentation/pages/my_day_page.dart` - Use ClientListCard, add Navigate action
- `lib/features/itinerary/presentation/pages/itinerary_page.dart` - Use ClientListCard, add Navigate action
- `lib/shared/widgets/action_bottom_sheet.dart` - Add Navigate option support

**Deleted File:**
- `lib/features/my_day/presentation/widgets/client_card.dart` - Replaced by shared widget

**Files to Audit for Naming:**
- `lib/shared/widgets/client/client_list_tile.dart`
- `lib/features/clients/presentation/pages/client_detail_page.dart`
- `lib/shared/widgets/touchpoint_history_dialog.dart`
- `lib/shared/widgets/client_selector_modal.dart`

---

## Task 1: Fix Client.fullName Getter (Naming Convention Foundation)

**Files:**
- Modify: `lib/features/clients/data/models/client_model.dart:78`

- [ ] **Step 1: Read current fullName getter implementation**

Open `lib/features/clients/data/models/client_model.dart` and locate the `fullName` getter (around line 78).

Current code:
```dart
String get fullName => '$firstName ${middleName != null ? '$middleName ' : ''}$lastName';
```

- [ ] **Step 2: Update fullName getter to "Last, First Middle" format**

Replace the fullName getter with:

```dart
/// Returns client name in "LastName, FirstName MiddleName" format
/// Example: "Delos Santos, Juan Miguel"
String get fullName => '$lastName, $firstName${middleName != null ? ' $middleName' : ''}';
```

- [ ] **Step 3: Verify no other name formatters in Client model**

Search `client_model.dart` for any other name-related getters or methods that might conflict with the new format.

- [ ] **Step 4: Commit naming convention fix**

```bash
cd mobile/imu_flutter
git add lib/features/clients/data/models/client_model.dart
git commit -m "fix(client): update fullName to 'Last, First Middle' format

- Change from 'First Middle Last' to 'Last, First Middle'
- Example: 'Delos Santos, Juan Miguel' instead of 'Juan Miguel Delos Santos'
- Affects all displays using client.fullName getter

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 2: Audit client_list_tile.dart for Name Usage

**Files:**
- Modify: `lib/shared/widgets/client/client_list_tile.dart`

- [ ] **Step 1: Search for direct name concatenation**

Open `lib/shared/widgets/client/client_list_tile.dart` and search for:
- Direct string concatenation with firstName/lastName
- Any custom name formatting logic
- References to `client.fullName`

- [ ] **Step 2: Verify client.fullName is used correctly**

Check that the widget uses `client.fullName` getter (not manual concatenation).

Line 124 should show:
```dart
client.fullName,
```

If manual concatenation exists, replace with `client.fullName`.

- [ ] **Step 3: Check for any name display in _getInitials()**

Verify the `_getInitials()` method (lines 243-251) still works correctly with new name format:
```dart
String _getInitials() {
  final firstNameInitial = client.firstName.isNotEmpty
      ? client.firstName[0].toUpperCase()
      : '';
  final lastNameInitial = client.lastName.isNotEmpty
      ? client.lastName[0].toUpperCase()
      : '';
  return '$firstNameInitial$lastNameInitial';
}
```

This method is correct - it uses firstName and lastName directly, not fullName.

- [ ] **Step 4: Commit if changes made**

```bash
cd mobile/imu_flutter
git add lib/shared/widgets/client/client_list_tile.dart
git commit -m "refactor(client): ensure client_list_tile uses fullName getter

- Verify all name displays use client.fullName for consistency
- No functional changes - naming convention compliance

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 3: Audit client_detail_page.dart for Name Usage

**Files:**
- Modify: `lib/features/clients/presentation/pages/client_detail_page.dart`

- [ ] **Step 1: Search for name display patterns**

Search for:
- `firstName`, `lastName`, `middleName` usage
- Manual name concatenation
- References to `client.fullName`

- [ ] **Step 2: Replace any manual concatenation with fullName getter**

If you find patterns like:
```dart
Text('${client.firstName} ${client.lastName}')
```

Replace with:
```dart
Text(client.fullName)
```

- [ ] **Step 3: Verify app bar title uses fullName**

Check that the app bar or page header uses `client.fullName`.

- [ ] **Step 4: Commit if changes made**

```bash
cd mobile/imu_flutter
git add lib/features/clients/presentation/pages/client_detail_page.dart
git commit -m "refactor(client): ensure client_detail_page uses fullName getter

- Replace manual name concatenation with client.fullName
- Consistent 'Last, First Middle' format

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 4: Audit touchpoint_history_dialog.dart for Name Usage

**Files:**
- Modify: `lib/shared/widgets/touchpoint_history_dialog.dart`

- [ ] **Step 1: Open and search for name display patterns**

Search for firstName/lastName concatenation in client name displays.

- [ ] **Step 2: Replace with fullName getter**

Ensure all client name displays use `client.fullName`.

- [ ] **Step 3: Commit if changes made**

```bash
cd mobile/imu_flutter
git add lib/shared/widgets/touchpoint_history_dialog.dart
git commit -m "refactor(client): ensure touchpoint_history_dialog uses fullName getter

- Consistent 'Last, First Middle' format across touchpoint history

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 5: Audit client_selector_modal.dart for Name Usage

**Files:**
- Modify: `lib/shared/widgets/client_selector_modal.dart`

- [ ] **Step 1: Search for name display patterns**

Look for client name displays in the modal list items.

- [ ] **Step 2: Replace with fullName getter**

Ensure all uses `client.fullName`.

- [ ] **Step 3: Commit if changes made**

```bash
cd mobile/imu_flutter
git add lib/shared/widgets/client_selector_modal.dart
git commit -m "refactor(client): ensure client_selector_modal uses fullName getter

- Consistent 'Last, First Middle' format in client selection

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 6: Create Shared ClientListCard Widget

**Files:**
- Create: `lib/shared/widgets/client/client_list_card.dart`

- [ ] **Step 1: Create new ClientListCard widget file**

Create `lib/shared/widgets/client/client_list_card.dart` with the following structure:

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../features/clients/data/models/client_model.dart';
import '../../../core/utils/haptic_utils.dart';
import 'touchpoint_progress_badge.dart';
import 'touchpoint_status_badge.dart';
import '../client/client_status_badge.dart';

/// Shared client card widget for My Day and Itinerary pages
/// Provides consistent client display with multi-select support
class ClientListCard extends StatelessWidget {
  final Client client;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onRemove;
  final bool isSelected;
  final bool isMultiSelectMode;
  final bool enableSwipeToDismiss;
  final bool showInMyDayBadge;
  final int? touchpointCount;
  final String? scheduledDate;

  const ClientListCard({
    super.key,
    required this.client,
    this.onTap,
    this.onLongPress,
    this.onRemove,
    this.isSelected = false,
    this.isMultiSelectMode = false,
    this.enableSwipeToDismiss = false,
    this.showInMyDayBadge = false,
    this.touchpointCount,
    this.scheduledDate,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = _buildCardContent(context);

    // Only enable swipe-to-dismiss when enabled and NOT in multi-select mode
    if (enableSwipeToDismiss && !isMultiSelectMode) {
      return Dismissible(
        key: Key('client_${client.id}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) {
          HapticUtils.mediumImpact();
          onRemove?.call();
        },
        background: _buildSwipeBackground(),
        child: cardContent,
      );
    }

    return cardContent;
  }

  Widget _buildCardContent(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticUtils.lightImpact();
        onTap?.call();
      },
      onLongPress: () {
        HapticUtils.mediumImpact();
        onLongPress?.call();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopRow(context),
              const SizedBox(height: 8),
              _buildBadgesRow(),
              const SizedBox(height: 8),
              _buildAddressRow(),
              if (client.touchpoints.isNotEmpty) ...[
                const SizedBox(height: 4),
                _buildTouchpointSummary(),
              ],
              if (client.touchpoints.isNotEmpty &&
                  client.touchpoints.last.reason != null) ...[
                const SizedBox(height: 4),
                _buildTouchpointReason(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow(BuildContext context) {
    final latestTouchpoint = client.touchpoints.isNotEmpty
        ? client.touchpoints.last
        : null;
    final isFirstTime = client.touchpoints.isEmpty;

    return Row(
      children: [
        // NEW badge or Touchpoint ordinal badge
        if (isFirstTime)
          _buildNewBadge()
        else if (latestTouchpoint != null)
          _buildTouchpointOrdinalBadge(latestTouchpoint.touchpointNumber),

        if (!isFirstTime || latestTouchpoint != null)
          const SizedBox(width: 12),

        // Client name
        Expanded(
          child: Text(
            client.fullName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // "In My Day" badge
        if (showInMyDayBadge)
          _buildInMyDayBadge(),
      ],
    );
  }

  Widget _buildNewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFF22C55E).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: const Text(
        'NEW',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF16A34A),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTouchpointOrdinalBadge(int touchpointNumber) {
    final ordinal = _getOrdinal(touchpointNumber);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$touchpointNumber$ordinal',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFF3B82F6),
        ),
      ),
    );
  }

  Widget _buildInMyDayBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.check,
            size: 10,
            color: const Color(0xFF22C55E),
          ),
          const SizedBox(width: 2),
          const Text(
            'In My Day',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Color(0xFF22C55E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesRow() {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        TouchpointProgressBadge(
          client: client,
          touchpointCount: touchpointCount,
        ),
        const TouchpointStatusBadge(
          client: null, // Will be passed correctly in usage
        ),
        if (client.loanReleased)
          _buildLoanReleasedBadge(),
      ],
    );
  }

  Widget _buildLoanReleasedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.dollarSign,
            size: 10,
            color: const Color(0xFF16A34A),
          ),
          const SizedBox(width: 4),
          Text(
            'Loan Released${client.udi != null ? ': ${client.udi}' : ''}',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow() {
    return Row(
      children: [
        Icon(
          LucideIcons.mapPin,
          size: 14,
          color: Colors.grey.shade400,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            client.fullAddress ?? 'No address',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTouchpointSummary() {
    final latestTouchpoint = client.touchpoints.last;
    final ordinal = _getOrdinal(latestTouchpoint.touchpointNumber);
    final type = latestTouchpoint.type == TouchpointType.visit ? 'Visit' : 'Call';
    final timeAgo = _getTimeAgo(latestTouchpoint.date);

    return Row(
      children: [
        Icon(
          latestTouchpoint.type == TouchpointType.visit
              ? LucideIcons.mapPin
              : LucideIcons.phone,
          size: 12,
          color: const Color(0xFF64748B),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '$ordinal $type - $timeAgo',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTouchpointReason() {
    final latestTouchpoint = client.touchpoints.last;
    if (latestTouchpoint.reason == null) return const SizedBox.shrink();

    return Row(
      children: [
        const Icon(
          LucideIcons.messageCircle,
          size: 12,
          color: Color(0xFF94A3B8),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            latestTouchpoint.reason!.apiValue,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
              fontStyle: FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSwipeBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Remove',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 8),
          Icon(
            LucideIcons.trash2,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  String _getOrdinal(int number) {
    if (number >= 11 && number <= 13) return 'th';
    switch (number % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        final minutes = difference.inMinutes;
        return minutes <= 1 ? 'just now' : '${minutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? 'last week' : '${weeks}w ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? 'last month' : '${months}mo ago';
    }
  }
}
```

- [ ] **Step 2: Fix TouchpointStatusBadge instantiation**

Update line 257 to correctly pass the client:
```dart
TouchpointStatusBadge(client: client),
```

- [ ] **Step 3: Commit new widget**

```bash
cd mobile/imu_flutter
git add lib/shared/widgets/client/client_list_card.dart
git commit -m "feat(client): add shared ClientListCard widget

- Unified card design for My Day and Itinerary pages
- Multi-select support with checkbox overlay
- Optional swipe-to-dismiss functionality
- Shows: name, progress, status, loan released, address, touchpoint info
- Uses 'Last, First Middle' naming convention

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 7: Update My Day Page to Use ClientListCard

**Files:**
- Modify: `lib/features/my_day/presentation/pages/my_day_page.dart`

- [ ] **Step 1: Remove old ClientCard import**

Remove line 26:
```dart
import '../widgets/client_card.dart';
```

- [ ] **Step 2: Add ClientListCard import**

Add at the top with other shared widget imports:
```dart
import '../../../../shared/widgets/client/client_list_card.dart';
```

- [ ] **Step 3: Replace ClientCard with ClientListCard in list**

Find the card usage in `_buildContent()` method (around line 821). Replace:
```dart
ClientCard(
  client: client,
  onTap: () => _onClientTap(client),
  onRemove: () => _confirmRemoveClient(client),
  onLongPress: () => _onClientLongPress(client),
  isSelected: _isClientSelected(client.id),
  isMultiSelectMode: _isMultiSelectMode,
),
```

With:
```dart
ClientListCard(
  client: client,
  onTap: () => _onClientTap(client),
  onRemove: () => _confirmRemoveClient(client),
  onLongPress: () => _onClientLongPress(client),
  isSelected: _isClientSelected(client.id),
  isMultiSelectMode: _isMultiSelectMode,
  enableSwipeToDismiss: true,
  showInMyDayBadge: true,
),
```

- [ ] **Step 4: Add Navigate action to ActionBottomSheet**

In the `_onClientTap()` method (around line 243), add Navigate option to the options list. Find the ActionOption list and add:

```dart
ActionOption(
  icon: LucideIcons.navigation,
  title: 'Navigate',
  description: 'Open navigation to client address',
  value: 'navigate',
),
```

Add it after the 'release' option (around line 266).

- [ ] **Step 5: Handle Navigate action in switch statement**

In the switch statement at the end of `_onClientTap()` (around line 285), add the case:

```dart
case 'navigate':
  await _navigateToClient(client);
  break;
```

- [ ] **Step 6: Add _navigateToClient method**

Add this method to the _MyDayPageState class:

```dart
Future<void> _navigateToClient(MyDayClient client) async {
  HapticUtils.lightImpact();

  final address = client.location;
  if (address == null || address.isEmpty) {
    showToast('No address available');
    return;
  }

  // Open external maps with the address
  final uri = Uri(
    scheme: 'https',
    host: 'www.google.com',
    path: '/maps/search/',
    query: Uri.encodeComponent(address),
  );

  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      showToast('Could not open maps');
    }
  } catch (e) {
    showToast('Error opening maps: $e');
  }
}
```

- [ ] **Step 7: Add required imports for navigation**

Add to the imports at the top:
```dart
import 'package:url_launcher/url_launcher.dart';
```

- [ ] **Step 8: Commit My Day page updates**

```bash
cd mobile/imu_flutter
git add lib/features/my_day/presentation/pages/my_day_page.dart
git commit -m "refactor(my_day): use shared ClientListCard widget

- Replace custom ClientCard with unified ClientListCard
- Add Navigate action to open maps navigation
- Consistent UI with reference Clients page design
- 'Last, First Middle' naming convention

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 8: Update Itinerary Page to Use ClientListCard

**Files:**
- Modify: `lib/features/itinerary/presentation/pages/itinerary_page.dart`

- [ ] **Step 1: Add ClientListCard import**

Add at the top with other imports:
```dart
import '../../../../shared/widgets/client/client_list_card.dart';
```

- [ ] **Step 2: Locate visit card rendering**

Find where visit cards are rendered in the `SliverList` (search for `SliverChildBuilderDelegate` around line 180).

- [ ] **Step 3: Replace inline visit card with ClientListCard**

The current implementation builds cards inline. Replace the entire itemBuilder content with ClientListCard. The current code should look similar to:

```dart
itemBuilder: (context, index) {
  final visit = sortedVisits[index];
  return VisitCard(...); // or inline card
},
```

Replace with:
```dart
itemBuilder: (context, index) {
  final visit = sortedVisits[index];
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 4),
    child: ClientListCard(
      client: visit.client,
      onTap: () => _handleVisitTap(visit),
      onLongPress: () => _toggleVisitSelection(visit.id),
      isSelected: _selectedVisitIds.contains(visit.id),
      isMultiSelectMode: _isMultiSelectMode,
      enableSwipeToDismiss: false,
      showInMyDayBadge: true,
      scheduledDate: visit.scheduledDate.toIso8601String(),
    ),
  );
},
```

- [ ] **Step 4: Add Navigate action to visit tap handler**

In the `_handleVisitTap()` or similar method that handles visit actions, add Navigate option to the action menu.

- [ ] **Step 5: Add navigation handler method**

Add method to open maps:

```dart
Future<void> _navigateToVisit(ItineraryVisit visit) async {
  HapticUtils.lightImpact();

  final address = visit.client.fullAddress;
  if (address == null || address.isEmpty) {
    showToast('No address available');
    return;
  }

  final uri = Uri(
    scheme: 'https',
    host: 'www.google.com',
    path: '/maps/search/',
    query: Uri.encodeComponent(address),
  );

  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      showToast('Could not open maps');
    }
  } catch (e) {
    showToast('Error opening maps: $e');
  }
}
```

- [ ] **Step 6: Add url_launcher import**

Add to imports:
```dart
import 'package:url_launcher/url_launcher.dart';
```

- [ ] **Step 7: Commit Itinerary page updates**

```bash
cd mobile/imu_flutter
git add lib/features/itinerary/presentation/pages/itinerary_page.dart
git commit -m "refactor(itinerary): use shared ClientListCard widget

- Replace inline visit cards with unified ClientListCard
- Add Navigate action for maps integration
- Consistent UI across My Day and Itinerary pages
- 'Last, First Middle' naming convention

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 9: Delete Old My Day ClientCard Widget

**Files:**
- Delete: `lib/features/my_day/presentation/widgets/client_card.dart`

- [ ] **Step 1: Verify no remaining imports**

Search the codebase for any remaining imports of the old ClientCard:
```bash
cd mobile/imu_flutter
grep -r "import '../widgets/client_card.dart'" lib/
grep -r "import.*client_card.dart" lib/
```

- [ ] **Step 2: Delete the old widget file**

```bash
cd mobile/imu_flutter
rm lib/features/my_day/presentation/widgets/client_card.dart
```

- [ ] **Step 3: Commit deletion**

```bash
cd mobile/imu_flutter
git add lib/features/my_day/presentation/widgets/client_card.dart
git commit -m "refactor(my_day): remove obsolete ClientCard widget

- Replaced by shared ClientListCard widget
- No remaining references in codebase

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 10: Add url_launcher Dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Check if url_launcher is already in dependencies**

Open `pubspec.yaml` and search for `url_launcher`.

- [ ] **Step 2: Add url_launcher if not present**

If not found, add to dependencies:
```yaml
dependencies:
  url_launcher: ^6.2.0
```

- [ ] **Step 3: Run flutter pub get**

```bash
cd mobile/imu_flutter
flutter pub get
```

- [ ] **Step 4: Commit dependency addition**

```bash
cd mobile/imu_flutter
git add pubspec.yaml pubspec.lock
git commit -m "deps: add url_launcher for maps navigation

- Required for Navigate action in My Day and Itinerary
- Opens external maps app with client address

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 11: Final Testing & Verification

**Files:**
- No file modifications

- [ ] **Step 1: Run Flutter analyzer**

```bash
cd mobile/imu_flutter
flutter analyze
```

Fix any issues found.

- [ ] **Step 2: Run tests**

```bash
cd mobile/imu_flutter
flutter test
```

- [ ] **Step 3: Build debug APK**

```bash
cd mobile/imu_flutter
flutter build apk --debug
```

- [ ] **Step 4: Manual testing checklist**

Test on device/emulator:

**My Day Page:**
- [ ] Client names display as "Last, First Middle"
- [ ] Cards show correct layout
- [ ] Loan Released + UDI displays when applicable
- [ ] Multi-select mode works
- [ ] Swipe-to-dismiss works
- [ ] Navigate action opens maps
- [ ] Tap opens action bottom sheet

**Itinerary Page:**
- [ ] Client names display as "Last, First Middle"
- [ ] Cards show correct layout
- [ ] Loan Released + UDI displays when applicable
- [ ] Multi-select mode works
- [ ] Navigate action opens maps
- [ ] Swipe actions still work

**Clients Page:**
- [ ] Client names display as "Last, First Middle"
- [ ] Reference design unchanged

**Other Pages:**
- [ ] Client detail page shows correct name format
- [ ] Touchpoint history shows correct name format
- [ ] Client selector modal shows correct name format

- [ ] **Step 5: Commit any fixes from testing**

```bash
cd mobile/imu_flutter
git add .
git commit -m "fix(client): address issues from final testing

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 12: Push Changes to Remote

**Files:**
- No file modifications

- [ ] **Step 1: Push all commits to remote**

```bash
cd mobile/imu_flutter
git push origin main
```

- [ ] **Step 2: Verify push succeeded**

Check that all commits are pushed.

---

## Summary

This implementation plan:
1. Fixes client naming convention to "Last, First Middle" across the entire app
2. Creates a shared ClientListCard widget for consistent UI
3. Updates My Day and Itinerary pages to use the new widget
4. Adds Navigate action for maps integration
5. Removes obsolete code and dependencies

**Total Estimated Tasks:** 12
**Total Files Modified:** 7
**Total Files Created:** 1
**Total Files Deleted:** 1
