import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'registration.dart';
import 'queue_monitor.dart';

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
    final List<Widget> pages = [
      QueueMonitorScreen(apiService: widget.apiService),
      RegistrationScreen(apiService: widget.apiService),
      Center(child: Text("Doctor Schedule (Coming Soon)")),
    ];

    return Scaffold(
      backgroundColor:
          Colors.transparent, // Let gradient show through (if scaffold wrapped)
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Klinik Admin - ${widget.user.username}",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        elevation: 0,
        centerTitle: true,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
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
              destinations: [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_add_outlined),
                  selectedIcon: Icon(Icons.person_add),
                  label: Text('Registration'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.calendar_today_outlined),
                  selectedIcon: Icon(Icons.calendar_today),
                  label: Text('Doctors'),
                ),
              ],
            ),
            VerticalDivider(
              thickness: 1,
              width: 1,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            Expanded(child: pages[_selectedIndex]),
          ],
        ),
      ),
    );
  }
}
