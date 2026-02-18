import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/appointment_repository.dart';

class CancelAppointmentUseCase {
  final AppointmentRepository repository;

  CancelAppointmentUseCase(this.repository);

  Future<Either<Failure, void>> execute(String appointmentId) async {
    return await repository.cancelAppointment(appointmentId);
  }
}
