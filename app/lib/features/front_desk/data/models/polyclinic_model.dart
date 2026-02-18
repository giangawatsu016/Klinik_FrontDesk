class PolyclinicModel {
  final String id;
  final String name;

  PolyclinicModel({required this.id, required this.name});

  factory PolyclinicModel.fromJson(Map<String, dynamic> json) {
    return PolyclinicModel(
      // Frappe 'name' is the ID
      id: json['name']?.toString() ?? '',
      // Frappe 'polyclinic_name' is the display name
      name:
          json['polyclinic_name']?.toString() ?? json['name']?.toString() ?? '',
    );
  }

  @override
  String toString() => name;
}
