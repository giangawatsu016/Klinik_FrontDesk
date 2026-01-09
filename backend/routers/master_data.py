from fastapi import APIRouter, Depends, HTTPException
from typing import List
from sqlalchemy.orm import Session
from .. import models, schemas, database

router = APIRouter(
    prefix="/master",
    tags=["master"]
)

@router.get("/marital-status", response_model=List[schemas.MaritalStatus])
def get_marital_statuses(db: Session = Depends(database.get_db)):
    return db.query(models.MaritalStatus).all()

@router.post("/marital-status", response_model=schemas.MaritalStatus)
def create_marital_status(status: schemas.MaritalStatusBase, db: Session = Depends(database.get_db)):
    new_status = models.MaritalStatus(display=status.display)
    db.add(new_status)
    db.commit()
    db.refresh(new_status)
    return new_status

@router.get("/issuers", response_model=List[schemas.Issuer])
def get_issuers(db: Session = Depends(database.get_db)):
    return db.query(models.Issuer).all()

@router.post("/issuers", response_model=schemas.Issuer)
def create_issuer(issuer: schemas.IssuerBase, db: Session = Depends(database.get_db)):
    new_issuer = models.Issuer(issuer=issuer.issuer, nama=issuer.nama)
    db.add(new_issuer)
    db.commit()
    db.refresh(new_issuer)
    return new_issuer

@router.get("/doctors", response_model=List[schemas.Doctor])
def get_doctors(db: Session = Depends(database.get_db)):
    return db.query(models.DoctorEntity).all()

@router.post("/doctors", response_model=schemas.Doctor)
def create_doctor(doctor: schemas.DoctorBase, db: Session = Depends(database.get_db)):
    new_doctor = models.DoctorEntity(**doctor.dict())
    db.add(new_doctor)
    db.commit()
    db.refresh(new_doctor)
    return new_doctor

@router.get("/address/provinces")
def get_provinces():
    # Placeholder for Indonesian provinces
    return [
        {"id": "1", "name": "DKI Jakarta"},
        {"id": "2", "name": "Jawa Barat"},
        {"id": "3", "name": "Jawa Tengah"},
        {"id": "4", "name": "Jawa Timur"},
        # Add more or fetch from external source
    ]

# Add similar endpoints for cities/districts based on province ID
