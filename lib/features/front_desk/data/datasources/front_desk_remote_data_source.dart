import '../../../../core/network/dio_client.dart';
import '../models/patient_model.dart';
import '../models/queue_entry_model.dart';

abstract class FrontDeskRemoteDataSource {
  Future<PatientModel> registerPatient(PatientModel patient);
  Future<PatientModel?> searchPatient(String query); // search by NIK or Phone
  Future<QueueEntryModel> addToQueue(QueueEntryModel entry);
  Future<List<QueueEntryModel>> getQueue();
  Future<QueueEntryModel> updateQueueStatus(String name, String status);
}

class FrontDeskRemoteDataSourceImpl implements FrontDeskRemoteDataSource {
  final DioClient client;

  // Track the last date the queue was active (for daily reset)
  static String? _lastActiveDate;

  // In-memory queue storage for demo/mock purposes
  static final List<QueueEntryModel> _mockQueue = [];

  static int _queueCounter = 1;

  FrontDeskRemoteDataSourceImpl(this.client) {
    // Check and reset queue on initialization
    _checkDailyReset();
  }

  /// Get current date in WIB timezone (UTC+7)
  static String _getCurrentDateWIB() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Check if queue should be reset (new day in WIB)
  static void _checkDailyReset() {
    final currentDateWIB = _getCurrentDateWIB();

    if (_lastActiveDate == null || _lastActiveDate != currentDateWIB) {
      // New day - reset the queue
      _mockQueue.clear();
      _queueCounter = 1;
      _lastActiveDate = currentDateWIB;

      // Optional: Add some sample data for today
      _mockQueue.addAll([
        const QueueEntryModel(
          name: 'MOCK-Q-001',
          patient: 'MOCK-PAT-001',
          patientName: 'Siti Aminah',
          queueNumber: 'D-001',
          queueType: 'Doctor',
          status: 'Waiting',
          isPriority: 1,
          practitioner: 'Dr. Andi Wijaya',
        ),
        const QueueEntryModel(
          name: 'MOCK-Q-002',
          patient: 'MOCK-PAT-002',
          patientName: 'Budi Santoso',
          queueNumber: 'D-002',
          queueType: 'Doctor',
          status: 'Called',
          practitioner: 'Dr. Andi Wijaya',
        ),
      ]);
      _queueCounter = 3;
    }
  }

  @override
  Future<PatientModel> registerPatient(PatientModel patient) async {
    // MOCK REGISTER
    await Future.delayed(const Duration(seconds: 1));
    return PatientModel(
      name: 'MOCK-PAT-${DateTime.now().millisecondsSinceEpoch}',
      firstName: patient.firstName,
      lastName: patient.lastName,
      email: patient.email,
      nik: patient.nik,
      phone: patient.phone,
      birthday: patient.birthday,
      gender: patient.gender,
      religion: patient.religion,
      maritalStatus: patient.maritalStatus,
      education: patient.education,
      province: patient.province,
      city: patient.city,
      district: patient.district,
      subdistrict: patient.subdistrict,
      fullAddress: patient.fullAddress,
      company: patient.company,
    );
  }

  @override
  Future<PatientModel?> searchPatient(String query) async {
    // MOCK SEARCH
    if (query == '081234567890' ||
        query == '1234567890123456' ||
        query.toLowerCase() == 'demo') {
      await Future.delayed(const Duration(milliseconds: 500));
      return const PatientModel(
        name: 'MOCK-PAT-EXISTING',
        firstName: 'Budi',
        lastName: 'Santoso',
        email: 'budi@demo.com',
        nik: '1234567890123456',
        phone: '081234567890',
        birthday: '1990-01-01',
        gender: 'Male',
        religion: 'Islam',
        maritalStatus: 'Menikah',
        education: 'S1',
        province: 'Jawa Barat',
        city: 'Bandung',
        district: 'Cicendo',
        subdistrict: 'Pasir Kaliki',
        fullAddress: 'Jl. Pasir Kaliki No. 123',
      );
    }

    // Attempt real search if not demo query, but fallback to null if connection fails
    try {
      final response = await client.dio.get(
        '/method/api_clinic.clinicfrontdesk.api.search_patient',
        queryParameters: {'query': query},
      );

      if (response.data['message'] != null) {
        return PatientModel.fromJson(response.data['message']);
      }
    } catch (e) {
      // Ignore connection error for demo purposes
    }
    return null;
  }

