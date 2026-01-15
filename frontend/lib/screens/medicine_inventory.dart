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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Inherit gradient
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMedicineDialog,
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
                            trailing: Column(
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
                                  med.stock > 0 ? "Available" : "Out of Stock",
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

  void _showAddMedicineDialog() {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String description = '';
    int stock = 0;
    String unit = 'Unit';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Add New Medicine"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: "Name"),
                validator: (v) => v!.isEmpty ? "Required" : null,
                onSaved: (v) => name = v!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Description"),
                onSaved: (v) => description = v ?? '',
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Initial Stock"),
                keyboardType: TextInputType.number,
                initialValue: "0",
                validator: (v) => v == null || int.tryParse(v) == null
                    ? "Invalid Number"
                    : null,
                onSaved: (v) => stock = int.parse(v!),
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Unit (e.g. tablet, box)",
                ),
                initialValue: "Unit",
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
                final newMed = Medicine(
                  id: 0,
                  erpnextItemCode: "", // Backend will generate MANUAL-ID
                  name: name,
                  description: description,
                  stock: stock,
                  unit: unit,
                );
                final res = await widget.apiService.createMedicine(newMed);
                if (!ctx.mounted) return;

                if (res != null) {
                  Navigator.pop(ctx);
                  if (mounted) {
                    _loadMedicines(); // Reload list
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Medicine Added Successfully")),
                    );
                  }
                }
              }
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }
}
