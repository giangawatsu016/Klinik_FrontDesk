# API Specification: FrontDesk Service

**Service Name:** FrontDesk
**Version:** v1

## 1. Overview

The FrontDesk Service manages patient lifecycle at the clinic reception, including registration, searching existing records, and managing the daily visitation queue for Doctors and Polyclinics.

## 2. Endpoints

### [POST] /register_patient

**Description**: Registers a new patient record in the system.

**Auth Required**: No (Whitelisted)

**Request Body (Schema)**:

```json
{
  "patient_data": {
    "full_name": "string (required)",
    "first_name": "string (required)",
    "last_name": "string (optional)",
    "nik": "string (16 digits, required)",
    "phone": "string (required)",
    "email": "string (required)",
    "birth_date": "YYYY-MM-DD (required)",
    "gender": "Male|Female (required)",
    "address": "string (required)",
    "company": "string (optional)"
  }
}
```

**Response (Success - 200)**:

```json
{
  "message": {
    "name": "PAT-2024-00001",
    "full_name": "John Doe",
    "nik": "1234567890123456",
    "status": "Active"
  }
}
```

---

### [GET] /search_patient

**Description**: Find an existing patient by NIK or Phone Number.

**Params**:

- `query`: Full Name, NIK or Phone Number string.

**Response (Success - 200)**:

```json
{
  "message": {
    "name": "PAT-2024-00001",
    "full_name": "John Doe",
    "phone": "08123456789"
  }
}
```

---

### [POST] /add_to_queue

**Description**: Adds a registered patient to the daily visitation queue.

**Side Effects**:

- Automatically creates a **`Clinic Encounter`** record with status **`Arrived`**.
- Updates linked `Clinic Appointment` status to **`CHECKED IN`**.
- Inherits `priority` from appointment if applicable.

**Request Body (Schema)**:

```json
{
  "entry_data": {
    "patient": "PAT-YYYY-XXXXX",
    "queue_type": "Doctor|Polyclinic",
    "practitioner": "DOC-YYYY-XXXXX (if Type=Doctor)",
    "polyclinic": "POLI-YYYY-XXXXX (if Type=Polyclinic)",
    "is_priority": 0|1,
    "company": "Intimedicare"
  }
}
```

**Response (Success - 200)**:

```json
{
  "message": {
    "name": "QUE-2024-0001",
    "queue_number": "D-001",
    "status": "Waiting"
  }
}
```

---

### [GET] /get_queue

**Description**: Retrieves queue entries for the **current day only** (WIB). All previous days' data is automatically excluded/reset.

**Response (Success - 200)**:

```json
{
  "message": [
    {
      "name": "QUE-2024-0001",
      "patient_name": "John Doe",
      "queue_number": "D-001",
      "status": "Waiting"
    }
  ]
}
```

---

### [GET] /get_queue_history

**Description**: Retrieves historical queue entries.

**Response (Success - 200)**:

```json
{
  "message": [
    {
      "name": "QUE-2024-0001",
      "patient_name": "John Doe",
      "queue_number": "D-001",
      "status": "Completed",
      "date": "YYYY-MM-DD"
    }
  ]
}
```

---

### [POST] /update_queue_status

**Description**: Transitions a queue entry through its lifecycle.

**Request Body**:

```json
{
  "name": "QUE-2024-0001",
  "status": "Called|Completed|Cancelled"
}
```

---

### [GET] /get_practitioners

**Description**: Fetches list of active doctors for registration selection.

**Response (Success - 200)**:

```json
{
  "message": [
    {
      "id": "PRAC-0001",
      "name": "Dr. Andi",
      "specialization": "General"
    }
  ]
}
```

---

### [GET] /get_polyclinics

**Description**: Fetches list of active clinics for registration selection.

**Response (Success - 200)**:

```json
{
  "message": [
    {
      "id": "POLY-0001",
      "name": "Poli Umum"
    }
  ]
}
```

---

### [GET] /get_medical_records

**Description**: Fetches historical medical records (`Clinic Encounter` records with `status` set to `Finished` or `Completed`) for formatting in the frontend Records menu.

**Params**:

- `limit` (int): Number of records per page.
- `offset` (int): Pagination offset.
- `patient` (string, optional): Specific `Clinic Patient` ID to filter by.

**Response (Success - 200)**:

```json
{
  "message": {
    "data": [
      {
        "id": "ENC-2024-00101",
        "date": "2024-12-01T10:00:00.000Z",
        "status": "COMPLETED",
        "serviceName": "Konsultasi Umum",
        "doctorName": "John Doe",
        "doctorTitlePrefix": "dr.",
        "patientDetail": {
          "fullname": "Jane Doe"
        },
        "clinicalRecord": {
          "systolicBP": 120,
          "diastolicBP": 80,
          "heartRate": 75,
          "respiratoryRate": 18,
          "temperature": 36.5,
          "anamnesis": "Patient complains of mild headache",
          "objective": "No fever, clear lungs",
          "diagnoses": [
            {
              "diagnosis": { "description": "Tension-type headache" },
              "note": "Mild"
            }
          ],
          "medicines": [
            {
              "medicine": { "description": "Paracetamol 500mg" },
              "qty": 10,
              "instruction": "3x sehari"
            }
          ]
        }
      }
    ]
  }
}
```
