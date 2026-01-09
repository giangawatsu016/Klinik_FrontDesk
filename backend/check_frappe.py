import os
import requests
import json
from dotenv import load_dotenv

load_dotenv()

FRAPPE_URL = os.getenv("FRAPPE_URL")
FRAPPE_API_KEY = os.getenv("FRAPPE_API_KEY")
FRAPPE_API_SECRET = os.getenv("FRAPPE_API_SECRET")

def check_frappe_data():
    print(f"Connecting to Frappe at: {FRAPPE_URL}...")
    
    headers = {
        "Authorization": f"token {FRAPPE_API_KEY}:{FRAPPE_API_SECRET}",
        "Content-Type": "application/json",
        "Accept": "application/json"
    }
    
    # 1. Check Patients (DOCTYPE: Patient)
    # Note: If you don't have Healthcare module, this might fail (404).
    url_patient = f"{FRAPPE_URL}/api/resource/Patient?fields=[\"name\",\"first_name\",\"mobile\"]&limit_page_length=5&order_by=creation desc"
    
    try:
        print("\n--- Checking Latest Patients ---")
        r = requests.get(url_patient, headers=headers)
        if r.status_code == 200:
            data = r.json().get('data', [])
            if not data:
                print("No Patients found.")
            else:
                for item in data:
                    print(f" - {item.get('name')}: {item.get('first_name')} ({item.get('mobile')})")
        else:
            print(f"Failed to fetch Patients: {r.status_code} {r.text}")
            print("Try checking 'Customer' doctype instead if Healthcare is not installed.")
            
            # Fallback to Customer
            url_customer = f"{FRAPPE_URL}/api/resource/Customer?fields=[\"name\",\"customer_name\"]&limit_page_length=5&order_by=creation desc"
            print("\n--- Checking Latest Customers (Fallback) ---")
            r2 = requests.get(url_customer, headers=headers)
            if r2.status_code == 200:
                data2 = r2.json().get('data', [])
                for item in data2:
                    print(f" - {item.get('name')}: {item.get('customer_name')}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_frappe_data()
