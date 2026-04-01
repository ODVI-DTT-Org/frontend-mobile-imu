# PowerSync Migration: Municipality Assignment Normalization

## Overview

This document summarizes the comprehensive changes made to normalize the `user_locations` table and update PowerSync sync rules for role-based client filtering.

## Changes Made

### 1. Database Schema Changes

#### Migration File: `migrations/add_user_location_province_municipality.sql`
- Added `province TEXT` and `municipality TEXT` columns to `user_locations`
- Migrated existing data by splitting `municipality_id` on "-" delimiter
- Added composite indexes for efficient querying:
  - `idx_user_locations_user_province_municipality` on `(user_id, province, municipality)` WHERE deleted_at IS NULL
  - `idx_user_locations_province` on `(province)` WHERE deleted_at IS NULL
  - `idx_user_locations_municipality` on `(municipality)` WHERE deleted_at IS NULL
- Added unique constraint: `user_locations_user_id_province_municipality_key`

#### Base Schema: `create-database-schema.sql`
- Updated `user_locations` table definition to use separate `province` and `municipality` columns
- Added `municipality_id` as a GENERATED column (later changed to trigger-based)
- Created trigger to auto-populate `municipality_id` from `province` and `municipality`

### 2. PowerSync Configuration Changes

#### Sync Config: `mobile/imu_flutter/powersync/sync-config.yaml`

**Fixed Issues:**
1. `user_locations` stream now filters out soft-deleted records (`AND ul.deleted_at IS NULL`)

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

#### `backend/src/routes/caravans.js`
- Updated GET endpoint to use new `province` and `municipality` columns
- Added backward compatibility for legacy `municipality_id` format
- Maps results to include both legacy and new formats

#### `backend/src/routes/users.js`
- Added format auto-detection for new vs legacy columns
- Updated GET/POST endpoints with backward compatibility

#### `backend/src/routes/groups.js`
- Updated caravan assignment logic to use new format when available
- Falls back to legacy format if new columns don't exist

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

#### `mobile/imu_flutter/lib/features/territ/data/models/user_municipalities_simple.dart`
- Renamed class to `UserLocation`
- Added `province` and `municipality` properties
- Added `municipalityId` getter for backward compatibility
- Added factory methods: `fromRow()` (new) and `fromLegacyRow()` (old)
- Added `matchesClient()` method for filtering

#### `mobile/imu_flutter/lib/features/territ/data/repositories/user_municipalities_simple_repository.dart`
- Added methods supporting both new and legacy formats
- Auto-detects format from schema
- `getAssignedLocations()` with format detection
- `createAssignment()` for new format
- Legacy alias methods for backward compatibility

#### `mobile/imu_flutter/lib/features/territ/providers/filter_providers.dart`
- Auto-detects new vs legacy columns
- Constructs location keys appropriately
- Uses different queries based on format

#### `mobile/imu_flutter/lib/features/home/presentation/pages/home_page.dart`
- Updated `_loadAssignedMunicipalities()` to detect and use new format
- Falls back to legacy format if needed

#### `mobile/imu_flutter/lib/services/sync/powersync_service.dart`
- Updated `user_locations` table schema with `province` and `municipality` columns
- Added `approvals` table to schema
- Updated `itineraries` schema with missing columns (`created_by`, `created_at`, `updated_at`)

## Backward Compatibility

All changes maintain backward compatibility with the legacy `municipality_id` format:

1. **Database**: `municipality_id` column is auto-populated via trigger
2. **Backend**: Endpoints detect and support both formats
3. **Frontend**: Mapping includes both formats for compatibility
4. **Mobile**: Auto-detects format and uses appropriate queries

## Database Migration Applied

The following SQL changes were applied directly to the database:

```sql
-- Added unique constraint
ALTER TABLE user_locations ADD CONSTRAINT user_locations_user_id_province_municipality_key
UNIQUE (user_id, province, municipality);

-- Created trigger for auto-populating municipality_id
CREATE OR REPLACE FUNCTION user_locations_update_municipality_id()
RETURNS TRIGGER AS $$
BEGIN
  NEW.municipality_id := NEW.province || '-' || NEW.municipality;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER user_locations_municipality_id_trigger
  BEFORE INSERT OR UPDATE OF province, municipality ON user_locations
  FOR EACH ROW
  EXECUTE FUNCTION user_locations_update_municipality_id();

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
