import requests
import json
from datetime import datetime

BASE_URL = "http://localhost:8001"

def check_queue():
    try:
        response = requests.get(f"{BASE_URL}/queues/", timeout=5)
        if response.status_code == 200:
            queues = response.json()
            print(f"API Returned {len(queues)} items for TODAY.")
            for q in queues:
                print(f" - ID: {q['id']}, No: {q['numberQueue']}, Time: {q['appointmentTime']}")
        else:
             print(f"Failed to fetch queues: {response.text}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_queue()
