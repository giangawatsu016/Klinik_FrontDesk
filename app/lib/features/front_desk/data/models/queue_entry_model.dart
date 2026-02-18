import 'package:equatable/equatable.dart';
import '../../../../core/constants/config_constants.dart';

class QueueEntryModel extends Equatable {
  final String? name; // Frappe ID
  final String patient; // Patient ID
  final String? patientName;
  final String? patientBirthDate;
  final String? queueNumber;
  final int isPriority; // Frappe Check is 0 or 1
  final String queueType; // Doctor, Polyclinic
  final String? practitioner;
  final String? practitionerName;
  final String? polyclinic;
  final String status; // Waiting, Called, Completed, Cancelled
  final String? calledAt;
  final String? completedAt;
  final String? appointment;
  final String? bloodPressure;
  final double? temperature;
  final double? weight;
  final double? height;
  final String company;
  final String facility;
  final String? paymentMethod;
  final String? creation;

  const QueueEntryModel({
    this.name,
    required this.patient,
    this.patientName,
    this.patientBirthDate,
    this.queueNumber,
    this.isPriority = 0,
    required this.queueType,
    this.practitioner,
    this.practitionerName,
    this.polyclinic,
    this.appointment,
    this.bloodPressure,
    this.temperature,
    this.weight,
    this.height,
    this.status = 'Waiting',
    this.calledAt,
    this.completedAt,
    this.company = ConfigConstants.defaultCompany,
    this.facility = ConfigConstants.defaultFacility,
    this.paymentMethod,
    this.creation,
  });

  factory QueueEntryModel.fromJson(Map<String, dynamic> json) {
    return QueueEntryModel(
      name: json['name'] as String?,
      patient: json['patient'] as String? ?? '',
      patientName: json['patient_name'] as String?,
      patientBirthDate: json['patient_birth_date'] as String?,
      queueNumber: json['queue_number'] as String?,
      isPriority: json['is_priority'] as int? ?? 0,
      queueType: json['queue_type'] as String? ?? 'Doctor',
      practitioner: json['practitioner'] as String?,
      practitionerName: json['practitioner_name'] as String?,
      polyclinic: json['polyclinic'] as String?,
      appointment: json['appointment'] as String?,
      bloodPressure: json['blood_pressure'] as String?,
      temperature: (json['temperature'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'Waiting',
      calledAt: json['called_at'] as String?,
      completedAt: json['completed_at'] as String?,
      company: json['company'] as String? ?? ConfigConstants.defaultCompany,
      facility: json['facility'] as String? ?? ConfigConstants.defaultFacility,
      paymentMethod: json['payment_method'] as String?,
      creation: json['creation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'patient': patient,
      'patient_name': patientName,
      'patient_birth_date': patientBirthDate,
      'queue_number': queueNumber,
      'is_priority': isPriority,
      'queue_type': queueType,
      'practitioner': practitioner,
      'practitioner_name': practitionerName,
      'polyclinic': polyclinic,
      'appointment': appointment,
      'blood_pressure': bloodPressure,
      'temperature': temperature,
      'weight': weight,
      'height': height,
      'status': status,
      'called_at': calledAt,
      'completed_at': completedAt,
      'company': company,
      'facility': facility,
      'payment_method': paymentMethod,
      'creation': creation,
    };
  }

  @override
  List<Object?> get props => [
    name,
    patient,
    patientName,
    patientBirthDate,
    queueNumber,
    isPriority,
    queueType,
    practitioner,
    practitionerName,
    polyclinic,
    polyclinic,
    appointment,
    bloodPressure,
    temperature,
    weight,
    height,
    status,
    calledAt,
    completedAt,
    company,
    facility,
    creation,
  ];
}
