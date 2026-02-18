## 1. Visual Tokens (Confirmed from `mobile-apps`)

- **Primary Color**: `#2859E2` (Intimedicare Blue)
- **Scaffold Background**: `#F8FAFC`
- **Typography**: `Outfit` (Google Fonts)
- **Border Radius**: 16px - 24px (Large rounded corners)
- **Header Font Color**: `#1E293B`

---

## 2. Layout Definitions

### A. Auth Layout (Login)

*Centered card layout for authentication.*

- **Background**: Gradient or clinic branding image
- **Card**: Centered, max-width 400px
- **Logo**: Top of card
- **Form**: Username, Password, Login button

### B. Sidebar Layout (Main App)

*Fixed sidebar on the left, scrollable content on the right.*

```
┌────────────────────────────────────────────────────────────┐
│ ┌─────────┐ ┌────────────────────────────────────────────┐ │
│ │         │ │  Header: Page Title + User Avatar          │ │
│ │         │ ├────────────────────────────────────────────┤ │
│ │ Sidebar │ │                                            │ │
│ │  250px  │ │           Main Content Area                │ │
│ │         │ │            (Scrollable)                    │ │
│ │         │ │                                            │ │
│ │         │ │                                            │ │
│ └─────────┘ └────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────┘
```

- **Sidebar (Width: 250px)**:
  - Logo (Top)
  - Navigation Links (Middle): Dashboard, Registrasi, Queue Monitor, Janji Temu
  - User Profile (Bottom): Avatar + Name + Logout
- **Main Content**:
  - Header bar with page title and breadcrumbs
  - Content container with padding
- **Mobile Behavior**: Sidebar becomes hamburger menu drawer

---

## 3. Page Specifications (Wireframes)

### Page: Dashboard (`/dashboard`)

#### Zone 1: Header

```
┌─────────────────────────────────────────────────────────────┐
│  Dashboard                              [User Avatar] Admin │
└─────────────────────────────────────────────────────────────┘
```

#### Zone 2: Stats Grid (4 Columns)

```
┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ 👥 23        │ │ ⏳ 12         │ │ ✅ 45        │ │ 📅 8         │
│ In Queue     │ │ Waiting      │ │ Completed    │ │ Appointments │
│ Today        │ │ Now          │ │ Today        │ │ Today        │
└──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘
```

#### Zone 3: Quick Actions

```
┌──────────────────────────────────────────────────────────────┐
│  Quick Actions                                               │
│  ┌─────────────────┐  ┌─────────────────┐                   │
│  │ + New Patient   │  │ 🔍 Find Patient │                   │
│  └─────────────────┘  └─────────────────┘                   │
└──────────────────────────────────────────────────────────────┘
```

---

### Page: New Patient Registration (`/registration/new`)

#### Zone 1: Progress Stepper

```
┌─────────────────────────────────────────────────────────────┐
│  Step 1        Step 2         Step 3          Step 4        │
│  [●]──────────[○]────────────[○]─────────────[○]           │
│  Personal     Medical        Address         Confirmation   │
└─────────────────────────────────────────────────────────────┘
```

#### Zone 2: Form - Personal Info

```
┌─────────────────────────────────────────────────────────────┐
│  Personal Information                                        │
├─────────────────────────────────────────────────────────────┤
│  First Name *              Last Name                         │
│  ┌─────────────────────┐   ┌─────────────────────┐          │
│  │                     │   │                     │          │
│  └─────────────────────┘   └─────────────────────┘          │
│                                                              │
│  NIK *                     Phone Number *                    │
│  ┌─────────────────────┐   ┌─────────────────────┐          │
│  │ 16 digits required  │   │ +62...              │          │
│  └─────────────────────┘   └─────────────────────┘          │
│                                                              │
│  Birthday *                                                  │
│  ┌─────────────────────┐                                    │
│  │ 📅 Choose Date      │                                    │
│  └─────────────────────┘                                    │
│                                                              │
│                              ┌───────────┐ ┌───────────────┐│
│                              │  Cancel   │ │ Next Step →   ││
│                              └───────────┘ └───────────────┘│
└─────────────────────────────────────────────────────────────┘
```

#### Zone 3: Form - Medical & Profiling

