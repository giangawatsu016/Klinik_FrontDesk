# Product Requirements Document (PRD)
**Project Name:** Klinik Admin System (Desktop App)
**Version:** 2.0
**Status:** Live / Maintenance
**Last Updated:** 2026-01-12

## 1. Product Overview
### 1.1 Vision
To provide a modern, efficient, and user-friendly desktop application for clinic front-desk operations, creating a seamless experience for patient registration and queue management while integrating with enterprise backend systems (ERPNext).

### 1.2 Objective
*   Streamline the patient registration process (New & Existing).
*   Manage daily patient queues for General Practitioners and Polyclinics.
*   Provide real-time dashboard analytics for clinic traffic.
*   **Ensure data synchronization with the central ERP system (Frappe/ERPNext).**

### 1.3 Scope
*   **Platform:** Windows Desktop (Flutter-based).
*   **Primary Users:** Receptionists / Front Desk Staff.
*   **Key Modules:** Authentication, Dashboard, Patient Registration, Queue Management, Master Data (Address, Doctors).

## 2. Target Audience & Personas
*   **Receptionist (Staff):** Needs a fast, keyboard-friendly interface to input patient data quickly and assign them to doctors.
*   **Administrator:** Needs to manage doctor schedules, user accounts, and view overall clinic performance.

## 3. Key Features & Requirements

### 3.1 Authentication & Security
*   **Login System:** Secure login with username/password.
*   **Role-Based Access:** Distinguish between Staff and Admin capabilities.
*   **Logout Mechanism:** Dedicated logout button in the sidebar (bottom-left) to clear session state.

### 3.2 Patient Management
*   **New Patient Registration:**
    *   Capture detailed personal info (Name, NIK, Phone, Birthday, Gender).
    *   **Indonesian Address System:** Full hierarchy support (Province -> City -> District -> Subdistrict) using external API.
    *   **Validation:** 
        *   **Phone Number:** Strictly limited to 14 digits, numeric only.
        *   **NIK:** 16 Digits, unique validation.
*   **Existing Patient Search:**
    *   Fast lookup by NIK or Phone number.
    *   One-click selection to add to queue.
*   **External Integration (Frappe):** 
    *   Auto-sync new patient data to ERPNext (Mapped to `Customer` Doctype).
    *   Bulk sync capability for legacy data.

### 3.3 Queue Management
*   **Queue Assignment:**
    *   Select Doctor or Polyclinic.
    *   Assign Priority status (Elderly, Emergency).
    *   **ERPNext Sync:** Push queue entry to ERPNext (Mapped to `Event` Doctype).
*   **Auto-Numbering:** Smart generating of queue numbers (e.g., D-001 for Doctor, P-001 for Poly).
*   **Daily Reset:** Queue numbers automatically reset to 001 at midnight.
*   **Daily Cleanup:** Auto-delete previous day's queue records to keep the list fresh.
*   **Text-to-Speech (TTS):** Audio announcement for calling patients (e.g., "Antrian Nomor D-001...").

### 3.4 Dashboard & Analytics (Renamed from "Queue")
*   **Real-time Stats:** Total Patients, Waiting, In-Consultation, Completed.
*   **Visual Charts:** Patient traffic trends (Daily/Weekly).
*   **Recent Activity:** List of latest registrations.

### 3.5 Integrations
*   **ERPNext / Frappe:** 
    *   **Patient Sync:** Local `Patient` -> Remote `Customer` (Two-way ID Link).
    *   **Appointment Sync:** Local `Queue` -> Remote `Event` (Calendar).
*   **Regional Data:** `emsifa` API for Indonesian administrative region data.

## 4. User Experience (UX) Requirements
*   **Glassmorphism Design:** Modern, clean UI with translucent elements.
*   **Responsive Layout:** Sidebar navigation with collapsibility.
*   **Efficiency:** Minimized clicks for common tasks (Registration -> Queue).
*   **Feedback:** Toast notifications (Snackbars) for success/error states.
*   **Input Constraints:** Numeric keyboards for Phone/NIK fields.

## 5. Non-Functional Requirements
*   **Performance:**
    *   Address API caching (LRU Cache) for sub-20ms response on repeat lookups.
    *   Database connection pooling (SQLAlchemy) to handle up to 50 concurrent requests.
*   **Reliability:** Offline capability (limited) or graceful error handling when API is down.
*   **Compatibility:** Windows 10/11.

## 6. Success Metrics
*   **Registration Time:** Reduce time to register a new patient to under 2 minutes.
*   **Queue Accuracy:** Zero duplicate queue numbers per day.
*   **Data Integrity:** 100% match between Local Database and ERPNext Customer list.
