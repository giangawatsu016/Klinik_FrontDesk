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

app = FastAPI(title="Klinik Admin API")

@app.middleware("http")
async def cors_handler(request: Request, call_next):
    # Log incoming request
    print(f"Request: {request.method} {request.url}")
    
    if request.method == "OPTIONS":
        response = Response(status_code=204)
        response.headers["Access-Control-Allow-Origin"] = "*"
        response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
        response.headers["Access-Control-Allow-Headers"] = "*"
        response.headers["Access-Control-Max-Age"] = "86400"
        return response

    try:
        response = await call_next(request)
    except Exception as e:
        print(f"Error handling request: {e}")
        response = Response(content="Internal Server Error", status_code=500)

    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "*"
    return response

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
