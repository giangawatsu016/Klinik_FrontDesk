from sqlalchemy.orm import Session
from database import SessionLocal, engine
import models
from auth_utils import get_password_hash

# Ensure tables exist
models.Base.metadata.create_all(bind=engine)

def reset_users():
    db = SessionLocal()
    try:
        # Delete all users
        num_deleted = db.query(models.User).delete()
        print(f"Deleted {num_deleted} existing users.")
        
        # Create Super Admin
        super_admin = models.User(
            username="superadmin",
            password_hash=get_password_hash("password"),
            full_name="Super Administrator",
            role="Super Admin"
        )
        
        # Create Administrator
        admin = models.User(
            username="admin",
            password_hash=get_password_hash("password"),
            full_name="System Administrator",
            role="Administrator"
        )
        
        # Create Staff
        staff = models.User(
            username="staff",
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
