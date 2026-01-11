# FUNCTIONAL SPECIFICATION DOCUMENT (FSD)
**Project Name:** Klinik Admin System
**Date:** 2024-01-11
**Version:** 1.0

---

## 1. Introduction

### 1.1 Purpose
The purpose of the Klinik Admin System is to streamline the operational workflow of a medical clinic, specifically focusing on patient registration, queue management, and data synchronization with external ERP systems (Frappe/ERPNext).

### 1.2 Scope
The system covers:
*   User Authentication & Role Management.
*   Master Data Management (Doctors, Polyclinics, Issuers, Marital Statuses).
*   Patient Registration with duplicate prevention.
*   Queue Management (Ticketing, Calling, Status Updates).
*   Integration with Frappe/ERPNext for centralized data.

---

## 2. System Actors

| Actor | Description |
| :--- | :--- |
| **Admin** | Full access to system configuration, user management, and master data. |
| **Staff/Front Desk** | Responsible for registering patients and managing the daily queue. |
| **Doctor** | (Future Scope) could view their specific queue and update medical records. |

---

## 3. Functional Requirements

### 3.1 Authentication Module
*   **REQ-AUTH-01**: Users must be able to log in using a username and password.
*   **REQ-AUTH-02**: Passwords must be hashed using `bcrypt`.
*   **REQ-AUTH-03**: The system must verify JWT tokens for protected endpoints.
*   **REQ-AUTH-04**: Session timeout is set to 8 hours (work shift).

### 3.2 Patient Management Module
*   **REQ-PAT-01**: Staff can register new patients with mandatory fields: NIK, Name, DOB, Phone, Address.
*   **REQ-PAT-02**: System must validate NIK (Identity Card) uniqueness.
*   **REQ-PAT-03**: **Issuer Logic**:
    *   If Issuer = "BPJS", user must select "BPJS Kesehatan" or "BPJS Ketenagakerjaan".
    *   If Issuer = "Asuransi", user must select Provider (Allianz, Prudential, Manulife).
*   **REQ-PAT-04**: Patient data is automatically synced to Frappe/ERPNext as a "Patient" or "Customer".

### 3.3 Queue Management Module
*   **REQ-QUEUE-01**: Staff can add a registered patient to a queue (General Doctor, Dental, etc.).
*   **REQ-QUEUE-02**: **Validation**: The system must reject a queue request if the patient currently has a status of "Waiting" or "In Consultation".
*   **REQ-QUEUE-03**: **Numbering Format**:
    *   **D-XXX**: Doctor (General)
    *   **DP-XXX**: Doctor (Priority)
    *   **P-XXX**: Polyclinic (General)
    *   **PP-XXX**: Polyclinic (Priority)
*   **REQ-QUEUE-04**: Queue numbering resets daily.
*   **REQ-QUEUE-05**: Staff can update status to "In Consultation" or "Completed".

### 3.4 Integration Module
*   **REQ-INT-01**: System synchronizes new Patient records to Frappe instance via API.
*   **REQ-INT-02**: System synchronizes new Appointments to Frappe instance via API.
*   **REQ-INT-03**: Integration failures should be logged but not block critical local operations (Background Task).

---

## 4. UI/UX Specifications

### 4.1 Design Philosophy
*   **Style**: Glassmorphism (Translucent elements, blurs).
*   **Theme**: Modern Gradient Backgrounds (Soft Blue/Purple/Teal).
*   **Responsiveness**: Optimized for Desktop/Tablet (Web).

### 4.2 Key Screens
1.  **Login Screen**: Centered glass card with gradient background.
2.  **Dashboard**: Navigation Rail (Left), Stats Overview.
3.  **Registration**: Multi-step form or long form with dynamic dropdowns.
4.  **Queue Monitor**: Large typography for "Current Patient", list of waiting patients.

---

## 5. Technical Architecture

### 5.1 Technology Stack
*   **Frontend**: Flutter (Web).
*   **Backend**: Python (FastAPI).
*   **Database**: MySQL (migrated from SQLite).
*   **Authentication**: JWT (JSON Web Tokens).

### 5.2 Database Schema
*   **Users**: `id`, `username`, `password_hash`, `role`.
*   **Patient**: `id`, `firstName`, `lastName`, `identityCard` (Unique), `phone`, `issuerId`, `insuranceName`.
*   **PatientQueue**: `id`, `userId`, `numberQueue`, `status`, `appointmentTime`.
*   **Issuer**: `issuerId`, `issuer` (Name), `nama` (JSON Sub-options).

---

## 6. Security Requirements
*   **SEC-01**: All external API calls (Frappe) must use secure headers with API Key/Secret.
*   **SEC-02**: Database credentials must be loaded from environment variables (`.env`).
*   **SEC-03**: API Endpoints must be protected via Dependency Injection (`get_current_user`).

---

## 7. Delivery Artifacts
*   Source Code (GitHub).
*   Postman Collection.
*   User Walkthrough/Guide.
*   Migration SQL Scripts.
