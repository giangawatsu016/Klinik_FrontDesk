# Queue & Encounter Integration Guide

This document describes how external applications (e.g., Doctor App, Pharmacy App, Payment App) can integrate with the Clinic FrontDesk Queue and Encounter systems to read patient data and auto-advance the queue workflow.

---

## 1. Overview

The Clinic system uses two closely linked DocTypes to manage patient flow:

1. **Clinic FrontDesk Queue**: Maintains the live queue status (`Waiting` → `Consultation` → `Pharmacy` → `Payment` → `Completed`).
2. **Clinic Encounter**: Stores the permanent medical record (Vital Signs, SOAP Notes, Diagnosis, Prescriptions, Billing).

These documents are bidirectionally linked. When the FrontDesk registers a patient to the Queue, an Encounter is automatically created. Modifying either correctly syncs the relevant statuses.

---

## 2. Status Workflow & Triggers

| Queue Status | Encounter Status | Active App / Action Trigger |
|---|---|---|
| Waiting | Arrived | **FrontDesk**: Adding patient to Queue (`add_to_queue`) |
| Consultation | In-Progress | **FrontDesk**: Clicks "Call Patient" (`advance_queue_status`) |
| Pharmacy | Pharmacy | **Doctor App**: Submits SOAP data & Clicks "Finish" |
| Payment | Billing | **Pharmacy App**: Submits Prescriptions & Clicks "Finish" |
| Completed | Finished | **Payment App**: Submits Payment & Clicks "Finish" |

---

## 3. External App Integration APIs

All APIs are exposed via Frappe Whitelist at the endpoint `/api/method/api_clinic.api.<method_name>`.

### A. Fetch Encounter Data (`get_encounter_by_queue`)

When a patient arrives at a specific section (e.g., Doctor's room), the external app should first fetch the linked Encounter data using the active Queue ID.

**Endpoint**: `/api/method/api_clinic.api.get_encounter_by_queue`
**Method**: `GET` / `POST`

**Request Payload**:

```json
{
    "queue_name": "QUE-2026-00042"
}
```

**Response**:
Returns the full Encounter JSON dictionary, allowing the app to read `blood_pressure_systolic`, `medical_history`, previous `soap_subjective` notes, etc.

---

### B. Submit Data and Auto-Advance (`submit_encounter`)

Once the Doctor, Pharmacist, or Cashier finishes their task, they submit their form data to this endpoint. This will:

1. Save the submitted data into the `Clinic Encounter` DocType.
2. Automatically advance the `Clinic FrontDesk Queue` condition (e.g., `Consultation` → `Pharmacy`).
3. Automatically sync the new status to the `Clinic Encounter` (e.g., `In-Progress` → `Pharmacy`).

**Endpoint**: `/api/method/api_clinic.api.submit_encounter`
**Method**: `POST`

**Request Payload**:

```json
{
    "encounter_name": "ENC-2026-00042",
    "data": {
        "soap_subjective": "Patient complains of headache...",
        "soap_objective": "Temp 38.5C",
        "soap_assessment": "Fever",
        "soap_plan": "Paracetamol 500mg"
    }
}
```

*Note*: The `data` object should map exactly to valid `Clinic Encounter` DocType fieldnames.

---

## 4. Example: Doctor App Workflow

1. A patient hits the front of the queue. FrontDesk clicks "Call Patient" in the FrontDesk app.
2. The Queue status becomes `Consultation`.
3. The **Doctor App** detects the Active Queue. It calls `get_encounter_by_queue(queue_name="QUE...")` to get the linked `encounter_name` ("ENC...").
4. The Doctor writes their SOAP notes in the App.
5. The Doctor clicks **"Submit & Finish"**.
6. The Doctor App calls `submit_encounter` with the SOAP data.
7. Under the hood:
   - The SOAP data saves to the Encounter.
   - The Queue status changes from `Consultation` → `Pharmacy`.
   - The Encounter status changes from `In-Progress` → `Pharmacy`.
8. The patient now appears in the **Pharmacy App** Queue.
