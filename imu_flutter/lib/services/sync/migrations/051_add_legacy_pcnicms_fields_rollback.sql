-- PowerSync Migration Rollback: Remove Legacy PCNICMS Fields from Clients Table
-- Version: 051 Rollback
-- Date: 2026-04-13
--
-- This migration removes the 17 legacy PCNICMS fields from the clients table.
-- WARNING: This will permanently delete any legacy data stored in these columns.
--
-- Use this rollback ONLY if:
-- 1. The PCNICMS migration has been cancelled
-- 2. You need to revert to the previous schema
-- 3. All legacy data has been successfully migrated to new fields

-- Step 1: Drop the account_number index
DROP INDEX IF EXISTS idx_clients_account_number;

-- Step 2: Remove all 17 legacy fields from clients table
-- SQLite doesn't support multiple ALTER TABLE in one statement,
-- so we need to drop each column individually
ALTER TABLE clients DROP COLUMN IF EXISTS ext_name;
ALTER TABLE clients DROP COLUMN IF EXISTS fullname;
ALTER TABLE clients DROP COLUMN IF EXISTS full_address;
ALTER TABLE clients DROP COLUMN IF EXISTS account_code;
ALTER TABLE clients DROP COLUMN IF EXISTS account_number;
ALTER TABLE clients DROP COLUMN IF EXISTS rank;
ALTER TABLE clients DROP COLUMN IF EXISTS monthly_pension_amount;
ALTER TABLE clients DROP COLUMN IF EXISTS monthly_pension_gross;
ALTER TABLE clients DROP COLUMN IF EXISTS atm_number;
ALTER TABLE clients DROP COLUMN IF EXISTS applicable_republic_act;
ALTER TABLE clients DROP COLUMN IF EXISTS unit_code;
ALTER TABLE clients DROP COLUMN IF EXISTS pcni_acct_code;
ALTER TABLE clients DROP COLUMN IF EXISTS dob;
ALTER TABLE clients DROP COLUMN IF EXISTS g_company;
ALTER TABLE clients DROP COLUMN IF EXISTS g_status;
ALTER TABLE clients DROP COLUMN IF EXISTS status;
