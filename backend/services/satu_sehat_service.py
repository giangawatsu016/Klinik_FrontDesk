import os
import requests
import json
from datetime import datetime
from dotenv import load_dotenv

load_dotenv()

class SatuSehatClient:
    def __init__(self):
        self.auth_url = os.getenv("SATUSEHAT_AUTH_URL")
        self.base_url = os.getenv("SATUSEHAT_BASE_URL")
        self.client_id = os.getenv("SATUSEHAT_CLIENT_ID")
        self.client_secret = os.getenv("SATUSEHAT_CLIENT_SECRET")
        self.org_id = os.getenv("SATUSEHAT_ORG_ID")
        self.access_token = None
        self.token_expiry = None

    def get_token(self):
        # Return existing token if valid
        if self.access_token and self.token_expiry and datetime.now() < self.token_expiry:
            return self.access_token

        try:
            url = f"{self.auth_url}/accesstoken?grant_type=client_credentials"
            resp = requests.post(
                url, 
                data={
                    "client_id": self.client_id,
                    "client_secret": self.client_secret
                }
            )
            
            if resp.status_code == 200:
                data = resp.json()
                self.access_token = data.get("access_token")
                # Token usually valid for 3599 seconds. Set simple expiry check.
                # using a slightly shorter valid duration to be safe
                # self.token_expiry = datetime.now() + timedelta(seconds=int(data.get("expires_in", 3600)) - 60)
                return self.access_token
            else:
                print(f"SatuSehat Auth Failed: {resp.text}")
                return None
        except Exception as e:
            print(f"SatuSehat Auth Error: {e}")
            return None

    def create_patient_fhir(self, patient_data):
        # Map local data to FHIR Patient Resource
        # Using dummy structure based on standard FHIR R4
        
        # Name
        first_name = patient_data.get("firstName", "")
        last_name = patient_data.get("lastName", "")
        full_name = f"{first_name} {last_name}".strip()
        
        # Gender mapping
        gender_map = {"Male": "male", "Female": "female"}
        gender = gender_map.get(patient_data.get("gender"), "unknown")
        
        # Phone
        phone = patient_data.get("phone", "")
        
        # NIK (Identifier)
        nik = patient_data.get("identityCard", "")

        payload = {
            "resourceType": "Patient",
            "meta": {
                "profile": [
                    "https://fhir.kemkes.go.id/r4/StructureDefinition/Patient"
                ]
            },
            "identifier": [
                {
                    "use": "official",
                    "system": "https://fhir.kemkes.go.id/id/nik",
                    "value": nik
                }
            ],
            "active": True,
            "name": [
                {
                    "use": "official",
                    "text": full_name,
                    "family": last_name if last_name else first_name,
                    "given": [first_name]
                }
            ],
            "telecom": [
                {
                    "system": "phone",
                    "value": phone,
                    "use": "mobile"
                }
            ],
            "gender": gender,
            "birthDate": patient_data.get("birthday", "2000-01-01"), # Format YYYY-MM-DD
            # Address is complex in FHIR, keeping it simple for now or adding stub
            "address": [
                {
                    "use": "home",
                    "line": [
                        patient_data.get("address_details", "")
                    ],
                    "city": patient_data.get("city", ""),
                    "postalCode": patient_data.get("postalCode", ""),
                    "country": "ID"
                }
            ],
            "communication": [
                {
                    "language": {
                        "coding": [
                            {
                                "system": "urn:ietf:bcp:47",
                                "code": "id-ID",
                                "display": "Indonesian"
                            }
                        ],
                        "text": "Indonesian"
                    }
                }
            ]
        }
        return payload

    def post_patient(self, patient_data):
        token = self.get_token()
        if not token:
            print("No valid SatuSehat token.")
            return None

        # Create FHIR Payload
        payload = self.create_patient_fhir(patient_data)
        
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        
        try:
            # POST /Patient
            url = f"{self.base_url}/Patient"
            resp = requests.post(url, headers=headers, json=payload)
            
            if resp.status_code in [200, 201]:
                data = resp.json()
                ihs_number = data.get("id")
                print(f"SatuSehat: Created Patient {ihs_number}")
                return ihs_number
            else:
                print(f"SatuSehat Create Patient Failed: {resp.status_code} - {resp.text}")
                return None
        except Exception as e:
            print(f"SatuSehat Request Error: {e}")
            return None

satu_sehat_client = SatuSehatClient()
