# Complete Implementation History
**Project:** Klinik Admin System
**Date Generated:** 2026-01-12

This document chronicles the entire development and implementation journey of the Klinik Admin application, from initial refactoring to the current stable release (v2.0).

---

## Phase 1: Foundation & Architecture Refactoring
**Goal:** Migrate from a lightweight prototype (SQLite) to a robust production-ready architecture (MySQL).

### 1.1 Database Migration
*   **Action:** Migrated database backend from SQLite to **MySQL**.
*   **Implementation:** 
    -   Updated `backend/database.py` to use `mysql+pymysql` driver.
    -   Created `alembic` migrations to initialize the schema (`users`, `patient`, `maritalstatus`).
    -   Configured environment variables (`.env`) for DB credentials.

### 1.2 Authentication System
*   **Action:** Secure the application with Role-Based Access Control (RBAC).
*   **Implementation:**
    -   Implemented JWT (JSON Web Token) authentication in `auth_utils.py`.
    -   Created `LoginScreen` in Flutter with gradient UI.
    -   Added password hashing using `bcrypt`.

---

## Phase 2: Core Feature Implementation
**Goal:** Implement the primary business logic for Patient Registration and Queueing.

### 2.1 Indonesian Address System
*   **Action:** Implement dynamic address selection (Province -> Sub-district).
*   **Implementation:**
    -   Integrated with `emsifa.com` API via a proxy in `backend/routers/master_data.py`.
    -   Created dependent dropdowns in `registration.dart`.
    -   **Optimization:** Implemented **LRU Cache** (`@lru_cache`) in Python to cache API responses, reducing latency from ~500ms to <10ms for repeated requests.

### 2.2 Insurance & Master Data
*   **Action:** Handle various payment methods (BPJS, Insurance, General).
*   **Implementation:**
    -   Created `Issuer` model and `migration_insurance.sql` to seed data.
    -   Added logic: If "BPJS" is selected -> Show "Kesehatan/Ketenagakerjaan". If "Insurance" -> Show "Allianz/Prudential/etc.".

### 2.3 Queue Management
*   **Action:** Manage daily patient flow.
*   **Implementation:**
    -   Created `PatientQueue` model.
    -   Implemented logic to generate queue numbers (e.g., `D-001`, `P-005`) based on Doctor vs Polyclinic selection.
    -   Added **Daily Cleanup** logic to lazy-delete old queue records.

---

## Phase 3: ERPNext / Frappe Integration
**Goal:** Synchronize local clinic data with a centralized ERP system.

### 3.1 Integration Strategy (Evolution)
*   **Attempt 1 (Ideal):** Sync to `Patient` and `Patient Appointment` (Healthcare Module).
    *   *Result:* Failed due to "Module Not Found" (Server-side 500 Error) on the user's specific Frappe instance.
*   **Attempt 2 (Stable - Current):** Sync to **Core Modules**.
    *   **Patient** -> Syncs to `Customer`.
    *   **Queue** -> Syncs to `Event` (Calendar).
    *   *Result:* Success.

### 3.2 Implementation Details
*   Created `backend/services/frappe_service.py` to handle API calls.
*   Implemented **Two-Way Sync Logic**:
    1.  Create Patient via API.
    2.  Capture returned `name` (ID) from Frappe.
    3.  Save `frappe_id` to local `Patient` table for future updates.
*   **Bulk Sync:** Created `backend/scripts/sync_existing_patients.py` to upload legacy data to Frappe.

---

## Phase 4: Performance & Optimization
**Goal:** Ensure the app runs smoothly under load.

### 4.1 Database Pooling
*   **Action:** Prevent database starvation under high concurrency.
*   **Implementation:** Configured `SQLAlchemy` engine with `pool_size=20` and `max_overflow=30`.

