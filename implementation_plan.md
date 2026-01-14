# Implementation Plan - Satu Sehat Integration

## Goal
Integrate Klinik Admin with **Satu Sehat Platform (SSP)** using the provided Development Credentials. The system will sync new patients to SSP via FHIR API.

## User Review Required
- **Credentials**: Confirm if the provided Client ID/Secret are for the **Development** or **Production** environment. (Assuming Development based on context).

## Proposed Changes

### Configuration
#### [MODIFY] [.env]
- Add `SATUSEHAT_AUTH_URL`, `SATUSEHAT_BASE_URL`, `SATUSEHAT_CLIENT_ID`, `SATUSEHAT_CLIENT_SECRET`, `SATUSEHAT_ORG_ID`.

### Backend
#### [NEW] [backend/services/satu_sehat_service.py](file:///c:/Users/1672/.gemini/antigravity/scratch/Klinik_Admin/backend/services/satu_sehat_service.py)
- **Class `SatuSehatClient`**:
    - `get_token()`: Handles OAuth2 Client Credentials flow. Caches token until expiry.
    - `create_patient_fhir(patient_data)`: Maps local patient data to FHIR `Patient` resource JSON.
    - `post_patient()`: Sends POST request to `/Patient` endpoint.

#### [MODIFY] [backend/routers/patients.py](file:///c:/Users/1672/.gemini/antigravity/scratch/Klinik_Admin/backend/routers/patients.py)
- In `create_patient`:
    - Call `SatuSehatClient.post_patient()` after local creation (or alongside Frappe sync).
    - Save the returned `id` (IHS Number) to a new column `ihs_number` in `Patient` table.

#### [MODIFY] [backend/models.py](file:///c:/Users/1672/.gemini/antigravity/scratch/Klinik_Admin/backend/models.py)
- Add `ihs_number = Column(String(100), nullable=True)` to `Patient` model.

## Verification Plan
### Automated Tests
- Create a script `test_satu_sehat.py` to:
    1. Authenticate and print Access Token.
    2. Create a dummy patient and print the returned IHS Number.
