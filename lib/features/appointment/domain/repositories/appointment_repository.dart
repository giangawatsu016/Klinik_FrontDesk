import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../domain/entities/doctor_entity.dart';
import '../../domain/entities/busy_range_entity.dart';

abstract class AppointmentRepository {
  Future<Either<Failure, List<DoctorEntity>>> getDoctors();
  
  Future<Either<Failure, Map<String, dynamic>>> getMedicalRecords({int page = 1, int limit = 10, String? search});

  Future<Either<Failure, List<BusyRangeEntity>>> getAvailability(int doctorId, String date);
  Future<Either<Failure, AppointmentEntity>> createAppointment(AppointmentEntity appointment);
  Future<Either<Failure, List<AppointmentEntity>>> getAppointments();
  Future<Either<Failure, String>> createInvoice(String appointmentId);
  Future<Either<Failure, void>> simulatePayment(int appointmentId);
}
