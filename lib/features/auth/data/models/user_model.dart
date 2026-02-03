import '../../domain/entities/auth_entity.dart';

class AuthModel extends AuthEntity {
  const AuthModel({required super.token, required super.user});

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      token: json['token'].toString(),
      user: UserModel.fromJson(json['user']),
    );
  }
}

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.role,
    required super.tier,
    super.photoProfile,
    super.gender,
    super.birthday,
    super.phone,
    super.address,
    super.nik,
    super.locationNote,
    super.latitude,
    super.longitude,
    super.satuSehatId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // If user is nested within patient, extract from there if needed
    final patient = json['patient'];
    return UserModel(
      id: json['id'],
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'PATIENT',
      tier: json['tier']?.toString() ?? 'BASIC',
      photoProfile: patient != null ? patient['photoProfile']?.toString() : json['photoProfile']?.toString(),
      gender: patient != null ? patient['gender']?.toString() : null,
      birthday: patient != null && patient['birthday'] != null ? DateTime.parse(patient['birthday']) : null,
      phone: patient != null ? patient['phone']?.toString() : null,
      address: patient != null ? patient['address']?.toString() : null,
      nik: patient != null ? patient['nik']?.toString() : null,
      locationNote: patient != null ? patient['locationNote']?.toString() : null,
      latitude: patient != null && patient['latitude'] != null 
          ? double.tryParse(patient['latitude'].toString()) 
          : (json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null),
      longitude: patient != null && patient['longitude'] != null 
          ? double.tryParse(patient['longitude'].toString()) 
          : (json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null),
      satuSehatId: patient != null ? patient['satusehatId']?.toString() : null,
    );
  }
}
