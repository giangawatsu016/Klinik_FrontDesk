from fastapi import APIRouter, Depends, HTTPException
from typing import List
from sqlalchemy.orm import Session
from .. import models, schemas, database

router = APIRouter(
    prefix="/doctors",
    tags=["doctors"]
)

@router.get("", response_model=List[schemas.Doctor])
def get_doctors(db: Session = Depends(database.get_db)):
    return db.query(models.DoctorEntity).order_by(models.DoctorEntity.namaDokter.asc()).all()

@router.post("/sync")
def sync_doctors_pull(db: Session = Depends(database.get_db)):
    """Pull data from ERPNext to App"""
    from ..services.frappe_service import frappe_client
    
    # 1. Fetch Practitioners from ERPNext
    practitioners = frappe_client.get_practitioners()
    if not practitioners:
         return {"status": "failed", "message": "No practitioners found in ERPNext", "count": 0}
            
    synced_count = 0
    
    for p in practitioners:
        # Check if exists by IHS Number (or Name if IHS missing)
        ihs = p.get("practitioner_identifiers", [{}])[0].get("identifier_value") if p.get("practitioner_identifiers") else None
        name = p.get("practitioner_name")
        
        # We use name as generic identifier if IHS is missing for now, though risky
        existing = None
        if ihs:
             existing = db.query(models.DoctorEntity).filter(models.DoctorEntity.ihs_practitioner_number == ihs).first()
        if not existing:
             existing = db.query(models.DoctorEntity).filter(models.DoctorEntity.namaDokter == name).first()
             
        if existing:
            # Update info from ERPNext (Master)
            existing.doctorSIP = ihs if ihs else existing.doctorSIP
            # existing.polyName = ... # Map department?
        else:
             # Create new locally
             new_doc = models.DoctorEntity(
                 namaDokter=name,
                 polyName="General", # Default
                 is_available=True,
                 ihs_practitioner_number=ihs
             )
             db.add(new_doc)
        
        synced_count += 1
        
    db.commit()
    return {"status": "success", "count": synced_count}

@router.post("/sync/push")
def sync_doctors_push(db: Session = Depends(database.get_db)):
    """Push data from App to ERPNext"""
    from ..services.frappe_service import frappe_client
    
    local_doctors = db.query(models.DoctorEntity).all()
    synced_count = 0
    
    for doc in local_doctors:
        try:
            name_parts = doc.namaDokter.split(" ", 1)
            first_name = name_parts[0]
            last_name = name_parts[1] if len(name_parts) > 1 else ""
            
            # Check if exists in ERPNext by Name (since we don't store ERP ID reliably yet)
            erp_docs = frappe_client.get_list("Healthcare Practitioner", filters={"practitioner_name": doc.namaDokter})
            
            if erp_docs:
                # Update
                frappe_id = erp_docs[0].get("name")
                update_data = {
                    "first_name": first_name,
                    "last_name": last_name,
                    "department": doc.polyName
                }
                frappe_client.update_practitioner(frappe_id, update_data)
            else:
                # Create
                frappe_client.create_practitioner(first_name, last_name, doc.polyName)
            
            synced_count += 1
        except Exception as e:
            print(f"Error pushing doctor {doc.namaDokter}: {e}")

    return {"status": "success", "count": synced_count}

@router.post("", response_model=schemas.Doctor)
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

@router.put("/{doctor_id}", response_model=schemas.Doctor)
def update_doctor(doctor_id: int, doctor_update: schemas.DoctorBase, db: Session = Depends(database.get_db)):
    db_doctor = db.query(models.DoctorEntity).filter(models.DoctorEntity.medicalFacilityPolyDoctorId == doctor_id).first()
    if not db_doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")
    
    # Update Local
    old_name = db_doctor.namaDokter # Keep for finding in ERPNext if needed
    
    db_doctor.namaDokter = doctor_update.namaDokter
    db_doctor.gelarDepan = doctor_update.gelarDepan
    db_doctor.polyName = doctor_update.polyName
    
    # New Fields
    db_doctor.firstName = doctor_update.firstName
    db_doctor.lastName = doctor_update.lastName
    db_doctor.gelarBelakang = doctor_update.gelarBelakang
    db_doctor.doctorSIP = doctor_update.doctorSIP
    db_doctor.identityCard = doctor_update.identityCard # NIK
    db_doctor.ihs_practitioner_number = doctor_update.ihs_practitioner_number
    db_doctor.onlineFee = doctor_update.onlineFee
    db_doctor.appointmentFee = doctor_update.appointmentFee
    
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

@router.get("/{doctor_id}/schedule")
def get_doctor_schedule(doctor_id: int):
    # Placeholder for future implementation
    return {"message": "Schedule not implemented yet", "doctor_id": doctor_id, "schedule": []}

from ..services.frappe_service import frappe_client


