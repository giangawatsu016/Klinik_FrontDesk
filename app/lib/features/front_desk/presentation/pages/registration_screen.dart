// ignore_for_file: deprecated_member_use, dead_code
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/front_desk_bloc.dart';
import '../bloc/front_desk_event.dart';
import '../bloc/front_desk_state.dart';
import '../../data/models/issuer_model.dart';
import '../../data/models/patient_model.dart';
import '../../data/models/practitioner_model.dart';
import '../../data/models/polyclinic_model.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // No longer using toggle, unified form
  // bool _isNewPatient = true;

  // Controllers for New Patient
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _nikController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthdayController = TextEditingController();

  // Medical & Profiling
  final _heightController = TextEditingController();

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
  String _patientStatus = 'Dewasa';
  String _religion = 'Islam';
  String _maritalStatus = 'Single';
  String _education = 'Sarjana (S1)';
  String _province = 'Jawa Barat';
  String _city = 'Bandung';
  String _district = 'Cicendo';
  String _subdistrict = 'Pasir Kaliki';

  List<PractitionerModel> _practitioners = [];
  List<PolyclinicModel> _polyclinics = [];

  String? _selectedPatientName;
  @override
  void initState() {
    super.initState();
    context.read<FrontDeskBloc>().add(
      const FetchPractitionersAndPolyclinicsEvent(),
    );
  }

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
      ),
      body: BlocListener<FrontDeskBloc, FrontDeskState>(
        listener: (context, state) {
          if (state is FrontDeskSuccess) {
            // Automatically navigate to Queue Monitor after successful registration/queue addition
            if (state.message.contains(
              'Registered and added to queue successfully',
            )) {
              // Navigation handled by HomePage BlocListener
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            _formKey.currentState?.reset();
            _firstNameController.clear();
            _lastNameController.clear();
            _emailController.clear();
            _nikController.clear();
            _phoneController.clear();
            _birthdayController.clear();
            _heightController.clear();
            _professionController.clear();
            _rtController.clear();
            _rwController.clear();
            _postalCodeController.clear();
            _addressController.clear();
            _searchController.clear();
            setState(() {
              _gender = 'Male';
              _patientStatus = 'Dewasa';
              _religion = 'Islam';
              _maritalStatus = 'Single';
              _education = 'Sarjana (S1)';
              _province = 'Jawa Barat';
              _city = 'Bandung';
              _district = 'Cicendo';
              _subdistrict = 'Pasir Kaliki';
              _selectedPatientName = null;
            });
          } else if (state is FrontDeskError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('DEBUG ERROR: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is FrontDeskLoading) {
            // Removed debug snackbar for loading
          } else if (state is PractitionersAndPolyclinicsLoaded) {
            setState(() {
              _practitioners = state.practitioners;
              _polyclinics = state.polyclinics;
            });
          } else if (state is PatientSearchResultState) {
            if (state.patients.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No patient found with that query'),
                  backgroundColor: Colors.orange,
                ),
              );
            } else if (state.patients.length == 1) {
              _fillPatientForm(state.patients.first);
            } else {
              _showPatientSelectionDialog(state.patients);
            }
          }
        },
        child: BlocBuilder<FrontDeskBloc, FrontDeskState>(
          builder: (context, state) {
            return Column(
              children: [
                if (state is FrontDeskLoading)
                  const LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF2859E2),
                    ),
                    minHeight: 2,
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 24,
                      bottom: 120,
                    ),
                    child: _buildUnifiedRegistrationForm(),
                  ),
                ),
              ],
            );
          },
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
              false,
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
                  child: _buildDropdown(
                    'Status',
                    ['Dewasa', 'Baru Lahir'],
                    _patientStatus,
                    (v) => setState(() => _patientStatus = v!),
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
              [
                'Islam',
                'Christian',
                'Catholic',
                'Hindu',
                'Buddhist',
                'Confucian',
                'Other',
              ],
              _religion,
              (v) => setState(() => _religion = v!),
            ),
            _buildDropdown(
              'Marital Status',
              ['Single', 'Married', 'Divorced', 'Widowed'],
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
              [
                'SD',
                'SMP',
                'SMA/SMK',
                'Diploma',
                'Sarjana (S1)',
                'Magister (S2)',
                'Doktor (S3)',
                'Other',
              ],
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
              hintText: 'Jl. Kaum No.2',
            ),
          ]),
          const SizedBox(height: 40),
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

  Widget _buildUnifiedRegistrationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Search Patient'),
        const SizedBox(height: 16),
        _buildCard([
          _buildTextField(
            _searchController,
            'Input Name, Phone Number, or NIK',
            Icons.search,
            false,
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
                'Search Patient',
                style: GoogleFonts.outfit(color: Colors.white),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 32),
        _buildNewPatientForm(),
      ],
    );
  }

  void _submitNewPatient() {
    if (_formKey.currentState!.validate()) {
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

  void _finalizeQueueAddition(
    String type,
    bool isPriority,
    String? selectedId,
    IssuerModel issuer,
  ) {
    final patient = PatientModel(
      name: _selectedPatientName,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      nik: _nikController.text,
      phone: _phoneController.text,
      birthday: _birthdayController.text,
      heightCm: int.tryParse(_heightController.text),
      gender: _gender,
      patientStatus: _patientStatus,
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

    context.read<FrontDeskBloc>().add(
      RegisterAndAddQueueEvent(
        patient: patient,
        queueType: type,
        isPriority: isPriority,
        selectedId: selectedId,
        paymentMethod: issuer.name,
      ),
    );
  }

  void _showVisitOptionsDialog() {
    showDialog(
      context: context,
      builder: (_) => VisitOptionsDialog(
        practitioners: _practitioners,
        polyclinics: _polyclinics,
        onConfirm: (type, isPriority, selectedId, issuer) {
          _finalizeQueueAddition(type, isPriority, selectedId, issuer);
        },
      ),
    );
  }

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
            color: Colors.black.withOpacity(0.05),
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
    String? hintText,
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
        hintText: hintText,
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
    // Safety check: ensure value exists in items
    final effectiveValue = items.contains(value) ? value : items.first;

    return DropdownButtonFormField<String>(
      value: effectiveValue,
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

  void _fillPatientForm(PatientModel patient) {
    setState(() {
      _selectedPatientName = patient.name;
      _firstNameController.text = patient.firstName;
      _lastNameController.text = patient.lastName ?? '';
      _emailController.text = patient.email;
      _nikController.text = patient.nik;
      _phoneController.text = patient.phone;
      _birthdayController.text = patient.birthday;
      _heightController.text = patient.heightCm?.toString() ?? '';
      _gender = patient.gender;
      _patientStatus = patient.patientStatus ?? 'Dewasa';
      _religion = patient.religion;
      _maritalStatus = patient.maritalStatus;
      _professionController.text = patient.profession ?? '';
      _education = patient.education;
      _province = patient.province;
      _city = patient.city;
      _district = patient.district;
      _subdistrict = patient.subdistrict;
      _rtController.text = patient.rt ?? '';
      _rwController.text = patient.rw ?? '';
      _postalCodeController.text = patient.postalCode ?? '';
      _addressController.text = patient.fullAddress;
    });
  }

  void _showPatientSelectionDialog(List<PatientModel> patients) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Select Patient',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: patients.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final patient = patients[index];
              return ListTile(
                title: Text(
                  '${patient.firstName} ${patient.lastName ?? ''}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          patient.name != null &&
                                  !patient.name!.startsWith('EXT')
                              ? Icons.storage
                              : Icons.cloud_off,
                          size: 14,
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'NIK: ${patient.nik}',
                          style: GoogleFonts.outfit(fontSize: 12),
                        ),
                      ],
                    ),
                    Text(
                      'Phone: ${patient.phone}',
                      style: GoogleFonts.outfit(fontSize: 12),
                    ),
                    Text(
                      'DOB: ${patient.birthday}',
                      style: GoogleFonts.outfit(fontSize: 12),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.pop(context);
                  _fillPatientForm(patient);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
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
  final List<PractitionerModel> practitioners;
  final List<PolyclinicModel> polyclinics;
  final Function(
    String type,
    bool isPriority,
    String? selectedId,
    IssuerModel issuer,
  )
  onConfirm;

  const VisitOptionsDialog({
    super.key,
    required this.practitioners,
    required this.polyclinics,
    required this.onConfirm,
  });

  @override
  State<VisitOptionsDialog> createState() => _VisitOptionsDialogState();
}

class _VisitOptionsDialogState extends State<VisitOptionsDialog> {
  String _type = 'Doctor';
  String? _selectedDoctor;
  String? _selectedPolyclinic;
  bool _isPriority = false;

  @override
  void initState() {
    super.initState();
    if (widget.practitioners.isNotEmpty) {
      _selectedDoctor = widget.practitioners.first.id;
    }
    if (widget.polyclinics.isNotEmpty) {
      _selectedPolyclinic = widget.polyclinics.first.id;
    }
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
              if (widget.practitioners.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'No doctors available',
                    style: TextStyle(color: Colors.orange),
                  ),
                )
              else
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
                      items: widget.practitioners.map((doctor) {
                        return DropdownMenuItem<String>(
                          value: doctor.id,
                          child: Text(doctor.name),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedDoctor = value),
                    ),
                  ),
                ),
            ],
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
                    items: widget.polyclinics.map((poly) {
                      return DropdownMenuItem<String>(
                        value: poly.id,
                        child: Text(poly.name),
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
          onPressed:
              (_type == 'Doctor' &&
                      (_selectedDoctor == null ||
                          widget.practitioners.isEmpty)) ||
                  (_type == 'Polyclinic' && _selectedPolyclinic == null)
              ? null
              : () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (ctx) => PaymentDialog(
                      onConfirm: (issuer) {
                        final String? selectedId = _type == 'Doctor'
                            ? _selectedDoctor
                            : _selectedPolyclinic;
                        widget.onConfirm(
                          _type,
                          _isPriority,
                          selectedId,
                          issuer,
                        );
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

class PaymentDialog extends StatefulWidget {
  final Function(IssuerModel issuer) onConfirm;
  const PaymentDialog({super.key, required this.onConfirm});
  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  IssuerModel? _selectedIssuer;

  @override
  void initState() {
    super.initState();
    context.read<FrontDeskBloc>().add(const FetchIssuersEvent());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Payment Method',
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      ),
      content: BlocBuilder<FrontDeskBloc, FrontDeskState>(
        builder: (context, state) {
          if (state is FrontDeskLoading) {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (state is IssuersLoaded) {
            if (state.issuers.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No payment methods found in the system.'),
                ),
              );
            }
            final Map<String, List<IssuerModel>> groups = {};
            for (var issuer in state.issuers) {
              final cat = issuer.category ?? 'Other';
              groups.putIfAbsent(cat, () => []).add(issuer);
            }

            // Define custom order for groups
            final orderedKeys = ['CASH', 'BPJS', 'ASURANSI'];
            final remainingKeys = groups.keys
                .where((k) => !orderedKeys.contains(k))
                .toList();
            final sortedKeys = [
              ...orderedKeys.where((k) => groups.containsKey(k)),
              ...remainingKeys,
            ];

            return SizedBox(
              width: 400,
              height: 400,
              child: ListView(
                shrinkWrap: true,
                children: [
                  ...sortedKeys.map((key) {
                    final issuers = groups[key]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            key.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2859E2),
                            ),
                          ),
                        ),
                        ...issuers.map(
                          (issuer) => RadioListTile<IssuerModel>(
                            title: Text(
                              issuer.name,
                              style: GoogleFonts.outfit(fontSize: 14),
                            ),
                            value: issuer,
                            groupValue: _selectedIssuer,
                            onChanged: (v) =>
                                setState(() => _selectedIssuer = v),
                          ),
                        ),
                        const Divider(),
                      ],
                    );
                  }),
                ],
              ),
            );
          }
          if (state is FrontDeskError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error: ${state.message}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return const Center(child: Text('Loading issuers...'));
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedIssuer == null
              ? null
              : () {
                  Navigator.pop(context);
                  widget.onConfirm(_selectedIssuer!);
                },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
