try:
    from backend.database import engine, Base
    from backend import models
except ImportError:
    import sys
    from pathlib import Path
    sys.path.append(str(Path(__file__).parent.absolute()))
    from backend.database import engine, Base
    from backend import models

from sqlalchemy.orm import sessionmaker
from datetime import date

def fix_missing_patient():
    print("Fixing Missing Patient for NIK: 3201010808880001")
    SessionLocal = sessionmaker(bind=engine)
    db = SessionLocal()

    try:
        # Check if it already exists (just in case)
        existing = db.query(models.Patient).filter(models.Patient.identityCard == "3201010808880001").first()
        if existing:
            print("Patient already exists! Updating name...")
            existing.firstName = "Budi"
            existing.lastName = "Santoso"
        else:
            print("Creating new patient record...")
            new_patient = models.Patient(
                firstName="Budi",
                lastName="Santoso",
                identityCard="3201010808880001", # MATCHING NIK
                phone="081234567890",
                gender="Male",
                birthday=date(1990, 1, 1),
                religion="Islam",
                profession="Swasta",
                education="S1",
                province="Jawa Barat",
                city="Bandung",
                district="Coblong",
                subdistrict="Dago",
                rt="01",
                rw="02",
                postalCode="40135",
                issuerId=1, # Assuming 1 exists, usually 'Umum'
                maritalStatusId=1 # Assuming 1 exists
            )
            db.add(new_patient)
        
        db.commit()
        print("Success! Patient 'Budi Santoso' added/updated.")

    except Exception as e:
        print(f"Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    fix_missing_patient()
