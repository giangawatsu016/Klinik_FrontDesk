import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class MedicineInventoryScreen extends StatefulWidget {
  final ApiService apiService;

  const MedicineInventoryScreen({super.key, required this.apiService});

  @override
  State<MedicineInventoryScreen> createState() =>
      _MedicineInventoryScreenState();
}

class _MedicineInventoryScreenState extends State<MedicineInventoryScreen> {
  List<Medicine> _medicines = [];
  List<Medicine> _filteredMedicines = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMedicines();
    _searchController.addListener(_filterMedicines);
  }

  void _loadMedicines() async {
    setState(() => _isLoading = true);
    try {
      final meds = await widget.apiService.getMedicines();
      if (mounted) {
        setState(() {
          _medicines = meds;
          _filteredMedicines = meds;
        });
      }
    } catch (e) {
      debugPrint("Error loading medicines: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error loading medicines: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterMedicines() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMedicines = _medicines
          .where(
            (m) =>
                m.medicineName.toLowerCase().contains(query) ||
                m.erpnextItemCode.toLowerCase().contains(query),
          )
          .toList();
    });
  }

  void _syncMedicines() async {
    setState(() => _isSyncing = true);
    try {
      final result = await widget.apiService.syncMedicines();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Sync Success! Updated ${result['count']} items from ERPNext.",
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadMedicines(); // Reload list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Sync Failed: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _showDetailDialog(Medicine medicine) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(medicine.medicineName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "ERPNext Code: ${medicine.erpnextItemCode}",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text("Description: ${medicine.medicineDescription ?? '-'}"),
            if (medicine.medicineLabel != null)
              Text("Label: ${medicine.medicineLabel}"),
            Divider(),
            Text("Price (Retail): Rp ${medicine.medicineRetailPrice}"),
            Text("Stock: ${medicine.qty} ${medicine.unit}"),
            SizedBox(height: 8),
            Text("Dosage: ${medicine.howToConsume ?? '-'}"),
            if (medicine.notes != null) Text("Notes: ${medicine.notes}"),
            if (medicine.signa1 != null && medicine.signa2 != null)
              Text("Signa: ${medicine.signa1} x ${medicine.signa2}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showAddMedicineDialog(existingMedicine: medicine);
            },
            child: Text("Edit", style: TextStyle(color: Colors.orange)),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Close")),
        ],
      ),
    );
  }

  void _showKfaSearchDialog(Function(String, String, String) onImport) {
    showDialog(
      context: context,
      builder: (ctx) => _KfaSearchDialog(
        apiService: widget.apiService,
        onImport: onImport,
        onImportAllComplete: _loadMedicines,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Inherit gradient
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMedicineDialog(),
        backgroundColor: Colors.blue.shade900,
        child: Icon(Icons.add, color: Colors.white),
      ),
      appBar: AppBar(
        title: Text("Medicine Inventory"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.science, color: Colors.blue.shade900),
            tooltip: "Create Racikan",
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => _ConcoctionDialog(
                  apiService: widget.apiService,
                  availableMedicines: _medicines,
                  onSuccess: _loadMedicines,
                ),
              );
            },
          ),
          IconButton(
            icon: _isSyncing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.blue,
                    ),
                  )
                : Icon(Icons.sync, color: Colors.blue.shade900),
            tooltip: "Sync with ERPNext",
            onPressed: _isSyncing ? null : _syncMedicines,
          ),
          SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Search Medicine",
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _filteredMedicines.length,
                      itemBuilder: (ctx, i) {
                        final med = _filteredMedicines[i];
                        return Card(
                          elevation: 2,
                          color: Colors.white.withValues(alpha: 0.9),
                          margin: EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: med.qty > 0
                                  ? Colors.blue.shade100
                                  : Colors.red.shade100,
                              child: Icon(
                                Icons.medication,
                                color: med.qty > 0
                                    ? Colors.blue.shade900
                                    : Colors.red.shade900,
                              ),
                            ),
                            title: Text(
                              med.medicineName,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "${med.qty} ${med.unit}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: med.qty > 0
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                Text(
                                  med.qty > 0 ? "Available" : "Out of Stock",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () => _showDetailDialog(med),
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

  void _showAddMedicineDialog({Medicine? existingMedicine}) {
    final formKey = GlobalKey<FormState>();

    // Initial Values
    String code = existingMedicine?.erpnextItemCode ?? '';
    String name = existingMedicine?.medicineName ?? '';
    String description = existingMedicine?.medicineDescription ?? '';
    String label = existingMedicine?.medicineLabel ?? '';
    int qty = existingMedicine?.qty ?? 0;
    String unit = existingMedicine?.unit ?? 'Pcs';
    int price = existingMedicine?.medicinePrice ?? 0;
    int retailPrice = existingMedicine?.medicineRetailPrice ?? 0;
    String howToConsume = existingMedicine?.howToConsume ?? '';
    String notes = existingMedicine?.notes ?? '';
    int? signa1 = existingMedicine?.signa1;
    double? signa2 = existingMedicine?.signa2;

    bool isEditing = existingMedicine != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(isEditing ? "Edit Medicine" : "Add New Medicine"),
            if (!isEditing)
              IconButton(
                icon: Icon(Icons.cloud_download, color: Colors.blue),
                tooltip: "Import from SatuSehat KFA",
                onPressed: () {
                  Navigator.pop(ctx);
                  _showKfaSearchDialog((kfaName, kfaUnit, kfaCode) {
                    _showAddMedicineDialog(
                      existingMedicine: Medicine(
                        id: 0,
                        erpnextItemCode: kfaCode,
                        medicineName: kfaName,
                        medicineDescription: null,
                        medicineLabel: null,
                        qty: 0,
                        unit: kfaUnit,
                        medicinePrice: 0,
                        medicineRetailPrice: 0,
                      ),
                    );
                  });
                },
              ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: code,
                    decoration: InputDecoration(
                      labelText: "Item Code (Unique)",
                    ),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                    onSaved: (v) => code = v!,
                  ),
                  TextFormField(
                    initialValue: name,
                    decoration: InputDecoration(labelText: "Medicine Name"),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                    onSaved: (v) => name = v!,
                  ),
                  TextFormField(
                    initialValue: description,
                    decoration: InputDecoration(labelText: "Description"),
                    maxLines: 2,
                    onSaved: (v) => description = v ?? '',
                  ),
                  TextFormField(
                    initialValue: label,
                    decoration: InputDecoration(
                      labelText: "Label (e.g. Generic)",
                    ),
                    onSaved: (v) => label = v ?? '',
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: retailPrice.toString(),
                          decoration: InputDecoration(
                            labelText: "Retail Price",
                          ),
                          keyboardType: TextInputType.number,
                          onSaved: (v) =>
                              retailPrice = int.tryParse(v ?? '0') ?? 0,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: price.toString(),
                          decoration: InputDecoration(labelText: "Buy Price"),
                          keyboardType: TextInputType.number,
                          onSaved: (v) => price = int.tryParse(v ?? '0') ?? 0,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          initialValue: qty.toString(),
                          decoration: InputDecoration(labelText: "Stock Qty"),
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? "Required" : null,
                          onSaved: (v) => qty = int.tryParse(v!) ?? 0,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(labelText: "Unit"),
                          initialValue:
                              [
                                'Pcs',
                                'Box',
                                'Bottle',
                                'Strip',
                                'Tablet',
                                'Capsule',
                              ].contains(unit)
                              ? unit
                              : null,
                          items:
                              [
                                    'Pcs',
                                    'Box',
                                    'Bottle',
                                    'Strip',
                                    'Tablet',
                                    'Capsule',
                                  ]
                                  .map(
                                    (u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => unit = v!,
                          onSaved: (v) => unit = v!,
                        ),
                      ),
                    ],
                  ),
                  Divider(),
                  Text("Dosage Info"),
                  TextFormField(
                    initialValue: howToConsume,
                    decoration: InputDecoration(labelText: "How to Consume"),
                    onSaved: (v) => howToConsume = v ?? '',
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: signa1?.toString(),
                          decoration: InputDecoration(labelText: "Freq (x)"),
                          keyboardType: TextInputType.number,
                          onSaved: (v) => signa1 = int.tryParse(v ?? ''),
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          initialValue: signa2?.toString(),
                          decoration: InputDecoration(labelText: "Qty/Dose"),
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onSaved: (v) => signa2 = double.tryParse(v ?? ''),
                        ),
                      ),
                    ],
                  ),
                  TextFormField(
                    initialValue: notes,
                    decoration: InputDecoration(
                      labelText: "Notes (Signa Text)",
                    ),
                    onSaved: (v) => notes = v ?? '',
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();

                final medicineData = Medicine(
                  id: isEditing ? existingMedicine.id : 0,
                  erpnextItemCode: code,
                  medicineName: name,
                  medicineDescription: description,
                  medicineLabel: label,
                  medicinePrice: price,
                  medicineRetailPrice: retailPrice,
                  qty: qty,
                  unit: unit,
                  howToConsume: howToConsume,
                  notes: notes,
                  signa1: signa1,
                  signa2: signa2,
                );

                if (isEditing) {
                  final res = await widget.apiService.updateMedicine(
                    existingMedicine.id!,
                    medicineData,
                  );
                  if (res != null) {
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      if (mounted) {
                        _loadMedicines();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Medicine Updated")),
                        );
                      }
                    }
                  }
                } else {
                  final res = await widget.apiService.createMedicine(
                    medicineData,
                  );
                  if (res != null) {
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      if (mounted) {
                        _loadMedicines();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Medicine Added")),
                        );
                      }
                    }
                  }
                }
              }
            },
            child: Text(isEditing ? "Save Changes" : "Add"),
          ),
        ],
      ),
    );
  }
}

