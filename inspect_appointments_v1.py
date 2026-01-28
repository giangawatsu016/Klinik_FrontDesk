try:
    from backend.database import engine
except ImportError:
    import sys
    import os
    from pathlib import Path
    sys.path.append(str(Path(__file__).parent.absolute()))
    from backend.database import engine

from sqlalchemy import text

def inspect_table():
    print("Inspecting 'appointments' table in klinik_db...")
    try:
        with engine.connect() as connection:
            result = connection.execute(text("DESCRIBE appointments"))
            columns = result.fetchall()
            print("\nColumns found:")
            for col in columns:
                print(f" - {col[0]} ({col[1]})")
            
            result = connection.execute(text("SELECT COUNT(*) FROM appointments"))
            count = result.scalar()
            print(f"\nTotal rows in appointments: {count}")
            
            if count > 0:
                result = connection.execute(text("SELECT * FROM appointments LIMIT 1"))
                row = result.fetchone()
                print(f"\nSample data: {row}")
                
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    inspect_table()
