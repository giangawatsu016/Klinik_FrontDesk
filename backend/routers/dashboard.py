from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from datetime import datetime
from .. import models, database, dependencies

router = APIRouter(
    prefix="/dashboard",
    tags=["dashboard"]
)

@router.get("/overview")
def get_dashboard_overview(db: Session = Depends(database.get_db), current_user: models.User = Depends(dependencies.get_current_user)):
    today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)

    # 1. Total Patients (New Registrations Today)
    total_patients = db.query(models.Patient).filter(models.Patient.created_at >= today_start).count()

    # 2. Doctors Available (Total Available - Currently In Consultation)
    total_doctors = db.query(models.Doctor).filter(models.Doctor.is_available == True).count()
    busy_doctors = db.query(models.PatientQueue.medicalFacilityPolyDoctorId).filter(
        models.PatientQueue.status == "In Consultation"
    ).distinct().count()
    
    doctors_available = max(0, total_doctors - busy_doctors)

    # 3. Queue Today
    queue_today = db.query(models.PatientQueue).filter(
        models.PatientQueue.appointmentTime >= today_start
    ).count()

    return {
        "total_patients": total_patients,
        "doctors_available": doctors_available,
        "queue_today": queue_today
    }
