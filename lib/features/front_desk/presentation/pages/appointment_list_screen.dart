import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppointmentListScreen extends StatelessWidget {
  const AppointmentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // In a real app, this would fetch from a specific AppointmentBloc or the shared FrontDeskBloc
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
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: 5, // Mock data for now
        itemBuilder: (context, index) {
          return _buildAppointmentCard(context, index);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, int index) {
    final names = [
      'Budi Santoso',
      'Siti Aminah',
      'Dewi Lestari',
      'Joko Widodo',
      'Prabowo Subianto',
    ];
    final doctors = [
      'Dr. Ruby Melinda',
      'Dr. Andre Wijaya',
      'Dr. Sarah Smith',
      'Dr. Ruby Melinda',
      'Dr. Andre Wijaya',
    ];
    final times = ['09:00 AM', '10:30 AM', '11:00 AM', '01:30 PM', '02:00 PM'];

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
                        names[index],
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        doctors[index],
                        style: GoogleFonts.outfit(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Text(
                  times[index],
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
                  onPressed: () => _checkInPatient(context, names[index]),
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
    // Implementation for converting appointment to queue
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Checking in $name...'),
        backgroundColor: const Color(0xFF2859E2),
      ),
    );
  }
}
