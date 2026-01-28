from backend.database import engine
from sqlalchemy import text

def add_nik_column():
    with engine.connect() as conn:
        try:
            conn.execute(text("ALTER TABLE pharmacists ADD COLUMN nik VARCHAR(16)"))
            print("Successfully added 'nik' column to pharmacists table.")
        except Exception as e:
            print(f"Error (might already exist): {e}")

if __name__ == "__main__":
    add_nik_column()
