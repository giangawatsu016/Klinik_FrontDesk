import 'package:flutter/material.dart';
import 'screens/login.dart';

import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const KlinikAdminApp());
}

class KlinikAdminApp extends StatelessWidget {
  const KlinikAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Klinik Intimedicare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.light(
          primary: Colors.black, // High contrast
          secondary: Colors.blue.shade700,
          surface: Colors.white,
          onSurface: Colors.black87,
          outline: Colors.grey.shade300, // For borders
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        cardTheme: CardThemeData(
          elevation: 0, // No shadows
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey.shade300), // Border instead
            borderRadius: BorderRadius.circular(8),
          ),
          margin: EdgeInsets.zero,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.black),
          ),
          floatingLabelBehavior:
              FloatingLabelBehavior.always, // Prevent overlap
          floatingLabelStyle: const TextStyle(
            color: Colors.black,
            backgroundColor: Colors.white,
          ),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.grey.shade200,
          thickness: 1,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            side: BorderSide(color: Colors.grey.shade300),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ),
      home: LoginScreen(),
    );
  }
}
