import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/date_utils.dart'; // Ext
import '../../domain/entities/appointment_entity.dart';
import '../components/vital_sign_card.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MedicalRecordDetailPage extends StatelessWidget {
  final AppointmentEntity appointment;

  const MedicalRecordDetailPage({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    // Convert to WIB
    final appointmentDate = appointment.date.toWib();
    final theme = _getTimeTheme(appointmentDate);
    final clinicalRecord = appointment.clinicalRecord;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Medical Record',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 10.0,
                color: Colors.black.withValues(alpha: 0.5),
                offset: const Offset(0.0, 2.0),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildDynamicHeader(theme),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: FadeInUp(
                duration: const Duration(milliseconds: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Patient Snapshot Card
                    _buildPatientSnapshotCard(),
                    const SizedBox(height: 24),

                    if (clinicalRecord == null)
                      _buildEmptyClinicalState()
                    else ...[
                      // 2. Vital Signs
                      _buildSectionTitle('Vital Signs'),
                      const SizedBox(height: 12),
                      _buildVitalSignsGrid(clinicalRecord),
                      const SizedBox(height: 24),

                      // 3. Anamnesis
                      _buildSectionTitle('Anamnesis & History'),
                      const SizedBox(height: 12),
                      _buildAnamnesisSection(clinicalRecord),
                      const SizedBox(height: 24),

                      // 4. Diagnosis & Diseases
                      _buildSectionTitle('Diagnosis'),
                      const SizedBox(height: 12),
                      _buildDiagnosisSection(clinicalRecord),
                      const SizedBox(height: 24),

                      if (clinicalRecord['diseases'] != null &&
                          (clinicalRecord['diseases'] as List).isNotEmpty) ...[
                        _buildSectionTitle('Diseases'),
                        const SizedBox(height: 12),
                        _buildDiseasesSection(clinicalRecord['diseases']),
                        const SizedBox(height: 24),
                      ],

                      // 5. Medicines
                      _buildSectionTitle('Prescriptions'),
                      const SizedBox(height: 12),
                      _buildMedicinesSection(clinicalRecord),
                      const SizedBox(height: 24),

                      // 6. Doctor Notes & Recommendation
                      _buildSectionTitle('Doctor Notes & Recommendation'),
                      const SizedBox(height: 12),
                      _buildDoctorNotesSection(clinicalRecord),
                      const SizedBox(height: 24),

                      // 7. Supporting Files
                      if (clinicalRecord['supportingFiles'] != null) ...[
                        _buildSectionTitle('Supporting Files'),
                        const SizedBox(height: 12),
                        _buildSupportingFilesSection(
                          context,
                          clinicalRecord['supportingFiles'],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 8. Documents (Downloads) - HIDDEN BY USER REQUEST
                      // _buildSectionTitle('Documents'),
                      // const SizedBox(height: 12),
                      // _buildDocumentsSection(context, appointment),
                      // const SizedBox(height: 24),
                    ],

                    // 9. Service Info (Bottom)
                    // 9. Doctor Information
                    _buildDoctorInfoSection(),
                    const SizedBox(height: 24),

                    // 10. Service Info (Bottom)
                    _buildServiceInfoSection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientSnapshotCard() {
    final snapshot = appointment.patientSnapshot ?? appointment.patientDetail;
    final name =
        snapshot?['name'] ?? snapshot?['fullname'] ?? 'Unknown Patient';
    final age = snapshot?['age']; // Might be null for old records
    final gender = snapshot?['gender'] ?? '-';
    final location =
        snapshot?['address'] ?? appointment.patientDetail?['address'] ?? '-';
    final mrn =
        snapshot?['medicalRecordNumber'] ??
        appointment.patientDetail?['medicalRecordNumber'] ??
        '-';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF2859E2).withValues(alpha: 0.1),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'P',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2859E2),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'MRN: $mrn',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSnapshotItem(
                Icons.calendar_today_rounded,
                'Age',
                age != null ? '$age y.o' : 'N/A',
              ),
              _buildSnapshotItem(
                Icons.person_outline_rounded,
                'Gender',
                gender,
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _launchMaps(location),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchMaps(String address) async {
    final query = Uri.encodeComponent(address);
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    }
  }

  Widget _buildSnapshotItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVitalSignsGrid(Map<String, dynamic> record) {
    // Extract values
    final sysBP = record['systolicBP'];
    final diaBP = record['diastolicBP'];
    final hr = record['heartRate'];
    final temp = record['bodyTemperature'];
    final spo2 = record['oxygenSaturation'];
    final rr = record['respiratoryRate'];
    final weight = record['weight'];
    final height = record['height'];

    // Calculcate BMI if weight/height exists

    final cards = <Widget>[];

    if (sysBP != null && diaBP != null) {
      cards.add(
        VitalSignCard(
          title: 'Blood Pressure',
          value: '$sysBP/$diaBP',
          unit: 'mmHg',
          color: Colors.redAccent,
          icon: Icons.favorite_border_rounded,
        ),
      );
    }
    if (hr != null) {
      cards.add(
        VitalSignCard(
          title: 'Heart Rate',
          value: '$hr',
          unit: 'Bpm',
          color: Colors.red,
          icon: Icons.monitor_heart_outlined,
        ),
      );
    }
    if (temp != null) {
      cards.add(
        VitalSignCard(
          title: 'Temperature',
          value: '$temp',
          unit: '°C',
          color: Colors.orange,
          icon: Icons.thermostat_outlined,
        ),
      );
    }
    if (spo2 != null) {
      cards.add(
        VitalSignCard(
          title: 'SpO2',
          value: '$spo2',
          unit: '%',
          color: Colors.blue,
          icon: Icons.water_drop_outlined,
        ),
      );
    }
    if (rr != null) {
      cards.add(
        VitalSignCard(
          title: 'Respiratory',
          value: '$rr',
          unit: 'breaths/m',
          color: Colors.teal,
          icon: Icons.air_rounded,
        ),
      );
    }
    if (weight != null) {
      cards.add(
        VitalSignCard(
          title: 'Weight',
          value: '$weight',
          unit: 'kg',
          color: Colors.purple,
          icon: Icons.monitor_weight_outlined,
        ),
      );
    }
    if (height != null) {
      cards.add(
        VitalSignCard(
          title: 'Height',
          value: '$height',
          unit: 'cm',
          color: Colors.indigo,
          icon: Icons.height_rounded,
        ),
      );
    }

    // Fallback if no data
    if (cards.isEmpty) {
      return Center(
        child: Text(
          'No vital signs recorded',
          style: GoogleFonts.outfit(
            color: Colors.grey[400],
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards.map((card) {
            // 2 columns
            final width = (constraints.maxWidth - 12) / 2;
            return SizedBox(width: width, child: card);
          }).toList(),
        );
      },
    );
  }

  Widget _buildAnamnesisSection(Map<String, dynamic> record) {
    return _buildCard([
      _buildDetailRow('Chief Complaint', record['complaint'] ?? '-'),
      const Divider(height: 24),
      _buildDetailRow(
        'Medical History (Anamnesis)',
        record['anamnesis'] ?? '-',
      ),
      const Divider(height: 24),
      _buildDetailRow(
        'Allergies',
        record['allergy'] ?? 'None declared',
        customColor: Colors.redAccent,
      ),
    ]);
  }

  Widget _buildDiagnosisSection(Map<String, dynamic> record) {
    final diagnoses = record['diagnoses'] as List?;
    if (diagnoses == null || diagnoses.isEmpty) {
      return _buildCard([
        Text(
          'No diagnosis recorded',
          style: GoogleFonts.outfit(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ]);
    }

    return _buildCard(
      diagnoses.map<Widget>((d) {
        final name =
            d['diagnosisName'] ??
            d['diagnosis']?['name'] ??
            'Unknown Diagnosis';
        final code = d['diagnosisCode'] ?? d['diagnosis']?['code'] ?? '';
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  code,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDiseasesSection(List<dynamic> diseases) {
    return _buildCard(
      diseases.map<Widget>((d) {
        final name =
            d['diseaseName'] ?? d['disease']?['name'] ?? 'Unknown Disease';
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              const Icon(Icons.circle, size: 8, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMedicinesSection(Map<String, dynamic> record) {
    final medicines = record['medicines'] as List?;
    if (medicines == null || medicines.isEmpty) {
      return _buildCard([
        Text(
          'No medicines prescribed',
          style: GoogleFonts.outfit(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ]);
    }

    return Column(
      children: medicines.map<Widget>((m) {
        final name =
            m['medicineName'] ?? m['medicine']?['name'] ?? 'Unknown Medicine';
        final instructions = m['instructions'] ?? '-';
        final qty = m['quantity'] ?? 1;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medication_outlined,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      instructions,
                      style: GoogleFonts.outfit(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'x$qty',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDoctorNotesSection(Map<String, dynamic> record) {
    return _buildCard([
      _buildDetailRow('Doctor Notes', record['doctorNotes'] ?? '-'),
      const Divider(height: 24),
      _buildDetailRow(
        'Recommendation',
        record['action'] is List
            ? (record['action'] as List).join(', ')
            : (record['action'] ?? '-'),
      ),
    ]);
  }

  Widget _buildSupportingFilesSection(BuildContext context, dynamic files) {
    late List<String> fileList;

    if (files is String) {
      // Handle JSON array string like '["path1.png", "path2.png"]'
      String cleaned = files.trim();
      if (cleaned.startsWith('[') && cleaned.endsWith(']')) {
        // Remove brackets and split
        cleaned = cleaned.substring(1, cleaned.length - 1);
      }
      fileList = cleaned
          .split(',')
          .map((e) {
            // Remove quotes and extra whitespace
            String path = e.trim();
            if (path.startsWith('"') || path.startsWith("'")) {
              path = path.substring(1);
            }
            if (path.endsWith('"') || path.endsWith("'")) {
              path = path.substring(0, path.length - 1);
            }
            return path.trim();
          })
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (files is List) {
      fileList = files.map((e) => e.toString()).toList();
    } else {
      return const SizedBox.shrink();
    }

    if (fileList.isEmpty) return const SizedBox.shrink();

    // Get CDN URL from environment
    final cdnUrl = dotenv.env['DO_SPACES_CDN_URL'] ?? '';

    return Column(
      children: fileList.map((filePath) {
        // Construct the full URL
        String fileUrl;
        if (filePath.startsWith('http')) {
          fileUrl = filePath; // Already a full URL
        } else {
          fileUrl =
              '$cdnUrl/${filePath.startsWith('/') ? filePath.substring(1) : filePath}';
        }

        final fileName = fileUrl.split('/').last;
        final isImage =
            fileName.toLowerCase().endsWith('.jpg') ||
            fileName.toLowerCase().endsWith('.png') ||
            fileName.toLowerCase().endsWith('.jpeg');

        if (isImage) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Image.network(
                    fileUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey[200],
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              insetPadding: EdgeInsets.zero,
                              backgroundColor: Colors.black.withValues(
                                alpha: 0.8,
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  InteractiveViewer(
                                    child: Image.network(fileUrl),
                                  ),
                                  Positioned(
                                    top: 40,
                                    right: 20,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.fullscreen,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Tap to view',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: InkWell(
            onTap: () {
              // TODO: Handle non-image file download/view
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.insert_drive_file_outlined,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'View File',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fileName,
                          style: GoogleFonts.outfit(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2859E2).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_outward_rounded,
                      size: 16,
                      color: Color(0xFF2859E2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildServiceInfoSection() {
    return _buildCard([
      _buildSectionTitle('Service Information', fontSize: 14),
      const SizedBox(height: 12),
      _buildDetailRow('Service', appointment.serviceName),
      _buildDetailRow('Transaction ID', appointment.transactionNumber ?? '-'),
    ]);
  }

  Widget _buildDoctorInfoSection() {
    return _buildCard([
      Text(
        'Doctor Information',
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF2859E2),
        ),
      ),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Doctor Name',
            style: GoogleFonts.outfit(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            appointment.doctorName,
            style: GoogleFonts.outfit(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'SIP',
            style: GoogleFonts.outfit(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            appointment.doctorSip ?? '-',
            style: GoogleFonts.outfit(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ]);
  }

  Widget _buildCard(
    List<Widget> children, {
    EdgeInsets padding = const EdgeInsets.all(20),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  // ignore: unused_element
  Widget _buildDownloadRow(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2859E2)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: const Color(0xFF2859E2),
                ),
              ),
            ),
            const Icon(
              Icons.download_rounded,
              color: Color(0xFF2859E2),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? customColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: customColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {double fontSize = 16}) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildEmptyClinicalState() {
    return Container(
      padding: const EdgeInsets.all(30),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.medical_services_outlined,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No Clinical Record Yet',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The doctor has not submitted the medical record for this appointment.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicHeader(dynamic theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.gradientColors,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 60), // AppBar space
            Icon(
              theme.icon,
              size: 50,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            const SizedBox(height: 16),
            Text(
              theme.greeting,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              DateFormat('EEEE, dd MMMM yyyy').format(appointment.date),
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _TimeTheme _getTimeTheme(DateTime date) {
    final hour = date.hour;
    if (hour >= 5 && hour < 11) {
      return _TimeTheme(
        gradientColors: [const Color(0xFFFF9966), const Color(0xFFFF5E62)],
        icon: Icons.wb_sunny_rounded,
        greeting: 'Good Morning',
      );
    } else if (hour >= 11 && hour <= 15) {
      return _TimeTheme(
        gradientColors: [const Color(0xFF56CCF2), const Color(0xFF2F80ED)],
        icon: Icons.wb_sunny_outlined,
        greeting: 'Good Afternoon',
      );
    } else if (hour > 15 && hour <= 18) {
      return _TimeTheme(
        gradientColors: [const Color(0xFFf2709c), const Color(0xFFff9472)],
        icon: Icons.wb_twilight_rounded,
        greeting: 'Good Evening',
      );
    } else {
      return _TimeTheme(
        gradientColors: [const Color(0xFF2C3E50), const Color(0xFF4CA1AF)],
        icon: Icons.nights_stay_rounded,
        greeting: 'Good Night',
      );
    }
  }
}

class _TimeTheme {
  final List<Color> gradientColors;
  final IconData icon;
  final String greeting;

  _TimeTheme({
    required this.gradientColors,
    required this.icon,
    required this.greeting,
  });
}
