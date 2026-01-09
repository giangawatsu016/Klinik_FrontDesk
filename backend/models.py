from sqlalchemy import Column, Integer, String, Boolean, Date, DateTime, ForeignKey, Text, JSON
from sqlalchemy.orm import relationship
from .database import Base
from datetime import datetime

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True)
    password_hash = Column(String(255))
    full_name = Column(String(100))
    role = Column(String(20), default="staff")
    is_active = Column(Boolean, default=True)

class MaritalStatus(Base):
    __tablename__ = "maritalstatus"
    
    id = Column(Integer, primary_key=True, index=True)
    display = Column(String(50))

class Issuer(Base):
    __tablename__ = "issuer"
    
    issuerId = Column(Integer, primary_key=True, index=True)
    issuer = Column(String(50)) # e.g., BPJS, General, Insurance
    nama = Column(JSON) # Storing sub-issuers as JSON array as implied by nama[]

class DoctorEntity(Base):
    __tablename__ = "doctorentity"
    
    medicalFacilityPolyDoctorId = Column(Integer, primary_key=True, index=True)
    gelarDepan = Column(String(20))
    namaDokter = Column(String(100))
    polyName = Column(String(50)) # Added for Policlinic Routing
    is_available = Column(Boolean, default=True)

class Patient(Base):
    __tablename__ = "patient"
    
    id = Column(Integer, primary_key=True, index=True)
    firstName = Column(String(100))
    lastName = Column(String(100))
    phone = Column(String(20))
    gender = Column(String(10)) # Male/Female
    birthday = Column(Date)
    identityCard = Column(String(20), unique=True, index=True) # NIK/KTP
    religion = Column(String(20))
    profession = Column(String(50))
    education = Column(String(20))
    
    # Address System
    province = Column(String(50))
    city = Column(String(50))
    district = Column(String(50))
    subdistrict = Column(String(50))
    rt = Column(String(5))
    rw = Column(String(5))
    postalCode = Column(String(10))
    address_details = Column(Text)
    
    # Insurance Info
    issuerId = Column(Integer, ForeignKey("issuer.issuerId"))
    insuranceName = Column(String(100), nullable=True) # BPJS Kesehatan, Allianz, etc.
    noAssuransi = Column(String(50), nullable=True)
    
    # Marital Status
    maritalStatusId = Column(Integer, ForeignKey("maritalstatus.id"))
    
    # Relationships
    issuer = relationship("Issuer")
    maritalStatus = relationship("MaritalStatus")
    queues = relationship("PatientQueue", back_populates="patient")

class PatientQueue(Base):
    __tablename__ = "patientqueue"
    
    id = Column(Integer, primary_key=True, index=True)
    numberQueue = Column(String(20))
    userId = Column(Integer, ForeignKey("patient.id")) # Refers to patient
    appointmentTime = Column(DateTime, default=datetime.utcnow)
    status = Column(String(20), default="Waiting") # Waiting, In Consultation, Completed
    isPriority = Column(Boolean, default=False)
    isChecked = Column(Boolean, default=False)
    
    medicalFacilityPolyDoctorId = Column(Integer, ForeignKey("doctorentity.medicalFacilityPolyDoctorId"), nullable=True)
    queueType = Column(String(20), default="Doctor") # Doctor or Polyclinic
    polyclinic = Column(String(50), nullable=True) # e.g. General, Dental
    
    patient = relationship("Patient", back_populates="queues")
    doctor = relationship("DoctorEntity")
