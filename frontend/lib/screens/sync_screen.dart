import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SyncScreen extends StatefulWidget {
  final ApiService apiService;

  const SyncScreen({super.key, required this.apiService});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  bool _isLoading = false;
  final List<String> _logs = [];

  void _addLog(String message) {
    setState(() {
      _logs.add(
        "[${DateTime.now().toIso8601String().split('T')[1].split('.')[0]}] $message",
      );
    });
  }

  Future<void> _runCombinedSync(
    String name,
    Future<Map<String, dynamic>> Function() pullFn,
    Future<Map<String, dynamic>> Function() pushFn,
  ) async {
    setState(() => _isLoading = true);
    _addLog("Starting $name Sync...");

    try {
      // 1. PULL
      _addLog("Pulling $name from ERPNext...");
      try {
        final pullRes = await pullFn();
        _addLog("Pull Success: ${pullRes['message'] ?? pullRes['status']}");
        if (pullRes['count'] != null) {
          _addLog("Pulled Count: ${pullRes['count']}");
        }
      } catch (e) {
        _addLog("Pull Error: $e");
      }

      // 2. PUSH
      _addLog("Pushing $name to ERPNext...");
      try {
        final pushRes = await pushFn();
        _addLog("Push Success: ${pushRes['message'] ?? pushRes['status']}");
        if (pushRes['count'] != null) {
          _addLog("Pushed Count: ${pushRes['count']}");
        }
      } catch (e) {
        _addLog("Push Error: $e");
      }
    } catch (e) {
      _addLog("General Error ($name): $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _syncEverything() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });

    try {
      _addLog("=== STARTING FULL SYNC ===");

      // 1. ERPNext
      _addLog("--- Phase 1: ERPNext ---");
      await _runCombinedSync(
        "Doctors",
        widget.apiService.syncDoctors,
        widget.apiService.syncDoctorsPush,
      );
      await _runCombinedSync(
        "Medicines",
        widget.apiService.syncMedicines,
        widget.apiService.syncMedicinesPush,
      );
      await _runCombinedSync(
        "Patients",
        widget.apiService.syncPatients,
        widget.apiService.syncPatientsPush,
      );
      await _runCombinedSync(
        "Diseases",
        widget.apiService.syncDiseases,
        widget.apiService.syncDiseasesPush,
      );
      await _runCombinedSync(
        "Pharmacists",
        widget.apiService.syncPharmacists,
        widget.apiService.syncPharmacistsERPNextPush,
      );

      // 2. SatuSehat
      _addLog("--- Phase 2: SatuSehat ---");
      await _runCombinedSync(
        "SS Doctors",
        widget.apiService.syncSatuSehatDoctors,
        widget.apiService.syncSatuSehatDoctorsPush,
      );
      await _runCombinedSync(
        "SS Patients",
        widget.apiService.syncSatuSehatPatients,
        widget.apiService.syncSatuSehatPatientsPush,
      );
      await _runCombinedSync(
        "SS Pharmacists",
        () async => {"message": "No Pull for Pharmacists"},
        widget.apiService.syncPharmacistsPush,
      );

      _addLog("=== FULL SYNC COMPLETE ===");
    } catch (e) {
      _addLog("CRITICAL ERROR: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: 32),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade900,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        onPressed: _isLoading ? null : _syncEverything,
                        icon: _isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : Icon(Icons.sync, size: 32),
                        label: Text(
                          "SYNC ALL DATA (ERPNext + SatuSehat)",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  Text(
                    "Granular Sync (Optional)",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 16),

                  // ERPNext Section (Cards Only)
                  Text(
                    "ERPNext Resources",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildSyncCard(
                        "Doctors",
                        Icons.medical_services,
                        Colors.blue,
                        () => _runCombinedSync(
                          "Doctors",
                          widget.apiService.syncDoctors,
                          widget.apiService.syncDoctorsPush,
                        ),
                      ),
                      _buildSyncCard(
                        "Medicines",
                        Icons.medication,
                        Colors.green,
                        () => _runCombinedSync(
                          "Medicines",
                          widget.apiService.syncMedicines,
                          widget.apiService.syncMedicinesPush,
                        ),
                      ),
                      _buildSyncCard(
                        "Patients",
                        Icons.people,
                        Colors.orange,
                        () => _runCombinedSync(
                          "Patients",
                          widget.apiService.syncPatients,
                          widget.apiService.syncPatientsPush,
                        ),
                      ),
                      _buildSyncCard(
                        "Diseases",
                        Icons.coronavirus,
                        Colors.purple,
                        () => _runCombinedSync(
                          "Diseases",
                          widget.apiService.syncDiseases,
                          widget.apiService.syncDiseasesPush,
                        ),
                      ),
                      _buildSyncCard(
                        "Pharmacists",
                        Icons.local_pharmacy,
                        Colors.teal,
                        () => _runCombinedSync(
                          "Pharmacists",
                          widget.apiService.syncPharmacists,
                          widget.apiService.syncPharmacistsERPNextPush,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),
                  // SatuSehat Section (Cards Only)
                  Text(
                    "SatuSehat Resources",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildSyncCard(
                        "SS Doctors",
                        Icons.medical_services_outlined,
                        Colors.teal,
                        () => _runCombinedSync(
                          "SS Doctors",
                          widget.apiService.syncSatuSehatDoctors,
                          widget.apiService.syncSatuSehatDoctorsPush,
                        ),
                      ),
                      _buildSyncCard(
                        "SS Patients",
                        Icons.people_outline,
                        Colors.orangeAccent,
                        () => _runCombinedSync(
                          "SS Patients",
                          widget.apiService.syncSatuSehatPatients,
                          widget.apiService.syncSatuSehatPatientsPush,
                        ),
                      ),
                      _buildSyncCard(
                        "SS Pharmacists",
                        Icons.local_pharmacy_outlined,
                        Colors.tealAccent.shade700,
                        () => _runCombinedSync(
                          "SS Pharmacists",
                          () async => {
                            "message": "No Pull for Pharmacists",
                          }, // No Pull available/needed yet
                          widget.apiService.syncPharmacistsPush,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Divider(height: 32),
          Text("Sync Logs", style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Container(
            height: 120,
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (ctx, i) {
                return Text(
                  _logs[i],
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'monospace',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        child: Container(
          width: 200, // Reduced width slightly
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: _isLoading ? Colors.grey : color),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                "Pull & Push",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
