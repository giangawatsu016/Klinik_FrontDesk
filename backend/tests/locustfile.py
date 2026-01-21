from locust import HttpUser, task, between
import random

class KlinikUser(HttpUser):
    wait_time = between(1, 3)
    host = "http://localhost:8001"
    
    def on_start(self):
        # Login and store token
        response = self.client.post("/auth/login", data={"username": "admin", "password": "admin123"})
        if response.status_code == 200:
            token = response.json()["access_token"]
            self.client.headers.update({"Authorization": f"Bearer {token}"})
        else:
            print(f"Login failed: {response.text}")

    @task(2)
    def index(self):
        self.client.get("/")

    @task(1)
    def view_doctors(self):
        self.client.get("/doctors")

    @task(1)
    def view_patients(self):
        self.client.get("/patients")

    @task(1)
    def view_queue(self):
        self.client.get("/queue")

    # Simulate Search
    @task(1)
    def search_patient(self):
        self.client.get("/patients?search=Budi")
