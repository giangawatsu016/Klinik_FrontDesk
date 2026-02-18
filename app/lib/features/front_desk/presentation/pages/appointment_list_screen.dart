import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Appointment {
  final String mrn;
  final String name;
  final String doctor;
  final String time;
  final String phone;

  Appointment({
    required this.mrn,
    required this.name,
    required this.doctor,
    required this.time,
    required this.phone,
  });
}

class AppointmentListScreen extends StatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Appointment> _allAppointments = [
    Appointment(
      mrn: '240211-001',
      name: 'Budi Santoso',
      doctor: 'Dr. Ruby Melinda',
      time: '09:00 AM',
      phone: '08123456789',
    ),
    Appointment(
      mrn: '240211-002',
      name: 'Siti Aminah',
      doctor: 'Dr. Andre Wijaya',
      time: '10:30 AM',
      phone: '08223456789',
    ),
    Appointment(
      mrn: '240211-003',
      name: 'Dewi Lestari',
      doctor: 'Dr. Sarah Smith',
      time: '11:00 AM',
      phone: '08323456789',
    ),
    Appointment(
      mrn: '240211-004',
      name: 'Joko Widodo',
      doctor: 'Dr. Ruby Melinda',
      time: '01:30 PM',
      phone: '08423456789',
    ),
    Appointment(
      mrn: '240211-005',
      name: 'Prabowo Subianto',
      doctor: 'Dr. Andre Wijaya',
      time: '02:00 PM',
      phone: '08523456789',
    ),
  ];
  List<Appointment> _filteredAppointments = [];

  @override
  void initState() {
    super.initState();
    _filteredAppointments = _allAppointments;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAppointments = _allAppointments.where((a) {
        return a.name.toLowerCase().contains(query) ||
            a.mrn.toLowerCase().contains(query) ||
            a.phone.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Today\'s Appointments',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Name, MRN, or Phone...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF2859E2)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredAppointments.isEmpty
                ? Center(
                    child: Text(
                      'No appointments found.',
                      style: GoogleFonts.outfit(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _filteredAppointments.length,
                    itemBuilder: (context, index) {
                      return _buildAppointmentCard(
                        context,
                        _filteredAppointments[index],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, Appointment appointment) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E7FF),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF2859E2),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.name,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'MRN: ${appointment.mrn} | ${appointment.doctor}',
                        style: GoogleFonts.outfit(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  appointment.time,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2859E2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusChip('Confirmed', Colors.green),
                ElevatedButton(
                  onPressed: () => _checkInPatient(context, appointment.name),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2859E2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Check-in',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _checkInPatient(BuildContext context, String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Checking in $name...'),
        backgroundColor: const Color(0xFF2859E2),
      ),
    );
  }
}
