from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from typing import List
from sqlalchemy.orm import Session
from datetime import datetime
from .. import models, schemas, database, dependencies
from ..services.frappe_service import frappe_client

router = APIRouter(
    prefix="/queues",
    tags=["queues"]
)

@router.post("/", response_model=schemas.PatientQueue)
def add_to_queue(queue_data: schemas.QueueCreate, background_tasks: BackgroundTasks, db: Session = Depends(database.get_db), current_user: models.User = Depends(dependencies.get_current_user)):
    today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    
    # Determine Prefix
    if queue_data.queueType == "Polyclinic":
        prefix = "PP" if queue_data.isPriority else "P"
    else:
        # Default to Doctor
        prefix = "DP" if queue_data.isPriority else "D"

    # Count for today with this specific prefix
    count = db.query(models.PatientQueue).filter(
        models.PatientQueue.numberQueue.like(f"{prefix}-%"),
        models.PatientQueue.appointmentTime >= today_start
    ).count()
    
    # Format: PREFIX-XXX (3 digits)
    next_number = f"{prefix}-{count + 1:03d}"

    new_queue = models.PatientQueue(
        numberQueue=next_number, 
        userId=queue_data.userId,
        appointmentTime=datetime.utcnow(),
        status="Waiting",
        isPriority=queue_data.isPriority,
        medicalFacilityPolyDoctorId=queue_data.medicalFacilityPolyDoctorId,
        queueType=queue_data.queueType,
        polyclinic=queue_data.polyclinic
    )
    db.add(new_queue)
    db.commit()
    db.refresh(new_queue)

    # Fetch Patient Name for Frappe
    patient = db.query(models.Patient).filter(models.Patient.id == queue_data.userId).first()
    if patient:
        bg_data = {
           "appointmentTime": new_queue.appointmentTime
        }
        background_tasks.add_task(frappe_client.create_appointment, bg_data, f"{patient.firstName} {patient.lastName}")

    return new_queue

@router.get("/", response_model=List[schemas.PatientQueue])
def get_queue(status: str = None, db: Session = Depends(database.get_db)):
    query = db.query(models.PatientQueue)
    if status:
        query = query.filter(models.PatientQueue.status == status)
    
    all_items = query.all()
    
    # Sort by Priority then Time
    # Priority (True) comes first, then earlier appointmentTime
    all_items.sort(key=lambda x: (not x.isPriority, x.appointmentTime))
    
    return all_items

@router.put("/{queue_id}/status", response_model=schemas.PatientQueue)
def update_queue_status(queue_id: int, status_update: schemas.QueueUpdateStatus, db: Session = Depends(database.get_db), current_user: models.User = Depends(dependencies.get_current_user)):
    queue_item = db.query(models.PatientQueue).filter(models.PatientQueue.id == queue_id).first()
    if not queue_item:
        raise HTTPException(status_code=404, detail="Queue item not found")
    
    queue_item.status = status_update.status
    db.commit()
    db.refresh(queue_item)
    return queue_item
