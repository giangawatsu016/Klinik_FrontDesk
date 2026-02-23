# Documentation Hub: Clinic Intimedicare

Welcome to the Clinic Intimedicare documentation hub. This repository contains the product and technical documentation for the clinic management system.

## Authentication

The application uses a simplified authentication system for clinic staff:

- **Primary Auth**: Email and Password.
- **Removed Options**: Google Sign-In, Public Registration, and Guest Access have been removed to ensure better security and control over staff access.
- **Account Creation**: Internal staff accounts are managed through the backend (Frappe/Clinic Admin panel).

## Modules

### FrontDesk

The FrontDesk module handles patient registration, queue management, and appointment monitoring.

- **[PRD](product/frontdesk-prd.md)**: Product Requirements Document.
- **[User Flows](product/user-flows.md)**: User journeys and operational diagrams.
- **[API Inventory](tech/api-inventory.md)**: Backend endpoints for Frappe integration.
- **[Database Schema](tech/database-schema.md)**: Data structures for Patients, Queues, Appointments, Doctors, and Services.

### Appointments

The Appointment module manages patient scheduling and doctor availability.

- **[API Inventory](tech/api-inventory.md)**: Includes endpoints for managing clinical appointments.
- **Key Features**:
- Real-time slot availability.
- Alphanumeric ID support (`APP-YYYY-XXXXX`).

## Backend Integration

The application supports two backend modes:

### Production: Frappe (`api_clinic`)

The primary backend is the `api_clinic` Frappe app running on WSL/Docker.

- **Base URL**: `http://localhost:8000/api`
- **Primary Source**: Real-time data from `api_clinic` module.
- **Queue Logic**: Backend handles queue numbering (`FDQ-...`) while Frontend handles display prioritization.
- **Endpoints**:
  - `clinicfrontdesk.api.register_patient` — Syncs to MySQL `patientcore` ✅
  - `clinicfrontdesk.api.search_patient` — Fallback to MySQL `patientcore` ✅
  - `clinicfrontdesk.api.add_to_queue` — Syncs to MySQL `patientqueue` ✅
  - `clinicfrontdesk.api.get_queue`
  - `clinicfrontdesk.api.update_queue_status` — Syncs status to MySQL ✅
  - `clinicfrontdesk.api.get_practitioners` — Merges from MySQL `doctorcore` ✅
  - `clinicfrontdesk.api.get_polyclinics`
  - `clinicfrontdesk.api.get_notifications`

### Development Fallback: FastAPI Mock (`backend/server.py`)

A lightweight FastAPI mock server for rapid frontend development without Frappe.

- **Base URL**: `http://localhost:8080/api`
- **Start**: `python.exe .\server.py` from the `backend/` directory.
- **Data**: In-memory mock data; resets on restart.

### Migration Documentation

For detailed field mappings, API endpoint mapping, and environment configuration, see:

- **[Backend Migration Guide](tech/backend-migration.md)**: Complete migration reference from FastAPI mock to Frappe.
- **[MySQL Integration Guide](tech/mysql-integration.md)**: External database sync with `klinik_db`.
- **Reference Codebase**: `Klinik_Admin V.01` (FastAPI backend with SQLAlchemy + SQLite).

## Templates

### Postman Collections

- **[Clinic Appointment API](templates/postman_clinic_appointment.json)**: API requests for managing appointments (Janji Temu).

## Key Features

- **Queue Management**:
  - **Queue Monitor**: The active queue list (Waiting/Called) only displays entries created on the current date (WIB). Previous days' pending entries are automatically filtered out from the monitor.
  - **Daily Statistics**: The "Completed" statistic card at the top of the Queue Monitor resets every day (WIB). Only entries completed on the current date are counted.
  - **All-Time History**: Now moved to a dedicated **"History"** submenu under the Queue menu. Displays the historical record of all completed queue entries.
  - **Queue Numbering**: Reset automatically to D-001/P-001 at the start of each day by the backend.
  - **Appointment History Search**:
    - Refined search functionality specifically for past appointments (COMPLETED/CANCELLED).
    - **Manual Search**: If the search query is empty, a full list of history records is displayed for manual browsing.
    - **Backend Limit**: API updated to fetch up to 1000 recent records (default 20) to ensure historical context is available.
