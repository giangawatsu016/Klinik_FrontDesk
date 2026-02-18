import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/appointment_repository.dart';

class CreateInvoiceUseCase {
  final AppointmentRepository repository;

  CreateInvoiceUseCase(this.repository);

  Future<Either<Failure, String>> execute(String appointmentId) {
    return repository.createInvoice(appointmentId);
  }
}
