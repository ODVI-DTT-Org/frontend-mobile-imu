# RBAC Testing Checklist

> **Purpose:** Manual testing checklist for Role-Based Access Control (RBAC) features in the IMU mobile app.
>
> **Last Updated:** 2026-04-02
> **Version:** 1.0

---

## Pre-Test Setup

### Test Accounts
Ensure you have test accounts for each role:
- [ ] Admin account (full system access)
- [ ] Area Manager account (regional oversight)
- [ ] Assistant Area Manager account (area support)
- [ ] Caravan account (field agent - visit touchpoints only)
- [ ] Tele account (telemarketer - call touchpoints only)

### Test Data
- [ ] At least 5 test clients with various statuses
- [ ] Test touchpoints for each sequence number (1-7)
- [ ] Test itineraries with scheduled visits
- [ ] Test reports for manager-level access

---

## 1. Authentication & Login

### Test: Login with Different Roles
- [ ] **Admin** - Can login successfully
- [ ] **Area Manager** - Can login successfully
- [ ] **Assistant Area Manager** - Can login successfully
- [ ] **Caravan** - Can login successfully
- [ ] **Tele** - Can login successfully

### Test: Permission Fetching on Login
- [ ] Verify permissions are fetched after login
- [ ] Verify permissions are cached locally
- [ ] Check console logs for "Permissions fetched and cached successfully"

### Test: Permission Refresh on Token Refresh
- [ ] Wait for access token to expire (or manually trigger refresh)
- [ ] Verify permissions are re-fetched
- [ ] Check console logs for "Permissions refreshed successfully"

---

## 2. Navigation & Menu Access

### Test: Home Screen Menu Items

#### Admin Role
- [ ] All menu items visible (8 items)
- [ ] "My Day" icon accessible
- [ ] "My Clients" icon accessible
- [ ] "My Targets" icon accessible
- [ ] "Missed Visits" icon accessible
- [ ] "Loan Calculator" icon accessible
- [ ] "Attendance" icon accessible
- [ ] **"Reports" icon visible and accessible**
- [ ] "My Profile" icon accessible
- [ ] "Developer Options" visible and accessible

#### Area Manager Role
- [ ] All menu items visible (8 items)
- [ ] **"Reports" icon visible and accessible**
- [ ] "Developer Options" hidden

#### Assistant Area Manager Role
- [ ] All menu items visible (8 items)
- [ ] **"Reports" icon visible and accessible**
- [ ] "Developer Options" hidden

#### Caravan Role
- [ ] All menu items visible (8 items)
- [ ] **"Reports" icon hidden**
- [ ] "Developer Options" hidden

#### Tele Role
- [ ] All menu items visible (8 items)
- [ ] **"Reports" icon hidden**
- [ ] "Developer Options" hidden

### Test: Bottom Navigation Tabs

#### Admin Role
- [ ] All 5 tabs visible (Home, My Day, Itinerary, Clients, Reports)

#### Manager Roles (Area Manager, Assistant Area Manager)
- [ ] All 5 tabs visible (Home, My Day, Itinerary, Clients, Reports)

#### Caravan Role
- [ ] Only 4 tabs visible (Home, My Day, Itinerary, Clients)
- [ ] Reports tab hidden

#### Tele Role
- [ ] Only 4 tabs visible (Home, My Day, Itinerary, Clients)
- [ ] Reports tab hidden

---

## 3. Client Management Permissions

### Test: Client List Access
- [ ] **Admin** - Can view all clients
- [ ] **Area Manager** - Can view all clients in their area
- [ ] **Assistant Area Manager** - Can view clients in assigned municipalities
- [ ] **Caravan** - Can view clients in assigned municipalities
- [ ] **Tele** - Can view clients (read-only access)

### Test: Client Creation
- [ ] **Admin** - Can create new clients
- [ ] **Area Manager** - Can create new clients
- [ ] **Assistant Area Manager** - Can create new clients
- [ ] **Caravan** - Can create new clients
- [ ] **Tele** - Cannot create new clients (read-only)

### Test: Client Editing
- [ ] **Admin** - Can edit any client
- [ ] **Area Manager** - Can edit clients in their area
- [ ] **Assistant Area Manager** - Can edit clients in assigned municipalities
- [ ] **Caravan** - Can edit clients in assigned municipalities
- [ ] **Tele** - Cannot edit clients (read-only)

### Test: Client Deletion
- [ ] **Admin** - Delete button visible and working
- [ ] **Area Manager** - Delete button visible and working
- [ ] **Assistant Area Manager** - Delete button visible and working
- [ ] **Caravan** - Delete button visible and working
- [ ] **Tele** - Delete button hidden (read-only)

---

## 4. Touchpoint Permissions

### Test: Touchpoint Number Display

#### Caravan Role (Visit touchpoints only: 1, 4, 7)
- [ ] Next touchpoint shows "1st Visit" when appropriate
- [ ] Next touchpoint shows "4th Visit" when appropriate
- [ ] Next touchpoint shows "7th Visit" when appropriate
- [ ] Call touchpoints (2, 3, 5, 6) are filtered out

#### Tele Role (Call touchpoints only: 2, 3, 5, 6)
- [ ] Next touchpoint shows "2nd Call" when appropriate
- [ ] Next touchpoint shows "3rd Call" when appropriate
- [ ] Next touchpoint shows "5th Call" when appropriate
- [ ] Next touchpoint shows "6th Call" when appropriate
- [ ] Visit touchpoints (1, 4, 7) are filtered out

