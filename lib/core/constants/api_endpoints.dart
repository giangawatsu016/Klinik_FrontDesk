import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

class ApiEndpoints {
  static String get baseUrl {
    final url = dotenv.env['BASE_URL'] ?? 'http://localhost:3000/api/m';
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        url.contains('localhost')) {
      return url.replaceFirst('localhost', '10.0.2.2');
    }
    return url;
  }

  static String get login => '$baseUrl/method/login';
  static String get register =>
      '$baseUrl/method/api_clinic.clinicfrontdesk.api.register_patient';
  static String get googleLogin => '$baseUrl/auth/google';

  static String get profile => '$baseUrl/profile';
  static String get services => '$baseUrl/services';
  static const String doctors = '/doctors';

  // Appointment & Medical Records
  static const String appointments = '/appointments';
  static const String medicalRecords = '/medical-records';

  static const String doctorAvailability = '/doctors/availability';

  // Payment Endpoints
  static String get allPayments => '$baseUrl/payment/all';
  static String get paymentInvoice => '$baseUrl/payment/invoice';
  static String get paymentSimulate => '$baseUrl/payment/simulate';
  static String paymentHistory(int id) => '$baseUrl/payment/history/$id';
}
