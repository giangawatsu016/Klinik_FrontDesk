import '../../domain/entities/busy_range_entity.dart';

class BusyRangeModel extends BusyRangeEntity {
  const BusyRangeModel({required super.start, required super.duration});

  factory BusyRangeModel.fromJson(Map<String, dynamic> json) {
    return BusyRangeModel(
      start: json['start'].toString(),
      duration: json['duration'] is int ? json['duration'] : int.parse(json['duration'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'duration': duration,
    };
  }
}
