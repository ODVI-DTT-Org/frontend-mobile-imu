# Client Detail Page - Redesign Specification

> **Version:** 2.0 (Complete Schema)
> **Date:** 2026-04-17
> **Status:** Draft
> **Author:** AI Agent + User Collaboration

---

## Table of Contents

1. [Overview](#overview)
2. [Design Goals](#design-goals)
3. [Information Architecture](#information-architecture)
4. [Screen Layout](#screen-layout)
5. [Component Specifications](#component-specifications)
6. [Field Reference](#field-reference)
7. [Implementation Notes](#implementation-notes)

---

## Overview

The client detail page displays comprehensive client information organized using progressive disclosure. The design prioritizes quick actions at the top, followed by a hero card with basic information, then expandable sections for detailed information.

**Design Philosophy:**
- **Quick Actions First:** Primary actions always visible at top
- **Hero Card:** Always-visible basic information (name, badges, birthday, created_at)
- **Progressive Disclosure:** Detailed information in expansion panels
- **Mobile-First:** Optimized for mobile screens (393 x 852 px baseline)
- **Accessible:** Large touch targets (48x48px), clear visual hierarchy

---

## Design Goals

| Goal | Description | Priority |
|------|-------------|----------|
| **Quick Access** | Primary actions always accessible | High |
| **Progressive Disclosure** | Show what's needed, hide details until requested | High |
| **Consistent Layout** | Follow established Flutter patterns | Medium |
| **Performance** | Fast loading with PowerSync offline data | High |
| **Accessibility** | Large touch targets, clear labels | High |
| **Complete Data** | Display all client fields from schema | High |

---

## Information Architecture

```
┌─────────────────────────────────────────┐
│ APP BAR (Edit, Delete, Navigate)        │
├─────────────────────────────────────────┤
│ HERO CARD (Always visible)              │
│ • Full name                             │
│ • Badges (client type, product type)    │
│ • Birthday (age calculation)            │
│ • Created date                          │
│ • Touchpoint progress badge              │
├─────────────────────────────────────────┤
│ QUICK ACTIONS (3 buttons only)          │
│ • Visit Only                            │
│ • Touchpoint                            │
│ • Release Loan                          │
├─────────────────────────────────────────┤
│ CLIENT INFORMATION (Expansion Panel)    │
│ ├─ Personal Information                 │
│ ├─ Employment Details                   │
│ ├─ Classification                       │
│ ├─ Location                             │
│ ├─ UDI (Unique Document Identifier)     │
│ ├─ Loan Information                     │
│ ├─ Legacy PCNICMS Information           │
│ └─ System Information                   │
├─────────────────────────────────────────┤
│ CONTACT INFORMATION (Expansion Panel)   │
│ ├─ Phone Numbers                        │
│ ├─ Email                                │
│ ├─ Addresses                            │
│ └─ Social Media                         │
├─────────────────────────────────────────┤
│ CMS VISIT HISTORY (Expansion Panel)     │
│ └─ List of CMS visits (separate from    │
│    touchpoints)                         │
├─────────────────────────────────────────┤
│ TOUCHPOINT HISTORY (Expansion Panel)    │
│ └─ List of 7 touchpoints with status   │
└─────────────────────────────────────────┘
```

---

## Screen Layout

### App Bar
```
┌─────────────────────────────────────────┐
│ [←] Client Details         [✏️] [🗑️] [📍] │
└─────────────────────────────────────────┘
```
- **Back button:** Navigate to previous screen
- **Title:** "Client Details"
- **Action buttons (icon only, no label):**
  - **Edit (✏️):** Open client edit dialog
  - **Delete (🗑️):** Delete client (admin only, with confirmation)
  - **Navigate (📍):** Open client location in map/navigation

### Hero Card (Always Visible)
```
┌─────────────────────────────────────────┐
│  ┌─────┐                                 │
│  │ AVATAR  Juan Dela Cruz                │
│  └─────┘  [Potential] [BFP_ACTIVE]      │
│                                         │
│  🎂 January 15, 1965 (59 years old)     │
│  📅 Created: March 1, 2024              │
│                                         │
│  [3/7 • visit]  ⭐  [📍 Sampaloc, Manila]│
└─────────────────────────────────────────┘
```
**Fields Displayed:**
- Avatar (initials or photo if available)
- Full name: `first_name + middle_name + last_name`
- Badges:
  - Client type: `client_type` (Potential | Existing)
  - Product type: `product_type` (BFP_ACTIVE, BFP_PENSION, etc.)
- Birthday: `birth_date` with age calculation
- Created date: `created_at`
- Touchpoint progress badge: `X/7 • next_type`
- Star indicator: `is_starred` (⭐ if true)
- Location badge: `municipality, province`

### Quick Actions (3 Buttons Only)
```
┌─────────────────────────────────────────┐
│     ┌─────────┐  ┌─────────┐  ┌─────────┐│
│     │  VISIT  │  │TOUCHPOINT│  │ RELEASE  ││
│     │  ONLY   │  │         │  │  LOAN   ││
│     └─────────┘  └─────────┘  └─────────┘│
└─────────────────────────────────────────┘
```
**Buttons:**
1. **Visit Only:** Create a visit-only touchpoint (no loan release)
2. **Touchpoint:** Create regular touchpoint (Visit or Call based on sequence)
3. **Release Loan:** Create release loan touchpoint

**Button Logic:**
- Show/hide based on user role and client state
- Disable if loan already released
- Disable if user cannot create touchpoint for next number

---

## Component Specifications

### CLIENT INFORMATION Expansion Panel

**Purpose:** Display all client demographic and classification information

**Subsections:**

#### 1. Personal Information
```
┌─────────────────────────────────────────┐
│ Personal Information                    │
├─────────────────────────────────────────┤
│ Full Name:        Juan Dela Cruz        │
│ First Name:       Juan                  │
│ Middle Name:      —                     │
│ Last Name:        Dela Cruz             │
│ Extension Name:   —                     │
│ Birth Date:       January 15, 1965      │
│ Age:              59 years old          │
│ Gender:           —                     │
└─────────────────────────────────────────┘
```
**Fields:**
- `fullname` (legacy) or computed from `first_name`, `middle_name`, `last_name`
- `first_name`
- `middle_name`
- `last_name`
- `ext_name` (legacy PCNICMS)
- `birth_date`
- `dob` (legacy PCNICMS, TEXT format)
- Age (computed from birth_date)

#### 2. Employment Details
```
┌─────────────────────────────────────────┐
│ Employment Details                      │
├─────────────────────────────────────────┤
│ Agency Name:      —                     │
│ Department:       —                     │
│ Position:         —                     │
│ Employment Status: —                    │
│ Payroll Date:     —                     │
│ Tenure:           —                     │
│ G Company:        —                     │
│ G Status:         —                     │
└─────────────────────────────────────────┘
```
**Fields:**
- `agency_name`
- `department`
- `position`
- `employment_status`
- `payroll_date`
- `tenure`
- `agency_id` (FK to agencies table)
- `g_company` (legacy PCNICMS)
- `g_status` (legacy PCNICMS)

#### 3. Classification
```
┌─────────────────────────────────────────┐
│ Classification                          │
├─────────────────────────────────────────┤
│ Client Type:      Potential             │
│ Product Type:     BFP_ACTIVE            │
│ Market Type:      —                     │
│ Pension Type:     —                     │
│ PAN:              —                     │
│ Rank:             —                     │
└─────────────────────────────────────────┘
```
**Fields:**
- `client_type` (POTENTIAL | EXISTING)
- `product_type` (BFP_ACTIVE, BFP_PENSION, PNP_PENSION, NAPOLCOM, BFP_STP)
- `market_type`
- `pension_type`
- `pan`
- `rank` (legacy PCNICMS)

#### 4. Location
```
┌─────────────────────────────────────────┐
│ Location                                │
├─────────────────────────────────────────┤
│ Region:          NCR                    │
│ Province:        Metro Manila            │
│ Municipality:    Sampaloc               │
│ Barangay:        —                      │
│ Full Address:    —                      │
│ PSGC ID:         —                      │
└─────────────────────────────────────────┘
```
**Fields:**
- `region`
- `province`
- `municipality`
- `barangay`
- `full_address` (legacy PCNICMS)
- `psgc_id`

#### 5. UDI (Unique Document Identifier)
```
┌─────────────────────────────────────────┐
│ UDI (Unique Document Identifier)        │
├─────────────────────────────────────────┤
│ UDI:             —                      │
│ UDI Number:      —                      │
│ Account Code:    —                      │
│ Account Number:  —                      │
│ Unit Code:       —                      │
│ PCNI Acct Code:  —                      │
└─────────────────────────────────────────┘
```
**Fields:**
- `udi`
- `udi_number` (from approvals table)
- `account_code` (legacy PCNICMS)
- `account_number` (legacy PCNICMS)
- `unit_code` (legacy PCNICMS)
- `pcni_acct_code` (legacy PCNICMS)

#### 6. Loan Information
```
┌─────────────────────────────────────────┐
│ Loan Information                        │
├─────────────────────────────────────────┤
│ Loan Released:    No                    │
│ Loan Released At: —                     │
│ ATM Number:       —                     │
│ Monthly Pension:  —                     │
│ Monthly Gross:    —                     │
└─────────────────────────────────────────┘
```
**Fields:**
- `loan_released`
- `loan_released_at`
- `atm_number` (legacy PCNICMS)
- `monthly_pension_amount` (legacy PCNICMS)
- `monthly_pension_gross` (legacy PCNICMS)

#### 7. Legacy PCNICMS Information
```
┌─────────────────────────────────────────┐
│ Legacy PCNICMS Information              │
├─────────────────────────────────────────┤
│ Applicable RA:    —                     │
│ Status:           Active                │
└─────────────────────────────────────────┘
```
**Fields:**
- `applicable_republic_act` (legacy PCNICMS)
- `status` (legacy PCNICMS, default: 'active')

#### 8. System Information
```
┌─────────────────────────────────────────┐
│ System Information                      │
├─────────────────────────────────────────┤
│ Client ID:       123e4567-e89b...       │
│ Assigned User:   Juan Dela Cruz (Agent) │
│ Is Starred:      Yes                    │
│ Created At:      March 1, 2024          │
│ Updated At:      April 15, 2026         │
│ Deleted At:      —                      │
└─────────────────────────────────────────┘
```
**Fields:**
- `id`
- `user_id` (FK to users, assigned agent)
- `is_starred`
- `created_at`
- `updated_at`
- `deleted_at`

---

### CONTACT INFORMATION Expansion Panel

**Purpose:** Display all client contact information

**Subsections:**

#### 1. Phone Numbers
```
┌─────────────────────────────────────────┐
│ Phone Numbers                           │
├─────────────────────────────────────────┤
│ Primary:   +63 912 345 6789  [📞] [💬] │
│ Secondary: +63 912 345 6790  [📞] [💬] │
│ ┌─────────────────────────────────┐     │
│ │ [+ Add Phone Number]            │     │
│ └─────────────────────────────────┘     │
└─────────────────────────────────────────┘
```
**Fields:**
- From `phone_numbers` table (one-to-many)
- Display type (mobile, home, work), number, label
- Actions: Call, SMS
- Add button (if editable)

#### 2. Email
```
┌─────────────────────────────────────────┐
│ Email                                   │
├─────────────────────────────────────────┤
│ Email:    juan.delacruz@email.com  [✉️] │
│ ┌─────────────────────────────────┐     │
│ │ [+ Add Email]                   │     │
│ └─────────────────────────────────┘     │
└─────────────────────────────────────────┘
```
**Fields:**
- `email` (from clients table)
- Action: Send email
- Add button (if editable)

#### 3. Addresses
```
┌─────────────────────────────────────────┐
│ Addresses                               │
├─────────────────────────────────────────┤
│ Primary: 123 Main St, Sampaloc, Manila  │
│          NCR [📍]                        │
│ ┌─────────────────────────────────┐     │
│ │ [+ Add Address]                 │     │
│ └─────────────────────────────────┘     │
└─────────────────────────────────────────┘
```
**Fields:**
- From `addresses` table (one-to-many)
- Display type, street, barangay, city, province, postal_code
- Action: Navigate (opens map)
- Add button (if editable)

#### 4. Social Media
```
┌─────────────────────────────────────────┐
│ Social Media                            │
├─────────────────────────────────────────┤
│ Facebook: facebook.com/client.name  [🔗]│
│ ┌─────────────────────────────────┐     │
│ │ [+ Add Social Media]             │     │
│ └─────────────────────────────────┘     │
└─────────────────────────────────────────┘
```
**Fields:**
- `facebook_link`
- Action: Open link
- Add button (if editable)

---

### CMS VISIT HISTORY Expansion Panel

**Purpose:** Display historical CMS visits (separate from touchpoints)

```
┌─────────────────────────────────────────┐
│ CMS Visit History                       │
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │ March 15, 2024                     │ │
│ │ Type: Regular Visit                │ │
│ │ Agent: Juan Dela Cruz              │ │
│ │ Remarks: Client interested...      │ │
│ │                                    │ │
│ │ [View Details]                     │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ March 10, 2024                     │ │
│ │ Type: Release Loan                 │ │
│ │ Agent: Maria Santos                │ │
│ │ Remarks: Loan approved...          │ │
│ │                                    │ │
│ │ [View Details]                     │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

**Notes:**
- CMS visits are from the old system (PCNICMS)
- Separate from the 7-step touchpoint system
- Displayed for historical reference only
- Read-only (cannot add new CMS visits)

---

### TOUCHPOINT HISTORY Expansion Panel

**Purpose:** Display the 7-step touchpoint sequence

```
┌─────────────────────────────────────────┐
│ Touchpoint History (7-Step Sequence)    │
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │ TP1: Visit  ✅ Completed           │ │
│ │ March 1, 2024  |  Agent: Juan D.   │ │
│ │ Status: Interested                 │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ TP2: Call  ✅ Completed            │ │
│ │ March 5, 2024  |  Agent: Maria S.  │ │
│ │ Status: Undecided                  │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ TP3: Call  ⏳ Pending              │ │
│ │ Next: March 10, 2024               │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ TP4: Visit  ⏸ Not Started         │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ TP5: Call  ⏸ Not Started          │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ TP6: Call  ⏸ Not Started          │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ TP7: Visit  ⏸ Not Started         │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

**Fields per Touchpoint:**
- Touchpoint number (1-7)
- Type (Visit | Call)
- Status (Completed | Pending | Not Started)
- Date (if completed/scheduled)
- Agent (if completed)
- Touchpoint status (Interested | Undecided | Not Interested | Completed)

---

## Field Reference

### Complete Client Field List

This section provides a complete reference of all client fields from the database schema, organized by category.

#### Personal Information
| Field | Type | Description | Source |
|-------|------|-------------|--------|
| `id` | UUID | Primary key | clients |
| `first_name` | TEXT | First name | clients |
| `middle_name` | TEXT | Middle name | clients |
| `last_name` | TEXT | Last name | clients |
| `fullname` | TEXT | Full name (legacy) | clients (047) |
| `ext_name` | TEXT | Extension name (legacy) | clients (047) |
| `birth_date` | DATE | Birth date | clients |
| `dob` | TEXT | Date of birth text format (legacy) | clients (047) |

#### Employment Details
| Field | Type | Description | Source |
|-------|------|-------------|--------|
| `agency_name` | TEXT | Agency name | clients |
| `agency_id` | UUID | Foreign key to agencies | clients |
| `department` | TEXT | Department | clients |
| `position` | TEXT | Position | clients |
| `employment_status` | TEXT | Employment status | clients |
| `payroll_date` | TEXT | Payroll date | clients |
| `tenure` | INTEGER | Tenure in years | clients |
| `g_company` | TEXT | Company name (legacy) | clients (047) |
| `g_status` | TEXT | Employment status (legacy) | clients (047) |

#### Classification
| Field | Type | Description | Source |
|-------|------|-------------|--------|
| `client_type` | TEXT | POTENTIAL or EXISTING | clients |
| `product_type` | TEXT | BFP_ACTIVE, BFP_PENSION, PNP_PENSION, NAPOLCOM, BFP_STP | clients |
| `market_type` | TEXT | Market type | clients |
| `pension_type` | TEXT | Pension type | clients |
| `pan` | TEXT | PAN identifier | clients |
| `rank` | TEXT | Rank (legacy) | clients (047) |

#### Location
| Field | Type | Description | Source |
|-------|------|-------------|--------|
| `psgc_id` | INTEGER | PSGC code | clients |
| `region` | TEXT | Region name | clients |
| `province` | TEXT | Province name | clients |
| `municipality` | TEXT | Municipality name | clients |
| `barangay` | TEXT | Barangay name | clients |
| `full_address` | TEXT | Full address string (legacy) | clients (047) |

#### Contact Information
| Field | Type | Description | Source |
|-------|------|-------------|--------|
| `email` | TEXT | Email address | clients |
| `phone` | TEXT | Primary phone (deprecated, use phone_numbers) | clients |
| `phone_numbers` | Array | Phone records (one-to-many) | phone_numbers table |
| `addresses` | Array | Address records (one-to-many) | addresses table |
| `facebook_link` | TEXT | Facebook profile URL | clients |

#### UDI (Unique Document Identifier)
| Field | Type | Description | Source |
|-------|------|-------------|--------|
| `udi` | TEXT | Unique Document Identifier | clients |
| `account_code` | TEXT | Account code (legacy) | clients (047) |
| `account_number` | TEXT | Account number (legacy) | clients (047) |
| `unit_code` | TEXT | Unit code (legacy) | clients (047) |
| `pcni_acct_code` | TEXT | PCNI account code (legacy) | clients (047) |

#### Loan Information
| Field | Type | Description | Source |
|-------|------|-------------|--------|
| `loan_released` | BOOLEAN | Loan released flag | clients |
| `loan_released_at` | TIMESTAMP | Loan release date | clients |
| `atm_number` | TEXT | ATM number (legacy) | clients (047) |
| `monthly_pension_amount` | NUMERIC | Monthly pension amount (legacy) | clients (047) |
| `monthly_pension_gross` | NUMERIC | Monthly pension gross (legacy) | clients (047) |

#### Legacy PCNICMS Information
| Field | Type | Description | Source |
|-------|------|-------------|--------|
| `applicable_republic_act` | TEXT | Applicable Republic Act | clients (047) |
| `status` | TEXT | Client status (default: 'active') | clients (047) |

#### Touchpoint Information
| Field | Type | Description | Source |
|-------|------|-------------|--------|
| `touchpoint_summary` | JSONB | Touchpoint summary array | clients |
| `touchpoint_number` | INTEGER | Current touchpoint number (1-7) | clients |
| `next_touchpoint` | VARCHAR(10) | Next touchpoint type (Visit/Call) | clients |
| `touchpoints` | Array | Touchpoint records (one-to-many) | touchpoints table |

#### System Information
| Field | Type | Description | Source |
|-------|------|-------------|--------|
| `user_id` | UUID | Assigned user (foreign key) | clients |
| `is_starred` | BOOLEAN | Starred flag | clients |
| `remarks` | TEXT | General remarks | clients |
| `created_at` | TIMESTAMPTZ | Creation timestamp | clients |
| `updated_at` | TIMESTAMPTZ | Last update timestamp | clients |
| `deleted_at` | TIMESTAMPTZ | Soft delete timestamp | clients |

---

## Implementation Notes

### Data Access Patterns

1. **Primary Client Data:**
   - Load from `clients` table via PowerSync
   - Display in hero card and expansion panels

2. **Related Data:**
   - `phone_numbers`: One-to-many relationship
   - `addresses`: One-to-many relationship
   - `touchpoints`: One-to-many relationship (filtered by client_id)
   - `visits`: Via touchpoints relationship
   - `calls`: Via touchpoints relationship

3. **Computed Fields:**
   - `fullname`: Computed from `first_name + ' ' + middle_name + ' ' + last_name`
   - `age`: Computed from `birth_date`
   - `touchpoint_status`: Fetched from backend `/api/clients/:id` endpoint

### Role-Based Access

**Display logic based on user role:**

| Role | Edit Client | Delete Client | Create Touchpoint | Release Loan |
|------|-------------|---------------|-------------------|--------------|
| Admin | ✅ | ✅ | All types | ✅ |
| Area Manager | ✅ | ✅ | All types | ✅ |
| Assistant Area Manager | ✅ | ❌ | Visit + Call | ✅ |
| Caravan | Own only | ❌ | Visit only (1,4,7) | ✅ |
| Tele | Own only | ❌ | Call only (2,3,5,6) | ❌ |

### State Management

**Required Providers:**
```dart
// Existing
final clientProvider = FutureProvider.autoDispose<Client>((ref) async { ... });
final touchpointsProvider = FutureProvider.autoDispose<List<Touchpoint>>((ref) async { ... });

// New
final clientTouchpointStatusProvider = FutureProvider.autoDispose<ClientTouchpointStatus>((ref) async { ... });
final phoneNumbersProvider = FutureProvider.autoDispose<List<PhoneNumber>>((ref) async { ... });
final addressesProvider = FutureProvider.autoDispose<List<Address>>((ref) async { ... });
```

### Navigation

**App Bar Actions:**
- **Edit:** Navigate to `ClientEditPage(clientId)`
- **Delete:** Show confirmation dialog, then delete and navigate back
- **Navigate:** Open map with client location

**Quick Actions:**
- **Visit Only:** Navigate to `TouchpointFormPage(clientId, type: Visit, releaseLoan: false)`
- **Touchpoint:** Navigate to `TouchpointFormPage(clientId, type: nextTouchpointType)`
- **Release Loan:** Show Release Loan dialog

---

## Next Steps

1. **Review with stakeholder:** Get feedback on field organization
2. **Create Flutter widgets:** Build expansion panel components
3. **Update data models:** Ensure all fields are included in Client model
4. **Implement role-based display logic:** Show/hide based on user role
5. **Test with real data:** Verify all fields display correctly
6. **Performance optimization:** Ensure fast loading with PowerSync

---

**Document Version:** 2.0 (Complete Schema)
**Last Updated:** 2026-04-17
**Related Documents:**
- COMPLETE_SCHEMA.sql (backend/migrations/)
- client_model.dart (mobile/imu_flutter/lib/features/clients/data/models/)
- client_detail_page.dart (mobile/imu_flutter/lib/features/clients/presentation/pages/)
