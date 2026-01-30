import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from backend.models import PatientQueue
from backend.database import SQLALCHEMY_DATABASE_URL

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
db = SessionLocal()

from datetime import datetime
print(f"PYTHON SYS TIME (UTC): {datetime.utcnow()}")
print(f"PYTHON SYS TIME (Local): {datetime.now()}")

print("-" * 50)
print("DUMPING PATIENT QUEUE TABLE")
print("-" * 50)

# TEST INSERT
try:
    test_q = PatientQueue(
        numberQueue="TEST-001", 
        userId=1, # Assuming user 1 exists
        appointmentTime=datetime.utcnow(),
        status="Waiting",
        queueType="Doctor"
    )
    db.add(test_q)
    db.commit()
    print(f"TEST INSERT SUCCESS. ID: {test_q.id}")
except Exception as e:
    print(f"TEST INSERT FAILED: {e}")
    db.rollback()

queues = db.query(PatientQueue).all()
print(f"TOTAL ROWS: {len(queues)}")

if not queues:
    print("TABLE IS EMPTY!")
else:
    for q in queues:
        print(f"ID: {q.id} | No: {q.numberQueue} | Status: {q.status} | Time(UTC): {q.appointmentTime} | Type: {q.queueType}")

print("-" * 50)
