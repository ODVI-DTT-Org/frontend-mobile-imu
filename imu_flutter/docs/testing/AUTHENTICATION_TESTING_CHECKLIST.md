# IMU Authentication System - Manual Testing Checklist

## Testing Environment Setup

### Prerequisites
- [ ] Flutter environment is set up and running
- [ ] Development server is accessible (http://192.168.100.70:3000/api)
- [ ] Android device/emulator is connected
- [ ] App is running in development mode

### Device Requirements
- [ ] Android device with biometric support (fingerprint)
- [ ] Device has PIN/password set up
- [ ] Network connectivity is available

---

## Phase 1: Login Flow Testing

### Test Case 1.1: Initial Login Screen
- [ ] App launches and shows login screen
- [ ] Email field is present and editable
- [ ] Password field is present and editable
- [ ] Password field shows obscured text by default
- [ ] Password visibility toggle button is present
- [ ] Login button is present
- [ ] Forgot Password button/link is present
- [ ] App name and logo are displayed correctly

### Test Case 1.2: Email Validation
- [ ] Enter invalid email format (e.g., "invalid-email")
- [ ] Tap login button
- [ ] Validation error message appears: "Please enter a valid email"
- [ ] Error message is user-friendly

### Test Case 1.3: Password Visibility Toggle
- [ ] Enter password in password field
- [ ] Tap the eye icon to show password
- [ ] Password becomes visible
- [ ] Tap the eye icon again to hide password
- [ ] Password becomes obscured again

### Test Case 1.4: Login Loading State
- [ ] Enter valid email: test@example.com
- [ ] Enter valid password: password123
- [ ] Tap login button
- [ ] Loading indicator appears (circular progress)
- [ ] Login button is disabled during loading
- [ ] Email and password fields are disabled during loading

### Test Case 1.5: Successful Login to PIN Setup
- [ ] Enter valid credentials
- [ ] Tap login button
- [ ] Navigate to PIN Setup page
- [ ] PIN Setup page displays correctly
- [ ] Page shows "Create your PIN" message
- [ ] Page shows "Enter a 6-digit PIN" instruction

---

## Phase 2: PIN Setup Testing

### Test Case 2.1: PIN Setup UI
- [ ] PIN entry screen is displayed
- [ ] Number pad (0-9) is present
- [ ] PIN dots are shown (6 dots)
- [ ] Backspace button is present
- [ ] Clear button is present
- [ ] Confirm PIN button is present

### Test Case 2.2: PIN Entry
- [ ] Tap 6 digits (e.g., 1-2-3-4-5-6)
- [ ] PIN dots fill up as digits are entered
- [ ] Each digit shows for a moment before being obscured
- [ ] Can delete last digit with backspace
- [ ] Can clear all digits with clear button

### Test Case 2.3: PIN Confirmation
- [ ] Enter 6-digit PIN
- [ ] Confirm PIN button becomes active after 6 digits
- [ ] Tap confirm button
- [ ] Screen changes to "Confirm your PIN"
- [ ] Enter same PIN again
- [ ] Confirmation succeeds

### Test Case 2.4: PIN Mismatch
- [ ] Enter 6-digit PIN: 123456
- [ ] Confirm PIN button becomes active
- [ ] Tap confirm button
- [ ] Enter different PIN: 654321
- [ ] Error message appears: "PINs do not match"
- [ ] Return to PIN entry screen

### Test Case 2.5: Successful PIN Setup
- [ ] Complete PIN setup with matching PINs
- [ ] Success message appears
- [ ] Navigate to authenticated home screen
- [ ] User is now logged in

---

## Phase 3: PIN Entry Testing (Returning User)

### Test Case 3.1: PIN Entry Screen
- [ ] App launches for returning user
- [ ] PIN entry screen is displayed
- [ ] "Enter your PIN" message is shown
- [ ] Number pad is present
- [ ] PIN dots are empty initially

### Test Case 3.2: Correct PIN Entry
- [ ] Enter correct 6-digit PIN
- [ ] PIN is accepted
- [ ] Navigate to authenticated home screen
- [ ] User is logged in

### Test Case 3.3: Incorrect PIN Entry
- [ ] Enter incorrect 6-digit PIN
- [ ] Error message appears: "Incorrect PIN"
- [ ] Remaining attempts counter updates
- [ ] Can try again

### Test Case 3.4: PIN Retry Limit (5 Attempts)
- [ ] Enter incorrect PIN 5 times
- [ ] After 5th attempt, lockout message appears
- [ ] Lockout timer is shown (30 minutes)
- [ ] Cannot enter PIN during lockout
- [ ] Lockout expires after 30 minutes

---

## Phase 4: Biometric Authentication Testing

### Test Case 4.1: Biometric Setup
- [ ] After PIN setup, biometric prompt appears
- [ ] Prompt asks if user wants to enable biometric
- [ ] "Enable" and "Skip" buttons are present
- [ ] Tap "Enable"
- [ ] System biometric prompt appears (fingerprint/Face ID)
- [ ] Biometric authentication succeeds
- [ ] Success message appears
- [ ] Biometric is now enabled

### Test Case 4.2: Biometric Login
- [ ] App launches for returning user with biometric enabled
- [ ] Biometric prompt appears automatically
- [ ] System biometric prompt appears
- [ ] Authenticate with fingerprint/Face ID
- [ ] Authentication succeeds
- [ ] Navigate to authenticated home screen

### Test Case 4.3: Biometric Fallback to PIN
- [ ] App launches with biometric enabled
- [ ] Biometric prompt appears
- [ ] Cancel biometric prompt
- [ ] PIN entry screen appears
- [ ] Can enter PIN instead
- [ ] PIN authentication works

### Test Case 4.4: Biometric Failure
- [ ] App launches with biometric enabled
- [ ] Biometric prompt appears
- [ ] Authenticate with wrong fingerprint
- [ ] Authentication fails
- [ ] Error message appears
- [ ] Fallback to PIN entry
- [ ] Can retry biometric (up to 3 attempts)
- [ ] After 3 failed attempts, forced to PIN

---

## Phase 5: Session Management Testing

### Test Case 5.1: 15-Minute Auto-Lock
- [ ] User is authenticated and on home screen
- [ ] Wait 15 minutes without any interaction
- [ ] SessionLockedPage appears automatically
- [ ] "Session Locked" message is shown
- [ ] Lock icon is displayed
- [ ] "Enter your PIN to unlock" instruction is shown
- [ ] PIN entry is required to unlock

### Test Case 5.2: Session Unlock
- [ ] Session is locked
- [ ] Enter correct PIN
- [ ] Session unlocks
- [ ] Return to previous screen
- [ ] All data is preserved

### Test Case 5.3: Activity Tracking
- [ ] User is authenticated
- [ ] Tap on screen (any interaction)
- [ ] 15-minute timer resets
- [ ] Wait 14 minutes, then tap again
- [ ] Timer resets, wait another 14 minutes
- [ ] No lock occurs (activity is tracked)

### Test Case 5.4: 8-Hour Session Timeout
- [ ] User is authenticated
- [ ] Wait 8 hours (or simulate with time change)
- [ ] Session expires
- [ ] Return to login screen
- [ ] Must log in again with email/password
- [ ] PIN entry is required after login

---

## Phase 6: Token Refresh Testing

### Test Case 6.1: Automatic Token Refresh
- [ ] User is authenticated
- [ ] Wait for token to approach expiry (5 minutes before)
- [ ] Token refresh happens automatically in background
- [ ] No interruption to user
- [ ] User continues using app normally
- [ ] Check network logs for refresh request

### Test Case 6.2: Token Refresh Failure
- [ ] Simulate network failure during token refresh
- [ ] Retry logic activates (up to 3 attempts)
- [ ] Exponential backoff occurs (1s → 2s → 4s)
- [ ] Error message appears if all retries fail
- [ ] User is logged out
- [ ] Return to login screen

---

## Phase 7: Offline Authentication Testing

### Test Case 7.1: Offline Grace Period (24 Hours)
- [ ] User is authenticated with valid tokens
- [ ] Disable network connection
- [ ] App continues to work normally
- [ ] Can access authenticated features
- [ ] 24-hour grace period is active
- [ ] Operations are queued for sync

### Test Case 7.2: Offline Grace Period Expiry
- [ ] User is authenticated
- [ ] Disable network for 24+ hours
- [ ] Grace period expires
- [ ] Session is invalidated
- [ ] Return to login screen
- [ ] Must re-authenticate with network

### Test Case 7.3: Sync Queue Operations
- [ ] User is offline
- [ ] Perform actions (e.g., create touchpoint)
- [ ] Operations are queued (max 100)
- [ ] Re-enable network
- [ ** ] Automatic sync occurs
- [ ] Queued operations are sent to server
- [ ] Conflicts are resolved (last-write-wins)

---

## Phase 8: Error Handling Testing

### Test Case 8.1: No Internet Connection
- [ ] Disable network (WiFi and mobile data)
- [ ] Try to log in
- [ ] Error message appears: "No internet connection"
- [ ] Error message is user-friendly
- [ ] Retry button is available

### Test Case 8.2: Server Error (500)
- [ ] Try to log in when server is down
- [ ] Error message appears: "Server error"
- [ ] User is informed of the issue
- [ ] Can retry when server is back

### Test Case 8.3: Network Timeout
- [ ] Simulate slow network
- [ ] Try to log in
- [ ] Timeout after 30 seconds
- [ ] Error message appears: "Request timed out"
- [ ] Can retry

### Test Case 8.4: Unauthorized (401)
- [ ] Use expired token
- [ ] Automatic token refresh is attempted
- [ ] If refresh succeeds, user continues
- [ ] If refresh fails, user is logged out

---

## Phase 9: Security Testing

### Test Case 9.1: PIN Encryption
- [ ] Set up PIN
- [ ] Check secure storage
- [ ] PIN is not stored in plain text
- [ ] PIN hash is salted
- [ ] PIN comparison uses constant-time algorithm

### Test Case 9.2: Token Storage
- [ ] Log in successfully
- [ ] Access token is stored in memory only
- [ ] Refresh token is stored encrypted
- [ ] Tokens are not logged
- [ ] Tokens are cleared on logout

### Test Case 9.3: Session Lock on Background
- [ ] User is authenticated
- [ ] Move app to background
- [ ] Wait 15 minutes
- [ ] Return to app
- [ ] Session is locked
- [ ] PIN is required to unlock

### Test Case 9.4: Screenshot Prevention
- [ ] Navigate to sensitive screens (PIN entry)
- [ ] Try to take screenshot
- [ ] Screenshot is blocked or shows black screen

---

## Phase 10: UI/UX Testing

### Test Case 10.1: Responsive Design
- [ ] Test on phone screen size
- [ ] Test on tablet screen size
- [ ] All elements are visible
- [ ] No layout overflow
- [ ] Touch targets are appropriate size (48x48dp min)

### Test Case 10.2: Accessibility
- [ ] Screen reader compatibility
- [ ] Touch targets are large enough
- [ ] Color contrast meets WCAG standards
- [ ] Error messages are descriptive
- [ ] Form fields have proper labels

### Test Case 10.3: Haptic Feedback
- [ ] Button taps provide haptic feedback
- [ ] Successful authentication provides positive haptic
- [ ] Failed authentication provides error haptic
- [ ] Feedback is appropriate and not excessive

---

## Phase 11: Edge Cases Testing

### Test Case 11.1: App Background During Authentication
- [ ] Start login process
- [ ] Move app to background
- [ ] Return to app
- [ ] Authentication state is preserved
- [ ] Can continue from where left off

### Test Case 11.2: Phone Call During Authentication
- [ ] Start login process
- [ ] Receive phone call
- [ ] Answer call
- [ ] End call
- [ ] Return to app
- [ ] Authentication state is preserved

### Test Case 11.3: App Crash During Authentication
- [ ] Force kill app during login
- [ ] Restart app
- [ ] App returns to appropriate screen
- [ ] No data corruption
- [ ] Can continue authentication

### Test Case 11.4: Multiple Failed Attempts
- [ ] Enter wrong PIN 5 times
- [ ] Account is locked for 30 minutes
- [ ] Try again before lockout expires
- [ ] Error message shows remaining time
- [ ] Can try again after lockout expires

---

## Phase 12: Performance Testing

### Test Case 12.1: Login Performance
- [ ] Launch app to login screen: < 2 seconds
- [ ] Login API response: < 3 seconds
- [ ] PIN setup navigation: < 500ms
- [ ] PIN verification: < 200ms
- [ ] Biometric prompt: < 1 second

### Test Case 12.2: Memory Usage
- [ ] Monitor memory during authentication
- [ ] No memory leaks
- [ ] Memory usage is reasonable
- [ ] App remains responsive

### Test Case 12.3: Battery Usage
- [ ] App doesn't drain battery excessively
- [ ] Background operations are minimal
- [ ] Location services are used efficiently

---

## Test Execution Summary

### Test Execution Date: ___________
### Tester Name: ___________
### Device: ___________
### Android Version: ___________
### App Version: ___________

### Results:
- Total Test Cases: ___
- Passed: ___
- Failed: ___
- Skipped: ___

### Critical Issues Found:
1.
2.
3.

### Recommendations:
1.
2.
3.

---

## Bug Report Template

### Bug ID: ___
### Title:
### Severity: [Critical | High | Medium | Low]
### Test Case:
### Steps to Reproduce:
1.
2.
3.

### Expected Behavior:
-

### Actual Behavior:
-

### Frequency: [Always | Sometimes | Rarely | Once]
### Screenshots/Videos:
### Additional Notes:
