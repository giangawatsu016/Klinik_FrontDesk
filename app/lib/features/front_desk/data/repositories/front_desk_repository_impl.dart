import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/front_desk_repository.dart';
import '../datasources/front_desk_remote_data_source.dart';
import '../models/patient_model.dart';
import '../models/queue_entry_model.dart';
import '../models/practitioner_model.dart';
import '../models/polyclinic_model.dart';
import '../models/issuer_model.dart';

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
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response?.data['detail'] ?? e.response?.data['message'])
          : null;
      return Left(
        ServerFailure(message?.toString() ?? e.message ?? 'Unknown error'),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PatientModel>>> searchPatient(
    String query,
  ) async {
    try {
      final patients = await remoteDataSource.searchPatient(query);
      return Right(patients);
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response?.data['detail'] ?? e.response?.data['message'])
          : null;
      return Left(
        ServerFailure(message?.toString() ?? e.message ?? 'Unknown error'),
      );
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
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response?.data['detail'] ?? e.response?.data['message'])
          : null;
      return Left(
        ServerFailure(message?.toString() ?? e.message ?? 'Unknown error'),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getQueue() async {
    try {
      final result = await remoteDataSource.getQueue();
      return Right(result);
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response?.data['detail'] ?? e.response?.data['message'])
          : null;
      return Left(
        ServerFailure(message?.toString() ?? e.message ?? 'Unknown error'),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getQueueHistory({
    int page = 0,
    int pageSize = 5,
  }) async {
    try {
      final result = await remoteDataSource.getQueueHistory(
        page: page,
        pageSize: pageSize,
      );
      return Right(result);
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
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response?.data['detail'] ?? e.response?.data['message'])
          : null;
      return Left(
        ServerFailure(message?.toString() ?? e.message ?? 'Unknown error'),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PractitionerModel>>> getPractitioners() async {
    try {
      final practitioners = await remoteDataSource.getPractitioners();
      return Right(practitioners);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PolyclinicModel>>> getPolyclinics() async {
    try {
      final polyclinics = await remoteDataSource.getPolyclinics();
      return Right(polyclinics);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<IssuerModel>>> getIssuers() async {
    try {
      final issuers = await remoteDataSource.getIssuers();
      return Right(issuers);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
