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
### Manual Verification
- Verify Dashboard look & feel.
- Verify "List Disease" menu navigation and functionality.
