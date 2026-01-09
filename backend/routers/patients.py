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
    # Check if existing
    if db.query(models.Patient).filter(models.Patient.identityCard == patient.identityCard).first():
        raise HTTPException(status_code=400, detail="Patient with this ID Card already exists")
    
    new_patient = models.Patient(**patient.dict())
    db.add(new_patient)
    db.commit()
    db.refresh(new_patient)
    
    # Sync to Frappe in background
    background_tasks.add_task(frappe_client.create_patient, patient.dict())
    
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
