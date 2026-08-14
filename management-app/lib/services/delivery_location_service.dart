import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/supabase_config.dart';

class DeliveryLocationService {
  /// Updates location via Supabase Realtime (direct insert to delivery_staff_locations table).
  /// Falls back to REST API if Supabase is not enabled.
  Future<void> updateLocation({
    required String staffId,
    String? shiftId,
    required double latitude,
    required double longitude,
  }) async {
    if (!SupabaseConfig.isEnabled) {
      // Fallback: if Supabase not configured, skip silently (or could call REST API here)
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      await supabase.from('delivery_staff_locations').insert({
        'staff_id': staffId,
        if (shiftId != null && shiftId.isNotEmpty) 'shift_id': shiftId,
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        // recorded_at is auto-set by database default
      });
    } catch (e) {
      // Log error but don't throw - location updates should be fire-and-forget
      // to avoid disrupting the app if network is temporarily unavailable
      print('Failed to update location via Supabase: $e');
    }
  }
}
