# User Flows: FrontDesk Module

This document visualizes the user journeys for the FrontDesk module.

## 1. Patient Registration Flow

```mermaid
graph TD
    A[Start] --> B{Patient Type?}
    B -- New --> C[Fill Registration Form]
    C --> D[Personal Info, Medical, Background, Address]
    D --> E[Click Register Button]
    
    B -- Existing --> F[Search NIK / Phone]
    F --> G{Found?}
    G -- Yes --> H[Verify Data & Add to Queue]
    G -- No --> C
    
    E --> I[Visit Options Dialog]
    H --> I
    
    I --> J[Select Doctor/Polyclinic]
    J --> K{Priority?}
    K -- Yes --> L[Check Priority Box]
    K -- No --> M[Continue]
    
    L --> N[Payment Dialog]
    M --> N
    
    N --> O{Payment Method}
    O --> P[Cash / BPJS / Insurance / Credit Card]
    P --> Q[Confirm Payment]
    Q --> R[Added to Queue Monitor]
    R --> S[End]
```

## 2. Queue Monitoring Flow

```mermaid
graph TD
    A[Queue Monitor Dashboard] --> B{Queue Type?}
    B -- Doctor --> C[Format: D-xxx]
    B -- Polyclinic --> D[Format: P-xxx]
    
    C --> E[Display in Waiting List]
    D --> E
    
    E --> F{Priority Patient?}
    F -- Yes --> G[Move to Top of List]
    F -- No --> H[Add to Bottom of List]
    
    G --> I[Receptionist View]
    H --> I
    
    I --> J[Click Call Button]
    J --> K[Status: Called]
    K --> L[Show in Currently Serving Section]
    L --> M[Patient In Consultation]
    M --> N[Click Done Button]
    N --> O[Status: Completed]
    O --> P[Move to History List]
    P --> Q[Visible in Monitor History]
    Q --> S[End]
```

## 3. Session Security & Logout Flow

```mermaid
graph TD
    A[User Logged In] --> B{Inactivity?}
    B -- Yes > 14m --> C[Show Auto-Logout Warning]
    C --> D{User Action?}
    D -- Yes --> E[Reset Timer & Stay Logged In]
    D -- No > 1m --> F[Auto-Logout Triggered]
    
    B -- Manual --> G[User Clicks Logout]
    G --> H{Clear All?}
    H -- Yes --> I[Logout From All Devices]
    H -- No --> J[Regular Logout]
    
    F --> K[Clear Local Token & Cache]
    I --> K
    J --> K
    K --> L[Navigate to Login Screen]
```

## 4. Janji Temu History Search

```mermaid
graph TD
    A[Clinic Backend] --> B[FrontDesk Janji Temu Menu]
    B --> C[Click Search Icon]
    C --> D{Search Box?}
    D -- Empty --> E[Show Full History List]
    D -- Typed --> F[Filter History by Patient/Doctor]
    E --> G[View Past Record Details]
    F --> G
```

## 5. Appointment Registration Flow (Doctor or Polyclinic)

```mermaid
graph TD
    A[Open Registrasi Form] --> B[Enter Patient Name]
    B --> C{Select Visit Type}
    C -- Doctor --> D[Show Doctor Dropdown]
    C -- Polyclinic --> E[Show Polyclinic Dropdown]
    D --> F[Select a Doctor]
    E --> G[Select a Polyclinic]
    F --> H[Pick Visit Date]
    G --> H
    H --> I[Click Save Schedule]
    I --> J[Appointment Created]
    J --> K[Navigate to Jadwal Kunjungan]
```

## 6. Add to Queue from Appointment Flow

```mermaid
graph TD
    A[Jadwal Kunjungan List] --> B{Appointment Status?}
    B -- Pending --> C{Is Today?}
    C -- Yes --> D[Show Add to Queue Button]
    C -- No --> E[Button Disabled]
    D --> F[Click Add to Queue]
    F --> G[Create Queue Entry]
    G --> H[Update Appointment Status: Checked In]
    H --> I[Refresh List - Checked In Sorted to Bottom]
    I --> J[Navigate to Queue Monitor]
    B -- Checked In --> K[No Button - Blue Badge Shown]
    B -- Attended --> L[No Button - Green Badge Shown]
```
