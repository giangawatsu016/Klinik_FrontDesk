from sqlalchemy.orm import sessionmaker
from sqlalchemy import create_engine
from backend.models import DoctorEntity
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

def sync_doctors():
    db = SessionLocal()
    try:
        # Get all doctors without IHS Number but WITH NIK
        doctors = db.query(DoctorEntity).filter(
            DoctorEntity.ihs_practitioner_number == None,
            DoctorEntity.identityCard != None
        ).all()
        
        print(f"Found {len(doctors)} doctors to sync.")

        for d in doctors:
            print(f"Syncing Dr. {d.namaDokter} (NIK: {d.identityCard})...")
            
            if len(d.identityCard) != 16:
                print(f"  -> Invalid NIK: {d.identityCard}")
                continue

            try:
                result = satu_sehat_client.search_practitioner_by_nik(d.identityCard)

                if result and result.get("ihs_number"):
                    ihs_number = result.get("ihs_number")
                    d.ihs_practitioner_number = ihs_number
                    db.commit()
                    print(f"  -> Linked! IHS: {ihs_number} (Name: {result.get('name')})")
                else:
                    print("  -> Not found in SatuSehat. Attempting to create...")
                    # Prepare data for creation
                    doc_data = {
                        "identityCard": d.identityCard,
                        "namaDokter": d.namaDokter,
                        "firstName": d.firstName,
                        "lastName": d.lastName
                    }
                    new_ihs = satu_sehat_client.create_practitioner_on_satusehat(doc_data)
                    if new_ihs:
                        d.ihs_practitioner_number = new_ihs
                        db.commit()
                        print(f"  -> Created & Linked! IHS: {new_ihs}")
                    else:
                        print("  -> Creation failed.")
            
            except Exception as e:
                print(f"  -> Error: {e}")

    finally:
        db.close()

if __name__ == "__main__":
    sync_doctors()
