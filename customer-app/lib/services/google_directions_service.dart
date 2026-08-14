import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../utils/google_maps_keys.dart';

class GoogleDirectionsService {
  final Dio _dio;

  GoogleDirectionsService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://maps.googleapis.com/maps/api',
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
              ),
            );

  Future<DirectionsRoute?> getRoute({
    required LatLng origin,
    required LatLng destination,
    List<LatLng> waypoints = const [],
  }) async {
    final key = GoogleMapsKeys.placesApiKey;
    if (key.isEmpty) return null;

    final wp = waypoints.isEmpty
        ? null
        : waypoints.map((p) => '${p.latitude},${p.longitude}').join('|');

    final res = await _dio.get(
      '/directions/json',
      queryParameters: {
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        if (wp != null) 'waypoints': wp,
        'mode': 'driving',
        'key': key,
      },
    );

    final data = (res.data as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final routes = data['routes'];
    if (routes is! List || routes.isEmpty) return null;

    final r0 = (routes.first as Map).cast<String, dynamic>();
    final overview = (r0['overview_polyline'] as Map?)?.cast<String, dynamic>();
    final encoded = overview?['points'] as String?;
    if (encoded == null || encoded.isEmpty) return null;

    final points = decodePolyline(encoded);

    int? totalSeconds;
    int? totalMeters;
    final legs = r0['legs'];
    if (legs is List && legs.isNotEmpty) {
      int secs = 0;
      int meters = 0;
      for (final leg in legs) {
        final l = (leg as Map).cast<String, dynamic>();
        final duration = (l['duration'] as Map?)?.cast<String, dynamic>();
        final distance = (l['distance'] as Map?)?.cast<String, dynamic>();
        secs += (duration?['value'] as num?)?.toInt() ?? 0;
        meters += (distance?['value'] as num?)?.toInt() ?? 0;
      }
      totalSeconds = secs > 0 ? secs : null;
      totalMeters = meters > 0 ? meters : null;
    }

    return DirectionsRoute(
      polylinePoints: points,
      totalDistanceMeters: totalMeters,
      totalDurationSeconds: totalSeconds,
    );
  }

  /// Decodes an encoded polyline string into a list of LatLng points.
  /// See: https://developers.google.com/maps/documentation/utilities/polylinealgorithm
  List<LatLng> decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int result = 0;
      int shift = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      result = 0;
      shift = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }
}

class DirectionsRoute {
  final List<LatLng> polylinePoints;
  final int? totalDistanceMeters;
  final int? totalDurationSeconds;

  const DirectionsRoute({
    required this.polylinePoints,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
  });
}


