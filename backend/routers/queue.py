from fastapi import APIRouter, Depends, HTTPException
from typing import List
from sqlalchemy.orm import Session
from datetime import datetime
from .. import models, schemas, database, dependencies

router = APIRouter(
    prefix="/queues",
    tags=["queues"]
)

@router.post("/", response_model=schemas.PatientQueue)
def add_to_queue(queue_data: schemas.QueueCreate, db: Session = Depends(database.get_db), current_user: models.User = Depends(dependencies.get_current_user)):
    # Determine Prefix based on Priority (P for Priority, D for Regular/Doctor)
    # Note: User requested D-XXXX (Normal) and P-XXXX (Priority)
    prefix = "P" if queue_data.isPriority else "D"
    
    # Calculate next number safely
    # We count how many items exist with this prefix to determine the next sequence
    # This is a simple implementation; for high concurrency, use a sequence or atomic counter.
    today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    count = db.query(models.PatientQueue).filter(
        models.PatientQueue.numberQueue.like(f"{prefix}-%"),
        models.PatientQueue.appointmentTime >= today_start
    ).count()
    
    next_number = f"{prefix}-{count + 1:04d}"

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
