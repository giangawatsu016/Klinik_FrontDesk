# Product Requirements Document (PRD)
**Project Name:** Klinik Admin System (Desktop App)
**Version:** 2.2
**Status:** Live / Maintenance
**Last Updated:** 2026-01-15

## 1. Product Overview
### 1.1 Vision
To provide a modern, efficient, and user-friendly desktop application for clinic front-desk operations, creating a seamless experience for patient registration and queue management while integrating with enterprise backend systems (ERPNext).

### 1.2 Objective
*   Streamline the patient registration process (New & Existing).
*   Manage daily patient queues for General Practitioners and Polyclinics.
*   Provide real-time dashboard analytics for clinic traffic.
*   **Secure the system with Role-Based Access Control (RBAC).**
*   **Ensure data synchronization with the central ERP system (Frappe/ERPNext) for Patients, Doctors, Medicines, and Users.**

### 1.3 Scope
*   **Platform:** Windows Desktop (Flutter-based).
*   **Primary Users:** Receptionists / Front Desk Staff, Administrators, Super Admins.
*   **Key Modules:** Authentication, User Management, Patient Registration, Queue Management, Master Data (Doctors, Medicines), ERPNext Integration.

## 2. Target Audience & Personas
*   **Receptionist (Staff):** Needs a fast, keyboard-friendly interface to input patient data quickly and check medicine stock.
*   **Administrator:** Needs to manage staff accounts, doctor schedules, and view overall clinic performance.
*   **Super Admin:** Full system control, including managing Administrators and configurations.

## 3. Key Features & Requirements

### 3.1 Authentication & Security
*   **Login System:** Secure login with username/password.
*   **Role-Based Access Control (RBAC):**
    *   **Super Admin:** Full Access. Can manage Admins and Staff.
    *   **Administrator:** Can manage Staff and Master Data (Doctors, Medicines). Access to Reports.
    *   **Staff:** Restricted to Patient Registration, Queue, and Dashboard (Queue Monitor).
*   **Logout Mechanism:** Dedicated logout button in the sidebar.

### 3.2 User Management (New)
*   **CRUD Operations:** Create, Read, Update, Delete system users.
*   **Role Assignment:** Assign roles (superadmin, admin, staff) during creation.
*   **Permission Enforcement:** UI hides actions based on the logged-in user's role.
*   **ERPNext User Sync:** Automatically create/update "System User" in ERPNext when a user is managed locally (requires Email).

### 3.3 Patient Management
*   **New Patient Registration:**
    *   Capture detailed personal info (Name, NIK, Phone, Birthday, Gender).
    *   **Indonesian Address System:** Full hierarchy support (emsifa API).
*   **Validation:** 14-digit Phone, 16-digit NIK.
*   **Edit Capabilities:** Update patient details with two-way sync to ERPNext.

### 3.4 Queue Management
*   **Assignment:** Assign to Doctor/Poly with Priority status.
*   **Auto-Numbering:** D-XXX (Doctor), P-XXX (Poly). Daily Reset.
*   **Daily Cleanup:** Auto-delete old queue records.
*   **ERPNext Sync:** Push queue entry to `Event` Doctype.
*   **TTS:** Audio announcements for queue calling.

### 3.5 Master Data Management
*   **Doctors:** View/Add/Edit with sync to `Healthcare Practitioner`.
*   **Medicines:** View/Add/Edit with sync to ERPNext `Item` (Stock Levels).

### 3.6 Dashboard & Analytics
*   **Role-Specific Views:**
    *   Staff: Queue Monitor, Registration.
    *   Admin/Super Admin: User Management, Master Data Lists.
*   **Stats:** Real-time patient counts.

### 3.7 Integrations
*   **ERPNext / Frappe (Two-Way Sync):**
    *   `User` (Local) <-> `User` (Remote)
    *   `Patient` (Local) <-> `Customer` (Remote)
    *   `Doctor` (Local) <-> `Healthcare Practitioner` (Remote)
    *   `Medicine` (Local) <-> `Item` (Remote)
    *   `Queue` (Local) -> `Event` (Remote)

## 4. User Experience (UX) Requirements
*   **Glassmorphism Design:** Modern UI with translucent/blur effects.
*   **Responsive Layout:** Sidebar navigation adaptable to roles.
*   **Efficiency:** Keyboard support (Enter to Submit), optimized forms.

## 5. Non-Functional Requirements
*   **Performance:** Caching for address data, DB pooling.
*   **Reliability:** Resilient integration (failsafe if ERPDown).
*   **Compatibility:** Windows 10/11.

## 6. Success Metrics
*   **Registration Time:** Under 2 minutes.
*   **Queue Accuracy:** Zero duplicates.
*   **Sync Accuracy:** 100% data match for Patients and Users between systems.

## 7. Quality Assurance
*   **Automated Testing:** Playwright suites for Login.
*   **Regression Testing:** Regular verification of Sync flows.

