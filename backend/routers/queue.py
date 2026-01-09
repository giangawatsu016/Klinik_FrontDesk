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
    # Initial Placeholder Number (will be dynamic in get_queue)
    # We just need to persist it.
    prefix = "D" if queue_data.queueType == "Doctor" else "P"
    new_queue = models.PatientQueue(
        numberQueue=f"{prefix}-PENDING", 
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
    
    # SeparationLogic
    accepted_status = ["In Consultation", "Completed"]
    
    # 1. Processing Doctor Queues ("Waiting")
    doc_waiting = [i for i in all_items if i.status == "Waiting" and i.queueType == "Doctor"]
    doc_waiting.sort(key=lambda x: (not x.isPriority, x.appointmentTime))
    for idx, item in enumerate(doc_waiting):
        item.numberQueue = f"D-{idx + 1:04d}"
        
    # 2. Processing Polyclinic Queues ("Waiting")
    poly_waiting = [i for i in all_items if i.status == "Waiting" and i.queueType != "Doctor"]
    poly_waiting.sort(key=lambda x: (not x.isPriority, x.appointmentTime))
    for idx, item in enumerate(poly_waiting):
        item.numberQueue = f"P-{idx + 1:04d}"
        
    # 3. Non-Waiting items (Keep original number or simple Logic?)
    # For now returning them as is, or you could apply similar sorting if needed.
    others = [i for i in all_items if i.status != "Waiting"]
    
    return doc_waiting + poly_waiting + others

@router.put("/{queue_id}/status", response_model=schemas.PatientQueue)
def update_queue_status(queue_id: int, status_update: schemas.QueueUpdateStatus, db: Session = Depends(database.get_db), current_user: models.User = Depends(dependencies.get_current_user)):
    queue_item = db.query(models.PatientQueue).filter(models.PatientQueue.id == queue_id).first()
    if not queue_item:
        raise HTTPException(status_code=404, detail="Queue item not found")
    
    queue_item.status = status_update.status
    db.commit()
    db.refresh(queue_item)
    return queue_item