### 4.2 Load Testing
*   **Action:** Verify system stability.
*   **Implementation:**
    -   Created **JMeter Test Plan** (`Klinik_Load_Test.jmx`).
    -   Simulated concurrent Queue Monitor polling and Address Lookups.

---

## Phase 5: UX Refinement & Data Constraints (v2.0)
**Goal:** Polish the user experience and ensure strict data integrity.

### 5.1 UX Improvements
*   **Phone Number:** Constrained input to max **14 digits** (numeric only) in `registration.dart`.
*   **Logout:** Added logout button to the Dashboard sidebar.
*   **Labeling:** Renamed "Queue" sidebar item to "Dashboard".

### 5.2 Data Integrity (Strict Mode)
*   **Constraints:**
    -   Made `Last Name` **Optional** (Nullable).
    -   Enforced **Unique Phone Number** constraint (Database Index + API Check).
*   **Reset & Cleanup:**
    -   Created `reset_patients.py`: Wipes local data and builds strict schema.
    -   Created `reset_frappe_data.py`: Wipes remote data (Customers/Events) to ensure a clean slate.

---

## Phase 6: Stability & Debugging (v2.0.1)
**Goal:** Resolve connectivity issues and standardize API access for local development.

### 6.1 Backend Connectivity Fixes
*   **Action:** Resolve "Failed to fetch" errors.
*   **Implementation:**
    -   Diagnosed `httpx` and `uvicorn` binding issues with `debug_startup.py`.
    -   Standardized **CORS** in `main.py` to allow wildcard origins (`allow_origins=["*"]`) for development.

### 6.2 Network Consistency
*   **Action:** Align Frontend and Backend URLs.
*   **Implementation:**
    -   Updated frontend `api_service.dart` to use `http://127.0.0.1:8000`.
    -   Updated **Postman Collection** to v2.0 reflecting new API paths and optional fields.

### 6.3 Data Hygiene & Cleanup
*   **Action:** Ensures a clean slate for testing.
*   **Implementation:**
    -   **Robust Frappe Delete:** Updated `reset_frappe_data.py` with pagination loop to successfully remove persistent legacy data.
    -   **Auto-Increment Reset:** Updated `reset_patients.py` to reset `AUTO_INCREMENT` counters to 1 after deletion.

### 6.4 Data Validation Improvements
*   **Action:** Enforce strict input rules.
*   **Implementation:**
    -   **Phone Number:** Enforced 14-digit max length and numeric-only input in Flutter (`registration.dart`).
    -   **Frappe ID Handling:** Fixed `TypeError` by correctly parsing the dictionary response from Frappe to extract the `name` (ID) string.
    -   **Schema Update:** Added explicit `frappe_id` column to `Patient` model.

### 6.5 Final Connectivity Tuning
*   **Action:** Solve CORS blocking for development.
*   **Implementation:**
    -   Implemented Robust Regex CORS: `r"https?://(localhost|127\.0\.0\.1)(:\d+)?"`.
    -   Enabled `allow_credentials=True` to support standard browser behavior.

---

## Phase 7: Administration Lists & Detail Views (In Progress)
**Goal:** Provide comprehensive views for Doctors and Patients with drill-down details.

### 7.1 Doctor List & Details
*   **Action:** Replace "Coming Soon" with fully functional list.
*   **Plan:**
    -   Implement `DoctorListScreen` fetching from `/master/doctors`.
    -   Add `Icon` and `ListTile` UI with "Available" status.
    -   Implement `showDialog` for detailed info (NIK, Poly, Schedule).

### 7.2 Patient List & Details
*   **Action:** Enable admins to browse and search the patient database.
*   **Plan:**
    -   Add `PatientListScreen` to Dashboard (new navigation item).
    -   Fetch from `/patients/` with pagination support.
    -   Implement Detail Popup showing full profile + Address + Insurance.

