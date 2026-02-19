import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/error_formatter.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../domain/entities/doctor_entity.dart';
import '../../domain/entities/busy_range_entity.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../datasources/appointment_remote_datasource.dart';
import '../models/appointment_model.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  final AppointmentRemoteDataSource remoteDataSource;

  AppointmentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<DoctorEntity>>> getDoctors() async {
    try {
      final doctors = await remoteDataSource.getDoctors();
      return Right(doctors);
    } catch (e) {
      return Left(ServerFailure(ErrorFormatter.format(e)));
    }
  }

  @override
  Future<Either<Failure, List<BusyRangeEntity>>> getAvailability(
    int doctorId,
    String date,
  ) async {
    try {
      final availability = await remoteDataSource.getAvailability(
        doctorId,
        date,
      );
      return Right(availability);
    } catch (e) {
      return Left(ServerFailure(ErrorFormatter.format(e)));
    }
  }

  @override
  Future<Either<Failure, AppointmentEntity>> createAppointment(
    AppointmentEntity appointment,
  ) async {
    try {
      final model = AppointmentModel(
        id: appointment.id,
        date: appointment.date,
        status: appointment.status,
        serviceName: appointment.serviceName,
        doctorName: appointment.doctorName,
        finalPrice: appointment.finalPrice,
        serviceId: appointment.serviceId,
        doctorId: appointment.doctorId,
        patientDetail: appointment.patientDetail,
        discountName: appointment.discountName,
        polyclinicId: appointment.polyclinicId,
        polyclinicName: appointment.polyclinicName,
      );

      final createdAppointment = await remoteDataSource.createAppointment(
        model,
      );
      return Right(createdAppointment);
    } catch (e) {
      return Left(ServerFailure(ErrorFormatter.format(e)));
    }
  }

  @override
  Future<Either<Failure, List<AppointmentEntity>>> getAppointments() async {
    try {
      final appointments = await remoteDataSource.getAppointments();
      return Right(appointments);
    } catch (e) {
      return Left(ServerFailure(ErrorFormatter.format(e)));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getMedicalRecords({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    try {
      final result = await remoteDataSource.getMedicalRecords(
        page,
        limit,
        search,
      );

      // Transform data list to Entities
      final List<dynamic> dataList = result['data'] ?? [];
      final appointments = dataList
          .map((json) => AppointmentModel.fromJson(json))
          .toList();

      return Right({'data': appointments, 'meta': result['meta']});
    } catch (e) {
      return Left(ServerFailure(ErrorFormatter.format(e)));
    }
  }

  @override
  Future<Either<Failure, String>> createInvoice(String appointmentId) async {
    try {
      final url = await remoteDataSource.createInvoice(appointmentId);
      return Right(url);
    } catch (e) {
      return Left(ServerFailure(ErrorFormatter.format(e)));
    }
  }

  @override
  Future<Either<Failure, void>> simulatePayment(String appointmentId) async {
    try {
      await remoteDataSource.simulatePayment(appointmentId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(ErrorFormatter.format(e)));
    }
  }

  @override
  Future<Either<Failure, void>> cancelAppointment(String appointmentId) async {
    try {
      await remoteDataSource.cancelAppointment(appointmentId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(ErrorFormatter.format(e)));
    }
  }
}
