from sqlalchemy import create_engine, text
import sys
import os

# Add parent directory to path to import database config
sys.path.append(os.getcwd())

from backend.database import SQLALCHEMY_DATABASE_URL as DATABASE_URL

def run_migration():
    engine = create_engine(DATABASE_URL)
    with engine.connect() as connection:
        try:
            print("Migrating: Making lastName nullable...")
            
            # MySQL specific syntax
            # Check current column definition if possible, or just force modify
            connection.execute(text("ALTER TABLE patient MODIFY lastName VARCHAR(100) NULL;"))
            
            print("Migration successful: lastName is now nullable.")
            
            print("Migrating: Checking for phone uniqueness...")
            # We won't force UNIQUE index on phone immediately to prevent breaking if duplicates exist
            # Instead, we rely on the API check I just added.
            # But let's try to add the index if safe.
            try:
                connection.execute(text("CREATE UNIQUE INDEX ix_patient_phone ON patient (phone);"))
                print("Index created: ix_patient_phone")
            except Exception as e:
                print(f"Skipping Unique Index on Phone (Duplicate data might exist): {e}")

        except Exception as e:
            print(f"Migration Failed: {e}")

if __name__ == "__main__":
    run_migration()
