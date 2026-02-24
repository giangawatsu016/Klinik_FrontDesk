# Product Requirements Document: Klinik FrontDesk

## Overview

The "FrontDesk" module is designed for clinic receptionists to manage patient registration and queue monitoring operations.

## Features

### 1. Registration Menu

Handles patient registration through a unified **Smart Registration Form** that eliminates the need for separate "New" and "Existing" menus.

#### Smart Registration Flow

1. **Search & Auto-fill**: Staff can search for existing patients by Full Name, Phone Number, or NIK using a search bar at the top of the form.
2. **Selection & Confirmation**: If multiple patients match (e.g., duplicate names), a selection dialog appears showing NIK and phone details for disambiguation.
3. **Draft Mode**: Selecting a patient automatically populates all form fields (Smart Auto-fill), allowing staff to verify or update data before proceeding.
4. **Data Entry**: If it's a new patient, staff manually fills the multi-session form:
   - **Personal Info**: First Name (Mandatory), Last Name, Email, ID / NIK (16 digits), Phone, Birthday.
   - **Medical & Profiling**: Height, Weight, Gender, Blood Type, Religion, Marital Status.
   - **Background**: Profession, Education.
   - **Address**: Province, City, Kabupaten, Kecamatan, Kelurahan, RT/RW, Postal Code, Full Address.

**Post-Registration Flow:**

1. Click **"Register"** or **"Add to Queue"**.
2. **Visit Options Dialog**: Select Doctor or Polyclinic, and Priority checkbox.
3. **Payment Dialog**: Select payment method (Cash, QRIS, Debit Card, Credit Card, Insurance).
4. Entry added to **Queue Monitor** with format `D-XXX` or `P-XXX`.

> [!NOTE]
> Patient data is stored in the `Clinic Patient` DocType and a `Clinic Encounter` is created on registration.

---

### 2. Queue Monitor Menu

For monitoring and calling patient queues.

**Queue Types:**

- **Doctor Queue**: Format `D-xxx` (Regular), `DP-xxx` (Priority).
- **Polyclinic Queue**: Format `P-xxx` (Regular), `PP-xxx` (Priority).

**Queue Status Cards (5 cards):**

| Card | Statuses Counted | Color |
|---|---|---|
| Waiting | `Waiting` | Orange |
| Consultation | `Consultation` | Blue |
| Pharmacy | `Pharmacy` | Purple |
| Payment | `Payment` | Teal |
| Completed | `Completed` | Green |

**Status Placement:**

| Status | UI Location |
|---|---|
| `Waiting` | **Waiting Card** |
| `Consultation`, `Pharmacy`, `Payment` | **Antrian Dokter** & **Antrian Polyclinic** columns |
| `Completed` | **Queue → History** submenu |

**Functionality:**

- **Call Patient**: Changes status from `Waiting` to `Consultation`.
- **Advance Status**: External apps (Doctor/Pharmacy/Payment) advance the status to the next stage.
- **Queue History Section**: Dedicated History submenu showing all `Completed` patients.
- **Priority Logic**: Priority patients automatically move to the top of their respective active queues.
- **Responsive Layout**: Side-by-side on desktop (>600px), stacked on mobile.

**Queue Lifecycle:**

```text
Waiting → Consultation → Pharmacy → Payment → Completed
```

| Trigger | Status Change |
|---|---|
| Frontdesk registers patient | → **Waiting** |
| Frontdesk clicks "Call Patient" | → **Consultation** |
| Doctor submits consultation (external app) | → **Pharmacy** |
| Pharmacy submits complete (external app) | → **Payment** |
| Payment team submits complete (external app) | → **Completed** |

**Daily Persistence:**

- **Active Queue**: Resets every day at **00:00 WIB (UTC+7)**.
- **Completed History**: Persistent across all days.

---

### 3. Janji Temu (Appointment)

Managed through a hierarchical sidebar navigation that provides direct access to scheduling and historical records.

**Navigation Structure (Sidebar):**

