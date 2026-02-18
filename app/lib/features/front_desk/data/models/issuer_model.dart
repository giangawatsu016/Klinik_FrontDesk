import 'package:equatable/equatable.dart';

class IssuerModel extends Equatable {
  final String id;
  final String name;
  final String? category;

  const IssuerModel({required this.id, required this.name, this.category});

  factory IssuerModel.fromJson(Map<String, dynamic> json) {
    return IssuerModel(
      id: (json['issuer_id'] ?? json['id'] ?? '').toString(),
      name: json['issuer_name'] ?? json['name'] ?? '',
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'category': category};
  }

  @override
  List<Object?> get props => [id, name, category];
}
