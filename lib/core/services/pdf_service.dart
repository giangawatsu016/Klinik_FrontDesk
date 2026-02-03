import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../features/appointment/domain/entities/appointment_entity.dart';
import '../utils/logger.dart';

class PdfService {
  static const PdfColor primaryColor = PdfColor.fromInt(0xFF2859E2);

  /// Load logo from assets
  Future<Uint8List> _loadLogo() async {
    final byteData = await rootBundle.load(
      'assets/images/logo-intimedicare.png',
    );
    return byteData.buffer.asUint8List();
  }

  /// Load network image (signature)
  Future<Uint8List?> _loadNetworkImage(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final dio = Dio();
      final response = await dio.get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.statusCode == 200) {
        return response
            .data; // response.data is Uint8List when ResponseType.bytes
      }
    } catch (e) {
      AppLogger.error('Error loading image', e);
    }
    return null;
  }

  /// Header Component
  pw.Widget _buildHeader(pw.Context context, Uint8List? logo) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (logo != null)
              pw.Container(
                width: 60,
                height: 60,
                child: pw.Image(pw.MemoryImage(logo)),
              ),
            pw.SizedBox(width: 15),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'KLINIK PRATAMA INTIMEDICARE',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Komplek Aldiron Hero Blok E No.3 A, Jalan Raya Daan Mogot, RT06/RW05',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.Text(
                    'Duri Kepa, Kebon Jeruk, Jakarta Barat, DKI Jakarta, 11510',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.Text(
                    'Tlpn. 087778102233',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 10),
      ],
    );
  }

  /// Generate Prescription PDF
  Future<Uint8List> generatePrescription(AppointmentEntity appointment) async {
    final doc = pw.Document();
    final logo = await _loadLogo();

    // Doctor Info
    final doctorName =
        '${appointment.doctorTitlePrefix ?? ''} ${appointment.doctorName} ${appointment.doctorTitleSuffix ?? ''}'
            .trim();
    final sip = appointment.doctorSip ?? '....................';

    // Calculate Age
    String age = '-';
    if (appointment.patientDetail != null &&
        appointment.patientDetail!['birthday'] != null) {
      try {
        final dob = DateTime.parse(appointment.patientDetail!['birthday']);
        final now = DateTime.now();
        final years = now.year - dob.year;
        age = '$years Tahun';
      } catch (_) {}
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(context, logo),

              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  'RESEP DOKTER',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),

              pw.SizedBox(height: 20),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Jakarta, ${DateFormat('d MMMM yyyy', 'id_ID').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),

              pw.SizedBox(height: 20),
              pw.Text(
                'R/',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 10),

              // Medicines List
              if (appointment.clinicalRecord != null &&
                  appointment.clinicalRecord!['medicines'] != null)
                ...((appointment.clinicalRecord!['medicines'] as List).map((m) {
                  final item = m['medicine']?['item'];
                  final name = item?['name'] ?? m['name'] ?? 'Unknown Medicine';
                  final qty = m['quantity'] ?? 1;
                  final instructions =
                      m['instructions'] ??
                      '-'; // Note: instructions might not be in the map if not selected in GQL

                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 12),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              name,
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              'S $instructions',
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                        pw.Text(
                          'No. $qty',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                })),

              pw.Spacer(),

              // Signature
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    children: [
                      pw.Text(
                        doctorName,
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.Container(
                        width: 150,
                        height: 1,
                        color: PdfColors.black,
                      ),
                      pw.Text(
                        'SIP. $sip',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 40),

              // Patient Info Footer
              pw.Divider(),
              pw.Row(
                children: [
                  pw.Container(
                    width: 80,
                    child: pw.Text(
                      'Nama',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                  pw.Text(
                    ': ${appointment.patientDetail?['fullname'] ?? '-'}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.Row(
                children: [
                  pw.Container(
                    width: 80,
                    child: pw.Text(
                      'Umur',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                  pw.Text(': $age', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Row(
                children: [
                  pw.Container(
                    width: 80,
                    child: pw.Text(
                      'Alamat',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                  pw.Text(
                    ': ${appointment.patientDetail?['address'] ?? '-'}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Text(
                'Resep tidak berlaku jika tidak ada stempel klinik atau stempel dokter.',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  /// Generate Informed Consent PDF
  Future<Uint8List> generateInformedConsent(
    AppointmentEntity appointment,
  ) async {
    final doc = pw.Document();
    final logo = await _loadLogo();

    final record = appointment.clinicalRecord;
    final consent = record?['informConsent'];

    // Doctor & Patient Info
    final doctorName =
        '${appointment.doctorTitlePrefix ?? ''} ${appointment.doctorName} ${appointment.doctorTitleSuffix ?? ''}'
            .trim();
    final patientName = appointment.patientDetail?['fullname'] ?? '-';

    // Signatures
    final patientSig = await _loadNetworkImage(consent?['patientSignatureUrl']);
    final doctorSig = await _loadNetworkImage(
      consent?['doctorSignatureUrl'] ?? record?['signatureUrl'],
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(context, logo),
              pw.Center(
                child: pw.Text(
                  'PERSETUJUAN TINDAKAN MEDIK',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              pw.Text(
                'Saya yang bertanda tangan di bawah ini:',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 10),

              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 20),
                child: pw.Column(
                  children: [
                    pw.Row(
                      children: [
                        pw.Container(width: 100, child: pw.Text('Nama')),
                        pw.Text(': $patientName'),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Container(width: 100, child: pw.Text('Alamat')),
                        pw.Text(
                          ': ${appointment.patientDetail?['address'] ?? '-'}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 15),
              pw.Text(
                'Menyatakan SETUJU untuk dilakukan tindakan medis:',
                style: const pw.TextStyle(fontSize: 10),
              ),

              if (record != null &&
                  record['diagnoses'] != null &&
                  (record['diagnoses'] as List).isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Text(
                    'Diagnosis: ${(record['diagnoses'] as List).map((d) => d['diagnosis']['description']).join(', ')}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),

              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Text(
                        'Pasien',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 5),
                      if (patientSig != null)
                        pw.Container(
                          height: 40,
                          width: 80,
                          child: pw.Image(pw.MemoryImage(patientSig)),
                        )
                      else
                        pw.SizedBox(height: 40),
                      pw.Text(
                        patientName,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text(
                        'Dokter Pemeriksa',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 5),
                      if (doctorSig != null)
                        pw.Container(
                          height: 40,
                          width: 80,
                          child: pw.Image(pw.MemoryImage(doctorSig)),
                        )
                      else
                        pw.SizedBox(height: 40),
                      pw.Text(
                        doctorName,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );

    return doc.save();
  }
}
