import sys
import os

# Ensure we can import from services
sys.path.append(os.path.join(os.getcwd()))

try:
    from services.frappe_service import frappe_client
    
    print("Seeding Healthcare Practitioners to ERPNext...")
    
    # Sample Data
    seed_data = [
        {"first_name": "Gregory", "last_name": "House", "department": "Internal Medicine"},
        {"first_name": "Meredith", "last_name": "Grey", "department": "General Surgery"},
        {"first_name": "John", "last_name": "Dorian", "department": "Internal Medicine"},
        {"first_name": "Stephen", "last_name": "Strange", "department": "Neurosurgery"}
    ]
    
    for doc in seed_data:
        res = frappe_client.create_practitioner(
            doc["first_name"], 
            doc["last_name"], 
            doc["department"]
        )
        if res:
            print(f"[SUCCESS] Created: {doc['first_name']} {doc['last_name']}")
        else:
             print(f"[FAILED] Could not create: {doc['first_name']} {doc['last_name']}")

except Exception as e:
    print(f"\n[ERROR] Seeding failed: {e}")
