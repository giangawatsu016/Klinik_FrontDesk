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
  final String? patientStatus;
  final String? idPatientSatusehat;
  final int? heightCm;
  final String? bloodType;
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

  String get fullName => "$firstName ${lastName ?? ''}".trim();

  const PatientModel({
    this.name,
    required this.firstName,
    this.lastName,
    required this.email,
    required this.nik,
    required this.phone,
    required this.birthday,
    required this.gender,
    this.patientStatus,
    this.idPatientSatusehat,
    this.heightCm,
    this.bloodType,
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
    final rawFirstName =
        json['first_name'] as String? ?? json['firstName'] as String?;
    final rawLastName = json['last_name'] as String?;
    final rawFullName =
        json['full_name'] as String? ?? json['patient_name'] as String? ?? '';

    String firstName = '';
    String? lastName;

    if (rawFirstName != null && rawFirstName.isNotEmpty) {
      firstName = rawFirstName;
      lastName = (rawLastName != null && rawLastName.isNotEmpty)
          ? rawLastName
          : null;
    } else if (rawFullName.isNotEmpty) {
      final parts = rawFullName.split(' ');
      firstName = parts.first;
      lastName = parts.length > 1 ? parts.skip(1).join(' ') : null;
    }

    return PatientModel(
      name: json['name'] as String?,
      firstName: firstName,
      lastName: lastName,
      email: json['email'] as String? ?? '',
      nik: (json['nik'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      birthday:
          json['birth_date'] as String? ?? json['birthday'] as String? ?? '',
      gender: json['gender'] as String? ?? 'Male',
      patientStatus: json['patient_status'] as String?,
      idPatientSatusehat: json['id_patient_satusehat'] as String?,
      heightCm: json['height_cm'] is int?
          ? json['height_cm'] as int?
          : int.tryParse(json['height_cm']?.toString() ?? ''),
      bloodType: json['blood_type']?.toString(),
      religion: json['religion']?.toString() ?? 'Islam',
      maritalStatus: json['marital_status']?.toString() ?? 'Single',
      education: json['education']?.toString() ?? 'Sarjana (S1)',
      profession: json['profession']?.toString(),
      province: json['province']?.toString() ?? 'Jawa Barat',
      city: json['city']?.toString() ?? 'Bandung',
      district: json['district']?.toString() ?? 'Cicendo',
      subdistrict: json['subdistrict']?.toString() ?? 'Pasir Kaliki',
      rt: (json['rt'] ?? '').toString(),
      rw: (json['rw'] ?? '').toString(),
      postalCode: (json['postal_code'] ?? '').toString(),
      fullAddress:
          json['address']?.toString() ?? json['fullAddress']?.toString() ?? '',
      company: json['company']?.toString() ?? ConfigConstants.defaultCompany,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'full_name': '$firstName ${lastName ?? ''}'.trim(),
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'nik': nik,
      'phone': phone,
      'birth_date': birthday,
      'gender': gender,
      'patient_status': patientStatus,
      'id_patient_satusehat': idPatientSatusehat,
      'height_cm': heightCm,
      'blood_type': bloodType,
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

  PatientModel copyWith({
    String? name,
    String? firstName,
    String? lastName,
    String? email,
    String? nik,
    String? phone,
    String? birthday,
    String? gender,
    String? patientStatus,
    String? idPatientSatusehat,
    int? heightCm,
    String? bloodType,
    String? religion,
    String? maritalStatus,
    String? education,
    String? profession,
    String? province,
    String? city,
    String? district,
    String? subdistrict,
    String? rt,
    String? rw,
    String? postalCode,
    String? fullAddress,
    String? company,
  }) {
    return PatientModel(
      name: name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      nik: nik ?? this.nik,
      phone: phone ?? this.phone,
      birthday: birthday ?? this.birthday,
      gender: gender ?? this.gender,
      patientStatus: patientStatus ?? this.patientStatus,
      idPatientSatusehat: idPatientSatusehat ?? this.idPatientSatusehat,
      heightCm: heightCm ?? this.heightCm,
      bloodType: bloodType ?? this.bloodType,
      religion: religion ?? this.religion,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      education: education ?? this.education,
      profession: profession ?? this.profession,
      province: province ?? this.province,
      city: city ?? this.city,
      district: district ?? this.district,
      subdistrict: subdistrict ?? this.subdistrict,
      rt: rt ?? this.rt,
      rw: rw ?? this.rw,
      postalCode: postalCode ?? this.postalCode,
      fullAddress: fullAddress ?? this.fullAddress,
      company: company ?? this.company,
    );
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
    patientStatus,
    idPatientSatusehat,
    heightCm,
    bloodType,
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
