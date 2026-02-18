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
    on<FetchPractitionersAndPolyclinicsEvent>(
      _onFetchPractitionersAndPolyclinics,
    );
    on<LoadQueueHistoryEvent>(_onLoadQueueHistory);
    on<FetchIssuersEvent>(_onFetchIssuers);
  }

  Future<void> _onFetchIssuers(
    FetchIssuersEvent event,
    Emitter<FrontDeskState> emit,
  ) async {
    emit(FrontDeskLoading());
    final result = await repository.getIssuers();
    result.fold(
      (failure) => emit(FrontDeskError(failure.message)),
      (issuers) => emit(IssuersLoaded(issuers)),
    );
  }

  Future<void> _onRegisterAndAddQueue(
    RegisterAndAddQueueEvent event,
    Emitter<FrontDeskState> emit,
  ) async {
    emit(FrontDeskLoading());
    final registerResult = await repository.registerPatient(event.patient);

    await registerResult.fold(
      (failure) async => emit(FrontDeskError(failure.message)),
      (patient) async {
        final queueEntry = QueueEntryModel(
          patientName: "${patient.firstName} ${patient.lastName ?? ''}".trim(),
          patient: patient.name ?? '',
          status: 'Waiting',
          queueType: event.queueType,
          isPriority: event.isPriority ? 1 : 0,
          practitioner: event.queueType == 'Doctor' ? event.selectedId : null,
          polyclinic: event.queueType == 'Polyclinic' ? event.selectedId : null,
          paymentMethod: event.paymentMethod,
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
      (patients) => emit(PatientSearchResultState(patients)),
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
      add(LoadQueueEvent());
    });
  }

  Future<void> _onLoadQueue(
    LoadQueueEvent event,
    Emitter<FrontDeskState> emit,
  ) async {
    // Preserve history if already loaded
    List<QueueEntryModel> currentHistory = [];
    int currentHistoryTotal = 0;
    int currentHistoryPage = 0;

    if (state is FrontDeskLoaded) {
      final loadedState = state as FrontDeskLoaded;
      currentHistory = loadedState.historyEntries;
      currentHistoryTotal = loadedState.historyTotal;
      currentHistoryPage = loadedState.historyPage;
    } else {
      emit(FrontDeskLoading());
    }

    final result = await repository.getQueue();
    result.fold((failure) => emit(FrontDeskError(failure.message)), (data) {
      emit(
        FrontDeskLoaded(
          activeQueue: List<QueueEntryModel>.from(data['active'] ?? []),
          todayCompleted: data['today_completed'] ?? 0,
          historyEntries: currentHistory,
          historyTotal: currentHistoryTotal,
          historyPage: currentHistoryPage,
        ),
      );
    });
  }

  Future<void> _onUpdateQueueStatus(
    UpdateQueueStatusEvent event,
    Emitter<FrontDeskState> emit,
  ) async {
    // Optimistic update or loading?
    // For now, let's just show loading to be safe, or keep state.
    // Given the UI complexity, showing loading might flicker.
    // But existing implementation shows loading.
    emit(FrontDeskLoading());
    final result = await repository.updateQueueStatus(event.name, event.status);
    result.fold(
      (failure) => emit(FrontDeskError(failure.message)),
      (entry) => add(LoadQueueEvent()),
    );
  }

  Future<void> _onFetchPractitionersAndPolyclinics(
    FetchPractitionersAndPolyclinicsEvent event,
    Emitter<FrontDeskState> emit,
  ) async {
    emit(FrontDeskLoading());
    final practitionersResult = await repository.getPractitioners();
    final polyclinicsResult = await repository.getPolyclinics();

    practitionersResult.fold(
      (failure) => emit(FrontDeskError(failure.message)),
      (practitioners) {
        polyclinicsResult.fold(
          (failure) => emit(FrontDeskError(failure.message)),
          (polyclinics) {
            emit(
              PractitionersAndPolyclinicsLoaded(
                practitioners: practitioners,
                polyclinics: polyclinics,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _onLoadQueueHistory(
    LoadQueueHistoryEvent event,
    Emitter<FrontDeskState> emit,
  ) async {
    List<QueueEntryModel> currentActive = [];
    int currentTodayCompleted = 0;

    if (state is FrontDeskLoaded) {
      final loadedState = state as FrontDeskLoaded;
      currentActive = loadedState.activeQueue;
      currentTodayCompleted = loadedState.todayCompleted;
    } else {
      emit(FrontDeskLoading());
    }

    final result = await repository.getQueueHistory(
      page: event.page,
      pageSize: 5,
    );
    result.fold((failure) => emit(FrontDeskError(failure.message)), (data) {
      final entries = data['entries'] as List<QueueEntryModel>;
      final total = data['total'] as int;

      emit(
        FrontDeskLoaded(
          activeQueue: currentActive,
          todayCompleted: currentTodayCompleted,
          historyEntries: entries,
          historyTotal: total,
          historyPage: event.page,
        ),
      );
    });
  }
}
