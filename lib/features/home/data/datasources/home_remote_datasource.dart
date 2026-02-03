import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/service_model.dart';

abstract class HomeRemoteDataSource {
  Future<List<ServiceModel>> getServices();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final DioClient client;

  HomeRemoteDataSourceImpl(this.client);

  @override
  Future<List<ServiceModel>> getServices() async {
    try {
      final response = await client.dio.get(ApiEndpoints.services);
      return (response.data as List)
          .map((s) => ServiceModel.fromJson(s))
          .toList();
    } catch (_) {
      // MOCK SERVICES (fallback when API unavailable)
      await Future.delayed(const Duration(milliseconds: 500));
      return const [
        ServiceModel(
          id: 1,
          name: 'Konsultasi Umum',
          description: 'Konsultasi dokter umum untuk pemeriksaan kesehatan',
          category: 'General',
          finalPrice: 150000,
          originalPrice: 150000,
          details: [
            ServiceDetailModel(id: 1, title: 'Durasi', content: '30 menit'),
            ServiceDetailModel(id: 2, title: 'Lokasi', content: 'Klinik'),
          ],
        ),
        ServiceModel(
          id: 2,
          name: 'Pemeriksaan Anak',
          description: 'Pemeriksaan kesehatan anak oleh dokter spesialis anak',
          category: 'Pediatric',
          finalPrice: 200000,
          originalPrice: 200000,
          details: [
            ServiceDetailModel(id: 1, title: 'Durasi', content: '45 menit'),
            ServiceDetailModel(id: 2, title: 'Usia', content: '0-17 tahun'),
          ],
        ),
        ServiceModel(
          id: 3,
          name: 'Konsultasi Kulit',
          description: 'Konsultasi masalah kulit dengan dokter dermatologi',
          category: 'Dermatology',
          finalPrice: 250000,
          originalPrice: 300000,
          discount: 50000,
          discountName: 'Promo',
          details: [
            ServiceDetailModel(id: 1, title: 'Durasi', content: '30 menit'),
          ],
        ),
        ServiceModel(
          id: 4,
          name: 'Pemeriksaan Gigi',
          description: 'Pemeriksaan dan perawatan gigi',
          category: 'Dental',
          finalPrice: 175000,
          originalPrice: 175000,
          details: [
            ServiceDetailModel(id: 1, title: 'Durasi', content: '45 menit'),
            ServiceDetailModel(
              id: 2,
              title: 'Termasuk',
              content: 'Scaling dasar',
            ),
          ],
        ),
        ServiceModel(
          id: 5,
          name: 'Home Care Visit',
          description: 'Kunjungan dokter ke rumah pasien',
          category: 'Homecare',
          finalPrice: 500000,
          originalPrice: 500000,
          details: [
            ServiceDetailModel(id: 1, title: 'Durasi', content: '60 menit'),
            ServiceDetailModel(
              id: 2,
              title: 'Area',
              content: 'Jakarta & sekitarnya',
            ),
          ],
        ),
      ];
    }
  }
}
