import 'package:equatable/equatable.dart';

class PaymentEntity extends Equatable {
  final int id;
  final int appointmentId;
  final double amount;
  final String? description;
  final String paymentMethod;
  final String status;
  final String? externalId;
  final String? qrString;
  final DateTime? paidAt;
  final DateTime? expiredAt;
  final DateTime createdAt;
  final List<PaymentItemEntity> items;
  final PaymentAppointment? appointment;

  const PaymentEntity({
    required this.id,
    required this.appointmentId,
    required this.amount,
    this.description,
    required this.paymentMethod,
    required this.status,
    this.externalId,
    this.qrString,
    this.paidAt,
    this.expiredAt,
    required this.createdAt,
    this.items = const [],
    this.appointment,
  });

  @override
  List<Object?> get props => [
        id,
        appointmentId,
        amount,
        description,
        paymentMethod,
        status,
        externalId,
        qrString,
        paidAt,
        expiredAt,
        createdAt,
        items,
        appointment,
      ];

  bool get isPaid => status == 'PAID';
  bool get isPending => status == 'PENDING';
  bool get isExpired => status == 'EXPIRED';
}

class PaymentAppointment extends Equatable {
  final String? transactionNumber;
  final String? serviceName;
  final double? servicePrice;
  final double? consultationPrice;
  final double? transportPrice;
  final double? itemsPrice;
  final double? discountAmount;
  final double? finalPrice;
  final String? discountName;
  final String? patientName;

  const PaymentAppointment({
    this.transactionNumber,
    this.serviceName,
    this.servicePrice,
    this.consultationPrice,
    this.transportPrice,
    this.itemsPrice,
    this.discountAmount,
    this.finalPrice,
    this.discountName,
    this.patientName,
  });

  double get originalPrice =>
      (servicePrice ?? 0) +
      (consultationPrice ?? 0) +
      (transportPrice ?? 0) +
      (itemsPrice ?? 0);

  @override
  List<Object?> get props => [
        transactionNumber,
        serviceName,
        servicePrice,
        consultationPrice,
        transportPrice,
        itemsPrice,
        discountAmount,
        finalPrice,
        discountName,
        patientName,
      ];
}

class PaymentItemEntity extends Equatable {
  final int id;
  final String name;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? type;

  const PaymentItemEntity({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.type,
  });

  @override
  List<Object?> get props => [id, name, quantity, unitPrice, totalPrice, type];
}

