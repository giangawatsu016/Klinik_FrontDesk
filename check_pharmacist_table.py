try:
    from backend.database import engine, Base
    from backend import models
except ImportError:
    import sys
    from pathlib import Path
    sys.path.append(str(Path(__file__).parent.absolute()))
    from backend.database import engine, Base
    from backend import models

from sqlalchemy import text

def check_pharmacist_table():
    print("Checking 'pharmacists' table...")
    try:
        with engine.connect() as connection:
            # Check if table exists
            result = connection.execute(text("SHOW TABLES LIKE 'pharmacists'"))
            if result.fetchone():
                print("Table 'pharmacists' EXISTS.")
                # Check columns
                result = connection.execute(text("DESCRIBE pharmacists"))
                print("Columns:")
                for col in result.fetchall():
                    print(f" - {col[0]}")
            else:
                print("Table 'pharmacists' DOES NOT EXIST. Creating...")
                models.Base.metadata.create_all(bind=engine)
                print("Table created.")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_pharmacist_table()
