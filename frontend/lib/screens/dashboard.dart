import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
import 'pharmacist_list.dart';
import 'sync_screen.dart';
import 'home_screen.dart'; // New Kiosk Home
import 'menu_settings.dart';

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
        "page": HomeScreen(apiService: widget.apiService), // New Screen
        "icon": LucideIcons.layoutDashboard,
        "label": "Overview",
      },
      {
        "id": "queue",
        "page": QueueMonitorScreen(apiService: widget.apiService),
        "icon": LucideIcons.monitorPlay,
        "label": "Queue Monitor",
      },
      {
        "id": "registration",
        "page": RegistrationScreen(apiService: widget.apiService),
        "icon": LucideIcons.userPlus,
        "label": "Registration",
      },
      {
        "id": "doctors",
        "page": DoctorListScreen(apiService: widget.apiService),
        "icon": LucideIcons.stethoscope,
        "label": "Doctors",
      },
      {
        "id": "pharmacists",
        "page": PharmacistListScreen(apiService: widget.apiService),
        "icon": LucideIcons.contact,
        "label": "Pharmacy",
      },
      {
        "id": "patients",
        "page": PatientListScreen(apiService: widget.apiService),
        "icon": LucideIcons.users,
        "label": "Patients",
      },
      {
        "id": "medicines",
        "page": MedicineInventoryScreen(apiService: widget.apiService),
        "icon": LucideIcons.pill,
        "label": "Medicines",
      },

      {
        "id": "users",
        "page": UserManagementScreen(
          apiService: widget.apiService,
          currentUser: widget.user,
        ),
        "icon": LucideIcons.userCog,
        "label": "Users",
      },
      {
        "id": "diagnosis",
        "page": DiagnosticReportsScreen(apiService: widget.apiService),
        "icon": LucideIcons.fileText,
        "label": "Diagnosis",
      },
      {
        "id": "diseases",
        "page": DiseaseListScreen(apiService: widget.apiService),
        "icon": LucideIcons.bug,
        "label": "Diseases",
      },
      {
        "id": "sync",
        "page": SyncScreen(apiService: widget.apiService),
        "icon": LucideIcons.refreshCw,
        "label": "Sync Data",
      },
    ];

    final displayedPages = _filteredPages(allPages);

    if (_selectedIndex >= displayedPages.length) {
      _selectedIndex = 0;
    }

    final currentPage = displayedPages[_selectedIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // SIDEBAR
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          LucideIcons.activity,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Intimedicare",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            fontFamily: 'Inter',
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: displayedPages.length,
                    separatorBuilder: (ctx, i) => SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final item = displayedPages[index];
                      final isSelected = _selectedIndex == index;
                      return ListTile(
                        leading: Icon(
                          item['icon'] as IconData,
                          size: 22,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade400,
                        ),
                        title: Text(
                          item['label'] as String,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade600,
                            fontFamily: 'Inter',
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tileColor: isSelected
                            ? Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.05)
                            : null,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        onTap: () => setState(() => _selectedIndex = index),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: ListTile(
                    leading: const Icon(
                      LucideIcons.logOut,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                    title: const Text(
                      "Logout",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: _logout,
                    dense: true,
                  ),
                ),
                if (widget.user.role == "Super Admin")
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 24.0,
                      right: 24.0,
                      bottom: 24.0,
                    ),
                    child: ListTile(
                      leading: const Icon(
                        LucideIcons.settings,
                        color: Colors.grey,
                        size: 22,
                      ),
                      title: const Text(
                        "Dev Settings",
                        style: TextStyle(color: Colors.grey),
                      ),
                      onTap: _openSettings,
                      dense: true,
                    ),
                  ),
              ],
            ),
          ),

          // MAIN CONTENT
          Expanded(
            child: Column(
              children: [
                // Minimal Header
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Text(
                        currentPage['label'] as String,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Theme.of(context).primaryColor,
                              child: Text(
                                widget.user.username[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.user.username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  widget.user.role,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 11,
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
                    color: Colors.grey.shade50,
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

  List<String> _hiddenMenus = [];

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  void _loadConfig() async {
    final hidden = await widget.apiService.getHiddenMenus();
    if (mounted) setState(() => _hiddenMenus = hidden);
  }

  List<Map<String, dynamic>> _filteredPages(
    List<Map<String, dynamic>> allPages,
  ) {
    return allPages.where((item) {
      final id = item['id'] as String;
      final role = widget.user.role;

      // 1. Check Global Hidden Config
      if (_hiddenMenus.contains(id)) {
        return false;
      }

      // 2. Role Based Logic
      if (id == "queue" || id == "registration") {
        return role == "Staff";
      }
      if (id == "home") return true;
      if (id == "users") {
        return role == "Super Admin" || role == "Administrator";
      }
      if (id == "sync") {
        return role == "Administrator";
      }

      // Default allow for others unless specific role restrictions exist
      return true;
    }).toList();
  }

  void _logout() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MenuVisibilityScreen(apiService: widget.apiService),
      ),
    );
  }
}
