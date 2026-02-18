# Database Schema: Clinic Intimedicare

This document outlines the Frappe DocTypes used for the FrontDesk module.

**Last Backend Sync Status**: Fixed & Migrated (2026-02-05).

## 1. DocType: Clinic Patient

| Field | Type | Options | Description |
| --- | --- | --- | --- |
| first_name | Data | Mandatory | Patient's first name |
| last_name | Data | | Patient's last name |
| email | Data | Mandatory | |
| nik | Data | Mandatory | 16-digit ID number |
| id_patient_satusehat | Data | | Satu Sehat ID |
| phone | Data | Mandatory | |
| birth_date | Date | Mandatory | |
| medical_record_no | Data | | |
| height_cm | Int | | |
| weight_kg | Int | | |
| gender | Select | Male, Female, Other | |
| birth_date | Date | Mandatory | |
| blood_type | Select | A, B, AB, O | |
| religion | Select | ... | |
| marital_status | Select | ... | |
| profession | Data | | |
| education | Select | ... | |
| province | Select | ... | |
| city | Select | ... | |
| district | Select | ... | (Kabupaten) |
| subdistrict | Select | ... | (Kecamatan) |
| rt | Data | | |
| rw | Data | | |
| postal_code | Data | | |
| address | Text | Mandatory | Full Address |
| company | Link | Mandatory | Default: "Intimedicare" |

## 2. DocType: Clinic FrontDesk Queue

Stores queue entries for Doctor and Polyclinic visits.

| Field | Type | Options | Description |
| --- | --- | --- | --- |
| patient | Link | Clinic Patient | |
| queue_type | Select | Doctor, Polyclinic | |
| practitioner | Link | Clinic Staff | (If queue_type is Doctor) |
| polyclinic | Link | Clinic Facility | (If queue_type is Polyclinic) |
| is_priority | Check | | 1 for Priority, 0 for Regular |
| status | Select | Waiting, Called, Completed, Cancelled | |
| queue_number | Data | | e.g. D-001, DP-001 |
| blood_pressure | Data | | mmHg |
| temperature | Float | | °C |
| weight | Float | | kg |
| height | Float | | cm |
| called_at | Datetime | | Time patient was called |
| completed_at | Datetime | | Time visit was completed |
| appointment | Link | Clinic Appointment | Optional link to appointment |
| facility | Link | Mandatory | Default: "Main Clinic" |
| company | Link | Mandatory | Default: "Intimedicare" |

## 3. DocType: Clinic Appointment

Stores appointment (Janji Temu) data including service, doctor, and payment info.

| Field | Type | Options | Description |
| --- | --- | --- | --- |
| patient_detail | JSON | | Patient name, address, etc. |
| service_id | Int | | Service ID |
| service_name | Data | | e.g. "Konsultasi Umum" |
| doctor_id | Int | | |
| doctor_name | Data | | |
| doctor_title_prefix | Data | | e.g. "dr." |
| doctor_title_suffix | Data | | e.g. "Sp.A", "Sp.KK" |
| date | Datetime | Mandatory | Appointment date and time |
| status | Select | PENDING, PAID, IN_PROGRESS, COMPLETED, CANCELLED | |
| payment_status | Select | UNPAID, PAID | |
| final_price | Currency | | Total price after discount |
| discount_name | Data | | Applied discount code |
| clinical_record | JSON | | Diagnoses and medicines |
| facility | Link | Mandatory | Default: "Main Clinic" |
| company | Link | Mandatory | Default: "Intimedicare" |

## 4. DocType: Clinic Practitioner

Stores practitioner information (Doctors, Nurses, etc.).

| Field | Type | Options | Description |
| --- | --- | --- | --- |
| full_name | Data | Mandatory | Practitioner name |
| practitioner_role | Select | Doctor, Nurse, Staff | |
| specialization | Data | | e.g. "Sp.A", "General" |
| registration_number | Data | | STR |
| license_number | Data | | SIP |
| email | Data | | |
| phone | Data | | |
| company | Link | Mandatory | Default: "Intimedicare" |
| status | Select | Active, Inactive | |

## 5. DocType: Clinic Polyclinic

Stores polyclinic facility information.

| Field | Type | Options | Description |
| --- | --- | --- | --- |
| polyclinic_name | Data | Mandatory | e.g. "Poli Umum" |
| description | Text | | |
| company | Link | Mandatory | Default: "Intimedicare" |
| status | Select | Active, Inactive | |

## 6. DocType: User / Clinic Staff

Stores information for clinic employees and application users.

| Field | Type | Options | Description |
| --- | --- | --- | --- |
| full_name | Data | Mandatory | User's full name |
| role | Select | Admin, Staff, Doctor | Access level role |
| staff_id | Data | Mandatory | NIP / Employee ID (e.g. STF-001) |
| email | Data | Mandatory | Login identifier |
| photo_profile | Data | | URL to profile image |

## 7. DocType: Clinic Service

Stores available medical services.

| Field | Type | Options | Description |
| --- | --- | --- | --- |
| name | Data | Mandatory | Service name |
| description | Text | | Service details |
| price | Currency | Mandatory | Base price |
| discount_price | Currency | | Discounted price (if any) |
| discount_name | Data | | e.g. "Early Bird" |
| image_url | Data | | Service image |
| category | Select | Consultation, Checkup, Treatment | |
| facility | Link | Mandatory | Associated clinic |
| company | Link | Mandatory | Default: "Intimedicare" |
