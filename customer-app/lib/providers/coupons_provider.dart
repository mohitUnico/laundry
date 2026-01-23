import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/coupon.dart';
import '../repositories/coupons_repository.dart';
import '../utils/prefs_keys.dart';

class CouponsProvider with ChangeNotifier {
  final CouponsRepository _repo;

  CouponsProvider({CouponsRepository? repo}) : _repo = repo ?? CouponsRepository() {
    _hydrateFromCache();
  }

  List<Coupon> _coupons = const [];
  bool _isLoading = false;
  String? _error;

  Future<void>? _fetchInFlight;
  Timer? _reconcileDebounce;
  int _lastRefreshMs = 0;

  // Hard limit how often we hit the backend when realtime sends bursts.
  static const Duration _reconcileDebounceWindow = Duration(milliseconds: 350);
  static const Duration _forceRefreshCooldown = Duration(seconds: 10);

  List<Coupon> get coupons => _coupons;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _hydrateFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastRefreshMs = prefs.getInt(PrefsKeys.couponsLastRefreshMs) ?? 0;
      final raw = prefs.getString(PrefsKeys.couponsJson);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final parsed = decoded
              .whereType<Map>()
              .map((e) => Coupon.fromJson(e.cast<String, dynamic>()))
              .toList();
          _coupons = parsed.where(_isApplicableNow).toList();
        }
      }
      notifyListeners();
    } catch (_) {
      // ignore
    }
  }

  Future<void> _persistToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PrefsKeys.couponsJson, jsonEncode(_coupons.map((c) => c.toJson()).toList()));
      await prefs.setInt(PrefsKeys.couponsLastRefreshMs, _lastRefreshMs);
    } catch (_) {
      // ignore
    }
  }

  bool _isApplicableNow(Coupon c) {
    if (!c.isActive) return false;
    final now = DateTime.now();
    if (c.validFrom != null && now.isBefore(c.validFrom!)) return false;
    if (c.validTill != null && now.isAfter(c.validTill!)) return false;
    return true;
  }

  Future<void> fetchApplicableCoupons({bool force = false}) async {
    if (_fetchInFlight != null) return _fetchInFlight!;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final withinCooldown =
        _lastRefreshMs > 0 && (nowMs - _lastRefreshMs) < _forceRefreshCooldown.inMilliseconds;
    final effectiveForce = force && !withinCooldown;

    // If we already have coupons and this isn't a forced refresh, don't block UI.
    if (!effectiveForce && _coupons.isNotEmpty) return;

    final future = () async {
      _isLoading = _coupons.isEmpty; // only show "loading" on first load
      _error = null;
      if (_isLoading) notifyListeners();

      try {
        final fresh = await _repo.listApplicableCoupons();
        _coupons = fresh.where(_isApplicableNow).toList();
        _lastRefreshMs = DateTime.now().millisecondsSinceEpoch;
        await _persistToCache();
      } catch (e) {
        _error = e.toString();
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }();

    _fetchInFlight = future;
    try {
      await future;
    } finally {
      _fetchInFlight = null;
    }
  }

  /// Apply Supabase realtime payload to local list immediately (no lag),
  /// then reconcile by re-fetching from backend with debounce.
  void applyRealtimeChange({
    required String eventType,
    required Map<String, dynamic>? newRow,
    required Map<String, dynamic>? oldRow,
  }) {
    final type = eventType.toLowerCase();

    if (type == 'delete') {
      final oldId = (oldRow?['id'] as num?)?.toInt();
      if (oldId != null) {
        _coupons = _coupons.where((c) => c.id != oldId).toList();
        notifyListeners();
      }
      _scheduleReconcile();
      return;
    }

    // insert/update
    final row = newRow ?? const <String, dynamic>{};
    if (row.isEmpty) {
      _scheduleReconcile();
      return;
    }

    try {
      final coupon = Coupon.fromJson(row);
      final applicable = _isApplicableNow(coupon);
      final idx = _coupons.indexWhere((c) => c.id == coupon.id);

      if (!applicable) {
        if (idx != -1) {
          final next = [..._coupons]..removeAt(idx);
          _coupons = next;
          notifyListeners();
        }
        _scheduleReconcile();
        return;
      }

      if (idx == -1) {
        _coupons = [coupon, ..._coupons];
      } else {
        final next = [..._coupons];
        next[idx] = coupon;
        _coupons = next;
      }
      notifyListeners();
    } catch (_) {
      // If parsing fails for any reason, fall back to a reconcile fetch.
    }

    _scheduleReconcile();
  }

  void _scheduleReconcile() {
    _reconcileDebounce?.cancel();
    _reconcileDebounce = Timer(_reconcileDebounceWindow, () {
      fetchApplicableCoupons(force: true);
    });
  }

  @override
  void dispose() {
    _reconcileDebounce?.cancel();
    super.dispose();
  }
}


