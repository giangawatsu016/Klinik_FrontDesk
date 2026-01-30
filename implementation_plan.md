# Implementation Plan - UI Simplification & Disease List

# [Goal Description]
Simplify the Front-end UI for a cleaner, more minimal look.
Add a new feature: **List Disease** (Master Data for Diagnoses/ICD-10).

## User Review Required
- **UI Design**: I will be removing some "visual noise" from the Dashboard. Confirmation on specific preferences (Sidebar vs Bottom Bar) would be ideal, but I will proceed with a standard "Clean Sidebar" approach.

## Proposed Changes

### Backend
#### [MODIFY] [backend/models.py](file:///c:/Users/1672/.gemini/antigravity/scratch/Klinik_Admin/backend/models.py)
- Add `Disease` model (id, icd_code, name, description, is_active).

#### [NEW] [backend/routers/diseases.py](file:///c:/Users/1672/.gemini/antigravity/scratch/Klinik_Admin/backend/routers/diseases.py)
- CRU endpoints for Diseases.

### Frontend
#### [MODIFY] [frontend/lib/screens/dashboard.dart](file:///c:/Users/1672/.gemini/antigravity/scratch/Klinik_Admin/frontend/lib/screens/dashboard.dart)
- Refactor `NavigationRail` to be cleaner or switch to a minimal `Drawer`.
- Add "Disease List" to the menu.

#### [NEW] [frontend/lib/screens/disease_list.dart](file:///c:/Users/1672/.gemini/antigravity/scratch/Klinik_Admin/frontend/lib/screens/disease_list.dart)
- CRUD UI for Diseases.

## Verification Plan
### Automated Tests
- Test API endpoints for Diseases using `curl`.
- Exact commands you'll run, browser tests using the browser tool, etc.
- `backend/tests/verify_queue_flow.py` (Completed)
- `backend/tests/check_api_visibility.py` (Completed - Confirmed API Visibility)
### Manual Verification
- Verify Dashboard look & feel.
- Asking the user to deploy to staging and testing, verifying UI changes on an iOS app etc.
- User confirmed Queue Monitor shows `TEST-001` correctly.
- Verify "List Disease" menu navigation and functionality.

## Frontdesk Focus Refactor
### [MODIFY] [frontend/lib/screens/dashboard.dart](file:///c:/Users/1672/.gemini/antigravity/scratch/Klinik_Admin/frontend/lib/screens/dashboard.dart)
- Remove the following menu items from `allPages`:
    - Doctors
    - Pharmacist
    - Patients
    - Medicines
    - Diagnosis
    - Diseases
- Ensure routing/indexing logic remains valid.

## Remove Super Admin & Dev Settings
### [MODIFY] [frontend/lib/screens/dashboard.dart](file:///c:/Users/1672/.gemini/antigravity/scratch/Klinik_Admin/frontend/lib/screens/dashboard.dart)
- Remove "Dev Settings" menu item.
- Remove Super Admin role checks.

### [MODIFY] [frontend/lib/screens/user_management.dart](file:///c:/Users/1672/.gemini/antigravity/scratch/Klinik_Admin/frontend/lib/screens/user_management.dart)
- Remove "Super Admin" from role dropdown and sorting.

### [MODIFY] [backend/routers/auth.py](file:///c:/Users/1672/.gemini/antigravity/scratch/Klinik_Admin/backend/routers/auth.py)
- Remove login bypass logic.

### [MODIFY] [backend/routers/users.py](file:///c:/Users/1672/.gemini/antigravity/scratch/Klinik_Admin/backend/routers/users.py)
- Simplify permissions to only Administrator and Staff.

## Refine Menu Visibility
### [MODIFY] [frontend/lib/screens/dashboard.dart](file:///c:/Users/1672/.gemini/antigravity/scratch/Klinik_Admin/frontend/lib/screens/dashboard.dart)
- Remove "Sync Data" menu item entirely.
- Update filtering logic:
    - **Administrator**: visible ONLY "Users".
    - **Staff**: visible "Queue Monitor", "Janji Temu", "Registration".
