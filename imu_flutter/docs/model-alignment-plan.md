# Mobile Model Alignment Plan

> **Goal:** Align all Flutter mobile models with the actual PostgreSQL database schema
>
> **Date:** 2026-04-05
>
> **Scope:** 8 core tables synced via PowerSync

---

## Database Schema Sources

- **Source:** Live PostgreSQL database (information_schema)
- **Date:** 2026-04-05
- **Tables:** 8 core tables for mobile sync

---

## Models to Update

### 1. Touchpoint Model ⚠️ CRITICAL

**File:** `lib/features/clients/data/models/client_model.dart` (class Touchpoint)

**Issues:**
- ❌ Field name mismatch: `remarks` → `notes` (database uses `notes`)
- ❌ Field name mismatch: `photoPath` → `photoUrl` (database uses `photo_url`)
- ❌ Field name mismatch: `audioPath` → `audioUrl` (database uses `audio_url`)
- ❌ Missing field: `rejection_reason`
- ❌ Missing field: `updated_at`

**Changes Required:**

```dart
class Touchpoint {
  // ... existing fields ...

  // RENAME: remarks → notes
  final String? notes; // was: remarks

  // RENAME: photoPath → photoUrl
  final String? photoUrl; // was: photoPath

  // RENAME: audioPath → audioUrl
  final String? audioUrl; // was: audioPath

  // ADD: New fields
  final String? rejectionReason; // NEW
  final DateTime? updatedAt; // NEW

  Touchpoint({
    // ... existing params ...
    this.notes, // was: remarks
    this.photoUrl, // was: photoPath
    this.audioUrl, // was: audioPath
    this.rejectionReason, // NEW
    this.updatedAt, // NEW
  });

  Touchpoint copyWith({
    // ... existing params ...
    String? notes, // was: remarks
    String? photoUrl, // was: photoPath
    String? audioUrl, // was: audioPath
    String? rejectionReason, // NEW
    DateTime? updatedAt, // NEW
  }) {
    return Touchpoint(
      // ... existing ...
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    // ... existing ...
    'notes': notes, // was: remarks
    'photo_url': photoUrl, // was: photo_path
    'audio_url': audioUrl, // was: audio_path
    'rejection_reason': rejectionReason, // NEW
    'updated_at': updatedAt?.toIso8601String(), // NEW
  };

  factory Touchpoint.fromJson(Map<String, dynamic> json) {
    return Touchpoint(
      // ... existing ...
      notes: json['notes'], // was: remarks
      photoUrl: json['photo_url'], // was: photo_path
      audioUrl: json['audio_url'], // was: audio_path
      rejectionReason: json['rejection_reason'], // NEW
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null, // NEW
    );
  }

  factory Touchpoint.fromRow(Map<String, dynamic> row) {
    return Touchpoint(
      // ... existing ...
      notes: row['notes'], // was: remarks
      photoUrl: row['photo_url'], // was: photo_path
      audioUrl: row['audio_url'], // was: audio_path
      rejectionReason: row['rejection_reason'], // NEW
      updatedAt: row['updated_at'], // NEW
    );
  }
}
```

**Impact:**
- ⚠️ **BREAKING CHANGE** - All references to `remarks`, `photoPath`, `audioPath` must be updated
- Files affected:
  - `lib/features/touchpoints/presentation/widgets/touchpoint_form.dart`
  - `lib/features/touchpoints/providers/touchpoint_form_provider.dart`
  - `lib/services/api/touchpoint_api_service.dart`
  - `lib/features/clients/presentation/pages/client_detail_page.dart`

---

### 2. Approval Model ⚠️ CRITICAL

**File:** `lib/features/approvals/data/models/approval_model.dart`

**Issues:**
- ❌ Missing field: `updated_client_information` (JSONB)
- ❌ Missing field: `updated_udi`
- ❌ Missing field: `udi_number`
- ❌ Missing field: `rejected_by`
- ❌ Missing field: `rejected_at`
- ❌ Missing field: `rejection_reason`
- ❌ Missing field: `updated_at`

**Changes Required:**

