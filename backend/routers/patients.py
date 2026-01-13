from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from typing import List
from sqlalchemy.orm import Session
from .. import models, schemas, database, dependencies
from ..services.frappe_service import frappe_client

router = APIRouter(
    prefix="/patients",
    tags=["patients"]
)

@router.post("/", response_model=schemas.Patient)
def create_patient(patient: schemas.PatientCreate, background_tasks: BackgroundTasks, db: Session = Depends(database.get_db), current_user: models.User = Depends(dependencies.get_current_user)):
    # Check if existing by ID Card
    if db.query(models.Patient).filter(models.Patient.identityCard == patient.identityCard).first():
        raise HTTPException(status_code=400, detail="Patient with this ID Card already exists")
    
    # Check if existing by Phone
    if db.query(models.Patient).filter(models.Patient.phone == patient.phone).first():
        raise HTTPException(status_code=400, detail="Patient with this Phone Number already exists")
    
    # 1. Sync to Frappe First (Synchronous) to get ID
    frappe_id = None
    try:
        frappe_response = frappe_client.create_patient(patient.dict())
        if frappe_response and "data" in frappe_response:
             frappe_id = frappe_response["data"].get("name")
    except Exception as e:
        print(f"Frappe Sync Error: {e}")
        # Continue creation even if sync fails, we can retry later

    # 2. Create Local Patient
    patient_data = patient.dict()
    patient_data["frappe_id"] = frappe_id # Now it's a String or None
    
    new_patient = models.Patient(**patient_data)
    db.add(new_patient)
    db.commit()
    db.refresh(new_patient)
    
    return new_patient

@router.get("/", response_model=List[schemas.Patient])
def get_patients(skip: int = 0, limit: int = 100, db: Session = Depends(database.get_db), current_user: models.User = Depends(dependencies.get_current_user)):
    return db.query(models.Patient).offset(skip).limit(limit).all()

@router.get("/search", response_model=List[schemas.Patient])
def search_patients(query: str, db: Session = Depends(database.get_db), current_user: models.User = Depends(dependencies.get_current_user)):
    # Simple search by name or ID
    return db.query(models.Patient).filter(
        (models.Patient.firstName.contains(query)) | 
        (models.Patient.lastName.contains(query)) | 
        (models.Patient.identityCard.contains(query)) |
        (models.Patient.phone.contains(query))
    ).all()

@router.get("/{patient_id}", response_model=schemas.Patient)
def get_patient(patient_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(dependencies.get_current_user)):
    patient = db.query(models.Patient).filter(models.Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    return patient
