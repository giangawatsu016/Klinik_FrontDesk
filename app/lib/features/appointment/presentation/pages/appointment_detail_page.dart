import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/age_utils.dart';
import '../../../../core/utils/date_utils.dart'; // Ext
import '../../domain/entities/appointment_entity.dart';
import '../blocs/appointment_bloc.dart';
import '../../../front_desk/presentation/bloc/front_desk_bloc.dart';
import '../../../front_desk/presentation/bloc/front_desk_event.dart';
import '../../../front_desk/presentation/bloc/front_desk_state.dart';
import '../../../front_desk/data/models/queue_entry_model.dart';

class AppointmentDetailPage extends StatelessWidget {
  final AppointmentEntity appointment;

  const AppointmentDetailPage({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    // Convert to WIB first
    final appointmentDate = appointment.date.toWib();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Appointment Detail',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2859E2),
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSection('Informasi Dokter', [
                  _buildDetailRow(
                    'Nama Dokter',
                    '${appointment.doctorTitlePrefix ?? ''} ${appointment.doctorName} ${appointment.doctorTitleSuffix ?? ''}'
                        .trim(),
                  ),
                  if (appointment.doctorSip != null)
                    _buildDetailRow('Nomor SIP Dokter', appointment.doctorSip!),
                ]),
                const SizedBox(height: 20),
                _buildSection('Jadwal Kunjungan', [
                  _buildDetailRow(
                    'Tanggal',
                    DateFormat('EEEE, dd MMMM yyyy').format(appointmentDate),
                  ),
                  _buildDetailRow(
                    'Waktu',
                    '${DateFormat('HH:mm').format(appointmentDate)} WIB',
                  ),
                ]),
                if (appointment.patientDetail != null &&
                    appointment.patientDetail!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSection('Informasi Pasien', [
                    _buildDetailRow(
                      'Nama Pasien',
                      appointment.patientDetail!['patient_name']?.toString() ??
                          appointment.patientDetail!['name']?.toString() ??
                          '-',
                    ),
                    _buildDetailRow(
                      'Umur Pasien',
                      AgeUtils.formatAge(
                        appointment.patientDetail!['dob']?.toString(),
                      ),
                    ),
                    _buildDetailRow(
                      'Nomor HP Pasien',
                      appointment.patientDetail!['phone']?.toString() ?? '-',
                    ),
                    _buildDetailRow(
                      'Alamat',
                      appointment.patientDetail!['address']?.toString() ?? '-',
                      maxLines: 3,
                    ),
                  ]),
                ],
                const SizedBox(height: 30),
                // Add to Queue Button
                if (appointment.status.toUpperCase() == 'PENDING' &&
                    appointmentDate.year == DateTime.now().year &&
                    appointmentDate.month == DateTime.now().month &&
                    appointmentDate.day == DateTime.now().day)
                  BlocConsumer<FrontDeskBloc, FrontDeskState>(
                    listener: (context, state) {
                      if (state is FrontDeskSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Berhasil menambahkan ke antrean'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        // Optional: Navigate back to list
                        Navigator.pop(context);
                      } else if (state is FrontDeskError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.message),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: state is FrontDeskLoading
                                ? null
                                : () {
                                    final patientId =
                                        appointment.patientDetail?['name']
                                            ?.toString() ??
                                        '';
                                    final isDoctor =
                                        appointment.doctorName.isNotEmpty;
                                    final doctorId =
                                        appointment
                                            .patientDetail?['practitioner_id']
                                            ?.toString() ??
                                        appointment.doctorId?.toString();

                                    final queueEntry = QueueEntryModel(
                                      patient: patientId,
                                      queueType: isDoctor
                                          ? 'Doctor'
                                          : 'Polyclinic',
                                      practitioner: isDoctor ? doctorId : null,
                                      polyclinic: (!isDoctor)
                                          ? appointment.polyclinicId
                                          : null,
                                      appointment: appointment.id,
                                    );

                                    context.read<FrontDeskBloc>().add(
                                      AddToQueueEvent(queueEntry),
                                    );
                                  },
                            icon: state is FrontDeskLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.how_to_reg,
                                    color: Colors.white,
                                  ),
                            label: Text(
                              state is FrontDeskLoading
                                  ? 'Memproses...'
                                  : 'Masukkan ke Antrean',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2859E2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                // Cancel Appointment Button — only for today or future dates
                if (appointment.status.toUpperCase() == 'PENDING' &&
                    !DateTime(
                      appointmentDate.year,
                      appointmentDate.month,
                      appointmentDate.day,
                    ).isBefore(
                      DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        DateTime.now().day,
                      ),
                    ))
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showCancelConfirmation(context),
                      icon: const Icon(
                        Icons.cancel_outlined,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'Batalkan Janji Temu',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Batalkan Janji Temu?'),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan janji temu ini? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AppointmentBloc>().add(
                CancelAppointmentRequested(appointment.id),
              );
              Navigator.pop(context); // Back to list
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Janji temu sedang dibatalkan...'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text(
              'Ya, Batalkan',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2859E2),
            ),
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isStatus = false,
    bool isPrice = false,
    int maxLines = 1,
    Color? customColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.grey[500],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color:
                    customColor ??
                    (isStatus
                        ? _getStatusColor(value)
                        : (isPrice
                              ? const Color(0xFF2859E2)
                              : const Color(0xFF1A1D1E))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'CANCELLED':
        return Colors.red;
      case 'PAID':
        return const Color(0xFF2859E2);
      case 'IN_PROGRESS':
        return Colors.purple;
      default:
        return Colors.black87;
    }
  }
}
