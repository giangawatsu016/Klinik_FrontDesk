import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  final String baseUrl = "http://127.0.0.1:8001";
  String? _authToken;

  void setToken(String token) {
    _authToken = token;
  }

  Map<String, String> get _headers {
    final headers = {"Content-Type": "application/json"};
    if (_authToken != null) {
      headers["Authorization"] = "Bearer $_authToken";
    }
    return headers;
  }

  Future<User?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"username": username, "password": password},
      );

      // print("Login Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _authToken = data['access_token'];

        // Fetch User Profile to get Role
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
          // Fallback if /me fails
        }

        return User(
          username: username,
          fullName: "Staff / Admin",
          role: "staff", // Default fallback
          token: _authToken!,
        );
      }
      return null;
    } catch (e) {
      // print("API Error: $e");
      rethrow;
    }
  }

  Future<List<QueueItem>> getQueue() async {
    final response = await http.get(
      Uri.parse('$baseUrl/patients/queue/'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => QueueItem.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<Patient>> searchPatients(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/patients/search?query=$query'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Patient.fromJson(json)).toList();
    }
    return [];
  }

  Future<Patient?> registerPatient(Patient patient) async {
    final response = await http.post(
      Uri.parse('$baseUrl/patients/'),
      headers: _headers,
      body: jsonEncode(patient.toJson()),
    );
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
    final response = await http.post(
      Uri.parse('$baseUrl/patients/queue/'),
      headers: _headers,
      body: jsonEncode({
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
    final response = await http.get(
      Uri.parse('$baseUrl/doctors/'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Doctor.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<Patient>> getPatients() async {
    final response = await http.get(
      Uri.parse('$baseUrl/patients/'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Patient.fromJson(json)).toList();
    }
    return [];
  }

  Future<bool> updateQueueStatus(int id, String status) async {
    final response = await http.put(
      Uri.parse('$baseUrl/patients/queue/$id/status'),
      headers: _headers,
      body: jsonEncode({"status": status}),
    );
    return response.statusCode == 200;
  }

  // Address Methods
  Future<List<Map<String, dynamic>>> getProvinces() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/master/address/provinces'),
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    } catch (_) {}
    return [];
  }

  Future<List<Map<String, dynamic>>> getCities(String provinceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/master/address/cities/$provinceId'),
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    } catch (_) {}
    return [];
  }

  Future<List<Map<String, dynamic>>> getDistricts(String cityId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/master/address/districts/$cityId'),
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    } catch (_) {}
    return [];
  }

  Future<List<Map<String, dynamic>>> getSubdistricts(String districtId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/master/address/subdistricts/$districtId'),
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    } catch (_) {}
    return [];
  }

  Future<Doctor?> createDoctor(Doctor doctor) async {
    final response = await http.post(
      Uri.parse('$baseUrl/doctors/'),
      headers: _headers,
      body: jsonEncode({
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
    final response = await http.put(
      Uri.parse('$baseUrl/doctors/$id'),
      headers: _headers,
      body: jsonEncode({
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
    final response = await http.put(
      Uri.parse('$baseUrl/patients/$id'),
      headers: _headers,
      body: jsonEncode(patient.toJson()),
    );
    if (response.statusCode == 200) {
      return Patient.fromJson(jsonDecode(response.body));
    }
    throw Exception("Update Failed: ${response.statusCode}");
  }

  // Medicine Methods
  Future<List<Medicine>> getMedicines() async {
    final response = await http.get(
      Uri.parse('$baseUrl/medicines/'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Medicine.fromJson(json)).toList();
    }
    return [];
  }

  Future<Medicine?> createMedicine(Medicine medicine) async {
    final response = await http.post(
      Uri.parse('$baseUrl/medicines/'),
      headers: _headers,
      body: jsonEncode(medicine.toJson()),
    );
    if (response.statusCode == 200) {
      return Medicine.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<Medicine?> updateMedicine(int id, Medicine medicine) async {
    final response = await http.put(
      Uri.parse('$baseUrl/medicines/$id'),
      headers: _headers,
      body: jsonEncode(medicine.toJson()),
    );
    if (response.statusCode == 200) {
      return Medicine.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<void> deleteMedicine(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/medicines/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception("Failed to delete medicine");
    }
  }

  Future<Medicine?> createConcoction(ConcoctionRequest concoction) async {
    final response = await http.post(
      Uri.parse('$baseUrl/medicines/concoctions'),
      headers: _headers,
      body: jsonEncode(concoction.toJson()),
    );
    if (response.statusCode == 200) {
      return Medicine.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<Map<String, dynamic>> syncMedicines() async {
    final response = await http.post(
      Uri.parse('$baseUrl/medicines/sync'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to sync medicines');
    }
  }

  Future<Map<String, dynamic>> syncDoctors() async {
    final response = await http.post(
      Uri.parse('$baseUrl/doctors/sync'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to sync doctors');
    }
  }

  // User Management Methods
  Future<List<User>> getUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    }
    return [];
  }

  Future<User?> createUser(User user, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/'),
      headers: _headers,
      body: jsonEncode({
        "username": user.username,
        "password": password,
        "full_name": user.fullName,
        "role": user.role,
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
    };
    if (password != null && password.isNotEmpty) {
      body["password"] = password;
    }

    final response = await http.put(
      Uri.parse('$baseUrl/users/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    throw Exception("Update User Failed: ${response.body}");
  }

  Future<bool> deleteUser(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/$id'),
      headers: _headers,
    );
    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>?> fetchPatientFromSatuSehat(String nik) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/integration/satusehat/patient/$nik'),
        headers: _headers,
      );
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
    final response = await http.get(
      Uri.parse(
        '$baseUrl/integration/kfa/products?query=$query&page=$page&limit=$limit',
      ),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getDiagnosticReports(int patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/integration/diagnostic-reports/$patientId'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    } catch (_) {}
    return [];
  }

  // --- Disease Management ---

  Future<List<Disease>> getDiseases({String query = ""}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/diseases?search=$query'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Disease.fromJson(json)).toList();
    }
    return [];
  }

  Future<Disease?> createDisease(Disease disease) async {
    final response = await http.post(
      Uri.parse('$baseUrl/diseases'),
      headers: _headers,
      body: jsonEncode(disease.toJson()),
    );
    if (response.statusCode == 200) {
      return Disease.fromJson(jsonDecode(response.body));
    }
    throw Exception(response.body);
  }

  Future<Disease?> updateDisease(int id, Disease disease) async {
    final response = await http.put(
      Uri.parse('$baseUrl/diseases/$id'),
      headers: _headers,
      body: jsonEncode(disease.toJson()),
    );
    if (response.statusCode == 200) {
      return Disease.fromJson(jsonDecode(response.body));
    }
    throw Exception(response.body);
  }

  Future<void> deleteDisease(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/diseases/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception("Failed to delete disease");
    }
  }
}
