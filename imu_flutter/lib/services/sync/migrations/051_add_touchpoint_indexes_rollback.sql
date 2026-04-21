-- PowerSync Migration Rollback: Remove touchpoint indexes
-- Version: 051 Rollback
-- Date: 2025-04-21
--
-- This migration removes the indexes added in migration 051

-- Rollback: Drop touchpoint indexes
DROP INDEX IF EXISTS idx_touchpoints_client_created;
DROP INDEX IF EXISTS idx_touchpoints_created_at;
DROP INDEX IF EXISTS idx_touchpoints_client_id;
