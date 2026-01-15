from sqlalchemy.orm import Session
from backend.database import SessionLocal, engine
from backend import models
from backend.auth_utils import get_password_hash

# Ensure tables exist (Recreate to apply schema changes)
try:
    models.User.__table__.drop(bind=engine)
    print("Dropped User table to apply schema changes.")
except Exception as e:
    print(f"Table drop skipped: {e}")

models.Base.metadata.create_all(bind=engine)

def reset_users():
    db = SessionLocal()
    try:
        # Delete all users (Redundant if dropped, but good for safety)
        db.query(models.User).delete()
        
        # Create Super Admin
        super_admin = models.User(
            username="superadmin",
            email="superadmin@klinik.local",
            password_hash=get_password_hash("password"),
            full_name="Super Administrator",
            role="Super Admin"
        )
        
        # Create Administrator
        admin = models.User(
            username="admin",
            email="admin@klinik.local",
            password_hash=get_password_hash("password"),
            full_name="System Administrator",
            role="Administrator"
        )
        
        # Create Staff
        staff = models.User(
            username="staff",
            email="staff@klinik.local",
            password_hash=get_password_hash("password"),
            full_name="Staff Member",
            role="Staff"
        )
        
        db.add_all([super_admin, admin, staff])
        db.commit()
        print("Created: superadmin, admin, staff")
        print("Users reset successfully.")
    except Exception as e:
        print(f"Error resetting users: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    reset_users()
