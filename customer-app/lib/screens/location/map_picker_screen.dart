import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../theme/app_text_styles.dart';
import '../../routes/app_routes.dart';
import '../../utils/location_error_messages.dart';
import '../../services/google_places_service.dart';

class MapPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;

  const MapPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(19.0760, 72.8777); // Default: Mumbai
  String _selectedAddress = 'Loading address...';
  bool _isLoadingAddress = false;
  final Set<Marker> _markers = {};
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _places = GooglePlacesService();
  Timer? _searchDebounce;
  String? _placesSessionToken;
  bool _isLoadingPredictions = false;
  List<PlacePrediction> _predictions = const [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _selectedAddress = widget.initialAddress ?? 'Loading address...';
    } else {
      _getCurrentLocation();
    }
    _updateMarker();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled. Please enable them in settings.')),
          );
        }
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission is required.')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is permanently denied. Please enable it in app settings.')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (mounted) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedLocation, 15.0),
        );
        _updateMarker();
        _reverseGeocode(_selectedLocation);
      }
    } catch (e) {
      debugPrint('Error getting current location: $e');
      if (mounted) {
        final message = LocationErrorMessages.getLocationErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  void _updateMarker() {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedLocation,
          draggable: true,
          onDragEnd: (LatLng newPosition) {
            setState(() {
              _selectedLocation = newPosition;
            });
            _reverseGeocode(newPosition);
          },
        ),
      );
    });
  }

  String _newPlacesSessionToken() {
    final r = Random.secure();
    final a = r.nextInt(1 << 32).toRadixString(16);
    final b = r.nextInt(1 << 32).toRadixString(16);
    return '${DateTime.now().millisecondsSinceEpoch}-$a$b';
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim();
    if (!_searchFocusNode.hasFocus || q.isEmpty) {
      if (mounted) {
        setState(() {
          _predictions = const [];
          _isLoadingPredictions = false;
        });
      }
      return;
    }

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      await _fetchPredictions(q);
    });
  }

  Future<void> _fetchPredictions(String query) async {
    try {
      final q = query.trim();
      if (q.isEmpty) return;

      _placesSessionToken ??= _newPlacesSessionToken();
      setState(() => _isLoadingPredictions = true);

      final results = await _places.autocomplete(
        input: q,
        sessionToken: _placesSessionToken!,
      );

      if (!mounted) return;
      setState(() {
        _predictions = results;
        _isLoadingPredictions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _predictions = const [];
        _isLoadingPredictions = false;
      });
    }
  }

  Future<void> _handlePredictionTap(PlacePrediction p) async {
    try {
      _placesSessionToken ??= _newPlacesSessionToken();
      setState(() {
        _isLoadingPredictions = true;
        _isLoadingAddress = true;
      });

      final details = await _places.getPlaceDetails(
        placeId: p.placeId,
        sessionToken: _placesSessionToken!,
      );

      if (!mounted) return;
      setState(() {
        _selectedLocation = details.location;
        _selectedAddress = details.formattedAddress;
        _isLoadingPredictions = false;
        _isLoadingAddress = false;
        _predictions = const [];
      });

      _updateMarker();
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(details.location, 15.0));

      // Put the chosen address in the search box for clarity.
      _searchController.text = details.formattedAddress;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchController.text.length),
      );
      _searchFocusNode.unfocus();

      // Close the billing session once a place is chosen.
      _placesSessionToken = null;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingPredictions = false;
        _isLoadingAddress = false;
      });
      final msg = LocationErrorMessages.getLocationErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _reverseGeocode(LatLng position) async {
    setState(() {
      _isLoadingAddress = true;
    });

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = _formatAddress(place);
        if (mounted) {
          setState(() {
            _selectedAddress = address;
            _isLoadingAddress = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _selectedAddress = 'Address not found';
            _isLoadingAddress = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
      if (mounted) {
        final message = LocationErrorMessages.getLocationErrorMessage(e);
        setState(() {
          _selectedAddress = message;
          _isLoadingAddress = false;
        });
      }
    }
  }

  String _formatAddress(Placemark place) {
    final parts = <String>[];
    if (place.street != null && place.street!.isNotEmpty) {
      parts.add(place.street!);
    }
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      parts.add(place.subLocality!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    }
    if (place.postalCode != null && place.postalCode!.isNotEmpty) {
      parts.add(place.postalCode!);
    }
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      parts.add(place.administrativeArea!);
    }
    if (place.country != null && place.country!.isNotEmpty) {
      parts.add(place.country!);
    }
    return parts.isEmpty ? 'Unknown location' : parts.join(', ');
  }

  void _onMapTap(LatLng location) {
    _searchFocusNode.unfocus();
    setState(() {
      _predictions = const [];
    });
    setState(() {
      _selectedLocation = location;
    });
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(location),
    );
    _updateMarker();
    _reverseGeocode(location);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_selectedLocation, 15.0),
    );
    _reverseGeocode(_selectedLocation);
  }

  Future<void> _confirmSelection() async {
    // Return the selected location data
    Navigator.of(context).pop({
      'latitude': _selectedLocation.latitude,
      'longitude': _selectedLocation.longitude,
      'address': _selectedAddress,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F7),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Select Location',
                      style: AppTextStyles.header(color: const Color(0xFF1B1F2A)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            // Map
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: _selectedLocation,
                      zoom: 15.0,
                    ),
                    markers: _markers,
                    onTap: _onMapTap,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    mapType: MapType.normal,
                  ),
                  // Place search (Google Places autocomplete)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      children: [
                        Material(
                          elevation: 6,
                          borderRadius: BorderRadius.circular(12),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'Search a place',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isEmpty
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _predictions = const []);
                                      },
                                    ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        if (_searchFocusNode.hasFocus &&
                            (_isLoadingPredictions || _predictions.isNotEmpty))
                          const SizedBox(height: 8),
                        if (_searchFocusNode.hasFocus &&
                            (_isLoadingPredictions || _predictions.isNotEmpty))
                          Material(
                            elevation: 6,
                            borderRadius: BorderRadius.circular(12),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 260),
                              child: _isLoadingPredictions
                                  ? const Padding(
                                      padding: EdgeInsets.all(14),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                          SizedBox(width: 10),
                                          Text('Searching...'),
                                        ],
                                      ),
                                    )
                                  : ListView.separated(
                                      shrinkWrap: true,
                                      padding: EdgeInsets.zero,
                                      itemCount: _predictions.length,
                                      separatorBuilder: (_, __) => const Divider(height: 1),
                                      itemBuilder: (context, index) {
                                        final p = _predictions[index];
                                        return ListTile(
                                          dense: true,
                                          leading: const Icon(Icons.place_outlined),
                                          title: Text(
                                            p.description,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          onTap: () => _handlePredictionTap(p),
                                        );
                                      },
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Center pin indicator
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFF2C3CA5),
                          size: 48,
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2C3CA5),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Current location button
                  Positioned(
                    bottom: 100,
                    right: 18,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.white,
                      onPressed: _getCurrentLocation,
                      child: const Icon(Icons.my_location, color: Color(0xFF2C3CA5)),
                    ),
                  ),
                ],
              ),
            ),
            // Address card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 14,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Address',
                    style: AppTextStyles.body(color: const Color(0xFF7B8296)),
                  ),
                  const SizedBox(height: 8),
                  if (_isLoadingAddress)
                    const CircularProgressIndicator()
                  else
                    Text(
                      _selectedAddress,
                      style: AppTextStyles.header(color: const Color(0xFF1B1F2A)),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _confirmSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C3CA5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Confirm Location',
                        style: AppTextStyles.header(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}