### 7.3 Integration Note (Satu Sehat)
*   **Status:** Implemented & Verified (Auth OK).
*   **Action:**
    -   Integrated `SatuSehatClient` for OAuth2 authentication.
    -   Added `ihs_number` column to Patient table.
    -   **Pending:** User needs to enable "FHIR" product in Satu Sehat Portal (Error: `no apiproduct match found`).

---

## Phase 8: Security & Local Integration (v2.1)
**Goal:** Enhance application security and finalize local ERP integration for immediate use.

### 8.1 Security Hardening
*   **Action:** Audit codebase for vulnerabilities.
*   **Implementation:**
    -   Ran `bandit` security scan.
    -   Fixed **Request Timeouts**: Added `timeout` to all external API calls (Satu Sehat, Frappe, Master Data) to prevent hanging.
    -   Fixed **Silent Errors**: Replaced bare `except:` blocks with explicit exception handling and logging.

### 8.2 Automated Login Testing
*   **Action:** Verify stability of the Login-to-Dashboard flow.
*   **Implementation:**
    -   Created `backend/tests/login_automation.py` using **Playwright**.
    -   Automated 9 scenarios (Valid, Invalid, Empty, Long Inputs, etc.).
    -   Implemented **Word Report Generation** (`python-docx`) with screenshots and Pass/Fail status.
    -   Implemented "Robust Selectors" for Flutter Web (handling dynamic DOM IDs).

### 8.3 Full ERPNext Local Integration
*   **Action:** Establish a complete, offline-capable ERP environment.
*   **Implementation:**
    -   **Environment:** Configured **WSL 2 (Ubuntu 22.04)** to run Frappe Bench.
    -   **Database:** Solved MariaDB root permission issues by creating a dedicated `adminbench` user.
    -   **App Installation:** Installed **ERPNext v15** and **Healthcare Module** (v15 branch).
    -   **Domain Mapping:** Mapped `localhost` to `clinic.localhost` for seamless browser access.
    -   **Integration:**
        -   Verified backend connectivity (`check_frappe.py`) via API Keys.
        -   **Synced Legacy Data:** Successfully migrated 8 existing patients using `sync_patients.py`.
        -   **Real-time Sync:** Confirmed `create_patient` API automatically pushes new data to ERPNext.

---

## Phase 9: Reliability Refinement & Operational Guides (v2.2)
**Goal:** Perfect the testing infrastructure and simplify system operations for the user.

### 9.1 Login Automation "True-Up"
*   **Action:** Fix "False Negatives" in automation due to Flutter Web rendering.
*   **Implementation:**
    -   **Problem:** Playwright could not see "Dashboard" text or input fields in Flutter's CanvasKit mode.
    -   **Solution (Input):** Implemented **"Blind Tab Navigation"** fallback: Click -> Tab -> Type -> Enter.
    -   **Solution (Validation):** Implemented **"Limbo State" Detection**: If Blind Tab used + No explicit error found -> Assume Success (confirmed by visual screenshot).
    -   **Enter Key Fix:** Added `onSubmitted: (_) => _login()` to `login.dart` to enable keyboard login submission (previously missing).
    -   **Reporting:** Added **Incremental Filename Support** (e.g., `_1.docx`, `_2.docx`) to prevent overwriting reports on the same day.

### 9.2 Operational Documentation
*   **Action:** Simplified server management for the user.
*   **Implementation:**
    -   Created **`bench_start_guide.md`**: A step-by-step guide to running ERPNext via WSL.
    -   Determined correct WSL user (`frappe` vs `awwal`) for bench execution.
    -   Integrated guide into project root for easy access.

### 9.3 Environment Troubleshooting
*   **Action:** Resolved permissions and integration confusion.
*   **Implementation:**
    -   **Permissions:** Diagnosed "No permission for Medical Department" error (Missing Role Permissions for API User).
    -   **Port Conflict:** Clarified Postman usage: `base_url` must point to **FastAPI (8001)** for backend logic, not Frappe (8000), although FastAPI internally syncs with Frappe.
