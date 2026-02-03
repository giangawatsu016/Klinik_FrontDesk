import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../core/utils/google_maps_geocoder.dart';
import '../../../../core/utils/logger.dart';

// States
abstract class MapPickerState extends Equatable {
  const MapPickerState();
  
  @override
  List<Object?> get props => [];
}

class MapPickerInitial extends MapPickerState {}

class MapPickerLoading extends MapPickerState {}

class MapPickerLoaded extends MapPickerState {
  final LatLng location;
  final String address;
  final bool isCurrentLocation;

  const MapPickerLoaded({
    required this.location, 
    required this.address,
    this.isCurrentLocation = false,
  });

  @override
  List<Object?> get props => [location, address, isCurrentLocation];
}

class MapPickerError extends MapPickerState {
  final String message;

  const MapPickerError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class MapPickerCubit extends Cubit<MapPickerState> {
  MapPickerCubit() : super(MapPickerInitial());

  void loadInitialLocation(LatLng? initialLocation, String? initialAddress) {
    if (initialLocation != null) {
      // If we have an initial location, use it
      emit(MapPickerLoaded(
        location: initialLocation,
        address: initialAddress ?? _formatCoordinates(initialLocation),
      ));
    } else {
      // Otherwise try to get current location
      getCurrentLocation();
    }
  }

  Future<void> getCurrentLocation() async {
    emit(MapPickerLoading());
    
    try {
      Position position;
      
      if (kIsWeb) {
        try {
          // On web, Geolocator handles permissions implicitly via browser
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
          ).timeout(const Duration(seconds: 10));
        } catch (e) {
          throw 'Location permission denied or unavailable in browser.';
        }
      } else {
        // Mobile permission checks
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
        
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
        );
      }
      
      final location = LatLng(position.latitude, position.longitude);
      await pickLocationOnMap(location, isCurrentLocation: true);
      
    } catch (e) {
      AppLogger.error('MapPicker Error', e);
      emit(MapPickerError(e.toString()));
    }
  }

  Future<void> searchLocation(String query) async {
    if (query.isEmpty) return;
    
    emit(MapPickerLoading());
    try {
      final location = await GoogleMapsGeocoder.getCoordinatesFromAddress(query);
      
      if (location != null) {
        await pickLocationOnMap(location);
      } else {
        emit(const MapPickerError('No location found for this address.'));
      }
    } catch (e) {
      AppLogger.error('MapPicker Search Error', e);
      emit(MapPickerError(e.toString()));
    }
  }

  Future<void> pickLocationOnMap(LatLng location, {bool isCurrentLocation = false}) async {
    // Show "Fetching address..." while waiting for Geocoding API
    emit(MapPickerLoaded(
      location: location,
      address: 'Fetching address...',
      isCurrentLocation: isCurrentLocation,
    ));
    
    try {
      final address = await GoogleMapsGeocoder.getAddressFromCoordinates(location);
      
      // If we got back coordinates instead of a real address (fallback), 
      // it means geocoding failed. We still emit but maybe we can flag it.
      emit(MapPickerLoaded(
        location: location,
        address: address,
        isCurrentLocation: isCurrentLocation,
      ));
    } catch (e) {
      AppLogger.error('Address fetch error', e);
      // Fallback already handled by geocoder returning coordinates
    }
  }

  String _formatCoordinates(LatLng location) {
    return 'Lat: ${location.latitude.toStringAsFixed(6)}, Lng: ${location.longitude.toStringAsFixed(6)}';
  }
}
