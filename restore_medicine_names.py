import sys
import os

# Add current directory to path
sys.path.append(os.getcwd())

from backend.database import SessionLocal
from backend import models
from backend.services.frappe_service import frappe_client
from sqlalchemy import or_

def restore_names():
    db = SessionLocal()
    try:
        # Get medicines with empty names
        meds_to_fix = db.query(models.Medicine).filter(
            or_(models.Medicine.medicineName.is_(None), models.Medicine.medicineName == "")
        ).all()
        
        print(f"Found {len(meds_to_fix)} medicines with missing names.")
        
        if not meds_to_fix:
            return

        # Fetch all items from ERPNext to minimize calls
        print("Fetching items from ERPNext...")
        erp_items = frappe_client.get_items()
        print(f"Fetched {len(erp_items)} items from ERPNext.")
        
        # Create a map for quick lookup
        # Frappe 'name' is the item_code
        erp_map = {item.get("name"): item.get("item_name") for item in erp_items}
        
        updated_count = 0
        
        for med in meds_to_fix:
            code = med.erpnext_item_code
            if code in erp_map:
                med.medicineName = erp_map[code]
                updated_count += 1
                print(f"Restored: {code} -> {med.medicineName}")
            else:
                # Fallback if not found in ERP (maybe KFA import that wasn't synced to ERP yet?)
                # We can't do much but maybe set it to code for now so it's visible
                # Or leave it empty? If we leave it empty, UI is broken.
                # Let's set it to "Unknown - {code}" or just the code as name
                print(f"Item {code} not found in ERPNext.")
                # Optional: med.medicineName = f"Unsynced: {code}" 
                # Better: Leave it, user can edit it manually or re-import.
                # Actually, user imported from KFA. KFA logic creates it locally.
                # If they were imported from KFA, they might NOT be in ERPNext yet if push failed.
                pass
        
        db.commit()
        print(f"Successfully restored names for {updated_count} medicines.")
        
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    restore_names()
