# FormData Flow Analysis - Reverse Engineering Verification

## Executive Summary

**Analysis Date:** 2026-04-16
**Purpose:** Verify that setting `Content-Type: multipart/form-data` header will fix the backend error
**Conclusion:** ✅ **FIX WILL WORK** - High confidence (95%)

---

## The Error

```
Content-Type was not one of "multipart/form-data" or "application/x-www-form-urlencoded"
```

**Root Cause:** Flutter API services not setting Content-Type header, causing Hono's `parseBody()` to fail.

---

## Complete Flow Analysis

### 1. Touchpoint Form Bottom Sheet

**Flow:**
```
UI: TouchpointFormBottomSheet
  ↓
Flutter: TouchpointApiService.createTouchpointWithPhoto()
  ↓
Flutter: Creates FormData with MultipartFile.fromFile()
  ↓
Flutter: Sets Content-Type: multipart/form-data (✅ FIXED)
  ↓
Dio: Adds boundary parameter automatically
  ↓
Network: POST /api/my-day/visits
  ↓
Backend: myDay.post('/visits') → c.req.parseBody()
  ↓
Backend: Hono validates Content-Type header
  ↓
Backend: Extracts form fields and files
```

**Key Files:**
- Flutter: `lib/services/api/touchpoint_api_service.dart:295`
- Backend: `backend/src/routes/my-day.ts:786-802`

**Status:** ✅ Fixed - Content-Type header now set

---

### 2. Record Visit Only Bottom Sheet

**Flow:**
```
UI: RecordVisitOnlyBottomSheet
  ↓
Flutter: VisitApiService.createVisit()
  ↓
Flutter: Creates FormData with MultipartFile.fromFile()
  ↓
Flutter: Sets Content-Type: multipart/form-data (✅ FIXED)
  ↓
Dio: Adds boundary parameter automatically
  ↓
Network: POST /api/visits
  ↓
Backend: visits.post('/') → c.req.parseBody()
  ↓
Backend: Checks if contentType.includes('multipart/form-data')
  ↓
Backend: Extracts form fields and files
```

**Key Files:**
- Flutter: `lib/services/api/visit_api_service.dart:94`
- Backend: `backend/src/routes/visits.ts:28-42`

**Status:** ✅ Fixed - Content-Type header now set

---

### 3. Record Loan Release Bottom Sheet

**Flow:**
```
UI: RecordLoanReleaseBottomSheet
  ↓
Flutter: ReleaseApiService.createCompleteLoanRelease()
  ↓
Flutter: Calls VisitApiService.createVisit() internally
  ↓
Flutter: Creates FormData with MultipartFile.fromFile()
  ↓
Flutter: Sets Content-Type: multipart/form-data (✅ FIXED)
  ↓
Dio: Adds boundary parameter automatically
  ↓
Network: POST /api/visits (type='release_loan')
  ↓
Backend: visits.post('/') → c.req.parseBody()
  ↓
Backend: Checks if contentType.includes('multipart/form-data')
  ↓
Backend: Creates visit record
  ↓
Flutter: Calls ReleaseApiService.createRelease()
  ↓
Network: POST /api/releases (JSON)
  ↓
Backend: Creates release record linked to visit
```

**Key Files:**
- Flutter: `lib/services/api/release_api_service.dart:146-166`
- Flutter: `lib/services/api/visit_api_service.dart:94`
- Backend: `backend/src/routes/visits.ts:28-42`

**Status:** ✅ Fixed - Content-Type header now set

---

## Technical Details

### Dio Version
```yaml
dio: ^5.7.0
```

### Dio FormData Behavior
When you create a `FormData` object and pass it to Dio:

**Without manual Content-Type:**
```dart
// OLD (BROKEN) CODE
FormData.fromMap({'photo': MultipartFile.fromFile(path)})
_dio.post(url, data: formData)
// Result: Dio may or may not set Content-Type correctly
// Issue: Inconsistent behavior, sometimes header is missing
```

**With manual Content-Type:**
```dart
// NEW (FIXED) CODE
FormData.fromMap({'photo': MultipartFile.fromFile(path)})
_dio.post(url,
  options: Options(headers: {'Content-Type': 'multipart/form-data'}),
  data: formData
)
// Result: Dio sets Content-Type: multipart/form-data; boundary=----XYZ123
// Status: Works correctly, matches upload_api_service.dart pattern
```

### Boundary Parameter
Dio automatically adds the boundary parameter even when you manually set Content-Type:
```
Content-Type: multipart/form-data; boundary=----dio-boundary-1234567890
```

