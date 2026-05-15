# Add / Edit Client Page Redesign

## Overview

The current Add Client and Edit Client pages are a single long scrollable form. Fields are cramped on mobile and the section grouping is not obvious. This redesign replaces the single-screen scroll with a **Wizard + Tabs hybrid** — step pills at the top for free navigation, Back / Next buttons at the bottom for linear flow — giving each logical group of fields its own focused screen.

---

## Design Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Overall layout | Wizard + Tabs hybrid | Guides new entries linearly; lets experienced users jump directly to a step |
| Number of steps | 5 | Separates Location from Contact; keeps each step to ≤5 fields |
| Field style | Outlined Material (Style B) | Consistent with the rest of the app; clear focus states |

---

## Step Structure

### Step 1 · Personal
Fields the form is named after — who the person is.

| Field | Required | Notes |
|---|---|---|
| First Name | ✅ | |
| Last Name | ✅ | Shown side-by-side with First Name |
| Middle Name | — | Optional |
| Birth Date | — | Date picker |
| Client Type | ✅ | Chip selector: Potential / Existing |

### Step 2 · Contact
How to reach the client.

| Field | Required | Notes |
|---|---|---|
| Phone Number | ✅ | |
| Email Address | — | |
| Facebook Profile | — | |

### Step 3 · Location
Cascading PSGC address pickers. Each dropdown unlocks after the parent is selected.

| Field | Required | Notes |
|---|---|---|
| Region | ✅ | Top-level PSGC |
| Province | ✅ | Unlocks after Region |
| Municipality / City | ✅ | Unlocks after Province |
| Barangay | ✅ | Unlocks after Municipality |

### Step 4 · Work
Employment details — all optional.

| Field | Required | Notes |
|---|---|---|
| Agency Name | — | |
| Position | — | Shown side-by-side with Department |
| Department | — | |
| PAN (Pension Account No.) | — | |
| Payroll Date | — | Shown side-by-side with Tenure |
| Tenure (years) | — | |

### Step 5 · Product + Notes
Product classification and free-text remarks. This is the final step — Save button appears here instead of Next.

| Field | Required | Notes |
|---|---|---|
| Product Type | ✅ | Dropdown |
| Pension Type | ✅ | Dropdown |
| Market Type | ✅ | Dropdown |
| Loan Type | ✅ | Dropdown |
| Remarks / Notes | — | Multi-line textarea |

---

## Navigation

- **Step pills row** — sits below the app bar; shows all 5 steps as tappable pills. Completed steps show a ✓ badge; the active step is highlighted in indigo; future steps are grey.
- **Back button** — returns to the previous step. Hidden on Step 1.
- **Next button** — validates the current step's required fields, then advances. Shown on Steps 1–4.
- **Save Client button** — green, replaces Next on Step 5. Triggers full validation and submission.
- Tapping a pill navigates directly to that step. Validation is **not** enforced on pill-tap jumps (allows editing already-saved records freely).

---

## Validation

Per-step validation fires when the user taps **Next** or **Save Client**:
- Required fields show an inline error below the field (red border + error text).
- The step pill does **not** turn to ✓ until all required fields on that step are filled.
- For the cascading PSGC dropdowns, a child picker is disabled (greyed out) until its parent has a value.

---

## Edit Mode

The same 5-step form is used for editing an existing client. Differences:
- App bar title changes to "Edit Client".
- All fields pre-populated from the existing record.
- All step pills start in the ✓ done state (user may jump to any step immediately).
- Save button performs an update instead of insert.

---

## Component Architecture

```
AddEditClientPage (StatefulWidget / ConsumerWidget)
├── StepPillsRow          — pill navigation, receives currentStep + completedSteps
├── Step1PersonalForm     — fields + chip selector for client type
├── Step2ContactForm      — phone, email, facebook
├── Step3LocationForm     — cascading PSGC pickers (Region → Province → Muni → Barangay)
├── Step4WorkForm         — agency, position, dept, PAN, payroll, tenure
├── Step5ProductForm      — product/pension/market/loan dropdowns + remarks textarea
└── StepNavBar            — back/next/save buttons, receives currentStep + onBack + onNext + onSave
```

State is held in a single `AddEditClientFormState` class (or a `StateNotifier`) containing all field values and the `currentStep` index. The page widget passes relevant slices of state down to each form step.

---

## Out of Scope

- Duplicate detection logic (existing behaviour is unchanged)
- Photo / attachment upload
- Offline sync behaviour (unchanged — same PowerSync path as today)
