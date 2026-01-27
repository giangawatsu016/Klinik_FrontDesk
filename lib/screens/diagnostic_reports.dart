import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/glass_container.dart';

class DiagnosticReportsScreen extends StatefulWidget {
  final ApiService apiService;

  const DiagnosticReportsScreen({super.key, required this.apiService});

  @override
  State<DiagnosticReportsScreen> createState() =>
      _DiagnosticReportsScreenState();
}

class _DiagnosticReportsScreenState extends State<DiagnosticReportsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Patient> _patients = [];
  bool _isLoadingPatients = false;

  Patient? _selectedPatient;
  List<Map<String, dynamic>> _reports = [];
  bool _isLoadingReports = false;

  @override
  void initState() {
    super.initState();
    // Initially load some patients or just wait for search
    _searchPatients(""); // Load all initially
  }

  Future<void> _searchPatients(String query) async {
    setState(() => _isLoadingPatients = true);
    try {
      // Reusing getPatients for now, ideally backend has search endpoint
      // Client-side filtering if backend doesn't support search
      final allPatients = await widget.apiService.getPatients();
      if (mounted) {
        setState(() {
          if (query.isEmpty) {
            _patients = allPatients;
          } else {
            final q = query.toLowerCase();
            _patients = allPatients.where((p) {
              return p.firstName.toLowerCase().contains(q) ||
                  p.lastName.toLowerCase().contains(q) ||
                  p.identityCard.contains(q);
            }).toList();
          }
          _isLoadingPatients = false;
          _selectedPatient = null; // Reset selection on new search
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPatients = false);
    }
  }

  Future<void> _loadReports(Patient patient) async {
    setState(() {
      _selectedPatient = patient;
      _isLoadingReports = true;
      _reports = [];
    });

    try {
      final reports = await widget.apiService.getDiagnosticReports(patient.id!);
      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoadingReports = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingReports = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error fetching reports: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header
            // Header Removed
            // Search & Content

            // Search & Content
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Panel: Patient Search List
                  Expanded(
                    flex: 4,
                    child: GlassContainer(
                      opacity: 0.8,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                labelText: "Search Patient (Name/NIK)",
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.white70,
                              ),
                              onSubmitted: _searchPatients,
                            ),
                          ),
                          Expanded(
                            child: _isLoadingPatients
                                ? Center(child: CircularProgressIndicator())
                                : ListView.separated(
                                    itemCount: _patients.length,
                                    separatorBuilder: (c, i) =>
                                        Divider(height: 1),
                                    itemBuilder: (ctx, i) {
                                      final p = _patients[i];
                                      final isSelected =
                                          _selectedPatient?.id == p.id;
                                      return ListTile(
                                        selected: isSelected,
                                        selectedTileColor:
                                            Colors.purple.shade100,
                                        leading: CircleAvatar(
                                          backgroundColor: isSelected
                                              ? Colors.purple
                                              : Colors.grey.shade300,
                                          child: Text(
                                            p.firstName[0],
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          "${p.firstName} ${p.lastName}",
                                        ),
                                        subtitle: Text(
                                          "NIK: ${p.identityCard}",
                                        ),
                                        onTap: () => _loadReports(p),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(width: 16),

                  // Right Panel: Reports View
                  Expanded(
                    flex: 6,
                    child: _selectedPatient == null
                        ? Center(
                            child: Text(
                              "Select a patient to view reports",
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 16,
                              ),
                            ),
                          )
                        : GlassContainer(
                            opacity: 0.9,
                            child: Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade50,
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${_selectedPatient!.firstName} ${_selectedPatient!.lastName}",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            "IHS: ${_selectedPatient!.ihsNumber ?? 'Not Linked'}",
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_selectedPatient!.ihsNumber != null)
                                        IconButton(
                                          icon: Icon(Icons.refresh),
                                          onPressed: () =>
                                              _loadReports(_selectedPatient!),
                                          tooltip: "Refresh Reports",
                                        ),
                                    ],
                                  ),
                                ),
                                Expanded(child: _buildReportsList()),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsList() {
    if (_isLoadingReports) {
      return Center(child: CircularProgressIndicator());
    }

    // Logic copied from Patient Detail
    if (_selectedPatient!.ihsNumber == null ||
        _selectedPatient!.ihsNumber!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link_off, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Patient not linked to SatuSehat (No IHS Number).",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _loadReports(_selectedPatient!),
              child: Text("Retry / Search by NIK"),
            ),
          ],
        ),
      );
    }

    if (_reports.isEmpty) {
      return Center(child: Text("No Diagnostic Reports found."));
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final report = _reports[index];
        return Card(
          // Elevation 0 from Theme
          margin: EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Icon(Icons.science, color: Colors.blue.shade800),
            ),
            title: Text(
              report['code'] ?? 'Unknown Test',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Date: ${report['effectiveDateTime']}"),
                Text("Performer: ${report['performer']}"),
              ],
            ),
            isThreeLine: true,
            trailing: Chip(
              label: Text(report['status'] ?? 'unknown'),
              backgroundColor: Colors.grey.shade200,
            ),
          ),
        );
      },
    );
  }
}
