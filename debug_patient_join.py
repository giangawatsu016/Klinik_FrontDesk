try:
    from backend.database import engine
    from backend import models
except ImportError:
    import sys
    from pathlib import Path
    sys.path.append(str(Path(__file__).parent.absolute()))
    from backend.database import engine
    from backend import models

from sqlalchemy import text
from sqlalchemy.orm import sessionmaker

def debug_join():
    print("Debugging Patient-Appointment Join...")
    SessionLocal = sessionmaker(bind=engine)
    db = SessionLocal()

    try:
        # 1. List All Patients
        print("\n--- Existing Patients (NIK | Name) ---")
        patients = db.query(models.Patient).all()
        for p in patients:
            print(f"NIK: '{p.identityCard}' | Name: {p.firstName} {p.lastName}")

        # 2. List All Appointments
        print("\n--- Existing Appointments (NIK Patient) ---")
        appointments = db.query(models.Appointment).all()
        for a in appointments:
            print(f"ID: {a.id} | NIK in Appointment: '{a.nik_patient}'")

        # 3. Test Join Logic Manually
        print("\n--- Testing Join ---")
        for a in appointments:
            patient = db.query(models.Patient).filter(models.Patient.identityCard == a.nik_patient).first()
            if patient:
                print(f"Appointment {a.id} MATCHES Patient: {patient.firstName}")
            else:
                print(f"Appointment {a.id} (NIK: {a.nik_patient}) => NO MATCH FOUND")

    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    debug_join()
