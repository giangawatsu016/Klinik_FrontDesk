import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/glass_container.dart';

class DoctorListScreen extends StatefulWidget {
  final ApiService apiService;
  const DoctorListScreen({super.key, required this.apiService});

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  List<Doctor> _doctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    try {
      final doctors = await widget.apiService.getDoctors();
      if (mounted) {
        setState(() {
          _doctors = doctors;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading doctors: $e')));
      }
    }
  }

  Future<void> _syncDoctors() async {
    setState(() => _isLoading = true);
    try {
      final res = await widget.apiService.syncDoctors();
      if (mounted) {
        String msg = "Synced ${res['count']} new doctors.";
        if (res['status'] == 'failed') msg = "Sync Failed: ${res['message']}";

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
        _loadDoctors(); // Reload list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Sync Error: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDoctorDetail(Doctor doctor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Doctor Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(
              "Name",
              "${doctor.gelarDepan} ${doctor.firstName ?? '-'} ${doctor.lastName ?? '-'} ${doctor.gelarBelakang ?? ''}",
            ),
            _detailRow("Polyclinic", doctor.polyName),
            _detailRow("SIP", doctor.doctorSIP ?? '-'),
            _detailRow(
              "Online Fee",
              doctor.onlineFee != null ? "Rp ${doctor.onlineFee}" : '-',
            ),
            _detailRow(
              "Appt Fee",
              doctor.appointmentFee != null
                  ? "Rp ${doctor.appointmentFee}"
                  : '-',
            ),
            _detailRow("ID", doctor.medicalFacilityPolyDoctorId.toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showAddDoctorDialog(existingDoctor: doctor);
            },
            child: Text("Edit", style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: Colors.black87),
          children: [
            TextSpan(
              text: "$label: ",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDoctorDialog,
        backgroundColor: Colors.blue.shade900,
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _doctors.isEmpty
          ? Center(child: Text("No doctors found."))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: GlassContainer(
                opacity: 0.8,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Doctor List",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.sync, color: Colors.blue.shade900),
                            tooltip: "Sync from ERPNext",
                            onPressed: _syncDoctors,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _doctors.length,
                        separatorBuilder: (context, index) => Divider(),
                        itemBuilder: (context, index) {
                          final doctor = _doctors[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Icon(
                                Icons.medical_services,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            title: Text(
                              "${doctor.gelarDepan} ${doctor.namaDokter}",
                            ),
                            subtitle: Text(doctor.polyName),
                            trailing: Icon(
                              Icons.info_outline,
                              color: Colors.grey,
                            ),
                            onTap: () => _showDoctorDetail(doctor),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showAddDoctorDialog({Doctor? existingDoctor}) {
    final formKey = GlobalKey<FormState>();
    // Existing fields
    String title = existingDoctor?.gelarDepan ?? '';
    String poly = existingDoctor?.polyName ?? 'General';

    // Split name or use existing fields
    String firstName = existingDoctor?.firstName ?? '';
    String lastName = existingDoctor?.lastName ?? '';
    if (existingDoctor != null && firstName.isEmpty) {
      // Fallback split if legacy data
      var parts = existingDoctor.namaDokter.split(' ');
      firstName = parts[0];
      if (parts.length > 1) lastName = parts.sublist(1).join(' ');
    }

    String gelarBelakang = existingDoctor?.gelarBelakang ?? '';
    String doctorSIP = existingDoctor?.doctorSIP ?? '';
    int? onlineFee = existingDoctor?.onlineFee;
    int? appointmentFee = existingDoctor?.appointmentFee;

    bool isEditing = existingDoctor != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? "Edit Doctor" : "Add New Doctor"),
        content: SizedBox(
          // Limit size for scrolling
          width: 400,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(labelText: "Title"),
                          initialValue: title.isNotEmpty ? title : 'Dr.',
                          items:
                              ['Dr.', 'Prof.', 'Sp.', 'Ns.', 'Bidan', 'Other']
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => title = v!,
                          onSaved: (v) => title = v!,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          initialValue: gelarBelakang,
                          decoration: InputDecoration(
                            labelText: "Suffix (Gelar Belakang)",
                          ),
                          onSaved: (v) => gelarBelakang = v ?? '',
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: firstName,
                          decoration: InputDecoration(labelText: "First Name"),
                          validator: (v) => v!.isEmpty ? "Required" : null,
                          onSaved: (v) => firstName = v!,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: lastName,
                          decoration: InputDecoration(labelText: "Last Name"),
                          onSaved: (v) => lastName = v ?? '',
                        ),
                      ),
                    ],
                  ),

                  TextFormField(
                    initialValue: doctorSIP,
                    decoration: InputDecoration(labelText: "SIP Number"),
                    onSaved: (v) => doctorSIP = v ?? '',
                  ),

                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: "Polyclinic"),
                    initialValue: poly,
                    items:
                        [
                              'General',
                              'Dental',
                              'Pediatric',
                              'Neurology',
                              'Cardiology',
                              'Internal Medicine',
                              'Surgery',
                              'Obgyn',
                            ]
                            .map(
                              (p) => DropdownMenuItem(value: p, child: Text(p)),
                            )
                            .toList(),
                    onChanged: (v) => poly = v!,
                    onSaved: (v) => poly = v!,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: onlineFee?.toString(),
                          decoration: InputDecoration(labelText: "Online Fee"),
                          keyboardType: TextInputType.number,
                          onSaved: (v) => onlineFee = int.tryParse(v ?? ''),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: appointmentFee?.toString(),
                          decoration: InputDecoration(labelText: "Appt Fee"),
                          keyboardType: TextInputType.number,
                          onSaved: (v) =>
                              appointmentFee = int.tryParse(v ?? ''),
                        ),
                      ),
                    ],
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

                String fullName = firstName;
                if (lastName.isNotEmpty) fullName += " $lastName";

                if (isEditing) {
                  // Update Logic
                  final updatedDoc = Doctor(
                    medicalFacilityPolyDoctorId:
                        existingDoctor.medicalFacilityPolyDoctorId,
                    namaDokter: fullName,
                    gelarDepan: title,
                    polyName: poly,
                    firstName: firstName,
                    lastName: lastName,
                    gelarBelakang: gelarBelakang,
                    doctorSIP: doctorSIP,
                    onlineFee: onlineFee,
                    appointmentFee: appointmentFee,
                  );
                  final res = await widget.apiService.updateDoctor(
                    existingDoctor.medicalFacilityPolyDoctorId,
                    updatedDoc,
                  );
                  if (res != null) {
                    if (ctx.mounted) Navigator.pop(ctx); // Close Dialog
                    if (mounted) {
                      _loadDoctors();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Doctor Updated Successfully")),
                      );
                    }
                  }
                } else {
                  // Create Logic
                  final newDoc = Doctor(
                    medicalFacilityPolyDoctorId: 0,
                    namaDokter: fullName,
                    gelarDepan: title,
                    polyName: poly,
                    firstName: firstName,
                    lastName: lastName,
                    gelarBelakang: gelarBelakang,
                    doctorSIP: doctorSIP,
                    onlineFee: onlineFee,
                    appointmentFee: appointmentFee,
                  );
                  final res = await widget.apiService.createDoctor(newDoc);
                  if (res != null) {
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      _loadDoctors();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Doctor Added Successfully")),
                      );
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
