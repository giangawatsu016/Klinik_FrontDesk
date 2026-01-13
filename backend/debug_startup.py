from fastapi.testclient import TestClient
import sys
import os

# Add parent directory to path
sys.path.append(os.getcwd())

try:
    print("Attempting to import backend.main...")
    from backend.main import app
    print("Import successful.")
    
    client = TestClient(app)
    
    print("Attempting to hit health check...")
    response = client.get("/")
    print(f"Health check status: {response.status_code}")
    print(f"Response: {response.json()}")
    
    print("Attempting to hit patients list...")
    # Just to see if router is mounted and db works
    from backend.auth_utils import create_access_token
    token = create_access_token(data={"sub": "admin"})
    response = client.get("/patients/", headers={"Authorization": f"Bearer {token}"})
    print(f"Patients list status: {response.status_code}")
    
except Exception as e:
    print(f"CRITICAL STARTUP ERROR: {e}")
    import traceback
    traceback.print_exc()
