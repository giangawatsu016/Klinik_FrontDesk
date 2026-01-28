from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from .database import engine, Base
from .routers import auth, patients, queue, master_data, medicines, users, integration, doctors, diseases, dashboard, payments, pharmacists, config, appointments
import os
from dotenv import load_dotenv
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from .limiter import limiter

from pathlib import Path

env_path = Path(__file__).parent / '.env'
load_dotenv(dotenv_path=env_path)


# Create Tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Klinik Admin API")

# Rate Limiter Configuration
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Flexible CORS for Development (Allows any localhost port)
# In production, you might want to switch back to strict allow_origins from env
# Flexible CORS for Development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.middleware("http")
async def add_cors_header(request: Request, call_next):
    if request.method == "OPTIONS":
        from fastapi.responses import Response
        response = Response()
        response.headers["Access-Control-Allow-Origin"] = "*"
        response.headers["Access-Control-Allow-Methods"] = "*"
        response.headers["Access-Control-Allow-Headers"] = "*"
        return response
    response = await call_next(request)
    response.headers["Access-Control-Allow-Origin"] = "*"
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
