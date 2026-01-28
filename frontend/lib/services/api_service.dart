import 'package:flutter/foundation.dart'; // For debugPrint
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  // Try localhost first, then 127.0.0.1, then Android Emulator 10.0.2.2
  static const String _localUrl = "http://localhost:8001";
  static const String _ipUrl = "http://127.0.0.1:8001";
  static const String _androidUrl = "http://10.0.2.2:8001";
  String baseUrl = _localUrl;

  String? _authToken;

  void setToken(String token) {
    _authToken = token;
  }

  // Debugging Helper: Switch URL if connection failed
  void _switchUrl() {
    if (baseUrl == _localUrl) {
      baseUrl = _ipUrl;
    } else if (baseUrl == _ipUrl) {
      baseUrl = _androidUrl;
    } else {
      baseUrl = _localUrl;
    }
    debugPrint("Switched API URL to: $baseUrl");
  }

  Map<String, String> get _headers {
    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
    if (_authToken != null) {
      headers["Authorization"] = "Bearer $_authToken";
    }
    return headers;
  }

  Future<User?> login(String username, String password) async {
    // Helper to perform the request
    Future<http.Response> attemptLogin(String url) {
      return http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"username": username, "password": password},
      );
    }

    http.Response response;
    try {
      response = await attemptLogin('$baseUrl/auth/login');
    } catch (e) {
      debugPrint("First Login Attempt Failed on $baseUrl: $e");
      _switchUrl(); // Toggle URL
      response = await attemptLogin('$baseUrl/auth/login'); // Retry
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _authToken = data['access_token'];

      // Fetch User Profile
      try {
        final meResponse = await http.get(
          Uri.parse('$baseUrl/auth/me'),
          headers: _headers,
        );
        if (meResponse.statusCode == 200) {
          final meData = jsonDecode(meResponse.body);
          return User(
            username: username,
            fullName: meData['full_name'] ?? "Unknown",
            role: meData['role'] ?? "staff",
            token: _authToken!,
          );
        }
      } catch (_) {
        // Ignore profile fetch fail
      }

      return User(
        username: username,
        fullName: "Staff / Admin",
        role: "staff",
        token: _authToken!,
      );
    }
    return null;
  }

  // Helper for resilient requests
  Future<http.Response> _safeGet(String endpoint) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$endpoint'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      return response;
    } catch (e) {
      debugPrint("GET Failed on $baseUrl: $e");
      _switchUrl();
      debugPrint("Retrying GET on $baseUrl");
      return await http.get(Uri.parse('$baseUrl$endpoint'), headers: _headers);
    }
  }

  Future<http.Response> _safePost(String endpoint, dynamic body) async {
    try {
      final response = await http
          .post(Uri.parse('$baseUrl$endpoint'), headers: _headers, body: body)
          .timeout(
            const Duration(seconds: 60),
          ); // Increased timeout to 60 seconds
      return response;
    } catch (e) {
      debugPrint("POST Failed on $baseUrl: $e");
      _switchUrl();
      debugPrint("Retrying POST on $baseUrl");
      return await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: body,
      );
    }
  }

  // Also add _safePut and _safeDelete if needed, or implement as generic _safeRequest

  Future<List<QueueItem>> getQueue() async {
    final response = await _safeGet('/patients/queue');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => QueueItem.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<Patient>> searchPatients(String query) async {
    final response = await _safeGet('/patients/search?query=$query');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Patient.fromJson(json)).toList();
    }
    return [];
  }

  Future<Patient?> registerPatient(Patient patient) async {
    final response = await _safePost('/patients', jsonEncode(patient.toJson()));
    if (response.statusCode == 200) {
      return Patient.fromJson(jsonDecode(response.body));
    }
    throw Exception(
      "Registration Failed: ${response.statusCode}\n${response.body}",
    );
  }

  Future<void> addToQueue({
    required int patientId,
    int? doctorId,
    required bool isPriority,
    required String queueType,
    String? polyclinic,
  }) async {
    final response = await _safePost(
      '/patients/queue',
      jsonEncode({
        "userId": patientId,
        "medicalFacilityPolyDoctorId": doctorId,
        "isPriority": isPriority,
        "queueType": queueType,
        "polyclinic": polyclinic,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception("Queue Error (${response.statusCode}): ${response.body}");
    }
  }

  Future<List<Doctor>> getDoctors() async {
    final response = await _safeGet('/doctors');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Doctor.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<Patient>> getPatients() async {
    final response = await _safeGet('/patients');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Patient.fromJson(json)).toList();
    }
    return [];
  }

  Future<bool> updateQueueStatus(int id, String status) async {
    final response = await _safePut(
      '/patients/queue/$id/status',
      jsonEncode({"status": status}),
    );
    return response.statusCode == 200;
  }

  // Address Methods
  Future<List<Map<String, dynamic>>> getProvinces() async {
    try {
      final response = await _safeGet('/master/address/provinces');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    } catch (_) {}
    return [];
  }

  Future<List<Map<String, dynamic>>> getCities(String provinceId) async {
    try {
      final response = await _safeGet('/master/address/cities/$provinceId');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    } catch (_) {}
    return [];
  }

  Future<List<Map<String, dynamic>>> getDistricts(String cityId) async {
    try {
      final response = await _safeGet('/master/address/districts/$cityId');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    } catch (_) {}
    return [];
  }

  Future<List<Map<String, dynamic>>> getSubdistricts(String districtId) async {
    try {
      final response = await _safeGet(
        '/master/address/subdistricts/$districtId',
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    } catch (_) {}
    return [];
  }

  Future<Doctor?> createDoctor(Doctor doctor) async {
    final response = await _safePost(
      '/doctors',
      jsonEncode({
        "gelarDepan": doctor.gelarDepan,
        "namaDokter": doctor.namaDokter,
        "polyName": doctor.polyName,
        "firstName": doctor.firstName,
        "lastName": doctor.lastName,
        "gelarBelakang": doctor.gelarBelakang,
        "doctorSIP": doctor.doctorSIP,
        "onlineFee": doctor.onlineFee,
        "appointmentFee": doctor.appointmentFee,
        "is_available": true,
      }),
    );
    if (response.statusCode == 200) {
      return Doctor.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<Doctor?> updateDoctor(int id, Doctor doctor) async {
    final response = await _safePut(
      '/doctors/$id',
      jsonEncode({
        "gelarDepan": doctor.gelarDepan,
        "namaDokter": doctor.namaDokter,
        "polyName": doctor.polyName,
        "firstName": doctor.firstName,
        "lastName": doctor.lastName,
        "gelarBelakang": doctor.gelarBelakang,
        "doctorSIP": doctor.doctorSIP,
        "onlineFee": doctor.onlineFee,
        "appointmentFee": doctor.appointmentFee,
        "is_available": true,
      }),
    );
    if (response.statusCode == 200) {
      return Doctor.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<Patient?> updatePatient(int id, Patient patient) async {
    final response = await _safePut(
      '/patients/$id',
      jsonEncode(patient.toJson()),
    );
    if (response.statusCode == 200) {
      return Patient.fromJson(jsonDecode(response.body));
    }
    throw Exception("Update Failed: ${response.statusCode}");
  }

  // Sync Methods
  Future<Map<String, dynamic>> syncDoctors() async {
    final response = await _safePost('/doctors/sync', null);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("Sync Doctors Failed: ${response.body}");
  }

  Future<Map<String, dynamic>> syncDoctorsPush() async {
    final response = await _safePost('/doctors/sync/push', null);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("Push Doctors Failed: ${response.body}");
  }

  Future<Map<String, dynamic>> syncPatients() async {
    final response = await _safePost('/patients/sync', null);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("Sync Patients Failed: ${response.body}");
  }

  Future<Map<String, dynamic>> syncPatientsPush() async {
    final response = await _safePost('/patients/sync/push', null);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("Push Patients Failed: ${response.body}");
  }

  // Medicine Methods
  Future<List<Medicine>> getMedicines() async {
    final response = await _safeGet('/medicines');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Medicine.fromJson(json)).toList();
    }
    return [];
  }

  Future<http.Response> _safePut(String endpoint, dynamic body) async {
    try {
      final response = await http
          .put(Uri.parse('$baseUrl$endpoint'), headers: _headers, body: body)
          .timeout(const Duration(seconds: 30));
      return response;
    } catch (e) {
      debugPrint("PUT Failed on $baseUrl: $e");
      _switchUrl();
      debugPrint("Retrying PUT on $baseUrl");
      return await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: body,
      );
    }
  }

  Future<http.Response> _safeDelete(String endpoint) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl$endpoint'), headers: _headers)
          .timeout(const Duration(seconds: 5));
      return response;
    } catch (e) {
      debugPrint("DELETE Failed on $baseUrl: $e");
      _switchUrl();
      debugPrint("Retrying DELETE on $baseUrl");
      return await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );
    }
  }

  Future<Medicine?> createMedicine(Medicine medicine) async {
    final response = await _safePost(
      '/medicines',
      jsonEncode(medicine.toJson()),
    );
    if (response.statusCode == 200) {
      return Medicine.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<Medicine?> updateMedicine(int id, Medicine medicine) async {
    final response = await _safePut(
      '/medicines/$id',
      jsonEncode(medicine.toJson()),
    );
    if (response.statusCode == 200) {
      return Medicine.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<void> deleteMedicine(int id) async {
    final response = await _safeDelete('/medicines/$id');
    if (response.statusCode != 200) {
      throw Exception("Failed to delete medicine");
    }
  }

  Future<MedicineBatch?> createMedicineBatch(
    int medicineId,
    MedicineBatch batch,
  ) async {
    final response = await _safePost(
      '/medicines/$medicineId/batches',
      jsonEncode(batch.toJson()),
    );
    if (response.statusCode == 200) {
      return MedicineBatch.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<void> deleteMedicineBatch(int batchId) async {
    final response = await _safeDelete('/medicines/batches/$batchId');
    if (response.statusCode != 200) {
      throw Exception("Failed to delete batch");
    }
  }

  Future<Map<String, dynamic>> syncMedicines() async {
    final response = await _safePost('/medicines/sync', null);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to sync medicines');
    }
  }

  Future<Map<String, dynamic>> syncMedicinesPush() async {
    final response = await _safePost('/medicines/sync/push', null);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to push medicines');
    }
  }

  // User Management Methods
  Future<List<User>> getUsers() async {
    final response = await _safeGet('/users');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    }
    return [];
  }

  Future<User?> createUser(User user, String password) async {
    final response = await _safePost(
      '/users',
      jsonEncode({
        "username": user.username,
        "password": password,
        "full_name": user.fullName,
        "role": user.role,
        "email": user.email,
      }),
    );
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    throw Exception("Create User Failed: ${response.body}");
  }

  Future<User?> updateUser(int id, User user, String? password) async {
    final body = {
      "username": user.username,
      "full_name": user.fullName,
      "role": user.role,
      "email": user.email,
    };
    if (password != null && password.isNotEmpty) {
      body["password"] = password;
    }

    final response = await _safePut('/users/$id', jsonEncode(body));
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    throw Exception("Update User Failed: ${response.body}");
  }

  Future<bool> deleteUser(int id) async {
    final response = await _safeDelete('/users/$id');
    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>?> fetchPatientFromSatuSehat(String nik) async {
    try {
      final response = await _safeGet('/integration/satusehat/patient/$nik');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }

  Future<List<Map<String, dynamic>>> searchKfaProducts(
    String query, {
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _safeGet(
      '/integration/kfa/products?query=$query&page=$page&limit=$limit',
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getDiagnosticReports(int patientId) async {
    try {
      final response = await _safeGet(
        '/integration/diagnostic-reports/$patientId',
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    } catch (_) {}
    return [];
  }

  // --- Satu Sehat Sync Methods ---

  Future<Map<String, dynamic>> syncSatuSehatDoctors() async {
    final response = await _safePost(
      '/integration/satusehat/doctors/sync',
      null,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("SS Pull Doctors Failed: ${response.body}");
  }

  Future<Map<String, dynamic>> syncSatuSehatDoctorsPush() async {
    final response = await _safePost(
      '/integration/satusehat/doctors/push',
      null,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("SS Push Doctors Failed: ${response.body}");
  }

  Future<Map<String, dynamic>> syncSatuSehatPatients() async {
    final response = await _safePost(
      '/integration/satusehat/patients/sync',
      null,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("SS Pull Patients Failed: ${response.body}");
  }

  Future<Map<String, dynamic>> syncSatuSehatPatientsPush() async {
    final response = await _safePost(
      '/integration/satusehat/patients/push',
      null,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("SS Push Patients Failed: ${response.body}");
  }

  // --- Disease Management ---

  Future<List<Disease>> getDiseases({String query = ""}) async {
    final response = await _safeGet('/diseases?search=$query');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Disease.fromJson(json)).toList();
    }
    return [];
  }

  Future<Disease?> createDisease(Disease disease) async {
    final response = await _safePost('/diseases', jsonEncode(disease.toJson()));
    if (response.statusCode == 200) {
      return Disease.fromJson(jsonDecode(response.body));
    }
    throw Exception(response.body);
  }

  Future<Disease?> updateDisease(int id, Disease disease) async {
    final response = await _safePut(
      '/diseases/$id',
      jsonEncode(disease.toJson()),
    );
    if (response.statusCode == 200) {
      return Disease.fromJson(jsonDecode(response.body));
    }
    throw Exception(response.body);
  }

  Future<Map<String, dynamic>> syncDiseases() async {
    final response = await _safePost('/diseases/sync', null);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("Sync Failed: ${response.body}");
  }

  Future<Map<String, dynamic>> syncDiseasesPush() async {
    final response = await _safePost('/diseases/sync/push', null);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("Push Failed: ${response.body}");
  }

  Future<void> deleteDisease(int id) async {
    final response = await _safeDelete('/diseases/$id');
    if (response.statusCode != 200) {
      throw Exception("Failed to delete disease");
    }
  }

  // --- Payments ---
  Future<Payment> processPayment(Payment payment) async {
    final response = await _safePost("/payments/", payment.toJson());
    if (response.statusCode == 200) {
      return Payment.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to process payment: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> getDashboardOverview() async {
    final response = await _safeGet('/dashboard/overview');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load dashboard stats');
  }

  Future<List<Doctor>> getIdleDoctors() async {
    final response = await _safeGet('/dashboard/idle_doctors');
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((json) => Doctor.fromJson(json)).toList();
    }
    throw Exception('Failed to fetch idle doctors');
  }

  // --- App Config ---
  Future<List<String>> getHiddenMenus() async {
    return (await getAppConfig('hidden_menus') as List).cast<String>();
  }

  // Generic Config
  Future<dynamic> getAppConfig(String key) async {
    try {
      final response = await _safeGet('/config/$key');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['value'] != null && data['value'].toString().isNotEmpty) {
          try {
            return jsonDecode(data['value']);
          } catch (e) {
            return data['value']; // Return as string if not JSON
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> saveAppConfig(String key, dynamic value) async {
    final body = jsonEncode({
      "key": key,
      "value": value is String ? value : jsonEncode(value),
    });

    final response = await _safePost('/config/', body);
    if (response.statusCode != 200) {
      throw Exception("Failed to save config: ${response.body}");
    }
  }

  Future<void> setHiddenMenus(List<String> hiddenMenus) async {
    await saveAppConfig("hidden_menus", hiddenMenus);
  }

  Future<List<Issuer>> getIssuers() async {
    final response = await _safeGet('/master/issuers');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Issuer.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<Appointment>> getAppointments() async {
    final response = await _safeGet('/appointments');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Appointment.fromJson(json)).toList();
    }
    return [];
  }

  // Pharmacist Methods
  Future<List<Pharmacist>> getPharmacists() async {
    final response = await _safeGet('/pharmacists');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Pharmacist.fromJson(json)).toList();
    }
    return [];
  }

  Future<Pharmacist> createPharmacist(Pharmacist pharmacist) async {
    final response = await http.post(
      Uri.parse("$baseUrl/pharmacists"),
      headers: _headers,
      body: jsonEncode(pharmacist.toJson()),
    );
    if (response.statusCode == 200) {
      return Pharmacist.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create pharmacist: ${response.body}');
    }
  }

  Future<Pharmacist> updatePharmacist(int id, Pharmacist pharmacist) async {
    final response = await http.put(
      Uri.parse("$baseUrl/pharmacists/$id"),
      headers: _headers,
      body: jsonEncode(pharmacist.toJson()),
    );
    if (response.statusCode == 200) {
      return Pharmacist.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update pharmacist: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> syncPharmacistsPush() async {
    final response = await http.post(
      Uri.parse("$baseUrl/integration/satusehat/pharmacists/push"),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to push pharmacists: ${response.body}');
    }
  }

  Future<void> deletePharmacist(int id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/pharmacists/$id"),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete pharmacist: ${response.body}');
    }
  }
}
