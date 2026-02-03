import '../entities/payment_entity.dart';

abstract class PaymentRepository {
  Future<List<PaymentEntity>> getAllPayments({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  });
  Future<List<PaymentEntity>> getPaymentHistory(int appointmentId);
}
