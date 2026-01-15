from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from .database import engine, Base
from .routers import auth, patients, queue, master_data, medicines, users, integration
import os
from dotenv import load_dotenv
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from .limiter import limiter

load_dotenv()


# Create Tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Klinik Admin API")

# Rate Limiter Configuration
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Flexible CORS for Development (Allows any localhost port)
# In production, you might want to switch back to strict allow_origins from env
app.add_middleware(
    CORSMiddleware,
    # Allow any localhost/127.0.0.1 port
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(patients.router)
app.include_router(master_data.router)
app.include_router(medicines.router)
app.include_router(users.router)
app.include_router(integration.router)

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
