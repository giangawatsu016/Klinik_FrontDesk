class User {
  final int? id;
  final String username;
  final String fullName;
  final String role;
  final String token;
  final String email;

  User({
    this.id,
    required this.username,
    required this.fullName,
    required this.role,
    this.token = "",
    this.email = "",
  });

  factory User.fromJson(Map<String, dynamic> json, [String token = ""]) {
    return User(
      id: json['id'],
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? '',
      role: json['role'] ?? 'staff',
      token: token,
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'username': username,
      'full_name': fullName,
      'role': role,
      'email': email,
      'token': token,
    };
  }
}

class Disease {
  final int? id;
  final String icdCode;
  final String name;
  final String? description;
  final bool isActive;

  Disease({
    this.id,
    required this.icdCode,
    required this.name,
    this.description,
    this.isActive = true,
  });

  factory Disease.fromJson(Map<String, dynamic> json) {
    return Disease(
      id: json['id'],
      icdCode: json['icd_code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'icd_code': icdCode,
      'name': name,
      'description': description,
      'is_active': isActive,
    };
  }
}

class Patient {
  final int? id;
  final String firstName;
  final String lastName;
  final String identityCard;
  final String phone;
  final String gender;
  final String birthday;
  final String religion;
  final String profession;
  final String education;
  final String province;
  final String city;
  final String district;
  final String subdistrict;
  final String rt;
  final String rw;
  final String postalCode;
  final String? addressDetails;
  final int issuerId;
  final String? insuranceName;
  final String? noAssuransi;
  final int maritalStatusId;
  final String? frappeId;
  final String? ihsNumber;
  final String? nomorRekamMedis;
  final String? avatar;
  final int? height;
  final int? weight;
  final String? address;

  Patient({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.identityCard,
    required this.phone,
    required this.gender,
    required this.birthday,
    required this.religion,
    required this.profession,
    required this.education,
    required this.province,
    required this.city,
    required this.district,
    required this.subdistrict,
    required this.rt,
    required this.rw,
    required this.postalCode,
    this.addressDetails,
    required this.issuerId,
    this.insuranceName,
    this.noAssuransi,
    required this.maritalStatusId,
    this.frappeId,
    this.ihsNumber,
    this.nomorRekamMedis,
    this.avatar,
    this.height,
    this.weight,
    this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'identityCard': identityCard,
      'phone': phone,
      'gender': gender,
      'birthday': birthday,
      'religion': religion,
      'profession': profession,
      'education': education,
      'province': province,
      'city': city,
      'district': district,
      'subdistrict': subdistrict,
      'rt': rt,
      'rw': rw,
      'postalCode': postalCode,
      'address_details': addressDetails,
      'issuerId': issuerId,
      'insuranceName': insuranceName,
      'noAssuransi': noAssuransi,
      'maritalStatusId': maritalStatusId,
      'frappe_id': frappeId,
      'ihs_number': ihsNumber,
      'nomorRekamMedis': nomorRekamMedis,
      'avatar': avatar,
      'height': height,
      'weight': weight,
      'address': address,
    };
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      identityCard: json['identityCard'] ?? '',
      phone: json['phone'] ?? '',
      gender: json['gender'] ?? 'Male',
      birthday: json['birthday'] != null
          ? json['birthday'].toString().substring(0, 10)
          : '2000-01-01',
      religion: json['religion'] ?? '',
      profession: json['profession'] ?? '',
      education: json['education'] ?? '',
      province: json['province'] ?? '',
      city: json['city'] ?? '',
      district: json['district'] ?? '',
      subdistrict: json['subdistrict'] ?? '',
      rt: json['rt'] ?? '',
      rw: json['rw'] ?? '',
      postalCode: json['postalCode'] ?? '',
      addressDetails: json['address_details'],
      issuerId: json['issuerId'] ?? 1,
      insuranceName: json['insuranceName'],
      maritalStatusId: json['maritalStatusId'] ?? 1,
      noAssuransi: json['noAssuransi'],
      frappeId: json['frappe_id'],
      ihsNumber: json['ihs_number'],
      nomorRekamMedis: json['nomorRekamMedis'],
      avatar: json['avatar'],
      height: json['height'],
      weight: json['weight'],
      address: json['address'],
    );
  }
}

class QueueItem {
  final int id;
  final String numberQueue;
  final String status;
  final bool isPriority;
  final String appointmentTime;

  final Patient? patient;
  final Doctor? doctor;
  final String? queueType;
  final String? polyclinic;

  QueueItem({
    required this.id,
    required this.numberQueue,
    required this.status,
    required this.isPriority,
    required this.appointmentTime,
    this.patient,
    this.doctor,
    this.queueType,
    this.polyclinic,
  });

  factory QueueItem.fromJson(Map<String, dynamic> json) {
    return QueueItem(
      id: json['id'],
      numberQueue: json['numberQueue'],
      status: json['status'],
      isPriority: json['isPriority'],
      appointmentTime: json['appointmentTime'],
      patient: json['patient'] != null
          ? Patient.fromJson(json['patient'])
          : null,
      doctor: json['doctor'] != null ? Doctor.fromJson(json['doctor']) : null,
      queueType: json['queueType'],
      polyclinic: json['polyclinic'],
    );
  }
}

