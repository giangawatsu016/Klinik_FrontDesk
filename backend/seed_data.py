from .database import SessionLocal, engine, Base
from . import models
from . import auth_utils

# Create tables if not exist (redundant but safe)
Base.metadata.create_all(bind=engine)

db = SessionLocal()

def seed_data():
    # 1. Create Default User
    if not db.query(models.User).filter(models.User.username == "admin").first():
        print("Creating default user: admin/admin")
        admin_user = models.User(
            username="admin",
            password_hash=auth_utils.get_password_hash("admin"),
            full_name="Administrator",
            role="admin"
        )
        db.add(admin_user)
    
    # 2. Create Master Data - Doctors
    if db.query(models.DoctorEntity).count() == 0:
        print("Seeding Doctors...")
        doctors = [
            models.DoctorEntity(gelarDepan="Dr.", namaDokter="Budi Santoso", polyName="General"),
            models.DoctorEntity(gelarDepan="Dr.", namaDokter="Siti Aminah", polyName="Dental"),
            models.DoctorEntity(gelarDepan="Sp.A", namaDokter="Andi Wijaya", polyName="Pediatric"),
        ]
        db.add_all(doctors)

    # 3. Create Master Data - Issuers
    if db.query(models.Issuer).count() == 0:
        print("Seeding Issuers...")
        issuers = [
            models.Issuer(issuer="Tunjangan Pribadi", nama=["Umum"]),
            models.Issuer(issuer="BPJS", nama=["BPJS Kesehatan", "BPJS Ketenagakerjaan"]),
            models.Issuer(issuer="Asuransi Swasta", nama=["Prudential", "Allianz", "Manulife"]),
        ]
        db.add_all(issuers)
        
    # 4. Create Master Data - Marital Status
    if db.query(models.MaritalStatus).count() == 0:
        print("Seeding Marital Status...")
        statuses = [
            models.MaritalStatus(display="Single"),
            models.MaritalStatus(display="Married"),
            models.MaritalStatus(display="Divorced"),
            models.MaritalStatus(display="Widowed"),
        ]
        db.add_all(statuses)

    db.commit()
    print("Seeding complete!")

if __name__ == "__main__":
    seed_data()
    db.close()
