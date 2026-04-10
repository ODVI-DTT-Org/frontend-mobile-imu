-- PowerSync Migration Rollback: Remove indexes for client attribute filter columns
-- Version: 050
-- Date: 2026-04-10
--
-- This rollback removes the indexes created in migration 050
-- Use this only for testing/development purposes
--
-- WARNING: Dropping indexes will significantly slow down filter options loading
-- and SELECT DISTINCT queries on filter columns

-- Step 1: Drop index on client_type column
DROP INDEX IF EXISTS idx_clients_client_type;

-- Step 2: Drop index on market_type column
DROP INDEX IF EXISTS idx_clients_market_type;

-- Step 3: Drop index on pension_type column
DROP INDEX IF EXISTS idx_clients_pension_type;

-- Step 4: Drop index on product_type column
DROP INDEX IF EXISTS idx_clients_product_type;

-- Verification queries (for testing):
-- SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE '%client_type%';
-- Expected: No results (indexes dropped)
