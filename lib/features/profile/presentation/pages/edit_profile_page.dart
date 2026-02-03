import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/error/error_formatter.dart';
import '../../../../core/utils/google_maps_geocoder.dart';
import '../../../../core/utils/logger.dart';
import '../../../../injection_container.dart';
import '../../../auth/domain/entities/auth_entity.dart';
import '../../../auth/presentation/blocs/auth_bloc.dart';
import '../../../appointment/presentation/pages/full_map_picker_page.dart'
    as map_picker;
import '../blocs/profile_cubit.dart';

class EditProfilePage extends StatefulWidget {
  final UserEntity user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _nikController;
  late TextEditingController _emailController;
  late TextEditingController _locationNoteController;
  String? _selectedGender;
  DateTime? _selectedBirthday;
  XFile? _profileImageFile;
  String? _currentPhotoUrl;
  String? _satuSehatId;
  bool _isUploadingPhoto = false;
  bool _isLookingUpNIK = false;
  bool _isSaving = false;

  LatLng? _pinnedLocation;
  GoogleMapController? _mapController;
  bool _isLoadingLocation = false;
  Set<Marker> _markers = {};

  final Color _primaryBlue = const Color(0xFF2859E2);

  // Verified fields should be read-only
  bool get _isNameVerified =>
      widget.user.satuSehatId != null && widget.user.satuSehatId!.isNotEmpty;
  bool get _isGenderVerified =>
      widget.user.satuSehatId != null && widget.user.satuSehatId!.isNotEmpty;
  bool get _isBirthdayVerified =>
      widget.user.satuSehatId != null && widget.user.satuSehatId!.isNotEmpty;
  bool get _isNIKVerified =>
      widget.user.satuSehatId != null && widget.user.satuSehatId!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _addressController = TextEditingController(text: widget.user.address ?? '');
    _nikController = TextEditingController(text: widget.user.nik ?? '');
    _emailController = TextEditingController(text: widget.user.email);
    _locationNoteController = TextEditingController(
      text: widget.user.locationNote ?? '',
    );
    _selectedGender = widget.user.gender;
    _selectedBirthday = widget.user.birthday;
    _currentPhotoUrl = widget.user.photoProfile;
    _satuSehatId = widget.user.satuSehatId;

