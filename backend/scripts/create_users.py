import sys
import os

# Add the parent directory to sys.path to resolve 'backend' modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from backend.models import User, Base
from backend.auth_utils import get_password_hash
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Database setup
DB_USER = os.getenv("DB_USER", "root")
DB_PASS = os.getenv("DB_PASSWORD", "")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_NAME = os.getenv("DB_NAME", "klinik_admin")

DATABASE_URL = f"mysql+pymysql://{DB_USER}:{DB_PASS}@{DB_HOST}/{DB_NAME}"
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def create_users():
    db = SessionLocal()
    try:
        # Define users to create
        users_to_create = [
            {"username": "super", "password": "super123", "role": "super_admin", "name": "Super Admin"},
            {"username": "admin", "password": "admin123", "role": "admin", "name": "Administrator"},
            {"username": "staff", "password": "staff123", "role": "staff", "name": "Front Desk Staff"},
        ]

        print("--- Creating Users ---")
        for user_data in users_to_create:
            # Check if user exists
            existing_user = db.query(User).filter(User.username == user_data["username"]).first()
            
            if existing_user:
                print(f"User '{user_data['username']}' already exists. Updating role/password...")
                existing_user.password_hash = get_password_hash(user_data["password"])
                existing_user.role = user_data["role"]
                existing_user.full_name = user_data["name"]
            else:
                print(f"Creating new user '{user_data['username']}' ({user_data['role']})...")
                new_user = User(
                    username=user_data["username"],
                    password_hash=get_password_hash(user_data["password"]),
                    full_name=user_data["name"],
                    role=user_data["role"]
                )
                db.add(new_user)
        
        db.commit()
        print("--- Success! All users created/updated. ---")
        print("\nCredentials:")
        for user in users_to_create:
            print(f"Username: {user['username']} | Password: {user['password']} | Role: {user['role']}")

    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    create_users()
