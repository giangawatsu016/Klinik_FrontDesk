# Global User Stories (Epics)

This document tracks the **High-Level Epics** of the Klinik FrontDesk product. Detailed feature stories can be found in `docs/product/frontdesk-prd.md`.

## Core Epics

### 1. Patient Registration

- As a **Receptionist**, I want to register new patients with their personal and medical details so they can be added to the clinic system.
- As a **Receptionist**, I want to quickly find and register existing patients using their NIK or phone number to minimize registration time.
- As a **Receptionist**, I want to select visit options (Doctor/Polyclinic) and payment methods during registration so the patient is correctly queued and billed.

### 2. Queue Management & Monitoring

- As a **Receptionist**, I want to monitor the real-time status of patient queues so I can manage the clinic flow effectively.
- As a **Receptionist**, I want to call patients from the waiting list to the consultation room so the doctors can start their sessions.
- As a **Receptionist**, I want to mark consultations as completed so that daily statistics are updated and the queue moves forward.
- As a **System**, I want to automatically reset all queue data at midnight (WIB) so that each day starts with a clean slate.

### 3. Appointments (Janji Temu) & History

- As a **Receptionist**, I want to view a list of scheduled appointments from 3rd party integrations so I can prepare for arriving patients.
- As a **Receptionist**, I want to view the medical history and clinical records of patients so I can provide relevant information if requested.
- As a **Receptionist**, I want to see detailed prescription and vital sign data for completed appointments to verify treatment plans.
- As a **Receptionist**, I want the appointment status to change to "Checked In" when I add a patient to the queue so I can see which appointments have been processed.
- As a **Receptionist**, I want checked-in appointments to appear at the bottom of the list so I can focus on patients who still need to be processed.
- As a **Receptionist**, I want to schedule a new appointment by selecting either a **Doctor** or a **Polyclinic** so I can accommodate different patient needs and clinic workflows.

### 4. Authentication & Security

- As a **Staff Member**, I want to view my profile details (Name, Role, NIP) so I can verify my identity in the system.
- As a **Clinic Manager**, I want the system to automatically log out idle users after 15 minutes of inactivity to protect sensitive patient data.
- As a **Staff Member**, I want to securely log out from all devices so I can terminate all active sessions if my account is compromised.

### 5. Operational Resilience

- As a **Receptionist**, I want the system to work with mock data when the backend is unreachable so that clinic operations are never fully blocked by connection issues.
- As a **System**, I want to prevent duplicate queue entries for the same patient on the same day to maintain queue integrity.
