# Implementation Plan - General Payment Methods
# Implementation- [x] Implement General Payment Sub-methods (Cash, QRIS, etc.)
- [x] Sync Patients to SatuSehat (Sandbox)
  - Implemented `post_patient` in `satu_sehat_service.py` with fallback creation.
  - created `backend/sync_patients_to_satusehat.py` script.
- [x] Sync Doctors to SatuSehat (Practitioner)
  - Added `identityCard` (NIK) to `DoctorEntity` and updated DB.
  - Implemented `search_practitioner_by_nik` in `satu_sehat_service.py`.
  - Created `backend/sync_doctors_to_satusehat.py`.

## Goal
Enhance the "Assign Doctor" flow to support specific payment sub-methods for "General" (Umum) patients.

## Proposed Changes

### Frontend
#### [MODIFY] [frontend/lib/screens/registration.dart](file:///c:/Users/1672/.gemini/antigravity/scratch/Klinik_Admin/frontend/lib/screens/registration.dart)
- **State**: Add `_paymentSubMethod` (String?) and related controllers (e.g., `_paymentAmount`, `_paymentReceipt`).
- **UI Logic**:
    - When `issuerId == 1` (General), display a Dropdown for: Cash, QRIS, Debit, Transfer, CreditCard.
    - **Cash**: Show "Enter Amount" field.
    - **QRIS**: Show "Scan & Verify" (Instruction/Button).
    - **Debit/CreditCard**: Show "Enter Receipt / Transaction ID" field.
    - **Transfer**: Show "Enter Details" field.
- **Data Handling**:
    - Store the selected sub-method and details in `insuranceName` (as "Method - Detail") or a separate field if available. For now, we will concatenate into `insuranceName` or `noAssuransi` to persist it without backend schema changes, or just validate for UI demo purposes if backend storage isn't specified.
    - *Decision*: Save `PaymentMethod: Details` into `insuranceName` field of `Patient` (or Queue) to avoid immediate backend refactor, as `insuranceName` is unused for General patients.

## Verification Plan
- Manual verification via "Assign Doctor" screen.
- Select "Umum" -> Verify Dropdown appears.
- Select "Cash" -> Verify Amount field appears.
