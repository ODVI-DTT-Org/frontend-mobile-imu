# Profile Page and Sync Overlay Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Profile tab to the bottom navigation with a simple profile page displaying user info and logout button, and move the sync status indicator to a top-right overlay.

**Architecture:** Modify the MainShell to use a Stack layout with a positioned sync overlay, update the BottomNavBar to include a 5th Profile tab, and simplify the ProfilePage to display basic user information with a logout button.

**Tech Stack:** Flutter 3.2+, Riverpod 2.0, go_router 13.0, Lucide Icons

---

## File Structure

**Create:**
- None (all files exist)

**Modify:**
- `lib/shared/widgets/main_shell.dart` - Add Stack layout, move sync to overlay, add profile nav item
- `lib/features/profile/presentation/pages/profile_page.dart` - Simplify to basic info display with logout
- `lib/core/router/app_router.dart` - Update navigation index logic for 5th tab

---

## Task 1: Update MainShell with Sync Overlay

**Files:**
- Modify: `lib/shared/widgets/main_shell.dart:1-207`

- [ ] **Step 1: Read current main_shell.dart to understand structure**

```bash
# View the current file
cat lib/shared/widgets/main_shell.dart
```

- [ ] **Step 2: Update MainShell to use Stack layout**

Replace the entire `MainShell` class and add sync overlay widget. The current implementation has:

```dart
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
          const BottomNavBar(),
        ],
      ),
    );
  }
}
```

Replace with:

```dart
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              Expanded(child: child),
              const BottomNavBar(),
            ],
          ),
          // Sync status overlay (top-right)
          const Positioned(
            top: 16,
            right: 16,
            child: _SyncStatusOverlay(),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Extract sync indicator logic into new _SyncStatusOverlay widget**

Add this new widget class before the `BottomNavBar` class:

```dart
/// Sync status overlay positioned in top-right corner
class _SyncStatusOverlay extends ConsumerWidget {
  const _SyncStatusOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        // Show sync status sheet
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) => const BackgroundSyncSheet(),
        );
      },
      child: const BackgroundSyncIndicator(
        showLabel: false,
        showPendingCount: true,
      ),
    );
  }
}
```

- [ ] **Step 4: Update BottomNavBar to remove sync indicator**

Remove the `_SyncIndicatorWrapper` from the nav items. Currently at lines 112-115:

```dart
// Remove these lines:
const Padding(
  padding: EdgeInsets.only(left: 4),
  child: _SyncIndicatorWrapper(),
),
```

Also remove the `_SyncIndicatorWrapper` widget class (lines 124-147).

- [ ] **Step 5: Run Flutter analyze to verify no errors**

```bash
cd mobile/imu_flutter
flutter analyze lib/shared/widgets/main_shell.dart
```

Expected: No analysis errors

- [ ] **Step 6: Commit changes**

```bash
git add lib/shared/widgets/main_shell.dart
git commit -m "refactor(main_shell): move sync status to top-right overlay

- Add Stack layout to MainShell for overlay support
- Create _SyncStatusOverlay widget positioned top-right
- Remove sync indicator from BottomNavBar
- Maintain tap behavior to show sync status sheet

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 2: Update BottomNavBar to Add Profile Tab

**Files:**
- Modify: `lib/shared/widgets/main_shell.dart:31-122`

- [ ] **Step 1: Update _getCurrentIndex to handle profile route**

Currently the method handles 4 routes (0-3). Update to include profile:

```dart
int _getCurrentIndex(BuildContext context) {
  final location = GoRouterState.of(context).matchedLocation;
  if (location == '/home') {
    return 0;
  } else if (location == '/my-day') {
    return 1;
  } else if (location == '/itinerary') {
    return 2;
  } else if (location == '/clients') {
    return 3;
  } else if (location == '/profile') {
    return 4;
  }
  return 0;
}
```

- [ ] **Step 2: Update _onItemTapped to handle profile navigation**

Add the profile case:

```dart
void _onItemTapped(BuildContext context, int index) {
  HapticUtils.lightImpact();
  switch (index) {
    case 0:
      context.go('/home');
      break;
    case 1:
      context.go('/my-day');
      break;
    case 2:
      context.go('/itinerary');
      break;
    case 3:
      context.go('/clients');
      break;
    case 4:
      context.go('/profile');
      break;
  }
}
```

