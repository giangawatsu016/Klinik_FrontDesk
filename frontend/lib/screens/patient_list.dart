import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/glass_container.dart';
import 'registration.dart';
import 'patient_detail.dart';

class PatientListScreen extends StatefulWidget {
  final ApiService apiService;
  const PatientListScreen({super.key, required this.apiService});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  List<Patient> _patients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    try {
      final patients = await widget.apiService.getPatients();
      if (mounted) {
        setState(() {
          _patients = patients;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading patients: $e')));
      }
    }
  }

  void _showPatientDetail(Patient patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDetailScreen(
          patient: patient,
          apiService: widget.apiService,
          onEdit: () async {
            // Edit Logic (Close detail first, or push replacement)
            // Ideally, push edit screen on top
            final nav = Navigator.of(context);
            await nav.push(
              MaterialPageRoute(
                builder: (context) => RegistrationScreen(
                  apiService: widget.apiService,
                  isRegistrationOnly: true,
                  patientToEdit: patient,
                ),
              ),
            );

            // Reload patient list when returning from Edit
            if (mounted) {
              _loadPatients();
              nav.pop();
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RegistrationScreen(
                apiService: widget.apiService,
                isRegistrationOnly: true,
              ),
            ),
          ).then((_) => _loadPatients());
        },
        backgroundColor: Colors.black, // High contrast theme
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _patients.isEmpty
          ? Center(child: Text("No patients found."))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: GlassContainer(
                opacity: 0.8,
                child: Column(
                  children: [
                    // Title Removed
                    Expanded(
                      child: ListView.separated(
                        itemCount: _patients.length,
                        separatorBuilder: (context, index) => Divider(),
                        itemBuilder: (context, index) {
                          final patient = _patients[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.purple.shade100,
                              child: Icon(
                                Icons.person,
                                color: Colors.purple.shade800,
                              ),
                            ),
                            title: Text(
                              "${patient.firstName} ${patient.lastName}",
                            ),
                            subtitle: Text(patient.phone),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
                            ),
                            onTap: () => _showPatientDetail(patient),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
