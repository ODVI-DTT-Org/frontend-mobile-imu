# Figma Alignment Plan - Vertical Slices

> **Goal**: Align Flutter IMU app with Figma wireframe design
> **Reference**: Figma file `gfjGqsbXPHA01RAUsR105x` and extracted wireframes in `IMU_Wireframe_Extracted/`
> **Methodology**: Elephant Carpaccio - each slice is 2-4 hours, demonstrable, and complete

---

## Phase 1: Navigation Structure (Priority: Critical)

### Slice 1.1: Update Bottom Navigation to 3 Tabs
**Time**: 1 hour
**Current**: 5 tabs (Home, Agencies, My Day, Itinerary, Call)
**Target**: 3 tabs (Home, My Day, Itinerary)

**Changes**:
- Remove Agencies tab
- Remove Call Log tab
- Update `main_shell.dart` to show only 3 tabs
- Update routing to remove Agencies and Call Log routes

**Files**:
- `lib/shared/widgets/main_shell.dart`
- `lib/core/router/app_router.dart`

**Validation**: App shows only 3 bottom nav items

---

### Slice 1.2: Move Extra Features to Home Grid
**Time**: 30 min
**Current**: Agencies and Call Log as separate tabs
**Target**: These features don't exist in Figma

**Changes**:
- Keep Agencies page accessible via route but not in bottom nav
- Keep Call Log page accessible via route but not in bottom nav
- Or remove entirely if not needed

**Files**:
- `lib/shared/widgets/main_shell.dart`
- `lib/core/router/app_router.dart`

**Validation**: Bottom nav has exactly 3 items matching Figma

---

## Phase 2: Home Page Alignment (Priority: High)

### Slice 2.1: Update Home Grid to 2 Columns
**Time**: 30 min
**Current**: 3 columns
**Target**: 2 columns with gap-8

**Changes**:
- Change `crossAxisCount` from 3 to 2
- Update spacing to match Figma (gap-8 = 32px)

**Files**:
- `lib/features/home/presentation/pages/home_page.dart`

**Validation**: Grid shows 2 columns per row

---

### Slice 2.2: Update Home Menu Items
**Time**: 30 min
**Current**: 7+ items (My Clients, My Targets, Missed Visits, Loan Calculator, Attendance, My Profile, Settings, Debug)
**Target**: 6 items (My Clients, My Targets, Missed Visits, Loan Calculator, Attendance, My Profile)

**Changes**:
- Remove Settings from home grid
- Remove Debug from home grid
- Keep only 6 Figma items

**Files**:
- `lib/features/home/presentation/pages/home_page.dart`

**Validation**: Grid shows exactly 6 items in 3 rows of 2

---

### Slice 2.3: Update Icon Sizes
**Time**: 15 min
**Current**: 24px icons
**Target**: 32px icons (w-8 h-8 in Figma)

**Changes**:
- Update icon size from 24 to 32
- Update icon container size from 40 to 48

**Files**:
- `lib/features/home/presentation/pages/home_page.dart`

**Validation**: Icons are 32px as per Figma

---

### Slice 2.4: Update Greeting Format
**Time**: 15 min
**Current**: "Good Morning/Afternoon/Evening, Name!"
**Target**: "Good Day, JC!" (simpler, time-agnostic)

**Changes**:
- Simplify greeting to "Good Day, {firstName}!"
- Or keep time-based but match Figma styling

**Files**:
- `lib/features/home/presentation/pages/home_page.dart`

**Validation**: Greeting matches Figma format

---

### Slice 2.5: Remove Sync Status Banner
**Time**: 15 min
**Current**: Sync banner at top
**Target**: Not in Figma design

**Changes**:
- Remove or hide sync status banner from home page
- Move to settings or keep as subtle indicator elsewhere

**Files**:
- `lib/features/home/presentation/pages/home_page.dart`

**Validation**: Home page has no sync banner

---

## Phase 3: Clients Page Alignment (Priority: High)

### Slice 3.1: Update Clients Header
**Time**: 30 min
**Current**: Title + count + Filter button
**Target**: Back button + "Home" text + "My Clients" title centered

**Changes**:
- Add back button with "Home" text
- Center "My Clients" title
- Remove client count from header
- Move filter button to search row

**Files**:
- `lib/features/clients/presentation/pages/clients_page.dart`

**Validation**: Header matches Figma layout

---

### Slice 3.2: Update Clients Tabs to 2 Tabs
**Time**: 30 min
**Current**: 3 tabs (ALL, POTENTIAL, EXISTING)
**Target**: 2 tabs (POTENTIAL, EXISTING)

