import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../domain/entities/doctor_entity.dart';
import '../../domain/usecases/create_appointment_usecase.dart';
import '../../domain/usecases/get_doctors_usecase.dart';
import '../../domain/usecases/get_appointments_usecase.dart';
import '../../domain/usecases/create_invoice_usecase.dart';
import '../../domain/usecases/get_availability_usecase.dart';
import '../../domain/usecases/simulate_payment_usecase.dart';
import '../../domain/entities/busy_range_entity.dart';

// Events
abstract class AppointmentEvent extends Equatable {
  const AppointmentEvent();
  @override
  List<Object> get props => [];
}

class GetDoctorsRequested extends AppointmentEvent {}

class CreateAppointmentRequested extends AppointmentEvent {
  final AppointmentEntity appointment;
  const CreateAppointmentRequested(this.appointment);
  @override
  List<Object> get props => [appointment];
}

class GetAppointmentsRequested extends AppointmentEvent {}

class CreateInvoiceRequested extends AppointmentEvent {
  final String appointmentId;
  const CreateInvoiceRequested(this.appointmentId);
  @override
  List<Object> get props => [appointmentId];
}

class SimulatePaymentRequested extends AppointmentEvent {
  final int appointmentId;
  const SimulatePaymentRequested(this.appointmentId);
  @override
  List<Object> get props => [appointmentId];
}

class GetAvailabilityRequested extends AppointmentEvent {
  final int doctorId;
  final String date;
  const GetAvailabilityRequested(this.doctorId, this.date);
  @override
  List<Object> get props => [doctorId, date];
}

// States
abstract class AppointmentState extends Equatable {
  const AppointmentState();
  @override
  List<Object> get props => [];
}

class AppointmentInitial extends AppointmentState {}
class AppointmentLoading extends AppointmentState {}
class DoctorsLoaded extends AppointmentState {
  final List<DoctorEntity> doctors;
  const DoctorsLoaded(this.doctors);
  @override
  List<Object> get props => [doctors];
}
class AvailabilityLoaded extends AppointmentState {
  final List<BusyRangeEntity> busyRanges;
  const AvailabilityLoaded(this.busyRanges);
  @override
  List<Object> get props => [busyRanges];
}
class AppointmentSuccess extends AppointmentState {
  final AppointmentEntity appointment;
  const AppointmentSuccess(this.appointment);
  @override
  List<Object> get props => [appointment];
}
class AppointmentsLoaded extends AppointmentState {
  final List<AppointmentEntity> appointments;
  const AppointmentsLoaded(this.appointments);
  @override
  List<Object> get props => [appointments];
}
class InvoiceCreated extends AppointmentState {
  final String invoiceUrl;
  final String? externalId;
  const InvoiceCreated(this.invoiceUrl, {this.externalId});
  @override
  List<Object> get props => [invoiceUrl, if (externalId != null) externalId!];
}
class AppointmentError extends AppointmentState {
  final String message;
  const AppointmentError(this.message);
  @override
  List<Object> get props => [message];
}

class AppointmentBloc extends Bloc<AppointmentEvent, AppointmentState> {
  final GetDoctorsUseCase getDoctors;
  final GetAvailabilityUseCase getAvailability;
  final CreateAppointmentUseCase createAppointment;
  final GetAppointmentsUseCase getAppointments;
  final CreateInvoiceUseCase createInvoice;
  final SimulatePaymentUseCase simulatePayment;

  AppointmentBloc({
    required this.getDoctors,
    required this.getAvailability,
    required this.createAppointment,
    required this.getAppointments,
    required this.createInvoice, 
    required this.simulatePayment,
  }) : super(AppointmentInitial()) {
    on<GetDoctorsRequested>(_onGetDoctors);
    on<GetAvailabilityRequested>(_onGetAvailability);
    on<CreateAppointmentRequested>(_onCreateAppointment);
    on<GetAppointmentsRequested>(_onGetAppointments);
    on<CreateInvoiceRequested>(_onCreateInvoice);
    on<SimulatePaymentRequested>(_onSimulatePayment);
  }

  Future<void> _onGetDoctors(GetDoctorsRequested event, Emitter<AppointmentState> emit) async {
    emit(AppointmentLoading());
    final result = await getDoctors.execute();
    result.fold(
      (failure) => emit(AppointmentError(failure.message)),
      (doctors) => emit(DoctorsLoaded(doctors)),
    );
  }

  Future<void> _onGetAvailability(GetAvailabilityRequested event, Emitter<AppointmentState> emit) async {
    // Note: We don't emit Loading here to avoid flickering the whole page
    // or we can emit a specialized loading state if needed.
    final result = await getAvailability.execute(event.doctorId, event.date);
    result.fold(
      (failure) => emit(AppointmentError(failure.message)),
      (busyRanges) => emit(AvailabilityLoaded(busyRanges)),
    );
  }

  Future<void> _onCreateAppointment(CreateAppointmentRequested event, Emitter<AppointmentState> emit) async {
    emit(AppointmentLoading());
    final result = await createAppointment.execute(event.appointment);
    result.fold(
      (failure) => emit(AppointmentError(failure.message)),
      (appointment) => emit(AppointmentSuccess(appointment)),
    );
  }

  Future<void> _onGetAppointments(GetAppointmentsRequested event, Emitter<AppointmentState> emit) async {
    emit(AppointmentLoading());
    final result = await getAppointments.execute();
    result.fold(
      (failure) => emit(AppointmentError(failure.message)),
      (appointments) => emit(AppointmentsLoaded(appointments)),
    );
  }

  Future<void> _onCreateInvoice(CreateInvoiceRequested event, Emitter<AppointmentState> emit) async {
    emit(AppointmentLoading());
    final result = await createInvoice.execute(event.appointmentId);
    result.fold(
      (failure) => emit(AppointmentError(failure.message)),
      (url) => emit(InvoiceCreated(url)),
    );
  }

  Future<void> _onSimulatePayment(SimulatePaymentRequested event, Emitter<AppointmentState> emit) async {
    final result = await simulatePayment.execute(event.appointmentId);
    result.fold(
      (failure) => emit(AppointmentError(failure.message)),
      (_) { 
        // Trigger refresh
        add(GetAppointmentsRequested());
      },
    );
  }
}
