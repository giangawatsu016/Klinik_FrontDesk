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
      name: json['name']?.toString(),
      patient: json['patient']?.toString() ?? '',
      patientName: json['patient_name']?.toString(),
      patientBirthDate: json['patient_birth_date']?.toString(),
      queueNumber: json['queue_number']?.toString(),
      isPriority: int.tryParse(json['is_priority']?.toString() ?? '0') ?? 0,
      queueType: json['queue_type']?.toString() ?? 'Doctor',
      practitioner: json['practitioner']?.toString(),
      practitionerName: json['practitioner_name']?.toString(),
      polyclinic: json['polyclinic']?.toString(),
      appointment: json['appointment']?.toString(),
      bloodPressure: json['blood_pressure']?.toString(),
      temperature: double.tryParse(json['temperature']?.toString() ?? ''),
      weight: double.tryParse(json['weight']?.toString() ?? ''),
      height: double.tryParse(json['height']?.toString() ?? ''),
      status: json['status']?.toString() ?? 'Waiting',
      calledAt: json['called_at']?.toString(),
      completedAt: json['completed_at']?.toString(),
      company: json['company']?.toString() ?? ConfigConstants.defaultCompany,
      facility: json['facility']?.toString() ?? ConfigConstants.defaultFacility,
      paymentMethod: json['payment_method']?.toString(),
      creation: json['creation']?.toString(),
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
