import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DashboardHomeScreen extends StatelessWidget {
  final ApiService apiService;

  const DashboardHomeScreen({super.key, required this.apiService});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: apiService.getDashboardOverview(),
      builder: (context, snapshot) {
        // Defaults while loading or if error
        String totalPatients = "...";
        String doctorsAvailable = "...";
        List<Map<String, dynamic>> recentActivity = [];

        if (snapshot.hasData) {
          final data = snapshot.data!;
          totalPatients = data['total_patients'].toString();
          doctorsAvailable = data['doctors_available'].toString();

          recentActivity = List<Map<String, dynamic>>.from(
            data['recent_activity'] ?? [],
          );
        }

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Overview",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              // Stats Row
              Row(
                children: [
                  _buildStatCard(
                    context,
                    title: "Total Patients",
                    value: totalPatients,
                    icon: Icons.people_outline,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    context,
                    title: "Doctors Available",
                    value: doctorsAvailable,
                    icon: Icons.medical_services_outlined,
                    color: Colors.green.shade600,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Recent Activity List
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Recent Activity",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (recentActivity.isEmpty)
                        Expanded(
                          child: Center(
                            child: Text(
                              "No recent activity",
                              style: TextStyle(color: Colors.grey.shade400),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            itemCount: recentActivity.length,
                            separatorBuilder: (context, index) =>
                                const Divider(),
                            itemBuilder: (context, index) {
                              final activity = recentActivity[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade50,
                                  child: Icon(
                                    Icons.person_outline,
                                    color: Colors.blue.shade600,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  activity['description'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  activity['time'],
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                                trailing: _buildStatusBadge(activity['status']),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case "Waiting":
        color = Colors.orange;
        break;
      case "In Consultation":
        color = Colors.blue;
        break;
      case "Completed":
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                // Removed "+2.5%" hardcoded text, can add back if we have difference calculation
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
