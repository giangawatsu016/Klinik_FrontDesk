import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'dart:math' show cos, sqrt, asin;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/presentation/components/custom_loading_button.dart';
import '../../../home/domain/entities/service_entity.dart';
import '../../../auth/presentation/blocs/auth_bloc.dart';
import '../../../auth/domain/entities/auth_entity.dart';
import '../../../profile/presentation/blocs/profile_cubit.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../domain/entities/busy_range_entity.dart';
import '../../domain/entities/doctor_entity.dart';
import '../blocs/appointment_bloc.dart';
import '../widgets/payment_dialog.dart';
import 'full_map_picker_page.dart' as map_picker;
import '../../../../core/utils/google_maps_geocoder.dart';

class AppointmentWizardPage extends StatefulWidget {
  final ServiceEntity service;
  final UserTier tier;

  const AppointmentWizardPage({
    super.key,
    required this.service,
    this.tier = UserTier.care,
  });

  @override
  State<AppointmentWizardPage> createState() => _AppointmentWizardPageState();
}

class _AppointmentWizardPageState extends State<AppointmentWizardPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Form Data
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _nikController = TextEditingController();
  final _locationNoteController = TextEditingController();

  LatLng? _pinnedLocation;
  GoogleMapController? _mapController;
  bool _isLoadingLocation = false;
  Set<Marker> _markers = {};

  // Read-only state flags
  bool _isNameReadOnly = false;
  bool _isNikReadOnly = false;

  dynamic _selectedDoctor;
  List<DoctorEntity>? _cachedDoctors; // Cache doctors to prevent re-fetch
  DateTime? _selectedDate;
  DateTime _displayedMonth = DateTime.now();
  String? _selectedTime;
  List<BusyRangeEntity> _busyRanges = [];
  String? _createdAppointmentId;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime.now();
    _selectedDate = DateTime.now();
    context.read<AppointmentBloc>().add(GetDoctorsRequested());

    // Auto-fill patient details from AuthBloc first
    _fillFromUser(
      context.read<AuthBloc>().state is AuthAuthenticated
          ? (context.read<AuthBloc>().state as AuthAuthenticated).auth.user
          : null,
    );

    // Also trigger profile fetch to get the most complete data
    context.read<ProfileCubit>().getProfile();
  }

  void _fillFromUser(UserEntity? user) {
    if (user == null) return;

    // Set name and mark as read-only if exists
    if (user.name.isNotEmpty) {
      _nameController.text = user.name;
      _isNameReadOnly = true;
    }

    // Set NIK and mark as read-only if exists
    if (user.nik != null && user.nik!.isNotEmpty) {
      _nikController.text = user.nik!;
      _isNikReadOnly = true;
    }

    // Set other fields
    if (user.phone != null && _phoneController.text.isEmpty) {
      _phoneController.text = user.phone!;
    }
    if (user.address != null && _addressController.text.isEmpty) {
      _addressController.text = user.address!;
    }
    if (user.locationNote != null && _locationNoteController.text.isEmpty) {
      _locationNoteController.text = user.locationNote!;
    }

    // Auto-select location if lat/long exists
    if (user.latitude != null &&
        user.longitude != null &&
        _pinnedLocation == null) {
      final location = LatLng(user.latitude!, user.longitude!);
      setState(() {
        _pinnedLocation = location;
        _markers = {
          Marker(
            markerId: const MarkerId('patient_location'),
            position: location,
            infoWindow: const InfoWindow(title: 'Your Location'),
          ),
        };
      });

      // Move camera when map is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(location, 15));
      });
    }
  }

  // Get current device location with permissions
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // For web, just try to get position directly
      if (kIsWeb) {
        try {
          Position position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          ).timeout(const Duration(seconds: 10));

          final location = LatLng(position.latitude, position.longitude);

          // Get address
          await _setLocationAndAddress(location);
        } catch (e) {
          throw 'Location permission denied or unavailable in browser. Please enable location services.';
        }
      } else {
        // For mobile, check permissions
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            throw 'Location permissions are denied';
          }
        }

        if (permission == LocationPermission.deniedForever) {
          throw 'Location permissions are permanently denied';
        }

        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );

        final location = LatLng(position.latitude, position.longitude);
        await _setLocationAndAddress(location);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  // Helper to set location and get address
  Future<void> _setLocationAndAddress(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final address = [
          place.street,
          place.subLocality,
          place.locality,
          place.subAdministrativeArea,
          place.administrativeArea,
          place.postalCode,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        setState(() {
          _addressController.text = address;
          _pinnedLocation = location;
          _markers = {
            Marker(
              markerId: const MarkerId('patient_location'),
              position: location,
              infoWindow: const InfoWindow(title: 'Your Location'),
            ),
          };
        });
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(location, 16));
      }
    } catch (e) {
      // Reverse geocoding failed, just set location
      if (mounted) {
        setState(() {
          _pinnedLocation = location;
          _markers = {
            Marker(
              markerId: const MarkerId('patient_location'),
              position: location,
              infoWindow: const InfoWindow(title: 'Your Location'),
            ),
          };
        });
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(location, 16));
      }
    }
  }

  // Calculate distance between two points in km (Haversine formula)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // Pi/180
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  // Get address from coordinates using Google Geocoding API
  Future<void> _updateAddressFromLocation(LatLng location) async {
    // First, update the location and marker immediately
    setState(() {
      _pinnedLocation = location;
      _addressController.text = 'Fetching address...';
      _markers = {
        Marker(
          markerId: const MarkerId('patient_location'),
          position: location,
          infoWindow: const InfoWindow(title: 'Selected Location'),
        ),
      };
    });

    // Then get the full address from Google's API
    try {
      final address = await GoogleMapsGeocoder.getAddressFromCoordinates(
        location,
      );

      if (mounted) {
        setState(() {
          _addressController.text = address;
        });
      }
    } catch (e) {
      AppLogger.error('Address lookup error', e);
      // Even on error, we already have the marker set, so user can see the location
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _nikController.dispose();
    _locationNoteController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.getTheme(widget.tier);
    final isSerenity = widget.tier == UserTier.serenity;

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Booking ${widget.service.name}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: _currentStep == 0
                ? () => Navigator.pop(context)
                : _prevStep,
          ),
        ),
        body: MultiBlocListener(
          listeners: [
            BlocListener<ProfileCubit, ProfileState>(
              listener: (context, state) {
                if (state is ProfileLoaded) {
                  _fillFromUser(state.user);
                }
              },
            ),
            BlocListener<AppointmentBloc, AppointmentState>(
              listener: (context, state) async {
                if (state is AppointmentSuccess) {
                  _createdAppointmentId = state.appointment.id;

                  // Smooth Profile Sync: Update local user state with details just used for booking
                  final authState = context.read<AuthBloc>().state;
                  if (authState is AuthAuthenticated) {
                    final updatedUser = authState.auth.user.copyWith(
                      name: _nameController.text,
                      phone: _phoneController.text,
                      address: _addressController.text,
                      nik: _nikController.text,
                      locationNote: _locationNoteController.text,
                      latitude: _pinnedLocation?.latitude,
                      longitude: _pinnedLocation?.longitude,
                    );
                    context.read<AuthBloc>().add(UserUpdated(updatedUser));
                    // Also trigger refresh for other parts of the app
                    context.read<ProfileCubit>().getProfile();
                  }

                  // Appointment booked locally, now trigger invoice creation
                  context.read<AppointmentBloc>().add(
                    CreateInvoiceRequested(state.appointment.id),
                  );
                } else if (state is InvoiceCreated) {
                  if (_createdAppointmentId != null) {
                    final result = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => PaymentDialog(
                        invoiceUrl: state.invoiceUrl,
                        externalId: state.externalId ?? '',
                        appointmentId: _createdAppointmentId!,
                      ),
                    );

                    if (result == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment Successful!')),
                      );
                      Navigator.of(context).pop(); // Go to home
                    } else if (result == false && context.mounted) {
                      // User cancelled payment - show confirmation
                      final shouldExit = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Cancel Payment?'),
                          content: const Text(
                            'Are you sure you want to cancel the payment and return to home?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('No, continue'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Yes, cancel'),
                            ),
                          ],
                        ),
                      );

                      if (shouldExit == true && context.mounted) {
                        Navigator.of(context).pop(); // Return to home
                      }
                    }
                  }
                } else if (state is DoctorsLoaded) {
                  // Cache doctors to prevent re-fetching
                  setState(() => _cachedDoctors = state.doctors);
                } else if (state is AvailabilityLoaded) {
                  setState(() {
                    _busyRanges = state.busyRanges;

                    // Auto-select first available slot if nothing is selected
                    if (_selectedTime == null) {
                      final now = DateTime.now();
                      final List<String> startTimes = [];
                      for (int h = 8; h <= 21; h++) {
                        startTimes.add('${h.toString().padLeft(2, '0')}:00');
                        if (h < 21) {
                          startTimes.add('${h.toString().padLeft(2, '0')}:30');
                        }
                      }

                      for (final time in startTimes) {
                        final [slotH, slotM] = time
                            .split(':')
                            .map(int.parse)
                            .toList();
                        final slotMinutes = slotH * 60 + slotM;
                        final slotEnd = slotMinutes + 90;

                        final isToday =
                            _selectedDate?.day == now.day &&
                            _selectedDate?.month == now.month &&
                            _selectedDate?.year == now.year;
                        final currentMinutes = now.hour * 60 + now.minute;
                        final isPastTime =
                            isToday && slotMinutes <= currentMinutes;

                        final isBooked = state.busyRanges.any((busy) {
                          final parts = busy.start
                              .split(':')
                              .map(int.parse)
                              .toList();
                          final busyStart = parts[0] * 60 + parts[1];
                          final busyEnd = busyStart + busy.duration;
                          return slotMinutes < busyEnd && slotEnd > busyStart;
                        });

                        if (!isPastTime && !isBooked) {
                          _selectedTime = time;
                          break;
                        }
                      }
                    }
                  });
                } else if (state is AppointmentError) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
            ),
          ],
          child: Column(
            children: [
              _buildStepIndicator(theme),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) {
                    setState(() => _currentStep = i);
                    if (i == 2 && _selectedDoctor != null) {
                      final date = _selectedDate ?? DateTime.now();
                      context.read<AppointmentBloc>().add(
                        GetAvailabilityRequested(
                          _selectedDoctor!.id,
                          DateFormat('yyyy-MM-dd').format(date),
                        ),
                      );
                    }
                  },
                  children: [
                    _buildPatientStep(theme),
                    _buildDoctorStep(theme, isSerenity),
                    _buildDateTimeStep(theme),
                    _buildSummaryStep(theme, isSerenity),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          return Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isActive ? theme.colorScheme.primary : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive
                        ? theme.colorScheme.primary
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.grey[400],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                ),
              ),
              if (index < 3)
                Container(
                  width: 30,
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: isActive && index < _currentStep
                      ? theme.colorScheme.primary
                      : Colors.grey[200],
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPatientStep(ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Patient Details',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter the details of the patient',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    _buildTextField(
                      _nameController,
                      'Full Name',
                      Icons.person_outline,
                      readOnly: _isNameReadOnly,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _phoneController,
                      'Phone Number',
                      Icons.phone_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _nikController,
                      'NIK (Identity Number)',
                      Icons.badge_outlined,
                      readOnly: _isNikReadOnly,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _addressController,
                      'Address',
                      Icons.location_on_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _locationNoteController,
                      'Location Note',
                      Icons.note_alt_outlined,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target:
                                    _pinnedLocation ??
                                    const LatLng(-6.1944, 106.8229),
                                zoom: 13,
                              ),
                              onMapCreated: (controller) {
                                _mapController = controller;
                                if (_pinnedLocation != null) {
                                  controller.animateCamera(
                                    CameraUpdate.newLatLngZoom(
                                      _pinnedLocation!,
                                      16,
                                    ),
                                  );
                                }
                              },
                              onTap: (location) async {
                                // Update address from selected location
                                await _updateAddressFromLocation(location);
                              },
                              markers: _markers,
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                              mapToolbarEnabled: false,
                            ),
                            // Fullscreen button
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Material(
                                elevation: 4,
                                borderRadius: BorderRadius.circular(8),
                                child: InkWell(
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            map_picker.FullMapPickerPage(
                                              initialLocation: _pinnedLocation,
                                              initialAddress:
                                                  _addressController.text,
                                            ),
                                      ),
                                    );

                                    if (result != null && mounted) {
                                      setState(() {
                                        _pinnedLocation = result['location'];
                                        _addressController.text =
                                            result['address'];
                                        _markers = {
                                          Marker(
                                            markerId: const MarkerId(
                                              'patient_location',
                                            ),
                                            position: result['location'],
                                            infoWindow: const InfoWindow(
                                              title: 'Your Location',
                                            ),
                                          ),
                                        };
                                      });
                                      _mapController?.animateCamera(
                                        CameraUpdate.newLatLngZoom(
                                          result['location'],
                                          16,
                                        ),
                                      );
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.fullscreen,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: _isLoadingLocation
                                  ? Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : TextButton.icon(
                                      onPressed: _getCurrentLocation,
                                      icon: const Icon(
                                        Icons.my_location,
                                        size: 16,
                                      ),
                                      label: const Text('Use Current Location'),
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(
                                          0xFF2859E2,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Open full map button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  map_picker.FullMapPickerPage(
                                    initialLocation: _pinnedLocation,
                                    initialAddress: _addressController.text,
                                  ),
                            ),
                          );

                          if (result != null && mounted) {
                            setState(() {
                              _pinnedLocation = result['location'];
                              _addressController.text = result['address'];
                              _markers = {
                                Marker(
                                  markerId: const MarkerId('patient_location'),
                                  position: result['location'],
                                  infoWindow: const InfoWindow(
                                    title: 'Your Location',
                                  ),
                                ),
                              };
                            });
                            _mapController?.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                result['location'],
                                16,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Open Full Map with Search'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFF2859E2)),
                          foregroundColor: const Color(0xFF2859E2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: CustomLoadingButton(
            text: 'Continue',
            isLoading: false,
            onPressed: _nextStep,
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorStep(ThemeData theme, bool isSerenity) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: BlocBuilder<AppointmentBloc, AppointmentState>(
          builder: (context, state) {
            // Use cached doctors if available, otherwise check state
            final doctors =
                _cachedDoctors ??
                (state is DoctorsLoaded ? state.doctors : null);

            if (state is AppointmentLoading && _cachedDoctors == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (doctors != null && doctors.isNotEmpty) {
              // Calculate distances and filter
              final List<Map<String, dynamic>> doctorsWithDistance = [];
              bool hasPatientLocation = _pinnedLocation != null;

              for (final doctor in doctors) {
                double? distance;
                bool isDisabled = false;

                if (hasPatientLocation &&
                    doctor.latitude != null &&
                    doctor.longitude != null) {
                  distance = _calculateDistance(
                    _pinnedLocation!.latitude,
                    _pinnedLocation!.longitude,
                    doctor.latitude!,
                    doctor.longitude!,
                  );
                  isDisabled = distance > 15.0;
                }

                doctorsWithDistance.add({
                  'doctor': doctor,
                  'distance': distance,
                  'isDisabled': isDisabled,
                });
              }

              // Check if all doctors are disabled
              final allDisabled =
                  hasPatientLocation &&
                  doctorsWithDistance.every((d) => d['isDisabled'] == true);

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: doctorsWithDistance.length,
                      itemBuilder: (context, index) {
                        final item = doctorsWithDistance[index];
                        final doctor = item['doctor'] as DoctorEntity;
                        final distance = item['distance'] as double?;
                        final isDisabled = item['isDisabled'] as bool;
                        final isSelected = _selectedDoctor?.id == doctor.id;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Opacity(
                            opacity: isDisabled ? 0.5 : 1.0,
                            child: InkWell(
                              onTap: isDisabled
                                  ? null
                                  : () => setState(
                                      () => _selectedDoctor = doctor,
                                    ),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.primary.withValues(
                                          alpha: 0.1,
                                        )
                                      : (isDisabled
                                            ? Colors.grey[100]
                                            : Colors.white),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : (isDisabled
                                              ? Colors.grey[300]!
                                              : Colors.transparent),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundImage:
                                          doctor.photoProfile != null
                                          ? NetworkImage(doctor.photoProfile!)
                                          : null,
                                      onBackgroundImageError:
                                          doctor.photoProfile != null
                                          ? (e, s) {
                                              AppLogger.error(
                                                'Doctor image error',
                                                e,
                                              );
                                            }
                                          : null,
                                      child: doctor.photoProfile == null
                                          ? const Icon(Icons.person)
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${doctor.titlePrefix ?? ''} ${doctor.name} ${doctor.titleSuffix ?? ''}'
                                                .trim(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              decoration: isDisabled
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                          ),
                                          Text(
                                            doctor.specialization ??
                                                'General Practitioner',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                          if (distance != null) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on,
                                                  size: 14,
                                                  color: isDisabled
                                                      ? Colors.red
                                                      : Colors.green,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${distance.toStringAsFixed(1)} km',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDisabled
                                                        ? Colors.red
                                                        : Colors.green,
                                                  ),
                                                ),
                                                if (isDisabled) ...[
                                                  const SizedBox(width: 8),
                                                  const Text(
                                                    'Too far',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.red,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (isSelected && !isDisabled)
                                      Icon(
                                        Icons.check_circle,
                                        color: theme.colorScheme.primary,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Show WhatsApp button if all doctors disabled
                  if (allDisabled) ...[
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Text(
                            'All doctors are more than 15km away from your location',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: _launchWhatsApp,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00bd7d),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF00bd7d,
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  FaIcon(
                                    FontAwesomeIcons.whatsapp,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Book via WhatsApp',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: CustomLoadingButton(
                        text: 'Continue',
                        isLoading: false,
                        onPressed: _selectedDoctor != null ? _nextStep : null,
                      ),
                    ),
                  ],
                ],
              );
            }

            return const Center(child: Text('Failed to load doctors'));
          },
        ),
      ),
    );
  }

  DateTime _combineDateAndTime(DateTime date, String time) {
    final parts = time.split(':').map(int.parse).toList();
    return DateTime(date.year, date.month, date.day, parts[0], parts[1]);
  }

  bool _isRestrictedDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);
    final difference = checkDate.difference(today).inDays;

    // User requested: "today sampai +3hari" (Today, +1, +2, +3)
    return difference >= 0 && difference <= 3;
  }

  Future<void> _launchWhatsApp() async {
    const phone = '6287778102233';
    final name = _nameController.text.isNotEmpty
        ? _nameController.text
        : '[Name]';
    final address = _addressController.text.isNotEmpty
        ? _addressController.text
        : '[Address]';
    final serviceName = widget.service.name;
    final doctorName = _selectedDoctor?.name ?? '[Doctor]';
    final dateStr = _selectedDate != null
        ? DateFormat('dd MMMM yyyy').format(_selectedDate!)
        : '[Date]';
    final titlePrefix = _selectedDoctor?.titlePrefix ?? '';
    final titleSuffix = _selectedDoctor?.titleSuffix ?? '';

    // "Hi, saya {name} ingin membuat janji untuk {service name} dengan {gelar} {nama dokter} {gelar} pada tanggal {date}. Alamat: {address}"
    final message =
        'Hi, saya $name ingin membuat janji untuk $serviceName dengan $titlePrefix $doctorName $titleSuffix pada tanggal $dateStr. Alamat: $address';

    final url = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
    );
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not trigger WhatsApp')),
        );
      }
    }
  }

  Widget _buildDateTimeStep(ThemeData theme) {
    final now = DateTime.now();
    final List<String> startTimes = [];
    for (int h = 8; h <= 21; h++) {
      startTimes.add('${h.toString().padLeft(2, '0')}:00');
      if (h < 21) {
        startTimes.add('${h.toString().padLeft(2, '0')}:30');
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isRestricted =
            _selectedDate != null && _isRestrictedDate(_selectedDate!);

        return Theme(
          data:
              ThemeData.from(
                colorScheme: ColorScheme.light(
                  primary: theme.colorScheme.primary,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                  onSurfaceVariant: Colors.black,
                ),
                useMaterial3: true,
              ).copyWith(
                datePickerTheme: DatePickerThemeData(
                  backgroundColor: Colors.white,
                  headerBackgroundColor: theme.colorScheme.primary,
                  headerForegroundColor: Colors.white,
                  dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return theme.colorScheme.primary;
                    }
                    return Colors.transparent;
                  }),
                  dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.white;
                    }
                    if (states.contains(WidgetState.disabled)) {
                      return Colors.grey;
                    }
                    return Colors.black;
                  }),
                  todayBackgroundColor: WidgetStateProperty.all(
                    Colors.transparent,
                  ),
                  todayForegroundColor: WidgetStateProperty.all(
                    theme.colorScheme.primary,
                  ),
                  todayBorder: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 1.5,
                  ),
                  dayStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 800),
                      child: Column(
                        children: [
                          // Calendar Card
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: _buildCustomCalendar(theme),
                          ),
                          const SizedBox(height: 24),

                          if (isRestricted) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.1),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: Column(
                                // ... Only content ...
                                children: [
                                  const Icon(
                                    FontAwesomeIcons.triangleExclamation,
                                    color: Colors.orange,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'If you wanna book at this day please book by admin',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  InkWell(
                                    onTap: _launchWhatsApp,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF00bd7d,
                                        ), // WhatsApp Teal
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF00bd7d,
                                            ).withValues(alpha: 0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const FaIcon(
                                            FontAwesomeIcons.whatsapp,
                                            color: Colors.white,
                                            size: 32,
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Text(
                                                'Book via',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                              Text(
                                                'WhatsApp',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // Start Time Card
                            _buildStartTimeCard(
                              theme,
                              startTimes,
                              now,
                              isMobile,
                            ),
                            const SizedBox(
                              height: 32,
                            ), // Add visual space but no button here
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Pinned Bottom Button
              Container(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: CustomLoadingButton(
                  text: 'Continue',
                  isLoading: false,
                  onPressed: !isRestricted && _selectedTime != null
                      ? _nextStep
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomCalendar(ThemeData theme) {
    final now = DateTime.now();
    final year = _displayedMonth.year;
    final month = _displayedMonth.month;

    // Days in month
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstDayOfMonth = DateTime(year, month, 1);

    // DateTime uses 1..7 for Mon..Sun. If we want Sun start:
    // If Mon(1) -> 1. If we want Sun(0) -> 1. If Sun(7) -> 0.
    // Standard Calender usually starts Sunday.
    // firstDayOfMonth.weekday: Mon=1, Sun=7.
    // We want Sun=0, Mon=1... Sat=6.
    // So if 7 -> 0. Else same.
    final startOffset = firstDayOfMonth.weekday == 7
        ? 0
        : firstDayOfMonth.weekday;

    final monthName = DateFormat('MMMM yyyy').format(_displayedMonth);

    return Column(
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              monthName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() {
                    _displayedMonth = DateTime(year, month - 1);
                  }),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() {
                    _displayedMonth = DateTime(year, month + 1);
                  }),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Weekday Headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        // Days Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: daysInMonth + startOffset,
          itemBuilder: (context, index) {
            if (index < startOffset) return const SizedBox();

            final day = index - startOffset + 1;
            final date = DateTime(year, month, day);

            // Status Checks
            final isToday =
                date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;
            final isPast = date.isBefore(
              DateTime(now.year, now.month, now.day),
            );
            final isSelected =
                _selectedDate != null &&
                date.year == _selectedDate!.year &&
                date.month == _selectedDate!.month &&
                date.day == _selectedDate!.day;
            final isRestricted = _isRestrictedDate(date);

            return InkWell(
              onTap: isPast
                  ? null
                  : () {
                      setState(() {
                        _selectedDate = date;
                        _selectedTime = null;
                        _busyRanges = [];
                      });
                      if (!isRestricted && _selectedDoctor != null) {
                        context.read<AppointmentBloc>().add(
                          GetAvailabilityRequested(
                            _selectedDoctor!.id,
                            DateFormat('yyyy-MM-dd').format(date),
                          ),
                        );
                      }
                    },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : (isToday
                            ? theme.colorScheme.primary.withValues(alpha: 0.1)
                            : Colors.transparent),
                  borderRadius: BorderRadius.circular(12),
                  border: isToday && !isSelected
                      ? Border.all(color: theme.colorScheme.primary)
                      : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isPast ? Colors.grey[300] : Colors.black87),
                        fontWeight: isToday || isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    if (isRestricted && !isPast && !isSelected)
                      Positioned(
                        bottom: 6,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStartTimeCard(
    ThemeData theme,
    List<String> startTimes,
    DateTime now,
    bool isMobile,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Time',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 3 : 4,
              childAspectRatio: isMobile ? 1.8 : 1.5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: startTimes.length,
            itemBuilder: (context, index) {
              final time = startTimes[index];
              final [slotH, slotM] = time.split(':').map(int.parse).toList();
              final slotMinutes = slotH * 60 + slotM;
              final slotEnd = slotMinutes + 90;

              final isToday =
                  _selectedDate?.day == now.day &&
                  _selectedDate?.month == now.month &&
                  _selectedDate?.year == now.year;
              final currentMinutes = now.hour * 60 + now.minute;
              final isPastTime = isToday && slotMinutes <= currentMinutes;

              final isBooked = _busyRanges.any((busy) {
                final parts = busy.start.split(':').map(int.parse).toList();
                final busyStart = parts[0] * 60 + parts[1];
                final busyEnd = busyStart + busy.duration;
                return slotMinutes < busyEnd && slotEnd > busyStart;
              });

              final isDisabled = isPastTime || isBooked;
              final isSelected = _selectedTime == time;

              return InkWell(
                onTap: isDisabled
                    ? null
                    : () => setState(() => _selectedTime = time),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : (isPastTime
                              ? Colors.grey[50]
                              : (isBooked
                                    ? Colors.red.withValues(alpha: 0.05)
                                    : Colors.white)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : (isPastTime
                                ? Colors.grey[200]!
                                : (isBooked
                                      ? Colors.red.withValues(alpha: 0.2)
                                      : Colors.grey[200]!)),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isPastTime
                                    ? Colors.grey
                                    : (isBooked ? Colors.red : Colors.black)),
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                      if (isBooked)
                        Text(
                          'BOOKED',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: isMobile ? 6 : 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStep(ThemeData theme, bool isSerenity) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummaryItem('Service', widget.service.name),
                _buildSummaryItem(
                  'Doctor',
                  _selectedDoctor != null
                      ? ('${_selectedDoctor!.titlePrefix ?? ''} ${_selectedDoctor!.name} ${_selectedDoctor!.titleSuffix ?? ''}'
                            .trim())
                      : '-',
                ),
                _buildSummaryItem(
                  'Date',
                  _selectedDate != null
                      ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                      : '-',
                ),
                _buildSummaryItem('Time', _selectedTime ?? '-'),
                const Divider(height: 48),
                if (widget.service.discount != null &&
                    widget.service.discount! > 0) ...[
                  _buildSummaryItem(
                    'Subtotal',
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(
                      widget.service.originalPrice ??
                          (widget.service.finalPrice! +
                              widget.service.discount!),
                    ),
                  ),
                  _buildSummaryItem(
                    'Discount (${widget.service.discountName ?? 'Promo'})',
                    '- ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(widget.service.discount)}',
                    valueColor: const Color(0xFF00BD7D),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Price',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(widget.service.finalPrice),
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color:
                            widget.service.discount != null &&
                                widget.service.discount! > 0
                            ? const Color(0xFF00BD7D)
                            : const Color(0xFF2859E2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: BlocBuilder<AppointmentBloc, AppointmentState>(
            builder: (context, state) {
              return CustomLoadingButton(
                text: 'Pay Now',
                isLoading: state is AppointmentLoading,
                onPressed: () {
                  // If an appointment was already created, just request a new invoice for it
                  if (_createdAppointmentId != null) {
                    context.read<AppointmentBloc>().add(
                      CreateInvoiceRequested(_createdAppointmentId.toString()),
                    );
                    return;
                  }

                  final appointmentDate = _combineDateAndTime(
                    _selectedDate ?? DateTime.now(),
                    _selectedTime ?? "00:00",
                  );

                  context.read<AppointmentBloc>().add(
                    CreateAppointmentRequested(
                      AppointmentEntity(
                        id: '', // Dummy ID for creation
                        date: appointmentDate,
                        status: 'PENDING',
                        serviceName: widget.service.name,
                        doctorName: _selectedDoctor?.name ?? '-',
                        finalPrice: widget.service.finalPrice ?? 0.0,
                        serviceId: widget.service.id,
                        doctorId: _selectedDoctor?.id ?? 0,
                        polyclinicId: _selectedDoctor?.polyclinicId,
                        polyclinicName: _selectedDoctor?.polyclinicName,
                        patientDetail: {
                          'name': _nameController.text,
                          'phone': _phoneController.text,
                          'address': _addressController.text,
                          'nik': _nikController.text,
                          'location_note': _locationNoteController.text,
                          'latitude': _pinnedLocation?.latitude,
                          'longitude': _pinnedLocation?.longitude,
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: valueColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    int maxLines = 1,
    bool readOnly = false,
  }) {
    const primaryBlue = Color(0xFF2859E2);
    return TextField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: readOnly ? const Color(0xFFF1F5F9) : Colors.white,
        prefixIcon: Icon(icon, color: primaryBlue),
        suffixIcon: readOnly
            ? const Icon(Icons.lock, size: 18, color: Colors.grey)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
      ),
    );
  }
}
