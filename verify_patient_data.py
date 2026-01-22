from backend.database import SessionLocal
from backend import models

def verify():
    db = SessionLocal()
    try:
        # Get patient associated with A001
        # First get queue
        queue = db.query(models.PatientQueue).filter(models.PatientQueue.numberQueue == "A002").first()
        if not queue:
            print("Queue A002 not found.")
            return


        print(f"Queue ID: {queue.id}")
        print(f"Queue Number: {queue.numberQueue}")
        print(f"Queue Type: {queue.queueType}")
        print(f"Status: {queue.status}")
        print(f"Appointment Time: {queue.appointmentTime} (Type: {type(queue.appointmentTime)})")
        
        p = queue.patient
        print(f"Patient ID: {p.id}")
        print(f"Name: {p.firstName} {p.lastName}")
        print(f"Religion: {p.religion} (Type: {type(p.religion)})")
        print(f"Profession: {p.profession} (Type: {type(p.profession)})")
        print(f"Education: {p.education} (Type: {type(p.education)})")
        print(f"RT: {p.rt} (Type: {type(p.rt)})")
        print(f"RW: {p.rw} (Type: {type(p.rw)})")
        
        # Check for None
        required_fields = ["religion", "profession", "education", "province", "city", "district", "subdistrict", "rt", "rw", "postalCode"]
        for field in required_fields:
             val = getattr(p, field)
             if val is None:
                 print(f"CRITICAL: Field '{field}' is NULL but Schema requires str!")
             
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    verify()
