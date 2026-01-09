from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from .database import engine, Base
from .routers import auth, patients, master_data, queue
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
    allow_origin_regex=".*",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(auth.router)
app.include_router(patients.router)
app.include_router(master_data.router)
app.include_router(queue.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to Klinik Admin API. Documentation at /docs"}
