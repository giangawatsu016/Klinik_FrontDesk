import requests
import sys

def check_url(url):
    print(f"Checking {url}...")
    try:
        response = requests.get(url, timeout=2)
        print(f"Success! Status: {response.status_code}")
        print(f"Response: {response.json()}")
        return True
    except Exception as e:
        print(f"Failed: {e}")
        return False

print("--- DIAGNOSTIC START ---")
local_ok = check_url("http://localhost:8000/")
ip_ok = check_url("http://127.0.0.1:8000/")

if not local_ok and not ip_ok:
    print("\nCONCLUSION: The Backend Server is NOT RUNNING or blocking connections.")
elif local_ok and ip_ok:
    print("\nCONCLUSION: Server is running and accessible via BOTH localhost and IP.")
elif local_ok:
    print("\nCONCLUSION: Server accessible via localhost ONLY.")
elif ip_ok:
    print("\nCONCLUSION: Server accessible via 127.0.0.1 ONLY.")
