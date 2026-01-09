class User {
  final String username;
  final String fullName;
  final String role;
  final String token;

  User({
    required this.username,
    required this.fullName,
    required this.role,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json, String token) {
    return User(
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? '',
      role: json['role'] ?? 'staff',
      token: token,
    );
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
  final String? noAssuransi;
  final int maritalStatusId;

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
    this.noAssuransi,
    required this.maritalStatusId,
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
      'noAssuransi': noAssuransi,
      'maritalStatusId': maritalStatusId,
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
      maritalStatusId: json['maritalStatusId'] ?? 1,
      noAssuransi: json['noAssuransi'],
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

  Doctor({
    required this.medicalFacilityPolyDoctorId,
    required this.namaDokter,
    required this.polyName,
    required this.gelarDepan,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      medicalFacilityPolyDoctorId: json['medicalFacilityPolyDoctorId'],
      namaDokter: json['namaDokter'],
      polyName: json['polyName'],
      gelarDepan: json['gelarDepan'] ?? '',
    );
  }
}
