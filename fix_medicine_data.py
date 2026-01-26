import sys
import os

# Add the current directory to sys.path so we can import backend modules
sys.path.append(os.getcwd())

from sqlalchemy import text
from backend.database import SessionLocal

def fix_data():
    db = SessionLocal()
    try:
        print("Checking medicinecore table...")
        
        # Check if 'name' column exists (old column)
        result = db.execute(text("SHOW COLUMNS FROM medicinecore LIKE 'name'"))
        has_name_col = result.fetchone() is not None
        print(f"Has 'name' column: {has_name_col}")
        
        # Check if 'medicineName' column exists
        result = db.execute(text("SHOW COLUMNS FROM medicinecore LIKE 'medicineName'"))
        has_new_col = result.fetchone() is not None
        print(f"Has 'medicineName' column: {has_new_col}")

        if has_name_col and has_new_col:
            print("Both columns exist. Attempting verification/migration...")
            
            # Check for empty medicineName
            count_empty = db.execute(text("SELECT COUNT(*) FROM medicinecore WHERE medicineName IS NULL OR medicineName = ''")).scalar()
            print(f"Rows with empty medicineName: {count_empty}")
            
            if count_empty > 0:
                print("Migrating data from 'name' to 'medicineName'...")
                db.execute(text("UPDATE medicinecore SET medicineName = name WHERE (medicineName IS NULL OR medicineName = '') AND name IS NOT NULL"))
                db.commit()
                print("Migration complete.")
            else:
                print("No empty medicineName rows found.")
        
        elif has_new_col and not has_name_col:
             print("Only 'medicineName' exists. Checking if empty...")
             rows = db.execute(text("SELECT id, medicineName, erpnext_item_code FROM medicinecore LIMIT 5")).fetchall()
             for row in rows:
                 print(f"ID: {row[0]}, Name: {row[1]}, Code: {row[2]}")
                 
        else:
            print("Schema seems unexpected.")

    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    fix_data()
