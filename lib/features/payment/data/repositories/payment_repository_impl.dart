import '../datasources/payment_remote_datasource.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../domain/entities/payment_entity.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;

  PaymentRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<PaymentEntity>> getAllPayments({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    return await remoteDataSource.getAllPayments(
      status: status,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<List<PaymentEntity>> getPaymentHistory(int appointmentId) async {
    return await remoteDataSource.getPaymentHistory(appointmentId);
  }
}
