# FUNCTIONAL SPECIFICATION DOCUMENT (FSD)
**Project Name:** Klinik Admin System
**Date:** 2026-01-15
**Version:** 2.2

---

## 1. Introduction

### 1.1 Purpose
The purpose of the Klinik Admin System is to streamline the operational workflow of a medical clinic, focusing on patient registration, queue management, medicine inventory, user access control, and data synchronization with external ERP systems (Frappe/ERPNext).

### 1.2 Scope
The system covers:
*   User Authentication & **Role-Based Access Control (RBAC)**.
*   **User Management (CRUD) & ERPNext Sync**.
*   Master Data Management (Doctors, Polyclinics, Issuers).
*   Patient Registration & Editing.
*   Queue Management (Ticketing, Calling).
*   Medicine Inventory Management.
*   **Two-Way Integration with Frappe/ERPNext**.

---

## 2. System Actors

| Actor | Description |
| :--- | :--- |
| **Super Admin** | Full access. Manages Admins and Staff. Can delete users. |
| **Administrator** | Manages Staff, Doctors, Medicines. Views Reports. |
| **Staff/Front Desk** | Registers patients, manages queues. Restricted from Admin panels. |

---

## 3. Functional Requirements

### 3.1 Authentication & RBAC
*   **REQ-AUTH-01**: Secure Login (bcrypt).
*   **REQ-AUTH-02**: **RBAC**: UI elements (Tabs, Buttons) generated dynamically based on Role.
*   **REQ-AUTH-03**: **Logout**: Session invalidation.

### 3.2 Patient Management
*   **REQ-PAT-01**: Register/Edit Patient (NIK, Name, Phone, Address).
*   **REQ-PAT-02**: Address Logic (emsifa API).
*   **REQ-PAT-03**: **Sync**: Auto-create/update `Customer` in ERPNext.

### 3.3 Queue Management
*   **REQ-QUEUE-01**: Assign to Doctor/Poly.
*   **REQ-QUEUE-02**: Validation (No double queue).
*   **REQ-QUEUE-03**: **Sync**: Push to `Event` in ERPNext.
*   **REQ-QUEUE-04**: TTS Announcements.

### 3.4 Integration Module
*   **REQ-INT-01**: **User Sync**: Local User -> ERPNext User (via Email).
*   **REQ-INT-02**: **Patient Sync**: Local Patient -> ERPNext Customer.
*   **REQ-INT-03**: **Doctor Sync**: Local Doctor -> Healthcare Practitioner.
*   **REQ-INT-04**: **Medicine Sync**: ERPNext Item -> Local Medicine.
*   **REQ-INT-05**: **Satu Sehat Auth**: OAuth2 Token Management.
*   **REQ-INT-06**: **Patient Verification**: Search NIK -> Auto-fill Form.
*   **REQ-INT-07**: **KFA Search**: Search Medicine -> Import.

### 3.5 User Management Module (New)
*   **REQ-USER-01**: **List Users**: View all users with Role indicators.
*   **REQ-USER-02**: **Create User**: Add Username, Full Name, Email, Role, Password.
*   **REQ-USER-03**: **Edit User**: Update details (optional Password).
*   **REQ-USER-04**: **Sync**: On Create/Update (if Email present), sync to ERPNext User.
*   **REQ-USER-05**: **Rules**: Admin cannot edit Super Admin. Staff cannot view User List.

### 3.6 Medicine Inventory Module
*   **REQ-MED-01**: Sync Items from ERPNext.
*   **REQ-MED-02**: Manual entry support.
*   **REQ-MED-03**: Stock-based validation.

### 3.7 Data Entry Module
*   **REQ-DATA-01**: Add/Edit Doctors (Syncs to Practitioner).
*   **REQ-DATA-02**: Add/Edit Medicines.

### 3.5 Performance & Optimization
*   **REQ-PERF-01**: Address API Caching.

---

## 4. UI/UX Specifications

### 4.1 Key Screens
1.  **Login**: Central Card.
2.  **Dashboard**: Role-dependent Tabs (Registration, Users, Dashboard, Doctors...).
3.  **User Management**: Data Table with Actions.
4.  **Registration**: Split form (Personal -> Address -> Payment).

---

## 5. Technical Architecture

### 5.1 Technology Stack
*   **Frontend**: Flutter (Desktop).
*   **Backend**: Python (FastAPI).
*   **Database**: SQLite (Dev) / MySQL (Prod).

### 5.2 Database Schema
*   **Users**: `id`, `username`, `email` (Unique, Sync Key), `password_hash`, `full_name`, `role`.
*   **Patient**: `id`, `firstName`, `identityCard`, `frappe_id`.
*   **PatientQueue**: `id`, `userId`, `numberQueue`, `status`.
*   **Medicine**: `id`, `erpnext_item_code`, `name`, `stock`.
*   **Doctor**: `id`, `namaDokter`, `polyName`.

---

## 5.3 API Endpoints Structure (Integration Points)

Based on the detailed design, the backend exposes the following key endpoints:

| Domain | Endpoint | Purpose |
| :--- | :--- | :--- |
| **Authentication** | `POST /auth/login` | User login (returns JWT Token). |
| | `POST /auth/register` | Register new user. |
| **Patients** | `GET /patients/` | List all patients. |
| | `GET /patients/{id}` | Get patient details. |
| | `POST /patients/` | Register new patient. |
| | `GET /patients/search` | Search by Name/ID. |
| **Queues** | `POST /patients/queue/` | Add patient to queue. |
| | `GET /patients/queue/` | List current queues. |
| | `PUT /patients/queue/{id}/status` | Update queue status (Waiting/Completed). |
| **Doctors** | `GET /doctors/` | List all doctors. |
| | `POST /doctors/` | Add new doctor. |
| | `GET /doctors/{id}/schedule` | Get doctor schedule (Placeholder). |

---

## 6. Security Requirements
*   **SEC-01**: API Keys for Frappe.
*   **SEC-02**: RBAC enforcement at API Router level.

---
