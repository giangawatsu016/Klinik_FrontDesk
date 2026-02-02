from sqlalchemy.orm import Session
from backend.database import SessionLocal, engine
from backend import models

from sqlalchemy import text

def seed_issuers():
    db = SessionLocal()
    
    # 1. Reset Table
    print("Resetting Issuer table...")
    try:
        db.execute(text("DELETE FROM issuer"))
        # Reset Auto Increment for SQLite
        db.execute(text("DELETE FROM sqlite_sequence WHERE name='issuer'"))
        db.commit()
    except Exception as e:
        print(f"Warning during reset: {e}")
        db.rollback()

    issuers = [
        {"issuer": "Umum", "nama": "General / Cash"}, # Will be ID 1
        {"issuer": "BPJS", "nama": "BPJS Kesehatan"}, # ID 2
        {"issuer": "BPJS", "nama": "BPJS Ketenagakerjaan"}, # ID 3
        {"issuer": "Asuransi Swasta", "nama": "Allianz"},
        {"issuer": "Asuransi Swasta", "nama": "Prudential"},
        {"issuer": "Asuransi Swasta", "nama": "Manulife"},
        {"issuer": "Asuransi Swasta", "nama": "AXA Mandiri"},
    ]

    for i in issuers:
        db_item = models.Issuer(issuer=i["issuer"], nama=i["nama"])
        db.add(db_item)
    
    db.commit()
    print(f"Seeded {len(issuers)} issuers. IDs should start at 1.")
    db.close()

if __name__ == "__main__":
    seed_issuers()
