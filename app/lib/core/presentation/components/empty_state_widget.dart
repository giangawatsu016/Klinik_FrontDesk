import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String? lottieAsset;
  final VoidCallback? onRetry;
  final bool isCentered;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.lottieAsset,
    this.onRetry,
    this.isCentered = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (lottieAsset != null)
          Lottie.asset(
            lottieAsset!,
            width: 200,
            height: 200,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallbackIcon();
            },
          )
        else
          _buildFallbackIcon(),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2859E2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Try Again',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );

    if (isCentered) {
      return Center(child: content);
    }
    return content;
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.search_off_rounded,
        size: 48,
        color: Colors.grey[400],
      ),
    );
  }
}
