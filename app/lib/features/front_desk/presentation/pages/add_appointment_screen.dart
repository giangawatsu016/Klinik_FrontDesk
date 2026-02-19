import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/front_desk_bloc.dart';
import '../bloc/front_desk_event.dart';
import '../bloc/front_desk_state.dart';
import '../../data/models/practitioner_model.dart';
import '../../data/models/polyclinic_model.dart';
import '../../../appointment/presentation/blocs/appointment_bloc.dart';
import '../../../appointment/domain/entities/appointment_entity.dart';

class AddAppointmentScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  const AddAppointmentScreen({super.key, this.onSuccess});

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _dateController = TextEditingController();

  // Visit type selection
  String _visitType = 'Doctor'; // 'Doctor' or 'Polyclinic'

  // Doctor selection
  String? _selectedDoctorId;
  String? _selectedDoctorName;
  List<PractitionerModel> _practitioners = [];

  // Polyclinic selection
  String? _selectedPolyclinicId;
  String? _selectedPolyclinicName;
  List<PolyclinicModel> _polyclinics = [];

  @override
  void initState() {
    super.initState();
    final bloc = context.read<FrontDeskBloc>();
    // Pre-populate if already loaded
    if (bloc.state is PractitionersAndPolyclinicsLoaded) {
      final state = bloc.state as PractitionersAndPolyclinicsLoaded;
      _practitioners = state.practitioners;
      _polyclinics = state.polyclinics;
      _initDefaults();
    }
    // Always fetch to ensure fresh data (BlocListener will catch the result)
    bloc.add(FetchPractitionersAndPolyclinicsEvent());
  }

  void _initDefaults() {
    if (_selectedDoctorId == null && _practitioners.isNotEmpty) {
      _selectedDoctorId = _practitioners.first.id;
      _selectedDoctorName = _practitioners.first.name;
    }
    if (_selectedPolyclinicId == null && _polyclinics.isNotEmpty) {
      _selectedPolyclinicId = _polyclinics.first.id;
      _selectedPolyclinicName = _polyclinics.first.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppointmentBloc, AppointmentState>(
      listener: (context, state) {
        if (state is AppointmentSuccess) {
          final debugCount =
              state.appointment.patientDetail?['_debug_total_count'];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Schedule added successfully${debugCount != null ? ' (DB Total: $debugCount)' : ''}',
              ),
              backgroundColor: Colors.green,
            ),
          );
          _patientNameController.clear();
          _dateController.clear();
          // Navigate to Jadwal Kunjungan
          widget.onSuccess?.call();
        } else if (state is AppointmentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: BlocListener<FrontDeskBloc, FrontDeskState>(
        listener: (context, state) {
          if (state is PractitionersAndPolyclinicsLoaded) {
            setState(() {
              _practitioners = state.practitioners;
              _polyclinics = state.polyclinics;
              _initDefaults();
            });
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Visit Schedule',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Schedule a new appointment for a patient',
                  style: GoogleFonts.outfit(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                _buildCard([
                  _buildTextField(
                    _patientNameController,
                    'Patient Name',
                    Icons.person,
                    true,
                  ),

                  // Visit Type Selection
                  _buildVisitTypeSelector(),

                  // Conditional Dropdown (uses cached state variables)
                  if (_visitType == 'Doctor')
                    _buildDoctorDropdown()
                  else
                    _buildPolyclinicDropdown(),

                  _buildTextField(
                    _dateController,
                    'Visit Date',
                    Icons.calendar_today,
                    true,
                    readOnly: true,
                    onTap: () => _selectDate(context),
                  ),
                ]),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _submitSchedule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2859E2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Save Schedule',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the Doctor / Polyclinic radio toggle
  Widget _buildVisitTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: RadioGroup<String>(
        groupValue: _visitType,
        onChanged: (v) {
          if (v != null) setState(() => _visitType = v);
        },
        child: Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: Text(
                  'Doctor',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: _visitType == 'Doctor'
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                value: 'Doctor',
                toggleable: false,
                activeColor: const Color(0xFF2859E2),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: Text(
                  'Polyclinic',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: _visitType == 'Polyclinic'
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                value: 'Polyclinic',
                toggleable: false,
                activeColor: const Color(0xFF2859E2),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the Doctor dropdown
  Widget _buildDoctorDropdown() {
    if (_practitioners.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Loading doctors...'),
      );
    }

    // Ensure selected value is valid
    if (_selectedDoctorId == null ||
        !_practitioners.any((p) => p.id == _selectedDoctorId)) {
      _selectedDoctorId = _practitioners.first.id;
      _selectedDoctorName = _practitioners.first.name;
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedDoctorId,
      items: _practitioners
          .map(
            (e) => DropdownMenuItem(
              value: e.id,
              child: Text(e.name, style: GoogleFonts.outfit(fontSize: 14)),
            ),
          )
          .toList(),
      onChanged: (val) {
        setState(() {
          _selectedDoctorId = val;
          _selectedDoctorName = _practitioners
              .firstWhere((d) => d.id == val)
              .name;
        });
      },
      decoration: InputDecoration(
        labelText: 'Doctor',
        prefixIcon: const Icon(
          Icons.medical_services,
          size: 20,
          color: Color(0xFF2859E2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  /// Builds the Polyclinic dropdown
  Widget _buildPolyclinicDropdown() {
    if (_polyclinics.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Loading polyclinics...'),
      );
    }

    // Ensure selected value is valid
    if (_selectedPolyclinicId == null ||
        !_polyclinics.any((p) => p.id == _selectedPolyclinicId)) {
      _selectedPolyclinicId = _polyclinics.first.id;
      _selectedPolyclinicName = _polyclinics.first.name;
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedPolyclinicId,
      items: _polyclinics
          .map(
            (e) => DropdownMenuItem(
              value: e.id,
              child: Text(e.name, style: GoogleFonts.outfit(fontSize: 14)),
            ),
          )
          .toList(),
      onChanged: (val) {
        setState(() {
          _selectedPolyclinicId = val;
          _selectedPolyclinicName = _polyclinics
              .firstWhere((p) => p.id == val)
              .name;
        });
      },
      decoration: InputDecoration(
        labelText: 'Polyclinic',
        prefixIcon: const Icon(
          Icons.local_hospital,
          size: 20,
          color: Color(0xFF2859E2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
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
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF2859E2)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) =>
          required && (value == null || value.isEmpty) ? 'Required' : null,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _submitSchedule() {
    if (_formKey.currentState!.validate()) {
      final isDoctor = _visitType == 'Doctor';

      context.read<AppointmentBloc>().add(
        CreateAppointmentRequested(
          AppointmentEntity(
            id: '',
            date: DateTime.parse(_dateController.text),
            status: 'PENDING',
            serviceName: 'Consultation',
            doctorName: isDoctor ? (_selectedDoctorName ?? '') : '',
            finalPrice: 0,
            doctorId: isDoctor ? int.tryParse(_selectedDoctorId ?? '') : null,
            polyclinicId: !isDoctor ? _selectedPolyclinicId : null,
            polyclinicName: !isDoctor ? _selectedPolyclinicName : null,
            patientDetail: {'name': _patientNameController.text},
          ),
        ),
      );
    }
  }
}
