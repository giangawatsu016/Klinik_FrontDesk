import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/appointment_repository.dart';

class SimulatePaymentUseCase {
  final AppointmentRepository repository;

  SimulatePaymentUseCase(this.repository);

  Future<Either<Failure, void>> execute(String appointmentId) async {
    return await repository.simulatePayment(appointmentId);
  }
}
