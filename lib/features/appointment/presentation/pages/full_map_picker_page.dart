import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../blocs/map_picker_cubit.dart';

class FullMapPickerPage extends StatelessWidget {
  final LatLng? initialLocation;
  final String? initialAddress;

  const FullMapPickerPage({
    super.key,
    this.initialLocation,
    this.initialAddress,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          MapPickerCubit()
            ..loadInitialLocation(initialLocation, initialAddress),
      child: const _MapPickerView(),
    );
  }
}

class _MapPickerView extends StatefulWidget {
  const _MapPickerView();

  @override
  State<_MapPickerView> createState() => _MapPickerViewState();
}

class _MapPickerViewState extends State<_MapPickerView> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Google Map Layer
          BlocConsumer<MapPickerCubit, MapPickerState>(
            listenWhen: (previous, current) => current is MapPickerLoaded,
            listener: (context, state) {
              if (state is MapPickerLoaded) {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(state.location, 16),
                );
                if (_searchController.text != state.address) {
                  _searchController.text = state.address;
                }
              } else if (state is MapPickerError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            buildWhen: (previous, current) => current is MapPickerLoaded,
            builder: (context, state) {
              Set<Marker> markers = {};
              LatLng initialTarget = const LatLng(-6.1944, 106.8229);

              if (state is MapPickerLoaded) {
                initialTarget = state.location;
                markers = {
                  Marker(
                    markerId: const MarkerId('selected'),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueBlue,
                    ),
                    position: state.location,
                    infoWindow: const InfoWindow(title: 'Selected Location'),
                  ),
                };
              }

              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: initialTarget,
                  zoom: 16,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (state is MapPickerLoaded) {
                    controller.moveCamera(
                      CameraUpdate.newLatLng(state.location),
                    );
                  }
                },
                onTap: (location) {
                  context.read<MapPickerCubit>().pickLocationOnMap(location);
                },
                markers: markers,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                padding: const EdgeInsets.only(bottom: 180),
              );
            },
          ),

          // 2. Floating Search Bar (Top)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search location...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (query) {
                        context.read<MapPickerCubit>().searchLocation(query);
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Color(0xFF2859E2)),
                    onPressed: () {
                      context.read<MapPickerCubit>().searchLocation(
                        _searchController.text,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 3. Loading Indicator Overlay
          BlocBuilder<MapPickerCubit, MapPickerState>(
            builder: (context, state) {
              if (state is MapPickerLoading) {
                return Positioned(
                  top: MediaQuery.of(context).padding.top + 65,
                  left: 0,
                  right: 0,
                  child: const Center(
                    child: Card(
                      shape: StadiumBorder(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Locating...', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // 4. My Location Button (Bottom Right)
          Positioned(
            bottom: 200,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF2859E2),
              child: const Icon(Icons.my_location),
              onPressed: () {
                context.read<MapPickerCubit>().getCurrentLocation();
              },
            ),
          ),

          // 5. Bottom Sheet (Location Details & Confirm)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: BlocBuilder<MapPickerCubit, MapPickerState>(
                builder: (context, state) {
                  String displayAddress = 'Select a location on the map';
                  bool isEnabled = false;
                  LatLng? selectedLoc;

                  if (state is MapPickerLoaded) {
                    displayAddress = state.address;
                    isEnabled = true;
                    selectedLoc = state.location;
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Selected Location',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        displayAddress,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isEnabled
                              ? () {
                                  Navigator.pop(context, {
                                    'location': selectedLoc,
                                    'address': displayAddress,
                                  });
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2859E2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Confirm Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