class _KfaSearchDialog extends StatefulWidget {
  final ApiService apiService;
  final Function(String name, String unit, String code) onImport;
  final VoidCallback? onImportAllComplete;

  const _KfaSearchDialog({
    required this.apiService,
    required this.onImport,
    this.onImportAllComplete,
  });

  @override
  State<_KfaSearchDialog> createState() => _KfaSearchDialogState();
}

class _KfaSearchDialogState extends State<_KfaSearchDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;

  void _search() async {
    if (_searchCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final res = await widget.apiService.searchKfaProducts(_searchCtrl.text);
      if (mounted) setState(() => _results = res);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _importAll() async {
    if (_results.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Import All?"),
        content: Text(
          "Do you want to import all ${_results.length} items? Stock will be set to 0.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              "Yes",
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    int successCount = 0;

    try {
      for (final item in _results) {
        final newMed = Medicine(
          id: 0,
          erpnextItemCode: item['item_code'] ?? '',
          medicineName: item['name'] ?? 'Unknown',
          medicineDescription:
              "${item['manufacturer'] ?? ''} - ${item['description'] ?? ''}",
          qty: 0,
          unit: item['unit'] ?? 'Unit',
          medicineLabel: null,
          medicinePrice: 0,
          medicineRetailPrice: 0,
        );
        final res = await widget.apiService.createMedicine(newMed);
        if (res != null) successCount++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Imported $successCount items successfully")),
        );
        Navigator.pop(context); // Close Dialog
        if (widget.onImportAllComplete != null) widget.onImportAllComplete!();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Import Error: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Search SatuSehat KFA"),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      labelText: "Medicine Name",
                      hintText: "e.g. Paracetamol",
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                IconButton(onPressed: _search, icon: Icon(Icons.search)),
              ],
            ),
            SizedBox(height: 10),
            _isLoading
                ? LinearProgressIndicator()
                : Container(
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(
                        (255 * 0.1).round(),
                      ), // Changed from withOpacity
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8), // Changed from 4
                    ),
                    child: _results.isEmpty
                        ? Center(child: Text("No results"))
                        : ListView.separated(
                            itemCount: _results.length,
                            separatorBuilder: (c, i) => Divider(),
                            itemBuilder: (ctx, i) {
                              final item = _results[i];
                              return ListTile(
                                title: Text(
                                  item['name'] ?? '',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  "${item['manufacturer']}\nCode: ${item['item_code']}",
                                ),
                                isThreeLine: true,
                                trailing: ElevatedButton(
                                  onPressed: () {
                                    widget.onImport(
                                      item['name'],
                                      item['unit'] ?? 'Unit',
                                      item['item_code'] ?? '',
                                    );
                                    Navigator.pop(ctx);
                                  },
                                  child: Text("Import"),
                                ),
                              );
                            },
                          ),
                  ),
          ],
        ),
      ),
      actions: [
        if (_results.isNotEmpty)
          TextButton(
            onPressed: () {
              _importAll();
            },
            child: Text("Import All"),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Close"),
        ),
      ],
    );
  }
}

