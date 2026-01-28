try:
    from backend.database import engine
except ImportError:
    import sys
    from pathlib import Path
    sys.path.append(str(Path(__file__).parent.absolute()))
    from backend.database import engine

from sqlalchemy import text

def update_table():
    print("Updating 'pharmacists' table...")
    try:
        with engine.connect() as connection:
            # Check if column exists
            result = connection.execute(text("SHOW COLUMNS FROM pharmacists LIKE 'erp_employee_id'"))
            if result.fetchone():
                print("Column 'erp_employee_id' ALREADY EXISTS.")
            else:
                print("Adding column 'erp_employee_id'...")
                connection.execute(text("ALTER TABLE pharmacists ADD COLUMN erp_employee_id VARCHAR(100) NULL AFTER ihs_number"))
                print("Column added.")
                
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    update_table()
