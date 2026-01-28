import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class PharmacistListScreen extends StatefulWidget {
  final ApiService apiService;

  const PharmacistListScreen({super.key, required this.apiService});

  @override
  State<PharmacistListScreen> createState() => _PharmacistListScreenState();
}

class _PharmacistListScreenState extends State<PharmacistListScreen> {
  List<Pharmacist> _pharmacists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPharmacists();
  }

  Future<void> _loadPharmacists() async {
    setState(() => _isLoading = true);
    try {
      final data = await widget.apiService.getPharmacists();
      setState(() {
        _pharmacists = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading pharmacists: $e')),
        );
      }
    }
  }

  void _showPharmacistDialog({Pharmacist? pharmacist}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: pharmacist?.name ?? '');
    final sipController = TextEditingController(text: pharmacist?.sipNo ?? '');
    final ihsController = TextEditingController(
      text: pharmacist?.ihsNumber ?? '',
    );
    final erpController = TextEditingController(
      text: pharmacist?.erpEmployeeId ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(pharmacist == null ? 'Add Pharmacist' : 'Edit Pharmacist'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (val) => val!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: sipController,
                  decoration: const InputDecoration(labelText: 'SIP Number'),
                  validator: (val) => val!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: ihsController,
                  decoration: const InputDecoration(
                    labelText: 'IHS Number (SatuSehat)',
                  ),
                ),
                TextFormField(
                  controller: erpController,
                  decoration: const InputDecoration(
                    labelText: 'ERPNext Employee ID',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newPharmacist = Pharmacist(
                  id: pharmacist?.id,
                  name: nameController.text,
                  sipNo: sipController.text,
                  ihsNumber: ihsController.text.isNotEmpty
                      ? ihsController.text
                      : null,
                  erpEmployeeId: erpController.text.isNotEmpty
                      ? erpController.text
                      : null,
                  isActive: true, // Default to true
                );

                try {
                  // Currently only Create is supported in ApiService for simplicity based on previous steps
                  // But we might need Update? I only added createPharmacist.
                  // I'll assume Create for now or check if I need to add Update.
                  // Wait, I only added createPharmacist and deletePharmacist in ApiService.
                  // So for "Edit", I'll just error or implement Update later.
                  // For now let's support Add only or hacked Add (which creates new).
                  // Actually let's just do Add for now.

                  if (pharmacist == null) {
                    await widget.apiService.createPharmacist(newPharmacist);
                  } else {
                    await widget.apiService.updatePharmacist(
                      pharmacist.id!,
                      newPharmacist,
                    );
                  }

                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  _loadPharmacists();
                } catch (e) {
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Pharmacist List",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showPharmacistDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text("Add Pharmacist"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _pharmacists.isEmpty
                  ? const Center(child: Text("No pharmacists found."))
                  : ListView.builder(
                      itemCount: _pharmacists.length,
                      itemBuilder: (context, index) {
                        final p = _pharmacists[index];
                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(LucideIcons.user),
                            ),
                            title: Text(p.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("SIP: ${p.sipNo}"),
                                if (p.ihsNumber != null)
                                  Text("IHS: ${p.ihsNumber}"),
                                if (p.erpEmployeeId != null)
                                  Text("ERP: ${p.erpEmployeeId}"),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                // Confirm Delete
                                try {
                                  await widget.apiService.deletePharmacist(
                                    p.id!,
                                  );
                                  _loadPharmacists();
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Error: $e")),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