**Changes**:
- Remove ALL tab
- Keep only POTENTIAL and EXISTING tabs
- Update tab styling to match Figma

**Files**:
- `lib/features/clients/presentation/pages/clients_page.dart`

**Validation**: Only 2 tabs visible

---

### Slice 3.3: Simplify Client Card Layout
**Time**: 1 hour
**Current**: Avatar + Name + Badge + Location + Phone + Progress bar
**Target**: Name + Touchpoint badge + Product type + Date

**Changes**:
- Remove avatar
- Remove location and phone display
- Remove progress bar
- Add touchpoint badge (e.g., "1st Visit • INTERESTED")
- Add product type below name
- Add date of latest touchpoint

**Files**:
- `lib/features/clients/presentation/pages/clients_page.dart`

**Validation**: Client cards match Figma layout

---

### Slice 3.4: Add Star/Interested Filter Button
**Time**: 30 min
**Current**: Not present
**Target**: Star button to filter "Interested" clients

**Changes**:
- Add star button next to filter button
- Toggle to show only "INTERESTED" clients when active
- Yellow highlight when active

**Files**:
- `lib/features/clients/presentation/pages/clients_page.dart`

**Validation**: Star filter works

---

### Slice 3.5: Update Filter Dialog
**Time**: 1 hour
**Current**: Sort options only
**Target**: Market Type, Product Type, Pension Type, Reason filters

**Changes**:
- Replace sort options with checkbox filters
- Add Market Type filter
- Add Product Type filter
- Add Pension Type filter
- Add Reason filter
- Add "Clear Filters" button

**Files**:
- `lib/features/clients/presentation/pages/clients_page.dart`

**Validation**: Filter dialog has all options

---

### Slice 3.6: Move Add Button to Header
**Time**: 15 min
**Current**: FAB at bottom
**Target**: Plus button in header row

**Changes**:
- Remove FAB
- Add Plus button in search/header row

**Files**:
- `lib/features/clients/presentation/pages/clients_page.dart`

**Validation**: Add button in header, no FAB

---

## Phase 4: Itinerary Page Alignment (Priority: High)

### Slice 4.1: Update Itinerary Header
**Time**: 15 min
**Current**: "My Itinerary" + Month selector
**Target**: "Itinerary" (centered)

**Changes**:
- Change title to "Itinerary"
- Center the title
- Remove month selector or move to calendar button

**Files**:
- `lib/features/itinerary/presentation/pages/itinerary_page.dart`

**Validation**: Header shows "Itinerary" centered

---

### Slice 4.2: Replace Date Picker with Tab Filter
**Time**: 1 hour
**Current**: Horizontal scrollable date picker
**Target**: Tomorrow / Today / Yesterday pill tabs

**Changes**:
- Remove horizontal date scroll
- Add pill-style tabs: Tomorrow, Today, Yesterday
- Add calendar button on right side
- Style tabs in gray container with rounded corners

**Files**:
- `lib/features/itinerary/presentation/pages/itinerary_page.dart`

**Validation**: Tab filter matches Figma

---

### Slice 4.3: Remove Add New Visit Button
**Time**: 15 min
**Current**: "Add new visit" button
**Target**: Not in Figma design

**Changes**:
- Remove "Add new visit" button from header area

**Files**:
- `lib/features/itinerary/presentation/pages/itinerary_page.dart`

**Validation**: No add button visible

---

### Slice 4.4: Enhance Visit Card Details
**Time**: 1.5 hours
**Current**: Touchpoint + Name + Address
**Target**: Full details with badges

**Changes**:
- Add date + status badge header
- Add Product Type with blue dot
- Add Pension Type with green dot
- Add Reason badge (color-coded)
- Add time with clock icon
- Add remarks in italics

**Files**:
- `lib/features/itinerary/presentation/pages/itinerary_page.dart`

**Validation**: Visit cards have all Figma details

---

## Phase 5: My Day Page Alignment (Priority: Medium)

### Slice 5.1: Verify My Day Implementation
**Time**: 30 min
**Current**: Full implementation with mock tasks
**Target**: Figma shows "Coming soon..." placeholder

**Decision**: Keep current implementation as it's more functional
- The Figma "Coming soon..." is likely a placeholder
- Current implementation adds value

**Validation**: My Day page works correctly

---

## Phase 6: Extra Features Decision (Priority: Low)

### Slice 6.1: Decide on Agencies Page
**Time**: 15 min (decision only)
**Current**: Implemented but not in Figma
**Options**:
1. Remove entirely
2. Keep accessible via route but not in navigation
3. Keep as is (extra feature)

