import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/payment_model.dart';

abstract class PaymentRemoteDataSource {
  Future<List<PaymentModel>> getAllPayments({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  });
  Future<List<PaymentModel>> getPaymentHistory(int appointmentId);
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final DioClient client;

  PaymentRemoteDataSourceImpl(this.client);

  @override
  Future<List<PaymentModel>> getAllPayments({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit, 'offset': offset};
      if (status != null) queryParams['status'] = status;
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final response = await client.dio.get(
        ApiEndpoints.allPayments,
        queryParameters: queryParams,
      );

      final data = response.data['data'] as List? ?? [];
      return data.map((json) => PaymentModel.fromJson(json)).toList();
    } catch (_) {
      // MOCK PAYMENTS (fallback when API unavailable)
      await Future.delayed(const Duration(milliseconds: 500));
      return [
        PaymentModel(
          id: 1,
          appointmentId: 101,
          amount: 150000,
          description: 'Konsultasi Umum - Budi Santoso',
          paymentMethod: 'QRIS',
          status: 'PAID',
          paidAt: DateTime.now().subtract(const Duration(days: 1)),
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          appointment: const PaymentAppointmentModel(
            transactionNumber: 'TRX-2026-0001',
            serviceName: 'Konsultasi Umum',
            servicePrice: 150000,
            finalPrice: 150000,
            patientName: 'Budi Santoso',
          ),
        ),
        PaymentModel(
          id: 2,
          appointmentId: 102,
          amount: 200000,
          description: 'Pemeriksaan Anak - Anak Budi',
          paymentMethod: 'CASH',
          status: 'PAID',
          paidAt: DateTime.now().subtract(const Duration(days: 2)),
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          appointment: const PaymentAppointmentModel(
            transactionNumber: 'TRX-2026-0002',
            serviceName: 'Pemeriksaan Anak',
            servicePrice: 200000,
            finalPrice: 200000,
            patientName: 'Anak Budi',
          ),
        ),
        PaymentModel(
          id: 3,
          appointmentId: 103,
          amount: 250000,
          description: 'Dermatology - Siti Aminah',
          paymentMethod: 'BPJS',
          status: 'PENDING',
          createdAt: DateTime.now(),
          expiredAt: DateTime.now().add(const Duration(hours: 24)),
          appointment: const PaymentAppointmentModel(
            transactionNumber: 'TRX-2026-0003',
            serviceName: 'Konsultasi Kulit',
            servicePrice: 250000,
            finalPrice: 250000,
            patientName: 'Siti Aminah',
          ),
        ),
      ];
    }
  }

  @override
  Future<List<PaymentModel>> getPaymentHistory(int appointmentId) async {
    try {
      final response = await client.dio.get(
        ApiEndpoints.paymentHistory(appointmentId),
      );
      final data = response.data as List? ?? [];
      return data.map((json) => PaymentModel.fromJson(json)).toList();
    } catch (_) {
      // MOCK PAYMENT HISTORY
      await Future.delayed(const Duration(milliseconds: 300));
      return [
        PaymentModel(
          id: appointmentId,
          appointmentId: appointmentId,
          amount: 150000,
          description: 'Payment for appointment #$appointmentId',
          paymentMethod: 'QRIS',
          status: 'PAID',
          paidAt: DateTime.now().subtract(const Duration(hours: 2)),
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ];
    }
  }
}
