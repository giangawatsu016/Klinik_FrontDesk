import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'registration.dart';
import 'queue_monitor.dart';
import 'login.dart';
import 'doctor_list.dart';
import 'patient_list.dart';
import 'user_management.dart';
import 'diagnostic_reports.dart';
import 'disease_list.dart';
import 'medicine_inventory.dart';
import 'sync_screen.dart';
import 'dashboard_home.dart';

class DashboardScreen extends StatefulWidget {
  final User user;
  final ApiService apiService;

  const DashboardScreen({
    super.key,
    required this.user,
    required this.apiService,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final allPages = [
      {
        "id": "home",
        "page": DashboardHomeScreen(apiService: widget.apiService),
        "icon": Icons.analytics_outlined,
        "selectedIcon": Icons.analytics,
        "label": "Overview",
      },
      {
        "id": "queue",
        "page": QueueMonitorScreen(apiService: widget.apiService),
        "icon": Icons.monitor_heart_outlined,
        "selectedIcon": Icons.monitor_heart,
        "label": "Queue Monitor",
      },
      {
        "id": "registration",
        "page": RegistrationScreen(apiService: widget.apiService),
        "icon": Icons.person_add_outlined,
        "selectedIcon": Icons.person_add,
        "label": "Registration",
      },
      {
        "id": "doctors",
        "page": DoctorListScreen(apiService: widget.apiService),
        "icon": Icons.medical_services_outlined,
        "selectedIcon": Icons.medical_services,
        "label": "Doctors",
      },
      {
        "id": "patients",
        "page": PatientListScreen(apiService: widget.apiService),
        "icon": Icons.people_outline,
        "selectedIcon": Icons.people,
        "label": "Patients",
      },
      {
        "id": "medicines",
        "page": MedicineInventoryScreen(apiService: widget.apiService),
        "icon": Icons.medication_outlined,
        "selectedIcon": Icons.medication,
        "label": "Medicines",
      },
      {
        "id": "users",
        "page": UserManagementScreen(
          apiService: widget.apiService,
          currentUser: widget.user,
        ),
        "icon": Icons.manage_accounts_outlined,
        "selectedIcon": Icons.manage_accounts,
        "label": "Users",
      },
      {
        "id": "diagnosis",
        "page": DiagnosticReportsScreen(apiService: widget.apiService),
        "icon": Icons.file_present_outlined,
        "selectedIcon": Icons.file_present,
        "label": "Diagnosis",
      },
      {
        "id": "diseases",
        "page": DiseaseListScreen(apiService: widget.apiService),
        "icon": Icons.coronavirus_outlined,
        "selectedIcon": Icons.coronavirus,
        "label": "Diseases",
      },
      {
        "id": "sync",
        "page": SyncScreen(apiService: widget.apiService),
        "icon": Icons.sync_outlined,
        "selectedIcon": Icons.sync,
        "label": "Sync Data",
      },
    ];

    // Filter based on Role
    final filteredPages = allPages.where((item) {
      final id = item['id'] as String;
      final role = widget.user.role;

      if (id == "queue" || id == "registration") {
        return role == "Staff"; // Only Staff see practical tools
      }

      if (id == "home") {
        return true;
      }

      if (id == "users" || id == "sync") {
        return role == "Super Admin" || role == "Administrator";
      }

      // Doctors, Patients, Medicines, Diagnosis
      if (["doctors", "patients", "medicines", "diagnosis"].contains(id)) {
        return role != "Super Admin";
      }

      return true;
    }).toList();

    if (_selectedIndex >= filteredPages.length) {
      _selectedIndex = 0;
    }

    final currentPage = filteredPages[_selectedIndex];

    return Scaffold(
      body: Row(
        children: [
          // SIDEBAR
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.local_hospital,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Klinik Admin",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                    itemCount: filteredPages.length,
                    itemBuilder: (context, index) {
                      final item = filteredPages[index];
                      final isSelected = _selectedIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: ListTile(
                          leading: Icon(
                            isSelected
                                ? (item['selectedIcon'] as IconData)
                                : (item['icon'] as IconData),
                            color: isSelected
                                ? Colors.blue.shade700
                                : Colors.grey.shade600,
                          ),
                          title: Text(
                            item['label'] as String,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? Colors.blue.shade700
                                  : Colors.grey.shade700,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          tileColor: isSelected ? Colors.blue.shade50 : null,
                          onTap: () => setState(() => _selectedIndex = index),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      "Logout",
                      style: TextStyle(color: Colors.red),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: _logout,
                  ),
                ),
              ],
            ),
          ),

          // MAIN CONTENT
          Expanded(
            child: Column(
              children: [
                // HEADER
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        currentPage['label'] as String,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.blue.shade700,
                              child: Text(
                                widget.user.username[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.user.username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  widget.user.role,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors
                        .grey
                        .shade50, // Light gray background for content
                    child: currentPage['page'] as Widget,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _logout() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen()));
  }
}
