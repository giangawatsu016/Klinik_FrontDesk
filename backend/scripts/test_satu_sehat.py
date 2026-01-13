import sys
import os
import json
from datetime import datetime

# Add parent directory to path to import services
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.satu_sehat_service import satu_sehat_client

def test_integration():
    print("--- Satu Sehat Integration Test ---")
    
    # 1. Test Authentication
    print("\n1. Testing Authentication...")
    try:
        token = satu_sehat_client.get_token()
        # token = "Q4cR0UhTioyG4Asca5AjjxXHOEYs" # Manual Token from User
        # print(f"[INFO] Using Manual Token: {token}")
        
        if token:
            print(f"[OK] Auth Success! Token received (Length: {len(token)})")
        else:
            print("[FAIL] Auth Failed. Check credentials in .env")
            return
    except Exception as e:
        print(f"[ERROR] Auth Error: {e}")
        return

    # 2. Test Create Patient (FHIR)
    print("\n2. Testing Patient Creation (FHIR POST)...")
    
    # Dummy Data for Testing (Must use unique NIK if possible, but for dev environment often flexible)
    # Using a random NIK to avoid duplicates in dev env if strict
    import random
    dummy_nik = f"1234567890{random.randint(100000, 999999)}"
    
    dummy_patient = {
        "firstName": "Test",
        "lastName": f"Patient_{random.randint(1000, 9999)}",
        "identityCard": dummy_nik,
        "phone": f"0812{random.randint(10000000, 99999999)}",
        "gender": "Male",
        "birthday": "1990-01-01",
        "address_details": "Jl. Test Dev No. 1",
        "city": "Jakarta",
        "postalCode": "10000"
    }
    
    print(f"Payload Preview: Name={dummy_patient['firstName']} {dummy_patient['lastName']}, NIK={dummy_patient['identityCard']}")
    
    try:
        ihs_number = satu_sehat_client.post_patient(dummy_patient)
        if ihs_number:
            print(f"[OK] Create Patient Success!")
            print(f"IHS Number: {ihs_number}")
        else:
            print("[FAIL] Create Patient Failed. Check prior logs.")
    except Exception as e:
        print(f"[ERROR] Create Error: {e}")

if __name__ == "__main__":
    test_integration()
