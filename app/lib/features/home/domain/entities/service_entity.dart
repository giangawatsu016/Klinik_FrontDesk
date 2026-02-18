import 'package:equatable/equatable.dart';

class ServiceEntity extends Equatable {
  final int id;
  final String name;
  final String? description;
  final List<String> posterImages;
  final String? category;
  final double? finalPrice;
  final double? originalPrice;
  final double? discount;
  final String? discountName;
  final String? discountType;
  final double? discountValue;
  final DateTime? discountUntil;
  final bool isDiscountExpired;
  final List<ServiceDetailEntity> details;

  const ServiceEntity({
    required this.id,
    required this.name,
    this.description,
    this.posterImages = const [],
    this.category,
    this.finalPrice,
    this.originalPrice,
    this.discount,
    this.discountName,
    this.discountType,
    this.discountValue,
    this.discountUntil,
    this.isDiscountExpired = false,
    required this.details,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        posterImages,
        category,
        finalPrice,
        originalPrice,
        discount,
        discountName,
        discountType,
        discountValue,
        discountUntil,
        isDiscountExpired,
        details
      ];
}

class ServiceDetailEntity extends Equatable {
  final int id;
  final String title;
  final String content;

  const ServiceDetailEntity({
    required this.id,
    required this.title,
    required this.content,
  });

  @override
  List<Object?> get props => [id, title, content];
}
