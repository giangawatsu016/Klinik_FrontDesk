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
            except:
                pass
    
    if not ihs_number:
         raise HTTPException(status_code=400, detail="Patient does not have IHS Number linked (and search by NIK failed)")

    # 3. Fetch Reports
    try:
        reports = satu_sehat_client.get_diagnostic_reports(ihs_number)
        return reports
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
