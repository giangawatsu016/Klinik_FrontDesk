import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/date_utils.dart'; // Ext
import '../../domain/entities/appointment_entity.dart';
import '../blocs/appointment_bloc.dart';

class AppointmentDetailPage extends StatelessWidget {
  final AppointmentEntity appointment;

  const AppointmentDetailPage({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    // Convert to WIB first
    final appointmentDate = appointment.date.toWib();
    final theme = _getTimeTheme(appointmentDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Appointment Detail',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
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
            // Dynamic Header Animation
            _buildDynamicHeader(theme),

            Padding(
              padding: const EdgeInsets.all(24),
              child: FadeInUp(
                duration: const Duration(milliseconds: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    _buildSection('Service Information', [
                      _buildDetailRow('Service Name', appointment.serviceName),
                      _buildDetailRow(
                        'Transaction ID',
                        appointment.transactionNumber ?? '-',
                      ),
                      _buildDetailRow(
                        'Status',
                        appointment.status,
                        isStatus: true,
                      ),
                    ]),
                    const SizedBox(height: 20),
                    _buildSection('Doctor Information', [
                      _buildDetailRow(
                        'Doctor Name',
                        '${appointment.doctorTitlePrefix ?? ''} ${appointment.doctorName} ${appointment.doctorTitleSuffix ?? ''}'
                            .trim(),
                      ),
                      if (appointment.doctorSip != null)
                        _buildDetailRow('SIP', appointment.doctorSip!),
                    ]),
                    const SizedBox(height: 20),
                    _buildSection('Schedule', [
                      _buildDetailRow(
                        'Date',
                        DateFormat(
                          'EEEE, dd MMMM yyyy',
                        ).format(appointmentDate),
                      ),
                      _buildDetailRow(
                        'Time',
                        '${DateFormat('HH:mm').format(appointmentDate)} WIB',
                      ),
                    ]),
                    const SizedBox(height: 20),
                    _buildSection('Payment', [
                      // Advanced Breakdown (if available)
                      if (appointment.serviceFee != null ||
                          appointment.consultationFee != null ||
                          (appointment.items != null &&
                              appointment.items!.isNotEmpty)) ...[
                        Text(
                          'PRICE AT BOOKING',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFD97706),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (appointment.serviceFee != null)
                          _buildDetailRow(
                            'Service Fee',
                            NumberFormat.currency(
                              locale: 'id',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(appointment.serviceFee),
                            isPrice: true,
                          ),
                        if (appointment.consultationFee != null)
                          _buildDetailRow(
                            'Consultation Fee',
                            NumberFormat.currency(
                              locale: 'id',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(appointment.consultationFee),
                            isPrice: true,
                          ),
                        if (appointment.transportFee != null)
                          _buildDetailRow(
                            'Transport Fee',
                            NumberFormat.currency(
                              locale: 'id',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(appointment.transportFee),
                            isPrice: true,
                          ),

                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Text(
                          'PACKAGE ITEMS',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFD97706),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (appointment.items != null)
                          ...appointment.items!.map((item) {
                            return _buildDetailRow(
                              '• ${item['name'] ?? 'Item'} x${item['quantity'] ?? 1}',
                              NumberFormat.currency(
                                locale: 'id',
                                symbol: 'Rp ',
                                decimalDigits: 0,
                              ).format(item['price'] ?? 0),
                              isPrice: true,
                            );
                          }),

                        const SizedBox(height: 8),
                        const Divider(height: 1, color: Colors.grey),
                        const SizedBox(height: 8),
                      ],

                      // Show Subtotal if there is a discount
                      if (appointment.discount != null &&
                          appointment.discount! > 0)
                        _buildDetailRow(
                          'Subtotal',
                          NumberFormat.currency(
                            locale: 'id',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(
                            (appointment.finalPrice +
                                (appointment.discount ?? 0)),
                          ),
                          isPrice: false,
                        ),

                      // Show Discount
                      if (appointment.discount != null &&
                          appointment.discount! > 0)
                        _buildDetailRow(
                          'Discount${appointment.discountName != null ? ' (${appointment.discountName})' : ''}',
                          '- ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(appointment.discount)}',
                          isPrice: true,
                          customColor: Colors.red, // Green or Red for discount
                        ),

                      _buildDetailRow(
                        'Total Price',
                        NumberFormat.currency(
                          locale: 'id',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(appointment.finalPrice),
                        isPrice: true,
                        customColor: const Color(0xFFFF5EFA),
                      ),
                      if (appointment.paymentStatus != null)
                        _buildDetailRow(
                          'Payment Status',
                          appointment.paymentStatus!.toUpperCase(),
                          isStatus: true,
                        ),

                      // Pay Now Button - Moved inside the Payment section for better visibility
                      if (appointment.status.toUpperCase() == 'PENDING' ||
                          appointment.paymentStatus?.toUpperCase() ==
                              'PENDING') ...[
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              context.read<AppointmentBloc>().add(
                                SimulatePaymentRequested(appointment.id),
                              );
                              Navigator.pop(
                                context,
                              ); // Go back to list to refresh
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Simulating Payment...'),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2859E2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Pay Now',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ]),
                    if (appointment.patientDetail != null &&
                        appointment.patientDetail!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildSection('Patient Details', [
                        _buildDetailRow(
                          'Name',
                          appointment.patientDetail!['name']?.toString() ?? '-',
                        ),
                        _buildDetailRow(
                          'Phone',
                          appointment.patientDetail!['phone']?.toString() ??
                              '-',
                        ),
                        _buildDetailRow(
                          'Address',
                          appointment.patientDetail!['address']?.toString() ??
                              '-',
                          maxLines: 3,
                        ),
                      ]),
                    ],
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

  Widget _buildDynamicHeader(_TimeTheme theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
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
        boxShadow: [
          BoxShadow(
            color: theme.gradientColors.first.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Center content
        children: [
          const SizedBox(height: 60), // Space for AppBar
          Pulse(
            infinite: true,
            duration: const Duration(seconds: 3),
            child: Icon(theme.icon, size: 60, color: Colors.white),
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
          const SizedBox(height: 4),
          Text(
            'Your appointment is scheduled',
            style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
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

  _TimeTheme _getTimeTheme(DateTime date) {
    final hour = date.hour;
    // Pagi: 05:00 - 10:59
    if (hour >= 5 && hour < 11) {
      return _TimeTheme(
        gradientColors: [const Color(0xFFFF9966), const Color(0xFFFF5E62)],
        icon: Icons.wb_sunny_rounded,
        greeting: 'Good Morning!',
      );
    }
    // Siang: 11:00 - 15:00
    else if (hour >= 11 && hour <= 15) {
      return _TimeTheme(
        gradientColors: [const Color(0xFF56CCF2), const Color(0xFF2F80ED)],
        icon: Icons.wb_sunny_outlined,
        greeting: 'Good Afternoon!',
      );
    }
    // Sore: 15:01 - 18:00
    else if (hour > 15 && hour <= 18) {
      return _TimeTheme(
        gradientColors: [const Color(0xFFf2709c), const Color(0xFFff9472)],
        icon: Icons.wb_twilight_rounded,
        greeting: 'Good Evening!',
      );
    }
    // Malam: 18:01 - 04:59
    else {
      return _TimeTheme(
        gradientColors: [const Color(0xFF2C3E50), const Color(0xFF4CA1AF)],
        icon: Icons.nights_stay_rounded,
        greeting: 'Have a Good Night',
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