class Doctor {
  final int medicalFacilityPolyDoctorId;
  final String namaDokter;
  final String polyName;
  final String gelarDepan;
  final String? firstName;
  final String? lastName;
  final String? gelarBelakang;
  final String? doctorSIP;
  final int? onlineFee;
  final int? appointmentFee;

  Doctor({
    required this.medicalFacilityPolyDoctorId,
    required this.namaDokter,
    required this.polyName,
    required this.gelarDepan,
    this.firstName,
    this.lastName,
    this.gelarBelakang,
    this.doctorSIP,
    this.onlineFee,
    this.appointmentFee,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      medicalFacilityPolyDoctorId: json['medicalFacilityPolyDoctorId'],
      namaDokter: json['namaDokter'],
      polyName: json['polyName'],
      gelarDepan: json['gelarDepan'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      gelarBelakang: json['gelarBelakang'],
      doctorSIP: json['doctorSIP'],
      onlineFee: json['onlineFee'],
      appointmentFee: json['appointmentFee'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Doctor &&
        other.medicalFacilityPolyDoctorId == medicalFacilityPolyDoctorId;
  }

  @override
  int get hashCode => medicalFacilityPolyDoctorId.hashCode;
}

class Medicine {
  final int? id;
  final String erpnextItemCode;
  final String medicineName;
  final String? medicineDescription;
  final String? medicineLabel;
  final int medicinePrice;
  final int medicineRetailPrice;
  final int qty;
  final String unit;
  final String? dosageForm; // New
  final String? howToConsume;
  final String? notes; // Signa Text
  final int? signa1;
  final double? signa2;
  final List<MedicineBatch> batches;

  Medicine({
    this.id,
    required this.erpnextItemCode,
    required this.medicineName,
    this.medicineDescription,
    this.medicineLabel,
    this.medicinePrice = 0,
    this.medicineRetailPrice = 0,
    required this.qty,
    required this.unit,
    this.dosageForm,
    this.howToConsume,
    this.notes,
    this.signa1,
    this.signa2,
    this.batches = const [],
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'],
      erpnextItemCode:
          json['erpnextItemCode'] ?? json['erpnext_item_code'] ?? '',
      medicineName: json['medicineName'] ?? '',
      medicineDescription: json['medicineDescription'],
      medicineLabel: json['medicineLabel'],
      medicinePrice: json['medicinePrice'] ?? 0,
      medicineRetailPrice: json['medicineRetailPrice'] ?? 0,
      qty: json['qty'] ?? 0,
      unit: json['unit'] ?? 'Unit',
      dosageForm: json['dosageForm'],
      howToConsume: json['howToConsume'],
      notes: json['notes'],
      signa1: json['signa1'],
      signa2: json['signa2'] != null
          ? (json['signa2'] as num).toDouble()
          : null,
      batches: json['batches'] != null
          ? (json['batches'] as List)
                .map((i) => MedicineBatch.fromJson(i))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'erpnextItemCode': erpnextItemCode,
      'medicineName': medicineName,
      'medicineDescription': medicineDescription,
      'medicineLabel': medicineLabel,
      'medicinePrice': medicinePrice,
      'medicineRetailPrice': medicineRetailPrice,
      'qty': qty,
      'unit': unit,
      'dosageForm': dosageForm,
      'howToConsume': howToConsume,
      'notes': notes,
      'signa1': signa1,
      'signa2': signa2,
    };
  }

  // Helper to extract "Paracetamol" from "Paracetamol 500 mg Tablet..."
  String get simplifiedName {
    if (medicineName.isEmpty) return "Unknown";
    // Regex: Find first occurrence of " <digit>" indicating start of dosage
    final match = RegExp(r'\s\d').firstMatch(medicineName);
    if (match != null) {
      return medicineName.substring(0, match.start).trim();
    }
    // Fallback: If no dosage found, check if it's very long and has parenthesis
    if (medicineName.contains('(')) {
      return medicineName.split('(').first.trim();
    }
    return medicineName;
  }
}

class MedicineBatch {
  final int id;
  final int medicineId;
  final String batchNumber;
  final String? expiryDate;
  final int qty;

  MedicineBatch({
    required this.id,
    required this.medicineId,
    required this.batchNumber,
    this.expiryDate,
    required this.qty,
  });

  factory MedicineBatch.fromJson(Map<String, dynamic> json) {
    return MedicineBatch(
      id: json['id'] ?? 0,
      medicineId: json['medicine_id'] ?? 0,
      batchNumber: json['batchNumber'] ?? '',
      expiryDate: json['expiryDate'],
      qty: json['qty'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'batchNumber': batchNumber,
    'expiryDate': expiryDate,
    'qty': qty,
  };
}

class Payment {
  final int? id;
  final int patientId;
  final int amount;
  final String method;
  final String? insuranceName;
  final String? insuranceNumber;
  final String? notes;
  final String? claimStatus;
  final String? createdAt;

  Payment({
    this.id,
    required this.patientId,
    required this.amount,
    required this.method,
    this.insuranceName,
    this.insuranceNumber,
    this.notes,
    this.claimStatus,
    this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      patientId: json['patient_id'],
      amount: json['amount'],
      method: json['method'],
      insuranceName: json['insuranceName'],
      insuranceNumber: json['insuranceNumber'],
      notes: json['notes'],
      claimStatus: json['claimStatus'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'amount': amount,
      'method': method,
      'insuranceName': insuranceName,
      'insuranceNumber': insuranceNumber,
      'notes': notes,
    };
  }
}
