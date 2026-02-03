import '../../domain/entities/appointment_entity.dart';
import '../../domain/entities/doctor_entity.dart';

class DoctorModel extends DoctorEntity {
  const DoctorModel({
    required super.id,
    required super.name,
    super.specialization,
    super.photoProfile,
    super.titlePrefix,
    super.titleSuffix,
    super.latitude,
    super.longitude,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id'],
      name: json['name'].toString(),
      specialization: json['specialization']?.toString(),
      photoProfile: json['photoProfile']?.toString(),
      titlePrefix: json['titlePrefix']?.toString(),
      titleSuffix: json['titleSuffix']?.toString(),
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
    );
  }
}

class AppointmentModel extends AppointmentEntity {
  const AppointmentModel({
    required super.id,
    required super.date,
    required super.status,
    required super.serviceName,
    required super.doctorName,
    required super.finalPrice,
    super.serviceId,
    super.doctorId,
    super.doctorTitlePrefix,
    super.doctorTitleSuffix,
    super.doctorSpecialization,
    super.patientDetail,
    super.paymentStatus,
    super.paymentUrl,
    super.externalId,
    super.transactionNumber,
    super.discount,
    super.discountName,
    super.serviceFee,
    super.consultationFee,
    super.transportFee,
    super.items,
    super.clinicalRecord,
    super.doctorSip,
    super.patientSnapshot,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'],
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      status: json['status']?.toString() ?? 'PENDING',
      serviceName:
          json['serviceName']?.toString() ??
          json['service']?['name']?.toString() ??
          '',
      doctorName:
          json['doctorName']?.toString() ??
          json['doctor']?['name']?.toString() ??
          '',
      finalPrice: double.tryParse(json['finalPrice']?.toString() ?? '0') ?? 0.0,
      serviceId: int.tryParse(json['serviceId']?.toString() ?? ''),
      doctorId: int.tryParse(json['doctorId']?.toString() ?? ''),
      doctorTitlePrefix:
          json['doctorTitlePrefix']?.toString() ??
          json['doctor']?['titlePrefix']?.toString(),
      doctorTitleSuffix:
          json['doctorTitleSuffix']?.toString() ??
          json['doctor']?['titleSuffix']?.toString(),
      doctorSpecialization: json['doctor']?['specialization']?.toString(),
      paymentStatus: json['paymentStatus']?.toString(),
      paymentUrl: json['paymentUrl']?.toString(),
      externalId: json['externalId']?.toString(),
      transactionNumber: json['transactionNumber']?.toString(),
      discount: double.tryParse(json['discount']?.toString() ?? ''),
      discountName: json['discountName']?.toString(),
      serviceFee: double.tryParse(json['serviceFee']?.toString() ?? ''),
      consultationFee: double.tryParse(
        json['consultationFee']?.toString() ?? '',
      ),
      transportFee: double.tryParse(json['transportFee']?.toString() ?? ''),
      items: json['items'] is List
          ? List<Map<String, dynamic>>.from(
              json['items'].where((x) => x != null).map((x) => x as Map),
            )
          : null,
      patientDetail: json['patientDetail'] is Map<String, dynamic>
          ? json['patientDetail']
          : (json['patientDetail'] is Map
                ? Map<String, dynamic>.from(json['patientDetail'])
                : null),
      patientSnapshot: json['patientSnapshot'] is Map<String, dynamic>
          ? json['patientSnapshot']
          : (json['patientSnapshot'] is Map
                ? Map<String, dynamic>.from(json['patientSnapshot'])
                : null),
      clinicalRecord: json['clinicalRecord'] is Map<String, dynamic>
          ? json['clinicalRecord']
          : null,
      doctorSip: json['doctor']?['sip']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceId': serviceId,
      'doctorId': doctorId,
      'date': date.toUtc().toIso8601String(),
      'patientDetail': patientDetail,
      'finalPrice': finalPrice, // Added to send price to backend
    };
  }
}
