import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/appointment_repository.dart';
import '../entities/doctor_entity.dart';

class GetDoctorsUseCase {
  final AppointmentRepository repository;

  GetDoctorsUseCase(this.repository);

  Future<Either<Failure, List<DoctorEntity>>> execute() {
    return repository.getDoctors();
  }
}
