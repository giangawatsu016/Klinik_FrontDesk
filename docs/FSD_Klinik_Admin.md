# FUNCTIONAL SPECIFICATION DOCUMENT (FSD)
**Project Name:** Klinik Intimedicare System
**Date:** 2026-01-22
**Version:** 2.5 (Bi-directional Sync & Dashboard Logic)

---

## 1. Introduction

### 1.1 Purpose
The purpose of the Klinik Intimedicare System is to streamline the operational workflow of a medical clinic, focusing on patient registration, queue management, medicine inventory (including concoctions), user access control, and regulatory compliance through data synchronization with SatuSehat and external ERP systems (Frappe/ERPNext).

### 1.2 Scope
The system covers:
*   User Authentication & **Role-Based Access Control (RBAC)**.
*   **User Management (CRUD) & ERPNext Sync**.
*   Master Data Management (Doctors, Polyclinics, Issuers).
*   Patient Registration, Vitals, & Editing.
*   Queue Management (Ticketing, Calling, Daily Cleanup).
*   Medicine Inventory Management (Standard & Concoctions).
*   **Two-Way Integration with Frappe/ERPNext**.
*   **Integration with SatuSehat (Ministry of Health)**.

---

## 2. System Actors

| Actor | Description |
| :--- | :--- |
| **Super Admin** | Full access. Manages Admins and Staff. Can delete users. |
| **Administrator** | Manages Staff, Doctors, Medicines. Views Reports. Configures Integrations. |
| **Staff/Front Desk** | Registers patients, manages queues, processes payments. Restricted from Admin panels. |

---

## 3. Functional Requirements

### 3.1 Authentication & RBAC
*   **REQ-AUTH-01**: Secure Login (bcrypt).
*   **REQ-AUTH-02**: **RBAC**: UI elements (Tabs, Buttons) generated dynamically based on Role.
*   **REQ-AUTH-03**: **Logout**: Session invalidation.

### 3.2 Patient Management
*   **REQ-PAT-01**: Register/Edit Patient (NIK, Name, Phone, Address, Height, Weight).
*   **REQ-PAT-02**: Address Logic (emsifa API).
*   **REQ-PAT-03**: **Sync**: Auto-create/update `Customer` in ERPNext.
*   **REQ-PAT-04**: **IHS Sync**: Push Patient demographics to SatuSehat (Sandbox) and store returned `ihs_number`.

### 3.3 Queue Management
*   **REQ-QUEUE-01**: Assign to Doctor/Poly.
*   **REQ-QUEUE-02**: Validation (No double queue).
*   **REQ-QUEUE-03**: **Sync**: Push to `Event` in ERPNext.
*   **REQ-QUEUE-04**: TTS Announcements.
*   **REQ-QUEUE-05**: **Daily Cleanup**: Lazy deletion of previous day's queue to reset counters.
*   **REQ-QUEUE-06**: **Prioritization**: `isPriority` flag triggers sorting to top of list. Prefix `D-` (Doctor) and `DP-` (Doctor Priority).

### 3.4 Integration Module
*   **REQ-INT-01**: **Bi-Directional User Sync**: Local User <-> ERPNext User (via Email).
*   **REQ-INT-02**: **Bi-Directional Patient Sync**: Local Patient <-> ERPNext Customer.
*   **REQ-INT-03**: **Doctor Sync**: Local Doctor <-> Healthcare Practitioner (ERPNext) & Practitioner (SatuSehat).
*   **REQ-INT-04**: **Bi-Directional Medicine Sync**: ERPNext Item <-> Local Medicine.
*   **REQ-INT-05**: **Satu Sehat Auth**: OAuth2 Token Management (Client Credentials).
*   **REQ-INT-06**: **Patient Verification**: Search NIK -> Auto-fill Form.
*   **REQ-INT-07**: **KFA Search**: Search Medicine from Kemkes KFA Browser.

### 3.5 User Management Module
*   **REQ-USER-01**: **List Users**: View all users with Role indicators.
*   **REQ-USER-02**: **Create User**: Add Username, Full Name, Email, Role, Password.
*   **REQ-USER-03**: **Edit User**: Update details (optional Password).
*   **REQ-USER-04**: **Sync**: On Create/Update (if Email present), sync to ERPNext User.
*   **REQ-USER-05**: **Rules**: Admin cannot edit Super Admin. Staff cannot view User List.

### 3.6 Medicine Inventory Module
*   **REQ-MED-01**: **Bi-Directional Sync**: Pull Items from ERPNext / Push Local Creations to ERPNext.
*   **REQ-MED-02**: Manual entry support.
*   **REQ-MED-03**: **Concoctions (Racikan)**: Create combined medicines (Parent) from multiple ingredients (Children) with pricing logic.
*   **REQ-MED-04**: Stock-based validation.

### 3.7 Payment Module
*   **REQ-PAY-01**: Support Multiple Methods (Cash, QRIS, Debit, Credit, Insurance).
*   **REQ-PAY-02**: Calculate Total Bill (Consultation + Medicine + Admin Fee).

### 3.8 Performance & Optimization
*   **REQ-PERF-01**: Address API Caching.
*   **REQ-PERF-02**: Background Tasks (FastAPI) for external Syncs to prevent UI blocking.

---

## 4. UI/UX Specifications

### 4.1 Key Screens
1.  **Login**: Central Card.
2.  **Dashboard**: Role-dependent Tabs (Registration, Users, Dashboard, Doctors...).
3.  **User Management**: Data Table with Actions.
4.  **Registration**: Split form (Personal -> Address -> Vitals -> Payment). **Animated Entrances**.
5.  **Medicine**: List view with Filter, Add Racikan Modal.
6.  **Dashboard Stats**:
    *   **Total Patients**: New Registrations Today.
    *   **Doctors Available**: Active - In Consultation.
    *   **Queue Today**: Total queues created today (Auto-resets daily).
    *   **Recent Activity**: Live list of last 5 patients added today.

---

## 5. Technical Architecture

### 5.1 Technology Stack
*   **Frontend**: Flutter (Web/Desktop).
*   **Backend**: Python (FastAPI).
*   **Database**: MySQL (Prod).
*   **Message Broker**: Kafka (KRaft mode) - Optional for async events.

### 5.2 Database Schema
*   See `ERD_Klinik Intimedicare.md`.
