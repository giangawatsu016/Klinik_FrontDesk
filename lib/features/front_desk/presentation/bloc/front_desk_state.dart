import 'package:equatable/equatable.dart';
import '../../data/models/patient_model.dart';
import '../../data/models/queue_entry_model.dart';

abstract class FrontDeskState extends Equatable {
  const FrontDeskState();

  @override
  List<Object?> get props => [];
}

class FrontDeskInitial extends FrontDeskState {}

class FrontDeskLoading extends FrontDeskState {}

class FrontDeskLoaded extends FrontDeskState {
  final List<QueueEntryModel> queue;
  const FrontDeskLoaded(this.queue);

  @override
  List<Object?> get props => [queue];
}

class PatientSearchResultState extends FrontDeskState {
  final PatientModel? patient;
  const PatientSearchResultState(this.patient);

  @override
  List<Object?> get props => [patient];
}

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
