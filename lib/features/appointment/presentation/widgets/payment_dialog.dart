import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app/features/appointment/presentation/blocs/appointment_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PaymentDialog extends StatefulWidget {
  final String invoiceUrl;
  final String externalId;
  final int appointmentId;

  const PaymentDialog({
    super.key,
    required this.invoiceUrl,
    required this.externalId,
    required this.appointmentId,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  Timer? _timer;
  bool _isSimulating = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      context.read<AppointmentBloc>().add(GetAppointmentsRequested());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppointmentBloc, AppointmentState>(
      listener: (context, state) {
        if (state is AppointmentError) {
          setState(() => _isSimulating = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        }
        if (state is AppointmentsLoaded) {
          try {
            final appointment = state.appointments.firstWhere(
              (a) => a.id == widget.appointmentId, 
            );
            // Check for PAID or CONFIRMED (depending on backend logic)
            if (appointment.paymentStatus == 'PAID' || appointment.status == 'CONFIRMED') {
              _timer?.cancel();
              Navigator.of(context).pop(true); // Return true for success
            }
          } catch (_) {
            // Appointment not found in current loaded list, continue polling
          }
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Scan QRIS to Pay',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please scan the QR code below using your preferred e-wallet or banking app.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                width: 200,
                child: QrImageView(
                  data: widget.invoiceUrl,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(height: 8),
              const Text(
                'Waiting for payment...',
                style: TextStyle(fontSize: 12, color: Colors.blue),
              ),
              const SizedBox(height: 16),
              _isSimulating 
                ? const CircularProgressIndicator()
                : TextButton(
                    onPressed: () {
                       setState(() => _isSimulating = true);
                       context.read<AppointmentBloc>().add(SimulatePaymentRequested(widget.appointmentId));
                    },
                    child: const Text('Simulate Success (Dev)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _timer?.cancel();
                  Navigator.of(context).pop(false);
                },
                child: const Text('Cancel Payment', style: TextStyle(color: Colors.grey)),
              ),
              if (widget.externalId.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Ref: ${widget.externalId}', 
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
