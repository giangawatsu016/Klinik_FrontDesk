from sqlalchemy.orm import Session
from .database import SessionLocal, engine, Base
from .models import MaritalStatus, Issuer, DoctorEntity, User
from .auth_utils import get_password_hash

def seed():
    print("Creating tables if not exist...")
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    # 1. Marital Status
    if not db.query(MaritalStatus).first():
        print("Seeding Marital Statuses...")
        statuses = ["Single", "Married", "Divorced", "Widowed"]
        for s in statuses:
            db.add(MaritalStatus(display=s))
        db.commit()

    # 2. Issuers
    if not db.query(Issuer).first():
        print("Seeding Issuers...")
        issuers = [
            {"issuer": "Umum (General)", "nama": []},
            {"issuer": "BPJS", "nama": ["BPJS Kesehatan", "BPJS Ketenagakerjaan"]},
            {"issuer": "Insurance", "nama": ["Allianz", "Prudential", "Manulife"]}
        ]
        for i in issuers:
            db.add(Issuer(issuer=i["issuer"], nama=i["nama"]))
        db.commit()

    # 3. Doctors
    if not db.query(DoctorEntity).first():
        print("Seeding Doctors...")
        doctors = [
            {"gelarDepan": "Dr.", "namaDokter": "Budi Santoso", "polyName": "General", "is_available": True},
            {"gelarDepan": "Drg.", "namaDokter": "Siti Aminah", "polyName": "Dental", "is_available": True},
            {"gelarDepan": "Sp.A", "namaDokter": "Andi Wijaya", "polyName": "Pediatric", "is_available": True},
            {"gelarDepan": "Sp.PD", "namaDokter": "Citra Lestari", "polyName": "Internal Medicine", "is_available": True}
        ]
        for d in doctors:
            db.add(DoctorEntity(**d))
        db.commit()

    # 4. Admin User
    if not db.query(User).filter(User.username == "admin").first():
        print("Creating Admin User...")
        admin_user = User(
            username="admin",
            password_hash=get_password_hash("admin123"),
            full_name="Administrator",
            role="admin"
        )
        db.add(admin_user)
        db.commit()

    print("Seeding Complete!")
    db.close()

if __name__ == "__main__":
    seed()
