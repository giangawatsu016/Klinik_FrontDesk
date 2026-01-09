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
      appBar: AppBar(title: Text("Klinik Admin - ${widget.user.username}")),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Queue'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_add),
                label: Text('Registration'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.calendar_today),
                label: Text('Doctors'),
              ),
            ],
          ),
          VerticalDivider(thickness: 1, width: 1),
          Expanded(child: pages[_selectedIndex]),
        ],
      ),
    );
  }
}
