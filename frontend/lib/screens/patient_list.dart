import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/glass_container.dart';
import 'registration.dart';

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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Patient Details"),
        content: SizedBox(
          width: 500, // Wider for detailed info
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader("Personal Info"),
                _detailRow("Name", "${patient.firstName} ${patient.lastName}"),
                _detailRow("Identity Card (NIK)", patient.identityCard),
                _detailRow("Phone", patient.phone),
                _detailRow("Gender", patient.gender),
                _detailRow("Birthday", patient.birthday),
                _detailRow("Religion", patient.religion),
                _detailRow("Profession", patient.profession),
                _detailRow("Education", patient.education),

                SizedBox(height: 16),
                _sectionHeader("Contact & Address"),
                _detailRow("Address", patient.addressDetails ?? "-"),
                _detailRow(
                  "Region",
                  "${patient.subdistrict}, ${patient.district}, ${patient.city}, ${patient.province}",
                ),
                _detailRow("RT/RW", "${patient.rt} / ${patient.rw}"),
                _detailRow("Postal Code", patient.postalCode),

                SizedBox(height: 16),
                _sectionHeader("Insurance / Payment"),
                _detailRow("Issuer ID", patient.issuerId.toString()),
                if (patient.insuranceName != null)
                  _detailRow("Insurance Name", patient.insuranceName!),
                if (patient.noAssuransi != null)
                  _detailRow("Policy Number", patient.noAssuransi!),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RegistrationScreen(
                    apiService: widget.apiService,
                    isRegistrationOnly: true,
                    patientToEdit: patient,
                  ),
                ),
              ).then((_) => _loadPatients());
            },
            child: Text("Edit", style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              "$label:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
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
        backgroundColor: Colors.purple.shade900,
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
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Patient List",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
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
