# IMU Authentication Flow Diagram

## Overview

The IMU app uses a dual authentication system:
- **Password Login** (full authentication with backend)
- **PIN Entry** (quick access for returning users)

---

## Authentication Flow Diagrams

### Initial Setup Flow (First Time User)

```
┌─────────────────────────────────────────────────────────────┐
│                     USER OPENS APP                          │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
                ┌──────────────────────┐
                │ Show Login Screen     │
                │ Email + Password      │
                └──────────────────────┘
                            │
                            ▼
                ┌──────────────────────┐
                │ Backend Validates    │
                │ Issues JWT Tokens:   │
                │ • access_token       │
                │ • refresh_token      │
                └──────────────────────┘
                            │
                            ▼
                ┌──────────────────────┐
                │ Show PIN Setup Screen│
                │ User creates 6-digit │
                │ PIN                  │
                └──────────────────────┘
                            │
                            ▼
                ┌──────────────────────┐
                │ PIN Saved Securely    │
                │ Tokens Stored        │
                └──────────────────────┘
                            │
                            ▼
                ┌──────────────────────┐
                │ Navigate to Home      │
                │ (NOT PIN Entry!)     │
                └──────────────────────┘
                            │
                            ▼
                    ┌───────────────────┐
                    │ User can use app   │
                    │ Set up complete    │
                    └───────────────────┘
```

---

### Subsequent App Opens (Within 8-Hour Grace Period)

```
┌─────────────────────────────────────────────────────────────┐
│                     USER OPENS APP                          │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
                ┌──────────────────────┐
                │ Check Auth State     │
                │ isAuthenticated?     │
                │ • hasPin: YES        │
                │ • token: VALID       │
                └──────────────────────┘
                            │
                            ▼
                ┌──────────────────────┐
                │ Show PIN Entry Screen│
                │ "Enter PIN to unlock" │
                └──────────────────────┘
                            │
                            ▼
                ┌──────────────────────┐
                │ User Enters PIN      │
                └──────────────────────┘
                            │
                            ▼
                ┌──────────────────────┐
                │ PIN Verification     │
                │ • Check PIN hash     │
                │ • Retrieve JWT token │
                │ • Check expiration   │
                └──────────────────────┘
                            │
                    ┌───────────┴───────────┐
                    │                       │
                Token VALID              Token EXPIRED
                    │                       │
                    ▼                       ▼
            ┌───────────────┐       ┌──────────────┐
            │ Allow Access │       │ Show Error   │
            │ Navigate to   │       │ "Session    │
            │ Sync-loading   │       │ Expired.    │
            │ Then Home     │       │ Please login │
            └───────────────┘       │ with password"│
                                    └──────────────┘
                                            │
                                            ▼
                                ┌───────────────────┐
                                │ Password Login    │
                                │ → Sync-loading   │
                                │ → Home           │
                                └───────────────────┘
```

---

### Token Expired Flow (> 8 Hours or Backend Session Invalid)

