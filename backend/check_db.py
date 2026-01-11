from database import SessionLocal, engine
from sqlalchemy import text

def check_connection():
    try:
        # Try to connect
        with engine.connect() as connection:
            result = connection.execute(text("SELECT 1"))
            print("Database connection successful!")
            print(f"Result: {result.fetchone()[0]}")
    except Exception as e:
        print(f"Database connection failed: {e}")

if __name__ == "__main__":
    check_connection()
