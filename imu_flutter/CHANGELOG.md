# Changelog

All notable changes to the IMU Mobile App will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.2] - 2026-03-26

### Fixed - Authentication & PowerSync 🔐
- **JWT Token Singleton Pattern** - Fixed critical authentication issue where JWT tokens weren't being shared across services. Converted `JwtAuthService` to a singleton pattern to ensure all services use the same token state. This fixes "No access token" errors and allows API calls to work properly.
- **PowerSync Logout Loop Fixed** - Fixed infinite logout loop caused by PowerSync authorization errors. Modified `invalidateCredentials()` to NOT automatically logout the user - PowerSync auth failures no longer affect user session.
- **PowerSync Credentials Fetching** - Improved token retrieval with better error handling and logging. PowerSync connector now properly handles token refresh and validates credentials before attempting sync.
- **PowerSync Connected Status** - Fixed `isConnected` getter to properly check database connection state, preventing false "not connected" status.
- **Background Sync Authentication Check** - Enhanced background sync to respect authentication state - stops attempting sync when user is not logged in, reducing error spam.

### Documentation
- Added `docs/powersync-jwt-setup-guide.md` - Complete guide for fixing JWT signing key mismatch between backend and PowerSync.

### Fixed - Previous Issues (from 1.3.1)
- **JWT Token Singleton Pattern** - Fixed critical authentication issue where JWT tokens weren't being shared across services. Converted `JwtAuthService` to a singleton pattern to ensure all services use the same token state. This fixes "No access token" errors and allows API calls to work properly.
- **PowerSync Authorization Loop** - Fixed infinite logout loop caused by PowerSync authorization errors. Login now succeeds even if PowerSync fails to sync - users can use the app without sync functionality.
- **PowerSync Credentials Fetching** - Improved token retrieval with better error handling and logging. PowerSync connector now properly handles token refresh and validates credentials before attempting sync.
- **PowerSync Connected Status** - Fixed `isConnected` getter to properly check database connection state, preventing false "not connected" status.
- **Background Sync Authentication Check** - Enhanced background sync to respect authentication state - stops attempting sync when user is not logged in, reducing error spam.
- **PowerSync Schema Error** - Fixed "touchpoint_reasons: id column is automatically added, custom id columns are not supported" error. Removed explicit `id` column definition from `touchpoint_reasons` table schema since PowerSync auto-adds `id` columns to all tables.
- **PowerSync Multiple Instances Error** - Fixed "Multiple instances for the same database have been detected" warning. Updated PowerSyncService to properly manage connector lifecycle, prevent simultaneous connection attempts, and disconnect old connectors before connecting new ones. This ensures only ONE PowerSync connection per device.
- **Login Page Disabled Bug** - Fixed login page being unclickable due to global loading overlay blocking interaction during background initialization. Removed `LoadingHelper.withLoading` from `_initializeBackgroundSync()` and `_initializeQuickActions()` in app.dart - these now run silently without blocking the UI.
- **PowerSync Client Parsing Bug** - Fixed incorrect client data parsing from PowerSync. Changed `Client.fromJson()` to `Client.fromRow()` to properly handle snake_case column names from PostgreSQL. This fixes incorrect `createdAt` dates and other field mappings.

## [1.3.0] - 2026-03-26

### Added - Global Loading States System 🎯
- **54 Loading States** - Comprehensive loading feedback for ALL async operations across the entire app
- **Splash Screen** - Beautiful animated splash screen with progressive status messages during app initialization
- **LoadingHelper Utility** - Enhanced utility with 8 methods for managing loading states (show, hide, updateMessage, withLoading, withLoadingBatch, withLoadingProgress, withLoadingTimeout)
- **Global Loading Overlay** - Full-screen overlay that blocks interaction during operations (AbsorbPointer)
- **Debug Logging** - Added debug logging for GPS, location, and sync operations

### Added - Loading States by Category
- **Authentication** (2): Login, PIN entry
- **Client Management** (6): Add, edit, delete, assign, load, map
- **Touchpoints/My Day** (5): Submit, remove, refresh, GPS capture
- **Profile & Settings** (5): Update profile, change PIN, change password, clear cache
- **Sync & Upload** (6): Manual sync, photo/audio upload with context-aware messages
- **Agencies & Groups** (9): CRUD operations, member management
- **Itineraries** (7): Load, add, edit, delete, mark completed/in-progress
- **Maps & Attendance** (4): Map loading, check in/out
- **App Startup** (6): Progressive initialization messages
- **GPS & PowerSync** (4): Location capture, initial sync, map init

