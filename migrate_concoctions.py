from backend.database import engine, Base
from backend.models import MedicineConcoction
from sqlalchemy import inspect

def migrate():
    inspector = inspect(engine)
    if "medicine_concoctions" not in inspector.get_table_names():
        print("Creating table medicine_concoctions...")
        MedicineConcoction.__table__.create(engine)
        print("Done.")
    else:
        print("Table medicine_concoctions already exists.")

if __name__ == "__main__":
    migrate()
