import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomLoadingButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final Color? color;
  final double height;
  final double borderRadius;
  final TextStyle? textStyle;

  const CustomLoadingButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.color,
    this.height = 56,
    this.borderRadius = 16,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? const Color(0xFF2859E2),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          disabledBackgroundColor: (color ?? const Color(0xFF2859E2))
              .withValues(alpha: 0.6),
          disabledForegroundColor: Colors.white,
          elevation: 0,
        ),
        child: isLoading
            ? const SpinKitThreeBounce(color: Colors.white, size: 24.0)
            : Text(
                text,
                style:
                    textStyle ??
                    GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
              ),
      ),
    );
  }
}