### Fixed
- **Hardcoded User ID** - Replaced hardcoded user ID with actual auth provider integration (security fix)
- **Touchpoint Form Validation UX** - Form no longer closes on validation error, shows inline error instead
- **GPS Capture UX** - Replaced local loading indicators with global loading overlay
- **Provider Loading States** - Added isLoading property to TodayAttendanceNotifier and UserProfileNotifier
- **Service Initialization** - Added loading states for quick actions and background sync initialization

### Changed
- **Loading Experience** - ALL async operations now show clear, descriptive loading messages
- **App Startup** - Users see progressive loading messages instead of blank screen
- **Error Handling** - Consistent error handling with haptic feedback and user-friendly messages
- **Touchpoint Upload** - Context-aware messages based on what files are being uploaded

### Technical Details
- **LoadingHelper Methods**: 8 utility methods for managing loading states
- **Files Modified**: 29 files with LoadingHelper integration
- **Files Created**: 1 (splash_screen.dart)
- **Coverage**: 100% of all user-facing async operations

### Documentation
- Added `docs/loading-states-complete-summary.md` - Complete implementation guide with all 54 loading states
- Added `docs/loading-states-phase-2-summary.md` - Phase 2 implementation details
- Added `docs/loading-states-phase-3-summary.md` - Phase 3 implementation details
- Added `docs/loading-states-implementation.md` - Original implementation guide
- Added `docs/global-loading-states-implementation.md` - Global loading system guide

## [1.2.0] - 2026-03-25

### Added - PowerSync Integration 🚀
- **PowerSync Cloud** - Integrated PowerSync for offline-first data synchronization
- **Sync Rules** - Configured sync streams for global data, user profiles, municipalities, and all clients
- **Client View Modes** - Added "My Clients" vs "All Clients" toggle in clients list
- **PowerSync Debug Dashboard** - Enhanced debug dashboard with PowerSync connection status and table counts
- **Network Configuration** - Updated backend API URL to use dynamic IP configuration (192.168.131.70)

### Fixed
- **PowerSync Schema Conflict** - Removed custom `id` column from `psgc` table definition (PowerSync auto-adds `id`)
- **Login Redirect Loop** - Fixed router to redirect to `/home` after successful password login instead of `/pin-entry`
- **PSGC Table Structure** - Updated sync rules to use single `psgc` table instead of separate region/province/municipality/barangay tables
- **User Profile Columns** - Fixed sync rules to only include existing columns in `user_profiles` table

### Changed
- **Data Source** - Migrated from mock data to PowerSync + PostgreSQL as primary data source
- **Sync Configuration** - Configured SSL verification with DigitalOcean PostgreSQL CA certificate
- **Region Setting** - Updated PowerSync instance region to `jp` (Japan)

### Technical Details
- **PowerSync Instance**: `69ba260fe44c66e817793c98` (Development)
- **Database**: DigitalOcean PostgreSQL (imu_db)
- **Sync Streams**:
  - `global` - Touchpoint reasons, PSGC locations
  - `user_profile` - Current user's profile
  - `user_municipalities` - User's assigned territories
  - `all_clients` - ALL clients, touchpoints, addresses, phone numbers

### Configuration Files
- `.env.dev` - Updated `POSTGRES_API_URL` to use correct network IP
- `powersync/service.yaml` - Database connection and JWT auth configuration
- `powersync/sync-config.yaml` - Sync rules for data synchronization
- `powersync/.env` - JWT secret for client authentication

### Documentation
- Added `docs/powersync-setup-guide.md` - Complete PowerSync setup instructions
- Added `.gitignore` entries for PowerSync sensitive files (service.yaml, .env, ca.crt, cli.yaml)

## [1.1.0] - Previous Release

### Features
- Client management with CRUD operations
- Touchpoint tracking with 7-step sequence pattern
- Attendance tracking
- Itinerary management
- Location-based filtering (municipalities)
- Map integration with Mapbox
- Debug dashboard
- PIN-based authentication
- Biometric authentication support

### Known Issues
- Using mock data instead of live database
- No offline synchronization
- Network configuration hardcoded

---

## Version Numbering

- **Major.Minor.Patch** (e.g., 1.2.0)
- **Build Number** (e.g., +2) - Increments with each release

### Release Types
- **Major** (X.0.0) - Breaking changes, major features
- **Minor** (1.X.0) - New features, enhancements
- **Patch** (1.1.X) - Bug fixes, small improvements
