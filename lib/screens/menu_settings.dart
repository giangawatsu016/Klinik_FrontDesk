import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MenuVisibilityScreen extends StatefulWidget {
  final ApiService apiService;
  const MenuVisibilityScreen({super.key, required this.apiService});

  @override
  State<MenuVisibilityScreen> createState() => _MenuVisibilityScreenState();
}

class _MenuVisibilityScreenState extends State<MenuVisibilityScreen> {
  // Configurable menus
  final Map<String, String> _menuLabels = {
    "doctors": "Doctors",
    "patients": "Patients",
    "diagnosis": "Diagnosis",
    "diseases": "Diseases",
    "medicines": "Medicines",
    "pharmacists": "Pharmacist",
  };

  List<String> _hiddenMenus = [];
  bool _bypassAdmin = false;
  bool _bypassStaff = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final hidden = await widget.apiService.getHiddenMenus();
      final bypassAdminVal = await widget.apiService.getAppConfig(
        "bypass_login_admin",
      );
      final bypassStaffVal = await widget.apiService.getAppConfig(
        "bypass_login_staff",
      );

      setState(() {
        _hiddenMenus = hidden;
        _bypassAdmin = bypassAdminVal == "true" || bypassAdminVal == true;
        _bypassStaff = bypassStaffVal == "true" || bypassStaffVal == true;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to load config")));
      }
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isLoading = true);
    try {
      await widget.apiService.setHiddenMenus(_hiddenMenus);
      await widget.apiService.saveAppConfig(
        "bypass_login_admin",
        _bypassAdmin ? "true" : "false",
      );
      await widget.apiService.saveAppConfig(
        "bypass_login_staff",
        _bypassStaff ? "true" : "false",
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Settings Saved")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to save: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Menu Visibility Settings")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16),
              children: [
                Text(
                  "Select menus to HIDE from all users:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                ..._menuLabels.entries.map((entry) {
                  final isHidden = _hiddenMenus.contains(entry.key);
                  return CheckboxListTile(
                    title: Text(entry.value),
                    subtitle: Text(isHidden ? "Hidden" : "Visible"),
                    value: isHidden,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _hiddenMenus.add(entry.key);
                        } else {
                          _hiddenMenus.remove(entry.key);
                        }
                      });
                    },
                  );
                }),
                SizedBox(height: 16),
                Divider(),
                SizedBox(height: 16),
                Text(
                  "Developer Settings (Bypass Login):",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SwitchListTile(
                  title: Text("Bypass Login (Administrator)"),
                  subtitle: Text("Allow admin login without password"),
                  value: _bypassAdmin,
                  onChanged: (val) => setState(() => _bypassAdmin = val),
                  activeTrackColor: Colors.red,
                ),
                SwitchListTile(
                  title: Text("Bypass Login (Staff)"),
                  subtitle: Text("Allow staff login without password"),
                  value: _bypassStaff,
                  onChanged: (val) => setState(() => _bypassStaff = val),
                  activeTrackColor: Colors.orange,
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveConfig,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: Text("SAVE CHANGES"),
                ),
              ],
            ),
    );
  }
}
