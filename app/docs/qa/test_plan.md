# Test Plan & Verification Strategy

**Feature:** Clinic Frontdesk System (Patient & Queue Management)
**Version:** v1.1
**Owner:** @dev (QA Role)

## 1. Scope of Testing

- **In Scope**:
  - Patient Registration flow with `patientcore` table mapping.
  - Patient Search functionality using `patientcore`.
  - Queueing System with `patientqueue` table mapping.
  - Status updates (Calling, Completing) in the queue.
  - UI responsiveness and error handling (image loading fixes).
- **Out of Scope**:
  - Integration with external health services (SatuSehat).
  - Payment processing (mocked).

## 2. Functional Test Cases (E2E)

| ID | Scenario | Steps | Expected Result | Status |
| :--- | :--- | :--- | :--- | :--- |
| **TC-01** | Register New Patient | 1. Navigate to Registration 2. Enter full details 3. Submit | Success message shown, patient saved to `patientcore`. | ✅ Passed |
| **TC-02** | Search Existing Patient | 1. Enter NIK/Phone in Search 2. Click Search | Patient details pop up from `patientcore`. | ✅ Passed |
| **TC-03** | Add Patient to Queue | 1. Find patient 2. Select Polyclinic/Doctor 3. Add | Queue number generated, saved to `patientqueue`. | ✅ Passed |
| **TC-04** | Update Queue Status | 1. Go to Queue Monitor 2. Call patient 3. Complete | Status changes in DB, time timestamps updated. | ✅ Passed |

## 3. UI/UX Verification

- [ ] **Image Fallback**: Profile pictures show initials if network fails.
- [ ] **Responsive Header**: Welcome message and icons display correctly.

## 4. Bug Report Template

If a test fails, log it here:

### [BUG-01] Title

- **Steps**: ...
- **Expected**: ...
- **Actual**: ...
- **Screenshot**: ...
