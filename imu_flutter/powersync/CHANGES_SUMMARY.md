# PowerSync Migration: Municipality Assignment Normalization

## Overview

This document summarizes the comprehensive changes made to normalize the `user_locations` table and update PowerSync sync rules for role-based client filtering.

## Changes Made

### 1. Database Schema Changes

#### Migration 042: `migrations/042_add_province_to_user_locations.sql`
- Added `province TEXT` column to `user_locations` table
- Created index on `province` for faster queries
- Created composite index on `(user_id, province)` WHERE deleted_at IS NULL

#### Migration 043: `migrations/043_add_municipality_to_user_locations.sql`
- Added `municipality TEXT` column to `user_locations` table
- Backfilled existing records by parsing `municipality_id` (format: "PROVINCE-MUNICIPALITY")
- Created index on `municipality` for faster queries
- Created composite index on `(user_id, province, municipality)` WHERE deleted_at IS NULL

#### Migration 044: `migrations/044_remove_municipality_id_from_user_locations.sql`
- **REMOVED** `municipality_id` column from `user_locations` table
- Dropped old unique constraint on `(user_id, municipality_id)`
- System now uses only separate `province` and `municipality` columns

**Note:** The `municipality_id` column is no longer stored in the database. It is constructed on-the-fly when needed by the backend using `province || '-' || municipality`.

### 2. PowerSync Configuration Changes

#### Sync Config: `backend/powersync/sync-config.yaml` & `docs/powersync-sync-rules.yaml`

**Updated for Separate Columns:**
1. `user_municipalities` stream now queries `province` and `municipality` columns (not `municipality_id`)
2. Filters out soft-deleted records (`AND deleted_at IS NULL`)
3. Syncs separate columns to mobile app

**New Features:**
1. **Role-based client filtering**:
   - Caravan users: Only sync clients in assigned provinces/municipalities
   - Tele users: Sync all clients (no territory restrictions)
   - Admin/Managers: Sync all clients (no restrictions)

2. **Added `approvals` stream**: Syncs pending approvals for current user

