import sys
import os

# Add root to sys.path
if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    root_dir = os.path.dirname(os.path.dirname(current_dir)) # Go up two levels to root
    sys.path.append(root_dir)

from backend.database import SessionLocal
from backend.models import Disease

COMMON_DISEASES = [
    {"icd_code": "I10", "name": "Essential (primary) hypertension", "description": "High blood pressure"},
    {"icd_code": "E11", "name": "Type 2 diabetes mellitus", "description": "Non-insulin-dependent diabetes"},
    {"icd_code": "J06.9", "name": "Acute upper respiratory infection, unspecified", "description": "Common cold / URI / ISPA"},
    {"icd_code": "K29.7", "name": "Gastritis, unspecified", "description": "Stomach inflammation / Maag"},
    {"icd_code": "A09", "name": "Infectious gastroenteritis and colitis, unspecified", "description": "Diarrhea / Diare"},
    {"icd_code": "J00", "name": "Acute nasopharyngitis [common cold]", "description": "Pilek"},
    {"icd_code": "R50.9", "name": "Fever, unspecified", "description": "Demam"},
    {"icd_code": "K30", "name": "Dyspepsia", "description": "Indigestion"},
    {"icd_code": "M79.1", "name": "Myalgia", "description": "Muscle pain"},
    {"icd_code": "R51", "name": "Headache", "description": "Sakit kepala"},
    {"icd_code": "J02.9", "name": "Acute pharyngitis, unspecified", "description": "Sakit tenggorokan"},
    {"icd_code": "J03.9", "name": "Acute tonsillitis, unspecified", "description": "Radang amandel"},
    {"icd_code": "L23.9", "name": "Allergic contact dermatitis, unspecified cause", "description": "Alergi kulit"},
    {"icd_code": "B35.4", "name": "Tinea corporis", "description": "Kurap"},
    {"icd_code": "E78.5", "name": "Hyperlipidemia, unspecified", "description": "Kolesterol tinggi"},
    {"icd_code": "E79.0", "name": "Hyperuricaemia without signs of inflammatory arthritis and tophaceous disease", "description": "Asam Urat tinggi"},
    {"icd_code": "H10.9", "name": "Conjunctivitis, unspecified", "description": "Sakit mata / Mata merah"},
    {"icd_code": "J20.9", "name": "Acute bronchitis, unspecified", "description": "Bronkitis"},
    {"icd_code": "K02.9", "name": "Dental caries, unspecified", "description": "Sakit gigi / Gigi berlubang"},
    {"icd_code": "R05", "name": "Cough", "description": "Batuk"},
]

def seed_diseases():
    db = SessionLocal()
    try:
        print("--- Seeding ICD-10 Diseases ---")
        added_count = 0
        skipped_count = 0

        for item in COMMON_DISEASES:
            exists = db.query(Disease).filter(Disease.icd_code == item["icd_code"]).first()
            if exists:
                print(f"Skipped {item['icd_code']} (Already exists)")
                skipped_count += 1
            else:
                new_disease = Disease(
                    icd_code=item["icd_code"],
                    name=item["name"],
                    description=item["description"],
                    is_active=True
                )
                db.add(new_disease)
                print(f"Added {item['icd_code']} - {item['name']}")
                added_count += 1
        
        db.commit()
        print(f"\nSeeding Complete.")
        print(f"Added: {added_count}")
        print(f"Skipped: {skipped_count}")

    except Exception as e:
        print(f"Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_diseases()
