-- PowerSync Migration Rollback: Remove full_name column from clients table
-- Version: 049
-- Date: 2026-04-09
--
-- This rollback removes the full_name column and its associated triggers and indexes
-- Use this for testing/development purposes only

-- Step 1: Drop indexes
DROP INDEX IF EXISTS idx_clients_full_name_lower;
DROP INDEX IF EXISTS idx_clients_full_name_nocase;

-- Step 2: Drop triggers
DROP TRIGGER IF EXISTS clients_update_full_name_trigger;
DROP TRIGGER IF EXISTS clients_insert_full_name_trigger;

-- Step 3: Drop column
ALTER TABLE clients DROP COLUMN full_name;
