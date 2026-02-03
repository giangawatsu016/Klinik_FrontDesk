import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/front_desk_repository.dart';

import '../../data/models/queue_entry_model.dart';
import 'front_desk_event.dart';
import 'front_desk_state.dart';

class FrontDeskBloc extends Bloc<FrontDeskEvent, FrontDeskState> {
  final FrontDeskRepository repository;

  FrontDeskBloc({required this.repository}) : super(FrontDeskInitial()) {
    on<RegisterPatientEvent>(_onRegisterPatient);
    on<SearchPatientEvent>(_onSearchPatient);
    on<AddToQueueEvent>(_onAddToQueue);
    on<LoadQueueEvent>(_onLoadQueue);
    on<UpdateQueueStatusEvent>(_onUpdateQueueStatus);
    on<RegisterAndAddQueueEvent>(_onRegisterAndAddQueue);
  }

  Future<void> _onRegisterAndAddQueue(
    RegisterAndAddQueueEvent event,
    Emitter<FrontDeskState> emit,
  ) async {
    emit(FrontDeskLoading());
    // 1. Register Patient
    final registerResult = await repository.registerPatient(event.patient);

    await registerResult.fold(
      (failure) async => emit(FrontDeskError(failure.message)),
      (patient) async {
        // 2. Add to Queue
        final queueEntry = QueueEntryModel(
          patientName: "${patient.firstName} ${patient.lastName ?? ''}".trim(),
          patient: patient.name ?? '', // name is the ID in Frappe
          status: 'Waiting',
          queueType: event.queueType,
          isPriority: event.isPriority ? 1 : 0,
          practitioner: event.queueType == 'Doctor' ? 'TBD' : null,
          polyclinic: event.queueType == 'Polyclinic' ? 'General' : null,
        );

        final queueResult = await repository.addToQueue(queueEntry);
        queueResult.fold((failure) => emit(FrontDeskError(failure.message)), (
          entry,
        ) {
          emit(
            const FrontDeskSuccess(
              'Registered and added to queue successfully',
            ),
          );
          // Reload queue to show new entry
          add(LoadQueueEvent());
        });
      },
    );
  }

  Future<void> _onRegisterPatient(
    RegisterPatientEvent event,
    Emitter<FrontDeskState> emit,
  ) async {
    emit(FrontDeskLoading());
    final result = await repository.registerPatient(event.patient);
    result.fold(
      (failure) => emit(FrontDeskError(failure.message)),
      (patient) =>
          emit(const FrontDeskSuccess('Patient registered successfully')),
    );
  }

  Future<void> _onSearchPatient(
    SearchPatientEvent event,
    Emitter<FrontDeskState> emit,
  ) async {
    emit(FrontDeskLoading());
    final result = await repository.searchPatient(event.query);
    result.fold(
      (failure) => emit(FrontDeskError(failure.message)),
      (patient) => emit(PatientSearchResultState(patient)),
    );
  }

  Future<void> _onAddToQueue(
    AddToQueueEvent event,
    Emitter<FrontDeskState> emit,
  ) async {
    emit(FrontDeskLoading());
    final result = await repository.addToQueue(event.entry);
    result.fold((failure) => emit(FrontDeskError(failure.message)), (entry) {
      emit(const FrontDeskSuccess('Added to queue successfully'));
      // Reload queue to show new entry
      add(LoadQueueEvent());
    });
  }

  Future<void> _onLoadQueue(
    LoadQueueEvent event,
    Emitter<FrontDeskState> emit,
  ) async {
    emit(FrontDeskLoading());
    final result = await repository.getQueue();
    result.fold(
      (failure) => emit(FrontDeskError(failure.message)),
      (queue) => emit(FrontDeskLoaded(queue)),
    );
  }

  Future<void> _onUpdateQueueStatus(
    UpdateQueueStatusEvent event,
    Emitter<FrontDeskState> emit,
  ) async {
    emit(FrontDeskLoading());
    final result = await repository.updateQueueStatus(event.name, event.status);
    result.fold((failure) => emit(FrontDeskError(failure.message)), (entry) {
      add(LoadQueueEvent()); // Reload queue after update
    });
  }
}
