# PRODUCT REQUIREMENTS DOCUMENT (PRD)
**Project Name:** Klinik Intimedicare System
**Date:** 2026-01-29
**Version:** 2.8 (Deployment Automation, Role Filtering, & Validation)

---

## 1. Executive Summary
The Klinik Intimedicare System is designed to modernize clinic operations by providing a unified interface for patient management, medical records, and inventory. Version 2.8 focuses on **security, data integrity, and operational streamlining** by enforcing role-based access restrictions, strict data validation (NIK), and automating deployment workflows to GitLab.

## 2. Problem Statement
*   **Data Integrity:** Invalid NIK entries (wrong length, non-numeric) cause sync failures with SatuSehat.
*   **Operational Clarity:** Admins cluttered with day-to-day operational menus (Queue, Registration) and vice-versa.
*   **Deployment:** Manual deployment to multiple repositories (GitHub, GitLab Frontend, GitLab Backend) is error-prone.
*   **User Experience:** "Janji Temu" (Appointments) screen cluttered with past appointments.

## 3. Product Goals
1.  **Operational Focus:** Show users only what they need via strict Role-Based Visibility (Staff vs Admin).
2.  **Data Quality:** Prevent bad data entry at the source (16-digit NIK enforcement).
3.  **DevOps Efficiency:** One-click deployment script for multi-repo synchronization.
4.  **Usability:** Auto-filter historical data to keep views relevant (Appointments).

## 4. Key Features & Requirements

### 4.1 Role-Based Visibility (v2.8)
*   **Staff Only:** "Overview", "Queue Monitor", and "Registration" menus are visible ONLY to Staff.
*   **Admin/Super Admin:** Restricted to Management (Users, Inventory, Master Data) and Reports.

### 4.2 Enhanced Validation (v2.8)
*   **NIK Enforcement:** Strict check for exactly 16 numeric digits in Registration and Pharmacist forms.
*   **Validation Feedback:** Clear error messages ("Must be 16 digits").

### 4.3 Appointment Management
*   **Scheduling:** Create and view appointments.
*   **Filtering:** Automatically hide appointments from previous dates.

### 4.4 One-Click Deployment
*   **Automation:** PowerShell script (`deploy_gitlab.ps1`) to:
    *   Clone GitLab repos.
    *   Reset/Clean to avoid conflicts.
    *   Sync local changes options to specific subdirectories.
    *   Push updates automatically.

### 4.5 Pharmacist Management
*   **CRUD:** Manage Pharmacist data (SIP, NIK, IHS).
*   **UI:** Clean card interface without redundant status indicators.

### 4.6 Core Features (Maintained)
*   **SatuSehat Integration:** OAuth2 & Patient/Practitioner Sync.
*   **ERPNext Sync:** Bi-directional data flow.
*   **Queue Management:** Daily cleanup and TTS calling.
*   **Inventory:** Batch management and expiration tracking.

## 5. Metrics for Success
*   **Error Rate:** 0% invalid NIK submissions to SatuSehat.
*   **Deployment Time:** < 1 minute to sync all repositories.
*   **User Satisfaction:** Staff experience less clutter in dashboard menus.

## 6. Roadmap
*   **v2.1 - v2.3:** Core Patient, Queue, SatuSehat, & Concoctions (Completed).
*   **v2.4:** UI/UX Polish & Dashboard Logic (Completed).
*   **v2.5:** Bi-directional Sync & Logic Refinements (Completed).
*   **v2.6:** Medicine Batch Management & Payment Integration (Completed).
*   **v2.7:** Comprehensive Testing & Security Hardening (Completed).
*   **v2.8:** Deployment Automation, Role-Based Visibility, & Strict Validation (Completed).
