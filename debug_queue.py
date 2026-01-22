from backend.database import SessionLocal
from backend import models
import datetime

db = SessionLocal()
queues = db.query(models.PatientQueue).all()

print(f"Total Queues in DB: {len(queues)}")
print("-" * 60)
print(f"{'ID':<5} | {'Number':<10} | {'Type':<10} | {'Status':<15} | {'Date (UTC)':<20} | {'PatientID':<5}")
print("-" * 60)

for q in queues:
    print(f"{q.id:<5} | {q.numberQueue:<10} | {q.queueType:<10} | {q.status:<15} | {q.appointmentTime} | {q.userId:<5}")

print("-" * 60)
today_start = datetime.datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
print(f"Backend Filter Date (UTC): >= {today_start}")
