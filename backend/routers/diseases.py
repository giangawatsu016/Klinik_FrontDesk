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
        from_attributes = True

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

@router.post("/sync")
def sync_diseases_pull(db: Session = Depends(database.get_db), current_user: models.User = Depends(dependencies.get_current_user)):
    """Pull Icd Codes from ERPNext (Diagnosis)"""
    from ..services.frappe_service import frappe_client
    
    # Fetch from ERPNext
    erp_diagnoses = frappe_client.get_list("Diagnosis", filters={}) # Get all? Limit?
    # get_list by default fetches names. We need code and description.
    # We might need to update get_list to accept fields or use a custom call here for simplicity.
    
    # Custom fetch to get fields
    import requests
    import json
    
    count = 0
    try:
        url = f"{frappe_client.base_url}/api/resource/Diagnosis"
        params = {
            "fields": '["name", "code", "description"]',
            "limit_page_length": 1000 # Fetch reasonable amount
        }
        resp = requests.get(url, headers=frappe_client.headers, params=params, timeout=10)
        if resp.status_code == 200:
            data = resp.json().get("data", [])
            for item in data:
                code = item.get("code")
                desc = item.get("description") or item.get("name") # Fallback
                
                existing = db.query(models.Disease).filter(models.Disease.icd_code == code).first()
                if not existing:
                    new_d = models.Disease(
                        icd_code=code,
                        name=desc, # Use description as name or code?
                        description=desc,
                        is_active=True
                    )
                    db.add(new_d)
                    count += 1
            db.commit()
    except Exception as e:
        print(f"Error pulling diseases: {e}")
        return {"status": "failed", "message": str(e)}

    return {"status": "success", "count": count}

@router.post("/sync/push")
def sync_diseases_push(db: Session = Depends(database.get_db), current_user: models.User = Depends(dependencies.get_current_user)):
    from ..services.frappe_service import frappe_client
    
    # Push Local -> ERPNext
    diseases = db.query(models.Disease).all()
    count = 0
    errors = 0
    
    for disease in diseases:
        result = frappe_client.create_diagnosis(disease.icd_code, disease.name)
        if result:
            count += 1
        else:
            errors += 1
            
    return {"status": "success", "synced": count, "errors": errors}
