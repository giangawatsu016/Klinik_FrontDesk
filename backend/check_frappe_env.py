import os
from pathlib import Path
from dotenv import load_dotenv

env_path = Path(__file__).parent / '.env'
load_dotenv(dotenv_path=env_path)

print("--- FRAPPE ENV CHECK ---")
print(f"FRAPPE_URL: '{os.getenv('FRAPPE_URL')}'")
print(f"FRAPPE_API_KEY: '{os.getenv('FRAPPE_API_KEY')}'")
print(f"FRAPPE_API_SECRET: '{os.getenv('FRAPPE_API_SECRET')}'")
print("------------------------")
