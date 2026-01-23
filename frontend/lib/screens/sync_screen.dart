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
        if (pullRes['count'] != null)
          _addLog("Pulled Count: ${pullRes['count']}");
      } catch (e) {
        _addLog("Pull Error: $e");
      }

      // 2. PUSH
      _addLog("Pushing $name to ERPNext...");
      try {
        final pushRes = await pushFn();
        _addLog("Push Success: ${pushRes['message'] ?? pushRes['status']}");
        if (pushRes['count'] != null)
          _addLog("Pushed Count: ${pushRes['count']}");
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

  Future<void> _syncAll() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });

    _addLog("Starting Global Sync (Pull + Push)...");

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

    _addLog("Global Sync Complete.");
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sync, size: 32, color: Colors.blue),
              SizedBox(width: 16),
              Text(
                "ERPNext Data Synchronization",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          SizedBox(height: 24),
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

              SizedBox(width: 40),

              // Global Action
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                ),
                onPressed: _isLoading ? null : _syncAll,
                icon: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(Icons.sync_alt),
                label: Text("SYNC ALL DATA (Pull + Push)"),
              ),
            ],
          ),
          Divider(height: 48),
          Text("Sync Logs", style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Expanded(
            child: Container(
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
          width: 220,
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: _isLoading ? Colors.grey : color),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
