from fastapi import APIRouter, Depends, HTTPException
from typing import List
from sqlalchemy.orm import Session
from .. import models, schemas, database

router = APIRouter(
    prefix="/pharmacists",
    tags=["pharmacists"]
)

@router.get("", response_model=List[schemas.Pharmacist])
def get_pharmacists(skip: int = 0, limit: int = 100, db: Session = Depends(database.get_db)):
    return db.query(models.Pharmacist).offset(skip).limit(limit).all()

@router.post("", response_model=schemas.Pharmacist)
def create_pharmacist(pharmacist: schemas.PharmacistCreate, db: Session = Depends(database.get_db)):
    db_pharmacist = models.Pharmacist(
        name=pharmacist.name,
        sip_no=pharmacist.sip_no,
        ihs_number=pharmacist.ihs_number,
        erp_employee_id=pharmacist.erp_employee_id,
        is_active=pharmacist.is_active
    )
    db.add(db_pharmacist)
    db.commit()
    db.refresh(db_pharmacist)
    return db_pharmacist

@router.put("/{pharmacist_id}", response_model=schemas.Pharmacist)
def update_pharmacist(pharmacist_id: int, pharmacist: schemas.PharmacistCreate, db: Session = Depends(database.get_db)):
    db_pharmacist = db.query(models.Pharmacist).filter(models.Pharmacist.id == pharmacist_id).first()
    if not db_pharmacist:
        raise HTTPException(status_code=404, detail="Pharmacist not found")
    
    db_pharmacist.name = pharmacist.name
    db_pharmacist.sip_no = pharmacist.sip_no
    db_pharmacist.ihs_number = pharmacist.ihs_number
    db_pharmacist.erp_employee_id = pharmacist.erp_employee_id
    db_pharmacist.is_active = pharmacist.is_active
    
    db.commit()
    db.refresh(db_pharmacist)
    return db_pharmacist

@router.delete("/{pharmacist_id}", response_model=dict)
def delete_pharmacist(pharmacist_id: int, db: Session = Depends(database.get_db)):
    db_pharmacist = db.query(models.Pharmacist).filter(models.Pharmacist.id == pharmacist_id).first()
    if not db_pharmacist:
        raise HTTPException(status_code=404, detail="Pharmacist not found")
    
    db.delete(db_pharmacist)
    db.commit()
    return {"status": "success", "message": "Pharmacist deleted"}
