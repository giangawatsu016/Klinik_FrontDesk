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
        # Filter patients that don't have a Frappe ID yet
        patients = db.query(Patient).filter(Patient.frappe_id == None).all()
        print(f"Found {len(patients)} unsynced patients (frappe_id is None).")
        
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
            if result and "data" in result:
                success_count += 1
                # Update local DB with Frappe ID
                p.frappe_id = result['data']['name']
                db.commit()
                print(f" -> Success! Frappe ID: {result['data']['name']}")
            else:
                print(f" -> Failed.")
                
        print(f"\nSync Complete. Successfully synced {success_count}/{len(patients)} patients.")
        
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    sync_patients()
