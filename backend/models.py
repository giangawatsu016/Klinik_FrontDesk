from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, Text, DateTime, Date, Enum, Float, JSON
from sqlalchemy.orm import relationship
from .database import Base
from datetime import datetime

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True)
    email = Column(String(100), unique=True, index=True, nullable=True)
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

class Disease(Base):
    __tablename__ = "diseases"
    
    id = Column(Integer, primary_key=True, index=True)
    icd_code = Column(String(20), unique=True, index=True) # ICD-10 Code
    name = Column(String(255)) # Disease Name
    description = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True)

class DoctorEntity(Base):
    __tablename__ = "doctorcore"
    
    medicalFacilityPolyDoctorId = Column(Integer, primary_key=True, index=True)
    gelarDepan = Column(String(20))
    namaDokter = Column(String(100))
    
    # New Fields
    firstName = Column(String(50), nullable=True)
    lastName = Column(String(50), nullable=True)
    gelarBelakang = Column(String(20), nullable=True)
    doctorSIP = Column(String(50), nullable=True)
    identityCard = Column(String(20), unique=True, index=True) # NIK for SatuSehat
    ihs_practitioner_number = Column(String(100), nullable=True) # SatuSehat ID
    onlineFee = Column(Integer, nullable=True)
    appointmentFee = Column(Integer, nullable=True)

    polyName = Column(String(50)) # Added for Policlinic Routing
    is_available = Column(Boolean, default=True)

class Patient(Base):
    __tablename__ = "patientcore"
    
    id = Column(Integer, primary_key=True, index=True)
    created_at = Column(DateTime, default=datetime.utcnow, index=True) # New field for dashboard stats
    firstName = Column(String(100))
    lastName = Column(String(100), nullable=True)
    phone = Column(String(20), unique=True) # Added unique constraint
    gender = Column(String(10)) # Male/Female
    birthday = Column(Date)
    frappe_id = Column(String(100), nullable=True)
    ihs_number = Column(String(100), nullable=True) # Satu Sehat ID # Link to ERPNext
    identityCard = Column(String(20), unique=True, index=True) # NIK/KTP
    religion = Column(String(20))
    profession = Column(String(50))
    education = Column(String(20))
    
    nomorRekamMedis = Column(String(50), nullable=True) # Medical Record Number
    avatar = Column(String(255), nullable=True) 
    height = Column(Integer, nullable=True) # cm
    weight = Column(Integer, nullable=True) # kg
    address = Column(String(255), nullable=True) # Simple address field

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
    userId = Column(Integer, ForeignKey("patientcore.id")) # Refers to patient
    appointmentTime = Column(DateTime, default=datetime.utcnow, index=True)
    status = Column(String(20), default="Waiting") # Waiting, In Consultation, Completed
    isPriority = Column(Boolean, default=False, index=True)
    isChecked = Column(Boolean, default=False)
    
    medicalFacilityPolyDoctorId = Column(Integer, ForeignKey("doctorcore.medicalFacilityPolyDoctorId"), nullable=True)
    queueType = Column(String(20), default="Doctor") # Doctor or Polyclinic
    polyclinic = Column(String(50), nullable=True) # e.g. General, Dental
    
    patient = relationship("Patient", back_populates="queues")
    doctor = relationship("DoctorEntity")

class Medicine(Base):
    __tablename__ = "medicinecore"
    
    id = Column(Integer, primary_key=True, index=True)
    erpnext_item_code = Column(String(100), unique=True, index=True)
    
    # Core Fields
    medicineName = Column(String(200)) # Was name
    medicineDescription = Column(Text, nullable=True) # Was description
    medicineLabel = Column(String(100), nullable=True) # New
    
    medicinePrice = Column(Integer, default=0) # New (Buy Price)
    medicineRetailPrice = Column(Integer, default=0) # New (Sell Price)
    qty = Column(Integer, default=0) # Was stock
    
    unit = Column(String(50)) # stock_uom
    dosageForm = Column(String(50), nullable=True) # Cream, Capsule, etc.
    
    # Consumption
    howToConsume = Column(String(200), nullable=True)
    notes = Column(Text, nullable=True) # Signa Text
    signa1 = Column(Integer, nullable=True) # Frequency
    signa2 = Column(Float, nullable=True) # Qty per dose

    # Relationship for Racikan (Concoction)
    ingredients = relationship("MedicineConcoction", back_populates="parent_medicine", foreign_keys="[MedicineConcoction.parent_medicine_id]")
    
    # Relationship for Batches
    batches = relationship("MedicineBatch", back_populates="medicine", cascade="all, delete-orphan")

class MedicineBatch(Base):
    __tablename__ = "medicine_batches"
    
    id = Column(Integer, primary_key=True, index=True)
    medicine_id = Column(Integer, ForeignKey("medicinecore.id"))
    batchNumber = Column(String(50))
    expiryDate = Column(Date, nullable=True)
    qty = Column(Integer, default=0)
    
    medicine = relationship("Medicine", back_populates="batches")


class MedicineConcoction(Base):
    __tablename__ = "medicine_concoctions"
    
    id = Column(Integer, primary_key=True, index=True)
    parent_medicine_id = Column(Integer, ForeignKey("medicinecore.id")) # The Racikan
    child_medicine_id = Column(Integer, ForeignKey("medicinecore.id")) # The Ingredient
    qty_needed = Column(Float, default=1.0)
    
    parent_medicine = relationship("Medicine", foreign_keys=[parent_medicine_id], back_populates="ingredients")
    child_medicine = relationship("Medicine", foreign_keys=[child_medicine_id])

# Alias for backward compatibility or cleaner usage
Doctor = DoctorEntity
