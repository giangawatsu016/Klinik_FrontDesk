import 'package:equatable/equatable.dart';

class AuthEntity extends Equatable {
  final String token;
  final UserEntity user;

  const AuthEntity({required this.token, required this.user});

  @override
  List<Object?> get props => [token, user];
}

class UserEntity extends Equatable {
  final int id;
  final String email;
  final String name;
  final String role;
  final String tier;
  final String? photoProfile;
  final String? gender;
  final DateTime? birthday;
  final String? phone;
  final String? address;
  final String? nik;
  final String? locationNote;
  final double? latitude;
  final double? longitude;
  final String? satuSehatId;
  final String? staffId;
  final String? company;
  final String? facility;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.tier,
    this.photoProfile,
    this.gender,
    this.birthday,
    this.phone,
    this.address,
    this.nik,
    this.locationNote,
    this.latitude,
    this.longitude,
    this.satuSehatId,
    this.staffId,
    this.company,
    this.facility,
  });

  UserEntity copyWith({
    String? name,
    String? photoProfile,
    String? gender,
    DateTime? birthday,
    String? phone,
    String? address,
    String? nik,
    String? locationNote,
    double? latitude,
    double? longitude,
    String? satuSehatId,
    String? staffId,
    String? company,
    String? facility,
  }) {
    return UserEntity(
      id: id,
      email: email,
      name: name ?? this.name,
      role: role,
      tier: tier,
      photoProfile: photoProfile ?? this.photoProfile,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      nik: nik ?? this.nik,
      locationNote: locationNote ?? this.locationNote,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      satuSehatId: satuSehatId ?? this.satuSehatId,
      staffId: staffId ?? this.staffId,
      company: company ?? this.company,
      facility: facility ?? this.facility,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    name,
    role,
    tier,
    photoProfile,
    gender,
    birthday,
    phone,
    address,
    nik,
    locationNote,
    latitude,
    longitude,
    satuSehatId,
    staffId,
    company,
    facility,
  ];
}
