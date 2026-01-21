from fastapi import APIRouter, Depends, HTTPException
from typing import List
from sqlalchemy.orm import Session
from .. import models, schemas, database, dependencies
from ..services.frappe_service import frappe_client
import uuid

router = APIRouter(
    prefix="/medicines",
    tags=["medicines"]
)

@router.get("/", response_model=List[schemas.Medicine])
def get_medicines(skip: int = 0, limit: int = 100, db: Session = Depends(database.get_db), current_user: models.User = Depends(dependencies.get_current_user)):
    return db.query(models.Medicine).offset(skip).limit(limit).all()

@router.post("/", response_model=schemas.Medicine)
def create_medicine(medicine: schemas.MedicineCreate, db: Session = Depends(database.get_db), current_user: models.User = Depends(dependencies.get_current_user)):
    # Generate fake code if manual
    code = medicine.erpnextItemCode
    if not code:
        code = f"MANUAL-{uuid.uuid4().hex[:8].upper()}"
        
    new_med = models.Medicine(
        erpnext_item_code=code,
        medicineName=medicine.medicineName,
        medicineDescription=medicine.medicineDescription,
        qty=medicine.qty,
        unit=medicine.unit,
        medicineLabel=medicine.medicineLabel,
        medicinePrice=medicine.medicinePrice,
        medicineRetailPrice=medicine.medicineRetailPrice,
        howToConsume=medicine.howToConsume,
        notes=medicine.notes,
        signa1=medicine.signa1,
        signa2=medicine.signa2
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
            existing_med.medicineName = item.get("item_name")
            existing_med.medicineDescription = item.get("description")
            existing_med.unit = item.get("stock_uom")
            existing_med.qty = int(stock_qty)
        else:
            # Create
            new_med = models.Medicine(
                erpnext_item_code=item_code,
                medicineName=item.get("item_name"),
                medicineDescription=item.get("description"),
                unit=item.get("stock_uom"),
                qty=int(stock_qty),
                medicinePrice=0,
                medicineRetailPrice=0
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
    db_med.medicineName = medicine_update.medicineName
    db_med.qty = medicine_update.qty
    db_med.unit = medicine_update.unit
    db_med.medicineDescription = medicine_update.medicineDescription
    
    # New Fields
    db_med.medicineLabel = medicine_update.medicineLabel
    db_med.medicinePrice = medicine_update.medicinePrice
    db_med.medicineRetailPrice = medicine_update.medicineRetailPrice
    db_med.howToConsume = medicine_update.howToConsume
    db_med.notes = medicine_update.notes
    db_med.signa1 = medicine_update.signa1
    db_med.signa2 = medicine_update.signa2

    if medicine_update.erpnextItemCode:
        db_med.erpnext_item_code = medicine_update.erpnextItemCode

    db.commit()
    db.refresh(db_med)
    return db_med

@router.delete("/{medicine_id}")
def delete_medicine(medicine_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(dependencies.get_current_user)):
    db_med = db.query(models.Medicine).filter(models.Medicine.id == medicine_id).first()
    if not db_med:
        raise HTTPException(status_code=404, detail="Medicine not found")
    
    db.delete(db_med)
    db.commit()
    return {"message": "Medicine deleted successfully"}

@router.post("/concoctions", response_model=schemas.Medicine)
def create_concoction(concoction: schemas.ConcoctionCreate, db: Session = Depends(database.get_db), current_user: models.User = Depends(dependencies.get_current_user)):
    # 1. Calculate Price & Verify Items
    total_price = 0
    
    # We need to verify all child items exist to avoid FK errors
    for item in concoction.items:
        child_med = db.query(models.Medicine).get(item.child_medicine_id)
        if not child_med:
             raise HTTPException(status_code=404, detail=f"Ingredient ID {item.child_medicine_id} not found")
        
        # Determine price (use RetailPrice if available, or just Price?)
        # For cost calculation, usually we use Buy Price + Margin or Retail Price.
        # Let's say we sum up the Retail Price of ingredients to be safe, or as defined policy.
        price_per_unit = child_med.medicineRetailPrice if child_med.medicineRetailPrice else 0
        total_price += (price_per_unit * item.qty)

    # Add Service Fee
    total_price += (concoction.serviceFee or 0)
    
    # 2. Create Parent Medicine
    code = f"RACIKAN-{uuid.uuid4().hex[:8].upper()}"
    new_med = models.Medicine(
        erpnext_item_code=code,
        medicineName=concoction.medicineName,
        medicineDescription=concoction.description or "Racikan / Concoction",
        qty=concoction.totalQty,
        unit=concoction.unit,
        medicinePrice=0, # Cost price complex to calc, set 0 for now
        medicineRetailPrice=int(total_price), # Sell Price
        medicineLabel="Racikan"
    )
    db.add(new_med)
    db.commit()
    db.refresh(new_med)
    
    # 3. Create Links
    for item in concoction.items:
        link = models.MedicineConcoction(
            parent_medicine_id=new_med.id,
            child_medicine_id=item.child_medicine_id,
            qty_needed=item.qty
        )
        db.add(link)
    
    db.commit()
    return new_med
