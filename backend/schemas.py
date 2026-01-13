from pydantic import BaseModel
from typing import List, Optional, Any
from datetime import date, datetime

class UserBase(BaseModel):
    username: str

class UserCreate(UserBase):
    password: str
    full_name: str
    role: str = "staff"

class User(UserBase):
    id: int
    full_name: str
    role: str
    is_active: bool

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

class Doctor(DoctorBase):
    medicalFacilityPolyDoctorId: int
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
