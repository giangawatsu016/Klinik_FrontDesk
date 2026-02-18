import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/patient_model.dart';
import '../../data/models/queue_entry_model.dart';
import '../../data/models/practitioner_model.dart';
import '../../data/models/polyclinic_model.dart';
import '../../data/models/issuer_model.dart';

abstract class FrontDeskRepository {
  Future<Either<Failure, PatientModel>> registerPatient(PatientModel patient);
  Future<Either<Failure, List<PatientModel>>> searchPatient(String query);
  Future<Either<Failure, QueueEntryModel>> addToQueue(QueueEntryModel entry);
  Future<Either<Failure, Map<String, dynamic>>> getQueue();
  Future<Either<Failure, Map<String, dynamic>>> getQueueHistory({
    int page,
    int pageSize,
  });
  Future<Either<Failure, QueueEntryModel>> updateQueueStatus(
    String name,
    String status,
  );
  Future<Either<Failure, List<PractitionerModel>>> getPractitioners();
  Future<Either<Failure, List<PolyclinicModel>>> getPolyclinics();
  Future<Either<Failure, List<IssuerModel>>> getIssuers();
}

// Note: Implementation will be added in repositories/front_desk_repository_impl.dart
