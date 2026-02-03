# Documentation Hub: Klinik_Admin

Welcome to the Klinik_Admin documentation hub. This repository contains the product and technical documentation for the Klinik management system.

## Modules

### FrontDesk

The FrontDesk module handles patient registration, queue management, and appointment monitoring.

- **[PRD](product/frontdesk-prd.md)**: Product Requirements Document.
- **[User Flows](product/user-flows.md)**: User journeys and operational diagrams.
- **[Database Schema](tech/database-schema.md)**: Data structures for Patients, Queues, Appointments, Doctors, and Services.
- **[API Inventory](tech/api-inventory.md)**: Backend endpoints for Frappe integration.

## Templates

### Postman Collections

- **[Clinic Appointment API](templates/postman_clinic_appointment.json)**: API requests for managing appointments (Janji Temu).

## Key Features

- **Daily Queue Reset**: Queue data automatically resets at 00:00 WIB (UTC+7).
- **Payment Integration**: Supports Cash, BPJS, Insurance, and Credit Card payments.
- **Responsive UI**: Adaptive layout for mobile, tablet, and desktop devices.
- **Mock Data Fallback**: All menus work offline with sample data.
- **Queue Duplicate Prevention**: Patients cannot register for queue if they already have an active entry.

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

When the backend API is unavailable, the app uses mock data for demonstration:

### FrontDesk Queue Monitor

| Data          | Count | Details                                      |
|---------------|-------|----------------------------------------------|
| Queue Entries | 2     | Doctor queue (D-001, D-002) with daily reset |

### Appointment (Janji Temu)

| Data            | Count | Details                                                     |
|-----------------|-------|-------------------------------------------------------------|
| Doctors         | 3     | Sarah Wilson (GP), James Carter (Sp.A), Emily Chen (Sp.KK)  |
| Appointments    | 3     | Statuses: PAID, IN_PROGRESS, UPCOMING                       |
| Medical Records | 1     | Sample diagnosis with doctor info                           |

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

### Registration (Doctors & Polyclinics)

| Data            | Count | Details                                         |
|-----------------|-------|-------------------------------------------------|
| Doctor List     | 5     | With specializations (Umum, Anak, Gigi, Kulit)  |
| Polyclinic List | 6     | Poli Umum, Gigi, Anak, Kulit, Mata, Kebidanan   |

## Documentation Standards

- Keep documentation up to date with implementation.
- Use Mermaid diagrams for flows and architectures.
- Use explicit field names matching the Frappe DocTypes.
