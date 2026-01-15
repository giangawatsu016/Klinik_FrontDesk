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
    final meds = await widget.apiService.getMedicines();
    if (mounted) {
      setState(() {
        _medicines = meds;
        _filteredMedicines = meds;
        _isLoading = false;
      });
    }
  }

  void _filterMedicines() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMedicines = _medicines
          .where(
            (m) =>
                m.name.toLowerCase().contains(query) ||
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
        title: Text(medicine.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "ERPNext Code: ${medicine.erpnextItemCode}",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text("Description: ${medicine.description ?? '-'}"),
            SizedBox(height: 8),
            Row(
              children: [
                Text("Stock: "),
                Text(
                  "${medicine.stock} ${medicine.unit ?? ''}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: medicine.stock > 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text("Close"),
          ),
          ElevatedButton(
            onPressed: medicine.stock > 0
                ? () {
                    // Placeholder for future logic
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Request sent for ${medicine.name}"),
                      ),
                    );
                  }
                : null, // Disabled if stock is 0
            style: ElevatedButton.styleFrom(
              backgroundColor: medicine.stock > 0 ? Colors.blue : Colors.grey,
            ),
            child: Text("Request Medicine"),
          ),
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
        onPressed: () => _showMedicineDialog(),
        backgroundColor: Colors.blue.shade900,
        child: Icon(Icons.add, color: Colors.white),
      ),
      appBar: AppBar(
        title: Text("Medicine Inventory"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
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
                              backgroundColor: med.stock > 0
                                  ? Colors.blue.shade100
                                  : Colors.red.shade100,
                              child: Icon(
                                Icons.medication,
                                color: med.stock > 0
                                    ? Colors.blue.shade900
                                    : Colors.red.shade900,
                              ),
                            ),
                            title: Text(
                              med.name,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text("Code: ${med.erpnextItemCode}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "${med.stock} ${med.unit ?? ''}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: med.stock > 0
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    Text(
                                      med.stock > 0
                                          ? "Available"
                                          : "Out of Stock",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  margin: EdgeInsets.only(left: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      size: 20,
                                      color: Colors.blue.shade800,
                                    ),
                                    tooltip: "Add Stock / Edit",
                                    onPressed: () =>
                                        _showMedicineDialog(medicine: med),
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

  void _showMedicineDialog({
    Medicine? medicine,
    String? initialName,
    String? initialUnit,
    String? initialCode,
  }) {
    final formKey = GlobalKey<FormState>();
    bool isEditing = medicine != null;

    String name = medicine?.name ?? initialName ?? '';
    String description =
        medicine?.description ??
        (initialCode != null ? "Imported from KFA (Code: $initialCode)" : '');
    int stock = medicine?.stock ?? 0;
    String unit = medicine?.unit ?? initialUnit ?? 'Tablet';

    List<String> validUnits = [
      "Tablet",
      "Capsule",
      "Bottle",
      "Box",
      "Pcs",
      "Strip",
      "Tube",
      "Vial",
      "Ampoule",
      "Sachet",
    ];

    // Ensure current unit is in the list to prevent Dropdown assertion error
    if (!validUnits.contains(unit) && unit.isNotEmpty) {
      validUnits.add(unit);
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(isEditing ? "Edit Material / Stock" : "Add New Medicine"),
            if (!isEditing && initialName == null)
              IconButton(
                icon: Icon(Icons.cloud_download, color: Colors.blue),
                tooltip: "Import from SatuSehat KFA",
                onPressed: () {
                  Navigator.pop(ctx);
                  _showKfaSearchDialog((kfaName, kfaUnit, kfaCode) {
                    _showMedicineDialog(
                      initialName: kfaName,
                      initialUnit: kfaUnit,
                      initialCode: kfaCode,
                    );
                  });
                },
              ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: name,
                decoration: InputDecoration(labelText: "Name"),
                validator: (v) => v!.isEmpty ? "Required" : null,
                onSaved: (v) => name = v!,
              ),
              TextFormField(
                initialValue: description,
                decoration: InputDecoration(labelText: "Description"),
                onSaved: (v) => description = v ?? '',
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Stock"),
                keyboardType: TextInputType.number,
                initialValue: stock.toString(),
                validator: (v) => v == null || int.tryParse(v) == null
                    ? "Invalid Number"
                    : null,
                onSaved: (v) => stock = int.parse(v!),
              ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: "Unit"),
                initialValue: unit,
                items: validUnits
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (v) => unit = v!,
                onSaved: (v) => unit = v!,
              ),
            ],
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
                Medicine? res;
                if (isEditing) {
                  final updatedMed = Medicine(
                    id: medicine.id,
                    erpnextItemCode: medicine.erpnextItemCode,
                    name: name,
                    description: description,
                    stock: stock,
                    unit: unit,
                  );
                  res = await widget.apiService.updateMedicine(
                    medicine.id,
                    updatedMed,
                  );
                } else {
                  final newMed = Medicine(
                    id: 0,
                    erpnextItemCode: initialCode ?? "",
                    name: name,
                    description: description,
                    stock: stock,
                    unit: unit,
                  );
                  res = await widget.apiService.createMedicine(newMed);
                }

                if (!ctx.mounted) return;

                if (res != null) {
                  Navigator.pop(ctx);
                  if (mounted) {
                    _loadMedicines(); // Reload list
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEditing
                              ? "Medicine Updated"
                              : "Medicine Added Successfully",
                        ),
                      ),
                    );
                  }
                }
              }
            },
            child: Text(isEditing ? "Save" : "Add"),
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
          name: item['name'] ?? 'Unknown',
          description:
              "${item['manufacturer'] ?? ''} - ${item['description'] ?? ''}",
          stock: 0,
          unit: item['unit'] ?? 'Unit',
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
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
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
            onPressed: _importAll,
            child: Text("Import All (${_results.length})"),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Close"),
        ),
      ],
    );
  }
}
