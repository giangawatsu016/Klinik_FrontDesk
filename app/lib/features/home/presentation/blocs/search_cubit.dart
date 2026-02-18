import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/service_entity.dart';
import '../../../appointment/domain/entities/appointment_entity.dart';

// STATES
abstract class SearchState extends Equatable {
  const SearchState();
  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {}

class SearchActive extends SearchState {
  final int tabIndex;
  final String query;
  final List<dynamic> results;
  final bool isLoading;

  const SearchActive({
    required this.tabIndex,
    this.query = '',
    this.results = const [],
    this.isLoading = false,
  });

  @override
  List<Object?> get props => [tabIndex, query, results, isLoading];

  SearchActive copyWith({
    int? tabIndex,
    String? query,
    List<dynamic>? results,
    bool? isLoading,
  }) {
    return SearchActive(
      tabIndex: tabIndex ?? this.tabIndex,
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// CUBIT
class SearchCubit extends Cubit<SearchState> {
  SearchCubit() : super(SearchInitial());

  // Data sources - will be set from HomePage
  List<ServiceEntity> _services = [];
  List<AppointmentEntity> _appointments = [];

  /// Set data sources for search
  void setDataSources({
    List<ServiceEntity>? services,
    List<AppointmentEntity>? appointments,
  }) {
    if (services != null) _services = services;
    if (appointments != null) _appointments = appointments;
  }

  /// Open search for a specific tab
  void openSearch(int tabIndex) {
    emit(SearchActive(tabIndex: tabIndex));
  }

  /// Perform search based on current tab context
  void search(String query) {
    final currentState = state;
    if (currentState is! SearchActive) return;

    final trimmedQuery = query.trim().toLowerCase();

    // If query is empty, we return FULL HISTORY for the relevant tab
    if (trimmedQuery.isEmpty) {
      List<dynamic> history = [];
      switch (currentState.tabIndex) {
        case 2: // Appointments - Show ALL Past Appointments
          history = _appointments.where((appt) {
            return [
              'COMPLETED',
              'CANCELLED',
            ].contains(appt.status.toUpperCase());
          }).toList();
          break;
        case 3: // Medical Records - Let MedicalRecordBloc handle it via SearchPopup if needed
          history = [];
          break;
        case 0: // Services/Home
          history = _services;
          break;
      }
      emit(
        currentState.copyWith(query: '', results: history, isLoading: false),
      );
      return;
    }

    emit(currentState.copyWith(query: query, isLoading: true));

    List<dynamic> results = [];

    switch (currentState.tabIndex) {
      case 0: // Home - Search Services
        results = _services.where((service) {
          return service.name.toLowerCase().contains(trimmedQuery) ||
              (service.description?.toLowerCase().contains(trimmedQuery) ??
                  false);
        }).toList();
        break;

      case 2: // Appointments - Search History ONLY (as requested)
        results = _appointments.where((appt) {
          final isPast = [
            'COMPLETED',
            'CANCELLED',
          ].contains(appt.status.toUpperCase());
          if (!isPast) return false;

          return appt.serviceName.toLowerCase().contains(trimmedQuery) ||
              appt.doctorName.toLowerCase().contains(trimmedQuery) ||
              (appt.transactionNumber?.toLowerCase().contains(trimmedQuery) ??
                  false);
        }).toList();
        break;

      case 3: // Medical Records - Search Results
        // This is usually handled by MedicalRecordBloc in SearchPopup,
        // but adding here for consistency if needed.
        results = [];
        break;

      default:
        results = [];
    }

    emit(
      currentState.copyWith(query: query, results: results, isLoading: false),
    );
  }

  /// Close search and reset state
  void closeSearch() {
    emit(SearchInitial());
  }

  /// Get context label based on tab index
  static String getSearchLabel(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'Search Services';
      case 1:
        return 'Search Schedule';
      case 2:
        return 'Search History';
      default:
        return 'Search';
    }
  }
}