class _ConcoctionDialog extends StatefulWidget {
  final ApiService apiService;
  final List<Medicine> availableMedicines;
  final VoidCallback onSuccess;

  const _ConcoctionDialog({
    required this.apiService,
    required this.availableMedicines,
    required this.onSuccess,
  });

  @override
  State<_ConcoctionDialog> createState() => _ConcoctionDialogState();
}

class _ConcoctionDialogState extends State<_ConcoctionDialog> {
  final _formKey = GlobalKey<FormState>();
  String _name = "";
  int _totalQty = 1;
  int _serviceFee = 0;
  String _unit = "Pcs";
  String _desc = "";

  final List<ConcoctionItemRequest> _items = [];

  void _addItem() {
    // Show dialog to pick medicine and qty
    Medicine? selected;
    if (widget.availableMedicines.isNotEmpty) {
      selected = widget.availableMedicines.first;
    }
    double qty = 1;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text("Add Ingredient"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InputDecorator(
                    decoration: InputDecoration(labelText: "Select Medicine"),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Medicine>(
                        isExpanded: true,
                        value: selected,
                        items: widget.availableMedicines.map((m) {
                          return DropdownMenuItem(
                            value: m,
                            child: Text(
                              m.medicineName.length > 30
                                  ? "${m.medicineName.substring(0, 27)}..."
                                  : m.medicineName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => selected = v),
                      ),
                    ),
                  ),
                  TextFormField(
                    initialValue: "1",
                    decoration: InputDecoration(labelText: "Qty Needed"),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (v) => qty = double.tryParse(v) ?? 0,
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (selected != null && qty > 0) {
                  // Use outer setState to update the main dialog
                  setState(() {
                    _items.add(
                      ConcoctionItemRequest(
                        childMedicineId: selected!.id!,
                        qty: qty,
                        name: selected!.medicineName,
                      ),
                    );
                  });
                  Navigator.pop(ctx);
                }
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please add at least one ingredient")),
        );
        return;
      }

      final req = ConcoctionRequest(
        medicineName: _name,
        items: _items,
        serviceFee: _serviceFee,
        totalQty: _totalQty,
        unit: _unit,
        description: _desc,
      );

      final res = await widget.apiService.createConcoction(req);
      if (res != null && mounted) {
        widget.onSuccess();
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Racikan Created!")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Create Racikan (Concoction)"),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: "Racikan Name"),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                  onSaved: (v) => _name = v!,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: "1",
                        decoration: InputDecoration(
                          labelText: "Total Result Qty",
                        ),
                        keyboardType: TextInputType.number,
                        onSaved: (v) => _totalQty = int.tryParse(v!) ?? 1,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: "0",
                        decoration: InputDecoration(
                          labelText: "Service Fee (Rp)",
                        ),
                        keyboardType: TextInputType.number,
                        onSaved: (v) => _serviceFee = int.tryParse(v!) ?? 0,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: "Pcs",
                        decoration: InputDecoration(labelText: "Unit"),
                        onSaved: (v) => _unit = v ?? 'Pcs',
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: "Description / Notes"),
                  onSaved: (v) => _desc = v ?? '',
                ),
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Ingredients:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle),
                      onPressed: _addItem,
                    ),
                  ],
                ),
                if (_items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "No ingredients added.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ..._items.map(
                  (item) => ListTile(
                    title: Text(item.name ?? "Item"),
                    subtitle: Text("Qty: ${item.qty}"),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => setState(() => _items.remove(item)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        ElevatedButton(onPressed: _save, child: Text("Create Racikan")),
      ],
    );
  }
}