- **Payment Integration**: Supports Cash, BPJS, Insurance, and Credit Card payments.
- **Responsive UI**: Adaptive layout for mobile, tablet, and desktop devices.
- **Unified Detail Views**: Clean, professional detail pages for Appointments and Medical Records with solid brand colors.
- **Real-time Master Data**: Fetches Practitioners and Polyclinic directly from Frappe backend.
- **External MySQL Sync**: All patient registrations and queue entries are synced in real-time to `klinik_db` MySQL database via `db_external.py`.
- **Cross-Database Search**: Patient search automatically falls back to MySQL `patientcore` if not found in Frappe.
- **Queue Duplicate Prevention**: Patients cannot register for queue if they already have an active entry today.
- **Staff Profile Details**: View logged-in staff information including Name, Role (Admin/Staff/Doctor), and Staff ID (NIP).
- **Detailed Appointment Views**: Complete patient information (Name, Formatted Age, Phone) and doctor license (SIP) details in the Appointment Detail page.
- **Strict Appointment Reorganization**:
  - **Jadwal Kunjungan**: Now strictly displays **Today's and Future** active appointments (`PENDING`, `SCHEDULED`, `CONFIRMED`, `ARRIVED`). This ensures the front desk focuses only on upcoming patient arrivals.
  - **History Submenu**: Now displays all **Past** appointments and **Finalized** appointments from any date (including `COMPLETED`, `CANCELLED`, `PAID`, `CHECKED IN`).
