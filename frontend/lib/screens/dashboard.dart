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
import 'pharmacy_list.dart';
import 'sync_screen.dart';

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
    // Define all possible pages
    final allPages = [
      {
        "id": "dashboard",
        "page": QueueMonitorScreen(apiService: widget.apiService),
        "icon": Icons.dashboard_outlined,
        "selectedIcon": Icons.dashboard,
        "label": "Dashboard",
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
        "id": "pharmacy",
        "page": PharmacyListScreen(apiService: widget.apiService),
        "icon": Icons.local_pharmacy_outlined,
        "selectedIcon": Icons.local_pharmacy,
        "label": "Pharmacy",
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
        "icon": Icons.analytics_outlined,
        "selectedIcon": Icons.analytics,
        "label": "Diagnosis",
      },
      {
        "id": "diseases",
        "page": DiseaseListScreen(apiService: widget.apiService),
        "icon": Icons.local_hospital_outlined,
        "selectedIcon": Icons.local_hospital,
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
      final role = widget.user.role; // "Super Admin", "Administrator", "Staff"

      if (id == "dashboard") {
        // Only Staff can see Dashboard (Queue Monitor)
        return role == "Staff";
      }

      if (id == "registration") {
        // Only Staff can see Registration
        return role == "Staff";
      }

      if (id == "users") {
        // Only Super Admin and Administrator can see Users
        return role == "Super Admin" || role == "Administrator";
      }

      // Doctors, Patients, Medicines, Diagnosis
      if (["doctors", "patients", "medicines", "diagnosis"].contains(id)) {
        // Not visible to Super Admin (who only sees Users)
        return role != "Super Admin";
      }

      if (id == "sync") {
        return role == "Super Admin" || role == "Administrator";
      }

      return true;
    }).toList();

    // Safety check for index
    if (_selectedIndex >= filteredPages.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      backgroundColor: Colors.blue.shade100, // Matching gradient start
      // extendBodyBehindAppBar: true, // Removed to prevent overlap
      appBar: AppBar(
        title: Text(
          "Klinik Admin - ${widget.user.username} (${widget.user.role})",
          style: TextStyle(
            color: Colors.blue.shade900,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.blue.shade900),
        backgroundColor: Colors.blue.shade100, // Solid color
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade100, Colors.purple.shade100],
          ),
        ),
        child: Row(
          children: [
            NavigationRail(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              selectedLabelTextStyle: TextStyle(
                color: Colors.blue.shade900,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelTextStyle: TextStyle(color: Colors.blue.shade700),
              selectedIconTheme: IconThemeData(color: Colors.blue.shade900),
              unselectedIconTheme: IconThemeData(color: Colors.blue.shade700),
              destinations: filteredPages.map((item) {
                return NavigationRailDestination(
                  icon: Icon(item['icon'] as IconData),
                  selectedIcon: Icon(item['selectedIcon'] as IconData),
                  label: Text(item['label'] as String),
                );
              }).toList(),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: IconButton(
                      icon: Icon(Icons.logout, color: Colors.red.shade700),
                      onPressed: _logout,
                      tooltip: 'Logout',
                    ),
                  ),
                ),
              ),
            ),
            VerticalDivider(
              thickness: 1,
              width: 1,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            Expanded(child: filteredPages[_selectedIndex]['page'] as Widget),
          ],
        ),
      ),
    );
  }

  void _logout() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen()));
  }
}
