# Entity Relationship Diagram (ERD) - Klinik Intimedicare
**Version:** 2.8 (Matches `backend/models.py`)

```mermaid
erDiagram

    %% Users (Staff/Admin)
    User {
        int id PK
        string username "Unique"
        string email "Unique, Sync Key"
        string password_hash
        string full_name
        string role "default: staff"
        boolean is_active
    }

    %% Master Data: Marital Status
    MaritalStatus {
        int id PK
        string display "Single, Married, etc."
    }

    %% Master Data: Issuer (Insurance/Payment)
    Issuer {
        int issuerId PK
        string issuer "BPJS, Insurance, General"
        string nama "Specific Provider (e.g. Allianz)"
    }

    %% Master Data: Doctors
    DoctorEntity {
        int medicalFacilityPolyDoctorId PK
        string gelarDepan
        string namaDokter
        string gelarBelakang
        string firstName
        string lastName
        string polyName
        string identityCard "NIK - Unique"
        string ihs_practitioner_number "SatuSehat ID"
        string doctorSIP
        int onlineFee
        int appointmentFee
        boolean is_available
    }

    %% Master Data: Pharmacist
    Pharmacist {
        int id PK
        string name
        string nik "16 Digit"
        string sip_no "License"
        string ihs_number
        string erp_employee_id
        boolean is_active
        datetime created_at
    }

    %% Config
    AppConfig {
        string key PK
        string value "JSON/Text"
    }

    %% Core: Medicine
    Medicine {
        int id PK
        string erpnext_item_code "Unique - Link to ERPNext Item"
        string medicineName
        string medicineDescription
        string medicineLabel
        int medicinePrice "Buy Price"
        int medicineRetailPrice "Sell Price"
        int qty "Stock"
        string unit "uom"
        string dosage_form
        string howToConsume
        string notes
        int signa1
        float signa2
    }

    %% Core: Medicine Batch
    MedicineBatch {
        int id PK
        int medicineId FK
        string batchNumber
        date expiryDate
        int qty
    }

    %% Core: Patient
    Patient {
        int id PK
        string identityCard "NIK - Unique"
        string frappe_id "ERPNext Customer Link"
        string ihs_number "Satu Sehat ID"
        string firstName
        string lastName
        string phone "Unique"
        string gender
        date birthday
        datetime created_at "System Timestamp"
        string religion
        string profession
        string education
        string nomorRekamMedis
        int height "cm"
        int weight "kg"
        string address
        string province
        string city
        string district
        string subdistrict
        string postalCode
        string rt
        string rw
        int maritalStatusId FK
        int issuerId FK
        string insuranceName
        string noAssuransi
    }

    %% Core: Appointment (Janji Temu)
    Appointment {
        int id PK
        string nik_patient "Indexed"
        int doctor_id
        string doctor_name
        date appointment_date
        string appointment_time
        string notes
        string status "Scheduled, etc."
        datetime created_at
    }

    %% Core: Queue
    PatientQueue {
        int id PK
        string numberQueue "e.g. P-001"
        datetime appointmentTime
        string status "Waiting, Completed"
        boolean isPriority
        boolean isChecked
        string queueType "Doctor or Polyclinic"
        string polyclinic
        int userId FK "Refers to Patient"
        int medicalFacilityPolyDoctorId FK
    }

    %% Core: Payments
    Payment {
        int id PK
        int patient_id FK
        int amount
        string method "Cash, BPJS, Insurance"
        string insuranceName
        string insuranceNumber
        string notes
        string claimStatus
        datetime created_at
    }

    %% Relationships
    Patient }|..|| MaritalStatus : "has"
    Patient }|..|| Issuer : "uses payment"
    Patient ||--o{ PatientQueue : "requests"
    Patient ||--o{ Payment : "makes"
    DoctorEntity ||--o{ PatientQueue : "assigned to"
    Medicine ||--o{ MedicineBatch : "has batches"
    
```
