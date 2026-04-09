-- PowerSync Migration: Add full_name column to clients table
-- Version: 049
-- Date: 2026-04-09
--
-- This migration adds a computed `full_name` column to the clients table
-- for efficient offline search, matching the backend database schema.
--
-- Changes:
-- - Adds full_name TEXT column to clients table
-- - Creates INSERT trigger to auto-populate full_name
-- - Creates UPDATE trigger to maintain full_name on name changes
-- - Creates optimized indexes for case-insensitive search
-- - Backfills existing records with computed full_name values

-- Step 1: Add full_name column
ALTER TABLE clients ADD COLUMN full_name TEXT;

-- Step 2: Create INSERT trigger for automatic full_name population
CREATE TRIGGER IF NOT EXISTS clients_insert_full_name_trigger
AFTER INSERT ON clients
BEGIN
  UPDATE clients
  SET full_name = last_name || ', ' || first_name ||
              CASE WHEN middle_name IS NOT NULL AND middle_name != ''
                   THEN ' ' || middle_name
                   ELSE ''
              END
  WHERE id = NEW.id;
END;

-- Step 3: Create UPDATE trigger to maintain full_name when names change
CREATE TRIGGER IF NOT EXISTS clients_update_full_name_trigger
AFTER UPDATE OF first_name, last_name, middle_name ON clients
BEGIN
  UPDATE clients
  SET full_name = last_name || ', ' || first_name ||
              CASE WHEN middle_name IS NOT NULL AND middle_name != ''
                   THEN ' ' || middle_name
                   ELSE ''
              END
  WHERE id = NEW.id;
END;

-- Step 4: Create index for case-insensitive search (LOWER function)
CREATE INDEX IF NOT EXISTS idx_clients_full_name_lower
ON clients(LOWER(full_name));

-- Step 5: Create index for natural case-insensitive search
CREATE INDEX IF NOT EXISTS idx_clients_full_name_nocase
ON clients(full_name COLLATE NOCASE);

-- Step 6: Backfill existing records with computed full_name
UPDATE clients
SET full_name = last_name || ', ' || first_name ||
            CASE WHEN middle_name IS NOT NULL AND middle_name != ''
                 THEN ' ' || middle_name
                 ELSE ''
            END
WHERE full_name IS NULL OR full_name = '';
