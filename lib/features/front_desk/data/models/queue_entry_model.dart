import 'package:equatable/equatable.dart';
import '../../../../core/constants/config_constants.dart';

class QueueEntryModel extends Equatable {
  final String? name; // Frappe ID
  final String patient; // Patient ID
  final String? patientName;
  final String? queueNumber;
  final int isPriority; // Frappe Check is 0 or 1
  final String queueType; // Doctor, Polyclinic
  final String? practitioner;
  final String? polyclinic;
  final String status; // Waiting, Called, Completed, Cancelled
  final String? calledAt;
  final String? completedAt;
  final String company;
  final String facility;

  const QueueEntryModel({
    this.name,
    required this.patient,
    this.patientName,
    this.queueNumber,
    this.isPriority = 0,
    required this.queueType,
    this.practitioner,
    this.polyclinic,
    this.status = 'Waiting',
    this.calledAt,
    this.completedAt,
    this.company = ConfigConstants.defaultCompany,
    this.facility = ConfigConstants.defaultFacility,
  });

  factory QueueEntryModel.fromJson(Map<String, dynamic> json) {
    return QueueEntryModel(
      name: json['name'] as String?,
      patient: json['patient'] as String? ?? '',
      patientName: json['patient_name'] as String?,
      queueNumber: json['queue_number'] as String?,
      isPriority: json['is_priority'] as int? ?? 0,
      queueType: json['queue_type'] as String? ?? 'Doctor',
      practitioner: json['practitioner'] as String?,
      polyclinic: json['polyclinic'] as String?,
      status: json['status'] as String? ?? 'Waiting',
      calledAt: json['called_at'] as String?,
      completedAt: json['completed_at'] as String?,
      company: json['company'] as String? ?? ConfigConstants.defaultCompany,
      facility: json['facility'] as String? ?? ConfigConstants.defaultFacility,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'patient': patient,
      'patient_name': patientName,
      'queue_number': queueNumber,
      'is_priority': isPriority,
      'queue_type': queueType,
      'practitioner': practitioner,
      'polyclinic': polyclinic,
      'status': status,
      'called_at': calledAt,
      'completed_at': completedAt,
      'company': company,
      'facility': facility,
    };
  }

  @override
  List<Object?> get props => [
    name,
    patient,
    patientName,
    queueNumber,
    isPriority,
    queueType,
    practitioner,
    polyclinic,
    status,
    calledAt,
    completedAt,
    company,
    facility,
  ];
}
