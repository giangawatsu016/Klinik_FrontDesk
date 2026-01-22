import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class UserManagementScreen extends StatefulWidget {
  final ApiService apiService;
  final User currentUser; // To determine permissions

  const UserManagementScreen({
    super.key,
    required this.apiService,
    required this.currentUser,
  });

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await widget.apiService.getUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUserDialog({User? user}) {
    final isEditing = user != null;
    final formKey = GlobalKey<FormState>();
    String username = user?.username ?? '';
    String fullName = user?.fullName ?? '';
    String email = user?.email ?? '';
    String role = user?.role ?? 'Staff'; // Default for creation
    String password = '';

    // Determine allowed roles to create/edit
    List<String> allowedRoles = [];
    if (widget.currentUser.role == 'Super Admin') {
      allowedRoles = ['Administrator', 'Staff']; // Super Admin can create these
      // If editing, preserve current role unless changed
      if (isEditing && user.role == 'Super Admin') {
        allowedRoles = [
          'Super Admin',
        ]; // Can't change Super Admin role to something else easily
      }
    } else if (widget.currentUser.role == 'Administrator') {
      allowedRoles = ['Staff'];
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit User' : 'Add New User'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: username,
                  decoration: InputDecoration(labelText: 'Username'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                  onSaved: (v) => username = v!,
                ),
                TextFormField(
                  initialValue: email,
                  decoration: InputDecoration(labelText: 'Email (for ERPNext)'),
                  validator: (v) => v!.contains('@') ? null : 'Invalid Email',
                  onSaved: (v) => email = v ?? '',
                ),
                TextFormField(
                  initialValue: fullName,
                  decoration: InputDecoration(labelText: 'Full Name'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                  onSaved: (v) => fullName = v!,
                ),
                if (allowedRoles.isNotEmpty)
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: allowedRoles.contains(role)
                        ? role
                        : allowedRoles.first,
                    decoration: InputDecoration(labelText: 'Role'),
                    items: allowedRoles
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => role = v!,
                    onSaved: (v) => role = v!,
                  ),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: isEditing
                        ? 'Password (Leave empty to keep)'
                        : 'Password',
                  ),
                  obscureText: true,
                  validator: (v) {
                    if (!isEditing && (v == null || v.isEmpty)) {
                      return 'Required';
                    }
                    return null;
                  },
                  onSaved: (v) => password = v ?? '',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                Navigator.pop(ctx);

                try {
                  if (isEditing) {
                    final updatedUser = User(
                      id: user.id,
                      username: username,
                      fullName: fullName,
                      role: role,
                      email: email,
                    );
                    await widget.apiService.updateUser(
                      user.id!,
                      updatedUser,
                      password,
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('User Updated')));
                  } else {
                    final newUser = User(
                      username: username,
                      fullName: fullName,
                      role: role,
                      email: email,
                    );
                    await widget.apiService.createUser(newUser, password);
                    if (!mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('User Created')));
                  }
                  _loadUsers();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(isEditing ? 'Save' : 'Create'),
          ),
        ],
      ),
    );
  }

  void _deleteUser(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.username}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await widget.apiService.deleteUser(user.id!);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('User Deleted')));
        _loadUsers();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.transparent, // For Dashboard gradient
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          // Theme defaults handle shape and elevation (0)
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.end, // Align button to right
                  children: [
                    // Title Removed (Handled by Dashboard Header)
                    ElevatedButton.icon(
                      onPressed: () => _showUserDialog(),
                      icon: Icon(Icons.add),
                      label: Text("Add User"),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    DataTable(
                      columns: [
                        DataColumn(label: Text('Username')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Full Name')),
                        DataColumn(label: Text('Role')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: _users.map((user) {
                        // Logic for Actions visibility
                        bool canEdit = false;
                        bool canDelete = false;

                        if (widget.currentUser.role == 'Super Admin') {
                          canEdit = true;
                          canDelete = true;
                          // Assuming "Tidak bisa... super admin" applies to Administrator, but Super Admin can edit others.
                          // But can Super Admin delete Super Admin? Usually no.
                          if (user.role == 'Super Admin') canDelete = false;
                        } else if (widget.currentUser.role == 'Administrator') {
                          if (user.role == 'Staff') {
                            canEdit = true;
                            canDelete = true;
                          }
                        }

                        return DataRow(
                          cells: [
                            DataCell(Text(user.username)),
                            DataCell(Text(user.email)),
                            DataCell(Text(user.fullName)),
                            DataCell(
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: user.role == 'Super Admin'
                                      ? Colors.red.shade100
                                      : (user.role == 'Administrator'
                                            ? Colors.orange.shade100
                                            : Colors.blue.shade100),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  user.role,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  if (canEdit)
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () =>
                                          _showUserDialog(user: user),
                                    ),
                                  if (canDelete)
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _deleteUser(user),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