```
┌─────────────────────────────────────────────────────────────┐
│  Medical & Profiling                                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Height (cm)               Weight (Kg)                       │
│  ┌─────────────────────┐   ┌─────────────────────┐          │
│  │                     │   │                     │          │
│  └─────────────────────┘   └─────────────────────┘          │
│                                                              │
│  Gender *                  Religion *                        │
│  ┌─────────────────────▼┐  ┌─────────────────────▼┐         │
│  │ Select...            │  │ Select...            │         │
│  └──────────────────────┘  └──────────────────────┘         │
│                                                              │
│  Marital Status *          Education *                       │
│  ┌─────────────────────▼┐  ┌─────────────────────▼┐         │
│  │ Select...            │  │ Select...            │         │
│  └──────────────────────┘  └──────────────────────┘         │
│                                                              │
│  Profession                                                  │
│  ┌─────────────────────┐                                    │
│  │ Optional            │                                    │
│  └─────────────────────┘                                    │
└─────────────────────────────────────────────────────────────┘
```

#### Zone 4: Form - Address

```
┌─────────────────────────────────────────────────────────────┐
│  Address Information                                         │
├─────────────────────────────────────────────────────────────┤
│  Province *                City *                            │
│  ┌─────────────────────▼┐  ┌─────────────────────▼┐         │
│  │ Select Province      │  │ Select City          │         │
│  └──────────────────────┘  └──────────────────────┘         │
│                                                              │
│  Kabupaten *               Kecamatan *                       │
│  ┌─────────────────────▼┐  ┌─────────────────────▼┐         │
│  │ Select Kabupaten     │  │ Select Kecamatan     │         │
│  └──────────────────────┘  └──────────────────────┘         │
│                                                              │
│  RT          RW           Postal Code                        │
│  ┌────────┐  ┌────────┐   ┌────────────────────┐            │
│  │        │  │        │   │                    │            │
│  └────────┘  └────────┘   └────────────────────┘            │
│                                                              │
│  Full Address *                                              │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                                                         ││
│  │                                                         ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

---

### Page: Existing Patient Search (`/registration/existing`)

```
┌─────────────────────────────────────────────────────────────┐
│  Find Existing Patient                                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Search by Full Name, Phone Number, or NIK                               │
│  ┌───────────────────────────────────┐  ┌────────────────┐  │
│  │ Enter name, phone or NIK...      │  │ 🔍 Search      │  │
│  └───────────────────────────────────┘  └────────────────┘  │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│  Search Result:                                              │
│  ┌─────────────────────────────────────────────────────────┐│
│  │  👤 John Doe                                            ││
│  │  NIK: ************3456 | Phone: 0812-3456-7890          ││
│  │  DOB: 15 May 1990 | Gender: Male                       ││
│  │                                                         ││
│  │                                                         ││
│  │  ┌──────────────────────┐  ┌────────────────────────┐   ││
│  │  │ ❌ Not This Patient  │  │ ✅ Confirm & Continue  │   ││
│  │  └──────────────────────┘  └────────────────────────┘   ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

---

### Page: Doctor/Polyclinic Selection (`/registration/select-doctor`)

```
┌─────────────────────────────────────────────────────────────┐
│  Select Destination                                          │
├─────────────────────────────────────────────────────────────┤
│  Patient: John Doe (NIK: ************3456)                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌───────────────────────┐  ┌───────────────────────┐       │
│  │  ○ Doctor             │  │  ○ Polyclinic         │       │
│  └───────────────────────┘  └───────────────────────┘       │
│                                                              │
│  Select Doctor                                               │
│  ┌─────────────────────────────────────────────────────────▼┐│
│  │ Choose Doctor...                                         ││
│  └──────────────────────────────────────────────────────────┘│
│                                                              │
│  ┌──────────────────────────────────────────────────────────┐│
│  │  ☐ Priority Queue                                        ││
│  │  Check if patient needs immediate attention              ││
│  └──────────────────────────────────────────────────────────┘│
│                                                              │
│                              ┌───────────┐ ┌───────────────┐│
│                              │  Back     │ │ Continue →    ││
│                              └───────────┘ └───────────────┘│
└─────────────────────────────────────────────────────────────┘
```

---

### Page: Queue Monitor (`/queue`)

