import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../domain/repositories/appointment_repository.dart';
import 'package:stream_transform/stream_transform.dart';

// EVENTS
abstract class MedicalRecordEvent extends Equatable {
  const MedicalRecordEvent();
  @override
  List<Object> get props => [];
}

class GetMedicalRecordsRequested extends MedicalRecordEvent {}

class LoadMoreMedicalRecords extends MedicalRecordEvent {}

class SearchMedicalRecords extends MedicalRecordEvent {
  final String query;
  const SearchMedicalRecords(this.query);
  @override
  List<Object> get props => [query];
}

class RefreshMedicalRecords extends MedicalRecordEvent {}

// STATES
abstract class MedicalRecordState extends Equatable {
  const MedicalRecordState();
  @override
  List<Object> get props => [];
}

class MedicalRecordInitial extends MedicalRecordState {}

class MedicalRecordLoading extends MedicalRecordState {}

class MedicalRecordLoaded extends MedicalRecordState {
  final List<AppointmentEntity> medicalRecords;
  final bool hasReachedMax;
  final int page;
  final String search;

  const MedicalRecordLoaded({
    this.medicalRecords = const [],
    this.hasReachedMax = false,
    this.page = 1,
    this.search = '',
  });

  MedicalRecordLoaded copyWith({
    List<AppointmentEntity>? medicalRecords,
    bool? hasReachedMax,
    int? page,
    String? search,
  }) {
    return MedicalRecordLoaded(
      medicalRecords: medicalRecords ?? this.medicalRecords,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      page: page ?? this.page,
      search: search ?? this.search,
    );
  }

  @override
  List<Object> get props => [medicalRecords, hasReachedMax, page, search];
}

class MedicalRecordError extends MedicalRecordState {
  final String message;
  const MedicalRecordError(this.message);
  @override
  List<Object> get props => [message];
}

// BLOC
const _debounceDuration = Duration(milliseconds: 500);

EventTransformer<E> debounce<E>(Duration duration) {
  return (events, mapper) {
    return events.debounce(duration).switchMap(mapper);
  };
}

class MedicalRecordBloc extends Bloc<MedicalRecordEvent, MedicalRecordState> {
  final AppointmentRepository repository;

  MedicalRecordBloc({required this.repository}) : super(MedicalRecordInitial()) {
    on<GetMedicalRecordsRequested>(_onGetMedicalRecords);
    on<LoadMoreMedicalRecords>(_onLoadMoreMedicalRecords);
    on<SearchMedicalRecords>(_onSearchMedicalRecords, transformer: debounce(_debounceDuration));
    on<RefreshMedicalRecords>(_onRefreshMedicalRecords);
  }

  Future<void> _onGetMedicalRecords(GetMedicalRecordsRequested event, Emitter<MedicalRecordState> emit) async {
    emit(MedicalRecordLoading());
    final result = await repository.getMedicalRecords(page: 1, limit: 10);
    result.fold(
      (failure) => emit(MedicalRecordError(failure.message)),
      (data) {
        final List<AppointmentEntity> records = (data['data'] as List).cast<AppointmentEntity>();
        final meta = data['meta'];
        final total = meta['total'] as int;
        final hasReachedMax = records.length >= total;
        emit(MedicalRecordLoaded(medicalRecords: records, hasReachedMax: hasReachedMax, page: 1));
      },
    );
  }

  Future<void> _onSearchMedicalRecords(SearchMedicalRecords event, Emitter<MedicalRecordState> emit) async {
    emit(MedicalRecordLoading()); 
    final result = await repository.getMedicalRecords(page: 1, limit: 10, search: event.query);
    result.fold(
      (failure) => emit(MedicalRecordError(failure.message)),
      (data) {
        final List<AppointmentEntity> records = (data['data'] as List).cast<AppointmentEntity>();
        final meta = data['meta'];
        final total = meta['total'] as int;
        final hasReachedMax = records.length >= total;
        emit(MedicalRecordLoaded(medicalRecords: records, hasReachedMax: hasReachedMax, page: 1, search: event.query));
      },
    );
  }

  Future<void> _onLoadMoreMedicalRecords(LoadMoreMedicalRecords event, Emitter<MedicalRecordState> emit) async {
    if (state is MedicalRecordLoaded) {
      final currentState = state as MedicalRecordLoaded;
      if (currentState.hasReachedMax) return;

      final nextPage = currentState.page + 1;
      final result = await repository.getMedicalRecords(page: nextPage, limit: 10, search: currentState.search);
      
      result.fold(
        (failure) => emit(MedicalRecordError(failure.message)),
        (data) {
          final List<AppointmentEntity> newRecords = (data['data'] as List).cast<AppointmentEntity>();
          final meta = data['meta'];
          final total = meta['total'] as int;
          
          final allRecords = List<AppointmentEntity>.from(currentState.medicalRecords)..addAll(newRecords);
          final hasReachedMax = allRecords.length >= total;
          
          emit(currentState.copyWith(
            medicalRecords: allRecords,
            hasReachedMax: hasReachedMax,
            page: nextPage
          ));
        },
      );
    }
  }

   Future<void> _onRefreshMedicalRecords(RefreshMedicalRecords event, Emitter<MedicalRecordState> emit) async {
      final currentSearch = state is MedicalRecordLoaded ? (state as MedicalRecordLoaded).search : '';
      emit(MedicalRecordLoading());
      final result = await repository.getMedicalRecords(page: 1, limit: 10, search: currentSearch);
      result.fold(
      (failure) => emit(MedicalRecordError(failure.message)),
      (data) {
        final List<AppointmentEntity> records = (data['data'] as List).cast<AppointmentEntity>();
        final meta = data['meta'];
        final total = meta['total'] as int;
        final hasReachedMax = records.length >= total;
        emit(MedicalRecordLoaded(medicalRecords: records, hasReachedMax: hasReachedMax, page: 1, search: currentSearch));
      },
    );
   }
}
