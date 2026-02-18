import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/appointment_repository.dart';
import '../entities/appointment_entity.dart';

class CreateAppointmentUseCase {
  final AppointmentRepository repository;

  CreateAppointmentUseCase(this.repository);

  Future<Either<Failure, AppointmentEntity>> execute(AppointmentEntity appointment) {
    return repository.createAppointment(appointment);
  }
}