```
┌─────────────────────────────────────────────────────────────┐
│  Queue Monitor                    [🔄 Refresh] [📢 Mute]     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────────────────────────┐  ┌─────────────────────┐│
│  │      NOW SERVING               │  │  NEXT IN LINE       ││
│  │  ┌────────────────────────┐    │  │                     ││
│  │  │        D-003           │    │  │  1. DP-002 (Priority)│
│  │  │     John Doe           │    │  │  2. D-004           ││
│  │  │   dr. Smith            │    │  │  3. D-005           ││
│  │  └────────────────────────┘    │  │                     ││
│  │                                │  │                     ││
│  │  ┌──────────┐ ┌──────────────┐ │  │                     ││
│  │  │ 📞 Call  │ │ ✅ Completed │ │  │                     ││
│  │  │  Next    │ │              │ │  │                     ││
│  │  └──────────┘ └──────────────┘ │  │                     ││
│  └────────────────────────────────┘  └─────────────────────┘│
│                                                              │
├─────────────────────────────────────────────────────────────┤
│  Full Queue List                                             │
│  ┌──────┬───────────────┬────────────┬──────────┬──────────┐│
│  │ No.  │ Patient       │ Doctor     │ Wait     │ Status   ││
│  ├──────┼───────────────┼────────────┼──────────┼──────────┤│
│  │DP-002│ Jane Priority │ dr. Smith  │ 5 min    │ 🟡WAITING ││
│  │ D-004│ Bob Regular   │ dr. Smith  │ 15 min   │ 🟡WAITING ││
│  │ D-005│ Alice Regular │ dr. Johnson│ 10 min   │ 🟡WAITING ││
│  │ P-001│ Charlie       │ Poli Umum  │ 8 min    │ 🟡WAITING ││
│  └──────┴───────────────┴────────────┴──────────┴──────────┘│
└─────────────────────────────────────────────────────────────┘
```

---

### Page: Appointments (`/appointments`)

```
┌─────────────────────────────────────────────────────────────┐
│  Today's Appointments                        📅 2026-02-02   │
├─────────────────────────────────────────────────────────────┤
│  Filters: [All Doctors ▼] [Date Range: Today ▼]             │
├─────────────────────────────────────────────────────────────┤
│  ┌──────┬───────────────┬──────────────┬───────┬───────────┐│
│  │ Time │ Patient       │ Doctor       │Status │ Action    ││
│  ├──────┼───────────────┼──────────────┼───────┼───────────┤│
│  │09:00 │ Maria Santos  │ dr. Smith    │🟢CONF │ [Check-in]││
│  │09:30 │ Peter Parker  │ dr. Johnson  │🟡SCHED│ [Check-in]││
│  │10:00 │ Tony Stark    │ dr. Smith    │🟢CONF │ [Check-in]││
│  │10:30 │ Bruce Wayne   │ dr. Wilson   │🔴CANC │ -         ││
│  │11:00 │ Clark Kent    │ dr. Johnson  │🟢CONF │ [Check-in]││
│  └──────┴───────────────┴──────────────┴───────┴───────────┘│
│                                                              │
│  Legend: 🟢 Confirmed  🟡 Scheduled  🔴 Cancelled           │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. Interaction Rules

### Form Validation

- Show inline error messages below invalid fields
- Highlight invalid fields with red border
- Disable submit button until all required fields are valid

### Loading States

- Show skeleton loaders while fetching data
- Show spinner on buttons during submission
- Disable form during API calls

### Toast Notifications

- Success: Green, top-right, auto-dismiss 3s
- Error: Red, top-right, dismiss on click
- Warning: Yellow, requires user action

### Modals

- Confirmation dialogs for destructive actions
- Patient details preview before registration

### Responsive Breakpoints

- Desktop: > 1024px (Full sidebar)
- Tablet: 768px - 1024px (Collapsible sidebar)
- Mobile: < 768px (Hamburger menu)

---

## 5. Flutter Project Structure

```
lib/
├── main.dart
├── app.dart
├── config/
│   ├── routes.dart
│   ├── theme.dart
│   └── constants.dart
├── models/
│   ├── patient.dart
│   ├── queue_entry.dart
│   ├── appointment.dart
│   └── doctor.dart
├── services/
│   ├── api_service.dart
│   ├── auth_service.dart
│   └── queue_service.dart
├── providers/
│   ├── patient_provider.dart
│   ├── queue_provider.dart
│   └── auth_provider.dart
├── screens/
│   ├── login/
│   ├── dashboard/
│   ├── registration/
│   │   ├── new_patient_screen.dart
│   │   ├── existing_patient_screen.dart
│   │   ├── select_doctor_screen.dart
│   │   └── payment_screen.dart
│   ├── queue/
│   │   └── queue_monitor_screen.dart
│   └── appointments/
│       └── appointments_screen.dart
├── widgets/
│   ├── sidebar.dart
│   ├── patient_card.dart
│   ├── queue_item.dart
│   └── form_fields/
└── utils/
    ├── validators.dart
    └── formatters.dart
```
