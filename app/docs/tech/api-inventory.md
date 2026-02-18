# API Inventory

This file lists all available services and their base URLs. For detailed Request/Response schemas, see specific `docs/tech/[feature]-api-spec.md`.

## Services

| Service | Base URL (Dev) | Description |
| :--- | :--- | :--- |
| **FrontDesk Service** | `http://clinic.localhost:8000/api/method/api_clinic.clinicfrontdesk.api` | Patient registration, search, and queue management. |
| **Doctor Service** | `http://clinic.localhost:8000/api/method/api_clinic.clinicdoctor.api` | Doctor data and facility synchronization. |
| **Appointment Service** | `http://clinic.localhost:8000/api/method/api_clinic.clinicappointment.api` | Appointment scheduling, invoicing, and payment simulation. |

## Endpoint Summary

### FrontDesk

- `POST /register_patient`
- `GET /search_patient`
- `POST /add_to_queue`
- `GET /get_queue`
- `GET /get_queue_history`
- `POST /update_queue_status`
- `GET /get_practitioners`
- `GET /get_polyclinics`
- `GET /get_issuers`

### System (Diagnostic)

- `GET /get_error_logs`

### Doctor

- `GET /get_doctors`
- `POST /sync_facility_to_satusehat`

### Appointments

- `GET /get_appointments` (Updated Feb 16 2026: now returns `phone`, `birth_date` in `patientDetail` and `license_number` as `doctorSip`)
- `POST /create_appointment`
- `POST /create_invoice`
- `POST /simulate_payment`
- `POST /cancel_appointment` (New Feb 16 2026: sets status to 'Cancelled')
