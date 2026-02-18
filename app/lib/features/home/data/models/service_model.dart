import 'dart:convert';
import '../../domain/entities/service_entity.dart';

class ServiceModel extends ServiceEntity {
  const ServiceModel({
    required super.id,
    required super.name,
    super.description,
    super.category,
    required super.details,
    super.finalPrice,
    super.originalPrice,
    super.discount,
    super.discountName,
    super.discountType,
    super.discountValue,
    super.discountUntil,
    super.isDiscountExpired = false,
    super.posterImages = const [],
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final List<String> posterImages = [];
    final rawPosterImages = json['posterImages'];
    
    if (rawPosterImages != null) {
      if (rawPosterImages is List) {
        posterImages.addAll(rawPosterImages.map((e) => e.toString()));
      } else if (rawPosterImages is String) {
        String cleaned = rawPosterImages.trim();
        if (cleaned.startsWith('[')) {
          try {
            final List<dynamic> urls = jsonDecode(cleaned);
            posterImages.addAll(urls.map((e) => e.toString()));
          } catch (_) {}
        } else {
          posterImages.add(cleaned);
        }
      }
    }

    return ServiceModel(
      id: json['id'],
      name: json['name'].toString(),
      description: json['description']?.toString(),
      category: json['category']?.toString(),
      finalPrice: json['finalPrice'] != null 
          ? double.tryParse(json['finalPrice'].toString()) 
          : null,
      originalPrice: json['originalPrice'] != null 
          ? double.tryParse(json['originalPrice'].toString()) 
          : null,
      discount: json['discount'] != null && json['discount'] != 'null'
          ? double.tryParse(json['discount'].toString()) 
          : null,
      discountName: json['discountName']?.toString(),
      discountType: json['discountType']?.toString(),
      discountValue: json['discountValue'] != null 
          ? double.tryParse(json['discountValue'].toString())
          : null,
      discountUntil: json['discountUntil'] != null
          ? DateTime.tryParse(json['discountUntil'].toString())
          : null,
      isDiscountExpired: json['isDiscountExpired'] == true,
      posterImages: posterImages,
      details: (json['details'] as List? ?? [])
          .map((d) => ServiceDetailModel.fromJson(d))
          .toList(),
    );
  }
}

class ServiceDetailModel extends ServiceDetailEntity {
  const ServiceDetailModel({
    required super.id,
    required super.title,
    required super.content,
  });

  factory ServiceDetailModel.fromJson(Map<String, dynamic> json) {
    return ServiceDetailModel(
      id: json['id'],
      title: json['title'].toString(),
      content: json['content'].toString(),
    );
  }
}
