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
    DateTime parsedDate;
    try {
      final dateStr =
          json['appointment_date']?.toString() ??
          json['date']?.toString() ??
          '';
      final timeStr = json['appointment_time']?.toString() ?? '00:00:00';

      if (dateStr.isNotEmpty) {
        if (dateStr.contains('T')) {
          parsedDate = DateTime.tryParse(dateStr) ?? DateTime.now();
        } else {
          // Combine date and time
          parsedDate =
              DateTime.tryParse('$dateStr $timeStr') ??
              DateTime.tryParse(dateStr) ??
              DateTime.now();
        }
      } else {
        parsedDate = DateTime.now();
      }
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return AppointmentModel(
      id: json['name']?.toString() ?? json['id']?.toString() ?? '',
      date: parsedDate,
      status: json['status']?.toString() ?? 'PENDING',
      serviceName:
          json['serviceName']?.toString() ??
          json['service_type']?.toString() ??
          json['service']?['name']?.toString() ??
          '',
      doctorName:
          json['doctorName']?.toString() ??
          json['practitioner']?.toString() ??
          json['doctor']?['name']?.toString() ??
          '',
      finalPrice:
          double.tryParse(json['finalPrice']?.toString() ?? '0') ??
          double.tryParse(json['grand_total']?.toString() ?? '0') ??
          0.0,
      serviceId: int.tryParse(json['serviceId']?.toString() ?? ''),
      doctorId: int.tryParse(json['doctorId']?.toString() ?? ''),
      doctorTitlePrefix:
          json['doctorTitlePrefix']?.toString() ??
          json['doctor']?['titlePrefix']?.toString(),
      doctorTitleSuffix:
          json['doctorTitleSuffix']?.toString() ??
          json['doctor']?['titleSuffix']?.toString(),
      doctorSpecialization: json['doctor']?['specialization']?.toString(),
      paymentStatus:
          json['paymentStatus']?.toString() ??
          json['payment_status']?.toString(),
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
      patientDetail:
          (json['patientDetail'] is Map
                ? Map<String, dynamic>.from(json['patientDetail'])
                : <String, dynamic>{})
            ..addAll({
              if (json.containsKey('patient_name'))
                'patient_name': json['patient_name'],
              if (json.containsKey('patient_phone'))
                'phone': json['patient_phone'],
              if (json.containsKey('patient_dob')) 'dob': json['patient_dob'],
              if (json.containsKey('patient')) 'name': json['patient'],
              if (json.containsKey('_debug_total_count'))
                '_debug_total_count': json['_debug_total_count'],
            }),
      patientSnapshot: (json['patientSnapshot'] is Map
          ? Map<String, dynamic>.from(json['patientSnapshot'])
          : (json['patient'] is Map && json['patient'].containsKey('full_name')
                ? {'fullName': json['patient']['full_name']}
                : null)),
      clinicalRecord: json['clinicalRecord'] is Map<String, dynamic>
          ? json['clinicalRecord']
          : null,
      doctorSip:
          json['doctorSip']?.toString() ?? json['doctor']?['sip']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceId': serviceId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'serviceName': serviceName,
      'date': date.toUtc().toIso8601String(),
      'patientDetail': patientDetail,
      'finalPrice': finalPrice, // Added to send price to backend
    };
  }
}
