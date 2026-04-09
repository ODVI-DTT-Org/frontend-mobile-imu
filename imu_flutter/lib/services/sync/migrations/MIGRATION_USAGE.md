# PowerSync Migration Usage Guide

## Files Created

1. **049_add_full_name_column.sql** - Main migration file
2. **049_add_full_name_column_rollback.sql** - Rollback migration file
3. **migration_runner.dart** - Utility to execute migrations

## Setup

### 1. Add SQL files to assets

Update `pubspec.yaml`:

```yaml
flutter:
  assets:
    - lib/services/sync/migrations/049_add_full_name_column.sql
    - lib/services/sync/migrations/049_add_full_name_column_rollback.sql
```

### 2. Run the migration

```dart
import 'package:powersync/powersync.dart';
import 'package:imu_flutter/services/sync/migrations/migration_runner.dart';

// Execute migration
final db = await PowerSyncService.database;
await MigrationRunner.executeMigration(
  db,
  '049_add_full_name_column.sql',
);
```

### 3. Rollback if needed (testing/development)

```dart
await MigrationRunner.rollbackMigration(
  db,
  '049_add_full_name_column_rollback.sql',
);
```

## What This Migration Does

1. **Adds full_name column** to clients table
2. **Creates triggers** to automatically maintain full_name:
   - INSERT trigger: Populates full_name on new records
   - UPDATE trigger: Updates full_name when name fields change
3. **Creates indexes** for fast case-insensitive search:
   - `idx_clients_full_name_lower` using LOWER()
   - `idx_clients_full_name_nocase` using COLLATE NOCASE
4. **Backfills existing records** with computed full_name values

## Full Name Format

```
LastName, FirstName MiddleName
```

Examples:
- "Doe, John"
- "Smith, Jane Marie"
- "Garcia, Carlos"

## Verification

After migration, verify with:

```dart
// Check if column exists
final result = await db.get("PRAGMA table_info(clients)");
final hasFullName = (result as List).any((row) => row['name'] == 'full_name');

// Check if triggers exist
final triggers = await db.getAll('''
  SELECT name FROM sqlite_master
  WHERE type = 'trigger'
  AND name LIKE '%full_name%'
''');

// Check if indexes exist
final indexes = await db.getAll('''
  SELECT name FROM sqlite_master
  WHERE type = 'index'
  AND name LIKE '%full_name%'
''');
```
