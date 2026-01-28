from fastapi import APIRouter, Depends, HTTPException
from typing import List
from sqlalchemy.orm import Session
from datetime import date
from .. import models, schemas, database, dependencies

router = APIRouter(
    prefix="/appointments",
    tags=["appointments"]
)

@router.get("/test")
def test_appointment_router():
    return {"status": "ok", "message": "Appointment router is working"}

@router.post("", response_model=schemas.Appointment)
def create_appointment(appointment: schemas.AppointmentCreate, db: Session = Depends(database.get_db)):
    new_appointment = models.Appointment(**appointment.dict())
    db.add(new_appointment)
    db.commit()
    db.refresh(new_appointment)
    return new_appointment

@router.post("/external", response_model=schemas.Appointment)
def create_external_appointment(
    appointment: schemas.AppointmentExternalCreate, 
    db: Session = Depends(database.get_db)
):
    # Lookup Doctor Name
    doctor_name = "Unknown"
    if appointment.doctor_id:
        doctor = db.query(models.DoctorEntity).filter(models.DoctorEntity.medicalFacilityPolyDoctorId == appointment.doctor_id).first()
        if doctor:
            doctor_name = doctor.namaDokter

    # Format Time from Datetime to HH:MM
    formatted_time = appointment.appointment_time.strftime("%H:%M")

    new_appointment = models.Appointment(
        nik_patient=appointment.nik,
        doctor_id=appointment.doctor_id,
        doctor_name=doctor_name,
        appointment_date=appointment.appointment_date,
        appointment_time=formatted_time,
        notes=appointment.notes,
        status="Scheduled"
    )
    db.add(new_appointment)
    db.commit()
    db.refresh(new_appointment)
    return new_appointment

@router.get("", response_model=List[schemas.Appointment])
def get_appointments(
    skip: int = 0, 
    limit: int = 100, 
    status: str = None,
    db: Session = Depends(database.get_db)
):
    query = db.query(models.Appointment)
    if status:
        query = query.filter(models.Appointment.status == status)
        
    return query.order_by(models.Appointment.appointment_date.asc(), models.Appointment.appointment_time.asc()).offset(skip).limit(limit).all()

@router.get("/today", response_model=List[schemas.Appointment])
def get_today_appointments(
    db: Session = Depends(database.get_db)
):
    today = date.today()
    return db.query(models.Appointment).filter(models.Appointment.appointment_date == today).all()

@router.put("/{appointment_id}/status", response_model=schemas.Appointment)
def update_appointment_status(
    appointment_id: int, 
    status: str, 
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(dependencies.get_current_user)
):
    appointment = db.query(models.Appointment).filter(models.Appointment.id == appointment_id).first()
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
    
    appointment.status = status
    db.commit()
    db.refresh(appointment)
    return appointment