- **Appointments** (Main Menu): Expands to show sub-menus on Desktop/Tablet.
  - **Jadwal Kunjungan**: Displays the strictly **Today's and Future** active appointments.
  - **History**: Displays all **Past** appointments and **Finalized** records (Completed, Cancelled, Checked In).
  - **Registrasi**: Opens the appointment registration form for new schedules.
    - **Visit Type Selection**: Radio toggle to choose between scheduling by **Doctor** or by **Polyclinic**.
      - **Doctor**: Shows a dropdown of available practitioners.
      - **Polyclinic**: Shows a dropdown of available polyclinics.
    - **Reactive Data Lists**: The form dynamically fetches and displays the latest practitioners and polyclinics, ensuring selections are always available and up-to-date.
    - **Auto-Navigation**: Completing a registration automatically redirects the user to the "Jadwal Kunjungan" list, providing immediate confirmation.

**Appointment History Search:**

- **Refined Search**: The search functionality specifically targets historical records.
- **Status Filter**: Automatically filters for `COMPLETED` or `CANCELLED` statuses.
- **Manual Search Support**: When the search box is empty, it automatically displays the full list of past appointments (History List) for manual browsing without typing.

**Appointment Lifecycle:**

```text
Pending → Checked In (via Add to Queue) → Attended (via Payment) | Cancelled
```

- **Pending**: Newly created appointment, "Add to Queue" button is visible for today's appointments.
- **Checked In**: Patient has been added to the queue. Status badge turns blue, button is hidden, and the card sorts to the bottom of the list.
- **Attended**: Payment has been completed.
- **Cancelled**: Appointment was cancelled.

**Details Displayed:**

- Patient Name
- Doctor Name
- Appointment Date and Time
- Patient, Doctor, and Service details

#### Detail Page Design (Standard)

The detail pages for Appointments and Medical Records follow a unified design standard:

- **Clean Interface**: Removal of dynamic time-based greetings and gradients for a more professional look.
- **Brand Consistency**: Solid primary blue (`#2859E2`) AppBar background.
- **Focus on Content**: Content is organized in clear, animated sections (e.g., Patient Snapshot, Vital Signs, etc.).

---

### 4. Profile Page Details

Displays the currently logged-in user's information from `Clinic Staff Profile` DocType.

**Information Displayed:**

| Field | Source (DocType Field) | Description |
|---|---|---|
| **Full Name** | `full_name` | Staff member's name |
| **Staff Role** | `staff_role` | Clinic Admin / Facility Admin / Doctor / Nurse / Pharmacist / Cashier |
| **Company** | `company` | Linked Clinic Company |
| **Default Facility** | `default_facility` | Assigned facility |
| **Specialization** | `specialization` | Medical specialization (if applicable) |
| **Registration Number** | `registration_number` | STR number |

---

## Data Integration (DocType APIs)

| Function | DocType | Key Fields Used |
|---|---|---|
| Patient Registration | `Clinic Patient` | full_name, nik, gender, birth_date, phone, address, blood_type, religion, etc. |
| Clinical Encounter | `Clinic Encounter` | patient, practitioner, polyclinic, encounter_date, SOAP, diagnosis |
| Queue Management | `Clinic Queue` | patient, practitioner, polyclinic, status, queue_number, vitals |
| Polyclinic List | `Clinic Polyclinic` | polyclinic_name |
| Doctor/Practitioner | `Clinic Practitioner` | full_name, specialization, polyclinic, practitioner_role |
| Payment Methods | `Clinic Payment` | payment_method (Cash/QRIS/Debit Card/Credit Card/Insurance) |
| Appointments | `Clinic Appointment` | patient, practitioner, polyclinic, appointment_date/time, status |
| Staff Profile | `Clinic Staff Profile` | user, full_name, staff_role, company, specialization, registration_number |

---

## Tech Stack

- **Frontend**: Flutter
- **Backend**: Python (Frappe)
- **Database**: MySQL
