# FUNCTIONAL SPECIFICATION DOCUMENT (FSD)
**Project Name:** Klinik Intimedicare System
**Date:** 2026-01-29
**Version:** 2.8 (Deployment Automation & Role Filtering)

---

## 1. Introduction

### 1.1 Purpose
The purpose of the Klinik Intimedicare System is to streamline the operational workflow of a medical clinic, focusing on patient registration, queue management, medicine inventory, user access control, and regulatory compliance through data synchronization with SatuSehat and external ERP systems (Frappe/ERPNext).

### 1.2 Scope
The system covers:
*   User Authentication & **Role-Based Access Control (RBAC)**.
*   **User Management (CRUD) & ERPNext Sync**.
*   Master Data Management (Doctors, Polyclinics, Issuers, Pharmacists).
*   Patient Registration, Vitals, & Editing.
*   Queue Management (Ticketing, Calling, Daily Cleanup).
*   **Appointment Management (Janji Temu)**.
*   Medicine Inventory Management (Standard & Batches).
*   **Two-Way Integration with Frappe/ERPNext**.
*   **Integration with SatuSehat (Ministry of Health)**.

---

## 2. System Actors

| Actor | Description |
| :--- | :--- |
| **Super Admin** | Full access. Manages Admins, Staff, and Dev Settings. Can delete users. |
| **Administrator** | Manages Staff, Doctors, Medicines. Views Reports. Configures Integrations. |
| **Staff/Front Desk** | **Exclusive Access** to Registration, Queue Monitor, and Overview. Processes daily flows. |

---

## 3. Functional Requirements

### 3.1 Authentication & RBAC
*   **REQ-AUTH-01**: Secure Login (bcrypt).
*   **REQ-AUTH-02**: **Role-Based Visibility**:
    *   **Staff Only**: Overview, Queue Monitor, Registration. (Hidden for Admins).
    *   **Admin/Super Admin**: Users, Sync Data, Master Data (Doctors, Pharmacists).
*   **REQ-AUTH-03**: **Logout**: Session invalidation.

### 3.2 Patient Management
*   **REQ-PAT-01**: Register/Edit Patient (Checking NIK, Name, Phone, Address).
*   **REQ-PAT-02**: **Validation**: NIK must be **exactly 16 digits** (numeric). Phone must be max 14 digits.
*   **REQ-PAT-03**: **Sync**: Auto-create/update `Customer` in ERPNext.
*   **REQ-PAT-04**: **IHS Sync**: Push Patient demographics to SatuSehat (Sandbox).

### 3.3 Queue Management
*   **REQ-QUEUE-01**: Assign to Doctor/Poly.
*   **REQ-QUEUE-02**: Validation (No double queue).
*   **REQ-QUEUE-03**: **Sync**: Push to `Event` in ERPNext.
*   **REQ-QUEUE-04**: TTS Announcements (Voice Call).
*   **REQ-QUEUE-05**: **Daily Cleanup**: Lazy deletion of previous day's queue.
*   **REQ-QUEUE-06**: **Prioritization**: `isPriority` flag for top-of-list sorting.

### 3.4 Appointment Management (Janji Temu)
*   **REQ-APT-01**: Schedule Appointments (Patient, Doctor, Date, Time).
*   **REQ-APT-02**: **Filtering**: Only display appointments for **Today and Future dates**. Past appointments are hidden.
*   **REQ-APT-03**: External API support for creating appointments.

### 3.5 Pharmacist Management
*   **REQ-PHARM-01**: CRUD Pharmacist Data (Name, NIK, SIP, IHS).
*   **REQ-PHARM-02**: **Validation**: Strict 16-digit NIK check.
*   **REQ-PHARM-03**: **UI**: Clean card layout (No Active/Inactive chip).

### 3.6 Integration Module
*   **REQ-INT-01**: **Bi-Directional User Sync**: Local User <-> ERPNext User.
*   **REQ-INT-02**: **Bi-Directional Patient Sync**: Local Patient <-> ERPNext Customer.
*   **REQ-INT-03**: **Doctor Sync**: Local Doctor <-> ERPNext Practitioner & SatuSehat.
*   **REQ-INT-04**: **Bi-Directional Medicine Sync**: ERPNext Item <-> Local Medicine.
*   **REQ-INT-05**: **Satu Sehat Auth**: OAuth2 Token Management.

### 3.7 Medicine Inventory Module
*   **REQ-MED-01**: **Bi-Directional Sync**: Pull/Push Items.
*   **REQ-MED-02**: **Batch Management**: Track Stock by Batch Number and Expiry Date.
*   **REQ-MED-03**: **Stock Logic**: Total Stock = Sum of all Batches.

### 3.8 Payment Module
*   **REQ-PAY-01**: Support Multiple Methods (Cash, BPJS, Insurance).
*   **REQ-PAY-02**: Dynamic Dropdown for Issuers (Seeded Data).
*   **REQ-PAY-03**: Record Insurance Number and Claim Status.

---

## 4. UI/UX Specifications

### 4.1 Key Screens
1.  **Dashboard**: Dynamic Sidebar based on "Staff" vs "Admin" role.
2.  **Registration**: Split form with Animated Entrance.
3.  **Queue Monitor**: Real-time status, "Call Patient" with TTS.
4.  **Janji Temu**: List of upcoming appointments.
5.  **Medicine**: Grid view with Batch management.
6.  **Pharmacist**: Grid view of staff cards.

---

## 5. Technical Architecture

### 5.1 Deployment
*   **Scripts**: `deploy_gitlab.ps1` for automated sync to GitLab (Frontend/Backend).
*   **Environment**: Docker-ready / WSL compatible.

### 5.2 Database Schema
*   See `ERD_Klinik Intimedicare.md`.
