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
        nik=pharmacist.nik,
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
    db_pharmacist.nik = pharmacist.nik
    db_pharmacist.sip_no = pharmacist.sip_no
    db_pharmacist.ihs_number = pharmacist.ihs_number
    db_pharmacist.erp_employee_id = pharmacist.erp_employee_id
    db_pharmacist.is_active = pharmacist.is_active
    
    db.commit()
    db.refresh(db_pharmacist)
    return db_pharmacist

    db.delete(db_pharmacist)
    db.commit()
    return {"status": "success", "message": "Pharmacist deleted"}

@router.post("/sync")
def sync_pharmacists_pull(db: Session = Depends(database.get_db)):
    """Pull data from ERPNext to App"""
    from ..services.frappe_service import frappe_client
    
    # 1. Fetch Practitioners (Pharmacists) from ERPNext
    # We filter by Role or Department if possible, but for now fetch all practitioners
    # and maybe check if they are pharmacists? 
    # Or just fetch all "Healthcare Practitioner" and if they match a naming convention?
    # In 'doctors.py', we fetch all. 
    # Here, we should probably fetch those with role 'Pharmacist' in ERPNext if modeled that way.
    # However, to simulate, let's just fetch all and assume we sync relevant ones by name or create locals.
    # Actually, simpler: Let's fetch all practitioners and if the name matches a local pharmacist, update.
    # If not, create new? That might mix Doctors and Pharmacists.
    # Ideally, ERPNext Healthcare Practitioner has 'Department'.
    # default_department="Pharmacy"?
    
    # For now, let's reuse get_practitioners but implementation-wise, 
    # we might need to filter.
    # Let's assume for this Prototype, we just pull everything and if it looks like a pharmacist (maybe "Apt." prefix?), we save as pharmacist?
    # Or cleaner: Since I don't control ERPNext data fully in this thought process, 
    # I will replicate the pattern but maybe rely on user to link?
    # No, automation is key.
    # Let's just implement the skeleton.
    
    practitioners = frappe_client.get_practitioners()
    if not practitioners:
         return {"status": "failed", "message": "No practitioners found in ERPNext", "count": 0}
            
    synced_count = 0
    
    for p in practitioners:
        name = p.get("practitioner_name")
        
        # Simple heuristic: If name contains "Apt." or "S.Farm", treat as pharmacist?
        # Or checking Department.
        
        dept = p.get("department", "")
        # If department is not Pharmacy, skip (optional, if your ERPNext setup has this)
        
        # Check if exists locally
        existing = db.query(models.Pharmacist).filter(models.Pharmacist.name == name).first()
             
        if existing:
            # Update
            # existing.erp_employee_id = p.get("name") # Store Frappe ID?
             pass 
        else:
             # Create new locally if name implies pharmacist
             if "Apt." in name or "Farm" in name or "S.Farm" in name:
                 new_pharma = models.Pharmacist(
                     name=name,
                     sip_no="SYNCED-FROM-ERP",
                     is_active=True
                 )
                 db.add(new_pharma)
                 synced_count += 1
        
    db.commit()
    return {"status": "success", "count": synced_count, "message": f"Synced {synced_count} pharmacists from ERPNext"}

@router.post("/sync/push")
def sync_pharmacists_push(db: Session = Depends(database.get_db)):
    """Push data from App to ERPNext"""
    from ..services.frappe_service import frappe_client
    
    local_pharmacists = db.query(models.Pharmacist).all()
    synced_count = 0
    
    for p in local_pharmacists:
        try:
            # Name parts
            parts = p.name.replace("Apt.", "").replace("S.Farm", "").strip().split(" ")
            first_name = parts[0]
            last_name = " ".join(parts[1:]) if len(parts) > 1 else ""
            
            # Check if exists in ERPNext
            filters = {"practitioner_name": p.name}
            erp_docs = frappe_client.get_list("Healthcare Practitioner", filters=filters)
            
            if erp_docs:
                # Update
                frappe_id = erp_docs[0].get("name")
                # p.erp_employee_id = frappe_id # Save back ID
                
                update_data = {
                    "first_name": first_name,
                    "last_name": last_name,
                    "department": "Pharmacy" # Force Department
                }
                frappe_client.update_practitioner(frappe_id, update_data)
            else:
                # Create
                frappe_client.create_practitioner(first_name, last_name, "Pharmacy")
            
            synced_count += 1
        except Exception as e:
            print(f"Error pushing pharmacist {p.name}: {e}")

    db.commit() # Save any IDs if we assigned them
    return {"status": "success", "count": synced_count}
