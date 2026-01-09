from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .database import engine, Base
from .routers import auth, patients, master_data, queue

# Create Tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Klinik Admin API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
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
