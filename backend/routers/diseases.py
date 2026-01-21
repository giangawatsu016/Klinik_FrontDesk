from fastapi import APIRouter, Depends, HTTPException
from typing import List, Optional
from sqlalchemy.orm import Session
from .. import models, schemas, database, dependencies
from pydantic import BaseModel

router = APIRouter(
    prefix="/diseases",
    tags=["diseases"]
)

# Pydantic Schemas for Disease
class DiseaseBase(BaseModel):
    icd_code: str
    name: str
    description: Optional[str] = None
    is_active: bool = True

class DiseaseCreate(DiseaseBase):
    pass

class Disease(DiseaseBase):
    id: int
    class Config:
        orm_mode = True

@router.get("", response_model=List[Disease])
def get_diseases(search: str = "", skip: int = 0, limit: int = 100, db: Session = Depends(database.get_db)):
    query = db.query(models.Disease)
    if search:
        query = query.filter(
            (models.Disease.name.contains(search)) | 
            (models.Disease.icd_code.contains(search))
        )
    return query.offset(skip).limit(limit).all()

@router.post("", response_model=Disease)
def create_disease(disease: DiseaseCreate, db: Session = Depends(database.get_db), current_user: models.User = Depends(dependencies.get_current_user)):
    # Check duplicate ICD
    existing = db.query(models.Disease).filter(models.Disease.icd_code == disease.icd_code).first()
    if existing:
        raise HTTPException(status_code=400, detail="Disease with this ICD Code already exists")
    
    new_disease = models.Disease(**disease.dict())
    db.add(new_disease)
    db.commit()
    db.refresh(new_disease)
    return new_disease

@router.put("/{disease_id}", response_model=Disease)
def update_disease(disease_id: int, disease_update: DiseaseCreate, db: Session = Depends(database.get_db), current_user: models.User = Depends(dependencies.get_current_user)):
    db_disease = db.query(models.Disease).filter(models.Disease.id == disease_id).first()
    if not db_disease:
        raise HTTPException(status_code=404, detail="Disease not found")
    
    for key, value in disease_update.dict().items():
        setattr(db_disease, key, value)
    
    db.commit()
    db.refresh(db_disease)
    return db_disease

@router.delete("/{disease_id}")
def delete_disease(disease_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(dependencies.get_current_user)):
    db_disease = db.query(models.Disease).filter(models.Disease.id == disease_id).first()
    if not db_disease:
        raise HTTPException(status_code=404, detail="Disease not found")
    
    db.delete(db_disease)
    db.commit()
    return {"message": "Disease deleted"}
