# PowerSync Sync Rules Deployment Instructions

## Summary of Changes

The `sync-config.yaml` file has been updated with the following improvements:

### 1. Fixed `user_locations` Sync Stream
- **Before**: Synced all `user_locations` records including soft-deleted ones
- **After**: Added `AND ul.deleted_at IS NULL` filter to exclude soft-deleted records
- **Impact**: Mobile devices will no longer sync records that were soft-deleted

### 2. Implemented Role-Based Client Filtering
- **Tele Users**: See all clients (no territory restrictions)
- **Caravan Users**: See only clients in their assigned provinces/municipalities
- **Admin/Managers**: See all clients (no restrictions)
- **Impact**: Reduced data transfer and improved privacy by filtering at the sync level

### 3. Added `approvals` Sync Stream
- **New**: Added sync stream for `approvals` table
- **Filter**: Only syncs pending approvals for the current user
- **Impact**: Mobile devices can now sync approval requests

### 4. Updated Sync Rules for Related Tables
- **addresses**: Added role-based filtering via client relationship
- **phone_numbers**: Added role-based filtering via client relationship
- **touchpoints**: Added role-based filtering via client relationship
- **my_touchpoints**: Added for user's own touchpoints
- **itineraries**: Already configured correctly

## Deployment Methods

### Option 1: PowerSync CLI (Recommended)

**Prerequisites:**
- Valid PowerSync Cloud credentials
- PowerSync CLI installed (`powersync/0.9.3`)

**Steps:**

1. **Navigate to the powersync directory:**
   ```bash
   cd C:\odvi-apps\IMU\mobile\imu_flutter\powersync
   ```

2. **Login to PowerSync Cloud:**
   ```bash
   powersync login
   ```
   Follow the prompts to authenticate with your PowerSync Cloud account.

3. **Link to your instance (if not already linked):**
   ```bash
   powersync link cloud --project-id=<your-project-id> --instance-id=<your-instance-id>
   ```
   Your instance ID is: `69cb46b4f69619e9d4830ea1`

4. **Deploy the sync configuration:**
   ```bash
   powersync deploy sync-config
   ```

5. **Verify deployment:**
   ```bash
   powersync fetch status
   ```

### Option 2: PowerSync Dashboard (Web UI)

1. **Access PowerSync Dashboard:**
   - Navigate to: https://app.powersync.journeyapps.com
   - Log in with your credentials

2. **Select your instance:**
   - Instance ID: `69cb46b4f69619e9d4830ea1`
   - Project: IMU Mobile

3. **Open Sync Configuration:**
   - Go to "Sync" or "Sync Rules" section
   - Click "Edit" or "Update"

4. **Copy and paste the new configuration:**
   - Open: `C:\odvi-apps\IMU\mobile\imu_flutter\powersync\sync-config.yaml`
   - Copy the entire contents
   - Paste into the dashboard editor

5. **Validate and Deploy:**
   - Click "Validate" to check for errors
   - Click "Deploy" or "Save" to apply changes

### Option 3: PowerSync API (Advanced)

Use the PowerSync Management API to update the sync configuration:

```bash
curl -X PUT https://app.powersync.journeyapps.com/api/v1/instances/69cb46b4f69619e9d4830ea1/sync-config \
  -H "Authorization: Bearer <your-admin-token>" \
  -H "Content-Type: application/yaml" \
  -d @sync-config.yaml
```

## Post-Deployment Verification

### 1. Check Sync Status
```bash
powersync fetch status
```

Expected output should show:
- Connected status
- Sync streams active
- No errors

### 2. Test Mobile App Sync

After deployment, test with different user roles:

**Caravan User (with assigned territories):**
```sql
-- Should sync only clients in assigned provinces/municipalities
SELECT * FROM user_locations WHERE user_id = '<caravan-user-id>' AND deleted_at IS NULL;
```

**Tele User (no territory restrictions):**
```sql
-- Should sync all clients
SELECT * FROM user_profiles WHERE user_id = '<tele-user-id>' AND role = 'tele';
```

**Admin User:**
```sql
-- Should sync all clients
SELECT * FROM user_profiles WHERE user_id = '<admin-user-id>' AND role = 'admin';
```

### 3. Verify Soft-Delete Filtering

Test that soft-deleted records are not synced:

```sql
-- Soft delete a location assignment
UPDATE user_locations SET deleted_at = NOW() WHERE user_id = '<test-user-id>';

-- Verify it no longer appears in sync
-- (Check mobile app or sync status)
```

### 4. Check Approvals Sync

Test that pending approvals are synced correctly:

```sql
-- Create a test approval
INSERT INTO approvals (type, status, client_id, role, created_at, updated_at)
VALUES ('udi', 'pending', '<client-id>', '<user-id>', NOW(), NOW());

-- Verify it appears in mobile app
```

## Rollback Instructions

If issues occur, you can rollback by:

1. **Restore previous sync-config.yaml** from git:
   ```bash
   git checkout HEAD~1 sync-config.yaml
   ```

2. **Redeploy:**
   ```bash
   powersync deploy sync-config
   ```

Or use the dashboard to revert to a previous configuration version.

## Troubleshooting

### Error: "Linking is required"
- Run `powersync link cloud` with your project and instance IDs
- Or update `cli.yaml` manually with your instance details

### Error: "Authentication failed"
- Run `powersync login` to refresh credentials
- Check that your token is valid and not expired

### Error: "Validation failed"
- Run `powersync validate` to check for syntax errors
- Ensure `sync-config.yaml` follows Edition 3 schema
- Check that all referenced tables exist in the database

### Sync not working on mobile
- Check PowerSync status: `powersync fetch status`
- Verify user has correct role in `user_profiles` table
- Check that `user_locations` has active (non-deleted) records
- Ensure mobile app is using latest PowerSync SDK

## Configuration Files

- **Sync Config**: `C:\odvi-apps\IMU\mobile\imu_flutter\powersync\sync-config.yaml`
- **Service Config**: `C:\odvi-apps\IMU\mobile\imu_flutter\powersync\service.yaml`
- **Client Schema**: `C:\odvi-apps\IMU\mobile\imu_flutter\lib\services\sync\powersync_service.dart`

## Support

For issues or questions:
- PowerSync Documentation: https://docs.powersync.com
- PowerSync Dashboard: https://app.powersync.journeyapps.com
- Check database schema: `create-database-schema.sql`
- Check migration: `migrations/add_user_location_province_municipality.sql`
