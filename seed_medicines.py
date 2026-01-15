import os
import sys
import requests

# Add backend to path
sys.path.append(os.path.join(os.getcwd(), 'backend'))

from sqlalchemy.orm import Session
from backend.database import SessionLocal, engine
from backend import models
from services.satu_sehat_service import satu_sehat_client

# List of medicines to import
TARGET_MEDICINES = [
    "Simvastatin",
    "Metformin",
    "Omeprazole",
    "Amlodipine",
    "Lansoprazole",
    "Cetirizine"
]

def seed_medicines():
    db = SessionLocal()
    print("Starting Seeding Process...")
    
    count = 0
    for med_name in TARGET_MEDICINES:
        print(f"\nProcessing: {med_name}")
        
        # 1. Search KFA
        try:
            results = satu_sehat_client.search_kfa_products(med_name, limit=5)
            if not results:
                print(f"  [X] No KFA results found for {med_name}")
                continue
                
            # Pick the best result (e.g., first one that looks like a generic or just the first one)
            # Prefer items with "Tablet" or "Generic" if possible, but for now take the first valid one
            selected_item = results[0]
            
            # Print which one we picked
            print(f"  [>] Selected: {selected_item['name']} ({selected_item['item_code']})")
            
            # 2. Check overlap in DB
            existing = db.query(models.Medicine).filter(
                (models.Medicine.erpnext_item_code == selected_item['item_code']) | 
                (models.Medicine.name == selected_item['name'])
            ).first()
            
            if existing:
                print(f"  [!] Already exists in DB (ID: {existing.id}). Skipping.")
                continue
                
            # 3. Create Model
            new_med = models.Medicine(
                erpnext_item_code=selected_item['item_code'],
                name=selected_item['name'],
                description=selected_item['description'],
                stock=0, # Default stock
                unit=selected_item['unit'] or "Tablet"
            )
            
            db.add(new_med)
            count += 1
            print(f"  [V] Added to Database.")
            
        except Exception as e:
            print(f"  [!] Error processing {med_name}: {e}")

    db.commit()
    db.close()
    print(f"\nSeeding Completed. Added {count} new medicines.")

if __name__ == "__main__":
    seed_medicines()
