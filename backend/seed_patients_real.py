from sqlalchemy.orm import sessionmaker
from sqlalchemy import create_engine
from backend.models import Patient
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

def seed_patients():
    db = SessionLocal()
    
    # Real Sandbox Data from Image
    # 10 Patients
    patients_data = [
        {"nik": "9271060312000001", "name": "Ardianto Putra", "gender": "Male", "dob": "1992-01-09", "ihs": "P02478375538"},
        {"nik": "9204014804000002", "name": "Claudia Sintia", "gender": "Female", "dob": "1989-11-03", "ihs": "P03647103112"},
        {"nik": "9104224509000003", "name": "Elizabeth Dior", "gender": "Female", "dob": "1976-07-07", "ihs": "P00805884304"},
        {"nik": "9104223107000004", "name": "Dr. Alan Bagus Prasetya", "gender": "Male", "dob": "1977-09-03", "ihs": "P00912894463"},
        {"nik": "9104224606000005", "name": "Ghina Assyifa", "gender": "Female", "dob": "2004-08-21", "ihs": "P01654557057"},
        {"nik": "9104025209000006", "name": "Salsabilla Anjani Rizki", "gender": "Female", "dob": "2001-04-16", "ihs": "P02280547535"},
        {"nik": "9201076001000007", "name": "Theodore Elisjah", "gender": "Female", "dob": "1985-09-18", "ihs": "P01836748436"},
        {"nik": "9201394901000008", "name": "Sonia Herdianti", "gender": "Female", "dob": "1996-06-08", "ihs": "P00883356749"},
        {"nik": "9201076407000009", "name": "Nancy Wang", "gender": "Female", "dob": "1955-10-10", "ihs": "P01058967035"},
        {"nik": "9210060207000010", "name": "Syarif Muhammad", "gender": "Male", "dob": "1988-11-02", "ihs": "P02428473601"},
    ]

    try:
        print("Seeding Patients...")
        count = 0
        for p in patients_data:
            # Split Name
            parts = p["name"].split(" ", 1)
            first_name = parts[0]
            last_name = parts[1] if len(parts) > 1 else ""
            
            # Dummy Phone (unique per NIK ending)
            dummy_phone = f"0812{p['nik'][-8:]}"

            # Check existence
            exists = db.query(Patient).filter(Patient.identityCard == p["nik"]).first()
            
            p_data = {
                "firstName": first_name,
                "lastName": last_name,
                "identityCard": p["nik"],
                "ihs_number": p["ihs"],
                "gender": p["gender"],
                "birthday": p["dob"],
                "phone": dummy_phone,
                "religion": "Islam",
                "profession": "Wiraswasta",
                "education": "S1",
                "address": "Jl. Sandbox Data No. 1",
                "province": "DKI Jakarta",
                "city": "Jakarta Selatan",
                "district": "Tebet",
                "subdistrict": "Tebet Barat",
                "rt": "001",
                "rw": "002",
                "postalCode": "12810",
                "address_details": "Jl. Sandbox Data No. 1, Tebet",
                "height": 170,
                "weight": 60,
                "maritalStatusId": 1,
                "issuerId": 1
            }

            if not exists:
                new_patient = Patient(**p_data)
                db.add(new_patient)
                print(f"Added {p['name']} ({p['nik']})")
                count += 1
            else:
                # Update IHS if missing
                if not exists.ihs_number:
                    exists.ihs_number = p["ihs"]
                    print(f"Updated IHS for {p['name']}")
                    count += 1
                else:
                    print(f"Skipped {p['name']} (Exists)")
        
        db.commit()
        print(f"Seeding Complete. {count} records affected.")

    except Exception as e:
        print(f"Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_patients()
