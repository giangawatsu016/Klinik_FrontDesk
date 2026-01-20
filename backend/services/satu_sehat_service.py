import os
import requests
import time
from pathlib import Path
from dotenv import load_dotenv

# Explicitly load .env from backend/ directory
env_path = Path(__file__).parent.parent / '.env'
load_dotenv(dotenv_path=env_path)

SATUSEHAT_AUTH_URL = os.getenv("SATUSEHAT_AUTH_URL")
SATUSEHAT_BASE_URL = os.getenv("SATUSEHAT_BASE_URL")
SATUSEHAT_CLIENT_ID = os.getenv("SATUSEHAT_CLIENT_ID")
SATUSEHAT_CLIENT_SECRET = os.getenv("SATUSEHAT_CLIENT_SECRET")

class SatuSehatClient:
    def __init__(self):
        self.auth_url = SATUSEHAT_AUTH_URL
        self.base_url = SATUSEHAT_BASE_URL
        self.client_id = SATUSEHAT_CLIENT_ID
        self.client_secret = SATUSEHAT_CLIENT_SECRET
        self._access_token = None
        self._token_expiry = 0

    def get_access_token(self):
        """
        Returns a valid access token. Refreshes if expired.
        """
        if self._access_token and time.time() < self._token_expiry:
            return self._access_token

        print("Refeshing SatuSehat Token...")
        url = f"{self.auth_url}/accesstoken?grant_type=client_credentials"
        headers = {
            "Content-Type": "application/x-www-form-urlencoded"
        }
        data = {
            "client_id": self.client_id,
            "client_secret": self.client_secret
        }

        try:
            response = requests.post(url, headers=headers, data=data, timeout=10)
            if response.status_code == 200:
                result = response.json()
                self._access_token = result.get("access_token")
                # expires_in is in seconds (e.g. 3599). Subtract a buffer (e.g. 60s)
                expires_in = int(result.get("expires_in", 3600))
                self._token_expiry = time.time() + expires_in - 60
                print("SatuSehat Token Refreshed.")
                return self._access_token
            else:
                print(f"SatuSehat Token Error: {response.text}")
                return None
        except Exception as e:
            print(f"SatuSehat Connection Error: {e}")
            return None

    def post_patient(self, patient_data: dict):
        """
        Sync patient to SatuSehat.
        Currently implements "Link by NIK" strategy.
        Returns IHS Number if found/linked.
        """
        nik = patient_data.get("identityCard")
        if not nik:
            print("No NIK provided for SatuSehat sync")
            return None
            
        # Try to find by NIK
        result = self.search_patient_by_nik(nik)
        if result and result.get("ihs_number"):
            return result.get("ihs_number")

        # Try to find by Demographics (Name, Birthdate, Gender) if NIK lookup fails
        # This handles cases where NIK might be different or not indexed, but patient exists
        print(f"NIK {nik} not found. Searching by Demographics...")
        demo_result = self.search_patient_by_demographics(
            patient_data.get("firstName", "") + " " + patient_data.get("lastName", ""),
            patient_data.get("birthday", "2000-01-01"),
            patient_data.get("gender", "unknown")
        )
        if demo_result and demo_result.get("ihs_number"):
            print(f"Found existing patient by demographics. IHS: {demo_result.get('ihs_number')}")
            return demo_result.get("ihs_number")
            
        print(f"Patient not found. Attempting to create new Patient in SatuSehat...")
        return self._create_new_patient_on_satusehat(patient_data)

    def search_patient_by_demographics(self, name: str, birthdate: str, gender: str):
        """
        Search by Name, Birthdate, and Gender
        GET /Patient?name={name}&birthdate={date}&gender={gender}
        """
        token = self.get_access_token()
        if not token: return None

        url = f"{self.base_url}/Patient"
        headers = {"Authorization": f"Bearer {token}"}
        
        # Ensure gender is lowercase for FHIR
        gender = gender.lower()
        if gender not in ['male', 'female', 'other', 'unknown']:
             gender = 'unknown'

        params = {
            "name": name,
            "birthdate": birthdate,
            "gender": gender
        }

        try:
            print(f"Searching SatuSehat by Demographics: {params}")
            response = requests.get(url, headers=headers, params=params, timeout=10)
            if response.status_code == 200:
                bundle = response.json()
                if bundle.get("total", 0) > 0 and bundle.get("entry"):
                    entry = bundle["entry"][0]["resource"]
                    return self._parse_patient_resource(entry)
            return None
        except Exception as e:
            print(f"SatuSehat Demographic Search Error: {e}")
            return None

    def _create_new_patient_on_satusehat(self, patient_data: dict):
        token = self.get_access_token()
        if not token: return None
        
        url = f"{self.base_url}/Patient"
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        
        # Map Gender
        gender = patient_data.get("gender", "unknown").lower()
        if gender not in ["male", "female", "other", "unknown"]:
            gender = "unknown"
            
        payload = {
            "resourceType": "Patient",
            "active": True,
            "identifier": [
                {
                    "use": "official",
                    "system": "https://fhir.kemkes.go.id/id/nik",
                    "value": patient_data.get("identityCard")
                }
            ],
            "name": [
                {
                    "use": "official",
                    "text": patient_data.get("firstName", "") + " " + patient_data.get("lastName", "") 
                }
            ],
            "gender": gender,
            "birthDate": patient_data.get("birthday", "2000-01-01"),
            "multipleBirthBoolean": False,
            "address": [
                {
                    "use": "home",
                    "line": [patient_data.get("address", "Jl. Sandbox Trial No. 1")],
                    "city": patient_data.get("city", "Jakarta"),
                    "postalCode": patient_data.get("postalCode", "10110"),
                    "country": "ID",
                    "extension": [
                        {
                            "url": "https://fhir.kemkes.go.id/r4/StructureDefinition/administrativeCode",
                            "extension": [
                                {"url": "province", "valueCode": "31"},
                                {"url": "city", "valueCode": "3171"},
                                {"url": "district", "valueCode": "317101"},
                                {"url": "village", "valueCode": "3171011001"},
                                {"url": "rt", "valueCode": "001"},
                                {"url": "rw", "valueCode": "002"}
                            ]
                        }
                    ]
                }
            ]
        }
        
        try:
            response = requests.post(url, headers=headers, json=payload, timeout=15)
            if response.status_code in [200, 201]:
                data = response.json()
                ihs = data.get("id")
                print(f"Successfully Created Patient. IHS: {ihs}")
                return ihs
            else:
                print(f"Failed to create patient ({response.status_code}): {response.text}")
                return None
        except Exception as e:
            print(f"Create Patient Request Error: {e}")
            return None

    def search_patient_by_nik(self, nik: str):
        """
        Search patient by NIK using FHIR Endpoint.
        GET /Patient?identifier=https://fhir.kemkes.go.id/id/nik|[NIK]
        """
        token = self.get_access_token()
        if not token:
            raise Exception("Failed to get Access Token")

        url = f"{self.base_url}/Patient"
        headers = {
            "Authorization": f"Bearer {token}"
        }
        params = {
            "identifier": f"https://fhir.kemkes.go.id/id/nik|{nik}"
        }

        try:
            print(f"Searching SatuSehat for NIK: {nik}")
            response = requests.get(url, headers=headers, params=params, timeout=10)
            if response.status_code == 200:
                bundle = response.json()
                if bundle.get("total", 0) > 0 and bundle.get("entry"):
                    # Success
                    entry = bundle["entry"][0]["resource"]
                    return self._parse_patient_resource(entry)
                else:
                    print("No patient found with that NIK")
                    return None
            else:
                print(f"SatuSehat Search Error ({response.status_code}): {response.text}")
                return None
        except Exception as e:
            print(f"SatuSehat Request Error: {e}")
            return None

    def _parse_patient_resource(self, resource: dict):
        """
        Extract relevant fields from FHIR Patient Resource
        """
        # Name
        name_entry = resource.get("name", [{}])[0]
        first_name = name_entry.get("text", "") # Usually "Full Name"
        
        # Parse Name parts if needed, but 'text' is often safest full name
        # Alternatively check 'given' array.
        
        # Phone (telecom)
        phone = ""
        telecoms = resource.get("telecom", [])
        for t in telecoms:
            if t.get("system") == "phone":
                phone = t.get("value", "")
                break
        
        # Address
        address_text = ""
        addresses = resource.get("address", [])
        if addresses:
            # Try to build text from lines + city
            addr = addresses[0]
            lines = addr.get("line", [])
            city = addr.get("city", "")
            address_text = f"{', '.join(lines)}, {city}"

        # ID (SatuSehat ID / IHS Number)
        ihs_number = resource.get("id", "")

        return {
            "firstName": first_name,
            "phone": phone,
            "address_details": address_text,
            "birthday": resource.get("birthDate", ""),
            "gender": resource.get("gender", ""), # 'male' | 'female'
            "ihs_number": ihs_number
        }

    def search_kfa_products(self, query: str, page: int = 1, limit: int = 10):
        """
        Search KFA Products (Medicines).
        GET /kfa-v2/products/all?page=1&size=10&product_type=farmasi&keyword=...
        """
        token = self.get_access_token()
        if not token:
            raise Exception("Failed to get Access Token")

        # KFA is often on Staging even if FHIR is on Dev, or user requested specific URL.
        # User specified: https://api-satusehat-stg.dto.kemkes.go.id/kfa-v2
        base_host = "https://api-satusehat-stg.dto.kemkes.go.id"
        url = f"{base_host}/kfa-v2/products/all"
        
        headers = {
            "Authorization": f"Bearer {token}"
        }
        params = {
            "page": page,
            "size": limit,
            "product_type": "farmasi",
            "keyword": query
        }

        try:
            print(f"Searching KFA URL: {url}")
            print(f"Params: {params}")
            response = requests.get(url, headers=headers, params=params, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                # Debug Logging
                import json
                print(f"KFA Raw Response: {json.dumps(data)[:500]}...") 
                
                # Check different response structures just in case
                items = []
                if "items" in data:
                     items = data["items"].get("data", [])
                elif "result" in data:
                     items = data["result"].get("data", [])
                elif "data" in data:
                     # Direct data array or data wrapper?
                     if isinstance(data["data"], list):
                         items = data["data"]
                     else:
                         items = data.get("data", {}).get("data", [])
                
                print(f"Found {len(items)} items.")
                return [self._parse_kfa_product(i) for i in items]
            else:
                print(f"KFA Search Error ({response.status_code}): {response.text}")
                return []
        except Exception as e:
            print(f"KFA Request Error: {e}")
            return []

    def _parse_kfa_product(self, item: dict):
        """
        Parse KFA Item to simplified format
        """
        # Identify name
        name = item.get("name", "Unknown Medicine")
        kfa_code = item.get("kfa_code", "")
        
        # Manufacturer
        manufacturer = item.get("manufacturer", "")
        
        # Packaging / Unit
        # usually in 'packaging' field or 'uom'
        unit = "Unit"
        packaging = item.get("packaging", "")
        if packaging:
             unit = packaging # Just use full packaging string or try to parse
             
        return {
            "name": name,
            "item_code": kfa_code, 
            "manufacturer": manufacturer,
            "unit": unit,
            "description": f"{manufacturer} - {packaging}"
        }

    def get_diagnostic_reports(self, ihs_number: str):
        """
        Fetch Diagnostic Reports for a specific patient (IHS Number).
        GET /DiagnosticReport?subject={ihs_number}
        """
        token = self.get_access_token()
        if not token:
            raise Exception("Failed to get Access Token")

        url = f"{self.base_url}/DiagnosticReport"
        headers = {
            "Authorization": f"Bearer {token}"
        }
        params = {
            "subject": ihs_number,
            "_sort": "-date" # Sort by latest
        }

        try:
            print(f"Fetching Diagnostic Reports for IHS: {ihs_number}")
            response = requests.get(url, headers=headers, params=params, timeout=10)
            
            if response.status_code == 200:
                bundle = response.json()
                if bundle.get("total", 0) > 0 and bundle.get("entry"):
                    items = [e["resource"] for e in bundle["entry"]]
                    return [self._parse_diagnostic_report(i) for i in items]
                else:
                    return []
            else:
                print(f"SatuSehat DiagnosticReport Error ({response.status_code}): {response.text}")
                return []
        except Exception as e:
            print(f"SatuSehat Request Error: {e}")
            return []

    def _parse_diagnostic_report(self, resource: dict):
        """
        Parse DiagnosticReport FHIR Resource
        """
        # Code / Display Name
        code_text = ""
        codes = resource.get("code", {}).get("coding", [])
        if codes:
            code_text = codes[0].get("display", codes[0].get("code", "Unknown Test"))
        else:
            code_text = resource.get("code", {}).get("text", "Unknown Report")

        # Effective DateTime
        date_time = resource.get("effectiveDateTime", "")
        
        # Performer
        performer_text = ""
        performers = resource.get("performer", [])
        if performers:
            performer_text = performers[0].get("display", "Unknown Performer")

        return {
            "id": resource.get("id"),
            "status": resource.get("status"),
            "code": code_text,
            "effectiveDateTime": date_time,
            "performer": performer_text,
            "category": self._get_category_text(resource)
        }

    def _get_category_text(self, resource: dict):
        cats = resource.get("category", [])
        if cats:
            codings = cats[0].get("coding", [])
            if codings:
                return codings[0].get("display", "")
        return ""

    def search_practitioner_by_nik(self, nik: str):
        """
        Search practitioner by NIK using FHIR Endpoint.
        GET /Practitioner?identifier=https://fhir.kemkes.go.id/id/nik|[NIK]
        """
        token = self.get_access_token()
        if not token:
            raise Exception("Failed to get Access Token")

        url = f"{self.base_url}/Practitioner"
        headers = {
            "Authorization": f"Bearer {token}"
        }
        params = {
            "identifier": f"https://fhir.kemkes.go.id/id/nik|{nik}"
        }

        try:
            print(f"Searching SatuSehat Practitioner for NIK: {nik}")
            response = requests.get(url, headers=headers, params=params, timeout=10)
            if response.status_code == 200:
                bundle = response.json()
                if bundle.get("total", 0) > 0 and bundle.get("entry"):
                    entry = bundle["entry"][0]["resource"]
                    return {
                        "ihs_number": entry.get("id"),
                        "name": entry.get("name", [{}])[0].get("text", "Unknown"),
                        "active": entry.get("active", False)
                    }
                else:
                    print("No practitioner found with that NIK")
                    return None
            else:
                print(f"SatuSehat Practitioner Search Error ({response.status_code}): {response.text}")
                return None
        except Exception as e:
            print(f"SatuSehat Request Error: {e}")
            return None

    def create_practitioner_on_satusehat(self, doctor_data: dict):
        """
        Create a new Practitioner in SatuSehat
        POST /Practitioner
        """
        token = self.get_access_token()
        if not token: return None
        
        url = f"{self.base_url}/Practitioner"
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        
        name_text = doctor_data.get("namaDokter", "Unknown")
        
        # Simple Gender Guessing for Dummy Data (Optional, default unknown)
        gender = "unknown"
        if "siti" in name_text.lower() or "dewi" in name_text.lower() or "putri" in name_text.lower():
            gender = "female"
        elif "budi" in name_text.lower() or "andi" in name_text.lower() or "joko" in name_text.lower():
            gender = "male"

        payload = {
            "resourceType": "Practitioner",
            "active": True,
            "identifier": [
                {
                    "use": "official",
                    "system": "https://fhir.kemkes.go.id/id/nik",
                    "value": doctor_data.get("identityCard")
                }
            ],
            "name": [
                {
                    "use": "official",
                    "text": name_text,
                    "family": doctor_data.get("lastName", ""),
                    "given": [doctor_data.get("firstName", "")]
                }
            ],
            "gender": gender,
            "birthDate": "1990-01-01" # Dummy birthdate mandated
        }
        
        try:
            print(f"Creating Practitioner: {name_text}...")
            response = requests.post(url, headers=headers, json=payload, timeout=15)
            if response.status_code in [200, 201]:
                data = response.json()
                ihs = data.get("id")
                print(f"Successfully Created Practitioner. IHS: {ihs}")
                return ihs
            else:
                print(f"Failed to create practitioner ({response.status_code}): {response.text}")
                return None
        except Exception as e:
            print(f"Create Practitioner Request Error: {e}")
            return None

satu_sehat_client = SatuSehatClient()
