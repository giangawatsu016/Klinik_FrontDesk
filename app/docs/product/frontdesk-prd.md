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
   - **Medical & Profiling**: Height, Weight, Gender, Religion, Marital Status.
   - **Background**: Profession, Education.
   - **Address**: Province, City, Kabupaten, Kecamatan, RT/RW, Postal Code, Full Address.

**Post-Registration Flow:**

1. Click **"Register"** or **"Add to Queue"**.
2. **Visit Options Dialog**: Select Doctor or Polyclinic, and Priority checkbox.
3. **Payment Dialog**: Select payment method (Cash, BPJS, Insurance, Credit Card).
4. Entry added to **Queue Monitor** with format `D-XXX` or `P-XXX`.

---

### 2. Queue Monitor Menu

For monitoring and calling patient queues.

**Queue Types:**

- **Doctor Queue**: Format `D-xxx` (Regular), `DP-xxx` (Priority).
- **Polyclinic Queue**: Format `P-xxx` (Regular), `PP-xxx` (Priority).

**Queue Display:**

- **Currently Serving Section**: Shows patient currently "Called" (In Consultation).
- **Waiting List**: Shows all patients with status "Waiting".

**Functionality:**

- **Call Patient**: Changes status from "Waiting" to "Called" (shows in Currently Serving).
- **Done (Completed)**: Updates status to **Completed**.
- **Queue History Section**: A dedicated list at the bottom showing **all** patients with "Completed" status across all dates.
- **Priority Logic**: Priority patients automatically move to the top of their respective active queues.
- **Responsive Layout**: Side-by-side on desktop (>600px), stacked on mobile.

**Queue Lifecycle:**

```text
Waiting → Called (In Consultation) → Completed (Moves to History)
```

**Daily Persistence:**

- **Active Queue**: Resets every day at **00:00 WIB (UTC+7)** to ensure focus on today's patients.
- **Completed History**: Persistent across all days, allowing staff to review past patient visits directly on the monitor screen.

---

### 3. Janji Temu (Appointment)

Managed through a hierarchical sidebar navigation that provides direct access to scheduling and historical records.

**Navigation Structure (Sidebar):**

- **Appointments** (Main Menu): Expands to show sub-menus on Desktop/Tablet.
  - **Jadwal Kunjungan**: Displays the historical list of past appointments.
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

Displays the currently logged-in user's information for identity verification.

**Information Displayed:**

- **Name**: Full name from the user profile.
- **Role**: Designated role (e.g., Admin, Staff, Doctor).
- **Staff ID / NIP**: Unique staff identifier for internal clinic reference.

---

## Tech Stack

- **Frontend**: Flutter
- **Backend**: Python (Frappe)
- **Database**: MySQL
