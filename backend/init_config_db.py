from backend.database import engine, Base
from backend.models import AppConfig
from sqlalchemy import inspect

def init_db():
    inspector = inspect(engine)
    if not inspector.has_table("app_config"):
        print("Creating app_config table...")
        Base.metadata.create_all(bind=engine)
        print("AppConfig table created.")
    else:
        print("AppConfig table already exists.")

if __name__ == "__main__":
    init_db()
