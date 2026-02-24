# Documentation Hub: Clinic Intimedicare

Welcome to the Clinic Intimedicare documentation hub. This repository contains the product and technical documentation for the clinic management system.

## Authentication

The application uses a simplified authentication system for clinic staff:

- **Primary Auth**: Email and Password.
- **Account Creation**: Internal staff accounts are managed through the backend (Frappe/Clinic Admin panel).
- **Security**: Google Sign-In, Public Registration, and Guest Access are disabled.

## Modules

### FrontDesk

The FrontDesk module handles patient registration, queue management, and appointment monitoring.

- **[PRD](product/frontdesk-prd.md)**: Product Requirements Document.
- **[User Flows](product/user-flows.md)**: User journeys and operational diagrams.
- **[App Structure](product/app-structure.md)**: Flutter project structure and architecture.
- **[API Spec](tech/frontdesk-api-spec.md)**: FrontDesk API endpoints.

### Documentation Structure

```
docs/
├── README.md                      # This file
├── product/
│   ├── frontdesk-prd.md           # Product requirements
│   ├── user-flows.md              # User journey diagrams
│   ├── user-stories.md            # User stories
│   └── app-structure.md           # Flutter architecture
├── tech/
│   ├── frontdesk-api-spec.md      # FrontDesk API specification
│   ├── doctor-api-spec.md         # Doctor module API specification
│   ├── api-inventory.md           # Full API inventory
│   ├── database-schema.md         # Database schema reference
│   ├── backend-migration.md       # Migration guide (FastAPI → Frappe)
│   └── mysql-integration.md       # External MySQL sync docs
└── standards/
    └── api-guidelines.md          # API coding standards
```

## Backend Integration

### Production: Frappe (`api_clinic`)

The primary backend is the `api_clinic` Frappe app running on WSL.

- **Base URL**: `http://localhost:8000/api`
- **Primary API Module**: `api_clinic.api`
- **DocType APIs**:

| DocType | Purpose |
|---|---|
| `Clinic Patient` | Patient registration and search |
| `Clinic FrontDesk Queue` | Queue management |
| `Clinic Polyclinic` | Polyclinic names |
| `Clinic Practitioner` | Doctor data |
| `Clinic Payment` | Payment methods (Cash, QRIS, Debit Card, Credit Card, Insurance) |
| `Clinic Appointment` | Appointment scheduling |
| `Clinic Staff Profile` | Staff profile (Role, Company, Facility, Specialization, STR) |
| `Clinic Encounter` | Clinical encounter records |

## Key Features

- **Queue Management**:
  - **Queue Lifecycle**: `Waiting → Consultation → Pharmacy → Payment → Completed`
  - **Status Cards**: 5 stat cards at the top of Queue Monitor
  - **Status Placement**:
    - `Waiting` → Waiting Card
    - `Consultation`, `Pharmacy`, `Payment` → Antrian Dokter & Antrian Polyclinic cards
    - `Completed` → Queue → History submenu
  - **Daily Statistics**: Stat cards reset every day (WIB)
  - **Queue Numbering**: Reset automatically to D-001/P-001 at start of each day
  - **External App Integration**: Doctor/Pharmacy/Payment apps advance queue status via `advance_queue_status` API
- **Payment Integration**: Payment methods fetched from `Clinic Payment` DocType options
- **Responsive UI**: Adaptive layout for mobile, tablet, and desktop
- **External MySQL Sync**: Patient registrations and queue entries synced to `klinik_db`
- **Cross-Database Search**: Patient search falls back to MySQL if not found in Frappe
- **Staff Profile**: Shows Role, Company, Facility, Specialization, and STR Number from `Clinic Staff Profile`
- **Age Calculation**: Automatic formatting as `X Tahun X Bulan X Hari`
- **Auto-Logout**: Session expires after 15 minutes of inactivity

## Responsive Design

| Device | Screen Width | Navigation | Layout |
| --- | --- | --- | --- |
| 📱 Mobile | < 600px | Bottom Navigation | Single column |
| 📱 Tablet | 600 - 1024px | Side Rail (icons, 80px) | Flexible grid |
| 💻 Desktop | > 1024px | Side Navigation (full, 240px) | Multi-column |

### Breakpoints (`lib/core/utils/responsive.dart`)

```dart
static const double mobileBreakpoint = 600;
static const double tabletBreakpoint = 1024;
static const double desktopBreakpoint = 1440;
```

## Troubleshooting

### Windows to WSL Sync

If you encounter **500 Server Errors**, sync the `api_clinic` app:

```bash
# Sync files
cp -r /mnt/c/Users/1672/.gemini/antigravity/scratch/app-clinic-frontdesk/api-clinic/api_clinic/* /home/frappe/frappe-bench/apps/api_clinic/api_clinic/

# Run migration
cd /home/frappe/frappe-bench && bench --site clinic.localhost migrate
```

> [!IMPORTANT]
> After adding new fields to a DocType JSON, you **MUST** run `bench migrate` to update database tables.

## Recent Updates

### v3.0 - Feb 24 2026 (Current)

- **Queue Status Flow Overhaul**:
  - New lifecycle: `Waiting → Consultation → Pharmacy → Payment → Completed`
  - 5 stat cards in Queue Monitor
  - External apps (Doctor/Pharmacy/Payment) advance status via API
- **DocType API Integration**:
  - Payment methods from `Clinic Payment` DocType
  - Profile from `Clinic Staff Profile` DocType
  - All endpoints use real Frappe DocType APIs
- **Codebase Cleanup**: Removed debug scripts, unused templates, and test artifacts

### v2.0 - v2.10 (Feb 2026)

- Queue Menu Refactoring (Monitor + History submenus)
- Appointment Registration with Doctor/Polyclinic toggle
- Appointment Status Auto-Update (Pending → Checked In)
- Smart Registration System with auto-fill
- External MySQL Sync for Patient/Queue data
- Responsive UI with adaptive layouts
