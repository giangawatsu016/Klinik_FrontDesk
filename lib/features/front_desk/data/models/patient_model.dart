import 'package:equatable/equatable.dart';
import '../../../../core/constants/config_constants.dart';

class PatientModel extends Equatable {
  final String? name; // Frappe ID
  final String firstName;
  final String? lastName;
  final String email;
  final String nik;
  final String phone;
  final String birthday;
  final String gender;
  final String? medicalRecordNo;
  final int? heightCm;
  final int? weightKg;
  final String religion;
  final String maritalStatus;
  final String education;
  final String? profession;
  final String province;
  final String city;
  final String district; // Kabupaten
  final String subdistrict; // Kecamatan
  final String? rt;
  final String? rw;
  final String? postalCode;
  final String fullAddress;
  final String company;

  const PatientModel({
    this.name,
    required this.firstName,
    this.lastName,
    required this.email,
    required this.nik,
    required this.phone,
    required this.birthday,
    required this.gender,
    this.medicalRecordNo,
    this.heightCm,
    this.weightKg,
    required this.religion,
    required this.maritalStatus,
    required this.education,
    this.profession,
    required this.province,
    required this.city,
    required this.district,
    required this.subdistrict,
    this.rt,
    this.rw,
    this.postalCode,
    required this.fullAddress,
    this.company = ConfigConstants.defaultCompany,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      name: json['name'] as String?,
      firstName:
          json['first_name'] as String? ?? json['firstName'] as String? ?? '',
      lastName: json['last_name'] as String?,
      email: json['email'] as String? ?? '',
      nik: (json['nik'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      birthday:
          json['birth_date'] as String? ?? json['birthday'] as String? ?? '',
      gender: json['gender'] as String? ?? 'Male',
      medicalRecordNo: json['medical_record_no'] as String?,
      heightCm: json['height_cm'] as int?,
      weightKg: json['weight_kg'] as int?,
      religion: json['religion'] as String? ?? 'Islam',
      maritalStatus: json['marital_status'] as String? ?? 'Belum Menikah',
      education: json['education'] as String? ?? 'S1',
      profession: json['profession'] as String?,
      province: json['province'] as String? ?? 'Jawa Barat',
      city: json['city'] as String? ?? 'Bandung',
      district: json['district'] as String? ?? 'Cicendo',
      subdistrict: json['subdistrict'] as String? ?? 'Pasir Kaliki',
      rt: (json['rt'] ?? '').toString(),
      rw: (json['rw'] ?? '').toString(),
      postalCode: (json['postal_code'] ?? '').toString(),
      fullAddress:
          json['address'] as String? ?? json['fullAddress'] as String? ?? '',
      company: json['company'] as String? ?? ConfigConstants.defaultCompany,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'nik': nik,
      'phone': phone,
      'birth_date': birthday,
      'gender': gender,
      'medical_record_no': medicalRecordNo,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'religion': religion,
      'marital_status': maritalStatus,
      'education': education,
      'profession': profession,
      'province': province,
      'city': city,
      'district': district,
      'subdistrict': subdistrict,
      'rt': rt,
      'rw': rw,
      'postal_code': postalCode,
      'address': fullAddress,
      'company': company,
    };
  }

  @override
  List<Object?> get props => [
    name,
    firstName,
    lastName,
    email,
    nik,
    phone,
    birthday,
    gender,
    medicalRecordNo,
    heightCm,
    weightKg,
    religion,
    maritalStatus,
    education,
    profession,
    province,
    city,
    district,
    subdistrict,
    rt,
    rw,
    postalCode,
    fullAddress,
    company,
  ];
}
