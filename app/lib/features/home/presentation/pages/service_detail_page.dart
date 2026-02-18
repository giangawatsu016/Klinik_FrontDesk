import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../../domain/entities/service_entity.dart';
import '../../../appointment/presentation/pages/appointment_wizard_page.dart';
import '../components/service_image_carousel.dart';

class ServiceDetailPage extends StatelessWidget {
  final ServiceEntity service;

  const ServiceDetailPage({super.key, required this.service});

  String _formatPrice(double? price) {
    if (price == null) return 'Rp 0';
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(price);
  }

  String _stripHtml(String? htmlString) {
    if (htmlString == null) return '';
    return Bidi.stripHtmlIfNeeded(htmlString).trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'service_image_${service.id}',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ServiceImageCarousel(
                      images: service.posterImages,
                      serviceId: service.id,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black54],
                          stops: [0.6, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              title: Text(
                service.name,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    const Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3.0,
                      color: Colors.black45,
                    ),
                  ],
                ),
              ),
              centerTitle: false,
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.black,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Medical Service',
                            style: GoogleFonts.outfit(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (service.finalPrice != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatPrice(service.finalPrice),
                                style: GoogleFonts.outfit(
                                  color:
                                      service.discount != null &&
                                          service.discount! > 0
                                      ? const Color(0xFF00897B)
                                      : const Color(0xFF1A237E),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                              if (service.discount != null &&
                                  service.discount! > 0) ...[
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE6FFFA),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF00BD7D,
                                          ).withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: Text(
                                        service.discountType == 'percentage'
                                            ? '-${service.discountValue?.round()}%'
                                            : '-Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(service.discountValue)}',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF00BD7D),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatPrice(
                                        service.originalPrice ??
                                            (service.finalPrice! +
                                                service.discount!),
                                      ),
                                      style: GoogleFonts.outfit(
                                        color: Colors.grey[700],
                                        decoration: TextDecoration.lineThrough,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (service.discount != null && service.discount! > 0) ...[
                    const SizedBox(height: 16),
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFE6FFFA),
                              Colors.white.withValues(alpha: 0.5),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(
                              0xFF00BD7D,
                            ).withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Color(0xFF00BD7D),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.local_offer_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service.discountName?.toUpperCase() ??
                                        'SPECIAL OFFER',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF00BD7D),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  if (service.discountUntil != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        _getRemainingTime(
                                          service.discountUntil!,
                                        ),
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFFE53935),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: Text(
                      'About Service',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1D1E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    child: Text(
                      _stripHtml(service.description),
                      style: GoogleFonts.outfit(
                        color: Colors.grey[600],
                        height: 1.6,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (service.details.isNotEmpty) ...[
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      child: Text(
                        'Service Details',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1D1E),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...service.details.asMap().entries.map((entry) {
                      final index = entry.key;
                      final detail = entry.value;
                      return FadeInUp(
                        delay: Duration(milliseconds: 500 + (index * 100)),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                detail.title,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: const Color(0xFF1A1D1E),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _stripHtml(detail.content),
                                style: GoogleFonts.outfit(
                                  color: Colors.grey[600],
                                  height: 1.5,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Savings text above button on right
              if (_hasSavings())
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Anda hemat ${_getSavingsText()}',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF00897B),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AppointmentWizardPage(service: service),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2859E2), // Primary color
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Pesan sekarang',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasSavings() {
    return service.discountValue != null && service.discountValue! > 0;
  }

  String _getSavingsText() {
    final originalPrice = service.originalPrice ?? 0;
    final finalPrice = service.finalPrice ?? 0;
    final savings = originalPrice - finalPrice;

    if (savings >= 1000) {
      final savingsInK = savings / 1000;
      return savingsInK == savingsInK.roundToDouble()
          ? '${savingsInK.toInt()}k'
          : '${savingsInK.toStringAsFixed(0)}k';
    }
    return NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(savings);
  }

  String _getRemainingTime(DateTime until) {
    final now = DateTime.now();
    final diff = until.difference(now);
    if (diff.isNegative) return 'Offer Expired';
    if (diff.inDays > 0) return '${diff.inDays} days left';
    if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes % 60}m left';
    }
    return 'Ending soon';
  }
}
