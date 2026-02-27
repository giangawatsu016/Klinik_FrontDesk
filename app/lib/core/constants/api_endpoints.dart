import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

class ApiEndpoints {
  static String get baseUrl {
    // HARDCODED DEFAULT FOR DEBUGGING
    // const defaultUrl = 'http://localhost:8000/api';

    final url = dotenv.env['BASE_URL'] ?? 'http://localhost:8000/api';

    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        url.contains('localhost')) {
      return url.replaceFirst('localhost', '10.0.2.2');
    }
    return url;
  }

  static String get login => '$baseUrl/method/login';
  static String get getLoggedUser =>
      '$baseUrl/method/frappe.auth.get_logged_user';
  // Custom endpoint to get full user context (Role, Company, etc.)
  static String get getUserContext =>
      '$baseUrl/method/api_clinic.clinicadmin.api.get_user_context';

  static String getUser(String email) => '$baseUrl/resource/User/$email';

  // FrontDesk Wrappers
  static String get register =>
      '$baseUrl/method/api_clinic.api.register_patient';
  static String get searchPatient =>
      '$baseUrl/method/api_clinic.api.search_patient';
  static String get addToQueue => '$baseUrl/method/api_clinic.api.add_to_queue';
  static String get getQueue => '$baseUrl/method/api_clinic.api.get_queue';
  static String get updateQueueStatus =>
      '$baseUrl/method/api_clinic.api.update_queue_status';
  static String get advanceQueueStatus =>
      '$baseUrl/method/api_clinic.api.advance_queue_status';
  static String get getQueueHistory =>
      '$baseUrl/method/api_clinic.api.get_queue_history';
  static String get getMedicalRecords =>
      '$baseUrl/method/api_clinic.api.get_medical_records';

  // Master Data
  static String get getPractitioners =>
      '$baseUrl/method/api_clinic.api.get_practitioners';
  static String get getPolyclinics =>
      '$baseUrl/method/api_clinic.api.get_polyclinics';
  static String get getDefaultFacility =>
      '$baseUrl/method/api_clinic.api.get_default_facility';
  static String get getNotifications =>
      '$baseUrl/method/api_clinic.api.get_notifications';
  static String get getIssuers =>
      '$baseUrl/method/api_clinic.api.get_payment_issuers';
  static String get googleLogin => '$baseUrl/auth/google';

  static String get profile => '$baseUrl/method/api_clinic.api.get_profile';
  static String get services => '$baseUrl/method/api_clinic.api.get_services';
  static String get updateFcmToken =>
      '$baseUrl/method/api_clinic.api.update_fcm_token';
  static const String doctors = '/doctors';

  // Appointment & Medical Records
  static const String appointments = '/appointments';
  static const String medicalRecords = '/medical-records';

  static const String doctorAvailability = '/doctors/availability';

  static String get getAppointments =>
      '$baseUrl/method/api_clinic.api.get_appointments';
  static String get createAppointment =>
      '$baseUrl/method/api_clinic.api.create_appointment';

  static String get createInvoice =>
      '$baseUrl/method/api_clinic.api.create_invoice';
  static String get simulatePayment =>
      '$baseUrl/method/api_clinic.api.simulate_payment';
  static String get cancelAppointment =>
      '$baseUrl/method/api_clinic.api.cancel_appointment';

  // Payment Endpoints
  static String get allPayments => '$baseUrl/payment/all';
  static String get paymentInvoice => '$baseUrl/payment/invoice';
  static String get paymentSimulate => '$baseUrl/payment/simulate';
  static String paymentHistory(int id) => '$baseUrl/payment/history/$id';
}