- [ ] **Step 3: Add Profile nav item to the Row**

Add the profile item after the Clients item. Currently ends at line 110 with Clients nav item. Add:

```dart
_NavItem(
  icon: LucideIcons.user,
  label: 'Profile',
  isSelected: currentIndex == 4,
  onTap: () => _onItemTapped(context, 4),
),
```

- [ ] **Step 4: Run Flutter analyze to verify no errors**

```bash
cd mobile/imu_flutter
flutter analyze lib/shared/widgets/main_shell.dart
```

Expected: No analysis errors

- [ ] **Step 5: Hot reload to verify 5th tab appears**

```bash
# If running flutter run, press 'r' to hot reload
# Or restart the app
flutter run
```

Expected: Bottom nav shows 5 items with equal spacing

- [ ] **Step 6: Commit changes**

```bash
git add lib/shared/widgets/main_shell.dart
git commit -m "feat(bottom_nav): add Profile tab as 5th navigation item

- Update _getCurrentIndex to handle /profile route
- Update _onItemTapped to navigate to profile page
- Add Profile nav item with user icon
- All 5 items now share equal width in bottom nav

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 3: Simplify ProfilePage to New Design

**Files:**
- Modify: `lib/features/profile/presentation/pages/profile_page.dart`
- Test: `test/features/profile/presentation/pages/profile_page_test.dart` (if exists)

- [ ] **Step 1: Read current profile_page.dart**

```bash
cat lib/features/profile/presentation/pages/profile_page.dart
```

Note: The current profile page may have more complex UI. We'll simplify it to the new design.

- [ ] **Step 2: Create simplified ProfilePage widget**

Replace the entire build method with the new simple design:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/models/user_role.dart';
import '../../../../services/auth/auth_service.dart' show authNotifierProvider;
import '../../../../shared/providers/app_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const Color(0xFFEF4444); // Red
      case UserRole.areaManager:
      case UserRole.assistantAreaManager:
        return const Color(0xFF3B82F6); // Blue
      case UserRole.caravan:
        return const Color(0xFF22C55E); // Green
      case UserRole.tele:
        return const Color(0xFFF59E0B); // Orange
    }
  }

  String _formatRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.areaManager:
        return 'Area Manager';
      case UserRole.assistantAreaManager:
        return 'Assistant Area Manager';
      case UserRole.caravan:
        return 'Caravan';
      case UserRole.tele:
        return 'Tele';
    }
  }

  void _handleLogout(BuildContext context, WidgetRef ref) {
    HapticUtils.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(currentUserNameProvider);
    final userEmail = ref.watch(currentUserEmailProvider);
    final userRole = ref.watch(currentUserRoleProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Name
                Text(
                  userName.isNotEmpty ? userName : 'User Name',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Email
                Text(
                  userEmail.isNotEmpty ? userEmail : 'user@email.com',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getRoleColor(userRole).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getRoleColor(userRole).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Role: ${_formatRole(userRole)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _getRoleColor(userRole),
                    ),
                  ),
                ),
                const Spacer(),
                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleLogout(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Log Out',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Run Flutter analyze to verify no errors**

```bash
cd mobile/imu_flutter
flutter analyze lib/features/profile/presentation/pages/profile_page.dart
```

Expected: No analysis errors

- [ ] **Step 4: Hot reload to verify profile page displays correctly**

```bash
# If running flutter run, press 'r' to hot reload
```

Expected:
- Avatar with user initial displayed
- Name displayed below avatar
- Email displayed below name
- Role badge with correct color
- Logout button at bottom

- [ ] **Step 5: Test logout flow**

1. Tap the logout button
2. Verify confirmation dialog appears
3. Tap "Log Out" in dialog
4. Verify navigation to login page

- [ ] **Step 6: Commit changes**

```bash
git add lib/features/profile/presentation/pages/profile_page.dart
git commit -m "feat(profile): simplify profile page to basic info display

- Display user avatar with initial
- Show user name and email
- Show role badge with color coding
- Add logout button with confirmation
- Remove unnecessary settings/links

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 4: Update App Router for Profile Navigation

**Files:**
- Modify: `lib/core/router/app_router.dart`

- [ ] **Step 1: Verify profile route exists**

