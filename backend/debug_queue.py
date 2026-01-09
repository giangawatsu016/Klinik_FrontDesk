import requests
import json

BASE_URL = "http://127.0.0.1:8000"

def debug_flow():
    # Login first to get token
    print("Logging in as admin...")
    try:
        r_login = requests.post(f"{BASE_URL}/auth/token", data={"username": "admin", "password": "admin123"})
        if r_login.status_code != 200:
            print("Login Failed:", r_login.text)
            return
        
        token = r_login.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}
        
        # List all patients
        print("\nListing ALL Patients...")
        r = requests.get(f"{BASE_URL}/patients/", headers=headers)
        if r.status_code == 200:
            patients = r.json()
            print(f"Found {len(patients)} patients:")
            for p in patients:
                print(f" - ID: {p['id']}, Name: {p['firstName']} {p['lastName']}, KTP: '{p['identityCard']}'")
        else:
            print("Failed to list patients:", r.status_code, r.text)

        # Search specifically
        query = "3201017007970003"
        print(f"\nSearching for '{query}'...")
        r_search = requests.get(f"{BASE_URL}/patients/search?query={query}", headers=headers)
        print("Search Status:", r_search.status_code)
        print("Search Results:", r_search.json())

    except Exception as e:
        print("CRITICAL ERROR:", e)

if __name__ == "__main__":
    debug_flow()
