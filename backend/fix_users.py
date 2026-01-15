import sys
import os

# Add parent dir to path so 'backend' package is visible
current = os.path.dirname(os.path.realpath(__file__))
parent = os.path.dirname(current)
sys.path.append(parent)

from backend.database import SessionLocal, engine
from backend import models
from backend.auth_utils import get_password_hash

# Ensure tables
models.Base.metadata.create_all(bind=engine)

def cleanup_and_create():
    db = SessionLocal()
    try:
        # Delete existing 'admin' to avoid PK conflict if ID differs, or update
        existing = db.query(models.User).filter(models.User.username == "admin").first()
        if existing:
            db.delete(existing)
            db.commit()
            
        # Create new admin
        admin = models.User(
            username="admin",
            password_hash=get_password_hash("password"),
            full_name="System Administrator",
            role="Administrator"
        )
        db.add(admin)
        db.commit()
        print("SUCCESS: Admin user created/reset with password 'password'")
    except Exception as e:
        print(f"ERROR: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    cleanup_and_create()
