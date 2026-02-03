# Product Requirements Document: Klinik FrontDesk

## Overview

The "FrontDesk" module is designed for clinic receptionists to manage patient registration and queue monitoring operations.

## Features

### 1. Registration Menu

Handles patient registration with two submenus: "New Patient" and "Existing Patient".

#### Submenu: New Patient

A multi-session form for inputting patient data.

##### A. Personal Info Session

- **First Name**: Mandatory
- **Last Name**: Optional
- **Email**: Mandatory
- **ID / NIK**: Mandatory (Must be 16 digits)
- **Phone Number**: Mandatory
- **Birthday**: Date Picker

##### B. Medical & Profiling

- **Medical Record No.**: Optional
- **Height (cm)**: Optional
- **Weight (kg)**: Optional
- **Gender**: List Dropdown [Male, Female]
- **Religion**: List Dropdown
- **Marital Status**: List Dropdown

##### C. Background

- **Profession**: Optional
- **Education**: List Dropdown

##### D. Address

- **Province**: List Dropdown
- **City**: List Dropdown
- **Kabupaten**: List Dropdown
- **Kecamatan**: List Dropdown
- **RT**: Optional
- **RW**: Optional
- **Postal Code**: Optional
- **Full Address**: Mandatory

**Post-Registration Flow:**

1. Click "Register" button.
2. **Visit Options Dialog**: Select Doctor or Polyclinic, and Priority checkbox.
3. **Payment Dialog**: Select payment method:
   - Cash (Pay at counter)
   - BPJS (National health insurance)
   - Insurance (Private insurance)
   - Credit Card (Debit/Credit card)
4. Entry added to "Queue Monitor" with format `D-XXX` or `P-XXX`.

#### Submenu: Existing Patient

1. Input Phone Number or NIK.
2. Display patient details if found.
3. Click "Add to Queue" button.
4. **Visit Options Dialog**: Select Doctor or Polyclinic, and Priority checkbox.
5. **Payment Dialog**: Select payment method.
6. Entry added to Queue Monitor.

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
- **Done (Completed)**: Updates status to **Completed** and retains the entry for daily statistics (visible in header cards).
- **Priority Logic**: Priority patients automatically move to the top of their respective queues.
- **Responsive Layout**: Side-by-side on desktop (>600px), stacked on mobile.

**Queue Lifecycle:**

```text
Waiting → Called (In Consultation) → Completed → Daily Reset (Cleanup)
```

**Daily Reset (Auto-Cleanup):**

- Queue data is automatically reset every day at **00:00 WIB (UTC+7)**.
- When a new day begins, all queue entries are cleared and counter resets to 1.
- This ensures no stale data from previous days remains in the system.

---

### 3. Janji Temu (Appointment)

Integrates with 3rd party apps to display scheduled appointments.

**Details Displayed:**

- Patient Name
- Doctor Name
- Appointment Date and Time

## Tech Stack

- **Frontend**: Flutter
- **Backend**: Python (Frappe)
- **Database**: MySQL
