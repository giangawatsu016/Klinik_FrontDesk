import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/busy_range_entity.dart';
import '../repositories/appointment_repository.dart';

class GetAvailabilityUseCase {
  final AppointmentRepository repository;

  GetAvailabilityUseCase({required this.repository});

  Future<Either<Failure, List<BusyRangeEntity>>> execute(int doctorId, String date) {
    return repository.getAvailability(doctorId, date);
  }
}
