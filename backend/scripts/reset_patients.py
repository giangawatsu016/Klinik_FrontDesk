from sqlalchemy import create_engine, text
import sys
import os

# Add parent directory to path to import database config
sys.path.append(os.getcwd())

from backend.database import SQLALCHEMY_DATABASE_URL as DATABASE_URL

def reset_db():
    engine = create_engine(DATABASE_URL)
    with engine.connect() as connection:
        try:
            print("Beginning Database Reset...")
            
            # 1. Clear Dependent Table (Queue) first
            print("Clearing 'patientqueue' table...")
            connection.execute(text("DELETE FROM patientqueue;"))
            connection.execute(text("ALTER TABLE patientqueue AUTO_INCREMENT = 1;"))
            
            # 2. Clear Patient Table
            print("Clearing 'patient' table...")
            connection.execute(text("DELETE FROM patient;"))
            connection.execute(text("ALTER TABLE patient AUTO_INCREMENT = 1;"))
            
            print("Data cleared. Applying Schema Constraints...")
            
            # 3. Ensure Last Name and Frappe ID are Nullable/Present
            try:
                connection.execute(text("ALTER TABLE patient MODIFY lastName VARCHAR(100) NULL;"))
                print("Confirmed: lastName is nullable.")
            except Exception as e:
                print(f"Schema Modify Warning (lastName): {e}")

            try:
                connection.execute(text("ALTER TABLE patient ADD COLUMN frappe_id VARCHAR(100) NULL;"))
                print("Confirmed: frappe_id column added.")
            except Exception as e:
                # Likely already exists
                print(f"Schema Modify Warning (frappe_id): {e}")

            # 4. Apply Unique Constraint on Phone
            # First, drop index if exists to avoid error
            try:
                connection.execute(text("DROP INDEX ix_patient_phone ON patient;"))
            except Exception:
                pass 
                
            try:
                connection.execute(text("CREATE UNIQUE INDEX ix_patient_phone ON patient (phone);"))
                print("Success: Applied UNIQUE constraint on 'phone'.")
            except Exception as e:
                print(f"Failed to create Unique Index: {e}")
                
            connection.commit()
            print("Reset Complete.")

        except Exception as e:
            print(f"Reset Failed: {e}")

if __name__ == "__main__":
    reset_db()
