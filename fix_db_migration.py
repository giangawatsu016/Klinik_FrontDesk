from backend.database import engine
from sqlalchemy import text

def migrate():
    with engine.connect() as conn:
        try:
            print("Checking if column 'dosageForm' exists in 'medicinecore'...")
            # Check if column exists
            result = conn.execute(text("SHOW COLUMNS FROM medicinecore LIKE 'dosageForm'"))
            if result.fetchone():
                print("Column 'dosageForm' already exists. Skipping.")
                return

            print("Adding column 'dosageForm' to 'medicinecore'...")
            conn.execute(text("ALTER TABLE medicinecore ADD COLUMN dosageForm VARCHAR(50) NULL"))
            print("Migration successful: dosageForm added.")
            conn.commit()
        except Exception as e:
            print(f"Migration Failed: {e}")

if __name__ == "__main__":
    migrate()
