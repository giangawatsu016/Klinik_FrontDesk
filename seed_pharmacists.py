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

def seed_pharmacists():
    print("Seeding to 'pharmacists' table...")
    SessionLocal = sessionmaker(bind=engine)
    db = SessionLocal()

    data = [
        {
            "name": "Apt. Budi Santoso",
            "sip_no": "19900101/SIP/2023/001",
            "ihs_number": "1000200030004001",
            "erp_employee_id": "EMP-PHAR-001",
            "is_active": True
        },
        {
            "name": "Apt. Siti Aminah",
            "sip_no": "19920515/SIP/2023/002",
            "ihs_number": "1000200030004002",
            "erp_employee_id": "EMP-PHAR-002",
            "is_active": True # Image says "On Leave", but boolean is Active/Inactive. We'll map to Active for now or add Status?
            # Model only has is_active. Let's keep True.
        },
        {
            "name": "A.Md.Farm Dewi Lestari",
            "sip_no": "19950820/STR/2023/005",
            "ihs_number": "1000200030004003",
            "erp_employee_id": "EMP-PHAR-003",
            "is_active": True
        },
        {
            "name": "S.Farm Rudi Hartono",
            "sip_no": "19931110/SIP/2023/008",
            "ihs_number": "1000200030004004",
            "erp_employee_id": "EMP-PHAR-004",
            "is_active": False # Inactive in image
        }
    ]

    try:
        count = 0
        for item in data:
            exists = db.query(models.Pharmacist).filter(models.Pharmacist.sip_no == item["sip_no"]).first()
            if not exists:
                new_p = models.Pharmacist(
                    name=item["name"],
                    sip_no=item["sip_no"],
                    ihs_number=item["ihs_number"],
                    erp_employee_id=item["erp_employee_id"],
                    is_active=item["is_active"]
                )
                db.add(new_p)
                count += 1
                print(f"Added: {item['name']}")
            else:
                print(f"Skipped (Exists): {item['name']}")
        
        db.commit()
        print(f"Seeding Complete. Added {count} records.")

    except Exception as e:
        print(f"Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_pharmacists()
