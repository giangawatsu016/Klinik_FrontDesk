import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';
import '../models/models.dart';
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
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(LucideIcons.plus, color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _patients.isEmpty
          ? Center(
              child: Text(
                "No patients found.",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.separated(
                  padding: EdgeInsets.all(16),
                  itemCount: _patients.length,
                  separatorBuilder: (context, index) =>
                      Divider(color: Colors.grey.shade100, height: 1),
                  itemBuilder: (context, index) {
                    final patient = _patients[index];
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.1),
                        radius: 24,
                        child: Icon(
                          LucideIcons.user,
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        "${patient.firstName} ${patient.lastName}",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          fontFamily: 'Inter',
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          Icon(LucideIcons.phone, size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            patient.phone,
                            style: TextStyle(fontFamily: 'Inter'),
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      onTap: () => _showPatientDetail(patient),
                    );
                  },
                ),
              ),
            ),
    );
  }
}
