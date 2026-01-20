from pydantic import BaseModel
from typing import List, Optional, Any
from datetime import date, datetime

class UserBase(BaseModel):
    username: str
    email: Optional[str] = None

class UserCreate(UserBase):
    password: str
    full_name: str
    role: str = "staff"

class UserUpdate(UserBase):
    password: Optional[str] = None
    full_name: Optional[str] = None
    role: Optional[str] = None
    email: Optional[str] = None

class User(UserBase):
    id: int
    full_name: str
    role: str
    is_active: bool
    email: Optional[str] # Redundant if in UserBase but good for clarity if overwritten

    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: Optional[str] = None

# Master Data Schemas
class MaritalStatusBase(BaseModel):
    display: str

class MaritalStatus(MaritalStatusBase):
    id: int
    class Config:
        from_attributes = True

class IssuerBase(BaseModel):
    issuer: str
    nama: List[str] # Assuming simple list of strings for sub-issuers

class Issuer(IssuerBase):
    issuerId: int
    class Config:
        from_attributes = True

class DoctorBase(BaseModel):
    gelarDepan: str
    namaDokter: str
    polyName: str
    is_available: bool
    
    # New Fields
    firstName: Optional[str] = None
    lastName: Optional[str] = None
    gelarBelakang: Optional[str] = None
    doctorSIP: Optional[str] = None
    onlineFee: Optional[int] = None
    appointmentFee: Optional[int] = None

class Doctor(DoctorBase):
    medicalFacilityPolyDoctorId: int
    firstName: Optional[str] = None
    lastName: Optional[str] = None
    gelarBelakang: Optional[str] = None
    doctorSIP: Optional[str] = None
    onlineFee: Optional[int] = None
    appointmentFee: Optional[int] = None
    class Config:
        from_attributes = True

# Patient Schemas
class PatientBase(BaseModel):
    firstName: str
    lastName: Optional[str] = None
    phone: str
    gender: str
    birthday: date
    identityCard: str
    religion: str
    profession: str
    education: str
    province: str
    city: str
    district: str
    subdistrict: str
    rt: str
    rw: str
    postalCode: str
    address_details: Optional[str] = None
    address: Optional[str] = None
    nomorRekamMedis: Optional[str] = None
    avatar: Optional[str] = None
    height: Optional[int] = None
    weight: Optional[int] = None
    address_details: Optional[str] = None
    issuerId: int
    insuranceName: Optional[str] = None
    noAssuransi: Optional[str] = None
    maritalStatusId: int

class PatientCreate(PatientBase):
    pass

class Patient(PatientBase):
    id: int
    # Allow expanding relationships if needed
    
    class Config:
        from_attributes = True

# Queue Schemas
class QueueBase(BaseModel):
    userId: int # Patient ID
    medicalFacilityPolyDoctorId: Optional[int] = None
    isPriority: bool = False
    queueType: str = "Doctor" # Doctor, Polyclinic
    polyclinic: Optional[str] = None

class QueueCreate(QueueBase):
    pass

class QueueUpdateStatus(BaseModel):
    status: str

class PatientQueue(QueueBase):
    id: int
    numberQueue: str
    appointmentTime: datetime
    status: str
    isChecked: bool
    
    patient: Patient
    doctor: Optional[Doctor] = None
    
    class Config:
        from_attributes = True

# Medicine Schemas
class MedicineBase(BaseModel):
    erpnextItemCode: str
    medicineName: str
    medicineDescription: Optional[str] = None
    medicineLabel: Optional[str] = None
    medicinePrice: Optional[int] = 0
    medicineRetailPrice: Optional[int] = 0
    qty: int = 0
    unit: Optional[str] = None
    howToConsume: Optional[str] = None
    notes: Optional[str] = None # Signa Text
    signa1: Optional[int] = None
    signa2: Optional[float] = None

class MedicineCreate(MedicineBase):
    pass

class Medicine(MedicineBase):
    id: int
    erpnext_item_code: str
    class Config:
        from_attributes = True

# Concoction Schemas
class ConcoctionItemCreate(BaseModel):
    child_medicine_id: int
    qty: float

class ConcoctionCreate(BaseModel):
    medicineName: str
    items: List[ConcoctionItemCreate]
    serviceFee: Optional[int] = 0
    totalQty: int
    unit: str = "Pcs"
    description: Optional[str] = None
