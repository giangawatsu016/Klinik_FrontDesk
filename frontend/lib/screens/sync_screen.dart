import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SyncScreen extends StatefulWidget {
  final ApiService apiService;

  const SyncScreen({super.key, required this.apiService});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Text(
          "No manual sync items available.",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ),
    );
  }
}