  @override
  Future<QueueEntryModel> addToQueue(QueueEntryModel entry) async {
    // MOCK ADD QUEUE - Add to in-memory storage
    await Future.delayed(const Duration(seconds: 1));

    // Check if patient already has an active queue entry
    final activeStatuses = ['Waiting', 'Called', 'In Consultation'];
    final existingEntry = _mockQueue
        .where(
          (q) =>
              q.patient == entry.patient && activeStatuses.contains(q.status),
        )
        .firstOrNull;

    if (existingEntry != null) {
      throw Exception(
        'Patient already has an active queue (${existingEntry.queueNumber}). '
        'Please wait until the current visit is completed.',
      );
    }

    final prefix = entry.queueType == 'Doctor' ? 'A' : 'B';
    final newEntry = QueueEntryModel(
      name: 'MOCK-Q-${DateTime.now().millisecondsSinceEpoch}',
      patient: entry.patient,
      patientName: entry.patientName,
      queueNumber: '$prefix-00$_queueCounter',
      isPriority: entry.isPriority,
      queueType: entry.queueType,
      status: 'Waiting',
      practitioner: entry.practitioner,
      polyclinic: entry.polyclinic,
      company: entry.company,
      facility: entry.facility,
    );

    _queueCounter++;
    _mockQueue.add(newEntry);

    return newEntry;
  }

  @override
  Future<List<QueueEntryModel>> getQueue() async {
    // Check for daily reset on every queue access
    _checkDailyReset();

    // Try real API first
    try {
      final response = await client.dio.get(
        '/method/api_clinic.clinicfrontdesk.api.get_queue',
      );

      final List data = response.data['message'] ?? [];
      if (data.isNotEmpty) {
        return data.map((json) => QueueEntryModel.fromJson(json)).toList();
      }
    } catch (_) {}

    // Return in-memory mock queue
    return List.from(_mockQueue);
  }

  @override
  Future<QueueEntryModel> updateQueueStatus(String name, String status) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Find the entry in mock queue
    final index = _mockQueue.indexWhere((e) => e.name == name);
    if (index != -1) {
      final oldEntry = _mockQueue[index];

      // If status is Completed, remove from queue (daily reset anyway)
      if (status == 'Completed') {
        _mockQueue.removeAt(index);
        return QueueEntryModel(
          name: oldEntry.name,
          patient: oldEntry.patient,
          patientName: oldEntry.patientName,
          queueNumber: oldEntry.queueNumber,
          queueType: oldEntry.queueType,
          status: 'Completed',
          isPriority: oldEntry.isPriority,
          practitioner: oldEntry.practitioner,
          polyclinic: oldEntry.polyclinic,
          company: oldEntry.company,
          facility: oldEntry.facility,
        );
      }

      // Otherwise update status normally
      final updatedEntry = QueueEntryModel(
        name: oldEntry.name,
        patient: oldEntry.patient,
        patientName: oldEntry.patientName,
        queueNumber: oldEntry.queueNumber,
        queueType: oldEntry.queueType,
        status: status,
        isPriority: oldEntry.isPriority,
        practitioner: oldEntry.practitioner,
        polyclinic: oldEntry.polyclinic,
        company: oldEntry.company,
        facility: oldEntry.facility,
      );
      _mockQueue[index] = updatedEntry;
      return updatedEntry;
    }

    return QueueEntryModel(
      name: name,
      patient: 'MOCK-PAT-UPDATED',
      queueType: 'Doctor',
      status: status,
      company: 'Intimedicare',
      facility: 'Main Clinic',
    );
  }
}
