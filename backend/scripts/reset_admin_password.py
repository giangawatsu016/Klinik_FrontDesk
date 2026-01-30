import sys
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Add parent dir to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))

from backend.database import SQLALCHEMY_DATABASE_URL
from backend import models, auth_utils

def reset_password(username, new_password):
    print(f"Connecting to database to reset password for '{username}'...")
    engine = create_engine(SQLALCHEMY_DATABASE_URL)
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionLocal()

    try:
        user = db.query(models.User).filter(models.User.username == username).first()
        if user:
            print(f"User found: {user.username} (Role: {user.role})")
            
            # Hash the new password
            hashed_pw = auth_utils.get_password_hash(new_password)
            user.password_hash = hashed_pw
            
            # Ensure user is active if that flag exists (it strictly should based on schemas)
            if hasattr(user, 'is_active'):
                user.is_active = True
                print(" ensured is_active=True")
                
            db.commit()
            print(f"Password for '{username}' has been RESET to '{new_password}'.")
        else:
            print(f"User '{username}' not found.")

    except Exception as e:
        print(f"Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    reset_password("admin1", "1234")
