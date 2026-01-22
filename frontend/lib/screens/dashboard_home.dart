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
        String queueToday = "...";

        if (snapshot.hasData) {
          final data = snapshot.data!;
          totalPatients = data['total_patients'].toString();
          doctorsAvailable = data['doctors_available'].toString();
          queueToday = data['queue_today'].toString();
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
                  const SizedBox(width: 16),
                  _buildStatCard(
                    context,
                    title: "Queue Today",
                    value: queueToday,
                    icon: Icons.chair_alt_outlined,
                    color: Colors.orange.shade600,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Placeholder for Chart or Recent Activity
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
                      Expanded(
                        child: Center(
                          child: Text(
                            "Chart Visualization Placeholder",
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
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