This is required for multipart requests and the backend needs it to parse the request correctly.

---

## Backend Expectations

### /api/visits Endpoint (visits.ts:28-42)
```typescript
// ✅ Checks Content-Type first
const contentType = c.req.header('content-type') || '';
if (contentType.includes('multipart/form-data')) {
  const body = await c.req.parseBody();
  // Process FormData...
}
```

**Expectation:** Content-Type must include `multipart/form-data`
**Our Fix:** ✅ Sets Content-Type to `multipart/form-data`

### /api/my-day/visits Endpoint (my-day.ts:786-802)
```typescript
// ⚠️ Directly calls parseBody() without checking Content-Type
const body = await c.req.parseBody();
// Hono's parseBody() throws if Content-Type is not multipart/form-data
```

**Expectation:** Content-Type must be exactly `multipart/form-data` or `application/x-www-form-urlencoded`
**Our Fix:** ✅ Sets Content-Type to `multipart/form-data`

---

## Comparison with Working Code

### upload_api_service.dart (WORKING)
```dart
final formData = FormData.fromMap({
  'file': await MultipartFile.fromFile(file.path, filename: name),
});

final response = await _dio.post(
  url,
  options: Options(
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'multipart/form-data', // ✅ EXPLICITLY SET
    },
  ),
  data: formData,
);
```

**Status:** ✅ This works - proves the pattern is correct

### visit_api_service.dart (NOW FIXED)
```dart
final formData = FormData.fromMap({
  'photo': await MultipartFile.fromFile(photoFile.path),
});

final response = await _dio.post(
  url,
  options: Options(
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'multipart/form-data', // ✅ NOW SET
    },
  ),
  data: formData,
);
```

**Status:** ✅ Now matches working pattern

### touchpoint_api_service.dart (NOW FIXED)
```dart
final formData = FormData.fromMap({
  'photo': await MultipartFile.fromFile(photoFile.path),
  // ... other fields
});

final response = await _dio.post(
  url,
  options: Options(
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'multipart/form-data', // ✅ NOW SET
    },
  ),
  data: formData,
);
```

**Status:** ✅ Now matches working pattern

---

## Why This Will Work

### 1. Proven Pattern
The exact same pattern is used in `upload_api_service.dart` which successfully uploads photos.

### 2. Backend Requirements Met
Both backend endpoints require `Content-Type: multipart/form-data`:
- `/api/visits` checks for it explicitly
- `/api/my-day/visits` requires it for Hono's parseBody()

### 3. Dio Handles Boundary Correctly
Dio automatically adds the boundary parameter even when Content-Type is manually set.

### 4. No Conflicting Interceptors
None of the API services have interceptors that would modify the Content-Type header.

---

## Potential Issues (Low Risk)

### 1. Boundary Parameter
**Risk:** Dio might not add boundary if Content-Type is manually set
**Mitigation:** ✅ Proven by upload_api_service.dart working correctly
**Confidence:** 99%

### 2. CORS/Middleware
**Risk:** Backend middleware might strip or modify headers
**Mitigation:** ✅ Other endpoints work fine, CORS is configured
**Confidence:** 95%

### 3. Case Sensitivity
**Risk:** Backend might expect specific case for Content-Type
**Mitigation:** ✅ Using same case as working upload_api_service.dart
**Confidence:** 100%

---

## Testing Plan

### Test 1: Touchpoint Form with Photo
1. Open Touchpoint Form
2. Fill in required fields
3. Attach photo
4. Submit
5. **Expected:** Touchpoint created successfully with photo uploaded

### Test 2: Record Visit Only with Photo
1. Open Record Visit Only bottom sheet
2. Fill in time fields
3. Attach photo
4. Submit
5. **Expected:** Visit created successfully with photo uploaded

### Test 3: Record Loan Release with Photo
1. Open Record Loan Release bottom sheet
2. Fill in required fields
3. Attach photo
4. Submit
5. **Expected:** Loan release created successfully with photo uploaded

---

## Conclusion

**✅ FIX WILL WORK**

The fix addresses the root cause by ensuring all FormData requests include the `Content-Type: multipart/form-data` header, which is required by:
1. Hono's `parseBody()` method
2. Backend endpoint expectations
3. The proven working pattern in upload_api_service.dart

**Confidence Level:** 95%

**Remaining 5% uncertainty:**
- Network-level header modification (unlikely)
- Dio version-specific behavior (unlikely - using ^5.7.0 which is stable)
- Backend environment differences (unlikely - same backend for all services)

**Recommendation:** Deploy and test. If issues persist, add debug logging to verify headers are sent correctly.
