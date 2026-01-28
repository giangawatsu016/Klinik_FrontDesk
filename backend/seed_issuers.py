from sqlalchemy.orm import Session
from database import SessionLocal, engine
import models

def seed_issuers():
    db = SessionLocal()
    
    # Check if data exists
    if db.query(models.Issuer).count() > 0:
        print("Issuers already exist. Skipping.")
        return

    issuers = [
        {"issuer": "Umum", "nama": "General / Cash"},
        {"issuer": "BPJS", "nama": "BPJS Kesehatan"},
        {"issuer": "BPJS", "nama": "BPJS Ketenagakerjaan"},
        {"issuer": "Asuransi Swasta", "nama": "Allianz"},
        {"issuer": "Asuransi Swasta", "nama": "Prudential"},
        {"issuer": "Asuransi Swasta", "nama": "Manulife"},
        {"issuer": "Asuransi Swasta", "nama": "AXA Mandiri"},
    ]

    for i in issuers:
        db_item = models.Issuer(issuer=i["issuer"], nama=i["nama"])
        db.add(db_item)
    
    db.commit()
    print(f"Seeded {len(issuers)} issuers.")
    db.close()

if __name__ == "__main__":
    seed_issuers()
