# API Specification: Doctor Service

**Service Name:** Doctor Service
**Version:** v1

## 1. Overview

The Doctor Service manages practitioner data and integration with national health systems (Satu Sehat). It provides data used globally in the application for appointments and scheduling.

## 2. Endpoints

### [GET] /get_doctors

**Description**: Retrieve a list of active doctors with their specializations and titles.

**Auth Required**: No (Whitelisted)

**Response (Success - 200)**:

```json
{
  "message": [
    {
      "id": "PRAC-2024-0001",
      "name": "Sarah Wilson",
      "specialization": "Pediatrics",
      "titlePrefix": "dr.",
      "photoProfile": null
    }
  ]
}
```

---

### [POST] /sync_facility_to_satusehat

**Description**: Synchronizes site facility data with the Satu Sehat FHIR Organization resource.

**Auth Required**: Yes (System Manager)

**Request Body (Schema)**:

```json
{
  "facility_name": "string (required)"
}
```

**Response (Success - 200)**:

```json
{
  "message": {
    "status": "success",
    "satusehat_id": "100099001",
    "message": "Facility Clinic A synced to Satu Sehat"
  }
}
```
