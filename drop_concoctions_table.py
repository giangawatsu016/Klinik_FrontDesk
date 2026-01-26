from backend.database import engine
from sqlalchemy import text

with engine.connect() as conn:
    print("Dropping medicine_concoctions table...")
    try:
        conn.execute(text("DROP TABLE IF EXISTS medicine_concoctions"))
        conn.commit()
        print("Table dropped successfully.")
    except Exception as e:
        print(f"Error dropping table: {e}")
