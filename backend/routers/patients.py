from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from typing import List
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from .. import models, schemas, database, dependencies
from ..services.frappe_service import frappe_client
from ..services.satu_sehat_service import satu_sehat_client

router = APIRouter(
    prefix="/patients",
    tags=["patients"]
)

@router.post("/sync")
def sync_patients(db: Session = Depends(database.get_db)):
    from ..services.frappe_service import frappe_client
    # Pull patients from ERPNext is complex due to volume. 
    # For now, we will just return a placeholder or implement limited sync (e.g. last 50).
    # Since the user asked for "Sync" menu, we should confirm behavior.
    # Assuming "Pull from ERPNext" for consistency.
    
    # LIMIT to 50 latest for performance
    patients = frappe_client.get_patients(limit=50) 
    count = 0
    if patients:
        for p in patients:
            # Check exist
            identity = p.get("mobile_uuid") # OR NIK if available in custom field
            phone = p.get("mobile")
            
            existing = db.query(models.Patient).filter(models.Patient.phone == phone).first()
            if not existing:
                # Create basic patient
                new_p = models.Patient(
                    firstName=p.get("patient_name", "Unknown"),
                    lastName="",
                    identityCard=identity or "UNKNOWN",
                    phone=phone or "000",
                    gender=p.get("sex", "Male"),
                    birthday=p.get("dob") or "2000-01-01",
                    address=p.get("primary_address", ""),
                    frappeId=p.get("name"),
                    
                    # Defaults
                    religion="Islam",
                    profession="Unknown",
                    education="Unknown",
                    province="Unknown",
                    city="Unknown",
                    district="Unknown",
                    subdistrict="Unknown",
                    rt="00",
                    rw="00",
                    postalCode="00000",
                    issuerId=1,
                    maritalStatusId=1
                )
                db.add(new_p)
                count += 1
        db.commit()
    
    return {"status": "success", "message": f"Synced {count} new contacts from ERPNext"}

@router.post("/sync/push")
def sync_patients_push(db: Session = Depends(database.get_db)):
    """Push data from App to ERPNext"""
    from ..services.frappe_service import frappe_client
    
    local_patients = db.query(models.Patient).all()
    synced_count = 0
    
    for pat in local_patients:
        try:
            # Prepare data
            data = {
                "first_name": pat.firstName,
                "last_name": pat.lastName,
                "sex": pat.gender,
                "mobile": pat.phone,
                "dob": str(pat.birthday) if pat.birthday else None,
            }
            
            # Check if linked (has frappe_id)
            if pat.frappeId:
                 # Update
                 frappe_client.update_patient(pat.frappeId, data)
                 synced_count += 1
            else:
                 # Create (or Check existence by phone via create_patient logic in service)
                 # The service `create_patient` handles check-if-exists logic.
                 resp = frappe_client.create_patient(data)
                 if resp and "data" in resp:
                     # Update local ID
                     new_id = resp["data"].get("name")
                     pat.frappeId = new_id
                     synced_count += 1
                     
        except Exception as e:
            print(f"Error pushing patient {pat.firstName}: {e}")
            
    db.commit()
    return {"status": "success", "count": synced_count}

def sync_new_patient(patient_id: int):
    from ..database import SessionLocal
    db = SessionLocal()
    try:
        patient = db.query(models.Patient).filter(models.Patient.id == patient_id).first()
        if not patient: return

        # 1. Sync to Frappe
        try:
            # Re-construct dict from model since we don't have the pydantic object here easily without simple mapping
            # effectively same as patient.dict() but from ORM
            patient_data = {
                "first_name": patient.firstName,
                "last_name": patient.lastName,
                "sex": patient.gender,
                "mobile": patient.phone,
                "dob": str(patient.birthday) if patient.birthday else None,
                "primary_address": patient.address  # Add other fields as needed for Frappe
            }
            
            frappe_response = frappe_client.create_patient(patient_data)
            if frappe_response and "data" in frappe_response:
                 patient.frappeId = frappe_response["data"].get("name")
        except Exception as e:
            print(f"Background Frappe Sync Error: {e}")

        # 2. Sync to Satu Sehat
        try:
            # Prepare data
             patient_data_ss = {
                "firstName": patient.firstName,
                "lastName": patient.lastName,
                "identityCard": patient.identityCard,
                "phone": patient.phone,
                "gender": patient.gender,
                "birthday": patient.birthday,
                "address": patient.address,
                # Add other fields required for SS if any
             }
             ihs_number = satu_sehat_client.post_patient(patient_data_ss)
             patient.ihs_number = ihs_number
        except Exception as e:
            print(f"Background Satu Sehat Sync Error: {e}")
            
        db.commit()
    finally:
        db.close()

