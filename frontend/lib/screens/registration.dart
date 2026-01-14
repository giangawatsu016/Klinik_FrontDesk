import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class RegistrationScreen extends StatefulWidget {
  final ApiService apiService;

  const RegistrationScreen({super.key, required this.apiService});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

enum RegistrationStep { selectType, inputData, selectDoctor }

enum PatientType { newPatient, existingPatient }

class _RegistrationScreenState extends State<RegistrationScreen> {
  RegistrationStep _currentStep = RegistrationStep.selectType;
  PatientType? _patientType;
  Patient? _verifiedPatient;

  // Existing Patient Search
  final TextEditingController _searchController = TextEditingController();
  List<Patient> _searchResults = [];
  bool _isSearching = false;

  // New Patient Form Key
  final _formKey = GlobalKey<FormState>();
  final _doctorFormKey =
      GlobalKey<FormState>(); // Added validation key for Doctor Step

  // New Patient Data
  String firstName = '';
  String lastName = '';
  String phone = '';
  String identityCard = '';
  String gender = 'Male';
  DateTime birthday = DateTime(2000, 1, 1);

  // New Fields
  String religion = 'Islam';
  String profession = '';
  String education = 'Bachelor';
  String province = '';
  String city = '';
  String district = '';
  String subdistrict = '';
  String rt = '';
  String rw = '';
  String postalCode = '';
  String addressDetails = '';

  int issuerId = 1; // 1=General, 2=BPJS, 3=Insurance
  String? insuranceName;
  String noAssuransi = '';
  int maritalStatusId = 1; // 1=Single, 2=Married, 3=Divorced, 4=Widowed

  // Doctor Selection
  List<Doctor> doctors = [];
  Doctor? selectedDoctor;
  bool isPriority = false;

  // Dynamic Address Data
  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _subdistricts = [];

  String? _selectedProvinceId;
  String? _selectedCityId;
  String? _selectedDistrictId;
  String? _selectedSubdistrictId;

  final List<String> religions = [
    'Islam',
    'Kristen',
    'Katolik',
    'Hindu',
    'Buddha',
    'Konghucu',
    'Lainnya',
  ];
  final List<String> educations = [
    'SD',
    'SMP',
    'SMA',
    'Diploma',
    'Bachelor',
    'Master',
    'Doctorate',
  ];

  // Hardcoded for demo, normally from backend
  final Map<int, String> issuers = {
    1: 'Umum (General)',
    2: 'BPJS',
    3: 'Asuransi (Insurance)',
  };
  final Map<int, String> maritalStatuses = {
    1: 'Single',
    2: 'Married',
    3: 'Divorced',
    4: 'Widowed',
  };

  @override
  void initState() {
    super.initState();
    _loadDoctors();
    _loadProvinces();
  }

  void _loadProvinces() async {
    final res = await widget.apiService.getProvinces();
    if (mounted) setState(() => _provinces = res);
  }

  void _onProvinceChanged(String? val) async {
    if (val == null) return;
    setState(() {
      _selectedProvinceId = val;
      _selectedCityId = null;
      _selectedDistrictId = null;
      _selectedSubdistrictId = null;
      _cities = [];
      _districts = [];
      _subdistricts = [];

      // Update Name for Submission
      province = _provinces.firstWhere((e) => e['id'] == val)['name'];
      city = '';
      district = '';
      subdistrict = '';
    });

    final res = await widget.apiService.getCities(val);
    if (mounted) setState(() => _cities = res);
  }

  void _onCityChanged(String? val) async {
    if (val == null) return;
    setState(() {
      _selectedCityId = val;
      _selectedDistrictId = null;
      _selectedSubdistrictId = null;
      _districts = [];
      _subdistricts = [];

      city = _cities.firstWhere((e) => e['id'] == val)['name'];
      district = '';
      subdistrict = '';
    });

    final res = await widget.apiService.getDistricts(val);
    if (mounted) setState(() => _districts = res);
  }

  void _onDistrictChanged(String? val) async {
    if (val == null) return;
    setState(() {
      _selectedDistrictId = val;
      _selectedSubdistrictId = null;
      _subdistricts = [];

      district = _districts.firstWhere((e) => e['id'] == val)['name'];
      subdistrict = '';
    });

    final res = await widget.apiService.getSubdistricts(val);
    if (mounted) setState(() => _subdistricts = res);
  }

  void _onSubdistrictChanged(String? val) {
    if (val == null) return;
    setState(() {
      _selectedSubdistrictId = val;
      subdistrict = _subdistricts.firstWhere((e) => e['id'] == val)['name'];
    });
  }

  void _loadDoctors() async {
    final docs = await widget.apiService.getDoctors();
    if (!mounted) return;
    setState(() {
      doctors = docs;
    });
  }

  void _searchPatient() async {
    if (_searchController.text.isEmpty) return;
    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final results = await widget.apiService.searchPatients(
        _searchController.text,
      );
      if (mounted) {
        setState(() {
          _searchResults = results;
        });
        if (results.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('No patient found')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Search Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectExistingPatient(Patient patient) {
    setState(() {
      _verifiedPatient = patient;
      _currentStep = RegistrationStep.selectDoctor;
    });
  }

  void _submitNewPatient() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newPatient = Patient(
        firstName: firstName,
        lastName: lastName,
        identityCard: identityCard,
        phone: phone,
        gender: gender,
        birthday: birthday.toIso8601String().substring(0, 10),
        religion: religion,
        profession: profession,
        education: education,
        province: province,
        city: city,
        district: district,
        subdistrict: subdistrict,
        rt: rt,
        rw: rw,
        postalCode: postalCode,
        addressDetails: addressDetails,
        issuerId: issuerId,
        insuranceName: insuranceName,
        noAssuransi: noAssuransi,
        maritalStatusId: maritalStatusId,
      );

      try {
        final createdPatient = await widget.apiService.registerPatient(
          newPatient,
        );

        if (!mounted) return;

        setState(() {
          _verifiedPatient = createdPatient;
          _currentStep = RegistrationStep.selectDoctor;
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _submitToQueue() async {
    try {
      // Validate Doctor/Polyclinic Selection
      if (!_doctorFormKey.currentState!.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a Doctor or Polyclinic'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_verifiedPatient == null || _verifiedPatient!.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: Patient data is invalid. Please search again.',
            ),
          ),
        );
        return;
      }

      final success = await widget.apiService.addToQueue(
        patientId: _verifiedPatient!.id!,
        doctorId: !_isPolyclinic
            ? selectedDoctor!.medicalFacilityPolyDoctorId
            : null,
        isPriority: isPriority,
        queueType: _isPolyclinic ? "Polyclinic" : "Doctor",
        polyclinic: _isPolyclinic ? _selectedPolyclinic : null,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Patient Registered & Queued Successfully',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Reset
        setState(() {
          _currentStep = RegistrationStep.selectType;
          _verifiedPatient = null;
          _patientType = null;
          _searchController.clear();
          _searchResults = [];
          selectedDoctor = null;
          _selectedPolyclinic = null;
          isPriority = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to queue. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Build Header / Progress
          _buildHeader(),
          SizedBox(height: 20),
          Expanded(child: _buildCurrentStep()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Text(
      _currentStep == RegistrationStep.selectType
          ? "Select Registration Type"
          : _currentStep == RegistrationStep.inputData
          ? (_patientType == PatientType.newPatient
                ? "New Patient Registration"
                : "Find Existing Patient")
          : "Assign Doctor",
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case RegistrationStep.selectType:
        return _buildSelectType();
      case RegistrationStep.inputData:
        return _patientType == PatientType.newPatient
            ? _buildNewPatientForm()
            : _buildExistingPatientSearch();
      case RegistrationStep.selectDoctor:
        return _buildDoctorSelection();
    }
  }

  Widget _buildSelectType() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _typeCard("New Patient", Icons.person_add, PatientType.newPatient),
        SizedBox(width: 20),
        _typeCard(
          "Existing Patient",
          Icons.person_search,
          PatientType.existingPatient,
        ),
      ],
    );
  }

  Widget _typeCard(String title, IconData icon, PatientType type) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _patientType = type;
          _currentStep = RegistrationStep.inputData;
        });
      },
      child: Card(
        elevation: 4,
        child: Container(
          width: 200,
          height: 200,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: Colors.blue),
              SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExistingPatientSearch() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                maxLength: 16,
                decoration: InputDecoration(
                  labelText: "Search by ID (NIK) or Phone",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                  counterText: "",
                ),
              ),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: _isSearching ? null : _searchPatient,
              child: _isSearching
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Search"),
            ),
          ],
        ),
        SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (ctx, i) {
              final p = _searchResults[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(p.firstName[0])),
                  title: Text("${p.firstName} ${p.lastName}"),
                  subtitle: Text("ID: ${p.identityCard} | Phone: ${p.phone}"),
                  trailing: ElevatedButton(
                    onPressed: () => _selectExistingPatient(p),
                    child: Text("Select"),
                  ),
                ),
              );
            },
          ),
        ),
        TextButton(
          onPressed: () =>
              setState(() => _currentStep = RegistrationStep.selectType),
          child: Text("Back"),
        ),
      ],
    );
  }

  Widget _buildNewPatientForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildSectionTitle("Personal Information"),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(labelText: 'First Name'),
                    onSaved: (v) => firstName = v!,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(labelText: 'Last Name'),
                    onSaved: (v) => lastName = v ?? '',
                    validator: null,
                  ),
                ),
              ],
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'ID Card (NIK)'),
              keyboardType: TextInputType.number,
              maxLength: 16,
              onSaved: (v) => identityCard = v!,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v.length != 16) return 'NIK must be exactly 16 digits';
                if (!RegExp(r'^[0-9]+$').hasMatch(v)) return 'Numeric only';
                return null;
              },
            ),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Phone',
                counterText:
                    "", // Hide default counter if desired, or keep it. I'll hide it for cleaner UI but enforce limit
              ),
              maxLength: 14,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onSaved: (v) => phone = v!,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            _buildDatePicker(),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: gender,
                    decoration: InputDecoration(labelText: 'Gender'),
                    items: ['Male', 'Female']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => gender = v!),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: religion,
                    decoration: InputDecoration(labelText: 'Religion'),
                    items: religions
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => religion = v!),
                  ),
                ),
              ],
            ),
            DropdownButtonFormField<int>(
              // ignore: deprecated_member_use
              value: maritalStatusId,
              decoration: InputDecoration(labelText: 'Marital Status'),
              items: maritalStatuses.entries
                  .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => maritalStatusId = v!),
            ),

            _buildSectionTitle("Background"),
            TextFormField(
              decoration: InputDecoration(labelText: 'Profession'),
              onSaved: (v) => profession = v!,
            ),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: education,
              decoration: InputDecoration(labelText: 'Education'),
              items: educations
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => education = v!),
            ),

            _buildSectionTitle("Address"),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey("prov_$_selectedProvinceId"),
                    initialValue: _selectedProvinceId,
                    decoration: InputDecoration(labelText: 'Province'),
                    items: _provinces
                        .map(
                          (e) => DropdownMenuItem(
                            value: e['id'] as String,
                            child: Text(e['name']),
                          ),
                        )
                        .toList(),
                    onChanged: _onProvinceChanged,
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey("city_$_selectedCityId"),
                    initialValue: _selectedCityId,
                    decoration: InputDecoration(labelText: 'City'),
                    items: _cities
                        .map(
                          (e) => DropdownMenuItem(
                            value: e['id'] as String,
                            child: Text(e['name']),
                          ),
                        )
                        .toList(),
                    onChanged: _onCityChanged,
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey("dist_$_selectedDistrictId"),
                    initialValue: _selectedDistrictId,
                    decoration: InputDecoration(labelText: 'District'),
                    items: _districts
                        .map(
                          (e) => DropdownMenuItem(
                            value: e['id'] as String,
                            child: Text(e['name']),
                          ),
                        )
                        .toList(),
                    onChanged: _onDistrictChanged,
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey("sub_$_selectedSubdistrictId"),
                    initialValue: _selectedSubdistrictId,
                    decoration: InputDecoration(labelText: 'Subdistrict'),
                    items: _subdistricts
                        .map(
                          (e) => DropdownMenuItem(
                            value: e['id'] as String,
                            child: Text(e['name']),
                          ),
                        )
                        .toList(),
                    onChanged: _onSubdistrictChanged,
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(labelText: 'RT'),
                    onSaved: (v) => rt = v!,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(labelText: 'RW'),
                    onSaved: (v) => rw = v!,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(labelText: 'Postal Code'),
                    onSaved: (v) => postalCode = v!,
                  ),
                ),
              ],
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Full Address'),
              onSaved: (v) => addressDetails = v!,
            ),

            _buildSectionTitle("Pembayaran"),
            DropdownButtonFormField<int>(
              // ignore: deprecated_member_use
              value: issuerId,
              decoration: InputDecoration(labelText: 'Metode Pembayaran'),
              items: issuers.entries
                  .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() {
                  issuerId = v!;
                  insuranceName = null; // Reset sub-selection
                });
              },
            ),
            if (issuerId == 2) // BPJS
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: DropdownButtonFormField<String>(
                  initialValue: insuranceName,
                  decoration: InputDecoration(labelText: 'BPJS Type'),
                  items: ['BPJS Kesehatan', 'BPJS Ketenagakerjaan']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => insuranceName = v),
                  validator: (v) =>
                      v == null ? 'Please select BPJS Type' : null,
                ),
              ),
            if (issuerId == 3) // Insurance
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: DropdownButtonFormField<String>(
                  initialValue: insuranceName,
                  decoration: InputDecoration(labelText: 'Insurance Provider'),
                  items: ['Allianz', 'Prudential', 'Manulife']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => insuranceName = v),
                  validator: (v) => v == null ? 'Please select Provider' : null,
                ),
              ),
            if (issuerId != 1)
              TextFormField(
                decoration: InputDecoration(labelText: 'Insurance Number'),
                onSaved: (v) => noAssuransi = v!,
                validator: (v) => v!.isEmpty ? 'Required for Insurance' : null,
              ),

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitNewPatient,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 20),
              ),
              child: Text("Register & Proceed"),
            ),
            TextButton(
              onPressed: () =>
                  setState(() => _currentStep = RegistrationStep.selectType),
              child: Text("Back"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: birthday,
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) setState(() => birthday = picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: 'Birthday'),
        child: Text("${birthday.day}/${birthday.month}/${birthday.year}"),
      ),
    );
  }

  bool _isPolyclinic = false;
  String? _selectedPolyclinic;

  Widget _buildDoctorSelection() {
    // Extract unique polyclinics from doctors
    final Set<String> polyclinics = doctors.map((d) => d.polyName).toSet();

    return Form(
      key: _doctorFormKey,
      child: Column(
        children: [
          if (_verifiedPatient != null)
            Card(
              color: Colors.green.shade50,
              child: ListTile(
                title: Text(
                  "Patient: ${_verifiedPatient!.firstName} ${_verifiedPatient!.lastName}",
                ),
                subtitle: Text("ID: ${_verifiedPatient!.identityCard}"),
                leading: Icon(Icons.check_circle, color: Colors.green),
              ),
            ),
          SizedBox(height: 20),

          // Toggle Type
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isPolyclinic = false),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: !_isPolyclinic ? Colors.blue : Colors.grey[200],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "Select Doctor",
                        style: TextStyle(
                          color: !_isPolyclinic ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isPolyclinic = true),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isPolyclinic ? Colors.blue : Colors.grey[200],
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "Go to Polyclinic",
                        style: TextStyle(
                          color: _isPolyclinic ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          if (!_isPolyclinic)
            DropdownButtonFormField<Doctor>(
              decoration: InputDecoration(
                labelText: 'Select Doctor',
                border: OutlineInputBorder(),
              ),
              // ignore: deprecated_member_use
              value: selectedDoctor,
              items: doctors
                  .map(
                    (d) => DropdownMenuItem(
                      value: d,
                      child: Text(
                        "${d.gelarDepan} ${d.namaDokter} (${d.polyName})",
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => selectedDoctor = v),
              validator: (v) => v == null ? 'Please select a Doctor' : null,
            )
          else
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Polyclinic',
                border: OutlineInputBorder(),
              ),
              // ignore: deprecated_member_use
              value: _selectedPolyclinic,
              items: polyclinics
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedPolyclinic = v),
              validator: (v) => v == null ? 'Please select a Polyclinic' : null,
            ),

          CheckboxListTile(
            title: Text("Priority Patient"),
            value: isPriority,
            onChanged: (v) => setState(() => isPriority = v!),
          ),
          Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () =>
                    setState(() => _currentStep = RegistrationStep.inputData),
                child: Text("Back"),
              ),
              ElevatedButton(
                onPressed: _submitToQueue,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                ),
                child: Text("Assign to Queue"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
