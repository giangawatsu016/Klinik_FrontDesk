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

    # 2. Doctors Available (Total Available - Assigned to Active Queue)
    total_doctors = db.query(models.Doctor).filter(models.Doctor.is_available == True).count()
    
    # Doctors are busy if they are assigned to a queue that is Waiting or In Consultation
    busy_doctors = db.query(models.PatientQueue.medicalFacilityPolyDoctorId).filter(
        models.PatientQueue.status.in_(["Waiting", "In Consultation"]),
        models.PatientQueue.medicalFacilityPolyDoctorId != None,
        models.PatientQueue.appointmentTime >= today_start # Assuming we only care about today's queues
    ).distinct().count()
    
    doctors_available = max(0, total_doctors - busy_doctors)

    # 3. Active Queue (Waiting + In Consultation) - Logic: "Active queues in Queue Monitor"
    active_queue = db.query(models.PatientQueue).filter(
        models.PatientQueue.appointmentTime >= today_start,
        models.PatientQueue.status.in_(["Waiting", "In Consultation"])
    ).count()

    # 4. Recent Activity (Last 5 Queues TODAY)
    recent_queues = db.query(models.PatientQueue).filter(
        models.PatientQueue.appointmentTime >= today_start
    ).order_by(
        models.PatientQueue.appointmentTime.desc()
    ).limit(5).all()

    recent_activity = []
    for q in recent_queues:
        # Format: "Patient Name - Polyclinic (Status)"
        patient_name = f"{q.patient.firstName} {q.patient.lastName or ''}".strip() if q.patient else "Unknown"
        activity = {
            "time": q.appointmentTime.strftime("%H:%M"),
            "description": f"{patient_name} - {q.queueType}",
            "status": q.status
        }
        recent_activity.append(activity)

    return {
        "total_patients": total_patients,
        "doctors_available": doctors_available,
        "active_queue": active_queue,
        "recent_activity": recent_activity
    }