@router.post("", response_model=schemas.Patient)
def create_patient(patient: schemas.PatientCreate, background_tasks: BackgroundTasks, db: Session = Depends(database.get_db), current_user: models.User = Depends(dependencies.get_current_user)):
    # Check if existing by ID Card
    if db.query(models.Patient).filter(models.Patient.identityCard == patient.identityCard).first():
        raise HTTPException(status_code=400, detail="Patient with this ID Card already exists")
    
    # Check if existing by Phone
    if db.query(models.Patient).filter(models.Patient.phone == patient.phone).first():
        raise HTTPException(status_code=400, detail="Patient with this Phone Number already exists")
    
    # Create Local Patient Immediately
    new_patient = models.Patient(**patient.dict())
    
    try:
        db.add(new_patient)
        db.commit()
        db.refresh(new_patient)
        
        # Offload sync to background
        background_tasks.add_task(sync_new_patient, new_patient.id)
        
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Patient with NIK {patient.identityCard} already exists or other constraint failed.")
    except Exception as e:
        db.rollback()
        print(f"Database Error: {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error during patient creation")

    return new_patient

@router.put("/{patient_id}", response_model=schemas.Patient)
def update_patient(patient_id: int, patient_update: schemas.PatientCreate, db: Session = Depends(database.get_db)):
    # Note: Using PatientCreate schema allows updating all fields
    db_patient = db.query(models.Patient).filter(models.Patient.id == patient_id).first()
    if not db_patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    
    # Update Local Fields
    update_data = patient_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_patient, key, value)
    
    db.commit()
    db.refresh(db_patient)
    
    # Sync to ERPNext
    if db_patient.frappe_id:
        try:
            from ..services.frappe_service import frappe_client
            # Map fields
            erp_data = {
                "first_name": patient_update.firstName,
                "last_name": patient_update.lastName,
                "sex": patient_update.gender,
                "mobile": patient_update.phone,
                "dob": str(patient_update.birthday) if patient_update.birthday else None,
            }
            frappe_client.update_patient(db_patient.frappe_id, erp_data)
        except Exception as e:
            print(f"Failed to sync update to ERPNext: {e}")
            
    return db_patient

@router.get("", response_model=List[schemas.Patient])
def get_patients(skip: int = 0, limit: int = 100, search: str = None, db: Session = Depends(database.get_db), current_user: models.User = Depends(dependencies.get_current_user)):
    return db.query(models.Patient).order_by(models.Patient.firstName.asc()).offset(skip).limit(limit).all()

@router.get("/search", response_model=List[schemas.Patient])
def search_patients(query: str, db: Session = Depends(database.get_db), current_user: models.User = Depends(dependencies.get_current_user)):
    # Simple search by name or ID
    return db.query(models.Patient).filter(
        (models.Patient.firstName.contains(query)) | 
        (models.Patient.lastName.contains(query)) | 
        (models.Patient.identityCard.contains(query)) |
        (models.Patient.phone.contains(query)) |
        (models.Patient.nomorRekamMedis.contains(query))
    ).all()

@router.get("/{patient_id}", response_model=schemas.Patient)
def get_patient(patient_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(dependencies.get_current_user)):
    patient = db.query(models.Patient).filter(models.Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    return patient
