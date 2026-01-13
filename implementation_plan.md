# Implementation Plan - Doctor & Patient Lists

## Goal
Implement list views for Doctors and Patients in the Admin Dashboard, allowing users to view details for each entry.

## User Review Required
- None. Standard UI components will be used.

## Proposed Changes

### Backend
- **Verify Endpoints**:
    - `GET /master/doctors`: Ensure it returns full doctor details (including NIK if applicable).
    - `GET /patients/`: Ensure it returns a paginated list of patients.

### Frontend
#### [NEW] [doctor_list.dart](file:///c:/Users/1672/.gemini/antigravity/scratch/Klinik_Admin/frontend/lib/screens/doctor_list.dart)
- Displays a `ListView` of doctors fetched from `ApiService.getDoctors()`.
- `ListTile` showing Name and Specialization (Poly).
- On Tap: Opens a Dialog showing full details (ID, Gelar, Availability).

#### [NEW] [patient_list.dart](file:///c:/Users/1672/.gemini/antigravity/scratch/Klinik_Admin/frontend/lib/screens/patient_list.dart)
- Displays a `ListView` of patients fetched from `ApiService.getPatients()`.
- `ListTile` showing Name and Phone.
- On Tap: Opens a Dialog showing full details (NIK, Address, BPJS, etc.).

#### [MODIFY] [dashboard.dart](file:///c:/Users/1672/.gemini/antigravity/scratch/Klinik_Admin/frontend/lib/screens/dashboard.dart)
- Add "Patients" to `NavigationRail` destinations (below Doctors).
- Update `pages` list to include `DoctorListScreen` and `PatientListScreen`.

#### [MODIFY] [api_service.dart](file:///c:/Users/1672/.gemini/antigravity/scratch/Klinik_Admin/frontend/lib/services/api_service.dart)
- Ensure `getPatients` method exists and handles pagination (or default limit).

## Verification Plan
### Manual Verification
- **Doctors**:
    - Click "Doctors" sidebar item.
    - Verify list loads.
    - Click a doctor -> Verify detail dialog.
- **Patients**:
    - Click "Patients" sidebar item.
    - Verify list loads.
    - Click a patient -> Verify detail dialog.
