# Backend Migration: FastAPI Mock → Frappe

## Overview

The Flutter FrontDesk app was initially developed against a local **FastAPI mock backend** (`backend/server.py`) for rapid prototyping. This document describes the migration to the production **Frappe backend** (`api-clinic`).

## Architecture

```
┌──────────────────┐       ┌──────────────────────────┐       ┌──────────────────┐
│  Flutter App     │──────▶│  Frappe (api_clinic)      │──────▶│  MySQL (klinik_db)│
│  (FrontDesk)     │  HTTP │  WSL / Docker             │ Sync  │  localhost:3306   │
│                  │       │                            │       │                  │
│  dio_client.dart │       │  clinicfrontdesk/api.py    │       │  patientcore     │
│  BASE_URL:       │       │  db_external.py (sync)     │       │  doctorcore      │
│  :8000/api       │       │  clinicadmin/api.py        │       │  patientqueue    │
└──────────────────┘       └──────────────────────────┘       └──────────────────┘
        ▲
        │ (fallback, dev only)
┌──────────────────┐
│  FastAPI Mock     │
│  backend/server.py│
│  :8080            │
└──────────────────┘
```

## DocType ↔ FastAPI Model Mapping

| Frappe DocType | FastAPI Model | Auto-Name Pattern | Key Differences |
|---|---|---|---|
| `Clinic Patient` | `PatientCore` | `PAT-YYYY-#####` | Frappe: `full_name` + `first_name` + `last_name`. FastAPI: `firstName` + `lastName` |
| `Clinic FrontDesk Queue` | `PatientQueue` | `FDQ-YYYY-#####` | Frappe requires `facility` & `company` (Link fields). FastAPI: none |
| `Clinic Practitioner` | `DoctorEntity` | `DOC-YYYY-#####` | Frappe: `full_name` + `specialization`. FastAPI: `namaDokter` + `polyName` |
| `Clinic Polyclinic` | n/a | `field:polyclinic_name` | Only in Frappe |
| `Clinic Payment` | `Payment` | `PAY-YYYY-#####` | Frappe: linked to `Clinic Billing`. FastAPI: direct `patient_id` |
| `Clinic Medication` | `Medicine` | varies | Frappe: `medicine_name`. FastAPI: `medicineName` |

## Field Mapping: Clinic Patient

| Frappe Field | FastAPI Field | Flutter `fromJson` Key | Notes |
|---|---|---|---|
| `name` | `id` | `name` / `id` | Frappe auto-ID (e.g. `PAT-2026-00001`) |
| `full_name` | — | `full_name` / `patient_name` | Required in Frappe |
| `first_name` | `firstName` | `first_name` / `firstName` | |
| `last_name` | `lastName` | `last_name` / `lastName` | |
| `nik` | `identityCard` | `nik` / `identityCard` | Unique |
| `phone` | `phone` | `phone` | |
| `gender` | `gender` | `gender` | `Male` / `Female` / `Other` |
| `birth_date` | `birthday` | `birth_date` / `birthday` / `dob` | Date format |
| `religion` | `religion` | `religion` | |
| `education` | `education` | `education` | |
| `profession` | `profession` | `profession` | |
| `marital_status` | `maritalStatusId` | `marital_status` | Frappe: string. FastAPI: FK int |
| `address` | `address` | `address` | |
| `province` | `province` | `province` | |
| `city` | `city` | `city` | |
| `district` | `district` | `district` | |
| `subdistrict` | `subdistrict` | `subdistrict` | |
| `rt` | `rt` | `rt` | |
| `rw` | `rw` | `rw` | |
| `postal_code` | `postalCode` | `postal_code` / `postalCode` | |
| `company` | — | — | **Required** in Frappe (Link to `Clinic Company`) |
| `status` | — | `status` | Default: `Active` |

## Field Mapping: Clinic FrontDesk Queue

| Frappe Field | FastAPI Field | Flutter Key | Notes |
|---|---|---|---|
| `name` | `id` | `name` / `id` | Auto-ID `FDQ-YYYY-#####` |
| `patient` | `userId` | `patient` / `userId` | Link to `Clinic Patient` |
| `queue_number` | `numberQueue` | `queue_number` / `numberQueue` | |
| `status` | `status` | `status` | `Waiting` / `Called` / `Completed` / `Cancelled` |
| `is_priority` | `isPriority` | `is_priority` / `isPriority` | Check field |
| `queue_type` | `queueType` | `queue_type` / `queueType` | `Doctor` / `Polyclinic` |
| `practitioner` | `medicalFacilityPolyDoctorId` | `practitioner` | Link to `Clinic Practitioner` |
| `polyclinic` | `polyclinic` | `polyclinic` | Link to `Clinic Polyclinic` |
| `facility` | — | — | **Required** (Link to `Clinic Facility`) |
| `company` | — | — | **Required** (Link to `Clinic Company`) |

