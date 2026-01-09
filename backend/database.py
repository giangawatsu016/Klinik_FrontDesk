from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Database URL - Replace user/password/db with actual values
# For local dev, assuming default XAMPP/MAMP or similar: root with no password or root/root
# DATABASE_URL = "mysql+pymysql://root:@localhost/klinik_db"
SQLALCHEMY_DATABASE_URL = "sqlite:///./klinik.db"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
