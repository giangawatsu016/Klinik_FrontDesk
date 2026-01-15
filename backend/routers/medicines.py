from fastapi import APIRouter, Depends, HTTPException
from typing import List
from sqlalchemy.orm import Session
from .. import models, schemas, database, dependencies
from ..services.frappe_service import frappe_client

router = APIRouter(
    prefix="/medicines",
    tags=["medicines"]
)

@router.get("/", response_model=List[schemas.Medicine])
def get_medicines(skip: int = 0, limit: int = 100, db: Session = Depends(database.get_db), current_user: models.User = Depends(dependencies.get_current_user)):
    return db.query(models.Medicine).offset(skip).limit(limit).all()

import uuid

@router.post("/", response_model=schemas.Medicine)
def create_medicine(medicine: schemas.MedicineCreate, db: Session = Depends(database.get_db), current_user: models.User = Depends(dependencies.get_current_user)):
    # Generate fake code if manual
    code = medicine.erpnext_item_code
    if not code:
        code = f"MANUAL-{uuid.uuid4().hex[:8].upper()}"
        
    new_med = models.Medicine(
        erpnext_item_code=code,
        name=medicine.name,
        description=medicine.description,
        stock=medicine.stock,
        unit=medicine.unit
    )
    db.add(new_med)
    db.commit()
    db.refresh(new_med)
    return new_med

@router.post("/sync")
def sync_medicines(db: Session = Depends(database.get_db), current_user: models.User = Depends(dependencies.get_current_user)):
    # 1. Fetch Items from ERPNext
    items = frappe_client.get_items()
    if not items:
        # Use existing if fetch fails? Or raise error?
        # For now, just return empty with message
        return {"status": "failed", "message": "Failed to fetch items from ERPNext", "count": 0}

    synced_count = 0
    
    for item in items:
        item_code = item.get("name") # In Frappe, name is the ID (item_code)
        
        # 2. Get Stock
        stock_qty = frappe_client.get_item_stock(item_code)
        
        # 3. Check if exists
        existing_med = db.query(models.Medicine).filter(models.Medicine.erpnext_item_code == item_code).first()
        
        if existing_med:
            # Update
            existing_med.name = item.get("item_name")
            existing_med.description = item.get("description")
            existing_med.unit = item.get("stock_uom")
            existing_med.stock = int(stock_qty)
        else:
            # Create
            new_med = models.Medicine(
                erpnext_item_code=item_code,
                name=item.get("item_name"),
                description=item.get("description"),
                unit=item.get("stock_uom"),
                stock=int(stock_qty)
            )
            db.add(new_med)
            
        synced_count += 1
    
    db.commit()
    return {"status": "success", "count": synced_count}
@router.put("/{medicine_id}", response_model=schemas.Medicine)
def update_medicine(medicine_id: int, medicine_update: schemas.MedicineCreate, db: Session = Depends(database.get_db), current_user: models.User = Depends(dependencies.get_current_user)):
    db_med = db.query(models.Medicine).filter(models.Medicine.id == medicine_id).first()
    if not db_med:
        raise HTTPException(status_code=404, detail="Medicine not found")
    
    # Update fields
    db_med.name = medicine_update.name
    db_med.stock = medicine_update.stock
    db_med.unit = medicine_update.unit
    db_med.description = medicine_update.description
    # We generally don't update erpnext_item_code unless specific reason, kept as is for now or update if needed
    if medicine_update.erpnext_item_code:
        db_med.erpnext_item_code = medicine_update.erpnext_item_code

    db.commit()
    db.refresh(db_med)
    return db_med