## API Endpoint Mapping

### Existing (clinicfrontdesk/api.py)

| Frappe Method | FastAPI Equivalent | Purpose |
|---|---|---|
| `api_clinic.clinicfrontdesk.api.register_patient` | `POST /api/patients` | Register new patient |
| `api_clinic.clinicfrontdesk.api.search_patient` | `GET /api/patients/search?query=` | Search patient |
| `api_clinic.clinicfrontdesk.api.add_to_queue` | `POST /api/queue` | Add to queue |
| `api_clinic.clinicfrontdesk.api.get_queue` | `GET /api/queue` | Get today's queue |
| `api_clinic.clinicfrontdesk.api.update_queue_status` | `PATCH /api/queue/{id}` | Update queue status |

### Added Endpoints (clinicfrontdesk/api.py)

| Frappe Method | Purpose | MySQL Sync |
|---|---|---|
| `clinicfrontdesk.api.get_practitioners` | List active practitioners | ✅ Merges from `doctorcore` |
| `clinicfrontdesk.api.get_polyclinics` | List active polyclinics | — |
| `clinicfrontdesk.api.get_notifications` | Notification feed (stub) | — |

### Search Logic Refinements (v2.5)

The `search_patient` endpoint has been upgraded to handle multi-patient scenarios:

- **Broad Matching**: Searches across `nik`, `phone`, and `full_name` (including multi-word split queries).
- **Result Aggregation**: Returns a combined list from Frappe and `patientcore` MySQL.
- **Frontend Disambiguation**: The app now displays a selection dialog if multiple matches are found, showing NIK and phone to help the operator select the correct record.

### Appointment Logic Refinements (v2.6)

The `create_appointment` endpoint has been enhanced to handle mandatory Frappe fields and frontend data variations:

- **Mandatory Field Resolution**: Automatically infers and sets `polyclinic` and `facility` IDs (linked master data) if they are missing from the frontend payload, preventing `MandatoryError` crashes.
- **Service Type Translation**: Implements a mapping layer that translates frontend service names (e.g., "Consultation") into valid backend `service_type` options (e.g., "Konsultasi").
- **Practitioner Linking**: Standardizes the resolution of practitioners using both IDs and full names to ensure valid doc linking.

### Real-time MySQL Sync

| Operation | Frappe DocType | MySQL Table | Sync Direction |
|---|---|---|---|
| Register Patient | `Clinic Patient` | `patientcore` | Frappe → MySQL |
| Add to Queue | `Clinic FrontDesk Queue` | `patientqueue` | Frappe → MySQL |
| Update Queue Status | `Clinic FrontDesk Queue` | `patientqueue` | Frappe → MySQL |
| Search Patient | `Clinic Patient` | `patientcore` | MySQL → Frappe (fallback) |
| Get Practitioners | `Clinic Practitioner` | `doctorcore` | MySQL → Frappe (merge) |

## Environment Configuration

```env
# In Flutter app .env or constants
# Development (FastAPI mock):
BASE_URL=http://localhost:8080/api

# Production (Frappe):
BASE_URL=http://localhost:8000/api
```

## WSL Sync Workflow

After modifying Frappe app files on Windows:

```bash
# 1. Copy updated files to WSL
cp -r /mnt/c/Users/1672/.gemini/antigravity/scratch/app-clinic-frontdesk/api-clinic/api_clinic/* \
      /home/frappe/frappe-bench/apps/api_clinic/api_clinic/

# 2. Run migration (if DocType changes)
cd /home/frappe/frappe-bench && bench --site clinic.localhost migrate

# 3. Restart bench
bench restart
```

## Reference

- **FastAPI Reference**: `C:\Users\1672\Downloads\Kerja\Project\Klinik_Project\Back Up\Klinik_Admin V.01`
- **Frappe App Source**: `api-clinic/api_clinic/`
- **Flutter App**: `app/`
- **MySQL Database**: `klinik_db` on `localhost:3306` (user: `awwal`)
- **MySQL Integration Module**: `api_clinic/clinicfrontdesk/db_external.py`
