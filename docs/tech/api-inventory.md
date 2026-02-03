# API Inventory: FrontDesk Module

All APIs are implemented as Frappe whitelisted methods.

## Patient Management

### `register_patient`

Registers a new patient and optionally initiates the visit flow.

- **Method**: POST
- **Endpoint**: `/api/method/api_clinic.clinicfrontdesk.api.register_patient`
- **Payload**: `Clinic Patient` data.

### `search_patient`

Search for existing patients by NIK or Phone.

- **Method**: GET
- **Endpoint**: `/api/method/api_clinic.clinicfrontdesk.api.search_patient`
- **Params**: `query` (NIK or Phone).

## Queue Management

### `add_to_queue`

Adds a patient to the queue after registration.

- **Method**: POST
- **Endpoint**: `/api/method/api_clinic.clinicfrontdesk.api.add_to_queue`
- **Payload**: `{"patient": "...", "queue_type": "...", "is_priority": 0|1, ...}`

### `get_queue`

Retrieves the current queue for monitoring.

- **Method**: GET
- **Endpoint**: `/api/method/api_clinic.clinicfrontdesk.api.get_queue`
