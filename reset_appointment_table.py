try:
    from backend.database import engine, Base
    from backend.models import Appointment
    from backend import models
except ImportError:
    import sys
    from pathlib import Path
    sys.path.append(str(Path(__file__).parent.absolute()))
    from backend.database import engine, Base
    from backend.models import Appointment
    from backend import models

from sqlalchemy import text
from datetime import date, datetime

def reset_table():
    print("Resetting 'appointments' table...")
    try:
        with engine.connect() as connection:
            print("Dropping old table...")
            connection.execute(text("DROP TABLE IF EXISTS appointments"))
            connection.commit()
            
        print("Re-creating table from models.py...")
        Base.metadata.create_all(bind=engine)
        
        print("Seeding sample data...")
        from sqlalchemy.orm import sessionmaker
        SessionLocal = sessionmaker(bind=engine)
        db = SessionLocal()
        
        # Create a sample appointment matching the NEW structure
        # nik_patient, doctor_name, appointment_time as string
        sample = Appointment(
            nik_patient="1234567890123456",
            doctor_id=1,
            doctor_name="Dr. Awwal (Spesialis Pusing)",
            appointment_date=date.today(),
            appointment_time="10:00",
            status="Scheduled",
            notes="Tes Janji Temu Baru"
        )
        
        db.add(sample)
        db.commit()
        print("Success! Table reset and sample data added.")
        db.close()
                
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    reset_table()
