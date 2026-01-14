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
