import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../blocs/payment_cubit.dart';
import '../../domain/entities/payment_entity.dart';

class PaymentBookPage extends StatefulWidget {
  const PaymentBookPage({super.key});

  @override
  State<PaymentBookPage> createState() => _PaymentBookPageState();
}

class _PaymentBookPageState extends State<PaymentBookPage> {
  @override
  void initState() {
    super.initState();
    // Fetch all PAID payments from the new Payment table
    context.read<PaymentCubit>().getAllPayments(status: 'PAID');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction History',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1D1E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track all your medical service payments here',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildPaymentList(),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: const Color(0xFFF8FAFF).withValues(alpha: 0.8),
      elevation: 0,
      title: Text(
        'Payment Book',
        style: GoogleFonts.outfit(
          color: const Color(0xFF1A1D1E),
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1D1E)),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildPaymentList() {
    return BlocBuilder<PaymentCubit, PaymentState>(
      builder: (context, state) {
        if (state is PaymentLoading) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is PaymentsLoaded) {
          if (state.payments.isEmpty) {
            return SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_rounded, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No transactions yet',
                      style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final payment = state.payments[index];
                return _buildPaymentCard(payment, index);
              },
              childCount: state.payments.length,
            ),
          );
        }

        if (state is PaymentError) {
          return SliverFillRemaining(
            child: Center(child: Text(state.message)),
          );
        }

        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    );
  }

  Widget _buildPaymentCard(PaymentEntity payment, int index) {
    final appt = payment.appointment;
    final hasDiscount = (appt?.discountAmount ?? 0) > 0;
    
    return FadeInUp(
      delay: Duration(milliseconds: index < 5 ? index * 50 : 0),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF2859E2)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appt?.serviceName ?? payment.description ?? 'Payment',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1D1E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (appt?.transactionNumber != null)
                        Text(
                          appt!.transactionNumber!,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: const Color(0xFF2859E2),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      Text(
                        '${DateFormat('dd MMM yyyy • HH:mm').format(payment.createdAt.toLocal())} WIB',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(payment.status),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            // Price Summary
            Column(
              children: [
                _buildPriceRow(
                  'Price Before Discount',
                  appt?.originalPrice ?? payment.amount,
                  isOriginal: hasDiscount,
                ),
                if (hasDiscount) ...[
                  const SizedBox(height: 8),
                  _buildDiscountRow(
                    appt?.discountName ?? 'Discount',
                    appt?.discountAmount ?? 0,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Final Price Paid',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1D1E),
                      ),
                    ),
                    Text(
                      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0)
                          .format(appt?.finalPrice ?? payment.amount),
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00897B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (payment.isPaid)
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Text('E-Receipt', style: GoogleFonts.outfit(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isOriginal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600]),
        ),
        Text(
          NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(amount),
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: isOriginal ? Colors.grey[500] : const Color(0xFF1A1D1E),
            decoration: isOriginal ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDiscountRow(String discountName, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text('Discount ', style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF00897B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                discountName,
                style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF00897B), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        Text(
          '- ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(amount)}',
          style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF00897B), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    Color bgColor = Colors.grey.withValues(alpha: 0.1);

    if (status == 'PAID') {
      color = Colors.green;
      bgColor = Colors.green.withValues(alpha: 0.1);
    } else if (status == 'PENDING') {
      color = const Color(0xFFFFB800);
      bgColor = const Color(0xFFFFB800).withValues(alpha: 0.1);
    } else if (status == 'CANCELLED' || status == 'EXPIRED' || status == 'FAILED') {
      color = Colors.red;
      bgColor = Colors.red.withValues(alpha: 0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: GoogleFonts.outfit(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
