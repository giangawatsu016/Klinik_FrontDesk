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
        # 1. Check if patient already exists by Mobile Number (Unique Key)
        phone = clinic_patient.get("phone")
        if phone:
            existing_params = {
                "filters": json.dumps({"mobile": phone}),
                "fields": '["name"]'
            }
            try:
                check_url = f"{self.base_url}/api/resource/Patient"
                check_resp = requests.get(check_url, headers=self.headers, params=existing_params, timeout=5)
                if check_resp.status_code == 200:
                    data = check_resp.json().get("data", [])
                    if data:
                        print(f"Patient with mobile {phone} already exists: {data[0]['name']}")
                        return {"data": data[0]} # Return existing record
            except Exception as e:
                print(f"Error checking existing patient: {e}")

        # 2. If not exists, sync to 'Patient' (Healthcare Module)
        data = {
            "first_name": clinic_patient.get('firstName'),
            "last_name": clinic_patient.get('lastName'),
            "sex": clinic_patient.get("gender"), # Ensure "Male"/"Female" matches ERPNext options
            "mobile": clinic_patient.get("phone"),
            "dob": str(clinic_patient.get("birthday")) if clinic_patient.get("birthday") else None,
        }
        return self._post("Patient", data)

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

    def get_list(self, doctype: str, filters: dict = {}, fields: list = None):
        url = f"{self.base_url}/api/resource/{doctype}"
        if not fields:
            fields = ["name"]
        
        params = {
            "fields": json.dumps(fields),
            "filters": json.dumps(filters),
            "limit_page_length": 500
        }
        try:
            response = requests.get(url, headers=self.headers, params=params, timeout=10)
            if response.status_code == 200:
                data = response.json()
                return data.get("data", [])
            else:
                print(f"Frappe Get List Failed ({response.status_code}): {response.text}")
                return []
        except Exception as e:
            print(f"Frappe Connection Error: {e}")
            return []

    def delete_document(self, doctype: str, name: str):
        url = f"{self.base_url}/api/resource/{doctype}/{name}"
        try:
            print(f"Deleting {doctype} {name}...")
            response = requests.delete(url, headers=self.headers, timeout=5)
            if response.status_code == 202 or response.status_code == 200:
                print(f"Deletion Success.")
                return True
        except Exception as e:
            print(f"Frappe Connection Error: {e}")
            return False

    def get_items(self):
        # Fetch Items that are meant for Sales/Stock
        filters = {
            "disabled": 0,
            "is_stock_item": 1,
            "is_sales_item": 1
        }
        fields = ["name", "item_name", "stock_uom", "description", "standard_rate"]
        try:
            return self.get_list("Item", filters=filters, fields=fields)
        except Exception as e:
            print(f"Frappe Get Items Error: {e}")
            return []
    
    def get_practitioners(self):
        # Fetch Healthcare Practitioner
        filters = {"status": "Active"}
        try:
            # Need to fetch identifiers for IHS linking
            url = f"{self.base_url}/api/resource/Healthcare Practitioner"
            params = {
                "fields": '["name", "practitioner_name", "department", "practitioner_identifiers"]',
                "filters": json.dumps(filters),
                "limit_page_length": 500
            }
            response = requests.get(url, headers=self.headers, params=params, timeout=10)
            if response.status_code == 200:
                return response.json().get("data", [])
            return []
        except Exception as e:
            print(f"Frappe Get Practitioners Error: {e}")
            return []

    def get_patients(self, limit: int = 50):
        # Fetch Patients
        filters = {"status": "Active"} # Assuming status field exists, or remove if not sure
        try:
            url = f"{self.base_url}/api/resource/Patient"
            # Fetch fields needed by patients.py
            fields = '["name", "patient_name", "sex", "mobile", "dob", "primary_address", "mobile_uuid"]'
            
            # Note: mobile_uuid might be a custom field. If it fails, we should handle it.
            # Safe bet: fetch standard fields first.
            
            params = {
                "fields": fields,
                "limit_page_length": limit,
                "order_by": "creation desc"
            }
            response = requests.get(url, headers=self.headers, params=params, timeout=10)
            if response.status_code == 200:
                return response.json().get("data", [])
            print(f"Frappe Get Patients Failed: {response.text}")
            return []
        except Exception as e:
            print(f"Frappe Get Patients Error: {e}")
            return []

    def create_practitioner(self, first_name: str, last_name: str, department: str):
        # Helper to create a Healthcare Practitioner for testing
        data = {
            "first_name": first_name,
            "last_name": last_name,
            "department": department,
            "status": "Active"
        }
        return self._post("Healthcare Practitioner", data)

    
    def _put(self, doctype: str, name: str, data: dict):
        url = f"{self.base_url}/api/resource/{doctype}/{name}"
        try:
            print(f"Updating Frappe {doctype} {name}...", url)
            response = requests.put(url, headers=self.headers, json=data, timeout=5)
            if response.status_code == 200:
                print(f"Frappe Update Success: {response.json()}")
                return response.json()
            else:
                print(f"Frappe Update Failed ({response.status_code}): {response.text}")
                return None
        except Exception as e:
            print(f"Frappe Connection Error: {e}")
            return None

    def update_practitioner(self, name: str, data: dict):
        # We assume 'name' is the Frappe ID (e.g., PRA-2023-001)
        # Note: If local DB stores 'name' as frappe_id, pass that.
        # But our local `create_practitioner` didn't save the ID. We might need to search it first or rely on standard naming if possible.
        # However, for now, we'll try to find it by practitioner_name if name isn't a direct ID, OR we assume updating by Name is tricky without ID.
        # Implementation Plan Assumption: We might need to fetch ID first.
        # For simplicity in this iteration: We'll implement the method accepting ID.
        return self._put("Healthcare Practitioner", name, data)

    def update_patient(self, name: str, data: dict):
        # name should be the Frappe ID (e.g. PAT-2023-001) stored in Patient.frappe_id
        return self._put("Patient", name, data)

    def get_item_stock(self, item_code):
        # ... (rest of the file as before)
        try:
             # Use a Report API or just get list of Bins
             filters = {"item_code": item_code}
             url = f"{self.base_url}/api/resource/Bin"
             params = {
                "fields": '["actual_qty"]',
                "filters": json.dumps(filters)
             }
             response = requests.get(url, headers=self.headers, params=params, timeout=5)
             if response.status_code == 200:
                 bins = response.json().get("data", [])
                 total_qty = sum([b.get("actual_qty", 0) for b in bins])
                 return total_qty
             return 0
        except:
             return 0

    def create_user(self, email: str, first_name: str, last_name: str = "", role_map: str = "System Manager"):
        # Sync to 'User'
        # Determine roles based on internal role?
        # For now, we allow basic creation.
        
        # ERPNext User requires Email and First Name.
        data = {
            "email": email,
            "first_name": first_name,
            "last_name": last_name,
            "enabled": 1,
            "send_welcome_email": 0,
            # "roles": [{"role": role_map}] # Optional: Assign default role
        }
        return self._post("User", data)

    def update_erp_user(self, email: str, data: dict):
        # Update User by Email (name=email in User doctype usually)
        return self._put("User", email, data)
    
    def delete_erp_user(self, email: str):
        return self.delete_document("User", email)

    # --- Diagnosis / Disease ---
    def create_diagnosis(self, icd_code: str, description: str):
        # Check if exists first
        filters = {"code": icd_code}
        existing = self.get_list("Diagnosis", filters=filters)
        if existing:
            return existing[0]

        data = {
            "code": icd_code,
            "description": description,
            "diagnosis_group": "General" # Optional default
        }
        return self._post("Diagnosis", data)

    # --- Items (Medicines) ---
    def create_item(self, item_code: str, item_name: str, stock_uom: str, description: str = None, standard_rate: int = 0):
        data = {
            "item_code": item_code,
            "item_name": item_name,
            "item_group": "Products", # Default group
            "stock_uom": stock_uom,
            "description": description,
            "standard_rate": standard_rate,
            "is_stock_item": 1,
            "is_sales_item": 1
        }
        return self._post("Item", data)

    def update_item(self, item_code: str, data: dict):
        return self._put("Item", item_code, data)

# Singleton
frappe_client = FrappeClient()