```
┌─────────────────────────────────────────────────────────────┐
│                     USER OPENS APP                          │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
                ┌──────────────────────┐
                │ Check Auth State     │
                │ isAuthenticated?     │
                │ • hasPin: YES        │
                │ • token: EXPIRED      │
                └──────────────────────┘
                            │
                            ▼
                ┌──────────────────────┐
                │ Show PIN Entry Screen│
                │ "Enter PIN to unlock" │
                └──────────────────────┘
                            │
                            ▼
                ┌──────────────────────┐
                │ User Enters PIN      │
                └──────────────┘       │
                            │                │
                            ▼                │
                ┌──────────────────────┐ │
                │ PIN Verification     │ │
                │ • Check PIN hash     │ │
                │ • Retrieve JWT token │ │
                │ • Check expiration   │ │
                └──────────────────────┘ │
                            │                │
                            ▼                │
                    ┌───────────────────┐ │
                    │ Token EXPIRED     │ │
                    │ (or missing)      │ │
                    └───────────────────┘ │
                            │                │
                            ▼                │
                ┌──────────────────────┐ │
                │ Show Error Message   │ │
                │ "Session expired.   │ │
                │  Please login with   │ │
                │  your password."     │ │
                │                      │ │
                │ [Use password instead]│ │
                └──────────────────────┘ │
                            │                │
                            ▼                │
                ┌──────────────────────┐ │
                │ User Taps            │ │
                │ "Use password       │ │
                │  instead"            │ │
                └──────────────────────┘ │
                            │                │
                            ▼                │
                ┌──────────────────────┐ │
                │ Navigate to Login     │ │
                │ ?use_password=true    │ │
                └──────────────────────┘ │
                            │                │
                            ▼                │
                ┌──────────────────────┐ │
                │ Password Login       │ │
                │ • Email + Password   │ │
                │ • Backend validates  │ │
                │ • Fresh JWT tokens   │ │
                └──────────────────────┘ │
                            │                │
                            ▼                │
                ┌──────────────────────┐ │
                │ Set State:          │ │
                │ • isAuthenticated   │
                │ • pinVerifiedViaPassword = true │
                └──────────────────────┘ │
                            │                │
                            ▼                │
                ┌──────────────────────┐ │
                │ Router Checks:       │ │
                │ • isAuth = true      │ │
                │ • pinVerifiedViaPassword = true │
                │ │                   │
                │ └─► Allow Access     │
                │     (skip PIN entry)  │
                └──────────────────────┘ │
                            │                │
                            ▼                │
                ┌──────────────────────┐ │
                │ Navigate to          │ │
                │ Sync-loading → Home    │ │
                └──────────────────────┘ │
                            │                │
                            ▼                │
                ┌───────────────────┐ │
                │ User can use app   │
                │ Fresh session!     │
                └───────────────────┘
```

---

### User Choosing Password Instead (Anytime)

```
┌─────────────────────────────────────────────────────────────┐
│              PIN ENTRY OR PIN SETUP SCREEN                   │
│                                                            │
│  [Use password instead] ← Always available at bottom       │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
                ┌──────────────────────┐
                │ Navigate to Login     │
                │ ?use_password=true    │
                └──────────────────────┘
                            │
                            ▼
                ┌──────────────────────┐
                │ Password Login       │
                │ • Email + Password   │
                │ • Fresh JWT tokens   │
                └──────────────────────┘
                            │
                            ▼
                ┌──────────────────────┐
                │ Set State:          │
                │ • isAuthenticated   │
                │ • pinVerifiedViaPassword = true │
                └──────────────────────┘
                            │
                            ▼
                ┌──────────────────────┐
                │ Router Checks:       │
                │ • isAuth = true      │
                │ • pinVerifiedViaPassword = true │
                │ │                   │
                │ └─► Allow Access     │
                │     (skip PIN entry)  │
                └──────────────────────┘
                            │
                            ▼
                ┌──────────────────────┐
                │ Navigate to          │
                │ Sync-loading → Home    │
                └──────────────────────┘
```

---

## State Management

### Key State Variables

**AuthState** (`auth_service.dart`):
- `isAuthenticated` - User has valid JWT token
- `user` - Current user information
- `pinVerifiedViaPassword` - User just logged in with password (skip PIN entry this session)

**PinVerificationState** (`app_router.dart`):
- `isPinVerified` - User has entered PIN this session
- Resets to `false` on logout
- Resets to `false` on app close

**Router Redirect Logic**:
```dart
// Allow access if ANY of these are true:
1. isAuthenticated = true (valid JWT)
2. pinVerifiedViaPassword = true (just logged in with password)
3. isPinVerified = true (entered PIN this session)
```

---

## Grace Period (8 Hours)

**What is the grace period?**
- After successful password login, user gets an 8-hour session
- During this period, user can use PIN for quick access
- PIN works even if JWT token expires (within 8 hours)

**When does grace period end?**
- 8 hours after password login
- User explicitly logs out
- App is closed and reopened (new session)

**Token Expiration within Grace Period:**
- JWT token expires (e.g., 1 hour)
- User can still use PIN (within 8-hour window)
- No "Session expired" error
- Seamless user experience

