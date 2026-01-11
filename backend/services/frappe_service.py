import os
import requests
import json
from dotenv import load_dotenv

load_dotenv()

FRAPPE_URL = os.getenv("FRAPPE_URL")
FRAPPE_API_KEY = os.getenv("FRAPPE_API_KEY")
FRAPPE_API_SECRET = os.getenv("FRAPPE_API_SECRET")

class FrappeClient:
    def __init__(self):
        self.base_url = FRAPPE_URL
        self.headers = {
            "Authorization": f"token {FRAPPE_API_KEY}:{FRAPPE_API_SECRET}",
            "Content-Type": "application/json",
            "Accept": "application/json"
        }

    def _post(self, doctype: str, data: dict):
        url = f"{self.base_url}/api/resource/{doctype}"
        try:
            print(f"Syncing to Frappe {doctype}...", url)
            response = requests.post(url, headers=self.headers, json=data, timeout=5)
            if response.status_code == 200:
                print(f"Frappe Sync Success: {response.json()}")
                return response.json()
            else:
                print(f"Frappe Sync Failed ({response.status_code}): {response.text}")
                return None
        except Exception as e:
            print(f"Frappe Connection Error: {e}")
            return None

    def create_patient(self, clinic_patient: dict):
        # Fallback: Sync to 'Customer' since 'Patient' (Healthcare) is not installed.
        fullname = f"{clinic_patient.get('firstName')} {clinic_patient.get('lastName')}"
        data = {
            "customer_name": fullname,
            "customer_type": "Individual",
            "customer_group": "All Customer Groups",
            "territory": "All Territories",
            "mobile_no": clinic_patient.get("phone"),
            "email_id": "", # Optional
        }
        return self._post("Customer", data)

    def create_appointment(self, queue_item: dict, patient_name: str):
        # Fallback: Sync to 'Event' (Calendar) since 'Patient Appointment' is missing.
        # Duration 30 mins default
        start_time = queue_item.get("appointmentTime")
        # Ensure start_time is datetime object or ISO string
        
        data = {
            "subject": f"Consultation: {patient_name}",
            "starts_on": str(start_time),
            "status": "Open",
            "event_type": "Public",
            "description": "Queued from Klinik Admin"
        }
        return self._post("Event", data)

# Singleton
frappe_client = FrappeClient()
