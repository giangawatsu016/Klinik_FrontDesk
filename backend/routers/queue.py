from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from typing import List
from sqlalchemy.orm import Session
from datetime import datetime
from .. import models, schemas, database, dependencies
from ..services.frappe_service import frappe_client

router = APIRouter(
    prefix="/queue",
    tags=["queues"]
)

@router.post("", response_model=schemas.PatientQueue)
def add_to_queue(queue_data: schemas.QueueCreate, background_tasks: BackgroundTasks, db: Session = Depends(database.get_db), current_user: models.User = Depends(dependencies.get_current_user)):
    today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    
    # Determine Prefix
    if queue_data.queueType == "Polyclinic":
        prefix = "PP" if queue_data.isPriority else "P"
    else:
        prefix = "AP" if queue_data.isPriority else "A"

    # Lazy Cleanup: Auto-complete old active queues (yesterday or older)
    old_queues = db.query(models.PatientQueue).filter(
        models.PatientQueue.userId == queue_data.userId,
        models.PatientQueue.status.in_(["Waiting", "In Consultation"]),
        models.PatientQueue.appointmentTime < today_start
    ).all()

    for old_q in old_queues:
        old_q.status = "Completed" # Mark as completed/expired so they don't block
        
    if old_queues:
        db.commit()

    # Check for existing active queue for this patient (TODAY ONLY)
    existing_queue = db.query(models.PatientQueue).filter(
        models.PatientQueue.userId == queue_data.userId,
        models.PatientQueue.status.in_(["Waiting", "In Consultation"]),
        models.PatientQueue.appointmentTime >= today_start
    ).first()

    if existing_queue:
        raise HTTPException(status_code=400, detail="Patient already has an active queue for today")

    # Get last number
    last_queue = db.query(models.PatientQueue).filter(
        models.PatientQueue.appointmentTime >= today_start,
        models.PatientQueue.numberQueue.like(f"{prefix}%")
    ).order_by(models.PatientQueue.id.desc()).first()
    
    if last_queue:
        # Assuming numberQueue is like "P001", "PP002", "A003", "AP004"
        # Extract the numeric part after the prefix
        try:
            last_num_str = last_queue.numberQueue[len(prefix):]
            last_num = int(last_num_str)
            new_num = last_num + 1
        except (ValueError, IndexError):
            # Fallback if parsing fails, e.g., if numberQueue format is unexpected
            new_num = 1
            # Optionally, log this error
    else:
        new_num = 1
        
    queue_number = f"{prefix}{new_num:03d}"

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

@router.get("", response_model=List[schemas.PatientQueue])
def get_queue(db: Session = Depends(database.get_db)):
    today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    return db.query(models.PatientQueue).filter(models.PatientQueue.appointmentTime >= today_start).all()
    if status:
        query = query.filter(models.PatientQueue.status == status)
    
    all_items = query.all()
    
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
