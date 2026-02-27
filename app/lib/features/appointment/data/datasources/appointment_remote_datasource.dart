import '../models/appointment_model.dart';
import '../models/busy_range_model.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';

/// Thrown when the API cannot find a patient during appointment creation.
/// The UI should catch this and redirect the user to patient registration.
class PatientNotFoundException implements Exception {
  final String message;
  final String searchQuery;
  PatientNotFoundException(this.message, {this.searchQuery = ''});
  @override
  String toString() => message;
}

abstract class AppointmentRemoteDataSource {
  Future<List<DoctorModel>> getDoctors();
  Future<List<BusyRangeModel>> getAvailability(int doctorId, String date);
  Future<AppointmentModel> createAppointment(AppointmentModel appointment);
  Future<List<AppointmentModel>> getAppointments();
  Future<Map<String, dynamic>> getMedicalRecords(
    int page,
    int limit,
    String? search,
  );
  Future<String> createInvoice(String appointmentId);
  Future<void> simulatePayment(String appointmentId);
  Future<void> cancelAppointment(String appointmentId);
}

class AppointmentRemoteDataSourceImpl implements AppointmentRemoteDataSource {
  final DioClient client;

  AppointmentRemoteDataSourceImpl({required this.client});

  @override
  Future<List<DoctorModel>> getDoctors() async {
    // MOCK DOCTORS
    await Future.delayed(const Duration(milliseconds: 500));
    return const [
      DoctorModel(
        id: 1,
        name: 'Sarah Wilson',
        specialization: 'General Practitioner',
        titlePrefix: 'dr.',
        photoProfile: 'https://i.pravatar.cc/300?img=1',
        latitude: -6.175110,
        longitude: 106.865036,
      ),
      DoctorModel(
        id: 2,
        name: 'James Carter',
        specialization: 'Pediatrician',
        titlePrefix: 'dr.',
        titleSuffix: 'Sp.A',
        photoProfile: 'https://i.pravatar.cc/300?img=2',
        latitude: -6.175110,
        longitude: 106.865036,
      ),
      DoctorModel(
        id: 3,
        name: 'Emily Chen',
        specialization: 'Dermatologist',
        titlePrefix: 'dr.',
        titleSuffix: 'Sp.KK',
        photoProfile: 'https://i.pravatar.cc/300?img=3',
        latitude: -6.175110,
        longitude: 106.865036,
      ),
    ];
  }

  @override
  Future<List<BusyRangeModel>> getAvailability(
    int doctorId,
    String date,
  ) async {
    // MOCK AVAILABILITY
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      BusyRangeModel(start: '12:00', duration: 60), // Lunch break
    ];
  }

  @override
  Future<AppointmentModel> createAppointment(
    AppointmentModel appointment,
  ) async {
    final response = await client.dio.post(
      ApiEndpoints.createAppointment,
      data: {'data': appointment.toJson()},
    );

    final message = response.data['message'];
    if (message != null) {
      // Check for patient_not_found FIRST (before nested extraction)
      if (message is Map && message['patient_not_found'] == true) {
        throw PatientNotFoundException(
          message['error_message']?.toString() ??
              'Pasien tidak ditemukan. Silakan registrasi terlebih dahulu.',
          searchQuery: message['search_query']?.toString() ?? '',
        );
      }

      // Handle both direct dict and nested {"message": dict} formats
      final data = message is Map && message.containsKey('message')
          ? message['message']
          : message;
      if (data is Map) {
        return AppointmentModel.fromJson(Map<String, dynamic>.from(data));
      }
    }
    throw Exception('Failed to create appointment');
  }

  @override
  Future<List<AppointmentModel>> getAppointments() async {
    try {
      final response = await client.dio.get(ApiEndpoints.getAppointments);
      final List message = response.data['message'] ?? [];
      return message.map((json) {
        try {
          return AppointmentModel.fromJson(json);
        } catch (e) {
          debugPrint('Error parsing appointment: $e, data: $json');
          rethrow;
        }
      }).toList();
    } catch (e) {
      debugPrint('Error fetching appointments: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getMedicalRecords(
    int page,
    int limit,
    String? search,
  ) async {
    try {
      final Map<String, dynamic> queryParams = {
        'limit': limit,
        'offset': (page - 1) * limit,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['patient'] = search; // Search by exact patient ID for now
      }

      final response = await client.dio.get(
        ApiEndpoints.getMedicalRecords,
        queryParameters: queryParams,
      );

      final List dataList = response.data['data'] ?? [];
      final List<Map<String, dynamic>> finalData = dataList.map((item) {
        return Map<String, dynamic>.from(item);
      }).toList();

      return {'data': finalData};
    } catch (e) {
      debugPrint('Error fetching medical records: $e');
      rethrow;
    }
  }

  @override
  Future<String> createInvoice(String appointmentId) async {
    final response = await client.dio.post(
      ApiEndpoints.createInvoice,
      data: {'appointment_id': appointmentId},
    );
    return response.data['message']?['invoice_url']?.toString() ??
        'https://example.com/invoice/$appointmentId';
  }

  @override
  Future<void> simulatePayment(String appointmentId) async {
    await client.dio.post(
      ApiEndpoints.simulatePayment,
      data: {'appointment_id': appointmentId},
    );
  }

  @override
  Future<void> cancelAppointment(String appointmentId) async {
    await client.dio.post(
      ApiEndpoints.cancelAppointment,
      data: {'appointment_id': appointmentId},
    );
  }
}
