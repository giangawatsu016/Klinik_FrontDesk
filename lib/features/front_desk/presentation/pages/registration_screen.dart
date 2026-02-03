// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/front_desk_bloc.dart';
import '../bloc/front_desk_event.dart';
import '../bloc/front_desk_state.dart';
import '../../data/models/patient_model.dart';
import '../../data/models/queue_entry_model.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Toggle between New and Existing Patient
  bool _isNewPatient = true;

  // Controllers for New Patient
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _nikController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthdayController = TextEditingController();

  // Medical & Profiling
  final _medicalRecordController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  // Background
  final _professionController = TextEditingController();

  // Address
  final _rtController = TextEditingController();
  final _rwController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _addressController = TextEditingController();

  // Controllers for Existing Patient
  final _searchController = TextEditingController();

  String _gender = 'Male';
  String _religion = 'Islam';
  String _maritalStatus = 'Belum Menikah';
  String _education = 'S1';
  String _province = 'Jawa Barat';
  String _city = 'Bandung';
  String _district = 'Cicendo';
  String _subdistrict = 'Pasir Kaliki';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Patient Registration',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildToggleButton('New Patient', _isNewPatient, () {
                    setState(() => _isNewPatient = true);
                  }),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildToggleButton(
                    'Existing Patient',
                    !_isNewPatient,
                    () {
                      setState(() => _isNewPatient = false);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: BlocListener<FrontDeskBloc, FrontDeskState>(
        listener: (context, state) {
          if (state is FrontDeskSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            // Reset form after successful registration
            _formKey.currentState?.reset();
            _firstNameController.clear();
            _lastNameController.clear();
            _emailController.clear();
            _nikController.clear();
            _phoneController.clear();
            _birthdayController.clear();
            _medicalRecordController.clear();
            _heightController.clear();
            _weightController.clear();
            _professionController.clear();
            _rtController.clear();
            _rwController.clear();
            _postalCodeController.clear();
            _addressController.clear();
            _searchController.clear();
            setState(() {
              _gender = 'Male';
              _religion = 'Islam';
              _maritalStatus = 'Belum Menikah';
              _education = 'S1';
              _province = 'Jawa Barat';
              _city = 'Bandung';
              _district = 'Cicendo';
              _subdistrict = 'Pasir Kaliki';
            });
          } else if (state is FrontDeskError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: 120,
          ),
          child: _isNewPatient
              ? _buildNewPatientForm()
              : _buildExistingPatientFlow(),
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2859E2) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? const Color(0xFF2859E2) : const Color(0xFFE2E8F0),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF2859E2).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              color: isActive ? Colors.white : const Color(0xFF64748B),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewPatientForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('A. Personal Information'),
          const SizedBox(height: 16),
          _buildCard([
            _buildTextField(
              _firstNameController,
              'First Name',
              Icons.person,
              true,
            ),
            _buildTextField(
              _lastNameController,
              'Last Name',
              Icons.person_outline,
              false,
            ),
            _buildTextField(
              _emailController,
              'Email',
              Icons.email,
              true,
              keyboardType: TextInputType.emailAddress,
            ),
            _buildTextField(
              _nikController,
              'ID / NIK',
              Icons.badge,
              true,
              maxLength: 16,
              keyboardType: TextInputType.number,
            ),
            _buildTextField(
              _phoneController,
              'Phone Number',
              Icons.phone,
              true,
              keyboardType: TextInputType.phone,
            ),
            _buildTextField(
              _birthdayController,
              'Birthday',
              Icons.cake,
              true,
              readOnly: true,
              onTap: () => _selectDate(context),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionTitle('B. Medical & Profiling'),
          const SizedBox(height: 16),
          _buildCard([
            _buildTextField(
              _medicalRecordController,
              'Medical Record No.',
              Icons.assignment_ind,
              false,
            ),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _heightController,
                    'Height (cm)',
                    Icons.height,
                    false,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    _weightController,
                    'Weight (kg)',
                    Icons.monitor_weight,
                    false,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            _buildDropdown(
              'Gender',
              ['Male', 'Female'],
              _gender,
              (v) => setState(() => _gender = v!),
            ),
            _buildDropdown(
              'Religion',
              ['Islam', 'Kristen', 'Katolik', 'Hindu', 'Buddha', 'Konghucu'],
              _religion,
              (v) => setState(() => _religion = v!),
            ),
            _buildDropdown(
              'Marital Status',
              ['Belum Menikah', 'Menikah', 'Cerai Hidup', 'Cerai Mati'],
              _maritalStatus,
              (v) => setState(() => _maritalStatus = v!),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionTitle('C. Background'),
          const SizedBox(height: 16),
          _buildCard([
            _buildTextField(
              _professionController,
              'Profession',
              Icons.work,
              false,
            ),
            _buildDropdown(
              'Education',
              ['SD', 'SMP', 'SMA', 'D3', 'S1', 'S2', 'S3'],
              _education,
              (v) => setState(() => _education = v!),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionTitle('D. Address'),
          const SizedBox(height: 16),
          _buildCard([
            _buildDropdown(
              'Province',
              ['Jawa Barat', 'DKI Jakarta', 'Jawa Tengah'],
              _province,
              (v) => setState(() => _province = v!),
            ),
            _buildDropdown(
              'City',
              ['Bandung', 'Jakarta Selatan', 'Semarang'],
              _city,
              (v) => setState(() => _city = v!),
            ),
            _buildDropdown(
              'Kabupaten',
              ['Cicendo', 'Andir', 'Sukasari'],
              _district,
              (v) => setState(() => _district = v!),
            ),
            _buildDropdown(
              'Kecamatan',
              ['Pasir Kaliki', 'Garuda', 'Isola'],
              _subdistrict,
              (v) => setState(() => _subdistrict = v!),
            ),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(_rtController, 'RT', Icons.map, false),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(_rwController, 'RW', Icons.map, false),
                ),
              ],
            ),
            _buildTextField(
              _postalCodeController,
              'Postal Code',
              Icons.post_add,
              false,
              keyboardType: TextInputType.number,
            ),
            _buildTextField(
              _addressController,
              'Full Address',
              Icons.home,
              true,
              maxLines: 3,
            ),
          ]),
          const SizedBox(height: 40),
          // Reduced width by 40% (20% padding each side)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.20,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submitNewPatient,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2859E2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Register',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildExistingPatientFlow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Search Patient'),
        const SizedBox(height: 16),
        _buildCard([
          _buildTextField(
            _searchController,
            'Input Phone Number or NIK',
            Icons.search,
            true,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _searchPatient,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2859E2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Search',
                style: GoogleFonts.outfit(color: Colors.white),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 24),
        BlocBuilder<FrontDeskBloc, FrontDeskState>(
          buildWhen: (previous, current) =>
              current is PatientSearchResultState ||
              current is FrontDeskLoading,
          builder: (context, state) {
            if (state is FrontDeskLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is PatientSearchResultState) {
              final patient = state.patient;
              if (patient == null) {
                return Center(
                  child: Text(
                    'No patient found',
                    style: GoogleFonts.outfit(color: Colors.red),
                  ),
                );
              }
              return _buildSearchResultCard(patient);
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildSearchResultCard(PatientModel patient) {
    return _buildCard([
      ListTile(
        title: Text(
          "${patient.firstName} ${patient.lastName ?? ''}",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("NIK: ${patient.nik} | Phone: ${patient.phone}"),
        trailing: const Icon(Icons.check_circle, color: Colors.green),
      ),
      const Divider(),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _showVisitOptionsForExistingPatient(patient),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Add to Queue',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
        ),
      ),
    ]);
  }

  void _showVisitOptionsForExistingPatient(PatientModel patient) {
    // Capture bloc reference BEFORE showing dialog
    final frontDeskBloc = context.read<FrontDeskBloc>();

    showDialog(
      context: context,
      builder: (_) => VisitOptionsDialog(
        onConfirm: (type, isPriority) {
          final queueEntry = QueueEntryModel(
            patientName: "${patient.firstName} ${patient.lastName ?? ''}"
                .trim(),
            patient: patient.name ?? '', // name is the ID in Frappe
            status: 'Waiting',
            queueType: type,
            isPriority: isPriority ? 1 : 0,
            practitioner: type == 'Doctor' ? 'TBD' : null,
          );
          // Use captured bloc reference instead of context.read
          frontDeskBloc.add(AddToQueueEvent(queueEntry));
        },
      ),
    );
  }

  // Reuse existing helper methods like _buildSectionTitle, _buildCard, _buildTextField, _buildDropdown, _selectDate

  void _submitNewPatient() {
    if (_formKey.currentState!.validate()) {
      // Logic for post-registration (selection of doctor, priority, etc.)
      _showVisitOptionsDialog();
    }
  }

  void _searchPatient() {
    if (_searchController.text.isNotEmpty) {
      context.read<FrontDeskBloc>().add(
        SearchPatientEvent(_searchController.text),
      );
    }
  }

  void _showVisitOptionsDialog() {
    // Capture bloc reference BEFORE showing dialog
    final frontDeskBloc = context.read<FrontDeskBloc>();

    showDialog(
      context: context,
      builder: (_) => VisitOptionsDialog(
        onConfirm: (type, isPriority) {
          final patient = PatientModel(
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
            email: _emailController.text,
            nik: _nikController.text,
            phone: _phoneController.text,
            birthday: _birthdayController.text,
            medicalRecordNo: _medicalRecordController.text,
            heightCm: int.tryParse(_heightController.text),
            weightKg: int.tryParse(_weightController.text),
            gender: _gender,
            religion: _religion,
            maritalStatus: _maritalStatus,
            education: _education,
            profession: _professionController.text,
            province: _province,
            city: _city,
            district: _district,
            subdistrict: _subdistrict,
            rt: _rtController.text,
            rw: _rwController.text,
            postalCode: _postalCodeController.text,
            fullAddress: _addressController.text,
          );
          frontDeskBloc.add(
            RegisterAndAddQueueEvent(
              patient: patient,
              queueType: type,
              isPriority: isPriority,
            ),
          );
          // Navigator.pop removed - dialogs handle their own closing
        },
      ),
    );
  }

  // Keep these helper methods at the end

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children:
            children.expand((w) => [w, const SizedBox(height: 16)]).toList()
              ..removeLast(),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    bool required, {
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF2859E2)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      validator: (value) {
        if (required && (value == null || value.isEmpty)) return 'Required';
        if (label.contains('NIK') && value != null && value.length != 16) {
          return 'NIK must be 16 digits';
        }
        return null;
      },
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(e, style: GoogleFonts.outfit(fontSize: 14)),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.list, size: 20, color: Color(0xFF2859E2)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthdayController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }
}

class VisitOptionsDialog extends StatefulWidget {
  final Function(String type, bool isPriority) onConfirm;
  const VisitOptionsDialog({super.key, required this.onConfirm});
  @override
  State<VisitOptionsDialog> createState() => _VisitOptionsDialogState();
}

class _VisitOptionsDialogState extends State<VisitOptionsDialog> {
  String _type = 'Doctor';
  String? _selectedDoctor;
  String? _selectedPolyclinic;
  bool _isPriority = false;

  // Sample doctor list (would be loaded from API in production)
  final List<Map<String, String>> _doctors = [
    {'id': 'PRAC-0001', 'name': 'Dr. Andi Wijaya', 'specialty': 'Umum'},
    {'id': 'PRAC-0002', 'name': 'Dr. Siti Rahayu', 'specialty': 'Anak'},
    {'id': 'PRAC-0003', 'name': 'Dr. Budi Santoso', 'specialty': 'Gigi'},
    {'id': 'PRAC-0004', 'name': 'Dr. Maya Putri', 'specialty': 'Kulit'},
    {'id': 'PRAC-0005', 'name': 'Dr. Ahmad Fauzi', 'specialty': 'Mata'},
  ];

  // Sample polyclinic list
  final List<Map<String, String>> _polyclinics = [
    {'id': 'POLY-0001', 'name': 'Poli Umum'},
    {'id': 'POLY-0002', 'name': 'Poli Gigi'},
    {'id': 'POLY-0003', 'name': 'Poli Anak'},
    {'id': 'POLY-0004', 'name': 'Poli Kulit'},
    {'id': 'POLY-0005', 'name': 'Poli Mata'},
    {'id': 'POLY-0006', 'name': 'Poli Kebidanan'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedDoctor = _doctors.first['id'];
    _selectedPolyclinic = _polyclinics.first['id'];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Select Visit Type',
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Visit Type Selection
            RadioListTile<String>(
              title: const Text('Doctor'),
              value: 'Doctor',
              groupValue: _type,
              onChanged: (v) => setState(() => _type = v!),
            ),
            RadioListTile<String>(
              title: const Text('Polyclinic'),
              value: 'Polyclinic',
              groupValue: _type,
              onChanged: (v) => setState(() => _type = v!),
            ),

            const Divider(),

            // Doctor Selection (shown when Doctor is selected)
            if (_type == 'Doctor') ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  'Select Doctor:',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDoctor,
                    isExpanded: true,
                    items: _doctors.map((doctor) {
                      return DropdownMenuItem<String>(
                        value: doctor['id'],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              doctor['name']!,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Spesialis ${doctor['specialty']}',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedDoctor = value),
                  ),
                ),
              ),
            ],

            // Polyclinic Selection (shown when Polyclinic is selected)
            if (_type == 'Polyclinic') ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  'Select Polyclinic:',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPolyclinic,
                    isExpanded: true,
                    items: _polyclinics.map((poly) {
                      return DropdownMenuItem<String>(
                        value: poly['id'],
                        child: Text(
                          poly['name']!,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedPolyclinic = value),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 8),
            const Divider(),

            CheckboxListTile(
              title: const Text('Priority Patient'),
              subtitle: Text(
                'Move to front of queue',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              value: _isPriority,
              onChanged: (v) => setState(() => _isPriority = v!),
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
          onPressed: () {
            Navigator.pop(context);
            // Show payment dialog
            showDialog(
              context: context,
              builder: (ctx) => PaymentDialog(
                onConfirm: (paymentMethod) {
                  widget.onConfirm(_type, _isPriority);
                },
              ),
            );
          },
          child: const Text('Continue to Payment'),
        ),
      ],
    );
  }
}

// Payment Dialog
class PaymentDialog extends StatefulWidget {
  final Function(String paymentMethod) onConfirm;
  const PaymentDialog({super.key, required this.onConfirm});
  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  String _paymentMethod = 'Cash';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Payment Method',
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select payment method for records (Actual payment at POS)',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          RadioListTile<String>(
            title: const Text('Cash'),
            subtitle: const Text('Pay at counter'),
            value: 'Cash',
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v!),
          ),
          RadioListTile<String>(
            title: const Text('BPJS'),
            subtitle: const Text('National health insurance'),
            value: 'BPJS',
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v!),
          ),
          RadioListTile<String>(
            title: const Text('Insurance'),
            subtitle: const Text('Private insurance'),
            value: 'Insurance',
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v!),
          ),
          RadioListTile<String>(
            title: const Text('Credit Card'),
            subtitle: const Text('Debit/Credit card'),
            value: 'Credit Card',
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
          ),
          onPressed: () {
            // Get root scaffold messenger before closing dialog
            final scaffoldMessenger = ScaffoldMessenger.of(context);

            Navigator.pop(context);
            widget.onConfirm(_paymentMethod);

            // Show success message
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Patient added to queue!',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Payment: $_paymentMethod (recorded)',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          },
          child: Text(
            'Confirm Payment',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
