# FUNCTIONAL SPECIFICATION DOCUMENT (FSD)
**Project Name:** Klinik Admin System
**Date:** 2026-01-12
**Version:** 2.0

---

## 1. Introduction

### 1.1 Purpose
The purpose of the Klinik Admin System is to streamline the operational workflow of a medical clinic, focusing on patient registration, queue management, and data synchronization with external ERP systems (Frappe/ERPNext).

### 1.2 Scope
The system covers:
*   User Authentication (Login/Logout) & Role Management.
*   Master Data Management (Doctors, Polyclinics, Issuers, Marital Statuses).
*   **Comprehensive Indonesian Address Management** (Proxy to external API).
*   Patient Registration with duplicate prevention.
*   Queue Management (Ticketing, Calling, Status Updates).
*   **Two-Way Integration with Frappe/ERPNext** for centralized data.

---

## 2. System Actors

| Actor | Description |
| :--- | :--- |
| **Admin** | Full access to system configuration, user management, and master data. |
| **Staff/Front Desk** | Responsible for registering patients, verifying address details, and managing the daily queue. |
| **Doctor** | (Future Scope) could view their specific queue and update medical records. |

---

## 3. Functional Requirements

### 3.1 Authentication Module
*   **REQ-AUTH-01**: Users must be able to log in using a username and password.
*   **REQ-AUTH-02**: Passwords must be hashed using `bcrypt`.
*   **REQ-AUTH-03**: The system must verify JWT tokens for protected endpoints.
*   **REQ-AUTH-04**: **Logout Feature**: Users can invalidate their local session via a dedicated Logout button in the sidebar.
*   **REQ-AUTH-05**: **Keyboard Accessibility**: Users must be able to submit the login form by pressing the "Enter" key on the keyboard without needing to click the button.

### 3.2 Patient Management Module
*   **REQ-PAT-01**: Staff can register new patients with mandatory fields: NIK, Name, DOB (Birthday), Phone, Address.
*   **REQ-PAT-02**: **Address Logic**:
    *   System dynamically fetches Provinces, Cities, Districts, and Subdistricts from `emsifa` API via Backend Proxy.
    *   Dropdowns are dependent (Choosing Province loads Cities, etc.).
*   **REQ-PAT-03**: **Validation**:
    *   **Phone Number**: Constrained to max 14 digits, numeric only.
    *   **NIK**: Unique 16-digit identifier.
*   **REQ-PAT-04**: **Integration**:
    *   Patient data is synced to **Frappe (DocType: Customer)** automatically upon creation.
    *   Returned `frappe_id` (e.g., CUST-2024-001) is stored locally for future linking.

### 3.3 Queue Management Module
*   **REQ-QUEUE-01**: Staff can add a registered patient to a queue (General Doctor, Dental, etc.).
*   **REQ-QUEUE-02**: **Validation**: The system must reject a queue request if the patient currently has a status of "Waiting" or "In Consultation".
*   **REQ-QUEUE-03**: **Numbering Format**:
    *   **D-XXX**: Doctor (General)
    *   **DP-XXX**: Doctor (Priority)
    *   **P-XXX**: Polyclinic (General)
    *   **PP-XXX**: Polyclinic (Priority)
*   **REQ-QUEUE-04**: Queue numbering resets daily at 00:00 UTC.
*   **REQ-QUEUE-05**: **Daily Cleanup**: Lazy cleanup mechanism deletes queue records from previous days to keep the list fresh.
*   **REQ-QUEUE-06**: **Integration**: Queue entries are synced to **Frappe (DocType: Event)** for calendar visibility.
*   **REQ-QUEUE-07**: **Text-to-Speech**: System can audibly announce queue numbers (e.g., "Antrian Nomor D-001, silakan masuk").

### 3.4 Integration Module
*   **REQ-INT-01**: System synchronizes new Patient records to Frappe instance via API.
*   **REQ-INT-02**: System synchronizes new Appointments to Frappe instance via API.
*   **REQ-INT-03**: Integration failures logged but do not block local operations (resilient design).

### 3.5 Performance & Optimization
*   **REQ-PERF-01**: **Caching**: Address API responses (Provinces, Cities, etc.) are cached in memory (LRU Cache) to strictly minimize latency.
*   **REQ-PERF-02**: **DB Pooling**: Database connection pool size is optimized (Size: 20, Overflow: 30) to handle high concurrency.

---

## 4. UI/UX Specifications

### 4.1 Design Philosophy
*   **Style**: Glassmorphism (Translucent elements, blurs).
*   **Theme**: Modern Gradient Backgrounds (Soft Blue/Purple/Teal).
*   **Responsiveness**: Optimized for Desktop/Tablet (Web).

### 4.2 Key Screens
1.  **Login Screen**: Centered glass card with gradient background.
2.  **Dashboard (Renamed from Queue)**: Navigation Rail (Left) with Logout button, Stats Overview.
3.  **Registration**: Vertical form with real-time address fetching and numeric keyboards.
4.  **Queue Monitor**: Large typography for "Current Patient", list of waiting patients.

---

## 5. Technical Architecture

### 5.1 Technology Stack
*   **Frontend**: Flutter (Web/Desktop).
*   **Backend**: Python (FastAPI).
*   **Database**: MySQL.
*   **Authentication**: JWT (JSON Web Tokens).

### 5.2 Database Schema
*   **Users**: `id`, `username`, `password_hash`, `role`.
*   **Patient**: `id`, `firstName`, `lastName`, `identityCard` (Unique), `phone`, `frappe_id` (Integration Key).
*   **PatientQueue**: `id`, `userId`, `numberQueue`, `status`, `appointmentTime`, `queueType`, `isPriority`.

---

## 6. Security Requirements
*   **SEC-01**: All external API calls (Frappe) must use secure headers with API Key/Secret.
*   **SEC-02**: Database credentials must be loaded from environment variables (`.env`).
*   **SEC-03**: API Endpoints must be protected via Dependency Injection (`get_current_user`).

---


---

## 8. Testing & Quality Assurance Module
### 8.1 Automated Regression Testing
*   **REQ-TEST-01**: **Login Automation**: System includes a Playwright-based test suite to verify login scenarios (Valid, Invalid, Empty, Layout).
*   **REQ-TEST-02**: **Reporting**: Test suite generates granular DOCX reports including:
    *   3-Step Screenshots (Empty -> Filled -> Result).
    *   Color-coded Pass/Fail status.
*   **REQ-TEST-03**: **CanvasKit Support**: Test infrastructure supports "Blind Tab" navigation to validate Flutter Web CanvasKit rendering without direct DOM accessibility.

---

## 9. Delivery Artifacts
*   Source Code (GitHub).
*   **Postman Collection** (API Testing).
*   **JMeter Test Plan** (`.jmx` for Load Testing).
*   User Walkthrough/Guide.
*   Product Requirements Document (PRD).
