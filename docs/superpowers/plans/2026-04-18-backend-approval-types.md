# Backend Approval Types Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire up approval flows for delete client, add address, and add phone number on the backend; fix the schema type constraint; and align Flutter enum values with backend strings.

**Architecture:** Three changes in lockstep — (1) a migration that widens the `approvals.type` CHECK constraint, (2) backend route + approve-handler changes, (3) Flutter enum value fix. The backend already handles `address_add` and `phone_add` creation and execution; only `client_delete` is missing.

**Tech Stack:** Node.js + Hono + TypeScript (backend), PostgreSQL migrations, Dart/Flutter (mobile)

---

### Task 1: Migration — widen approvals.type constraint

**Files:**
- Create: `backend-imu/migrations/049_add_approval_types.sql`

The current CHECK constraint is `type IN ('client', 'udi')`. The code already uses `'address_add'`, `'phone_add'`, and `'loan_release_v2'` — these silently fail at the DB level. We're also adding `'client_delete'`.

- [ ] **Step 1: Create the migration file**

```sql
-- Migration 049: Widen approvals.type CHECK constraint
-- Description: Add address_add, phone_add, loan_release_v2, client_delete approval types
-- Date: 2026-04-18

-- Drop the existing constraint and replace with one that covers all used types
ALTER TABLE approvals
  DROP CONSTRAINT IF EXISTS approvals_type_check;

ALTER TABLE approvals
  ADD CONSTRAINT approvals_type_check
  CHECK (type IN ('client', 'udi', 'address_add', 'phone_add', 'loan_release_v2', 'client_delete'));
```

- [ ] **Step 2: Verify the file exists**

Run: `ls backend-imu/migrations/049_add_approval_types.sql`
Expected: file listed

---

### Task 2: Backend route — add client_delete approval path to DELETE /clients/:id

**Files:**
- Modify: `backend-imu/src/routes/clients.ts` lines 1235–1259

Currently the delete route throws `AuthorizationError` for non-admin users. Replace with: tele/caravan → create `client_delete` approval and return `{ requires_approval: true }`, admin → existing soft-delete.

- [ ] **Step 1: Replace the delete handler body**

Find and replace in `backend-imu/src/routes/clients.ts`:

Old block (lines 1235–1259):
```typescript
// DELETE /api/clients/:id - Delete client (soft delete, admin only)
clients.delete('/:id', authMiddleware, requirePermission('clients', 'delete'), auditMiddleware('client'), async (c) => {
  try {
    const user = c.get('user');
    const id = c.req.param('id');

    // Soft delete: Only admin users can delete clients
    if (user.role !== 'admin') {
      throw new AuthorizationError('Only administrators can delete clients');
    }

    // Check if client exists and is not already deleted
    const existingResult = await pool.query('SELECT * FROM clients WHERE id = $1 AND deleted_at IS NULL', [id]);
    if (existingResult.rows.length === 0) {
      throw new NotFoundError('Client');
    }

    // Soft delete: Set deleted_at timestamp and deleted_by user instead of deleting the record
    await pool.query('UPDATE clients SET deleted_at = NOW(), deleted_by = $1 WHERE id = $2', [user.sub, id]);
    return c.json({ message: 'Client deleted successfully' });
  } catch (error) {
    console.error('Delete client error:', error);
    throw new Error();
  }
});
```

