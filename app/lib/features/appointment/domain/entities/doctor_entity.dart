import 'package:equatable/equatable.dart';

class DoctorEntity extends Equatable {
  final int id;
  final String name;
  final String? specialization;
  final String? photoProfile;
  final String? titlePrefix;
  final String? titleSuffix;
  final double? latitude;
  final double? longitude;

  const DoctorEntity({
    required this.id,
    required this.name,
    this.specialization,
    this.photoProfile,
    this.titlePrefix,
    this.titleSuffix,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [id, name, specialization, photoProfile, titlePrefix, titleSuffix, latitude, longitude];
}
