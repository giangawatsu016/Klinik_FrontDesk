# Database Schema: FrontDesk Module

This document outlines the Frappe DocTypes used for the FrontDesk module.

## 1. DocType: Clinic Patient

Stores patient personal and medical information.

| Field | Type | Options | Description |
| --- | --- | --- | --- |
| first_name | Data | Mandatory | Patient's first name |
| last_name | Data | | Patient's last name |
| email | Data | Mandatory | |
| nik | Data | Mandatory | 16-digit ID number |
| phone | Data | Mandatory | |
| birth_date | Date | Mandatory | |
| medical_record_no | Data | | |
| height_cm | Int | | |
| weight_kg | Int | | |
| gender | Select | Male, Female | |
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

## 4. DocType: Clinic Doctor

Stores doctor/practitioner information.

| Field | Type | Options | Description |
| --- | --- | --- | --- |
| name | Data | Mandatory | Doctor name |
| title_prefix | Data | | e.g. "dr." |
| title_suffix | Data | | e.g. "Sp.A", "Sp.KK" |
| specialization | Data | | Specialty area |
| photo_url | Data | | Profile image URL |
| schedule | JSON | | Available time slots |
| facility | Link | Mandatory | Associated clinic |
| company | Link | Mandatory | Default: "Intimedicare" |

## 5. DocType: Clinic Service

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
