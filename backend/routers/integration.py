from fastapi import APIRouter, Depends, HTTPException
from ..services.satu_sehat_service import satu_sehat_client
from ..auth_utils import get_current_user
from .. import models

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