#### Manager Roles (Admin, Area Manager, Assistant Area Manager)
- [ ] All touchpoint numbers (1-7) are available
- [ ] No filtering applied

### Test: Touchpoint Creation Permission Denied

#### Caravan Role
- [ ] Attempting to create Call touchpoint (2, 3, 5, 6) shows permission denied dialog
- [ ] Permission denied dialog shows: "You don't have permission to perform this action"
- [ ] Visit touchpoints (1, 4, 7) can be created successfully

#### Tele Role
- [ ] Attempting to create Visit touchpoint (1, 4, 7) shows permission denied dialog
- [ ] Permission denied dialog shows: "You don't have permission to perform this action"
- [ ] Call touchpoints (2, 3, 5, 6) can be created successfully

#### Manager Roles
- [ ] All touchpoint types can be created
- [ ] No permission denied dialogs

---

## 5. Settings & Admin Features

### Test: Settings Page Access
- [ ] **Admin** - All settings options visible
- [ ] **Area Manager** - All settings options visible
- [ ] **Assistant Area Manager** - All settings options visible
- [ ] **Caravan** - All settings options visible
- [ ] **Tele** - All settings options visible

### Test: Test PowerSync Button
- [ ] **Admin** - "Test PowerSync" button visible and accessible
- [ ] **Area Manager** - "Test PowerSync" button hidden
- [ ] **Assistant Area Manager** - "Test PowerSync" button hidden
- [ ] **Caravan** - "Test PowerSync" button hidden
- [ ] **Tele** - "Test PowerSync" button hidden

### Test: Developer Options
- [ ] **Admin** - "Developer Options" visible and accessible
- [ ] **Area Manager** - "Developer Options" hidden
- [ ] **Assistant Area Manager** - "Developer Options" hidden
- [ ] **Caravan** - "Developer Options" hidden
- [ ] **Tele** - "Developer Options" hidden

---

## 6. Permission Caching

### Test: Permission Cache Expiry
- [ ] Login and verify permissions are cached
- [ ] Wait 1 hour (or clear cache manually)
- [ ] Attempt action that requires permission
- [ ] Verify permissions are re-fetched from backend
- [ ] Check console logs for permission fetch

### Test: Offline Mode
- [ ] Login while online (permissions cached)
- [ ] Go offline (airplane mode)
- [ ] Verify cached permissions still work
- [ ] Verify permission checks use cached data

---

## 7. Error Handling

### Test: Permission Denied Dialog
- [ ] Dialog appears when permission is denied
- [ ] Dialog shows correct message: "You don't have permission to perform this action"
- [ ] Dialog has "OK" button
- [ ] Dialog dismisses when "OK" is tapped
- [ ] No console errors when dialog is shown

### Test: Network Errors
- [ ] If permission fetch fails on login, login still succeeds
- [ ] App gracefully handles permission service unavailability
- [ ] Console shows error logs but app doesn't crash

---

## 8. Cross-Role Testing

### Test: Role Switching
1. Login as Admin
2. Note down accessible features
3. Logout
4. Login as Caravan
5. Verify different features are accessible
6. Verify Reports tab is hidden
7. Verify Call touchpoints are restricted

### Test: Permission Changes
1. Note: This requires backend access
2. Change user's role in backend
3. Logout and login again
4. Verify new permissions are applied
5. Verify old permissions are revoked

---

## 9. Performance Testing

### Test: Permission Check Performance
- [ ] Permission checks complete in < 100ms (cached)
- [ ] Permission fetch from backend completes in < 2 seconds
- [ ] No UI lag when checking permissions
- [ ] No excessive memory usage from permission caching

---

## 10. Security Testing

### Test: Token Tampering
- [ ] Tampered access token is rejected
- [ ] Expired token triggers refresh flow
- [ ] Invalid permissions are not granted

### Test: Permission Bypass Attempts
- [ ] Cannot access restricted features via deep links
- [ ] Cannot perform restricted actions via API directly
- [ ] Backend validates all permission requests

---

## Test Results Summary

### Date: _______________
### Tester: _______________

#### Unit Tests
- [ ] Permission helpers tests: _____ / 11 passed
- [ ] Permission dialog tests: _____ / 2 passed
- [ ] Session service tests: _____ / 13 passed

#### Manual Tests
- [ ] Authentication & Login: _____ / 11 passed
- [ ] Navigation & Menu Access: _____ / 38 passed
- [ ] Client Management: _____ / 15 passed
- [ ] Touchpoint Permissions: _____ / 17 passed
- [ ] Settings & Admin Features: _____ / 10 passed
- [ ] Permission Caching: _____ / 4 passed
- [ ] Error Handling: _____ / 5 passed
- [ ] Cross-Role Testing: _____ / 7 passed
- [ ] Performance Testing: _____ / 4 passed
- [ ] Security Testing: _____ / 3 passed

**Total Manual Tests: _____ / 114 passed**

#### Issues Found:
1. _________________________________________________________________
2. _________________________________________________________________
3. _________________________________________________________________

#### Overall Status:
- [ ] All tests passed ✅
- [ ] Some tests failed (see above)
- [ ] Critical issues found

---

## Notes

### Test Environment
- **Device/Emulator:** _______________
- **OS Version:** _______________
- **App Version:** _______________
- **Backend URL:** _______________

### Known Limitations
- Permission changes require logout/login to take effect
- Cached permissions expire after 1 hour
- Some tests require backend access to modify user roles

### Test Execution Time
- Unit tests: ~5 minutes
- Manual tests: ~2-3 hours

---

**End of RBAC Testing Checklist**
