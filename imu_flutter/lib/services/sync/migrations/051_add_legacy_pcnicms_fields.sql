-- PowerSync Migration: Add Legacy PCNICMS Fields to Clients Table
-- Version: 051
-- Date: 2026-04-13
--
-- This migration adds 17 legacy PCNICMS fields to the clients table
-- to preserve data during the PCNICMS to IMU migration.
--
-- Changes:
-- - Adds 17 legacy PCNICMS columns to clients table
-- - All fields are optional (nullable) to preserve backward compatibility
-- - No triggers needed - these are static legacy fields
--
-- Legacy Fields Added:
-- - ext_name: Extension name (Jr., Sr., III)
-- - fullname: Full name in format: LASTNAME, FIRSTNAME MIDDLENAME
-- - full_address: Complete address string
-- - account_code: Account code
-- - account_number: Legacy PCNI account number (indexed)
-- - rank: Rank/Title
-- - monthly_pension_amount: Monthly pension amount (numeric)
-- - monthly_pension_gross: Monthly pension gross amount (numeric)
-- - atm_number: ATM number
-- - applicable_republic_act: Applicable Republic Act
-- - unit_code: Unit code
-- - pcni_acct_code: PCNI account code
-- - dob: Date of birth as TEXT (preserving legacy format)
-- - g_company: Company/Group
-- - g_status: Status
-- - status: Record status (default: 'active')

-- Step 1: Add all 17 legacy fields to clients table
ALTER TABLE clients ADD COLUMN ext_name TEXT;
ALTER TABLE clients ADD COLUMN fullname TEXT;
ALTER TABLE clients ADD COLUMN full_address TEXT;
ALTER TABLE clients ADD COLUMN account_code TEXT;
ALTER TABLE clients ADD COLUMN account_number TEXT;
ALTER TABLE clients ADD COLUMN rank TEXT;
ALTER TABLE clients ADD COLUMN monthly_pension_amount REAL;
ALTER TABLE clients ADD COLUMN monthly_pension_gross REAL;
ALTER TABLE clients ADD COLUMN atm_number TEXT;
ALTER TABLE clients ADD COLUMN applicable_republic_act TEXT;
ALTER TABLE clients ADD COLUMN unit_code TEXT;
ALTER TABLE clients ADD COLUMN pcni_acct_code TEXT;
ALTER TABLE clients ADD COLUMN dob TEXT;
ALTER TABLE clients ADD COLUMN g_company TEXT;
ALTER TABLE clients ADD COLUMN g_status TEXT;
ALTER TABLE clients ADD COLUMN status TEXT DEFAULT 'active';

-- Step 2: Create index for account_number lookups (matches backend)
CREATE INDEX IF NOT EXISTS idx_clients_account_number
ON clients(account_number);

-- Step 3: Add comments for documentation (SQLite doesn't support COMMENT ON,
-- so we use a documentation table approach)
-- Note: PowerSync SQLite doesn't support COMMENT ON COLUMN like PostgreSQL
-- Field documentation is maintained in the migration file header above
