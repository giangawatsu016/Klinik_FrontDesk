class PractitionerModel {
  final String id;
  final String name;
  final String? specialization;

  PractitionerModel({
    required this.id,
    required this.name,
    this.specialization,
  });

  factory PractitionerModel.fromJson(Map<String, dynamic> json) {
    return PractitionerModel(
      // Frappe 'name' is the ID
      id: json['name']?.toString() ?? '',
      // Frappe 'full_name' is the display name
      name: json['full_name']?.toString() ?? json['name']?.toString() ?? '',
      specialization: json['specialization']?.toString(),
      // Add practitioner_role if needed
    );
  }

  @override
  String toString() => name;
}
