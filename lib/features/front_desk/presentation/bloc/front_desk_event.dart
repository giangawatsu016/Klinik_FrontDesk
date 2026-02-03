import 'package:equatable/equatable.dart';
import '../../data/models/patient_model.dart';
import '../../data/models/queue_entry_model.dart';

abstract class FrontDeskEvent extends Equatable {
  const FrontDeskEvent();

  @override
  List<Object?> get props => [];
}

class RegisterPatientEvent extends FrontDeskEvent {
  final PatientModel patient;
  const RegisterPatientEvent(this.patient);
}

class SearchPatientEvent extends FrontDeskEvent {
  final String query;
  const SearchPatientEvent(this.query);
}

class AddToQueueEvent extends FrontDeskEvent {
  final QueueEntryModel entry;
  const AddToQueueEvent(this.entry);
}

class LoadQueueEvent extends FrontDeskEvent {}

class UpdateQueueStatusEvent extends FrontDeskEvent {
  final String name;
  final String status;
  const UpdateQueueStatusEvent(this.name, this.status);
}

class RegisterAndAddQueueEvent extends FrontDeskEvent {
  final PatientModel patient;
  final String queueType;
  final bool isPriority;

  const RegisterAndAddQueueEvent({
    required this.patient,
    required this.queueType,
    required this.isPriority,
  });

  @override
  List<Object?> get props => [patient, queueType, isPriority];
}
