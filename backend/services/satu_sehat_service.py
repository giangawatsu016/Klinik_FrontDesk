import os
import requests
import time
from dotenv import load_dotenv

load_dotenv()

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

satu_sehat_client = SatuSehatClient()