```dart
class Approval {
  final String id;
  final String type;
  final String? status;
  final String clientId;
  final String? userId;
  final int? touchpointNumber;
  final String? role;
  final String? reason;
  final String? notes;

  // NEW FIELDS
  final Map<String, dynamic>? updatedClientInformation; // JSONB
  final String? updatedUdi;
  final String? udiNumber;
  final String? rejectedBy;
  final DateTime? rejectedAt;
  final String? rejectionReason;

  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime createdAt;
  final DateTime? updatedAt; // NEW

  Approval({
    required this.id,
    required this.type,
    this.status,
    required this.clientId,
    this.userId,
    this.touchpointNumber,
    this.role,
    this.reason,
    this.notes,
    this.updatedClientInformation, // NEW
    this.updatedUdi, // NEW
    this.udiNumber, // NEW
    this.approvedBy,
    this.approvedAt,
    this.rejectedBy, // NEW
    this.rejectedAt, // NEW
    this.rejectionReason, // NEW
    required this.createdAt,
    this.updatedAt, // NEW
  });

  Approval copyWith({
    // ... existing params ...
    Map<String, dynamic>? updatedClientInformation,
    String? updatedUdi,
    String? udiNumber,
    String? rejectedBy,
    DateTime? rejectedAt,
    String? rejectionReason,
    DateTime? updatedAt,
  });

  Map<String, dynamic> toJson() => {
    // ... existing ...
    'updated_client_information': updatedClientInformation,
    'updated_udi': updatedUdi,
    'udi_number': udiNumber,
    'rejected_by': rejectedBy,
    'rejected_at': rejectedAt?.toIso8601String(),
    'rejection_reason': rejectionReason,
    'updated_at': updatedAt?.toIso8601String(),
  };

  factory Approval.fromJson(Map<String, dynamic> json) {
    return Approval(
      // ... existing ...
      updatedClientInformation: json['updated_client_information'],
      updatedUdi: json['updated_udi'],
      udiNumber: json['udi_number'],
      rejectedBy: json['rejected_by'],
      rejectedAt: json['rejected_at'] != null
          ? DateTime.parse(json['rejected_at'])
          : null,
      rejectionReason: json['rejection_reason'],
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  factory Approval.fromRow(Map<String, dynamic> row) {
    return Approval(
      // ... existing ...
      updatedClientInformation: row['updated_client_information'],
      updatedUdi: row['updated_udi'],
      udiNumber: row['udi_number'],
      rejectedBy: row['rejected_by'],
      rejectedAt: row['rejected_at'],
      rejectionReason: row['rejection_reason'],
      updatedAt: row['updated_at'],
    );
  }
}
```

**Impact:**
- New fields for rejection workflow
- Support for UDI updates
- No breaking changes (additive only)

---

### 3. Itinerary Model

**File:** `lib/features/itineraries/data/models/itinerary_model.dart`

**Issues:**
- ❌ Missing field: `created_by`
- ❌ Missing field: `updated_at`

**Changes Required:**

```dart
class Itinerary {
  final String id;
  final String? userId;
  final String? clientId;
  final DateTime scheduledDate;
  final String? scheduledTime;
  final String? status;
  final String? priority;
  final String? notes;
  final String? createdBy; // NEW
  final DateTime createdAt;
  final DateTime? updatedAt; // NEW

  Itinerary({
    required this.id,
    this.userId,
    this.clientId,
    required this.scheduledDate,
    this.scheduledTime,
    this.status,
    this.priority,
    this.notes,
    this.createdBy, // NEW
    required this.createdAt,
    this.updatedAt, // NEW
  });

  Itinerary copyWith({
    String? id,
    String? userId,
    String? clientId,
    DateTime? scheduledDate,
    String? scheduledTime,
    String? status,
    String? priority,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Itinerary(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      clientId: clientId ?? this.clientId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'client_id': clientId,
    'scheduled_date': scheduledDate.toIso8601String(),
    'scheduled_time': scheduledTime,
    'status': status,
    'priority': priority,
    'notes': notes,
    'created_by': createdBy,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    return Itinerary(
      id: json['id'],
      userId: json['user_id'],
      clientId: json['client_id'],
      scheduledDate: DateTime.parse(json['scheduled_date']),
      scheduledTime: json['scheduled_time'],
      status: json['status'],
      priority: json['priority'],
      notes: json['notes'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  factory Itinerary.fromRow(Map<String, dynamic> row) {
    return Itinerary(
      id: row['id'],
      userId: row['user_id'],
      clientId: row['client_id'],
      scheduledDate: row['scheduled_date'],
      scheduledTime: row['scheduled_time'],
      status: row['status'],
      priority: row['priority'],
      notes: row['notes'],
      createdBy: row['created_by'],
      createdAt: row['created_at'],
      updatedAt: row['updated_at'],
    );
  }
}
```

**Impact:**
- Track who created itinerary entries
- Track modification time
- No breaking changes (additive only)

---

### 4. PSGC Model

**Discovery Required:**

Step 1: Search for existing PSGC model:
```bash
cd mobile/imu_flutter
grep -r "class.*PSGC" lib/ --include="*.dart"
grep -r "class.*Psgc" lib/ --include="*.dart" -i
```

**If found:** Update that file with the new fields below

**If not found:** Create new file at `lib/features/psgc/data/models/psgc_model.dart`

