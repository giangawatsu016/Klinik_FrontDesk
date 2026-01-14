import sys
import os

# Create a dummy module entry for 'backend' so imports work
if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    root_dir = os.path.dirname(current_dir)
    if root_dir not in sys.path:
        sys.path.append(root_dir)

from backend.database import SessionLocal
from backend.models import Patient
from backend.services.frappe_service import FrappeClient

def sync_patients():
    db = SessionLocal()
    frappe = FrappeClient()
    
    try:
        patients = db.query(Patient).all()
        print(f"Found {len(patients)} patients in local database.")
        
        success_count = 0
        for p in patients:
            print(f"Syncing {p.firstName} {p.lastName}...")
            
            # Convert SQLAlchemy model to dict for the service
            patient_dict = {
                "firstName": p.firstName,
                "lastName": p.lastName,
                "gender": p.gender,
                "phone": p.phone,
                "birthday": p.birthday
            }
            
            result = frappe.create_patient(patient_dict)
            if result:
                success_count += 1
                # Optional: Update local DB with Frappe ID if needed
                # p.frappe_id = result['data']['name']
                # db.commit()
                print(f" -> Success! Frappe ID: {result['data']['name']}")
            else:
                print(" -> Failed.")
                
        print(f"\nSync Complete. Successfully synced {success_count}/{len(patients)} patients.")
        
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    sync_patients()
