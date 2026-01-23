from fastapi import APIRouter, Depends, HTTPException
from ..services.satu_sehat_service import satu_sehat_client
from ..auth_utils import get_current_user
from .. import models
from ..database import get_db
from sqlalchemy.orm import Session

router = APIRouter(
    prefix="/integration",
    tags=["integration"]
)

@router.get("/satusehat/patient/{nik}")
def get_patient_from_satusehat(
    nik: str,
    current_user: models.User = Depends(get_current_user)
):
    """
    Fetch Patient details from Satu Sehat by NIK.
    Requires Authentication.
    """
    if not nik or len(nik) != 16:
         raise HTTPException(status_code=400, detail="Invalid NIK format")

    try:
        patient_data = satu_sehat_client.search_patient_by_nik(nik)
        if not patient_data:
            raise HTTPException(status_code=404, detail="Patient not found in Satu Sehat")
        return patient_data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
@router.get("/kfa/products")
def search_kfa_products(
    query: str,
    page: int = 1,
    limit: int = 10,
    current_user: models.User = Depends(get_current_user)
):
    """
    Search KFA Products (Medicines).
    """
    if not query:
        return []
        
    try:
        return satu_sehat_client.search_kfa_products(query, page, limit)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/diagnostic-reports/{patient_id}")
def get_diagnostic_reports(
    patient_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    Get Diagnostic Reports from Satu Sehat for a local patient.
    """
    # 1. Get Patient
    patient = db.query(models.Patient).filter(models.Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
        
    # 2. Check IHS Number
    ihs_number = patient.ihs_number
    if not ihs_number:
        # Try to search by NIK if not linked yet
        if patient.identityCard:
            try:
                ss_data = satu_sehat_client.search_patient_by_nik(patient.identityCard)
                if ss_data and ss_data.get("ihs_number"):
                    ihs_number = ss_data.get("ihs_number")
                    # Update DB
                    patient.ihs_number = ihs_number
                    db.commit()
            except Exception as e:
                print(f"Error fetching/linking IHS for patient {patient.identityCard}: {e}")
                # Continue without linking
                pass
    
    if not ihs_number:
         raise HTTPException(status_code=400, detail="Patient does not have IHS Number linked (and search by NIK failed)")

    # 3. Fetch Reports
    try:
        reports = satu_sehat_client.get_diagnostic_reports(ihs_number)
        return reports
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# --- Sync Endpoints (Doctors) ---

@router.post("/satusehat/doctors/sync")
def sync_doctors_pull(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    Pull/Link: Search SatuSehat by NIK for local doctors and update IHS Number.
    """
    try:
        doctors = db.query(models.DoctorEntity).filter(
            models.DoctorEntity.identityCard != None
        ).all()
        
        count = 0
        updated = 0
        
        for d in doctors:
            # Skip if already linked (optional, but good for perf)
            # if d.ihs_practitioner_number: continue 
            
            if len(d.identityCard) != 16: continue
            
            result = satu_sehat_client.search_practitioner_by_nik(d.identityCard)
            if result and result.get("ihs_number"):
                if d.ihs_practitioner_number != result.get("ihs_number"):
                    d.ihs_practitioner_number = result.get("ihs_number")
                    updated += 1
                count += 1
        
        db.commit()
        return {"status": "success", "message": f"Linked {updated} doctors. Total verified: {count}", "count": updated}
    except Exception as e:
        print(f"Error syncing doctors: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/satusehat/doctors/push")
def sync_doctors_push(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    Push: Create Doctors on SatuSehat if they don't exist.
    """
    try:
        # Get doctors with NIK but NO IHS
        doctors = db.query(models.DoctorEntity).filter(
            models.DoctorEntity.identityCard != None,
            models.DoctorEntity.ihs_practitioner_number == None
        ).all()
        
        count = 0
        for d in doctors:
            if len(d.identityCard) != 16: continue
            
            # Use the service method which constructs payload
            # Mapping model to dict for the helper
            d_data = {
                "identityCard": d.identityCard,
                "namaDokter": d.namaDokter,
                "firstName": d.firstName,
                "lastName": d.lastName
            }
            new_ihs = satu_sehat_client.create_practitioner_on_satusehat(d_data)
            if new_ihs:
                d.ihs_practitioner_number = new_ihs
                count += 1
                
        db.commit()
        return {"status": "success", "message": f"Created {count} new practitioners on SatuSehat.", "count": count}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# --- Sync Endpoints (Patients) ---

@router.post("/satusehat/patients/sync")
def sync_patients_pull(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    Pull/Link: Search SatuSehat by NIK for local patients and update IHS Number.
    """
    try:
        # Get patients with NIK
        patients = db.query(models.Patient).filter(
            models.Patient.identityCard != None
        ).all()
        
        updated = 0
        verified = 0
        
        for p in patients:
            if len(p.identityCard) != 16: continue
            
            # Check SS
            ss_data = satu_sehat_client.search_patient_by_nik(p.identityCard)
            if ss_data and ss_data.get("ihs_number"):
                if p.ihs_number != ss_data.get("ihs_number"):
                    p.ihs_number = ss_data.get("ihs_number")
                    updated += 1
                verified += 1
                
        db.commit()
        return {"status": "success", "message": f"Linked {updated} patients. Total verified: {verified}", "count": updated}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/satusehat/patients/push")
def sync_patients_push(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    Push: Create Patients on SatuSehat if they don't exist.
    """
    try:
        # Patients with NIK but NO IHS
        patients = db.query(models.Patient).filter(
            models.Patient.identityCard != None,
            models.Patient.ihs_number == None
        ).all()
        
        count = 0
        for p in patients:
            if len(p.identityCard) != 16: continue
            
            # Convert model to dict for service
            p_data = {
                "identityCard": p.identityCard,
                "firstName": p.firstName,
                "lastName": p.lastName,
                "gender": p.gender,
                "birthday": p.birthday,
                "phone": p.phone,
                "address": p.address,
                "city": p.city,
                "postalCode": p.postalCode
            }
            
            # This method attempts to create
            new_ihs = satu_sehat_client._create_new_patient_on_satusehat(p_data)
            if new_ihs:
                p.ihs_number = new_ihs
                count += 1
                
        db.commit()
        return {"status": "success", "message": f"Created {count} new patients on SatuSehat.", "count": count}
    except Exception as e:
        print(f"Push Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
