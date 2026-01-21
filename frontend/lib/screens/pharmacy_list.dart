import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class PharmacyListScreen extends StatefulWidget {
  final ApiService apiService;

  const PharmacyListScreen({super.key, required this.apiService});

  @override
  State<PharmacyListScreen> createState() => _PharmacyListScreenState();
}

class _PharmacyListScreenState extends State<PharmacyListScreen> {
  List<Medicine> _medicines = [];
  List<Medicine> _filteredMedicines = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    setState(() => _isLoading = true);
    try {
      final medicines = await widget.apiService.getMedicines();
      setState(() {
        _medicines = medicines;
        _filteredMedicines = medicines;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading medicines: $e')));
    }
  }

  void _filterMedicines(String query) {
    if (query.isEmpty) {
      setState(() => _filteredMedicines = _medicines);
    } else {
      setState(() {
        _filteredMedicines = _medicines
            .where(
              (m) =>
                  m.medicineName.toLowerCase().contains(query.toLowerCase()) ||
                  (m.erpnextItemCode.toLowerCase().contains(
                    query.toLowerCase(),
                  )),
            )
            .toList();
      });
    }
  }

  void _showMedicineDialog({Medicine? medicine}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text: medicine?.medicineName ?? '',
    );
    final codeController = TextEditingController(
      text: medicine?.erpnextItemCode ?? '',
    );
    final qtyController = TextEditingController(
      text: medicine?.qty.toString() ?? '0',
    );
    final unitController = TextEditingController(
      text: medicine?.unit ?? 'Unit',
    );
    String? selectedDosageForm = medicine?.dosageForm; // NEW local state

    final priceController = TextEditingController(
      text: medicine?.medicineRetailPrice.toString() ?? '0',
    );
    final descController = TextEditingController(
      text: medicine?.medicineDescription ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(medicine == null ? 'Add Medicine' : 'Edit Medicine'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Medicine Name'),
                  validator: (val) => val!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Item Code (Optional/Auto)',
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: qtyController,
                        decoration: const InputDecoration(labelText: 'Qty'),
                        keyboardType: TextInputType.number,
                        validator: (val) => val!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: unitController,
                        decoration: const InputDecoration(labelText: 'Unit'),
                        validator: (val) => val!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedDosageForm,
                  decoration: const InputDecoration(labelText: 'Dosage Form'),
                  items:
                      [
                            "Tablet",
                            "Capsule",
                            "Syrup",
                            "Injection",
                            "Cream",
                            "Ointment",
                            "Drops",
                            "Suppository",
                            "Inhaler",
                            "Patch",
                            "Other",
                          ]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (v) {
                    selectedDosageForm = v;
                  },
                ),
                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Retail Price (IDR)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
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
                final newMedicine = Medicine(
                  id: medicine?.id,
                  erpnextItemCode: codeController.text.isNotEmpty
                      ? codeController.text
                      : "MANUAL-${DateTime.now().millisecondsSinceEpoch}",
                  medicineName: nameController.text,
                  medicineDescription: descController.text,
                  qty: int.tryParse(qtyController.text) ?? 0,
                  unit: unitController.text.isNotEmpty
                      ? unitController.text
                      : "Unit",
                  dosageForm: selectedDosageForm, // SAVE HERE
                  medicineRetailPrice: int.tryParse(priceController.text) ?? 0,
                  medicinePrice:
                      medicine?.medicinePrice ?? 0, // Preserve Buy Price
                );

                try {
                  if (medicine == null) {
                    await widget.apiService.createMedicine(newMedicine);
                  } else {
                    await widget.apiService.updateMedicine(
                      medicine.id!,
                      newMedicine,
                    );
                  }
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  _loadMedicines();
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: "Search Pharmacy",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _filterMedicines,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showMedicineDialog(),
                icon: const Icon(Icons.add),
                label: const Text("Add Medicine"),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  await widget.apiService.syncMedicines();
                  _loadMedicines();
                },
                icon: const Icon(Icons.sync),
                label: const Text("Sync ERPNext"),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _filteredMedicines.length,
                    itemBuilder: (context, index) {
                      final medicine = _filteredMedicines[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: const Icon(Icons.medication),
                          ),
                          title: Text(medicine.medicineName),
                          subtitle: Text(
                            "${medicine.dosageForm ?? 'Unknown'} | Qty: ${medicine.qty} ${medicine.unit} | Rp ${medicine.medicineRetailPrice}",
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () =>
                                    _showMedicineDialog(medicine: medicine),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (dialogContext) => AlertDialog(
                                      title: const Text("Confirm Delete"),
                                      content: Text(
                                        "Delete ${medicine.medicineName}?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(dialogContext),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            await widget.apiService
                                                .deleteMedicine(medicine.id!);
                                            if (!dialogContext.mounted) return;
                                            Navigator.pop(dialogContext);
                                            _loadMedicines();
                                          },
                                          child: const Text(
                                            "Delete",
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
