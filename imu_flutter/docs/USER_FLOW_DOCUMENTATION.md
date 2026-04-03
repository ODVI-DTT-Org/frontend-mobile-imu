# IMU Mobile App - User Flow Documentation

> **Version:** 1.0
> **Last Updated:** 2026-04-02
> **User Role:** Field Agents (Caravan)
> **App:** IMU (Itinerary Manager - Uniformed)

---

## Table of Contents

1. [Overview](#overview)
2. [Authentication Flow](#authentication-flow)
3. [Home Dashboard](#home-dashboard)
4. [Client Management](#client-management)
5. [Itinerary Management](#itinerary-management)
6. [Touchpoint Creation](#touchpoint-creation)
7. [My Day Tasks](#my-day-tasks)
8. [Settings & Profile](#settings--profile)
9. [End of Day Flow](#end-of-day-flow)
10. [Error Handling](#error-handling)

---

## Overview

The IMU mobile app is designed for field agents (Caravan role) managing client visits for retired police personnel (PNP retirees). This document describes the complete user journey from login to end of day.

### Key User Roles

| Role | Description | Permissions |
|------|-------------|-------------|
| **Caravan** | Field agents | Client management, Visit touchpoints (1, 4, 7) |
| **Tele** | Telemarketers | Call touchpoints (2, 3, 5, 6) |
| **Admin** | System administrators | Full system access |

---

## Authentication Flow

### 1. Login Screen

**Purpose:** Authenticate field agents with email and password.

**User Flow:**

```
┌─────────────────────────────────┐
│  IMU Logo                      │
│  Itinerary Manager - Uniformed │
├─────────────────────────────────┤
│  [Email Field]                 │
│  [Password Field]      [👁️]   │
│  [FORGOT YOUR PASSWORD?]       │
├─────────────────────────────────┤
│  [LOGIN BUTTON]                │
└─────────────────────────────────┘
```

**Steps:**

1. **Enter Email**
   - Input: Valid email address
   - Validation: Email format check
   - Error: "Invalid email format"

2. **Enter Password**
   - Input: Password (minimum 8 characters)
   - Feature: Toggle visibility with eye icon
   - Error: "Password is too short"

3. **Tap Login**
   - Validates credentials with backend
   - Loads user profile and permissions
   - Proceeds to PIN setup or PIN entry

**Error States:**

- **Offline:** Shows offline banner, disables login button
- **Invalid credentials:** "Invalid email or password"
- **Network error:** "Connection failed. Please check your internet."

---

### 2. PIN Setup (First-Time Users)

**Purpose:** Set up 6-digit PIN for quick daily access.

**User Flow:**

```
┌─────────────────────────────────┐
│  Setup Your PIN                │
│  Enter a 6-digit PIN           │
├─────────────────────────────────┤
│  [PIN Field 1] [PIN Field 2]   │
│  [PIN Field 3] [PIN Field 4]   │
│  [PIN Field 5] [PIN Field 6]   │
├─────────────────────────────────┤
│  Confirm Your PIN              │
│  Re-enter your PIN             │
├─────────────────────────────────┤
│  [PIN Field 1] [PIN Field 2]   │
│  [PIN Field 3] [PIN Field 4]   │
│  [PIN Field 5] [PIN Field 6]   │
├─────────────────────────────────┤
│  [CONFIRM PIN]                 │
└─────────────────────────────────┘
```

**Steps:**

1. **Enter 6-digit PIN**
   - Must be exactly 6 digits
   - Validation: Numeric only

2. **Confirm PIN**
   - Must match first entry
   - Error: "PINs do not match"

3. **Complete Setup**
   - PIN saved securely
   - Proceeds to home dashboard

---

### 3. PIN Entry (Returning Users)

**Purpose:** Quick daily access with 6-digit PIN.

**User Flow:**

```
┌─────────────────────────────────┐
│  Enter Your PIN                │
│  ┌───┬───┬───┬───┬───┬───┐    │
│  │ 1 │ 2 │ 3 │ 4 │ 5 │ 6 │    │
│  └───┴───┴───┴───┴───┴───┘    │
├─────────────────────────────────┤
│  [1] [2] [3]                  │
│  [4] [5] [6]                  │
│  [7] [8] [9]                  │
│     [0]     [⌫]               │
├─────────────────────────────────┤
│  Forgot PIN?                   │
└─────────────────────────────────┘
```

**Features:**

- **Biometric option:** Fingerprint/Face ID (if enabled)
- **Forgot PIN:** Redirects to email login
- **Auto-lock:** After 15 minutes of inactivity
- **Session timeout:** 8 hours full session

---

## Home Dashboard

**Purpose:** Main navigation hub for field agents.

**User Flow:**

```
┌─────────────────────────────────────┐
│  ☰  IMU - Home              🔔 3   │
├─────────────────────────────────────┤
│  Welcome, [Agent Name]              │
│  [My Day Progress]                  │
├─────────────────────────────────────┤
│  ┌─────┐ ┌─────┐ ┌─────┐          │
│  │Clients│ │Itinerary│ │My Day│     │
│  └─────┘ └─────┘ └─────┘          │
│  ┌─────┐ ┌─────┐ ┌─────┐          │
│  │Map View│ │Reports│ │Settings│   │
│  └─────┘ └─────┘ └─────┘          │
├─────────────────────────────────────┤
│  [Bottom Navigation Bar]            │
│  🏠 Home | 📋 Itinerary | 👤 Profile│
└─────────────────────────────────────┘
```

**Features:**

1. **My Day Progress:** Shows task completion for today
2. **Quick Actions:** 6-icon grid for main features
3. **Notifications:** Bell icon with unread count
4. **Bottom Navigation:** Quick access to main sections

---

## Client Management

### 1. Client List

**Purpose:** View and manage assigned clients.

**User Flow:**

```
┌─────────────────────────────────────┐
│  ← Clients              [+ Add New]│
├─────────────────────────────────────┤
│  🔍 [Search clients...]             │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐    │
│  │ ⭐ Juan dela Cruz            │    │
│  │ 📱 0917-123-4567            │    │
│  │ 📍 Manila, Philippines      │    │
│  │ Touchpoints: 3/7            │    │
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │ Maria Santos                │    │
│  │ 📱 0918-765-4321            │    │
│  │ 📍 Quezon City, Philippines │    │
│  │ Touchpoints: 5/7            │    │
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
```

**Features:**

- **Search:** Find clients by name or phone
- **Filter:** Filter by touchpoint status
- **Star:** Mark important clients
- **Swipe:** Quick actions (call, navigate, view)

**Actions:**

- **Tap client:** View client details
- **Swipe left:** Quick actions menu
- **Pull to refresh:** Sync with server

---

### 2. Client Detail

**Purpose:** View complete client information.

**User Flow:**

```
┌─────────────────────────────────────┐
│  ← Client Details         [Edit]    │
├─────────────────────────────────────┤
│  Juan dela Cruz                      │
│  ⭐⭐⭐ Potential Client              │
├─────────────────────────────────────┤
│  Contact Information                 │
│  📱 0917-123-4567                    │
│  📧 juan.delacruz@email.com          │
├─────────────────────────────────────┤
│  Address                             │
│  📍 123 Main St, Manila              │
│  [Navigate with Maps]                │
├─────────────────────────────────────┤
│  Touchpoint History                  │
│  1. ✅ Visit (2026-04-01)            │
│  2. ✅ Call (2026-04-02)             │
│  3. ⏳ Visit (Today)                 │
├─────────────────────────────────────┤
│  [Add Touchpoint]  [View on Map]     │
└─────────────────────────────────────┘
```

**Features:**

- **Client info:** Name, contact, address
- **Touchpoint history:** All previous interactions
- **Quick actions:** Call, navigate, add touchpoint
- **Edit:** Update client information

---

## Itinerary Management

### 1. Daily Itinerary

**Purpose:** View today's scheduled client visits.

**User Flow:**

```
┌─────────────────────────────────────┐
│  ← Itinerary            [Calendar]  │
├─────────────────────────────────────┤
│  Today, April 2, 2026               │
│  5 clients scheduled                │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐    │
│  │ 09:00 AM                    │    │
│  │ Juan dela Cruz              │    │
│  │ 📍 123 Main St, Manila      │    │
│  │ ⏳ Pending                  │    │
│  │ [Time In] [Navigate]        │    │
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │ 10:30 AM                    │    │
│  │ Maria Santos                │    │
│  │ 📍 456 Oak Ave, Quezon City │    │
│  │ ✅ Completed                │    │
│  │ [View Details]              │    │
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
```

**Features:**

- **Date selector:** View past/future itineraries
- **Client cards:** Scheduled visits with time slots
- **Status indicators:** Pending, in-progress, completed
- **Quick actions:** Time in, navigate, view details

---

### 2. Add Client to Itinerary

**Purpose:** Schedule a client visit for today.

**User Flow:**

```
┌─────────────────────────────────────┐
│  ← Add to Itinerary                 │
├─────────────────────────────────────┤
│  Select Client                      │
│  🔍 [Search clients...]             │
├─────────────────────────────────────┤
│  Juan dela Cruz                      │
│  Last visit: 7 days ago              │
│  ⏤ Time slot: 2:00 PM              │
├─────────────────────────────────────┤
│  Select Time Slot                    │
│  ◉ 9:00 AM  ○ 10:30 AM             │
│  ○ 2:00 PM   ○ 3:30 PM             │
│  ○ 5:00 PM                          │
├─────────────────────────────────────┤
│  [ADD TO ITINERARY]                 │
└─────────────────────────────────────┘
```

**Steps:**

1. **Select Client** from assigned list
2. **Choose Time Slot** (30-minute increments)
3. **Confirm** addition to itinerary

---

## Touchpoint Creation

### 1. Create Touchpoint (Visit)

**Purpose:** Record a client visit touchpoint.

**User Flow:**

```
┌─────────────────────────────────────┐
│  ← New Touchpoint                   │
├─────────────────────────────────────┤
│  Client: Juan dela Cruz             │
│  Touchpoint #3: Visit               │
├─────────────────────────────────────┤
│  Reason for Visit                    │
│  [Select reason...]                 │
│  ◉ Follow-up on previous discussion │
│  ○ Product presentation             │
│  ○ Document submission              │
│  ○ Contract signing                 │
│  ○ Payment collection               │
│  ○ Issue resolution                 │
│  ○ Other                            │
├─────────────────────────────────────┤
│  Status                             │
│  ◉ Interested  ○ Undecided          │
│  ○ Not Interested  ○ Completed      │
├─────────────────────────────────────┤
│  [TAKE PHOTO]     [RECORD AUDIO]    │
├─────────────────────────────────────┤
│  [TIME IN]                          │
├─────────────────────────────────────┤
│  Location: 📍 Manila, Philippines   │
│  [Verify GPS Location]              │
└─────────────────────────────────────┘
```

**Steps:**

1. **Select Reason** (25+ options available)
2. **Choose Status** (Interested, Undecided, Not Interested, Completed)
3. **Optional:** Take photo of client/interaction
4. **Optional:** Record audio notes
5. **Record Time In** (auto-captures GPS location)
6. **Submit** touchpoint

**Validation:**

- **Caravan role:** Can only create Visit touchpoints (1, 4, 7)
- **GPS required:** Location must be captured
- **Mandatory fields:** Reason, status, time in

---

### 2. Record Time In/Out

**Purpose:** Track visit duration for client touchpoints.

**Time In Flow:**

```
┌─────────────────────────────────────┐
│  Record Time In                     │
├─────────────────────────────────────┤
│  Client: Juan dela Cruz             │
│  Touchpoint #3: Visit               │
├─────────────────────────────────────┤
│  📍 Verifying GPS location...       │
│  Location: 123 Main St, Manila      │
│  Lat: 14.5995, Lng: 120.9842        │
├─────────────────────────────────────┤
│  ✓ Location verified                │
│  Time: 09:05 AM                     │
├─────────────────────────────────────┤
│  [CONFIRM TIME IN]                  │
└─────────────────────────────────────┘
```

**Time Out Flow:**

```
┌─────────────────────────────────────┐
│  Record Time Out                    │
├─────────────────────────────────────┤
│  Client: Juan dela Cruz             │
│  Visit duration: 45 minutes          │
├─────────────────────────────────────┤
│  📍 Verifying GPS location...       │
│  Location: 123 Main St, Manila      │
│  Lat: 14.5995, Lng: 120.9842        │
├─────────────────────────────────────┤
│  ✓ Location verified                │
│  Time: 09:50 AM                     │
├─────────────────────────────────────┤
│  [CONFIRM TIME OUT]                 │
└─────────────────────────────────────┘
```

**Features:**

- **Auto GPS capture:** Records location automatically
- **Address verification:** Confirms client address
- **Duration tracking:** Calculates visit length
- **Offline support:** Works without internet, syncs when online

---

## My Day Tasks

**Purpose:** Track daily task completion and progress.

**User Flow:**

```
┌─────────────────────────────────────┐
│  ← My Day                           │
├─────────────────────────────────────┤
│  Today's Progress                    │
│  ████████░░ 80% Complete            │
│  4 of 5 clients visited              │
├─────────────────────────────────────┤
│  Completed Today                    │
│  ✅ Juan dela Cruz (Visit #3)       │
│  ✅ Maria Santos (Visit #1)         │
│  ✅ Pedro Reyes (Visit #4)          │
│  ✅ Ana Garcia (Visit #7)           │
├─────────────────────────────────────┤
│  Pending                            │
│  ⏳ Carlos Mendoza (Visit #1)       │
│  Scheduled: 5:00 PM                 │
├─────────────────────────────────────┤
│  Statistics                         │
│  Total visits today: 4              │
│  Total time: 3h 45m                 │
│  Average duration: 56m              │
├─────────────────────────────────────┤
│  [VIEW FULL REPORT]                 │
└─────────────────────────────────────┘
```

**Features:**

- **Progress bar:** Visual completion indicator
- **Completed list:** Successfully finished visits
- **Pending list:** Remaining scheduled visits
- **Statistics:** Daily metrics and totals
- **View report:** Detailed daily summary

---

## Settings & Profile

**Purpose:** Manage app settings and user profile.

**User Flow:**

```
┌─────────────────────────────────────┐
│  ← Settings                         │
├─────────────────────────────────────┤
│  Profile                            │
│  Name: Juan Dela Cruz               │
│  Role: Caravan                      │
│  Agency: Metro Manila Agency         │
│  [Edit Profile]                      │
├─────────────────────────────────────┤
│  App Settings                        │
│  🔔 Notifications                   │
│  🌙 Dark Mode                       │
│  📱 Language: English                │
├─────────────────────────────────────┤
│  Data & Sync                         │
│  🔄 Sync Status: Last sync 2m ago   │
│  💾 Storage Used: 45 MB             │
│  [Clear Cache]                       │
├─────────────────────────────────────┤
│  Support                             │
│  [Help Center]                       │
│  [Report Issue]                      │
│  [Contact Support]                   │
├─────────────────────────────────────┤
│  Account                             │
│  [Change PIN]                        │
│  [Logout]                            │
└─────────────────────────────────────┘
```

**Features:**

- **Profile management:** View and edit user info
- **App preferences:** Notifications, theme, language
- **Data management:** Sync status, cache, storage
- **Support:** Help, issue reporting, contact
- **Account:** PIN change, logout

---

## End of Day Flow

**Purpose:** Complete daily tasks and prepare for next day.

### 1. Review Day's Work

```
┌─────────────────────────────────────┐
│  End of Day Summary                 │
├─────────────────────────────────────┤
│  Today, April 2, 2026               │
├─────────────────────────────────────┤
│  Performance                        │
│  ✓ 5 clients visited                │
│  ✓ 4 touchpoints created            │
│  ✓ 3h 45m total visit time          │
│  ✓ 100% completion rate             │
├─────────────────────────────────────┤
│  Outstanding                        │
│  ⏳ 1 client rescheduled            │
│  ⏳ 2 follow-up calls pending        │
├─────────────────────────────────────┤
│  Tomorrow's Schedule                 │
│  6 clients scheduled                │
│  First visit: 9:00 AM               │
├─────────────────────────────────────┤
│  [VIEW FULL REPORT]                 │
│  [SYNC & LOGOUT]                     │
└─────────────────────────────────────┘
```

### 2. Sync Data

**Purpose:** Ensure all data is synchronized with server.

```
┌─────────────────────────────────────┐
│  Syncing Data...                    │
├─────────────────────────────────────┤
│  ✓ Uploading 4 touchpoints          │
│  ✓ Uploading 2 photos               │
│  ✓ Uploading 1 audio recording      │
│  ✓ Downloading tomorrow's itinerary │
│  ✓ Syncing client updates           │
├─────────────────────────────────────┤
│  Sync Complete!                     │
│  All data up to date                │
├─────────────────────────────────────┤
│  [CONTINUE TO LOGOUT]               │
└─────────────────────────────────────┘
```

### 3. Logout

**Purpose:** Securely end session and lock app.

```
┌─────────────────────────────────────┐
│  Logout                             │
├─────────────────────────────────────┤
│  ✓ All data synced                  │
│  ✓ Session ended                    │
│  ✓ App locked                       │
├─────────────────────────────────────┤
│  Thank you for your hard work!      │
│  See you tomorrow!                  │
├─────────────────────────────────────┤
│  [OK]                               │
└─────────────────────────────────────┘
```

**Features:**

- **Auto-sync:** Ensures all data is uploaded
- **Session secure:** Clears sensitive data
- **App locked:** Ready for next day's PIN entry

---

## Error Handling

### Network Errors

**No Internet Connection:**

```
┌─────────────────────────────────────┐
│  ⚠️ Connection Lost                 │
├─────────────────────────────────────┤
│  You appear to be offline.          │
│  Some features may be limited.      │
├─────────────────────────────────────┤
│  ✓ You can still:                   │
│    • View clients                    │
│    • Create touchpoints              │
│    • View itinerary                  │
│  ✗ You cannot:                      │
│    • Sync data                       │
│    • Upload photos                   │
├─────────────────────────────────────┤
│  Data will sync when you're back    │
│  online.                             │
├─────────────────────────────────────┤
│  [OK]                               │
└─────────────────────────────────────┘
```

**Recovery:**

- App continues to work in offline mode
- Data stored locally until connection restored
- Automatic sync when internet returns

---

### Permission Errors

**Access Denied:**

```
┌─────────────────────────────────────┐
│  ⛔ Access Denied                   │
├─────────────────────────────────────┤
│  You don't have permission to       │
│  perform this action.               │
├─────────────────────────────────────┤
│  This feature requires:             │
│  • Call touchpoint permission       │
│  (Your role: Caravan - Visit only)  │
├─────────────────────────────────────┤
│  Contact your administrator if      │
│  you believe this is an error.      │
├─────────────────────────────────────┤
│  [OK]                               │
└─────────────────────────────────────┘
```

**Recovery:**

- Return to previous screen
- Contact administrator for permission changes
- Switch to allowed actions

---

### GPS Errors

**Location Not Found:**

```
┌─────────────────────────────────────┐
│  📍 Location Error                  │
├─────────────────────────────────────┤
│  Unable to verify your location.    │
│  Please ensure GPS is enabled.      │
├─────────────────────────────────────┤
│  Troubleshooting:                   │
│  • Enable location services          │
│  • Check app permissions             │
│  • Move to an open area              │
├─────────────────────────────────────┤
│  [RETRY]            [SKIP]           │
└─────────────────────────────────────┘
```

**Recovery:**

- Enable GPS/location services
- Grant location permission to app
- Move to area with better GPS signal
- Retry location capture

---

## Best Practices

### For Field Agents

1. **Start Day Early**
   - Login 15 minutes before first visit
   - Review itinerary and plan route
   - Check for any schedule changes

2. **Use Time In/Out**
   - Always record time in when arriving
   - Record time out when leaving
   - Ensures accurate visit tracking

3. **Take Photos**
   - Document client interactions
   - Capture important documents
   - Provides proof of visit

4. **Sync Regularly**
   - Sync data after each visit
   - Ensures data is backed up
   - Prevents data loss

5. **Complete All Tasks**
   - Finish all scheduled visits
   - Document any issues
   - Prepare for next day

---

## Support

**Need Help?**

- **App Documentation:** [CLAUDE.md](../CLAUDE.md)
- **Architecture:** [docs/architecture/README.md](../docs/architecture/README.md)
- **Contact:** Development Team
- **Report Issues:** GitHub Issues

---

**Last Updated:** 2026-04-02
**Document Version:** 1.0
