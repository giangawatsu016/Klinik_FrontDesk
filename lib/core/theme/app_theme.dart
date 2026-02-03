import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum UserTier { care, comfort, serenity }

class AppTheme {
  static ThemeData getTheme(UserTier tier) {
    switch (tier) {
      case UserTier.care:
        return _careTheme;
      case UserTier.comfort:
        return _comfortTheme;
      case UserTier.serenity:
        return _serenityTheme;
    }
  }

  // CARE THEME (Blue/Slate)
  static final _careTheme = ThemeData(
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    textTheme: GoogleFonts.outfitTextTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1E293B),
      elevation: 0,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2859E2), // Intimedicare Blue
      primary: const Color(0xFF2859E2),
      secondary: const Color(0xFF64748B),
    ),
  );

  // COMFORT THEME (Emerald/Green)
  static final _comfortTheme = ThemeData(
    primarySwatch: Colors.green, // emerald not standard in Material2/3 without extension?
    scaffoldBackgroundColor: const Color(0xFFF0FDF4),
    textTheme: GoogleFonts.outfitTextTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF064E3B),
      elevation: 0,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF10B981),
      primary: const Color(0xFF10B981),
      secondary: const Color(0xFF059669),
    ),
  );

  // SERENITY THEME (Gold/Amber + Premium)
  static final _serenityTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.amber,
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFFFBBF24),
      elevation: 0,
    ),
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: const Color(0xFFFBBF24),
      primary: const Color(0xFFFBBF24),
      secondary: const Color(0xFFD97706),
      surface: const Color(0xFF1E293B),
    ),
  );
}
