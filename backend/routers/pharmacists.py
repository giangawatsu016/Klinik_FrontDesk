from fastapi import APIRouter, Depends, HTTPException
from typing import List
from sqlalchemy.orm import Session
from .. import models, schemas, database

router = APIRouter(
    prefix="/pharmacists",
    tags=["pharmacists"]
)

@router.get("", response_model=List[schemas.Pharmacist])
def get_pharmacists(db: Session = Depends(database.get_db)):
    return db.query(models.Pharmacist).all()

@router.post("", response_model=schemas.Pharmacist)
def create_pharmacist(pharmacist: schemas.PharmacistCreate, db: Session = Depends(database.get_db)):
    new_pharmacist = models.Pharmacist(**pharmacist.dict())
    db.add(new_pharmacist)
    db.commit()
    db.refresh(new_pharmacist)
    return new_pharmacist

@router.put("/{pharmacist_id}", response_model=schemas.Pharmacist)
def update_pharmacist(pharmacist_id: int, pharmacist_update: schemas.PharmacistCreate, db: Session = Depends(database.get_db)):
    db_pharmacist = db.query(models.Pharmacist).filter(models.Pharmacist.id == pharmacist_id).first()
    if not db_pharmacist:
        raise HTTPException(status_code=404, detail="Pharmacist not found")
    
    for key, value in pharmacist_update.dict().items():
        setattr(db_pharmacist, key, value)
    
    db.commit()
    db.refresh(db_pharmacist)
    return db_pharmacist

@router.delete("/{pharmacist_id}")
def delete_pharmacist(pharmacist_id: int, db: Session = Depends(database.get_db)):
    db_pharmacist = db.query(models.Pharmacist).filter(models.Pharmacist.id == pharmacist_id).first()
    if not db_pharmacist:
        raise HTTPException(status_code=404, detail="Pharmacist not found")
    
    db.delete(db_pharmacist)
    db.commit()
    return {"message": "Pharmacist deleted successfully"}
