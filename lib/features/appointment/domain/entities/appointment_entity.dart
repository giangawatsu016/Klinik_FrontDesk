import 'package:equatable/equatable.dart';


class AppointmentEntity extends Equatable {
  final int id;
  final DateTime date;
  final String status;
  final String serviceName;
  final String doctorName;
  final double finalPrice;
  final int? serviceId;
  final int? doctorId;
  final String? doctorTitlePrefix;
  final String? doctorTitleSuffix;
  final String? doctorSpecialization;
  final Map<String, dynamic>? patientDetail;
  final String? paymentStatus;
  final String? paymentUrl;
  final String? externalId;
  final String? transactionNumber;
  final double? discount;
  final String? discountName;
  // Breakdown
  final double? serviceFee;
  final double? consultationFee;
  final double? transportFee;
  final Map<String, dynamic>? clinicalRecord;
  final String? doctorSip;
  final List<Map<String, dynamic>>? items;
  final Map<String, dynamic>? patientSnapshot;
  
  String? get medicalRecordNumber => patientDetail?['medicalRecordNumber']?.toString();

  const AppointmentEntity({
    required this.id,
    required this.date,
    required this.status,
    required this.serviceName,
    required this.doctorName,
    required this.finalPrice,
    this.serviceId,
    this.doctorId,
    this.doctorTitlePrefix,
    this.doctorTitleSuffix,
    this.doctorSpecialization,
    this.patientDetail,
    this.paymentStatus,
    this.paymentUrl,
    this.externalId,
    this.transactionNumber,
    this.discount,
    this.discountName,
    this.serviceFee,
    this.consultationFee,
    this.transportFee,
    this.items,
    this.clinicalRecord,
    this.doctorSip,
    this.patientSnapshot,
  });

  @override
  List<Object?> get props => [id, date, status, clinicalRecord, doctorSip, serviceName, doctorName, finalPrice, serviceId, doctorId, doctorTitlePrefix, doctorTitleSuffix, doctorSpecialization, patientDetail, paymentStatus, paymentUrl, externalId, transactionNumber, discount, discountName, serviceFee, consultationFee, transportFee, items, patientSnapshot];
}
