import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';

class PharmacistListScreen extends StatefulWidget {
  final ApiService apiService;
  const PharmacistListScreen({super.key, required this.apiService});

  @override
  State<PharmacistListScreen> createState() => _PharmacistListScreenState();
}

class _PharmacistListScreenState extends State<PharmacistListScreen> {
  // Dummy Data for Pharmacists
  final List<Map<String, dynamic>> _pharmacists = [
    {
      "name": "Budi Santoso",
      "title": "Apt.",
      "sip": "19900101/SIP/2023/001",
      "status": "Active",
    },
    {
      "name": "Siti Aminah",
      "title": "Apt.",
      "sip": "19920515/SIP/2023/002",
      "status": "On Leave",
    },
    {
      "name": "Dewi Lestari",
      "title": "A.Md.Farm",
      "sip": "19950820/STR/2023/005",
      "status": "Active",
    },
    {
      "name": "Rudi Hartono",
      "title": "S.Farm",
      "sip": "19931110/SIP/2023/008",
      "status": "Inactive",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Add Pharmacist feature coming soon!")),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(LucideIcons.plus, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: GridView.builder(
            padding: EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: _pharmacists.length,
            itemBuilder: (context, index) {
              final pharmacist = _pharmacists[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.teal.withValues(alpha: 0.1),
                      radius: 36,
                      child: Icon(
                        LucideIcons.user,
                        color: Colors.teal,
                        size: 32,
                      ),
                    ),
                    SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        "${pharmacist['title']} ${pharmacist['name']}",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          fontFamily: 'Inter',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "SIP: ${pharmacist['sip']}",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: pharmacist['status'] == 'Active'
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        pharmacist['status'],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: pharmacist['status'] == 'Active'
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
