import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/appointment_repository.dart';
import '../entities/appointment_entity.dart';

class GetAppointmentsUseCase {
  final AppointmentRepository repository;

  GetAppointmentsUseCase(this.repository);

  Future<Either<Failure, List<AppointmentEntity>>> execute() {
    return repository.getAppointments();
  }
}
