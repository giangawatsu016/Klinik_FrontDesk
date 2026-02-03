import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VitalSignCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? color;

  const VitalSignCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    this.onTap,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: (color ?? const Color(0xFF2859E2)).withValues(
                          alpha: 0.1,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 14,
                        color: color ?? const Color(0xFF2859E2),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              if (onTap != null)
                GestureDetector(
                  onTap: onTap,
                  child: Text(
                    'View Details',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2859E2),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Value
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),
          Text(
            'Recorded during visit',
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: Colors.grey[300],
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
