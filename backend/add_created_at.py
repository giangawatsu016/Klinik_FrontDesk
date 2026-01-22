from database import engine
from sqlalchemy import text
from sqlalchemy.exc import OperationalError

def add_column():
    with engine.connect() as conn:
        try:
            # Check if column exists
            result = conn.execute(text("SHOW COLUMNS FROM patientcore LIKE 'created_at'"))
            if result.rowcount == 0:
                print("Column 'created_at' not found. Adding...")
                conn.execute(text("ALTER TABLE patientcore ADD COLUMN created_at DATETIME DEFAULT CURRENT_TIMESTAMP"))
                conn.commit()
                print("Column added successfully.")
            else:
                print("Column 'created_at' already exists.")
        except OperationalError as e:
            print(f"Error: {e}")

if __name__ == "__main__":
    add_column()
