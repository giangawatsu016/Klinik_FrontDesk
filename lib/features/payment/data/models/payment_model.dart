import '../../domain/entities/payment_entity.dart';

class PaymentModel extends PaymentEntity {
  const PaymentModel({
    required super.id,
    required super.appointmentId,
    required super.amount,
    super.description,
    required super.paymentMethod,
    required super.status,
    super.externalId,
    super.qrString,
    super.paidAt,
    super.expiredAt,
    required super.createdAt,
    super.items,
    super.appointment,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'],
      appointmentId: json['appointmentId'],
      amount: double.tryParse(json['amount'].toString()) ?? 0,
      description: json['description']?.toString(),
      paymentMethod: json['paymentMethod']?.toString() ?? 'QRIS',
      status: json['status']?.toString() ?? 'PENDING',
      externalId: json['externalId']?.toString(),
      qrString: json['qrString']?.toString(),
      paidAt: json['paidAt'] != null ? DateTime.tryParse(json['paidAt'].toString()) : null,
      expiredAt: json['expiredAt'] != null ? DateTime.tryParse(json['expiredAt'].toString()) : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      items: (json['items'] as List? ?? [])
          .map((item) => PaymentItemModel.fromJson(item))
          .toList(),
      appointment: json['appointment'] != null 
          ? PaymentAppointmentModel.fromJson(json['appointment']) 
          : null,
    );
  }

  PaymentEntity toEntity() => this;
}

class PaymentAppointmentModel extends PaymentAppointment {
  const PaymentAppointmentModel({
    super.transactionNumber,
    super.serviceName,
    super.servicePrice,
    super.consultationPrice,
    super.transportPrice,
    super.itemsPrice,
    super.discountAmount,
    super.finalPrice,
    super.discountName,
    super.patientName,
  });

  factory PaymentAppointmentModel.fromJson(Map<String, dynamic> json) {
    return PaymentAppointmentModel(
      transactionNumber: json['transactionNumber']?.toString(),
      serviceName: json['serviceName']?.toString(),
      servicePrice: double.tryParse(json['servicePrice']?.toString() ?? ''),
      consultationPrice: double.tryParse(json['consultationPrice']?.toString() ?? ''),
      transportPrice: double.tryParse(json['transportPrice']?.toString() ?? ''),
      itemsPrice: double.tryParse(json['itemsPrice']?.toString() ?? ''),
      discountAmount: double.tryParse(json['discountAmount']?.toString() ?? ''),
      finalPrice: double.tryParse(json['finalPrice']?.toString() ?? ''),
      discountName: json['service']?['discountName']?.toString(),
      patientName: json['patient']?['fullname']?.toString(),
    );
  }
}

class PaymentItemModel extends PaymentItemEntity {
  const PaymentItemModel({
    required super.id,
    required super.name,
    required super.quantity,
    required super.unitPrice,
    required super.totalPrice,
    super.type,
  });

  factory PaymentItemModel.fromJson(Map<String, dynamic> json) {
    return PaymentItemModel(
      id: json['id'],
      name: json['name']?.toString() ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice: double.tryParse(json['unitPrice'].toString()) ?? 0,
      totalPrice: double.tryParse(json['totalPrice'].toString()) ?? 0,
      type: json['type']?.toString(),
    );
  }
}

