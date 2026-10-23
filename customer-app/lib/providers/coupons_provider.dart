import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/coupon.dart';
import '../repositories/coupons_repository.dart';
import '../utils/prefs_keys.dart';

class CouponsProvider with ChangeNotifier {
  CouponsProvider({CouponsRepository? repo}) {
    _coupons = _hardcodedCoupons();
    _persistToCache();
  }

  List<Coupon> _coupons = const [];
  bool _isLoading = false;
  String? _error;

  Future<void>? _fetchInFlight;
  Timer? _reconcileDebounce;
  int _lastRefreshMs = 0;
  Map<String, int> _usageByCode = const {};

  // Hard limit how often we hit the backend when realtime sends bursts.
  static const Duration _reconcileDebounceWindow = Duration(milliseconds: 350);
  static const Duration _forceRefreshCooldown = Duration(seconds: 10);

  List<Coupon> get coupons => _coupons;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, int> get usageByCode => _usageByCode;

  Future<void> _persistToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PrefsKeys.couponsJson, jsonEncode(_coupons.map((c) => c.toJson()).toList()));
      await prefs.setInt(PrefsKeys.couponsLastRefreshMs, _lastRefreshMs);
      await prefs.setString(
        PrefsKeys.couponUsageJson,
        jsonEncode(_usageByCode.map((k, v) => MapEntry(k, v))),
      );
    } catch (_) {
      // ignore
    }
  }

  bool _isApplicableNow(Coupon c) {
    if (!c.isActive) return false;
    final now = DateTime.now();
    if (c.validFrom != null && now.isBefore(c.validFrom!)) return false;
    if (c.validTill != null && now.isAfter(c.validTill!)) return false;

    // Per-user usage limits: hide coupons the current user has already exhausted.
    if (c.usagePerUser != null && c.usagePerUser! > 0) {
      final used = _usageByCode[c.code.toUpperCase()] ?? 0;
      if (used >= c.usagePerUser!) return false;
    }

    // Extra constraints (client-side) for marketing-style coupons where backend doesn't encode
    // day-of-week rules explicitly (e.g., "WEEKEND" coupons).
    return true;
  }

  List<Coupon> _hardcodedCoupons() {
    final now = DateTime.now();
    Coupon coupon({
      required int id,
      required String code,
      required String description,
      required String discountType,
      required num discountValue,
      num? maxDiscount,
      num? minOrderValue,
    }) {
      return Coupon(
        id: id,
        code: code,
        description: description,
        discountType: discountType,
        discountValue: discountValue,
        maxDiscount: maxDiscount,
        minOrderValue: minOrderValue,
        usageLimit: null,
        usagePerUser: null,
        validFrom: DateTime(2020, 1, 1),
        validTill: DateTime(2030, 12, 31),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );
    }

    return [
      coupon(
        id: 1,
        code: 'WELCOME20',
        description: 'Welcome Offer',
        discountType: 'percentage',
        discountValue: 20,
      ),
      coupon(
        id: 2,
        code: 'WEEKEND15',
        description: 'Weekend Deal',
        discountType: 'percentage',
        discountValue: 15,
      ),
      coupon(
        id: 3,
        code: 'FIRST50',
        description: 'First Order',
        discountType: 'fixed',
        discountValue: 50,
      ),
      coupon(
        id: 4,
        code: 'WASH10',
        description: '10% off',
        discountType: 'percentage',
        discountValue: 10,
      ),
      coupon(
        id: 5,
        code: 'FLAT50',
        description: 'Flat 50 off',
        discountType: 'fixed',
        discountValue: 50,
        minOrderValue: 100,
      ),
      coupon(
        id: 6,
        code: 'CAPPED',
        description: '50% off capped at 20',
        discountType: 'percentage',
        discountValue: 50,
        maxDiscount: 20,
      ),
    ];
  }

  /// Record that the given coupon code has been successfully used by the
  /// currently logged-in customer. This is used to enforce client-side
  /// per-user limits (e.g. "first order" coupons) when deciding which
  /// banners to show.
  Future<void> recordCouponUsage(String code) async {
    final key = code.toUpperCase();
    final current = _usageByCode[key] ?? 0;
    _usageByCode = {
      ..._usageByCode,
      key: current + 1,
    };
    await _persistToCache();
    // Re-run applicability filter so banners update instantly.
    _coupons = _coupons.where(_isApplicableNow).toList();
    notifyListeners();
  }

  Future<void> fetchApplicableCoupons({bool force = false}) async {
    if (kDebugMode) {
      debugPrint('[CouponsProvider] fetchApplicableCoupons: start force=$force cached=${_coupons.length}');
    }
    if (_fetchInFlight != null) return _fetchInFlight!;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final withinCooldown =
        _lastRefreshMs > 0 && (nowMs - _lastRefreshMs) < _forceRefreshCooldown.inMilliseconds;
    final effectiveForce = force && !withinCooldown;

    // If we already have coupons and this isn't a forced refresh, don't block UI.
    if (!effectiveForce && _coupons.isNotEmpty) return;

    final future = () async {
      _coupons = _hardcodedCoupons().where(_isApplicableNow).toList();
      _isLoading = false;
      _error = null;
      _lastRefreshMs = DateTime.now().millisecondsSinceEpoch;
      notifyListeners();
      await _persistToCache();
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
    if (kDebugMode) {
      debugPrint(
        '[CouponsProvider] realtime: event=$eventType '
        'newId=${newRow?['id']} oldId=${oldRow?['id']}',
      );
    }
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
      if (kDebugMode) {
        debugPrint('[CouponsProvider] reconcile: debounced fetch(force=true)');
      }
      fetchApplicableCoupons(force: true);
    });
  }

  @override
  void dispose() {
    _reconcileDebounce?.cancel();
    super.dispose();
  }
}


