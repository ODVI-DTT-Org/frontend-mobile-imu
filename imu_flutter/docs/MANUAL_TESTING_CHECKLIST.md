# Mobile Error Logging - Manual Testing Checklist

> **Implementation Date:** 2026-04-04
> **Purpose:** Verify the mobile error logging system works correctly across all workflows

---

## Prerequisites

Before testing, ensure:
- [ ] Backend is running with POST /api/errors endpoint
- [ ] PowerSync service is running and connected
- [ ] Flutter app is built and installed on device/emulator
- [ ] Error logs table exists in PostgreSQL (migration 039 applied)
- [ ] User is logged in with valid JWT token

---

## Phase 1: Critical Error Testing (Direct API Flow)

**Purpose:** Verify critical errors (blocking workflows) are sent directly to backend API

### Test 1.1: Login Failure Error Logging

**Steps:**
1. Logout from the app
2. Enter invalid credentials (wrong email/password)
3. Tap "Login"
4. Check backend logs for error report

**Expected Results:**
- [ ] App shows login error message to user
- [ ] Backend receives error report via POST /api/errors
- [ ] Error code: `AUTH_ERROR` or similar
- [ ] Error message contains "Failed to user login"
- [ ] User ID is populated in error report
- [ ] Device info is included in error report

**Verification SQL:**
```sql
SELECT * FROM error_logs
WHERE platform = 'mobile'
  AND code LIKE '%AUTH%'
ORDER BY created_at DESC
LIMIT 1;
```

---

### Test 1.2: Token Refresh Error Logging

**Steps:**
1. Login with valid credentials
2. Manually corrupt the access token in storage
3. Trigger an API call that requires authentication
4. Watch for token refresh failure

**Expected Results:**
- [ ] Token refresh attempt is logged
- [ ] Error report sent to backend with operation: 'token refresh'
- [ ] User is not logged out on network errors (only auth errors)

**Verification SQL:**
```sql
SELECT * FROM error_logs
WHERE platform = 'mobile'
  AND message LIKE '%token refresh%'
ORDER BY created_at DESC
LIMIT 1;
```

---

### Test 1.3: Touchpoint Creation Error Logging

**Steps:**
1. Navigate to a client detail page
2. Start creating a touchpoint
3. Disconnect from internet (airplane mode)
4. Try to save the touchpoint
5. Reconnect and check backend

**Expected Results:**
- [ ] App shows error message about network failure
- [ ] Error report sent to backend with operation: 'save touchpoint'
- [ ] Client ID and touchpoint number included in context
- [ ] Error code: `DIO_ERROR` or `CONNECTION_ERROR`

**Verification SQL:**
```sql
SELECT * FROM error_logs
WHERE platform = 'mobile'
  AND message LIKE '%save touchpoint%'
ORDER BY created_at DESC
LIMIT 1;
```

---

### Test 1.4: Client Creation Error Logging

**Steps:**
1. Navigate to "Add Client" page
2. Fill in client details
3. Disconnect from internet
4. Tap "Save"
5. Reconnect and check backend

**Expected Results:**
- [ ] Error report sent with operation: 'create client'
- [ ] Client name included in context
- [ ] User can retry after reconnecting

---

## Phase 2: Non-Critical Error Testing (PowerSync Queue Flow)

**Purpose:** Verify non-critical errors (user can continue) are queued via PowerSync

### Test 2.1: GPS Timeout Error Logging

**Steps:**
1. Navigate to "My Day" or "Itinerary" page
2. Try to record time-in for a visit
3. Force GPS timeout (simulate location timeout)
4. Check that app continues working

**Expected Results:**
- [ ] App shows timeout message but continues functioning
- [ ] Error queued locally in PowerSync (is_synced = 0)
- [ ] Error code: `TIMEOUT_ERROR` or similar
- [ ] Context includes: `usingCachedFallback: 'true'`

