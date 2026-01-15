import sys
import os

# Add parent directory to path to allow importing backend modules
current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir) # Clinic_Admin
sys.path.append(parent_dir)

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from backend.models import DoctorEntity
from backend.database import SessionLocal, engine

# Database Setup
# Using the engine/session from database.py which connects to MySQL
print(f"Connecting to database via backend.database...")

def check_tables():
    from sqlalchemy import inspect
    inspector = inspect(engine)
    print("Tables in DB:", inspector.get_table_names())

def delete_doctors(ids):
    check_tables()
    db = SessionLocal()
    try:
        print(f"Attempting to delete doctors with IDs: {ids}")
        doctors_to_delete = db.query(DoctorEntity).filter(DoctorEntity.medicalFacilityPolyDoctorId.in_(ids)).all()
        
        if not doctors_to_delete:
            print("No doctors found with these IDs.")
            # Print all doctors to see what's there
            all_docs = db.query(DoctorEntity).all()
            print(f"Existing Doctors ({len(all_docs)}):")
            for d in all_docs:
                print(f" - ID: {d.medicalFacilityPolyDoctorId}, Name: {d.namaDokter}")
            return

        # Handle Foreign Key Constraint (PatientQueue)
        from backend.models import PatientQueue
        print("Cleaning up related PatientQueue entries...")
        
        # Option 1: Set to NULL (Preserve History)
        # db.query(PatientQueue).filter(PatientQueue.medicalFacilityPolyDoctorId.in_(ids)).update({PatientQueue.medicalFacilityPolyDoctorId: None}, synchronize_session=False)
        
        # Option 2: Delete (Cleanup)
        # Since this is likely test data cleanup, we delete the queue items for these doctors.
        deleted_queues = db.query(PatientQueue).filter(PatientQueue.medicalFacilityPolyDoctorId.in_(ids)).delete(synchronize_session=False)
        print(f"Deleted {deleted_queues} related queue entries.")

        for doc in doctors_to_delete:
            print(f"Deleting: {doc.namaDokter} (ID: {doc.medicalFacilityPolyDoctorId})")
            db.delete(doc)
        
        db.commit()
        print("Deletion successful.")
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    ids_to_delete = [1, 2, 3, 4]
    delete_doctors(ids_to_delete)
