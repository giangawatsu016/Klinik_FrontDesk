import sys
import os
from sqlalchemy import create_engine, text

# Add parent directory to path so we can import backend modules if needed
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from database import SQLALCHEMY_DATABASE_URL

def migrate():
    engine = create_engine(SQLALCHEMY_DATABASE_URL)
    with engine.connect() as conn:
        print("Running migration: Add ihs_number to patient table...")
        try:
            conn.execute(text("ALTER TABLE patient ADD COLUMN ihs_number VARCHAR(100)"))
            print("Migration successful: ihs_number column added.")
        except Exception as e:
            # Check if error is "Duplicate column name"
            if "Duplicate column name" in str(e):
                print("Column 'ihs_number' already exists. Skipping.")
            else:
                print(f"Migration failed: {e}")

if __name__ == "__main__":
    migrate()
