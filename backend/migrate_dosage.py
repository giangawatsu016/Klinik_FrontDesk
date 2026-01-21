import sqlite3

def migrate():
    conn = sqlite3.connect("klinik.db")
    cursor = conn.cursor()
    
    try:
        cursor.execute("ALTER TABLE medicinecore ADD COLUMN dosageForm VARCHAR(50)")
        print("Success: Added dosageForm column to medicinecore")
    except sqlite3.OperationalError as e:
        print(f"Skipped: {e}")
        
    conn.commit()
    conn.close()

if __name__ == "__main__":
    migrate()
