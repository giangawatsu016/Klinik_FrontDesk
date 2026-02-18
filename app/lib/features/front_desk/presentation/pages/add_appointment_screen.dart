import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/front_desk_bloc.dart';
import '../bloc/front_desk_event.dart';
import '../bloc/front_desk_state.dart';
import '../../data/models/practitioner_model.dart';
import '../../../appointment/presentation/blocs/appointment_bloc.dart';
import '../../../appointment/domain/entities/appointment_entity.dart';

class AddAppointmentScreen extends StatefulWidget {
  const AddAppointmentScreen({super.key});

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _dateController = TextEditingController();
  String? _selectedDoctorId;
  String? _selectedDoctorName;
  List<PractitionerModel> _practitioners = [];

  @override
  void initState() {
    super.initState();
    // Trigger fetch if practitioners are empty
    final bloc = context.read<FrontDeskBloc>();
    if (bloc.state is! PractitionersAndPolyclinicsLoaded) {
      bloc.add(FetchPractitionersAndPolyclinicsEvent());
    } else {
      final state = bloc.state as PractitionersAndPolyclinicsLoaded;
      _practitioners = state.practitioners;
      if (_practitioners.isNotEmpty) {
        _selectedDoctorId = _practitioners.first.id;
        _selectedDoctorName = _practitioners.first.name;
      }
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
                'Schedule added successfully' +
                    (debugCount != null ? ' (DB Total: $debugCount)' : ''),
              ),
              backgroundColor: Colors.green,
            ),
          );
          _patientNameController.clear();
          _dateController.clear();
        } else if (state is AppointmentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
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
                BlocBuilder<FrontDeskBloc, FrontDeskState>(
                  builder: (context, state) {
                    List<PractitionerModel> items = [];
                    if (state is PractitionersAndPolyclinicsLoaded) {
                      items = state.practitioners;
                      // Sync local selection if it becomes valid
                      if (_selectedDoctorId == null && items.isNotEmpty) {
                        _selectedDoctorId = items.first.id;
                        _selectedDoctorName = items.first.name;
                      }
                    }

                    return _buildDropdown('Doctor', items, _selectedDoctorId, (
                      val,
                    ) {
                      setState(() {
                        _selectedDoctorId = val;
                        _selectedDoctorName = items
                            .firstWhere((d) => d.id == val)
                            .name;
                      });
                    });
                  },
                ),
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

  Widget _buildDropdown(
    String label,
    List<PractitionerModel> items,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e.id,
              child: Text(e.name, style: GoogleFonts.outfit(fontSize: 14)),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
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
      context.read<AppointmentBloc>().add(
        CreateAppointmentRequested(
          AppointmentEntity(
            id: '',
            date: DateTime.parse(_dateController.text),
            status: 'PENDING',
            serviceName: 'Consultation',
            doctorName: _selectedDoctorName!,
            finalPrice: 0,
            doctorId: int.tryParse(_selectedDoctorId!),
            patientDetail: {'name': _patientNameController.text},
          ),
        ),
      );
    }
  }
}
