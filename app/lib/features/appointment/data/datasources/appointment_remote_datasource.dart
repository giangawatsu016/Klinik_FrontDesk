import '../models/appointment_model.dart';
import '../models/busy_range_model.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';

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
    // MOCK MEDICAL RECORDS
    await Future.delayed(const Duration(milliseconds: 600));
    return {
      'data': [
        {
          'id': 201,
          'date': DateTime.now()
              .subtract(const Duration(days: 2, hours: 4))
              .toIso8601String(),
          'status': 'COMPLETED',
          'serviceName': 'Pemeriksaan Anak',
          'doctorName': 'James Carter',
          'doctorTitlePrefix': 'dr.',
          'doctorTitleSuffix': 'Sp.A',
          'finalPrice': 200000,
          'paymentStatus': 'PAID',
          'transactionNumber': 'TRX-20240101-001',
          'doctor': {
            'name': 'James Carter',
            'specialization': 'Pediatrician',
            'sip': '123/SIP/2023',
          },
          'patientDetail': {'fullname': 'Anak Budi'},
          'clinicalRecord': {
            'diagnoses': [
              {
                'diagnosis': {'description': 'Acute Pharyngitis'},
                'note': 'Sore throat, fever',
              },
            ],
            'medicines': [
              {
                'item': {'name': 'Paracetamol Syrup'},
                'qty': 1,
                'instruction': '3x1 tsp after meal',
              },
            ],
          },
        },
        {
          'id': 202,
          'date': DateTime.now()
              .subtract(const Duration(days: 5))
              .toIso8601String(),
          'status': 'CANCELLED',
          'serviceName': 'Konsultasi Umum',
          'doctorName': 'Sarah Wilson',
          'doctorTitlePrefix': 'dr.',
          'finalPrice': 150000,
          'paymentStatus': 'REFUNDED',
          'transactionNumber': 'TRX-20231228-005',
          'doctor': {
            'name': 'Sarah Wilson',
            'specialization': 'General Practitioner',
          },
          'patientDetail': {'fullname': 'Budi Santoso'},
        },
        {
          'id': 203,
          'date': DateTime.now()
              .subtract(const Duration(days: 10))
              .toIso8601String(),
          'status': 'COMPLETED',
          'serviceName': 'Vaksinasi Flu',
          'doctorName': 'Emily Chen',
          'doctorTitlePrefix': 'dr.',
          'doctorTitleSuffix': 'Sp.KK',
          'finalPrice': 350000,
          'paymentStatus': 'PAID',
          'transactionNumber': 'TRX-20231220-008',
          'doctor': {'name': 'Emily Chen', 'specialization': 'Dermatologist'},
          'patientDetail': {'fullname': 'Siti Aminah'},
          'clinicalRecord': {
            'diagnoses': [
              {
                'diagnosis': {'description': 'Healthy'},
                'note': 'Routine vaccination',
              },
            ],
            'medicines': [],
          },
        },
      ],
      'meta': {'total': 3, 'page': page, 'limit': limit},
    };
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
