from backend.database import SessionLocal
from backend import models
from datetime import datetime

def debug_queue():
    db = SessionLocal()
    try:
        print("Dumping Last 20 Queue Items:")
        queues = db.query(models.PatientQueue).order_by(models.PatientQueue.id.desc()).limit(20).all()
        
        for q in queues:
            print("--------------------------------------------------")
            print(f"ID: {q.id}")
            print(f"Number: {q.numberQueue}")
            print(f"Queue Type: '{q.queueType}'")
            print(f"Status: '{q.status}'")
            print(f"Appointment Time: {q.appointmentTime}")
            print(f"Patient ID: {q.patient.id if q.patient else 'None'} ({q.patient.firstName if q.patient else 'N'} {q.patient.lastName if q.patient else 'A'})")
            
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    debug_queue()
