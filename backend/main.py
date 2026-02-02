from fastapi import FastAPI, Request, Response
from .database import engine, Base
from .routers import auth, patients, queue, master_data, medicines, users, integration, doctors, diseases, dashboard, payments, pharmacists, config, appointments
import os
from dotenv import load_dotenv
from pathlib import Path

env_path = Path(__file__).parent / '.env'
load_dotenv(dotenv_path=env_path)

# Create Tables
Base.metadata.create_all(bind=engine)

from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Klinik Admin API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(queue.router)
app.include_router(patients.router)
app.include_router(master_data.router)
app.include_router(medicines.router)
app.include_router(integration.router)
app.include_router(doctors.router)
app.include_router(diseases.router)
app.include_router(dashboard.router)
app.include_router(payments.router)
app.include_router(pharmacists.router)
app.include_router(config.router)
app.include_router(appointments.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to Klinik Admin API. Documentation at /docs"}

# Startup & Shutdown Events
@app.on_event("startup")
def startup_event():
    from .scheduler import start_scheduler
    start_scheduler()

@app.on_event("shutdown")
def shutdown_event():
    from .scheduler import shutdown_scheduler
    shutdown_scheduler()
