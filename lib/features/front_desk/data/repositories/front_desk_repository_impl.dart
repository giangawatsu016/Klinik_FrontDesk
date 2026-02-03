import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/front_desk_repository.dart';
import '../datasources/front_desk_remote_data_source.dart';
import '../models/patient_model.dart';
import '../models/queue_entry_model.dart';

class FrontDeskRepositoryImpl implements FrontDeskRepository {
  final FrontDeskRemoteDataSource remoteDataSource;

  FrontDeskRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, PatientModel>> registerPatient(
    PatientModel patient,
  ) async {
    try {
      final remotePatient = await remoteDataSource.registerPatient(patient);
      return Right(remotePatient);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PatientModel?>> searchPatient(String query) async {
    try {
      final patient = await remoteDataSource.searchPatient(query);
      return Right(patient);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, QueueEntryModel>> addToQueue(
    QueueEntryModel entry,
  ) async {
    try {
      final remoteEntry = await remoteDataSource.addToQueue(entry);
      return Right(remoteEntry);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<QueueEntryModel>>> getQueue() async {
    try {
      final queue = await remoteDataSource.getQueue();
      return Right(queue);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, QueueEntryModel>> updateQueueStatus(
    String name,
    String status,
  ) async {
    try {
      final updated = await remoteDataSource.updateQueueStatus(name, status);
      return Right(updated);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
