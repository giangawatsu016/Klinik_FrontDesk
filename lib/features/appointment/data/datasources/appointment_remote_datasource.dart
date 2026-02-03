import '../models/appointment_model.dart';
import '../models/busy_range_model.dart';
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
  Future<void> simulatePayment(int appointmentId);
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
    // MOCK CREATE APPOINTMENT
    await Future.delayed(const Duration(seconds: 1));
    return AppointmentModel(
      id: DateTime.now().millisecondsSinceEpoch,
      date: appointment.date,
      status: 'PENDING',
      serviceName: 'Home Care Visit',
      doctorName: 'Mock Doctor',
      serviceId: appointment.serviceId,
      doctorId: appointment.doctorId,
      finalPrice: appointment.finalPrice,
      paymentStatus: 'UNPAID',
      patientDetail: appointment.patientDetail,
      doctorTitlePrefix: 'dr.',
    );
  }

  @override
  Future<List<AppointmentModel>> getAppointments() async {
    // MOCK GET APPOINTMENTS (Fixes DioException)
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      AppointmentModel(
        id: 101,
        serviceId: 1,
        doctorId: 1,
        doctorName: 'Sarah Wilson',
        doctorTitlePrefix: 'dr.',
        date: DateTime.now().add(const Duration(days: 1, hours: 2)),
        status: 'PAID', // Active appointment with payment done
        serviceName: 'Konsultasi Umum',
        finalPrice: 150000,
        paymentStatus: 'PAID',
        patientDetail: {
          'fullname': 'Budi Santoso',
          'address': 'Jl. Merdeka No. 1',
        },
      ),
      AppointmentModel(
        id: 102,
        serviceId: 2,
        doctorId: 2,
        doctorName: 'James Carter',
        doctorTitlePrefix: 'dr.',
        doctorTitleSuffix: 'Sp.A',
        date: DateTime.now().add(const Duration(hours: 3)),
        status: 'IN_PROGRESS', // Currently being processed
        serviceName: 'Pemeriksaan Anak',
        finalPrice: 200000,
        paymentStatus: 'PAID',
        patientDetail: {
          'fullname': 'Anak Budi',
          'address': 'Jl. Merdeka No. 1',
        },
        clinicalRecord: {
          'diagnoses': [
            {
              'diagnosis': {'description': 'Common Cold'},
            },
          ],
          'medicines': [],
        },
      ),
      AppointmentModel(
        id: 103,
        serviceId: 1,
        doctorId: 3,
        doctorName: 'Emily Chen',
        doctorTitlePrefix: 'dr.',
        doctorTitleSuffix: 'Sp.KK',
        date: DateTime.now().add(const Duration(days: 3)),
        status: 'UPCOMING', // Future appointment
        serviceName: 'Konsultasi Kulit',
        finalPrice: 250000,
        paymentStatus: 'PAID',
        patientDetail: {
          'fullname': 'Siti Aminah',
          'address': 'Jl. Sudirman No. 5',
        },
      ),
    ];
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
      'message': [
        {
          'id': 102,
          'date': DateTime.now()
              .subtract(const Duration(days: 2))
              .toIso8601String(),
          'doctor': {
            'name': 'James Carter',
            'titlePrefix': 'dr.',
            'titleSuffix': 'Sp.A',
          },
          'diagnosis': 'Common Cold',
          'patient': {'fullname': 'Anak Budi'},
        },
      ],
      'meta': {'total': 1, 'page': page, 'limit': limit},
    };
  }

  @override
  Future<String> createInvoice(String appointmentId) async {
    // MOCK INVOICE
    await Future.delayed(const Duration(seconds: 1));
    return 'https://example.com/invoice/$appointmentId';
  }

  @override
  Future<void> simulatePayment(int appointmentId) async {
    // MOCK PAYMENT
    await Future.delayed(const Duration(seconds: 1));
  }
}
