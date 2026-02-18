# MySQL Integration: klinik_db

## Overview

The Frappe backend (`api_clinic`) integrates with an external MySQL database (`klinik_db`) for real-time data synchronization. This ensures that patient and queue data is always available in both systems.

## Connection Details

| Property | Value |
| --- | --- |
| Host | `localhost` |
| Port | `3306` |
| Database | `klinik_db` |
| Username | `awwal` |
| Password | `awwal1234` |

## Table Mapping

| MySQL Table | Frappe DocType | Purpose |
| --- | --- | --- |
| `patientcore` | `Clinic Patient` | Patient master data |
| `doctorcore` | `Clinic Practitioner` | Doctor/practitioner list |
| `patientqueue` | `Clinic FrontDesk Queue` | Daily queue entries |
| `issuer` | — | Payment issuers (future) |
| `maritalstatus` | — | Marital status options (future) |

## Sync Architecture

```mermaid
Flutter App ──HTTP──▶ Frappe API ──pymysql──▶ MySQL (klinik_db)
                        │                        │
                  [Primary DB]            [Secondary DB]
                        │                        │
                  register_patient ──────▶ patientcore (INSERT/UPDATE)
                  add_to_queue ──────────▶ patientqueue (INSERT)
                  update_queue_status ───▶ patientqueue (UPDATE)
                  search_patient ◀─────── patientcore (SELECT fallback)
                  get_practitioners ◀──── doctorcore (SELECT merge)
```

## Sync Behavior

### Write Operations (Frappe → MySQL)

| Operation | Trigger | MySQL Table | Strategy |
| --- | --- | --- | --- |
| Register Patient | After `doc.insert()` | `patientcore` | `INSERT ON DUPLICATE KEY UPDATE` (by NIK) |
| Add to Queue | After `doc.insert()` | `patientqueue` | `INSERT ON DUPLICATE KEY UPDATE` (by `frappe_id`) |
| Update Queue Status | After `doc.save()` | `patientqueue` | `UPDATE WHERE frappe_id = ?` (syncs `status`, `called_at`, `completed_at`) |

### Read Operations (MySQL → Frappe)

| Operation | Trigger | MySQL Table | Strategy |
| --- | --- | --- | --- |
| Search Patient | When Frappe returns 0 results | `patientcore` | `SELECT WHERE nik/phone/name LIKE ?` |
| Get Practitioners | Always | `doctorcore` | Merge results, deduplicate by `full_name` |

## Key Module

**File**: `api_clinic/clinicfrontdesk/db_external.py`

### Functions

| Function | Direction | Description |
| --- | --- | --- |
| `get_connection()` | — | Creates pymysql connection to `klinik_db` |
| `search_patient_external(query)` | Read | Search `patientcore` by NIK/phone/name |
| `get_doctors_external()` | Read | Fetch all from `doctorcore` |
| `sync_patient_to_external(doc)` | Write | Upsert patient to `patientcore` |
| `sync_queue_to_external(doc)` | Write | Insert queue entry to `patientqueue` |
| `sync_queue_status_to_external(id, status)` | Write | Update status in `patientqueue` |

## Prerequisites

1. Install `pymysql` in the Frappe bench environment:

   ```bash
   cd /home/frappe/frappe-bench
   ./env/bin/pip install pymysql
   bench restart
   ```

2. Ensure MySQL tables have a `frappe_id` column (VARCHAR) for cross-reference:

   ```sql
   ALTER TABLE patientcore ADD COLUMN IF NOT EXISTS frappe_id VARCHAR(140);
   ALTER TABLE patientcore ADD UNIQUE INDEX idx_nik (nik);
   ALTER TABLE patientqueue ADD COLUMN IF NOT EXISTS frappe_id VARCHAR(140) UNIQUE;
   ```

## Error Handling

All sync operations are wrapped in try/catch blocks. If MySQL is unavailable:

- **Write failures** are logged to Frappe Error Log but do not block the primary operation.
- **Read failures** return empty results; the app continues with Frappe-only data.
