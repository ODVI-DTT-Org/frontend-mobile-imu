# Profile Page and Sync Status Overlay Design

**Date:** 2026-04-03
**Status:** Approved
**Author:** AI Agent (Brainstorming Session)

---

## Overview

Add a Profile tab to the bottom navigation that displays basic user info with a logout button, and move the sync status indicator from the bottom nav to a top-right overlay position.

---

## Requirements

### Functional Requirements
- FR1: Add Profile as the 5th item in the bottom navigation bar
- FR2: Create a new Profile page displaying basic user information
- FR3: Include a logout button on the Profile page
- FR4: Move the sync status indicator to a top-right overlay position
- FR5: Maintain existing sync status tap behavior (show bottom sheet)

### Non-Functional Requirements
- NFR1: Profile page should load user data from existing providers
- NFR2: Sync overlay must be visible on all pages
- NFR3: Logout flow should match existing Settings page behavior
- NFR4: Design should follow existing Material 3 patterns

---

## Design

### Part 1: Bottom Navigation Update

**Current State:**
- 4 navigation items: Home, My Day, Itinerary, Clients
- Sync indicator positioned at the end of the nav items

**New State:**
- 5 navigation items: Home, My Day, Itinerary, Clients, Profile
- Sync indicator removed from bottom nav (moved to overlay)

**Icon:** `LucideIcons.user` or `LucideIcons.userCircle`

**Layout:** All 5 items share equal width in the bottom navigation bar

---

### Part 2: Profile Page Design

**Page Layout:**
```
┌─────────────────────────────┐
│                             │
│      [Avatar or Icon]        │
│         (80px, circular)     │
│                             │
│      John Doe               │
│   (Large, bold, 20-24px)     │
│                             │
│   john.doe@email.com        │
│    (Smaller, 14-16px, grey)  │
│                             │
│   ┌───────────────────┐     │
│   │  Role: Caravan   │     │
│   └───────────────────┘     │
│      (Pill-shaped badge)     │
│                             │
│                             │
│                             │
│   ┌───────────────────┐     │
│   │    Log Out       │     │
│   └───────────────────┘     │
│      (Red, full-width)      │
│                             │
└─────────────────────────────┘
```

**Components:**

1. **Avatar/Icon**
   - Centered at top of page
   - Size: ~80px
   - Circular shape
   - Display user initials or generic person icon
   - Background color: Primary color with white text

2. **Name Display**
   - Font size: 20-24px
   - Font weight: Bold
   - Color: Primary color (#0F172A)
   - Centered below avatar

3. **Email Display**
   - Font size: 14-16px
   - Color: Grey (#64748B)
   - Centered below name

4. **Role Badge**
   - Pill-shaped container
   - Background color: Role-based (Admin=red, Manager=blue, Caravan=green, Tele=orange)
   - Text: "Role: {Role Name}"
   - Centered below email

5. **Logout Button**
   - Positioned at bottom of page
   - Full-width with horizontal padding
   - Red background (#EF4444)
   - White text
   - Shows confirmation dialog before logout

**Styling:**
- Page background: `Colors.grey[50]`
- Content centered vertically and horizontally
- Card or container for profile info (optional, depending on design preference)

---

### Part 3: Sync Status Overlay

**Position:**
- Top-right corner of the screen
- Floating above all page content
- Padding: 16px from top and right edges

**Visual Design:**
- Small circular indicator (~40px diameter)
- Semi-transparent background to not obstruct content
- Sync icon in center
- Badge showing pending count (if any)
- Color changes based on sync status:
  - Green: Synced
  - Yellow: Syncing
  - Red: Error

**Behavior:**
- Always visible on all pages (inside MainShell)
- Tappable to show sync status bottom sheet
- Animation for status changes

**Implementation Approach:**
- Use `Stack` widget in MainShell
- Position sync indicator with `Positioned(top: 16, right: 16)`
- Remove sync indicator from BottomNavBar

---

### Part 4: Data Flow

**Data Sources (Existing Providers):**
- **Name:** `currentUserNameProvider` - Returns user's full name
- **Email:** `currentUserEmailProvider` - Returns user's email
- **Role:** `currentUserRoleProvider` - Returns user's role enum

**Logout Flow:**
1. User taps logout button
2. Show confirmation dialog: "Are you sure you want to log out?"
3. If confirmed:
   - Call `ref.read(authNotifierProvider.notifier).logout()`
   - Clear session data
   - Navigate to `/login`

---

### Part 5: Files to Modify/Create

**Modify:**

1. **`lib/shared/widgets/main_shell.dart`**
   - Add `Stack` wrapper around body content
   - Add sync status overlay as `Positioned` widget
   - Remove sync indicator from `BottomNavBar`

2. **`lib/features/profile/presentation/pages/profile_page.dart`**
   - Simplify to match new design
   - Use existing providers for user data
   - Add logout button with confirmation

3. **`lib/core/router/app_router.dart`**
   - Update `BottomNavBar` `_getCurrentIndex()` to include profile route
   - Update `_onItemTapped()` to handle profile navigation

**Router Configuration:**
- Profile route already exists: `/profile`
- Update navigation logic to handle profile tab

---

## Error Handling

- **Profile Data Loading:** Show loading state if user data is not yet available
- **Logout Failure:** Show error message if logout fails
- **Sync Overlay:** Handle tap errors gracefully

---

## Testing Checklist

- [ ] Profile tab appears in bottom navigation
- [ ] Profile tab navigates to profile page
- [ ] Profile page displays user name correctly
- [ ] Profile page displays user email correctly
- [ ] Profile page displays user role correctly
- [ ] Logout button shows confirmation dialog
- [ ] Logout confirms and navigates to login
- [ ] Sync overlay appears in top-right corner
- [ ] Sync overlay is tappable on all pages
- [ ] Sync overlay shows correct status
- [ ] Sync overlay shows pending count badge
- [ ] Bottom nav has 5 items with equal spacing

---

## Success Criteria

1. Users can access their profile from the bottom navigation
2. Profile page displays basic user information clearly
3. Users can log out from the profile page
4. Sync status is always visible without taking up bottom nav space
5. All existing functionality remains intact

---

**Next Steps:** Create implementation plan using writing-plans skill.
