import 'package:flutter/material.dart';
import 'screens/login.dart';

void main() {
  runApp(KlinikAdminApp());
}

class KlinikAdminApp extends StatelessWidget {
  const KlinikAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Klinik Admin',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LoginScreen(),
    );
  }
}