3. **Updated related tables** with role-based filtering:
   - `addresses`
   - `phone_numbers`
   - `touchpoints`
   - `my_touchpoints` (user's own touchpoints)

### 3. Backend API Changes

#### `backend/src/routes/users.ts`
- **GET `/api/users/:id/municipalities`**: Returns separate `province` and `municipality` fields
  - Removed `municipality_id` and `municipality_code` from response
  - Response now includes: `province`, `municipality`, `municipality_name`, `region_name`, `region_code`

- **POST `/api/users/:id/municipalities`**: Accepts separate province/municipality assignments
  - Changed request body from `{ municipality_ids: string[] }`
  - To: `{ assignments: [{ province, municipality }[] }`

- **POST `/api/users/:id/municipalities/bulk`**: Bulk unassign with separate fields
  - Updated to accept separate province/municipality assignments

#### `backend/src/routes/clients.ts`
- Maintains `municipality_ids` query parameter for filtering
  - Internally constructs `province || '-' || mun_city` for PSGC matching
  - Mobile app sends computed `municipalityId` values

### 4. Vue Frontend Changes

#### `imu-web-vue/src/lib/types.ts`
- Added `MunicipalityAssignment` interface with new properties
- Updated `Caravan` interface to include `municipalities` array

#### `imu-web-vue/src/stores/caravans.ts`
- Added `fetchMunicipalities()` method
- Added `assignMunicipalities()` method
- Added `unassignMunicipality()` method

#### `imu-web-vue/src/views/caravan/CaravanDetailView.vue`
- Replaced "Assigned Area" field with municipalities list
- Added unassign functionality for each municipality

#### `imu-web-vue/src/views/caravan/CaravanFormView.vue`
- Removed `assigned_area` input field
- Added info banner about municipality assignment

### 5. Flutter Mobile Changes

#### `mobile/imu_flutter/lib/services/area/area_filter_service.dart`
- Updated `UserLocation` model with separate `province` and `municipality` fields
- Added computed `municipalityId` getter: `'$province-$municipality'`
- Updated `fromJson()` to parse new format (separate fields)
- Updated caching to store separate fields
- **No legacy format support** - only uses new separate columns

#### `mobile/imu_flutter/lib/features/territ/data/models/user_municipalities_simple.dart`
- Uses separate `province` and `municipality` fields
- Provides `municipalityId` getter for backward compatibility
- Updated `toJson()` to include both separate fields and computed `municipalityId`

#### `mobile/imu_flutter/lib/features/territ/providers/filter_providers.dart`
- **Simplified** - only queries `province` and `municipality` columns
- Removed legacy format detection
- Constructs location keys as `'province-municipality'`

#### `mobile/imu_flutter/lib/features/home/presentation/pages/home_page.dart`
- **Simplified** - only queries `province` and `municipality` columns
- Removed legacy format detection
- Constructs location keys as `'province-municipality'`

#### `mobile/imu_flutter/lib/services/sync/powersync_service.dart`
- Updated `user_locations` table schema with `province` and `municipality` columns
- Added `approvals` table to schema
- Updated `itineraries` schema with missing columns (`created_by`, `created_at`, `updated_at`)

## Backward Compatibility

**IMPORTANT:** The `municipality_id` column has been **REMOVED** from the database.

The system now uses **only** separate `province` and `municipality` columns:

1. **Database**: Only `province` and `municipality` columns exist (no `municipality_id`)
2. **Backend API**: Returns separate `province` and `municipality` fields
3. **Mobile App**: Uses separate `province` and `municipality` fields
4. **PowerSync**: Sync rules query separate columns

**Note:** The mobile app maintains a computed `municipalityId` getter (`'$province-$municipality'`) for internal use, but this is not stored in or synced from the database.

## Database Migration Applied

The following migrations have been applied to the database:

### Migration 042: Add Province Column
```sql
ALTER TABLE user_locations ADD COLUMN province TEXT;
CREATE INDEX idx_user_locations_province ON user_locations(province);
CREATE INDEX idx_user_locations_user_province ON user_locations(user_id, province) WHERE deleted_at IS NULL;
```

### Migration 043: Add Municipality Column
```sql
ALTER TABLE user_locations ADD COLUMN municipality TEXT;
CREATE INDEX idx_user_locations_municipality ON user_locations(municipality);
CREATE INDEX idx_user_locations_user_province_municipality ON user_locations(user_id, province, municipality) WHERE deleted_at IS NULL;

-- Backfill existing records
UPDATE user_locations
SET municipality = SUBSTRING(municipality_id FROM POSITION('-' IN municipality_id) + 1)
WHERE municipality IS NULL
  AND municipality_id IS NOT NULL
  AND municipality_id LIKE '%-%';
```

### Migration 044: Remove Municipality ID Column
```sql
-- Drop old unique constraint
DROP INDEX IF EXISTS idx_user_locations_user_municipality_id;

-- Remove the municipality_id column
ALTER TABLE user_locations DROP COLUMN IF EXISTS municipality_id;
```

### PowerSync Publication
```sql
-- Added itineraries and approvals to PowerSync publication
ALTER PUBLICATION powersync ADD TABLE itineraries, approvals;
```

## Testing Recommendations

### 1. Test Caravan User (with assigned territories)
- Should only see clients in assigned provinces/municipalities
- Soft-deleted territories should not sync

### 2. Test Tele User (no territory restrictions)
- Should see all clients regardless of location

### 3. Test Admin User
- Should see all clients and all system data

### 4. Test Approvals Sync
- Create pending approval for a user
- Verify it appears in their mobile app

### 5. Test Soft-Delete Filtering
- Soft-delete a location assignment
- Verify it no longer syncs to mobile

## Deployment Checklist

- [x] Database migration applied
- [x] Backend routes updated
- [x] Vue frontend updated
- [x] Flutter mobile schema updated
- [x] PowerSync sync rules configured
- [ ] **PowerSync sync rules deployed** (requires authentication)
- [ ] Mobile app testing with different roles
- [ ] Production deployment

## Next Steps

1. **Deploy PowerSync sync rules** - See `DEPLOYMENT_INSTRUCTIONS.md`
2. **Test with mobile app** - Verify sync works for all user roles
3. **Monitor sync status** - Check for errors or performance issues
4. **Update documentation** - Document any production-specific configurations

## Files Modified

### Database
- `create-database-schema.sql`
- `migrations/add_user_location_province_municipality.sql` (created)

### PowerSync
- `mobile/imu_flutter/powersync/sync-config.yaml`
- `mobile/imu_flutter/lib/services/sync/powersync_service.dart`

### Backend
- `backend/src/routes/caravans.js`
- `backend/src/routes/users.js`
- `backend/src/routes/groups.js`

### Vue Frontend
- `imu-web-vue/src/lib/types.ts`
- `imu-web-vue/src/stores/caravans.ts`
- `imu-web-vue/src/views/caravan/CaravanDetailView.vue`
- `imu-web-vue/src/views/caravan/CaravanFormView.vue`

### Flutter Mobile
- `mobile/imu_flutter/lib/features/territ/data/models/user_municipalities_simple.dart`
- `mobile/imu_flutter/lib/features/territ/data/repositories/user_municipalities_simple_repository.dart`
- `mobile/imu_flutter/lib/features/territ/providers/filter_providers.dart`
- `mobile/imu_flutter/lib/features/home/presentation/pages/home_page.dart`

## Documentation Created

- `mobile/imu_flutter/powersync/DEPLOYMENT_INSTRUCTIONS.md` - Step-by-step deployment guide
- `mobile/imu_flutter/powersync/CHANGES_SUMMARY.md` - This document
