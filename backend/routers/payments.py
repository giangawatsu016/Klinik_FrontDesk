from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from .. import models, schemas, database
from ..services.satu_sehat_service import satu_sehat_client

router = APIRouter(
    prefix="/payments",
    tags=["Payments"]
)

@router.post("/", response_model=schemas.Payment)
def process_payment(payment: schemas.PaymentCreate, db: Session = Depends(database.get_db)):
    # 1. Create Local Payment Record
    db_payment = models.Payment(
        patient_id=payment.patient_id,
        amount=payment.amount,
        method=payment.method,
        insuranceName=payment.insuranceName,
        insuranceNumber=payment.insuranceNumber,
        notes=payment.notes,
        claimStatus="Paid" if payment.method == "Cash" else "Submitted"
    )
    db.add(db_payment)
    db.commit()
    db.refresh(db_payment)

    # 2. Sync to Satu Sehat (Coverage) if Insurance/BPJS
    if payment.method in ["BPJS", "Insurance"] and payment.insuranceNumber:
        try:
            # Fetch Patient to get IHS Number (needed for Subject)
            patient = db.query(models.Patient).filter(models.Patient.id == payment.patient_id).first()
            if patient and patient.ihs_number:
                coverage_id = satu_sehat_client.create_coverage(
                    ihs_number=patient.ihs_number,
                    insurance_name=payment.insuranceName,
                    insurance_number=payment.insuranceNumber,
                    method=payment.method
                )
                if coverage_id:
                    print(f"SatuSehat Coverage Created: {coverage_id}")
                    db_payment.notes = (db_payment.notes or "") + f" [SS: {coverage_id}]"
                    db.commit()
            else:
                 print("Skipping SatuSehat Sync: Patient has no IHS Number")

        except Exception as e:
            print(f"Failed to sync Coverage to SatuSehat: {e}")

    return db_payment

@router.get("/patient/{patient_id}", response_model=List[schemas.Payment])
def get_patient_payments(patient_id: int, db: Session = Depends(database.get_db)):
    return db.query(models.Payment).filter(models.Payment.patient_id == patient_id).all()
