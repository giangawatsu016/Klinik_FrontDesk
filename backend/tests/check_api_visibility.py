import requests
import sys

BASE_URL = "http://localhost:8001"

def check_api():
    print(f"Checking API at {BASE_URL}")
    
    # 1. Login
    session = requests.Session()
    try:
        r = session.post(f"{BASE_URL}/auth/login", data={"username": "admin", "password": "password"})
        if r.status_code != 200:
            print(f"Login Failed: {r.status_code} {r.text}")
            return
        token = r.json()['access_token']
        headers = {"Authorization": f"Bearer {token}"}
        print("Login Success.")
    except Exception as e:
        print(f"Connection Failed: {e}")
        return

    # 2. Get Queue
    try:
        r = session.get(f"{BASE_URL}/patients/queue", headers=headers)
        print(f"Queue Status: {r.status_code}")
        data = r.json()
        print(f"Queue Items Count: {len(data)}")
        for item in data:
            print(f" - ID: {item['id']} | No: {item.get('numberQueue')} | Status: {item.get('status')} | Time: {item.get('appointmentTime')}")
            
    except Exception as e:
        print(f"Get Queue Failed: {e}")

if __name__ == "__main__":
    check_api()
