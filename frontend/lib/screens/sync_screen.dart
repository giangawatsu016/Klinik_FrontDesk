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

  Future<void> _runSync(
    String name,
    Future<Map<String, dynamic>> Function() syncFn,
  ) async {
    setState(() => _isLoading = true);
    _addLog("Starting $name Sync...");

    try {
      final result = await syncFn();
      _addLog("Success: ${result['message'] ?? result['status'] ?? 'OK'}");
      if (result['count'] != null) {
        _addLog("Synced Count: ${result['count']}");
      }
    } catch (e) {
      _addLog("Error ($name): $e");
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

    await _runSync("Doctors", widget.apiService.syncDoctors);
    await _runSync("Medicines", widget.apiService.syncMedicines);
    await _runSync("Patients", widget.apiService.syncPatients);

    _addLog("Sync All Complete.");
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
                "Sync Doctors",
                Icons.medical_services,
                Colors.blue,
                () => _runSync("Doctors", widget.apiService.syncDoctors),
              ),
              _buildSyncCard(
                "Sync Medicines",
                Icons.medication,
                Colors.green,
                () => _runSync("Medicines", widget.apiService.syncMedicines),
              ),
              _buildSyncCard(
                "Sync Patients",
                Icons.people,
                Colors.orange,
                () => _runSync("Patients", widget.apiService.syncPatients),
              ),
              SizedBox(width: 40), // Spacer
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // Standardized
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
                label: Text("SYNC ALL DATA"),
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
      // Elevation 0 from Theme
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        child: Container(
          width: 200,
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: _isLoading ? Colors.grey : color),
              SizedBox(height: 12),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                "Pull from ERPNext",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
