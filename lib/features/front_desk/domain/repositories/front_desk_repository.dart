import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/patient_model.dart';
import '../../data/models/queue_entry_model.dart';

abstract class FrontDeskRepository {
  Future<Either<Failure, PatientModel>> registerPatient(PatientModel patient);
  Future<Either<Failure, PatientModel?>> searchPatient(String query);
  Future<Either<Failure, QueueEntryModel>> addToQueue(QueueEntryModel entry);
  Future<Either<Failure, List<QueueEntryModel>>> getQueue();
  Future<Either<Failure, QueueEntryModel>> updateQueueStatus(
    String name,
    String status,
  );
}

// Note: Implementation will be added in repositories/front_desk_repository_impl.dart