```bash
grep -n "profile" lib/core/router/app_router.dart
```

Expected: Route for `/profile` should already exist

- [ ] **Step 2: Run Flutter analyze to verify no errors**

```bash
cd mobile/imu_flutter
flutter analyze lib/core/router/app_router.dart
```

Expected: No analysis errors

- [ ] **Step 3: Test navigation flow**

1. Start the app
2. Tap each bottom nav item (Home, My Day, Itinerary, Clients, Profile)
3. Verify correct page displays for each tab
4. Verify sync overlay appears on all pages

- [ ] **Step 4: Run full app test**

```bash
cd mobile/imu_flutter
flutter test
```

Expected: All tests pass

- [ ] **Step 5: Commit if any router changes were needed**

```bash
# Only if changes were made
git add lib/core/router/app_router.dart
git commit -m "feat(router): ensure profile route properly configured

- Verify /profile route exists in router
- Ensure proper navigation to profile page

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 5: Final Integration Testing

**Files:**
- All modified files

- [ ] **Step 1: Run Flutter analyze on entire project**

```bash
cd mobile/imu_flutter
flutter analyze
```

Expected: No analysis errors

- [ ] **Step 2: Run all unit tests**

```bash
cd mobile/imu_flutter
flutter test
```

Expected: All tests pass (no regressions)

- [ ] **Step 3: Manual testing checklist**

Test each item and verify:

- [ ] Profile tab appears in bottom navigation
- [ ] Profile tab navigates to profile page
- [ ] Profile page displays user name correctly
- [ ] Profile page displays user email correctly
- [ ] Profile page displays user role with correct color
- [ ] Logout button shows confirmation dialog
- [ ] Logout confirms and navigates to login
- [ ] Sync overlay appears in top-right corner
- [ ] Sync overlay is tappable on all pages
- [ ] Sync overlay shows correct status
- [ ] Bottom nav has 5 items with equal spacing
- [ ] All nav items highlight correctly when active
- [ ] Sync status sheet still opens when tapping overlay

- [ ] **Step 4: Final commit with integration testing notes**

```bash
git add .
git commit -m "test(profile): complete integration testing

- All navigation tests passed
- Profile page displays user data correctly
- Logout flow works as expected
- Sync overlay visible on all pages
- No test regressions

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 6: Documentation Updates

**Files:**
- Modify: `CLAUDE.md` (if needed)
- Modify: `docs/architecture/README.md` (if needed)

- [ ] **Step 1: Update CLAUDE.md with new navigation structure**

Add to the appropriate section:

```markdown
### Bottom Navigation

The app has 5 bottom navigation tabs:
- **Home** - Dashboard with quick actions
- **My Day** - Today's tasks and visits
- **Itinerary** - Scheduled visits by date
- **Clients** - Client list and search
- **Profile** - User profile with logout

A sync status overlay appears in the top-right corner on all pages.
```

- [ ] **Step 2: Commit documentation updates**

```bash
git add CLAUDE.md docs/architecture/README.md
git commit -m "docs: update navigation structure documentation

- Document 5th Profile tab in bottom navigation
- Document sync status overlay position
- Update navigation flow description

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Self-Review Checklist

- [ ] **Spec coverage:** All requirements from design spec are implemented
  - Profile tab added to bottom nav ✓
  - Profile page with basic info ✓
  - Logout button with confirmation ✓
  - Sync status moved to overlay ✓

- [ ] **Placeholder scan:** No TBDs, TODOs, or incomplete steps

- [ ] **Type consistency:** All types and names match throughout
  - `currentUserNameProvider` used consistently
  - `currentUserEmailProvider` used consistently
  - `currentUserRoleProvider` used consistently
  - Role color methods match

- [ ] **DRY check:** No code duplication
  - Logout logic reused from existing pattern
  - Sync overlay logic extracted properly

---

**Total Estimated Time:** 2-3 hours

**Testing Strategy:**
- Unit tests: Run existing test suite
- Manual testing: Navigation flow, profile display, logout flow, sync overlay
- Visual testing: Verify layout on different screen sizes

**Success Criteria:**
- 5th Profile tab appears and navigates correctly
- Profile page shows user info with proper styling
- Logout works with confirmation
- Sync overlay visible on all pages
- No test regressions
