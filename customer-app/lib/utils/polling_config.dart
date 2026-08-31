/// Polling intervals for REST refresh (replaces Supabase Realtime).
class PollingConfig {
  static const Duration orders = Duration(seconds: 15);
  static const Duration coupons = Duration(seconds: 30);
  static const Duration orderTracking = Duration(seconds: 5);
}