**File:** `lib/features/psgc/data/models/psgc_model.dart` (CREATE if doesn't exist)

**Issues:**
- ❌ Missing field: `mun_city_kind`
- ❌ Missing field: `mun_city`
- ❌ Missing field: `pin_location` (JSONB)

**Changes Required:**

```dart
class PSGC {
  final int id;
  final String region;
  final String province;
  final String? munCityKind; // NEW
  final String? munCity; // NEW
  final String? barangay;
  final Map<String, dynamic>? pinLocation; // NEW - JSONB
  final String? zipCode;

  PSGC({
    required this.id,
    required this.region,
    required this.province,
    this.munCityKind, // NEW
    this.munCity, // NEW
    this.barangay,
    this.pinLocation, // NEW
    this.zipCode,
  });

  PSGC copyWith({
    int? id,
    String? region,
    String? province,
    String? munCityKind,
    String? munCity,
    String? barangay,
    Map<String, dynamic>? pinLocation,
    String? zipCode,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'region': region,
    'province': province,
    'mun_city_kind': munCityKind,
    'mun_city': munCity,
    'barangay': barangay,
    'pin_location': pinLocation,
    'zip_code': zipCode,
  };

  factory PSGC.fromJson(Map<String, dynamic> json) {
    return PSGC(
      id: json['id'],
      region: json['region'],
      province: json['province'],
      munCityKind: json['mun_city_kind'],
      munCity: json['mun_city'],
      barangay: json['barangay'],
      pinLocation: json['pin_location'],
      zipCode: json['zip_code'],
    );
  }

  factory PSGC.fromRow(Map<String, dynamic> row) {
    return PSGC(
      id: row['id'],
      region: row['region'],
      province: row['province'],
      munCityKind: row['mun_city_kind'],
      munCity: row['mun_city'],
      barangay: row['barangay'],
      pinLocation: row['pin_location'],
      zipCode: row['zip_code'],
    );
  }
}
```

**Impact:**
- Support for city/municipality classification
- Support for GPS pin locations
- No breaking changes (additive only)

---

### 5. TouchpointReason Model

**File:** Need to verify location

**Issues:**
- ❌ Missing field: `created_at`
- ❌ Missing field: `updated_at`

**Changes Required:**

```dart
class TouchpointReason {
  final String id;
  final String reasonCode;
  final String label;
  final String touchpointType;
  final String role;
  final String? category;
  final int? sortOrder;
  final bool isActive;
  final DateTime createdAt; // NEW
  final DateTime? updatedAt; // NEW

  TouchpointReason({
    required this.id,
    required this.reasonCode,
    required this.label,
    required this.touchpointType,
    required this.role,
    this.category,
    this.sortOrder,
    this.isActive = true,
    required this.createdAt, // NEW
    this.updatedAt, // NEW
  });

  TouchpointReason copyWith({
    String? id,
    String? reasonCode,
    String? label,
    String? touchpointType,
    String? role,
    String? category,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TouchpointReason(
      id: id ?? this.id,
      reasonCode: reasonCode ?? this.reasonCode,
      label: label ?? this.label,
      touchpointType: touchpointType ?? this.touchpointType,
      role: role ?? this.role,
      category: category ?? this.category,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'reason_code': reasonCode,
    'label': label,
    'touchpoint_type': touchpointType,
    'role': role,
    'category': category,
    'sort_order': sortOrder,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  factory TouchpointReason.fromJson(Map<String, dynamic> json) {
    return TouchpointReason(
      id: json['id'],
      reasonCode: json['reason_code'],
      label: json['label'],
      touchpointType: json['touchpoint_type'],
      role: json['role'],
      category: json['category'],
      sortOrder: json['sort_order'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  factory TouchpointReason.fromRow(Map<String, dynamic> row) {
    return TouchpointReason(
      id: row['id'],
      reasonCode: row['reason_code'],
      label: row['label'],
      touchpointType: row['touchpoint_type'],
      role: row['role'],
      category: row['category'],
      sortOrder: row['sort_order'],
      isActive: row['is_active'] ?? true,
      createdAt: row['created_at'],
      updatedAt: row['updated_at'],
    );
  }
}
```

**Impact:**
- Track when reasons were created/modified
- No breaking changes (additive only)

---

### 6. UserProfile Model

**File:** Need to verify location

**Issues:**
- ❌ Missing field: `employee_id`
- ❌ Missing field: `first_name`
- ❌ Missing field: `last_name`
- ❌ Missing field: `phone`
- ❌ Missing field: `area_manager_id`
- ❌ Missing field: `assistant_area_manager_id`

**Changes Required:**

```dart
class UserProfile {
  final String id;
  final String? userId;
  final String name;
  final String email;
  final String? role;
  final String? avatarUrl;

  // NEW FIELDS
  final String? employeeId;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? areaManagerId;
  final String? assistantAreaManagerId;

  final DateTime updatedAt;

  UserProfile({
    required this.id,
    this.userId,
    required this.name,
    required this.email,
    this.role,
    this.avatarUrl,
    this.employeeId, // NEW
    this.firstName, // NEW
    this.lastName, // NEW
    this.phone, // NEW
    this.areaManagerId, // NEW
    this.assistantAreaManagerId, // NEW
    required this.updatedAt,
  });

  UserProfile copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? role,
    String? avatarUrl,
    String? employeeId,
    String? firstName,
    String? lastName,
    String? phone,
    String? areaManagerId,
    String? assistantAreaManagerId,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      employeeId: employeeId ?? this.employeeId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      areaManagerId: areaManagerId ?? this.areaManagerId,
      assistantAreaManagerId: assistantAreaManagerId ?? this.assistantAreaManagerId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'email': email,
    'role': role,
    'avatar_url': avatarUrl,
    'employee_id': employeeId,
    'first_name': firstName,
    'last_name': lastName,
    'phone': phone,
    'area_manager_id': areaManagerId,
    'assistant_area_manager_id': assistantAreaManagerId,
    'updated_at': updatedAt.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      avatarUrl: json['avatar_url'],
      employeeId: json['employee_id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      phone: json['phone'],
      areaManagerId: json['area_manager_id'],
      assistantAreaManagerId: json['assistant_area_manager_id'],
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  factory UserProfile.fromRow(Map<String, dynamic> row) {
    return UserProfile(
      id: row['id'],
      userId: row['user_id'],
      name: row['name'],
      email: row['email'],
      role: row['role'],
      avatarUrl: row['avatar_url'],
      employeeId: row['employee_id'],
      firstName: row['first_name'],
      lastName: row['last_name'],
      phone: row['phone'],
      areaManagerId: row['area_manager_id'],
      assistantAreaManagerId: row['assistant_area_manager_id'],
      updatedAt: row['updated_at'],
    );
  }
}
```

**Impact:**
- Support for employee IDs
- Support for separate first/last names
- Support for manager hierarchy
- No breaking changes (additive only)

---

### 7. Client Model

**File:** `lib/features/clients/data/models/client_model.dart` (class Client)

**Issues:**
- ❌ Type mismatch: `psgc_id` is `String?` but should be `int?`

**Changes Required:**

```dart
class Client {
  // ... existing fields ...

  final int? psgcId; // CHANGE: was String?, now int?

  Client({
    // ... existing params ...
    this.psgcId, // Type changed
    // ... rest ...
  });

  Client copyWith({
    // ... existing params ...
    int? psgcId, // Type changed
    // ... rest ...
  }) {
    return Client(
      // ... existing ...
      psgcId: psgcId ?? this.psgcId,
      // ... rest ...
    );
  }

  Map<String, dynamic> toJson() => {
    // ... existing ...
    'psgc_id': psgcId, // Already correct (int to JSON)
    // ... rest ...
  };

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      // ... existing ...
      psgcId: json['psgc_id'] as int?, // CHANGE: Parse as int
      // ... rest ...
    );
  }

  factory Client.fromRow(Map<String, dynamic> row) {
    return Client(
      // ... existing ...
      psgcId: row['psgc_id'] as int?, // CHANGE: Parse as int
      // ... rest ...
    );
  }
}
```

**Impact:**
- ⚠️ **POTENTIAL BREAKING CHANGE** - Any code treating psgcId as String may break
- More accurate type representation
- Aligns with database INTEGER type

---

### 8. UserLocation Model

**File:** Need to verify location and completeness

**Verification Required:**
- ✅ All fields present in PowerSync sync config
- ⚠️ `created_at` and `updated_at` NOT synced (only in database)

**Current fields (from PowerSync):**
```dart
class UserLocation {
  final String id;
  final String userId;
  final String province;
  final String municipality;
  final DateTime? assignedAt;
  final String? assignedBy;
  final DateTime? deletedAt;
}
```

**No changes required** - PowerSync sync config already correct.

---

## Implementation Order

### Phase 1: Critical Models (Breaking Changes)
1. **Touchpoint Model** - Field renames affect multiple files
2. **Client Model** - Type change may affect code

### Phase 2: Important Models (Additive Changes)
3. **Approval Model** - New rejection workflow fields
4. **Itinerary Model** - Tracking fields

### Phase 3: Supporting Models (Additive Changes)
5. **PSGC Model** - New location fields
6. **TouchpointReason Model** - Timestamp fields
7. **UserProfile Model** - Employee/hierarchy fields

### Phase 4: Verification
8. **UserLocation Model** - Verify no changes needed

---

## Testing Checklist

For each model update:

- [ ] Model compiles without errors
- [ ] `toJson()` produces correct snake_case output
- [ ] `fromJson()` handles both snake_case and camelCase
- [ ] `fromRow()` handles PowerSync row format
- [ ] `copyWith()` includes all new fields
- [ ] All references updated (for renamed fields)
- [ ] PowerSync sync rules aligned with model fields
- [ ] API services use correct field names

---

## Migration Notes

### Backend API Verification

**IMPORTANT:** Verify backend returns correct field names before updating mobile models.

#### Test Commands

```bash
# Set your API URL and token
API_URL="https://imu-api.cfbtools.app/api"
TOKEN="your-jwt-token-here"

# Test Touchpoints endpoint
echo "=== Testing Touchpoints API ==="
curl -H "Authorization: Bearer $TOKEN" \
  "$API_URL/touchpoints?limit=1" | jq '.[0] | {
    notes: .notes,
    photo_url: .photo_url,
    audio_url: .audio_url,
    rejection_reason: .rejection_reason,
    updated_at: .updated_at
  }'

# Test Clients endpoint
echo "=== Testing Clients API ==="
curl -H "Authorization: Bearer $TOKEN" \
  "$API_URL/clients?limit=1" | jq '.[0] | {
    psgc_id: (.psgc_id | type),
    udi: .udi
  }'

# Test Approvals endpoint
echo "=== Testing Approvals API ==="
curl -H "Authorization: Bearer $TOKEN" \
  "$API_URL/approvals?limit=1" | jq '.[0] | {
    rejected_by: .rejected_by,
    rejected_at: .rejected_at,
    rejection_reason: .rejection_reason,
    updated_client_information: .updated_client_information,
    updated_at: .updated_at
  }'

# Test Itineraries endpoint
echo "=== Testing Itineraries API ==="
curl -H "Authorization: Bearer $TOKEN" \
  "$API_URL/itineraries?limit=1" | jq '.[0] | {
    created_by: .created_by,
    updated_at: .updated_at
  }'

# Test PSGC endpoint
echo "=== Testing PSGC API ==="
curl -H "Authorization: Bearer $TOKEN" \
  "$API_URL/psgc?limit=1" | jq '.[0] | {
    mun_city_kind: .mun_city_kind,
    mun_city: .mun_city,
    pin_location: .pin_location
  }'

# Test UserProfile endpoint
echo "=== Testing UserProfile API ==="
curl -H "Authorization: Bearer $TOKEN" \
  "$API_URL/profile" | jq '{
    employee_id: .employee_id,
    first_name: .first_name,
    last_name: .last_name,
    phone: .phone,
    area_manager_id: .area_manager_id,
    assistant_area_manager_id: .assistant_area_manager_id
  }'
```

#### Expected Results

**Touchpoints:**
```json
{
  "notes": "Example notes",
  "photo_url": "https://s3.amazonaws.com/...",
  "audio_url": "https://s3.amazonaws.com/...",
  "rejection_reason": null,
  "updated_at": "2026-04-05T10:00:00Z"
}
```

**Clients:**
```json
{
  "psgc_id": "number",  // Should be "number", not "string"
  "udi": "123456789"
}
```

**Approvals:**
```json
{
  "rejected_by": "uuid-or-null",
  "rejected_at": "2026-04-05T10:00:00Z-or-null",
  "rejection_reason": "Reason text or null",
  "updated_client_information": {...},
  "updated_at": "2026-04-05T10:00:00Z"
}
```

---

### PowerSync Sync Config Updates

**File:** `mobile/imu_flutter/powersync/sync-config.yaml`

#### Update Steps

1. **Update sync-config.yaml:**

```yaml
touchpoints:
  queries:
    - SELECT t.id, t.client_id, t.user_id, t.touchpoint_number, t.type,
        t.date, t.time_arrival, t.time_departure, t.reason, t.status, t.notes,
        t.photo_url, t.audio_url,  # UPDATED: was photo_path, audio_path
        t.rejection_reason,        # NEW
        t.created_at, t.updated_at
      FROM touchpoints t
      WHERE ...
```

2. **Validate sync config:**

```bash
cd mobile/imu_flutter/powersync
npx @powersync/service-cli validate sync-config.yaml
```

3. **Deploy sync rules:**

```bash
# Option A: Using deploy script
./deploy_sync_rules.sh

# Option B: Manual deployment
npx @powersync/service-cli deploy sync-config.yaml
```

4. **Verify in PowerSync Dashboard:**

- Go to: https://dashboard.powersync.com
- Check sync rules are updated
- Verify query syntax is valid

5. **Test on device:**

- Clear app data on test device
- Reinstall app with new sync rules
- Verify data syncs correctly

---

## Estimated Time

| Phase | Tasks | Time |
|-------|-------|------|
| Phase 1 | Touchpoint, Client models | 2 hours |
| Phase 2 | Approval, Itinerary models | 1 hour |
| Phase 3 | PSGC, TouchpointReason, UserProfile | 1 hour |
| Phase 4 | UserLocation verification | 15 minutes |
| Testing | All models | 1 hour |
| **Total** | | **5-6 hours** |

---

## Rollback Plan

If issues arise:
1. Git revert all model changes
2. Restore previous PowerSync sync config
3. Re-deploy backend with old field names
4. Document issues for future fixes

---

## Dependencies

- **Required:** Database schema access (confirmed ✅)
- **Required:** PowerSync sync config access (confirmed ✅)
- **Required:** Backend API alignment verification (pending)
- **Optional:** Data migration script for existing records

---

## Affected Features & Cross-Checks

### 🔴 CRITICAL: Touchpoint Model Field Renames

**Breaking Changes:** `remarks` → `notes`, `photoPath` → `photoUrl`, `audioPath` → `audioUrl`

**Affected Files (10 total):**

| File | Line Reference | Usage | Action Required |
|------|----------------|-------|-----------------|
| `client_model.dart` | Touchpoint class | Model definition | ✅ Update model |
| `touchpoint_form.dart` | Widget | Form fields | ⚠️ **UPDATE** field references |
| `touchpoint_form_provider.dart` | Provider | State management | ⚠️ **UPDATE** field references |
| `client_detail_page.dart` | Page | Touchpoint display | ⚠️ **UPDATE** display logic |
| `touchpoint_api_service.dart` | API service | API calls | ⚠️ **UPDATE** JSON parsing |
| `touchpoint_repository.dart` | Repository | Data access | ⚠️ **UPDATE** serialization |
| `edit_client_form.dart` | Widget | Client editing | ⚠️ **UPDATE** if touchpoints shown |
| `edit_client_form_v2.dart` | Widget | Client editing | ⚠️ **UPDATE** if touchpoints shown |
| `client_api_service.dart` | API service | Client API calls | ⚠️ **UPDATE** if touchpoints included |
| `client_repository.dart` | Repository | Client data access | ⚠️ **UPDATE** if touchpoints included |

**Features Affected:**
- ✅ **Touchpoint Creation** - Form fields renamed
- ✅ **Touchpoint Display** - Client detail page shows touchpoints
- ✅ **Touchpoint Editing** - Edit functionality uses renamed fields
- ✅ **Photo/Audio Upload** - File path references changed
- ✅ **Touchpoint Sync** - PowerSync integration uses new field names
- ✅ **API Communication** - Backend expects `notes`, `photo_url`, `audio_url`

**Cross-Check Commands:**

```bash
# Find all references to old field names
cd mobile/imu_flutter
grep -r "\.remarks" lib/ --include="*.dart"
grep -r "\.photoPath" lib/ --include="*.dart"
grep -r "\.audioPath" lib/ --include="*.dart"
grep -r "remarks:" lib/ --include="*.dart"
grep -r "photoPath:" lib/ --include="*.dart"
grep -r "audioPath:" lib/ --include="*.dart"
```

**Verification After Update:**
```bash
# Should return NO results after fix
grep -r "\.remarks" lib/ --include="*.dart"
grep -r "\.photoPath" lib/ --include="*.dart"
grep -r "\.audioPath" lib/ --include="*.dart"

# Should return results (new field names)
grep -r "\.notes" lib/ --include="*.dart"
grep -r "\.photoUrl" lib/ --include="*.dart"
grep -r "\.audioUrl" lib/ --include="*.dart"
```

---

### 🟡 MEDIUM: Client Model psgcId Type Change

**Breaking Change:** `psgc_id` type from `String?` to `int?`

**Affected Files (3 total):**

| File | Line Reference | Usage | Action Required |
|------|----------------|-------|-----------------|
| `client_model.dart` | Client class | Model definition | ✅ Update type |
| `edit_client_form_v2.dart` | Widget | Client editing | ⚠️ **VERIFY** dropdown handling |
| `powersync_service.dart` | Service | Sync configuration | ⚠️ **VERIFY** type handling |

**Features Affected:**
- ✅ **Client Creation** - PSGC dropdown selection
- ✅ **Client Editing** - PSGC field display/update
- ✅ **Client Sync** - PowerSync type conversion
- ✅ **Location Filtering** - PSGC-based territory filtering

**Cross-Check Commands:**

```bash
# Find all psgcId references
cd mobile/imu_flutter
grep -r "psgcId" lib/ --include="*.dart" -n
grep -r "psgc_id" lib/ --include="*.dart" -n
```

**Verification After Update:**
```bash
# Check type annotations
grep -r "String\? psgcId" lib/ --include="*.dart"  # Should return NO results
grep -r "int\? psgcId" lib/ --include="*.dart"     # Should return results
```

---

### 🟢 LOW: Approval Model Additions

**Additive Changes:** New rejection workflow fields, UDI update fields

**Affected Files (5 total):**

| File | Usage | Action Required |
|------|-------|-----------------|
| `approval_model.dart` | Model definition | ✅ Add new fields |
| `pending_approvals_page.dart` | UI display | ⚠️ **UPDATE** to show rejection info |
| `approvals_api_service.dart` | API calls | ⚠️ **VERIFY** JSON parsing |
| `approvals_provider.dart` | State management | ⚠️ **UPDATE** to include new fields |
| `approvals_api_service.dart` (dup) | API service | ⚠️ **VERIFY** endpoint handling |

**Features Affected:**
- ✅ **Approval List** - Display rejection reasons
- ✅ **Approval Detail** - Show rejection workflow
- ✅ **UDI Updates** - Handle UDI change approvals
- ✅ **Client Updates** - Track updated client information

**Cross-Check Commands:**

```bash
# Find all Approval usage
cd mobile/imu_flutter
grep -r "Approval(" lib/ --include="*.dart" -n
grep -r "class.*Approval" lib/ --include="*.dart" -n
```

**Verification After Update:**
```bash
# Check new fields exist
grep -r "rejectionReason" lib/ --include="*.dart" -n
grep -r "updatedClientInformation" lib/ --include="*.dart" -n
grep -r "rejectedBy" lib/ --include="*.dart" -n
```

---

### 🟢 LOW: Itinerary Model Additions

**Additive Changes:** `created_by`, `updated_at` fields

**Affected Files (8 total):**

| File | Usage | Action Required |
|------|-------|-----------------|
| `itinerary_model.dart` | Model definition | ✅ Add new fields |
| `itinerary_page.dart` | Main itinerary page | ⚠️ **OPTIONAL** display creator |
| `itinerary_detail_page.dart` | Detail view | ⚠️ **OPTIONAL** show timestamps |
| `itinerary_api_service.dart` | API calls | ⚠️ **VERIFY** JSON parsing |
| `client_selector_modal.dart` | Client selection | ⚠️ **VERIFY** itinerary creation |
| `ownership_service.dart` | Ownership logic | ⚠️ **VERIFY** uses created_by |
| `itinerary_skeleton.dart` | Loading skeleton | No changes needed |
| `hive_service.dart` | Local storage | ⚠️ **VERIFY** local schema |

**Features Affected:**
- ✅ **Itinerary Creation** - Track creator
- ✅ **Itinerary Display** - Show modification time
- ✅ **My Day View** - Itinerary list display
- ✅ **Ownership Validation** - Use created_by for permissions

**Cross-Check Commands:**

```bash
# Find all Itinerary usage
cd mobile/imu_flutter
grep -r "Itinerary(" lib/ --include="*.dart" -n
grep -r "class.*Itinerary" lib/ --include="*.dart" -n
```

---

### 🟢 LOW: PSGC Model Additions

**Additive Changes:** `mun_city_kind`, `mun_city`, `pin_location` fields

**Status:** ⚠️ **MODEL MAY NOT EXIST** - Need to create or verify

**Potential Affected Files:**

| File | Usage | Action Required |
|------|-------|-----------------|
| `psgc_api_service.dart` | API service | ⚠️ **VERIFY** handles new fields |
| `psgc/` feature folder | PSGC features | ⚠️ **VERIFY** dropdowns use new fields |
| `edit_client_form_v2.dart` | Location dropdowns | ⚠️ **VERIFY** PSGC selection |

**Features Affected:**
- ✅ **Location Dropdowns** - Province/municipality selection
- ✅ **Client Creation** - PSGC-based location
- ✅ **Client Editing** - Location field updates
- ✅ **Territory Filtering** - PSGC-based filtering

**Cross-Check Commands:**

```bash
# Find PSGC usage
cd mobile/imu_flutter
grep -r "PSGC" lib/ --include="*.dart" -n
grep -r "psgc" lib/ --include="*.dart" -n
```

---

### 🟢 LOW: TouchpointReason Model Additions

**Additive Changes:** `created_at`, `updated_at` fields

**Affected Files (2 total):**

| File | Usage | Action Required |
|------|-------|-----------------|
| `client_model.dart` | TouchpointReason enum/class | ✅ Add timestamps |
| `client_list_tile.dart` | Touchpoint display | ⚠️ **OPTIONAL** show timestamps |

**Features Affected:**
- ✅ **Touchpoint Creation** - Reason dropdown
- ✅ **Touchpoint Display** - Show reason labels
- ✅ **Reason Filtering** - Filter by role/category

**Cross-Check Commands:**

```bash
# Find TouchpointReason usage
cd mobile/imu_flutter
grep -r "TouchpointReason" lib/ --include="*.dart" -n
```

---

### 🟢 LOW: UserProfile Model Additions

**Additive Changes:** Employee fields, manager hierarchy fields

**Affected Files (7 total):**

| File | Usage | Action Required |
|------|-------|-----------------|
| `user_profile.dart` | Model definition | ✅ Add new fields |
| `app_providers.dart` | App providers | ⚠️ **UPDATE** profile provider |
| `profile_api_service.dart` | API service | ⚠️ **VERIFY** JSON parsing |
| `offline_auth_service.dart` | Auth service | ⚠️ **VERIFY** profile caching |
| `area_filter_service.dart` | Area filtering | ⚠️ **VERIFY** manager hierarchy |
| `user_municipalities_simple.dart` | User locations | ⚠️ **VERIFY** profile integration |
| `user_municipalities_simple_repository.dart` | Repository | ⚠️ **VERIFY** data access |

**Features Affected:**
- ✅ **Profile Display** - Show employee info
- ✅ **Manager Assignment** - Area manager hierarchy
- ✅ **Contact Info** - Phone number display
- ✅ **Area Filtering** - Manager-based territory access

**Cross-Check Commands:**

```bash
# Find UserProfile usage
cd mobile/imu_flutter
grep -r "UserProfile" lib/ --include="*.dart" -n
```

---

### 🟢 LOW: UserLocation Model Verification

**Status:** ✅ **NO CHANGES NEEDED** - PowerSync already synced correctly

**Affected Files (4 total):**

| File | Usage | Action Required |
|------|-------|-----------------|
| `user_municipalities_simple.dart` | Model definition | ✅ Already aligned |
| `area_filter_service.dart` | Area filtering | ✅ Uses correct fields |
| `app_providers.dart` | Providers | ✅ Already integrated |
| `user_municipalities_simple_repository.dart` | Repository | ✅ Already aligned |

**Features Affected:**
- ✅ **Territory Assignment** - User municipality assignments
- ✅ **Client Filtering** - Territory-based client access
- ✅ **Area Management** - Manager territory oversight

**Cross-Check Commands:**

```bash
# Verify UserLocation has all required fields
cd mobile/imu_flutter
grep -A 10 "class.*UserLocation" lib/ --include="*.dart" -n
```

---

## Master Cross-Check Checklist

### Before Implementation

- [ ] **Backup current code** - Create git branch for model changes
- [ ] **Export current database schema** - Save for rollback reference
- [ ] **Document all API endpoints** - Know which backend calls will be affected
- [ ] **Identify test cases** - List all tests that need updating

### During Implementation

For each model update:

- [ ] **Update model class** - Add/modify fields
- [ ] **Update toJson()** - Ensure snake_case output
- [ ] **Update fromJson()** - Handle both snake_case and camelCase
- [ ] **Update fromRow()** - Handle PowerSync row format
- [ ] **Update copyWith()** - Include all new/renamed fields
- [ ] **Search for usages** - Find all references to changed fields
- [ ] **Update all references** - Fix field name/type changes
- [ ] **Run flutter analyze** - Check for compilation errors
- [ ] **Run affected tests** - Verify tests still pass

### After Implementation

- [ ] **Cross-check all affected files** - Verify no old field references remain
- [ ] **Update PowerSync sync config** - Align with new field names
- [ ] **Test offline mode** - Verify Hive storage works
- [ ] **Test online mode** - Verify API calls work
- [ ] **Test sync functionality** - Verify PowerSync syncs correctly
- [ ] **Manual testing** - Test each affected feature
- [ ] **Integration testing** - Test full user flows

### Feature-Level Testing

- [ ] **Touchpoint Feature** - Create, edit, display, sync touchpoints
- [ ] **Client Feature** - Create, edit, display clients with PSGC
- [ ] **Approval Feature** - Create, approve, reject approvals
- [ ] **Itinerary Feature** - Create, view, edit itineraries
- [ ] **Profile Feature** - Display user profile with new fields
- [ ] **Location Feature** - PSGC dropdowns, territory filtering

---

## Summary Table: Impact by Feature

| Feature | Models Affected | Files to Update | Breaking Change | Priority |
|---------|----------------|-----------------|-----------------|----------|
| **Touchpoints** | Touchpoint | 10 files | ✅ YES (field renames) | 🔴 CRITICAL |
| **Clients** | Client, PSGC | 3 files | ⚠️ PARTIAL (psgcId type) | 🟡 MEDIUM |
| **Approvals** | Approval | 5 files | ❌ No (additive) | 🟢 LOW |
| **Itineraries** | Itinerary | 8 files | ❌ No (additive) | 🟢 LOW |
| **Profile** | UserProfile | 7 files | ❌ No (additive) | 🟢 LOW |
| **Locations** | PSGC, UserLocation | 4 files | ❌ No (additive) | 🟢 LOW |
| **Touchpoint Reasons** | TouchpointReason | 2 files | ❌ No (additive) | 🟢 LOW |

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| **Field rename breaks existing code** | HIGH | HIGH | Comprehensive grep search, update all references |
| **Type change causes runtime errors** | MEDIUM | MEDIUM | Type checking, null safety verification |
| **PowerSync sync breaks** | MEDIUM | HIGH | Test sync config before deployment |
| **Backend API mismatch** | LOW | HIGH | Verify backend returns new fields |
| **Offline storage corruption** | LOW | MEDIUM | Test Hive migration, provide rollback |

---

## Rollback Strategy

If critical issues arise after deployment:

1. **Immediate Actions:**
   - Revert model changes via git
   - Restore previous PowerSync sync config
   - Clear local app data (force fresh sync)

2. **Data Recovery:**
   - Backend maintains all data with backward compatibility
   - PowerSync preserves data during sync rule updates
   - Hive local storage can be cleared and re-synced

3. **Communication:**
   - Notify users of app update
   - Provide rollback instructions if needed
   - Document issues for future fixes