**After Grace Period Expires (> 8 hours):**
- PIN entry still shows
- But token expiration check fails
- Shows error: "Session expired. Please login with your password."
- User must login with password again

---

## Error Handling

### Invalid PIN
```
User enters wrong PIN
    ↓
Show error: "Incorrect PIN. Please try again."
    ↓
Increment attempt counter
    ↓
After 3 attempts → Force logout
```

### Session Expired (Token Expired + Grace Period Over)
```
User enters PIN
    ↓
Token is EXPIRED (> 8 hours old)
    ↓
Show error: "Session expired. Please login with your password."
    ↓
User must tap "Use password instead"
    ↓
Login with email + password
    ↓
Fresh session starts
```

### No Cached Credentials
```
User tries PIN
    ↓
No cached JWT token found
    ↓
Show error: "No cached credentials. Please login with your password."
    ↓
User must login with password
```

---

## Security Features

### 1. PIN-Based Authentication
- Quick access for returning users
- 6-digit PIN (not full password)
- Works offline with cached JWT

### 2. Token Expiration Enforcement
- JWT tokens have expiration time
- Grace period: 8 hours after password login
- After grace period: PIN requires valid JWT or password login

### 3. Session Timeout (15 Minutes)
- App locks after 15 minutes of inactivity
- Requires PIN entry to unlock
- Keeps user logged in (JWT still valid)

### 4. Session Duration (8 Hours)
- Full session expires after 8 hours
- Requires password login (not just PIN)
- Prevents indefinite PIN-only access

### 5. Offline Capability
- PIN works offline (within grace period)
- Changes sync when connection restored
- No blocking on network issues

---

## Code Flow Summary

### Password Login Success
```dart
// AuthService.login() succeeds
  ↓
AuthState.login() method
  ↓
Set: isAuthenticated = true
  ↓
Call: _markPinAsVerifiedAfterPasswordLogin()
  ↓
Set: pinVerifiedViaPassword = true
  ↓
Router checks pinVerifiedViaPassword flag
  ↓
Router allows access (skip PIN entry)
  ↓
Navigate to: Sync-loading → Home
```

### PIN Entry Success
```dart
// OfflineAuthService.authenticateWithPin() succeeds
  ↓
AuthState.isAuthenticated = true
  ↓
Call: pinVerificationProvider.markVerified()
  ↓
Router allows access
  ↓
Navigate to: Sync-loading → Home
```

### App Open (Existing User)
```dart
// App starts
  ↓
Check: hasPin? YES
  ↓
Check: isAuthenticated? NO (new session)
  ↓
Check: pinVerifiedViaPassword? NO (not just logged in)
  ↓
Navigate to: /pin-entry
  ↓
User enters PIN
  ↓
Check token expiration
  ↓
If VALID → Allow access
  If EXPIRED → Show error, require password login
```

---

## Test Mode

To test expired token handling, set this flag:

**File:** `lib/services/auth/offline_auth_service.dart`

```dart
// Line 13 - Change to true to test
static bool forceExpiredForTesting = false;  // ← Change to true
```

**When enabled:**
- All PIN authentication attempts will be rejected
- Error: "Session expired. Please login with your password."
- User must login with password
- **Remember to set back to `false` when done!**

---

## Summary

### Key Points

1. ✅ **First time setup:** Password → PIN Setup → Home (no PIN entry required)
2. ✅ **Subsequent opens:** PIN Entry → Home (if token valid)
3. ✅ **Token expired:** PIN Entry → Error → Password Login → Home
4. ✅ **Always available:** "Use password instead" option
5. ✅ **Grace period:** 8 hours after password login
6. ✅ **Security:** PIN requires valid session or fresh login

### User Experience

**First Time:**
- Login with email/password
- Set up 6-digit PIN
- Start using app immediately ✅

**Returning (Within 8 hours):**
- Enter 6-digit PIN
- Quick access to app ✅

**Returning (After 8 hours or token expired):**
- Enter 6-digit PIN
- See "Session expired" error
- Tap "Use password instead"
- Login with email/password
- Back to normal ✅

**Always Can:**
- Choose "Use password instead" anytime
- Full control over authentication method
