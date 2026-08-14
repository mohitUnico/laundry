import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../utils/google_maps_keys.dart';

class PlacePrediction {
  final String placeId;
  final String description;

  const PlacePrediction({
    required this.placeId,
    required this.description,
  });
}

class PlaceDetailsResult {
  final LatLng location;
  final String formattedAddress;

  const PlaceDetailsResult({
    required this.location,
    required this.formattedAddress,
  });
}

class GooglePlacesService {
  final Dio _dio;

  GooglePlacesService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://maps.googleapis.com/maps/api/place',
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                sendTimeout: const Duration(seconds: 15),
              ),
            );

  String get _apiKey => GoogleMapsKeys.placesApiKey;

  Future<List<PlacePrediction>> autocomplete({
    required String input,
    required String sessionToken,
  }) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return [];

    if (_apiKey.isEmpty) {
      throw Exception('Google Maps API key missing for Places search');
    }

    final res = await _dio.get<Map<String, dynamic>>(
      '/autocomplete/json',
      queryParameters: {
        'input': trimmed,
        'key': _apiKey,
        'sessiontoken': sessionToken,
        // Keep results relevant for your target market; can be removed to be global.
        'components': 'country:in',
      },
    );

    final data = res.data ?? const <String, dynamic>{};
    final status = (data['status'] ?? '') as String;
    if (status != 'OK' && status != 'ZERO_RESULTS') {
      final message = (data['error_message'] ?? data['status'] ?? 'Unknown error').toString();
      throw Exception(message);
    }

    final predictions = (data['predictions'] as List?) ?? const [];
    return predictions
        .map((p) => p as Map<String, dynamic>)
        .map(
          (p) => PlacePrediction(
            placeId: (p['place_id'] ?? '') as String,
            description: (p['description'] ?? '') as String,
          ),
        )
        .where((p) => p.placeId.isNotEmpty && p.description.isNotEmpty)
        .toList(growable: false);
  }

  Future<PlaceDetailsResult> getPlaceDetails({
    required String placeId,
    required String sessionToken,
  }) async {
    if (placeId.isEmpty) {
      throw Exception('Invalid place selection');
    }

    if (_apiKey.isEmpty) {
      throw Exception('Google Maps API key missing for Places details');
    }

    final res = await _dio.get<Map<String, dynamic>>(
      '/details/json',
      queryParameters: {
        'place_id': placeId,
        'key': _apiKey,
        'sessiontoken': sessionToken,
        'fields': 'geometry/location,formatted_address',
      },
    );

    final data = res.data ?? const <String, dynamic>{};
    final status = (data['status'] ?? '') as String;
    if (status != 'OK') {
      final message = (data['error_message'] ?? data['status'] ?? 'Unknown error').toString();
      throw Exception(message);
    }

    final result = (data['result'] as Map?)?.cast<String, dynamic>() ?? const {};
    final formatted = (result['formatted_address'] ?? '') as String;
    final geometry = (result['geometry'] as Map?)?.cast<String, dynamic>() ?? const {};
    final location = (geometry['location'] as Map?)?.cast<String, dynamic>() ?? const {};

    final lat = (location['lat'] as num?)?.toDouble();
    final lng = (location['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) {
      throw Exception('Place location not available');
    }

    return PlaceDetailsResult(
      location: LatLng(lat, lng),
      formattedAddress: formatted.isEmpty ? 'Selected location' : formatted,
    );
  }
}


