import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class DiseaseListScreen extends StatefulWidget {
  final ApiService apiService;

  const DiseaseListScreen({super.key, required this.apiService});

  @override
  State<DiseaseListScreen> createState() => _DiseaseListScreenState();
}

class _DiseaseListScreenState extends State<DiseaseListScreen> {
  List<Disease> _diseases = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDiseases();
  }

  Future<void> _loadDiseases({String query = ""}) async {
    setState(() => _isLoading = true);
    try {
      final diseases = await widget.apiService.getDiseases(query: query);
      setState(() {
        _diseases = diseases;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading diseases: $e')));
      }
    }
  }

  void _showDiseaseDialog({Disease? disease}) {
    final formKey = GlobalKey<FormState>();
    final icdController = TextEditingController(text: disease?.icdCode ?? '');
    final nameController = TextEditingController(text: disease?.name ?? '');
    final descController = TextEditingController(
      text: disease?.description ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(disease == null ? 'Add Disease' : 'Edit Disease'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: icdController,
                decoration: const InputDecoration(labelText: 'ICD Code'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Disease Name'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newDisease = Disease(
                  id: disease?.id,
                  icdCode: icdController.text,
                  name: nameController.text,
                  description: descController.text,
                );

                try {
                  if (disease == null) {
                    await widget.apiService.createDisease(newDisease);
                  } else {
                    await widget.apiService.updateDisease(
                      disease.id!,
                      newDisease,
                    );
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    _loadDiseases();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
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
                    labelText: "Search by ICD or Name",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (val) => _loadDiseases(query: val),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showDiseaseDialog(),
                icon: const Icon(Icons.add),
                label: const Text("Add Disease"),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _diseases.length,
                    itemBuilder: (context, index) {
                      final disease = _diseases[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(disease.icdCode.substring(0, 1)),
                          ),
                          title: Text("${disease.icdCode} - ${disease.name}"),
                          subtitle: Text(disease.description ?? ""),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () =>
                                    _showDiseaseDialog(disease: disease),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text("Confirm Delete"),
                                      content: Text("Delete ${disease.name}?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            await widget.apiService
                                                .deleteDisease(disease.id!);
                                            if (mounted) {
                                              Navigator.pop(ctx);
                                              _loadDiseases();
                                            }
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
