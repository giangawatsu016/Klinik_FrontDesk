import sys
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Add parent dir to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))

from backend.database import SQLALCHEMY_DATABASE_URL
from backend import models

def cleanup_superadmin():
    print("Connecting to database...")
    engine = create_engine(SQLALCHEMY_DATABASE_URL)
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionLocal()

    try:
        # 1. Delete user 'superadmin' (The specific default account)
        superadmin_user = db.query(models.User).filter(models.User.username == "superadmin").first()
        if superadmin_user:
            print(f"Found user 'superadmin' (ID: {superadmin_user.id}). Deleting...")
            db.delete(superadmin_user)
            db.commit()
            print("User 'superadmin' deleted successfully.")
        else:
            print("User 'superadmin' not found.")

        # 2. Migrate any other 'Super Admin' roles to 'Administrator'
        # Because the app no longer supports 'Super Admin' role logic.
        other_supers = db.query(models.User).filter(models.User.role == "Super Admin").all()
        for user in other_supers:
            print(f"Migrating user '{user.username}' from 'Super Admin' to 'Administrator'...")
            user.role = "Administrator"
        
        if other_supers:
            db.commit()
            print(f"Migrated {len(other_supers)} users.")
        else:
            print("No other users with 'Super Admin' role found.")

    except Exception as e:
        print(f"Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    cleanup_superadmin()
