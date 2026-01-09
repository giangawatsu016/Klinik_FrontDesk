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
        # Maps local Patient data to Frappe Customer (or Patient if Healthcare exists)
        # Using "Customer" for broader compatibility if Healthcare module missing
        # If user installs Healthcare, we should switch to "Patient" doctype.
        
        # Checking if "Patient" doctype exists might be too slow for every req.
        # Let's assume standard Customer for now as per plan, or try Patient first?
        # User said they use Healthcare module in future (or now).
        # Let's try to create a 'Patient' first, if 404/failure, fallback? 
        # No, simpler to just map to 'Customer' as 'Customer Name' is mandatory.
        # But for a Clinic, 'Patient' is best.
        
        # Let's try 'Patient' Doctype since user installs Healthcare app.
        data = {
            "first_name": clinic_patient.get("firstName"),
            "sex": clinic_patient.get("gender"),
            "mobile": clinic_patient.get("phone"),
            "dob": clinic_patient.get("birthday"),
            # Custom fields might be needed for ID Card
        }
        return self._post("Patient", data)

    def create_appointment(self, queue_item: dict, patient_name: str):
        # Syncs Queue to Appointment
        data = {
            "patient": patient_name, # Needs ID or Name? Usually ID/Name link
            "appointment_date": str(queue_item.get("appointmentTime", "")),
            "status": "Open",
            "appointment_type": "Consultation"
        }
        return self._post("Patient Appointment", data)

# Singleton
frappe_client = FrappeClient()
