import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  final ApiService apiService;
  const HomeScreen({super.key, required this.apiService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _activeQueue = 0;
  int _doctorsAvailable = 0;
  bool _isLoading = true;

  List<Doctor> _idleDoctors = [];
  bool _showIdleList = false;
  bool _isLoadingIdle = false;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  void _fetchStats() async {
    try {
      final data = await widget.apiService.getDashboardOverview();
      if (mounted) {
        setState(() {
          _activeQueue = data['active_queue'] ?? 0;
          _doctorsAvailable = data['doctors_available'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error fetching stats: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 32),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _buildStatsRow(context),

              if (_showIdleList) ...[
                SizedBox(height: 24),
                Text(
                  "Active Idle Doctors",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: _isLoadingIdle
                      ? Center(child: CircularProgressIndicator())
                      : _idleDoctors.isEmpty
                      ? Center(child: Text("No available doctors found."))
                      : ListView.separated(
                          itemCount: _idleDoctors.length,
                          separatorBuilder: (c, i) => Divider(height: 1),
                          itemBuilder: (context, index) {
                            final doctor = _idleDoctors[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.shade50,
                                child: Icon(
                                  LucideIcons.stethoscope,
                                  color: Colors.green,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                "${doctor.gelarDepan} ${doctor.namaDokter}",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(doctor.polyName),
                              contentPadding: EdgeInsets.zero,
                            );
                          },
                        ),
                ),
              ] else
                Spacer(),

              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            LucideIcons.activity,
            size: 32,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Klinik Intimedicare',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            Text(
              'Front Desk & Queue System',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildStatusCard('Queue', '$_activeQueue', Colors.blue),
        const SizedBox(width: 16),
        _buildStatusCard(
          'Doctors',
          '$_doctorsAvailable Active',
          Colors.green,
          onTap: _showIdleDoctors,
        ),
      ],
    );
  }

  Widget _buildStatusCard(
    String label,
    String value,
    Color color, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showIdleDoctors() async {
    // Toggle
    if (_showIdleList) {
      setState(() => _showIdleList = false);
      return;
    }

    setState(() {
      _showIdleList = true;
      _isLoadingIdle = true;
    });

    try {
      final doctors = await widget.apiService.getIdleDoctors();
      if (mounted) {
        setState(() {
          _idleDoctors = doctors;
          _isLoadingIdle = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingIdle = false;
          _showIdleList = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Widget _buildFooter() {
    return const Center(
      child: Text(
        'v1.0.0 • Connected to Klinik Intimedicare Server',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}