New block:
```typescript
// DELETE /api/clients/:id - Delete client (soft delete; approval required for tele/caravan)
clients.delete('/:id', authMiddleware, requirePermission('clients', 'delete'), auditMiddleware('client'), async (c) => {
  const dbClient = await pool.connect();
  try {
    await dbClient.query('BEGIN');

    const user = c.get('user');
    const id = c.req.param('id');

    // Check if client exists and is not already deleted
    const existingResult = await dbClient.query('SELECT * FROM clients WHERE id = $1 AND deleted_at IS NULL', [id]);
    if (existingResult.rows.length === 0) {
      await dbClient.query('ROLLBACK');
      throw new NotFoundError('Client');
    }

    // Tele/Caravan: submit for approval instead of deleting directly
    if (user.role === 'tele' || user.role === 'caravan') {
      const approvalResult = await dbClient.query(
        `INSERT INTO approvals (id, type, client_id, user_id, role, reason, notes, status)
         VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6, 'pending')
         RETURNING *`,
        ['client_delete', id, user.sub, user.role, 'Delete Client Request', null]
      );

      await dbClient.query('COMMIT');

      return c.json({
        message: 'Client deletion submitted for approval',
        approval: mapRowToApproval(approvalResult.rows[0]),
        requires_approval: true
      });
    }

    // Admin: soft delete immediately
    await dbClient.query('UPDATE clients SET deleted_at = NOW(), deleted_by = $1 WHERE id = $2', [user.sub, id]);
    await dbClient.query('COMMIT');
    return c.json({ message: 'Client deleted successfully' });
  } catch (error) {
    await dbClient.query('ROLLBACK');
    console.error('Delete client error:', error);
    throw error;
  } finally {
    dbClient.release();
  }
});
```

- [ ] **Step 2: Verify the file compiles**

Run: `cd backend-imu && npx tsc --noEmit 2>&1 | head -20`
Expected: no errors (or only pre-existing unrelated errors)

---

### Task 3: Backend approve handler — add client_delete execution

**Files:**
- Modify: `backend-imu/src/routes/approvals.ts` — insert a new block after line 561 (after the `phone_add` block, before the client-edit block)

When an admin approves a `client_delete` approval, soft-delete the client.

- [ ] **Step 1: Add the client_delete execution block**

In `backend-imu/src/routes/approvals.ts`, after the `phone_add` block (after line 561) and before the comment `// For client edit approvals`:

```typescript
    // For client_delete approvals, soft-delete the client
    if (approval.type === 'client_delete') {
      try {
        await client.query(
          'UPDATE clients SET deleted_at = NOW(), deleted_by = $1 WHERE id = $2 AND deleted_at IS NULL',
          [approval.user_id, approval.client_id]
        );
        console.log(`Soft-deleted client ${approval.client_id} from approval`);
      } catch (deleteError) {
        console.error('Failed to soft-delete client from approval:', deleteError);
        await client.query('ROLLBACK');
        throw new Error('Failed to delete client from approval');
      }
    }
```

- [ ] **Step 2: Verify the file compiles**

Run: `cd backend-imu && npx tsc --noEmit 2>&1 | head -20`
Expected: no errors

---

### Task 4: Flutter — fix ApprovalType enum values to match backend

**Files:**
- Modify: `imu_flutter/lib/features/approvals/data/models/approval_model.dart`

The Flutter enum uses `'client_address'` and `'client_phone'` but the backend uses `'address_add'` and `'phone_add'`. Fix the string values to match.

- [ ] **Step 1: Update the enum string values**

In `imu_flutter/lib/features/approvals/data/models/approval_model.dart`, change:

```dart
enum ApprovalType {
  client('client'),
  clientDelete('client_delete'),
  clientAddress('client_address'),
  clientPhone('client_phone'),
  udi('udi');
```

To:

```dart
enum ApprovalType {
  client('client'),
  clientDelete('client_delete'),
  clientAddress('address_add'),
  clientPhone('phone_add'),
  udi('udi');
```

- [ ] **Step 2: Commit both backend and Flutter changes**

```bash
cd /home/claude-team/loi/imu3
git add backend-imu/migrations/049_add_approval_types.sql
git add backend-imu/src/routes/clients.ts
git add backend-imu/src/routes/approvals.ts
git add frontend-mobile-imu/imu_flutter/lib/features/approvals/data/models/approval_model.dart
git commit -m "feat: add client_delete approval flow and fix approval type constraint"
```
