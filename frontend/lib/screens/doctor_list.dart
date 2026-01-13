import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/glass_container.dart';

class DoctorListScreen extends StatefulWidget {
  final ApiService apiService;
  const DoctorListScreen({super.key, required this.apiService});

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  List<Doctor> _doctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    try {
      final doctors = await widget.apiService.getDoctors();
      if (mounted) {
        setState(() {
          _doctors = doctors;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading doctors: $e')));
      }
    }
  }

  void _showDoctorDetail(Doctor doctor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Doctor Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow("Name", "${doctor.gelarDepan} ${doctor.namaDokter}"),
            _detailRow("Polyclinic", doctor.polyName),
            _detailRow("ID", doctor.medicalFacilityPolyDoctorId.toString()),
            // Add more fields if available in model later
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: Colors.black87),
          children: [
            TextSpan(
              text: "$label: ",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_doctors.isEmpty) {
      return Center(child: Text("No doctors found."));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GlassContainer(
        opacity: 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Doctor List",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: _doctors.length,
                separatorBuilder: (context, index) => Divider(),
                itemBuilder: (context, index) {
                  final doctor = _doctors[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(
                        Icons.medical_services,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    title: Text("${doctor.gelarDepan} ${doctor.namaDokter}"),
                    subtitle: Text(doctor.polyName),
                    trailing: Icon(Icons.info_outline, color: Colors.grey),
                    onTap: () => _showDoctorDetail(doctor),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
