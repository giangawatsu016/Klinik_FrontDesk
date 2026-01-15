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
    return db.query(models.DoctorEntity).order_by(models.DoctorEntity.namaDokter.asc()).all()

@router.post("/doctors", response_model=schemas.Doctor)
def create_doctor(doctor: schemas.DoctorBase, db: Session = Depends(database.get_db)):
    new_doctor = models.DoctorEntity(**doctor.dict())
    db.add(new_doctor)
    db.commit()
    db.refresh(new_doctor)

    # Sync to ERPNext
    try:
        from ..services.frappe_service import frappe_client
        name_parts = doctor.namaDokter.split(" ", 1)
        first_name = name_parts[0]
        last_name = name_parts[1] if len(name_parts) > 1 else ""
        frappe_client.create_practitioner(first_name, last_name, doctor.polyName)
    except Exception as e:
        print(f"Failed to sync new doctor to ERPNext: {e}")

    return new_doctor

@router.put("/doctors/{doctor_id}", response_model=schemas.Doctor)
def update_doctor(doctor_id: int, doctor_update: schemas.DoctorBase, db: Session = Depends(database.get_db)):
    db_doctor = db.query(models.DoctorEntity).filter(models.DoctorEntity.medicalFacilityPolyDoctorId == doctor_id).first()
    if not db_doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")
    
    # Update Local
    old_name = db_doctor.namaDokter # Keep for finding in ERPNext if needed
    
    db_doctor.namaDokter = doctor_update.namaDokter
    db_doctor.gelarDepan = doctor_update.gelarDepan
    db_doctor.polyName = doctor_update.polyName
    
    db.commit()
    db.refresh(db_doctor)

    # Sync to ERPNext
    try:
        from ..services.frappe_service import frappe_client
        # 1. Find Practitioner ID by Old Name (or New Name if not changed) in ERPNext
        # Since we don't store Frappe ID, we search.
        erp_docs = frappe_client.get_list("Healthcare Practitioner", filters={"practitioner_name": old_name})
        
        if erp_docs:
            frappe_id = erp_docs[0].get("name")
            
            # 2. Update
            name_parts = doctor_update.namaDokter.split(" ", 1)
            first_name = name_parts[0]
            last_name = name_parts[1] if len(name_parts) > 1 else ""
            
            update_data = {
                "first_name": first_name,
                "last_name": last_name,
                "department": doctor_update.polyName
            }
            frappe_client.update_practitioner(frappe_id, update_data)
        else:
            print("Skipping ERPNext sync: Practitioner not found by name.")
            
    except Exception as e:
        print(f"Failed to sync update to ERPNext: {e}")

    return db_doctor

from ..services.frappe_service import frappe_client

@router.post("/doctors/sync")
def sync_doctors(db: Session = Depends(database.get_db)):
    # 1. Fetch from Frappe
    erp_doctors = frappe_client.get_doctors()
    if not erp_doctors:
        return {"status": "failed", "message": "No doctors found or Frappe error", "count": 0}

    count = 0
    # 2. Sync to Local DB
    # Mapping: practitioner_name -> namaDokter, department -> polyName
    for doc in erp_doctors:
        name = doc.get("practitioner_name")
        dept = doc.get("department") or "General"
        
        # Check if exists by name (simple check)
        existing = db.query(models.DoctorEntity).filter(models.DoctorEntity.namaDokter == name).first()
        if not existing:
             new_doc = models.DoctorEntity(
                 medicalFacilityPolyDoctorId=0, # Ignored/Auto
                 namaDokter=name,
                 gelarDepan="Dr.", # Default title as it's not always in Practitioner
                 polyName=dept
             )
             db.add(new_doc)
             count += 1
    
    if count > 0:
        db.commit()
        
    return {"status": "success", "count": count}


import requests

BASE_URL_WILAYAH = "https://www.emsifa.com/api-wilayah-indonesia/api"

from functools import lru_cache

@router.get("/address/provinces")
@lru_cache(maxsize=1)
def get_provinces():
    try:
        resp = requests.get(f"{BASE_URL_WILAYAH}/provinces.json", timeout=10)
        if resp.status_code == 200:
            return resp.json()
    except Exception as e:
        print(f"Error fetching provinces: {e}")
    return []

@router.get("/address/cities/{province_id}")
async def get_cities(province_id: str):
    try:
        resp = requests.get(f"{BASE_URL_WILAYAH}/regencies/{province_id}.json", timeout=10)
        if resp.status_code == 200:
            return resp.json()
    except Exception as e:
        print(f"Error fetching cities: {e}")
    return []

@router.get("/address/districts/{city_id}")
async def get_districts(city_id: str):
    try:
        resp = requests.get(f"{BASE_URL_WILAYAH}/districts/{city_id}.json", timeout=10)
        if resp.status_code == 200:
            return resp.json()
    except Exception as e:
        print(f"Error fetching districts: {e}")
    return []

@router.get("/address/subdistricts/{district_id}")
async def get_subdistricts(district_id: str):
    try:
        resp = requests.get(f"{BASE_URL_WILAYAH}/villages/{district_id}.json", timeout=10)
        if resp.status_code == 200:
            return resp.json()
    except Exception as e:
        print(f"Error fetching subdistricts: {e}")
    return []