**Verification SQL (immediately):**
```sql
SELECT * FROM error_logs
WHERE platform = 'mobile'
  AND is_synced = 0
  AND code LIKE '%TIMEOUT%'
ORDER BY created_at DESC
LIMIT 1;
```

**Verification SQL (after 5 minutes):**
```sql
SELECT * FROM error_logs
WHERE platform = 'mobile'
  AND is_synced = 1
  AND code LIKE '%TIMEOUT%'
ORDER BY created_at DESC
LIMIT 1;
```

---

### Test 2.2: Photo Upload Error Logging

**Steps:**
1. Navigate to touchpoint form
2. Try to attach a photo
3. Disconnect from internet after photo is selected
4. Try to upload
5. Check that app continues working

**Expected Results:**
- [ ] Error queued in PowerSync (is_synced = 0)
- [ ] Error report shows operation: 'image upload'
- [ ] File name included in context
- [ ] Context includes: `willRetry: 'true'`
- [ ] User can continue using the app

---

### Test 2.3: Audio Recording Error Logging

**Steps:**
1. Navigate to touchpoint form
2. Record audio note
3. Disconnect from internet
4. Try to upload audio
5. Verify app continues working

**Expected Results:**
- [ ] Error queued in PowerSync
- [ ] Operation: 'audio upload'
- [ ] File name included

---

## Phase 3: Batch Processing Verification

**Purpose:** Verify PowerSync batch processor syncs queued errors to main table

### Test 3.1: Batch Processing Every 5 Minutes

**Steps:**
1. Generate 3-5 non-critical errors (GPS timeouts, photo uploads)
2. Wait 5 minutes for cron job to run
3. Check backend logs for batch processing

**Expected Results:**
- [ ] Backend logs show: "Processing X mobile error logs"
- [ ] Backend logs show: "Mobile error logs processed: X succeeded, Y failed"
- [ ] Queued errors (is_synced = 0) become synced (is_synced = 1)

**Verification SQL:**
```sql
-- Check synced errors
SELECT COUNT(*) as synced_count
FROM error_logs
WHERE platform = 'mobile'
  AND is_synced = 1
  AND created_at > NOW() - INTERVAL '10 minutes';

-- Check unsynced errors
SELECT COUNT(*) as unsynced_count
FROM error_logs
WHERE platform = 'mobile'
  AND is_synced = 0
  AND created_at > NOW() - INTERVAL '10 minutes';
```

---

### Test 3.2: Deduplication (Fingerprint Matching)

**Steps:**
1. Trigger the same error multiple times within 1 minute
2. Check backend for duplicate prevention

**Expected Results:**
- [ ] Only one error logged in main table
- [ ] Subsequent errors marked as duplicates
- [ ] Database returns: `reason: 'duplicate'` for duplicates

**Verification SQL:**
```sql
SELECT fingerprint, COUNT(*) as count
FROM error_logs
WHERE platform = 'mobile'
  AND created_at > NOW() - INTERVAL '5 minutes'
GROUP BY fingerprint
HAVING COUNT(*) > 1;
```

---

### Test 3.3: Daily Cleanup Job (2 AM)

**Steps:**
1. Create synced errors older than 7 days
2. Wait for 2 AM cron job (or manually trigger cleanup)
3. Verify old errors are deleted

**Expected Results:**
- [ ] Backend logs show: "Cleaned up X old mobile error logs"
- [ ] Old synced errors deleted from database
- [ ] Recent errors (< 7 days) not deleted

**Verification SQL:**
```sql
-- Check for old synced errors (should be 0 after cleanup)
SELECT COUNT(*) as old_errors
FROM error_logs
WHERE platform = 'mobile'
  AND is_synced = 1
  AND created_at < NOW() - INTERVAL '7 days';
```

---

## Phase 4: Offline Behavior Testing

**Purpose:** Verify error queue works when device is offline

### Test 4.1: Offline Error Queue

**Steps:**
1. Disconnect device from internet (airplane mode)
2. Trigger multiple non-critical errors:
   - GPS timeout
   - Photo upload failure
   - Audio upload failure
