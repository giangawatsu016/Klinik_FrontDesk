import requests
import os
from pathlib import Path
from dotenv import load_dotenv

env_path = Path(__file__).parent / '.env'
load_dotenv(dotenv_path=env_path)

FRAPPE_URL = os.getenv("FRAPPE_URL")
FRAPPE_API_KEY = os.getenv("FRAPPE_API_KEY")
FRAPPE_API_SECRET = os.getenv("FRAPPE_API_SECRET")

def test_connection():
    if not FRAPPE_URL:
        print("FRAPPE_URL not set.")
        return

    url = f"{FRAPPE_URL}/api/method/frappe.auth.get_logged_user"
    headers = {
        "Authorization": f"token {FRAPPE_API_KEY}:{FRAPPE_API_SECRET}",
        "Accept": "application/json"
    }
    
    try:
        print(f"Connecting to {url}...")
        response = requests.get(url, headers=headers, timeout=5)
        if response.status_code == 200:
            print(f"Success! Logged in user: {response.json()}")
        else:
            print(f"Failed ({response.status_code}): {response.text}")
    except Exception as e:
        print(f"Connection Error: {e}")

if __name__ == "__main__":
    test_connection()
