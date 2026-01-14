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
        Uri.parse('$baseUrl/auth/token'),
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
      Uri.parse('$baseUrl/queues/'),
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

  Future<bool> addToQueue({
    required int patientId,
    int? doctorId,
    required bool isPriority,
    required String queueType,
    String? polyclinic,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/queues/'),
      headers: _headers,
      body: jsonEncode({
        "userId": patientId,
        "medicalFacilityPolyDoctorId": doctorId,
        "isPriority": isPriority,
        "queueType": queueType,
        "polyclinic": polyclinic,
      }),
    );
    return response.statusCode == 200;
  }

  Future<List<Doctor>> getDoctors() async {
    final response = await http.get(
      Uri.parse('$baseUrl/master/doctors'),
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
      Uri.parse('$baseUrl/queues/$id/status'),
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
}
