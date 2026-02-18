import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart';

class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer.frostedGlass(
      height: height,
      width: width,
      borderRadius: borderRadius ?? BorderRadius.circular(24),
      borderWidth: 1.5,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.15),
          Colors.white.withValues(alpha: 0.05),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.25),
          Colors.white.withValues(alpha: 0.1),
        ],
      ),
      blur: 15,
      borderColor: Colors.white.withValues(alpha: 0.2),
      child: child,
    );
  }
}

class PremiumButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isSerenity;

  const PremiumButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isSerenity = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isSerenity) {
      return LiquidGlassCard(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            alignment: Alignment.center,
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFFBBF24),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: Text(text),
    );
  }
}
