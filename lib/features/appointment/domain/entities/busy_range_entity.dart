import 'package:equatable/equatable.dart';

class BusyRangeEntity extends Equatable {
  final String start;
  final int duration;

  const BusyRangeEntity({required this.start, required this.duration});

  @override
  List<Object?> get props => [start, duration];
}
