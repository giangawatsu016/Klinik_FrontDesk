from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from backend.models import Patient
from backend.services.satu_sehat_service import satu_sehat_client
import os
from dotenv import load_dotenv

# Load Env
load_dotenv()

# DB Connection
DB_USER = os.getenv("DB_USER", "root")
DB_PASS = os.getenv("DB_PASSWORD", "")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_NAME = os.getenv("DB_NAME", "klinik_admin")

DATABASE_URL = f"mysql+pymysql://{DB_USER}:{DB_PASS}@{DB_HOST}/{DB_NAME}"
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def sync_patients():
    db = SessionLocal()
    try:
        # Get all patients without IHS Number
        patients = db.query(Patient).filter(Patient.ihs_number == None).all()
        print(f"Found {len(patients)} patients to sync.")

        for p in patients:
            print(f"Syncing {p.firstName} (NIK: {p.identityCard})...")
            
            if not p.identityCard or len(p.identityCard) != 16:
                print(f"  -> Invalid NIK: {p.identityCard}")
                continue

            try:
                # Reuse the newly created post_patient method
                ihs_number = satu_sehat_client.post_patient({
                    "identityCard": p.identityCard,
                    "firstName": p.firstName,
                    "lastName": p.lastName or "",
                    "gender": p.gender or "unknown",
                    "birthday": str(p.birthday) if p.birthday else "2000-01-01",
                    "address": p.address or p.address_details or "Jl. Sandbox",
                    "city": p.city or "Jakarta",
                    "postalCode": p.postalCode or "10110"
                })

                if ihs_number:
                    p.ihs_number = ihs_number
                    db.commit()
                    print(f"  -> Linked! IHS: {ihs_number}")
                else:
                    print("  -> Not found in SatuSehat.")
            
            except Exception as e:
                print(f"  -> Error: {e}")

    finally:
        db.close()

if __name__ == "__main__":
    sync_patients()
