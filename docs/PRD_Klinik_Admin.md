# PRODUCT REQUIREMENTS DOCUMENT (PRD)
**Project Name:** Klinik Admin System
**Date:** 2026-01-22
**Version:** 2.4 (UI/UX & Dashboard)

---

## 1. Executive Summary
The Klinik Admin System is designed to modernize clinic operations by providing a unified interface for patient management, medical records, and inventory. Version 2.3 specifically upgrades the system to meet Indonesian Health Ministry regulations (**SatuSehat**) and integrates with **ERPNext** for back-office accounting, while introducing advanced features like **Medicine Concoctions**.

## 2. Problem Statement
*   **Regulatory Compliance:** Clinics are mandated to sync patient and practitioner data with the SatuSehat national platform.
*   **Complex Prescriptions:** Basic inventory systems cannot handle "Racikan" (Concoctions) where one sold item reduces stock of multiple raw ingredients.
*   **Data Silos:** Patient data often exists locally but not in the central HQ ERP.

## 3. Product Goals
1.  **Compliance:** Achieve seamless synchronization with SatuSehat (Sandbox/Prod).
2.  **Integration:** Ensure real-time or background consistency between Local Admin and ERPNext.
3.  **Efficiency:** Reduce check-in time via NIK search and autofill.
4.  **Accuracy:** Automate stock deduction for compound medicines (Racikan).

## 4. Key Features & Requirements

### 4.1 SatuSehat Integration
*   **Authentication:** Auto-renew OAuth2 tokens.
*   **Practitioner Sync:** Map local Doctors to `Practitioner` resources using IHS IDs.
*   **Patient Sync:** Map local Patients to `Patient` resources. Store `ihs_number`.
*   **Location Sync:** Map Clinic Location ID.

### 4.2 ERPNext Integration
*   **Two-Way Sync:** Users, Patients, Medicines.
*   **Queue-to-Event:** Queues appear on the ERPNext Calendar.

### 4.3 Advanced Inventory (Concoctions)
*   **Definition:** Ability to define a "Parent" medicine (e.g., "Racikan Batuk Anak") composed of "Child" medicines (e.g., Paracetamol, CTM).
*   **Pricing:** Auto-calculation based on ingredient COGS + Service Fee.
*   **Dispensing:** (Future) Deducting child stock when parent is dispensed.

### 4.4 Queue Management
*   **Daily Reset:** Auto-archive old queues at midnight to ensure clean slate.
*   **Priority Handling:** Distinct numbering (P-xxx vs AP-xxx) for Priority patients.

### 4.5 Security
*   **Authentication:** JWT-based access.
*   **Port Config:** Non-standard ports (8001) to avoid conflicts.
*   **Audit:** Regular scanning for common vulnerabilities (Bandit).

## 5. Metrics for Success
*   **Sync Rate:** 99% of new patients successfully synced to ERPNext.
*   **System Uptime:** 99.9% during clinic hours.
*   **Load Capacity:** Support 10+ concurrent users with <200ms API latency.

## 6. Roadmap
*   **v2.1:** Core Patient & Queue (Completed).
*   **v2.2:** ERPNext Sync (Completed).
*   **v2.3:** SatuSehat & Concoctions (Completed).
*   **v2.4:** UI/UX Polish, Animations, & Dashboard Logic (Completed).
*   **v2.5:** E-Prescribing & Clinical Notes (Next).
