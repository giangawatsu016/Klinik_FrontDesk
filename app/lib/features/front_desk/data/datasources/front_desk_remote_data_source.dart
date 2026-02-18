import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/patient_model.dart';
import '../models/queue_entry_model.dart';
import '../models/practitioner_model.dart';
import '../models/polyclinic_model.dart';
import '../models/issuer_model.dart';

abstract class FrontDeskRemoteDataSource {
  Future<PatientModel> registerPatient(PatientModel patient);
  Future<List<PatientModel>> searchPatient(
    String query,
  ); // search by NIK or Phone
  Future<QueueEntryModel> addToQueue(QueueEntryModel entry);
  Future<Map<String, dynamic>> getQueue();
  Future<Map<String, dynamic>> getQueueHistory({
    int page = 0,
    int pageSize = 5,
  });
  Future<QueueEntryModel> updateQueueStatus(String name, String status);
  Future<List<PractitionerModel>> getPractitioners();
  Future<List<PolyclinicModel>> getPolyclinics();
  Future<List<IssuerModel>> getIssuers();
}

class FrontDeskRemoteDataSourceImpl implements FrontDeskRemoteDataSource {
  final DioClient client;

  FrontDeskRemoteDataSourceImpl(this.client);

  Future<String?> _getCompany() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_company');
  }

  Future<String?> _getFacility() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_facility');
  }

  @override
  Future<PatientModel> registerPatient(PatientModel patient) async {
    final company = await _getCompany() ?? 'IMC';
    final updatedPatient = patient.copyWith(company: company);

    try {
      final response = await client.dio.post(
        ApiEndpoints.register,
        data: {'patient_data': updatedPatient.toJson()},
      );

      if (response.data['message'] != null) {
        return PatientModel.fromJson(response.data['message']);
      }
      throw Exception('Failed to register patient: No data returned');
    } catch (e) {
      if (e.toString().contains('demo')) {
        rethrow; // Allow demo logic if implemented elsewhere
      }
      rethrow;
    }
  }

  @override
  Future<List<PatientModel>> searchPatient(String query) async {
    try {
      final response = await client.dio.get(
        ApiEndpoints.searchPatient,
        queryParameters: {'query': query},
      );

      final data = response.data['message'];
      if (data != null) {
        if (data is List) {
          final patients = data
              .map((json) => PatientModel.fromJson(json))
              .toList();
          AppLogger.info('Search found ${patients.length} patients');
          return patients;
        } else if (data is Map<String, dynamic>) {
          AppLogger.info('Search found 1 patient (Map)');
          return [PatientModel.fromJson(data)];
        }
      }
      return [];
    } catch (e) {
      // Return empty list on NOT FOUND or connection errors to allow clean UI handling
      AppLogger.error('Error during patient search', e);
      return [];
    }
  }

  @override
  Future<QueueEntryModel> addToQueue(QueueEntryModel entry) async {
    final company = await _getCompany();
    final facility = await _getFacility();

    // Inject company/facility if missing in model
    final updatedEntry = QueueEntryModel(
      name: entry.name,
      patient: entry.patient,
      patientName: entry.patientName,
      queueNumber: entry.queueNumber,
      isPriority: entry.isPriority,
      queueType: entry.queueType,
      practitioner: entry.practitioner,
      polyclinic: entry.polyclinic,
      appointment: entry.appointment,
      bloodPressure: entry.bloodPressure,
      temperature: entry.temperature,
      weight: entry.weight,
      height: entry.height,
      status: entry.status,
      calledAt: entry.calledAt,
      completedAt: entry.completedAt,
      company: entry.company != 'IMC' ? entry.company : (company ?? 'IMC'),
      facility: entry.facility != 'General'
          ? entry.facility
          : (facility ?? 'General'),
      creation: entry.creation,
    );

    final response = await client.dio.post(
      ApiEndpoints.addToQueue,
      data: {'entry_data': updatedEntry.toJson()},
    );

    if (response.data['message'] != null) {
      return QueueEntryModel.fromJson(response.data['message']);
    }
    throw Exception('Failed to add to queue: No data returned');
  }

  @override
  Future<Map<String, dynamic>> getQueue() async {
    try {
      final response = await client.dio.get(ApiEndpoints.getQueue);
      final rawData = response.data['message'];

      if (rawData is List) {
        return {
          'active': rawData
              .map((json) => QueueEntryModel.fromJson(json))
              .toList(),
          'today_completed': 0,
        };
      }

      final data = rawData as Map<String, dynamic>? ?? {};
      final List activeList = data['active'] ?? [];
      final int todayCompleted = data['today_completed'] ?? 0;

      return {
        'active': activeList
            .map((json) => QueueEntryModel.fromJson(json))
            .toList(),
        'today_completed': todayCompleted,
      };
    } catch (e) {
      return {'active': <QueueEntryModel>[], 'today_completed': 0};
    }
  }

  @override
  Future<Map<String, dynamic>> getQueueHistory({
    int page = 0,
    int pageSize = 5,
  }) async {
    try {
      final response = await client.dio.get(
        ApiEndpoints.getQueueHistory,
        queryParameters: {
          'limit_start': page * pageSize,
          'limit_page_length': pageSize,
        },
      );

      final data = response.data['message'] ?? {};
      final List entries = data['entries'] ?? [];
      return {
        'entries': entries
            .map((json) => QueueEntryModel.fromJson(json))
            .toList(),
        'total': data['total'] ?? 0,
      };
    } catch (e) {
      return {'entries': <QueueEntryModel>[], 'total': 0};
    }
  }

  @override
  Future<QueueEntryModel> updateQueueStatus(String name, String status) async {
    final response = await client.dio.post(
      ApiEndpoints.updateQueueStatus,
      data: {'name': name, 'status': status},
    );

    if (response.data['message'] != null) {
      return QueueEntryModel.fromJson(response.data['message']);
    }
    throw Exception('Failed to update status: No data returned');
  }

  @override
  Future<List<PractitionerModel>> getPractitioners() async {
    final company = await _getCompany() ?? 'IMC';
    final response = await client.dio.get(
      ApiEndpoints.getPractitioners,
      queryParameters: {'company': company},
    );

    final List data = response.data['message'] ?? [];
    return data.map((json) => PractitionerModel.fromJson(json)).toList();
  }

  @override
  Future<List<PolyclinicModel>> getPolyclinics() async {
    final response = await client.dio.get(ApiEndpoints.getPolyclinics);

    final List data = response.data['message'] ?? [];
    return data.map((json) => PolyclinicModel.fromJson(json)).toList();
  }

  @override
  Future<List<IssuerModel>> getIssuers() async {
    final response = await client.dio.get(ApiEndpoints.getIssuers);

    final List data = response.data['message'] ?? [];
    return data.map((json) => IssuerModel.fromJson(json)).toList();
  }
}
