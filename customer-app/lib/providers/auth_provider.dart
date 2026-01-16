import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import '../repositories/auth_repository.dart';
import '../repositories/customer_info_repository.dart';
import '../utils/prefs_keys.dart';
import '../utils/jwt_utils.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _userOrCustomer;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  final AuthRepository _authRepository;
  final CustomerInfoRepository _customerInfoRepository;

  AuthProvider({
    AuthRepository? authRepository,
    CustomerInfoRepository? customerInfoRepository,
  })  : _authRepository = authRepository ?? AuthRepository(),
        _customerInfoRepository = customerInfoRepository ?? CustomerInfoRepository();

  String? get token => _token;
  Map<String, dynamic>? get user => _userOrCustomer;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get hasValidSession => _token != null && !JwtUtils.isExpired(_token!);

  String get displayName {
    final fromUser = _stringFromMap(_userOrCustomer, const [
      'fullName',
      'full_name',
      'name',
      'customerName',
      'customer_name',
    ]);
    if (fromUser.isNotEmpty) return fromUser;

    final token = _token;
    if (token == null || token.isEmpty) return 'Guest';
    final payload = JwtUtils.decodePayload(token);
    final fromToken = _stringFromMap(payload, const ['full_name', 'fullName', 'name']);
    return fromToken.isNotEmpty ? fromToken : 'Guest';
  }

  String get displayFirstName {
    final name = displayName.trim();
    if (name.isEmpty || name == 'Guest') return 'Guest';
    final first = name.split(RegExp(r'\s+')).first;
    return first.isNotEmpty ? first : name;
  }

  String get displayEmail {
    final fromUser = _stringFromMap(_userOrCustomer, const ['email', 'customerEmail', 'customer_email']);
    if (fromUser.isNotEmpty) return fromUser;

    final token = _token;
    if (token == null || token.isEmpty) return '';
    final payload = JwtUtils.decodePayload(token);
    return _stringFromMap(payload, const ['email']) ;
  }

  String get displayPhone {
    final fromUser = _stringFromMap(_userOrCustomer, const [
      'phone',
      'phoneNumber',
      'phone_number',
      'customerPhone',
      'customer_phone',
    ]);
    return fromUser;
  }

  String get profileImageUrl {
    final fromUser = _stringFromMap(_userOrCustomer, const [
      'profile_image_url',
      'profileImageUrl',
      'profileImageURL',
    ]);
    return fromUser;
  }

  void updateLocalProfile({String? fullName, String? phone}) {
    final updated = <String, dynamic>{...(_userOrCustomer ?? {})};

    if (fullName != null && fullName.trim().isNotEmpty) {
      updated['full_name'] = fullName.trim();
      updated['fullName'] = fullName.trim();
    }

    if (phone != null) {
      updated['phone'] = phone.trim();
      updated['phoneNumber'] = phone.trim();
    }

    _userOrCustomer = updated;
    notifyListeners();
  }

  Future<void> updateProfileRemote({
    String? fullName,
    String? phone,
  }) async {
    _setLoading(true);
    _error = null;
    notifyListeners();

    try {
      // Send null for phone when user clears it.
      final normalizedPhone = phone == null ? null : (phone.trim().isEmpty ? null : phone.trim());
      final normalizedName = fullName == null ? null : fullName.trim();

      final updated = await _customerInfoRepository.updateProfile(
        fullName: normalizedName,
        phone: normalizedPhone,
      );

      _userOrCustomer = {
        ...?_userOrCustomer,
        ...updated,
      };
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> hydrateFromStorage() async {
    final stored = await _authRepository.getStoredToken();
    if (stored != null && stored.isNotEmpty) {
      if (JwtUtils.isExpired(stored)) {
        try {
          final refreshed = await _authRepository.refreshSession();
          _token = refreshed.token;
          _userOrCustomer = refreshed.user ?? _userOrCustomer;
          _isAuthenticated = true;
        } catch (_) {
          await _authRepository.clearSession();
          _token = null;
          _userOrCustomer = null;
          _isAuthenticated = false;
        }
      } else {
        _token = stored;
        _isAuthenticated = true;
      }
      notifyListeners();
    }
  }

  Future<CustomerSendOtpResult> sendCustomerOtp(String email) async {
    _setLoading(true);
    _error = null;
    notifyListeners();

    try {
      return await _authRepository.sendCustomerOtp(email: email);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<CustomerSendOtpResult> resendCustomerOtp(String email) async {
    _setLoading(true);
    _error = null;
    notifyListeners();

    try {
      return await _authRepository.resendCustomerOtp(email: email);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<CustomerVerifyOtpResult> verifyCustomerOtp({
    required String email,
    required String otp,
  }) async {
    _setLoading(true);
    _error = null;
    notifyListeners();

    try {
      final result =
          await _authRepository.verifyCustomerOtp(email: email, otp: otp);

      if (!result.isNewUser) {
        final token = result.token;
        if (token == null || token.isEmpty) throw Exception('Missing token');
        _token = token;
        _userOrCustomer = result.user;
        _isAuthenticated = true;
      }

      return result;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> completeCustomerRegistration({
    required String sessionToken,
    required String fullName,
    String? phone,
    Map<String, dynamic>? address,
  }) async {
    _setLoading(true);
    _error = null;
    notifyListeners();

    try {
      final result = await _authRepository.completeCustomerRegistration(
        sessionToken: sessionToken,
        fullName: fullName,
        phone: phone,
        address: address,
      );

      _token = result.token;
      _userOrCustomer = result.customer;
      _isAuthenticated = true;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> uploadProfileImage(File file) async {
    _setLoading(true);
    _error = null;
    notifyListeners();

    try {
      final updated = await _customerInfoRepository.uploadProfileImage(file: file);
      _userOrCustomer = {
        ...?_userOrCustomer,
        ...updated,
      };
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  void logout() {
    _token = null;
    _userOrCustomer = null;
    _isAuthenticated = false;
    _error = null;
    _authRepository.clearSession();
    // Show onboarding again after logout (so the next user/new session sees it).
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setBool(PrefsKeys.onboardingSeen, false));
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
  }

  static String _stringFromMap(Map<String, dynamic>? map, List<String> keys) {
    if (map == null) return '';
    for (final k in keys) {
      final v = map[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }
}
