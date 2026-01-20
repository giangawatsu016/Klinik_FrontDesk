import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/glass_container.dart';

class PatientDetailScreen extends StatefulWidget {
  final Patient patient;
  final ApiService apiService;
  final VoidCallback onEdit;

  const PatientDetailScreen({
    super.key,
    required this.patient,
    required this.apiService,
    required this.onEdit,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.patient.firstName} ${widget.patient.lastName}'),
        backgroundColor: Colors.purple.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: widget.onEdit,
            tooltip: "Edit Patient",
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade50, Colors.blue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _buildInfoTab(),
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: GlassContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader("Personal Info"),
            _detailRow(
              "Name",
              "${widget.patient.firstName} ${widget.patient.lastName}",
            ),
            _detailRow("Identity Card (NIK)", widget.patient.identityCard),
            _detailRow("Phone", widget.patient.phone),
            _detailRow("Gender", widget.patient.gender),
            _detailRow("Birthday", widget.patient.birthday),

            _detailRow(
              "Medical Record No",
              widget.patient.nomorRekamMedis ?? '-',
            ),
            _detailRow("Height", "${widget.patient.height ?? '-'} cm"),
            _detailRow("Weight", "${widget.patient.weight ?? '-'} kg"),
            if (widget.patient.ihsNumber != null)
              _detailRow("IHS Number (SatuSehat)", widget.patient.ihsNumber!),

            SizedBox(height: 16),
            _sectionHeader("Address"),
            _detailRow(
              "Full Address",
              widget.patient.address ??
                  "${widget.patient.addressDetails ?? ''}, ${widget.patient.subdistrict}, ${widget.patient.city}",
            ),

            SizedBox(height: 16),
            _sectionHeader("Insurance"),
            _detailRow("Insurance", widget.patient.insuranceName ?? "-"),
            _detailRow("Policy No", widget.patient.noAssuransi ?? "-"),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.purple.shade900,
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
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}