3. Reconnect to internet
4. Wait 5 minutes for batch processing

**Expected Results:**
- [ ] All errors queued locally when offline
- [ ] No API calls made when offline
- [ ] Errors sync to backend after reconnection
- [ ] Batch processor picks up all queued errors

**Verification SQL:**
```sql
SELECT code, COUNT(*) as count
FROM error_logs
WHERE platform = 'mobile'
  AND created_at > NOW() - INTERVAL '15 minutes'
GROUP BY code
ORDER BY count DESC;
```

---

### Test 4.2: PowerSync Reconnect

**Steps:**
1. Disconnect from internet
2. Force PowerSync disconnect (close app, wait 30 seconds)
3. Reopen app
4. Reconnect to internet
5. Check that queued errors sync

**Expected Results:**
- [ ] PowerSync reconnects successfully
- [ ] Queued errors sync after reconnection
- [ ] No duplicate errors created

---

## Phase 5: Admin Dashboard Verification

**Purpose:** Verify mobile errors are visible in admin dashboard

### Test 5.1: Error Logs View

**Steps:**
1. Login to admin dashboard
2. Navigate to "Error Logs" page
3. Filter by platform: 'mobile'
4. Check for recent mobile errors

**Expected Results:**
- [ ] Mobile errors appear in list
- [ ] Platform column shows "mobile"
- [ ] Error codes are displayed correctly
- [ ] Device info is visible
- [ ] App version is displayed

---

### Test 5.2: Error Details

**Steps:**
1. Click on a mobile error in the list
2. View error details

**Expected Results:**
- [ ] Full error message visible
- [ ] Stack trace displayed (if available)
- [ ] Device info shown (platform, OS version, locale)
- [ ] Context data visible (operation, user info)
- [ ] Timestamp accurate

---

### Test 5.3: Error Resolution

**Steps:**
1. Select a mobile error
2. Mark as resolved
3. Add resolution notes

**Expected Results:**
- [ ] Error marked as resolved
- [ ] Resolution notes saved
- [ ] Resolved by user recorded
- [ ] Resolved at timestamp set

---

## Phase 6: Edge Cases

### Test 6.1: Concurrent Error Logging

**Steps:**
1. Trigger multiple errors simultaneously
2. Verify no race conditions

**Expected Results:**
- [ ] All errors logged
- [ ] No database locks
- [ ] No duplicate error IDs

---

### Test 6.2: Large Error Payload

**Steps:**
1. Trigger error with very large stack trace
2. Verify it's logged correctly

**Expected Results:**
- [ ] Large stack trace saved
- [ ] No truncation issues
- [ ] Database can handle large text fields

---

### Test 6.3: Special Characters in Error Messages

**Steps:**
1. Trigger error with special characters in message
2. Verify SQL injection protection

**Expected Results:**
- [ ] Special characters escaped
- [ ] No SQL errors
- [ ] Message displayed correctly in dashboard

---

## Phase 7: Performance Testing

### Test 7.1: Error Logging Performance

**Steps:**
1. Time how long it takes to log a critical error
2. Verify it doesn't block UI

**Expected Results:**
- [ ] Error logging completes in < 100ms
- [ ] UI remains responsive
- [ ] No jank or freezing

---

### Test 7.2: Batch Processing Performance

**Steps:**
1. Generate 100+ queued errors
2. Time the batch processing

**Expected Results:**
- [ ] Batch completes in reasonable time
- [ ] No database performance issues
- [ ] Server CPU usage normal

---

## Sign-Off

**Tester Name:** _______________
**Date:** _______________
**Build Version:** _______________

**Overall Status:**
- [ ] All tests passed
- [ ] Some tests failed (see notes below)
- [ ] Tests blocked (see notes below)

**Notes:**
___________________________________________________________________
___________________________________________________________________
___________________________________________________________________

**Issues Found:**
1. _______________
2. _______________
3. _______________

**Recommendations:**
___________________________________________________________________
___________________________________________________________________
