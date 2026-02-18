import 'package:equatable/equatable.dart';
import '../../data/models/patient_model.dart';
import '../../data/models/queue_entry_model.dart';
import '../../data/models/practitioner_model.dart';
import '../../data/models/polyclinic_model.dart';
import '../../data/models/issuer_model.dart';

abstract class FrontDeskState extends Equatable {
  const FrontDeskState();

  @override
  List<Object?> get props => [];
}

class FrontDeskInitial extends FrontDeskState {}

class FrontDeskLoading extends FrontDeskState {}

class FrontDeskSuccess extends FrontDeskState {
  final String message;
  const FrontDeskSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class FrontDeskError extends FrontDeskState {
  final String message;
  const FrontDeskError(this.message);

  @override
  List<Object?> get props => [message];
}

class FrontDeskLoaded extends FrontDeskState {
  final List<QueueEntryModel> activeQueue;
  final int todayCompleted;
  final List<QueueEntryModel> historyEntries;
  final int historyTotal;
  final int historyPage;

  const FrontDeskLoaded({
    required this.activeQueue,
    this.todayCompleted = 0,
    this.historyEntries = const [],
    this.historyTotal = 0,
    this.historyPage = 0,
  });

  @override
  List<Object?> get props => [
    activeQueue,
    todayCompleted,
    historyEntries,
    historyTotal,
    historyPage,
  ];

  FrontDeskLoaded copyWith({
    List<QueueEntryModel>? activeQueue,
    int? todayCompleted,
    List<QueueEntryModel>? historyEntries,
    int? historyTotal,
    int? historyPage,
  }) {
    return FrontDeskLoaded(
      activeQueue: activeQueue ?? this.activeQueue,
      todayCompleted: todayCompleted ?? this.todayCompleted,
      historyEntries: historyEntries ?? this.historyEntries,
      historyTotal: historyTotal ?? this.historyTotal,
      historyPage: historyPage ?? this.historyPage,
    );
  }
}

class PatientSearchResultState extends FrontDeskState {
  final List<PatientModel> patients;
  const PatientSearchResultState(this.patients);

  @override
  List<Object?> get props => [patients];
}

class PractitionersAndPolyclinicsLoaded extends FrontDeskState {
  final List<PractitionerModel> practitioners;
  final List<PolyclinicModel> polyclinics;

  const PractitionersAndPolyclinicsLoaded({
    required this.practitioners,
    required this.polyclinics,
  });

  @override
  List<Object?> get props => [practitioners, polyclinics];
}

class IssuersLoaded extends FrontDeskState {
  final List<IssuerModel> issuers;
  const IssuersLoaded(this.issuers);

  @override
  List<Object?> get props => [issuers];
}