    // Initialize location
    if (widget.user.latitude != null && widget.user.longitude != null) {
      _pinnedLocation = LatLng(widget.user.latitude!, widget.user.longitude!);
      _markers = {
        Marker(
          markerId: const MarkerId('current_location'),
          position: _pinnedLocation!,
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      };
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _nikController.dispose();
    _emailController.dispose();
    _locationNoteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Select Photo Source'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              final XFile? image = await picker.pickImage(
                source: ImageSource.camera,
                maxWidth: 800,
              );
              if (image != null) {
                _handlePickedImage(image);
              }
            },
            child: const Text('Take Photo'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              final XFile? image = await picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 800,
              );
              if (image != null) {
                _handlePickedImage(image);
              }
            },
            child: const Text('Choose from Gallery'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _handlePickedImage(XFile imageFile) async {
    setState(() {
      _profileImageFile = imageFile;
      _isUploadingPhoto = true;
    });

    try {
      final dioClient = sl<DioClient>();
      final formData = FormData.fromMap({
        'photo': kIsWeb
            ? MultipartFile.fromBytes(
                await imageFile.readAsBytes(),
                filename: 'profile.jpg',
              )
            : await MultipartFile.fromFile(
                imageFile.path,
                filename: 'profile.jpg',
              ),
      });

      final response = await dioClient.dio.post(
        '/profile/photo',
        data: formData,
      );

      if (response.data['success'] == true) {
        setState(() {
          _currentPhotoUrl = response.data['photoUrl'];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to upload photo: ${ErrorFormatter.format(e)}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
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
      await _updateAddressFromLocation(location);

      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(location, 16));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _updateAddressFromLocation(LatLng location) async {
    setState(() {
      _pinnedLocation = location;
      _markers = {
        Marker(
          markerId: const MarkerId('current_location'),
          position: location,
          infoWindow: const InfoWindow(title: 'Selected Location'),
        ),
      };
    });

    try {
      final address = await GoogleMapsGeocoder.getAddressFromCoordinates(
        location,
      );
      if (mounted && address.isNotEmpty) {
        setState(() {
          _addressController.text = address;
        });
      }
    } catch (e) {
      AppLogger.error('Address lookup error', e);
    }
  }

  Future<void> _lookupNIK() async {
    final nik = _nikController.text.trim();
    if (nik.length != 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('NIK must be 16 digits'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLookingUpNIK = true);

    try {
      final dioClient = sl<DioClient>();
      final response = await dioClient.dio.get('/satusehat/lookup/$nik');

      final data = response.data;
      if (data['success'] == true && data['found'] == true) {
        final autoFill = data['autoFill'];
        setState(() {
          _satuSehatId = data['satuSehatId'];
          if (autoFill['name'] != null && autoFill['name'].isNotEmpty) {
            _nameController.text = autoFill['name'];
          }
          if (autoFill['gender'] != null) {
            _selectedGender = autoFill['gender'] == 'male' ? 'Male' : 'Female';
          }
          if (autoFill['birthday'] != null) {
            _selectedBirthday = DateTime.tryParse(autoFill['birthday']);
          }
          if (autoFill['phone'] != null) {
            _phoneController.text = autoFill['phone'];
          }
          if (autoFill['address'] != null) {
            _addressController.text = autoFill['address'];
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Connected to SatuSehat! ID: ${data['satuSehatId']}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('NIK not found in SatuSehat database'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lookup failed: ${ErrorFormatter.format(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLookingUpNIK = false);
      }
    }
  }

  void _showDatePicker() {
    if (_isBirthdayVerified) return;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: Text(
                      'Done',
                      style: TextStyle(
                        color: _primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedBirthday ?? DateTime(1995, 1, 1),
                maximumDate: DateTime.now(),
                onDateTimeChanged: (DateTime date) {
                  setState(() {
                    _selectedBirthday = date;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGenderPicker() {
    if (_isGenderVerified) return;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Select Gender'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedGender = 'Male');
              Navigator.pop(context);
            },
            child: const Text('Male'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedGender = 'Female');
              Navigator.pop(context);
            },
            child: const Text('Female'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      final dioClient = sl<DioClient>();

      await dioClient.dio.put(
        '/profile',
        data: {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'nik': _nikController.text.trim(),
          'gender': _selectedGender,
          'birthday': _selectedBirthday?.toIso8601String(),
          'locationNote': _locationNoteController.text.trim(),
          'satuSehatId': _satuSehatId,
          'latitude': _pinnedLocation?.latitude,
          'longitude': _pinnedLocation?.longitude,
        },
      );

      if (mounted) {
        // Prepare updated user entity
        final updatedUser = widget.user.copyWith(
          name: _nameController.text.trim(),
          photoProfile: _currentPhotoUrl,
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          nik: _nikController.text.trim(),
          gender: _selectedGender,
          birthday: _selectedBirthday,
          locationNote: _locationNoteController.text.trim(),
          satuSehatId: _satuSehatId,
          latitude: _pinnedLocation?.latitude,
          longitude: _pinnedLocation?.longitude,
        );

        // Update AuthBloc for immediate global UI response
        context.read<AuthBloc>().add(UserUpdated(updatedUser));

        // Also refresh profile cubit for consistency
        context.read<ProfileCubit>().getProfile();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update profile: ${ErrorFormatter.format(e)}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Patient Details',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const CupertinoActivityIndicator()
                : Text(
                    'Save',
                    style: GoogleFonts.outfit(
                      color: _primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Photo Section
            Center(
              child: GestureDetector(
                onTap: _isUploadingPhoto ? null : _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _primaryBlue, width: 3),
                      ),
                      child: ClipOval(
                        child: _profileImageFile != null
                            ? kIsWeb
                                  ? FutureBuilder<Uint8List>(
                                      future: _profileImageFile!.readAsBytes(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          return Image.memory(
                                            snapshot.data!,
                                            fit: BoxFit.cover,
                                          );
                                        }
                                        return const Center(
                                          child: CupertinoActivityIndicator(),
                                        );
                                      },
                                    )
                                  : Image.network(
                                      _profileImageFile!.path,
                                      fit: BoxFit.cover,
                                    )
                            : (_currentPhotoUrl != null &&
                                  _currentPhotoUrl!.isNotEmpty)
                            ? CachedNetworkImage(
                                imageUrl: _currentPhotoUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: const Color(0xFFE8F1FF),
                                  child: const Center(
                                    child: CupertinoActivityIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    _buildDefaultAvatar(),
                              )
                            : _buildDefaultAvatar(),
                      ),
                    ),
                    if (_isUploadingPhoto)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CupertinoActivityIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _primaryBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // SatuSehat Integration Section
            _buildSatuSehatSection(),
            const SizedBox(height: 24),

            _buildSectionHeader('PERSONAL INFORMATION', Colors.pinkAccent),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Full Name',
              controller: _nameController,
              verified: _isNameVerified,
              readOnly: _isNameVerified,
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPickerField(
                    label: 'Gender',
                    value: _selectedGender ?? 'Select',
                    onTap: _showGenderPicker,
                    verified: _isGenderVerified,
                    readOnly: _isGenderVerified,
                    prefixIcon: Icons.people_outline,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPickerField(
                    label: 'Date of Birth',
                    value: _selectedBirthday != null
                        ? '${_selectedBirthday!.day}/${_selectedBirthday!.month}/${_selectedBirthday!.year}'
                        : 'Select',
                    onTap: _showDatePicker,
                    verified: _isBirthdayVerified,
                    readOnly: _isBirthdayVerified,
                    prefixIcon: Icons.calendar_today_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'NIK (Identity Number)',
              controller: _nikController,
              verified: _isNIKVerified,
              readOnly: _isNIKVerified,
              prefixIcon: Icons.badge_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Phone',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              readOnly: true, // Email is always read-only
              prefixIcon: Icons.email_outlined,
            ),

            const SizedBox(height: 32),
            _buildSectionHeader('LOCATION', Colors.green),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Address',
              controller: _addressController,
              maxLines: 3,
              prefixIcon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Location Note',
              controller: _locationNoteController,
              prefixIcon: Icons.note_alt_outlined,
            ),
            const SizedBox(height: 16),
            Text(
              'Pin Location on Map',
              style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 8),
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
                            _pinnedLocation ?? const LatLng(-6.1944, 106.8229),
                        zoom: 13,
                      ),
                      markers: _markers,
                      onMapCreated: (controller) => _mapController = controller,
                      onTap: (loc) => _updateAddressFromLocation(loc),
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: TextButton.icon(
                        onPressed: _isLoadingLocation
                            ? null
                            : _getCurrentLocation,
                        icon: _isLoadingLocation
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.near_me, size: 16),
                        label: Text(
                          _isLoadingLocation
                              ? 'Locating...'
                              : 'Use Current Location',
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _primaryBlue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => map_picker.FullMapPickerPage(
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
                          markerId: const MarkerId('current_location'),
                          position: result['location'],
                          infoWindow: const InfoWindow(
                            title: 'Selected Location',
                          ),
                        ),
                      };
                    });
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(result['location'], 16),
                    );
                  }
                },
                icon: const Icon(Icons.search_rounded),
                label: const Text('Search & Select on Full Map'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: _primaryBlue),
                  foregroundColor: _primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xFFE8F1FF),
      child: Icon(
        Icons.person,
        size: 60,
        color: _primaryBlue.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildSatuSehatSection() {
    final bool isIntegrated = _satuSehatId != null && _satuSehatId!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isIntegrated ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isIntegrated
              ? const Color(0xFF10B981)
              : const Color(0xFFF97316),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isIntegrated
                  ? const Color(0xFF10B981)
                  : const Color(0xFFF97316),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIntegrated ? Icons.verified : Icons.link_off,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SatuSehat',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isIntegrated
                        ? const Color(0xFF065F46)
                        : const Color(0xFF9A3412),
                  ),
                ),
                Text(
                  isIntegrated ? 'ID: $_satuSehatId' : 'Not integrated',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: isIntegrated
                        ? const Color(0xFF047857)
                        : const Color(0xFFEA580C),
                  ),
                ),
              ],
            ),
          ),
          if (!isIntegrated)
            ElevatedButton(
              onPressed: _isLookingUpNIK ? null : _lookupNIK,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              child: _isLookingUpNIK
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Integrate',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(width: 4, height: 24, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool verified = false,
    bool readOnly = false,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13),
            ),
            if (verified) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'VERIFIED',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF059669),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          style: GoogleFonts.outfit(
            color: readOnly ? Colors.grey[600] : Colors.black,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    size: 20,
                    color: _primaryBlue.withValues(alpha: 0.7),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            filled: readOnly,
            fillColor: readOnly ? Colors.grey[50] : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: readOnly ? Colors.grey[200]! : _primaryBlue,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPickerField({
    required String label,
    required String value,
    required VoidCallback onTap,
    bool verified = false,
    bool readOnly = false,
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13),
            ),
            if (verified) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'VERIFIED',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF059669),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: readOnly ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: readOnly ? Colors.grey[50] : Colors.white,
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (prefixIcon != null) ...[
                  Icon(
                    prefixIcon,
                    size: 20,
                    color: _primaryBlue.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.outfit(
                      color: readOnly ? Colors.grey[600] : Colors.black,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!readOnly)
                  Icon(
                    CupertinoIcons.chevron_down,
                    size: 14,
                    color: Colors.grey[400],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
