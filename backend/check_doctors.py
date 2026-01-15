import sys
import os
from dotenv import load_dotenv

# Ensure we can import from services
sys.path.append(os.path.join(os.getcwd()))

try:
    from services.frappe_service import frappe_client
    
    print("Fetching Healthcare Practitioners from ERPNext...")
    doctors = frappe_client.get_doctors()
    
    if doctors:
        print(f"\n[SUCCESS] Found {len(doctors)} practitioners:")
        for doc in doctors:
            print(f" - {doc.get('practitioner_name')} (Dept: {doc.get('department')}) [ID: {doc.get('name')}]")
    else:
        print("\n[INFO] No Healthcare Practitioners found (or API returned empty list).")

except Exception as e:
    print(f"\n[ERROR] Failed to fetch data: {e}")