**Recommendation**: Keep as extra feature, accessible from somewhere

---

### Slice 6.2: Decide on Call Log Page
**Time**: 15 min (decision only)
**Current**: Implemented but not in Figma
**Options**:
1. Remove entirely
2. Keep accessible via route but not in navigation
3. Keep as is (extra feature)

**Recommendation**: Keep as extra feature

---

### Slice 6.3: Decide on Settings Page
**Time**: 15 min (decision only)
**Current**: Implemented but not in Figma
**Options**:
1. Remove from Home grid, keep accessible via profile
2. Remove entirely
3. Keep as is (extra feature)

**Recommendation**: Move to Profile page or keep as extra feature

---

## Phase 7: Final Polish

### Slice 7.1: Color and Typography Audit
**Time**: 1 hour
**Task**: Verify all colors match Figma
- Primary color: #0F172A
- Gray shades
- Badge colors (green, red, yellow, blue, etc.)

**Files**: All page files

**Validation**: Colors match Figma specs

---

### Slice 7.2: Spacing and Padding Audit
**Time**: 1 hour
**Task**: Verify spacing matches Figma
- Page padding
- Card margins
- Grid gaps
- Button spacing

**Files**: All page files

**Validation**: Spacing matches Figma specs

---

### Slice 7.3: Font Sizes and Weights Audit
**Time**: 30 min
**Task**: Verify typography matches Figma
- Header sizes
- Body text sizes
- Label sizes
- Font weights

**Files**: All page files

**Validation**: Typography matches Figma specs

---

## Summary

| Phase | Slices | Total Time | Priority |
|-------|--------|------------|----------|
| Phase 1: Navigation | 2 | 1.5 hours | Critical |
| Phase 2: Home | 5 | 1.75 hours | High |
| Phase 3: Clients | 6 | 4 hours | High |
| Phase 4: Itinerary | 4 | 3 hours | High |
| Phase 5: My Day | 1 | 0.5 hours | Medium |
| Phase 6: Extra Features | 3 | 0.75 hours (decisions) | Low |
| Phase 7: Polish | 3 | 2.5 hours | Medium |

**Total Slices**: 24
**Estimated Time**: ~14 hours

---

## Recommended Execution Order

1. **Phase 1** - Navigation (Critical foundation)
2. **Phase 2** - Home Page (Most visible)
3. **Phase 3** - Clients Page (Core feature)
4. **Phase 4** - Itinerary Page (Core feature)
5. **Phase 7** - Polish (Final touches)
6. **Phase 5 & 6** - Decisions and verification

---

## Progress Tracking

- [ ] Phase 1: Navigation Structure
  - [ ] Slice 1.1: Update Bottom Navigation to 3 Tabs
  - [ ] Slice 1.2: Move Extra Features to Home Grid
- [ ] Phase 2: Home Page Alignment
  - [ ] Slice 2.1: Update Home Grid to 2 Columns
  - [ ] Slice 2.2: Update Home Menu Items
  - [ ] Slice 2.3: Update Icon Sizes
  - [ ] Slice 2.4: Update Greeting Format
  - [ ] Slice 2.5: Remove Sync Status Banner
- [ ] Phase 3: Clients Page Alignment
  - [ ] Slice 3.1: Update Clients Header
  - [ ] Slice 3.2: Update Clients Tabs to 2 Tabs
  - [ ] Slice 3.3: Simplify Client Card Layout
  - [ ] Slice 3.4: Add Star/Interested Filter Button
  - [ ] Slice 3.5: Update Filter Dialog
  - [ ] Slice 3.6: Move Add Button to Header
- [ ] Phase 4: Itinerary Page Alignment
  - [ ] Slice 4.1: Update Itinerary Header
  - [ ] Slice 4.2: Replace Date Picker with Tab Filter
  - [ ] Slice 4.3: Remove Add New Visit Button
  - [ ] Slice 4.4: Enhance Visit Card Details
- [ ] Phase 5: My Day Page Alignment
  - [ ] Slice 5.1: Verify My Day Implementation
- [ ] Phase 6: Extra Features Decision
  - [ ] Slice 6.1: Decide on Agencies Page
  - [ ] Slice 6.2: Decide on Call Log Page
  - [ ] Slice 6.3: Decide on Settings Page
- [ ] Phase 7: Final Polish
  - [ ] Slice 7.1: Color and Typography Audit
  - [ ] Slice 7.2: Spacing and Padding Audit
  - [ ] Slice 7.3: Font Sizes and Weights Audit