- **Quick Queue Access**: Direct "Add to Queue" button from the Visit Schedule list (visible for today's appointments) for seamless patient check-in. Clicking the button automatically navigates to the Queue Monitor.
- **Age Calculation**: Automatic formatting of patient age as `X Tahun X Bulan X Hari` for clinical precision.

## Responsive Design

The application uses adaptive layouts based on screen width:

| Device | Screen Width | Navigation | Layout |
| --- | --- | --- | --- |
| 📱 Mobile | < 600px | Bottom Navigation | Single column |
| 📱 Tablet | 600 - 1024px | Side Rail (icons only, 80px) | Flexible grid |
| 💻 Desktop | > 1024px | Side Navigation (full, 240px) | Multi-column |

### Breakpoints (lib/core/utils/responsive.dart)

```dart
static const double mobileBreakpoint = 600;
static const double tabletBreakpoint = 1024;
static const double desktopBreakpoint = 1440;
```

### Helper Extensions

```dart
// Check device type
context.isMobile   // true if width < 600
context.isTablet   // true if 600 <= width < 1024
context.isDesktop  // true if width >= 1024

// Responsive values
context.responsivePadding        // EdgeInsets based on device
context.gridColumns              // 1 (mobile), 2 (tablet), 3 (desktop)
context.maxContentWidth          // Centered content max width
```

### Responsive Widgets

- **`ResponsiveLayout`**: Builds different widgets based on screen size
- **`ResponsiveCenter`**: Centers content with max width constraint
- **`ResponsiveGrid`**: Adjusts grid columns based on screen size

## Mock Data (Demo Mode)

When the backend API is unavailable or for specific modules not yet integrated, the app falls back to mock data:

### Home Services

| Data        | Count        | Details                                                     |
|-------------|--------------|-------------------------------------------------------------|
| Services    | 5            | Konsultasi Umum, Pemeriksaan Anak, Kulit, Gigi, Home Care   |
| Price Range | Rp 150k-500k | With discount examples                                      |

### Payment History

| Data     | Count | Details                      |
|----------|-------|------------------------------|
| Payments | 3     | QRIS, CASH, BPJS methods     |
| Status   | Mixed | PAID and PENDING examples    |

- **Enhanced Logout Features**:
  - **Sidebar Logout**: Quick-access logout button available in the side navigation for tablet and desktop views.
  - **Auto-Logout After Idle**: The application automatically logs out the user after **15 minutes** of inactivity (no pointer/keyboard movement).
    - A warning dialog appears **1 minute** before the session expires.
  - **Logout From All Devices**: Invalides all active sessions across all devices, ensuring immediate security if a device is lost or compromised.
  - **Profile Page Security**: Both regular and multi-device logout options are conveniently located at the bottom of the Profile page.

  #### Technical Implementation (`IdleDetector`)

  The idle handling is implemented using the `IdleDetector` widget (`lib/core/services/idle_detector.dart`), which is placed at the top of the widget tree. To ensure it has access to the `Navigator` and `Localizations` (which are provided by `MaterialApp`), it uses the `NavigationService` to access the global `navigatorKey`.

  - **Global Key**: `NavigationService().navigatorKey`
  - **Context Access**: `NavigationService().navigatorKey.currentContext`

## Development Automation

To simplify the development workflow, a startup script is provided to run both backend and frontend in the background.

- **[start_dev.ps1](file:///c:/Users/1672/.gemini/antigravity/scratch/app-clinic-frontdesk/start_dev.ps1)**: PowerShell script to launch both services.

### Usage

1. Open PowerShell in the project root.
2. Run the script:

   ```powershell
   ./start_dev.ps1
   ```

3. Monitor logs if needed:

   ```powershell
   Get-Job
   Receive-Job -Name IntimedicareBackend -Keep
   Receive-Job -Name IntimedicareFrontend -Keep
   ```

## Troubleshooting & Environment

### Windows to WSL Sync

If you encounter **500 Server Errors** or **DocType Missing** errors in the app, it is likely because the `api_clinic` app source in WSL is out of sync with the Windows development folder.

**Symptom**: `ProgrammingError: ('DocType', 'Clinic FrontDesk Queue')` in Frappe logs.

**Fix**:

1. Sync files via WSL mount:

   ```bash
   cp -r /mnt/c/Users/1672/.gemini/antigravity/scratch/app-clinic-frontdesk/api-clinic/api_clinic/* /home/frappe/frappe-bench/apps/api_clinic/api_clinic/
   ```

2. Run migration:

   ```bash
   cd /home/frappe/frappe-bench && bench --site clinic.localhost migrate
   ```

> [!IMPORTANT]
> **Database Schema Sync**: If you've added new fields (like `payment_method`) to a DocType via JSON, simply syncing the files to WSL is not enough. You MUST run `bench migrate` to update the actual database tables, otherwise the API may crash or return empty results.

- Use explicit field names matching the Frappe DocTypes.

## Recent Updates (v2.0 - Feb 2026)

### Functional Enhancements

- **Lazy Sync**: Automatically syncs Patient/Doctor/Facility/Queue data from external MySQL to Frappe when adding to queue.
- **Improved ID Generation**: Switched Patient and Queue ID generation to `hash` to prevent duplicate entry errors.

### Fixes

- **Queue Monitor**: Resolved display issues with duplicate entries.
- **Search**: Fixed issue with existing patient searches returning incomplete data.

### v2.7 - Feb 18 2026 (Current)

- **Queue Menu Refactoring**:
  - Split "Queue" menu into two submenus: **Queue Monitor** and **History**.
  - **Queue Monitor**: Dedicated screen for active daily queues, removing previous days' clutter.
  - **History**: Dedicated screen for viewing all-time queue history with pagination.
  - Improved navigation flow to match the "Appointments" menu structure.

### v2.10 - Feb 18 2026 (Current)

- **Appointment Registration Enhancement**:
  - The "Add Visit Schedule" (Registrasi) form now supports selecting **Doctor OR Polyclinic** via radio toggle buttons.
  - When "Doctor" is selected, a Doctor dropdown is shown. When "Polyclinic" is selected, a Polyclinic dropdown is shown.
  - Backend `Clinic Appointment` doctype updated: `practitioner` and `polyclinic` fields are now optional to support flexible scheduling.
  - Backend API (`appointment_api.py`) updated to accept and process the `polyclinicName` field from request data.
  - **Fixed Dropdown Loading**: Resolved issue where Doctor/Polyclinic lists showed "Loading..." due to the shared `FrontDeskBloc` overwriting the `PractitionersAndPolyclinicsLoaded` state. Switched from `BlocBuilder` to cached state variables populated via `BlocListener`.

### v2.9 - Feb 18 2026

- **Appointment Status Auto-Update**:
  - Clicking "Add to Queue" on an appointment now automatically changes its status from `Pending` → `Checked In`.
  - `Checked In` appointments are sorted to the bottom of the visit schedule list.
  - Blue status badge for `Checked In` appointments; "Add to Queue" button hidden once checked in.

### v2.8 - Feb 18 2026

- **"Add to Queue" Button Fix**:
  - Fixed date comparison using WIB timezone conversion to correctly enable the button for today's appointments.
  - Added automatic navigation to Queue Monitor after successful check-in.
  - Added unit tests for the `AddToQueueEvent` bloc flow (success and failure cases).

### v2.6 - Feb 16 2026

- **Appointment UX & Stability**:
  - Implemented **Reactive Doctor Lists** in the appointment registration form, ensuring the dropdown is always populated accurately even if master data loads late.
  - Added **Auto-Navigation** logic that seamlessly redirects the user to the "Jadwal Kunjungan" history list upon successful appointment creation.
  - Fixed a critical `MandatoryError` in the backend by implementing automatic resolution for `polyclinic` and `facility` fields during appointment creation.
  - Standardized `service_type` mapping to ensure compatibility with backend DocType options.

### v2.5 - Feb 16 2026

- **Smart Registration System**:
  - Unified "New" and "Existing" patient forms into a single **Smart Form**.
  - Implemented **Auto-fill logic** with disambiguation dialog for duplicate search results.
  - Enhanced search to handle multi-word queries and fallback to external MySQL correctly.
- **Hierarchical Navigation**:
  - Moved Appointment sub-functions ("Jadwal Kunjungan" and "Registrasi") into an **expandable sidebar menu**.
  - Removed redundant header buttons to improve UI focus.
- **Backend Stability**:
  - Fixed a critical search bug in `api.py` caused by environment sync issues in WSL.
  - Optimized `db_external.py` for multi-result retrieval.

### v2.3 - Feb 13 2026

- **External Database Stability**:
  - Implemented real-time synchronization for `called_at` and `completed_at` timestamps in the `patientqueue` table.
  - Resolved `NullPointerException` risks in field mappings for doctor and polyclinic IDs.
- **Frontend Restoration**:
  - Fully restored the notification feature suite, including `NotificationCubit` and `NotificationListPage`.
  - Fixed malformed UI code in `home_page.dart` causing compilation failures.
