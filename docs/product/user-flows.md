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
    N --> O[DELETE from Queue]
    O --> P[End - Daily Reset]
```

## 3. Janji Temu (3rd Party Integration) Flow

```mermaid
graph LR
    A[3rd Party App] --> B[Push Appointment Data]
    B --> C[Clinic Backend]
    C --> D[FrontDesk Janji Temu Menu]
    D --> E[View Details]
    E --> F[Check-in Patient]
    F --> G[Initiate Registration Flow]
```
