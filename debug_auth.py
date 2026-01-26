from backend.database import SessionLocal
from backend import models

db = SessionLocal()

print("--- Users ---")
users = db.query(models.User).all()
for u in users:
    print(f"ID: {u.id}, Username: '{u.username}', Role: '{u.role}'")

print("\n--- App Config ---")
configs = db.query(models.AppConfig).all()
for c in configs:
    print(f"Key: '{c.key}', Value: '{c.value}'")

db.close()
