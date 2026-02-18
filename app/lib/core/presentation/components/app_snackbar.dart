import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

enum SnackBarType { success, error, warning, info }

class AppSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Clear existing snackbars
    scaffoldMessenger.removeCurrentSnackBar();

    Color backgroundColor;
    IconData icon;
    String title;

    switch (type) {
      case SnackBarType.success:
        backgroundColor = const Color(0xFF10B981);
        icon = FontAwesomeIcons.circleCheck;
        title = 'Success';
        break;
      case SnackBarType.error:
        backgroundColor = const Color(0xFFEF4444);
        icon = FontAwesomeIcons.circleExclamation;
        title = 'Error';
        break;
      case SnackBarType.warning:
        backgroundColor = const Color(0xFFF59E0B);
        icon = FontAwesomeIcons.triangleExclamation;
        title = 'Warning';
        break;
      case SnackBarType.info:
        backgroundColor = const Color(0xFF3B82F6);
        icon = FontAwesomeIcons.circleInfo;
        title = 'Info';
        break;
    }

    scaffoldMessenger.showSnackBar(
      SnackBar(
        duration: duration,
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              FaIcon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      message,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                onPressed: () {
                  scaffoldMessenger.hideCurrentSnackBar();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
