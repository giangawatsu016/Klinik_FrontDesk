import requests
import json

BASE_URL = "http://127.0.0.1:8000"

def debug_flow():
    # 1. Register Patient
    patient_data = {
        "firstName": "Debug",
        "lastName": "User",
        "phone": "08123456789",
        "gender": "Male",
        "birthday": "2000-01-01",
        "identityCard": "9999999999999999",
        "religion": "Islam",
        "profession": "Tester",
        "education": "Bachelor",
        "province": "Jawa Barat",
        "city": "Bogor",
        "district": "Bogor Timur",
        "subdistrict": "Baranangsiang",
        "rt": "01",
        "rw": "02",
        "postalCode": "16143",
        "issuerId": 1,
        "maritalStatusId": 1
    }
    
    print(f"1. Registering Patient to {BASE_URL}/patients/...")
    try:
        r = requests.post(f"{BASE_URL}/patients/", json=patient_data)
        if r.status_code == 200:
            patient = r.json()
            print("   SUCCESS! Patient ID:", patient['id'])
            
            # 2. Add to Queue
            print("\n2. Adding to Queue...")
            queue_data = {
                "userId": patient['id'],
                "medicalFacilityPolyDoctorId": 1, # Assuming doctor ID 1 exists
                "isPriority": False,
                "queueType": "Doctor",
                "polyclinic": None
            }
            r_q = requests.post(f"{BASE_URL}/queues/", json=queue_data)
            print("   Status Code:", r_q.status_code)
            print("   Response:", r_q.text)
        else:
            print("   FAILED to register patient.")
            print("   Status Code:", r.status_code)
            print("   Response:", r.text)

            # If failed because strict ID unique constraint, try search
            if "already exists" in r.text:
                print("   Patient exists, searching...")
                r_s = requests.get(f"{BASE_URL}/patients/search?query=9999999999999999")
                patients = r_s.json()
                if patients:
                     p_id = patients[0]['id']
                     print("   Found Patient ID:", p_id)
                     # Retry Queue
                     print("\n2b. Retry Adding to Queue...")
                     queue_data = {
                        "userId": p_id,
                        "medicalFacilityPolyDoctorId": 1,
                        "isPriority": False,
                        "queueType": "Doctor",
                        "polyclinic": None
                    }
                     r_q = requests.post(f"{BASE_URL}/queues/", json=queue_data)
                     print("   Status Code:", r_q.status_code)
                     print("   Response:", r_q.text)
                     
    except Exception as e:
        print("CRITICAL ERROR:", e)

if __name__ == "__main__":
    debug_flow()
