import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../utils/auth_storage.dart';
import '../utils/jwt_utils.dart';
import 'auth_service.dart';

/// Customer login and registration kept on the device.
class LocalAuthStore {
  static const _customersKey = 'local_auth_customers';
  static const _otpKey = 'local_auth_otp';
  static const _sessionKey = 'local_auth_pending_session';

  static const otpTtlSeconds = 300;

  Future<CustomerSendOtpResult> sendOtp(String email) async {
    final normalized = _email(email);
    final otp = (100000 + Random().nextInt(900000)).toString();
    final expiresAt = DateTime.now().add(const Duration(seconds: otpTtlSeconds));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _otpKey,
      jsonEncode({
        'email': normalized,
        'otp': otp,
        'expires_at': expiresAt.toIso8601String(),
      }),
    );
    return CustomerSendOtpResult(
      email: normalized,
      expiresIn: otpTtlSeconds,
      otp: otp,
    );
  }

  Future<CustomerVerifyOtpResult> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final normalized = _email(email);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_otpKey);
    if (raw == null || raw.isEmpty) {
      throw Exception('Invalid OTP');
    }
    final saved = jsonDecode(raw);
    if (saved is! Map) throw Exception('Invalid OTP');
    final savedEmail = (saved['email'] ?? '') as String;
    final savedOtp = (saved['otp'] ?? '') as String;
    final expiresAt = DateTime.tryParse((saved['expires_at'] ?? '') as String);
    if (savedEmail != normalized || savedOtp != otp.trim()) {
      throw Exception('Invalid OTP');
    }
    if (expiresAt == null || DateTime.now().isAfter(expiresAt)) {
      throw Exception('Invalid OTP');
    }

    final existing = await _findCustomer(normalized);
    if (existing != null) {
      final tokens = _tokensFor(existing);
      return CustomerVerifyOtpResult(
        isNewUser: false,
        token: tokens.$1,
        refreshToken: tokens.$2,
        user: existing,
      );
    }

    final sessionToken = 'local-session-${DateTime.now().microsecondsSinceEpoch}';
    await prefs.setString(
      _sessionKey,
      jsonEncode({
        'session_token': sessionToken,
        'email': normalized,
        'expires_at': DateTime.now().add(const Duration(minutes: 30)).toIso8601String(),
      }),
    );
    return CustomerVerifyOtpResult(
      isNewUser: true,
      sessionToken: sessionToken,
      expiresIn: 1800,
    );
  }

  Future<CustomerCompleteRegistrationResult> completeRegistration({
    required String sessionToken,
    required String fullName,
    String? phone,
    Map<String, dynamic>? address,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null || raw.isEmpty) {
      throw Exception('Invalid session');
    }
    final saved = jsonDecode(raw);
    if (saved is! Map) throw Exception('Invalid session');
    if ((saved['session_token'] ?? '') != sessionToken) {
      throw Exception('Invalid session');
    }
    final expiresAt = DateTime.tryParse((saved['expires_at'] ?? '') as String);
    if (expiresAt == null || DateTime.now().isAfter(expiresAt)) {
      throw Exception('Invalid session');
    }

    final email = (saved['email'] ?? '') as String;
    final customer = <String, dynamic>{
      'email': email,
      'full_name': fullName.trim(),
      'fullName': fullName.trim(),
      'phone': (phone ?? '').trim(),
      if (address != null) 'address': address,
    };
    await _upsertCustomer(customer);
    await prefs.remove(_sessionKey);
    await prefs.remove(_otpKey);

    final tokens = _tokensFor(customer);
    return CustomerCompleteRegistrationResult(
      token: tokens.$1,
      refreshToken: tokens.$2,
      customer: customer,
    );
  }

  Future<RefreshTokenResult> refresh() async {
    final token = await AuthStorage.getAuthToken();
    final email = _emailFromToken(token);
    if (email == null) throw Exception('Missing refresh token');
    final customer = await _findCustomer(email);
    if (customer == null) throw Exception('Missing refresh token');
    final tokens = _tokensFor(customer);
    return RefreshTokenResult(
      token: tokens.$1,
      refreshToken: tokens.$2,
      user: customer,
    );
  }

  Future<Map<String, dynamic>> currentProfile() async {
    final token = await AuthStorage.getAuthToken();
    final email = _emailFromToken(token);
    if (email == null) throw Exception('Profile not found');
    final customer = await _findCustomer(email);
    if (customer == null) throw Exception('Profile not found');
    return customer;
  }

  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? phone,
  }) async {
    final current = await currentProfile();
    final next = Map<String, dynamic>.from(current);
    if (fullName != null && fullName.trim().isNotEmpty) {
      next['full_name'] = fullName.trim();
      next['fullName'] = fullName.trim();
    }
    if (phone != null) {
      next['phone'] = phone.trim();
    }
    await _upsertCustomer(next);
    return next;
  }

  Future<Map<String, dynamic>> saveProfileImage(String path) async {
    final current = await currentProfile();
    final next = Map<String, dynamic>.from(current);
    next['profile_image_url'] = path;
    next['profileImageUrl'] = path;
    await _upsertCustomer(next);
    return next;
  }

  (String, String) _tokensFor(Map<String, dynamic> customer) {
    final exp = DateTime.now().add(const Duration(days: 365)).millisecondsSinceEpoch ~/ 1000;
    final claims = <String, dynamic>{
      'email': customer['email'],
      'full_name': customer['full_name'] ?? customer['fullName'] ?? '',
      'phone': customer['phone'] ?? '',
      'exp': exp,
    };
    final token = _jwt(claims);
    final refresh = 'local-refresh-${customer['email']}';
    return (token, refresh);
  }

  String _jwt(Map<String, dynamic> claims) {
    String encode(Object value) {
      return base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
    }

    final header = encode({'alg': 'none', 'typ': 'JWT'});
    final payload = encode(claims);
    return '$header.$payload.local';
  }

  Future<Map<String, dynamic>?> _findCustomer(String email) async {
    final all = await _readCustomers();
    for (final customer in all) {
      if (((customer['email'] ?? '') as String).toLowerCase() == email) {
        return customer;
      }
    }
    return null;
  }

  Future<void> _upsertCustomer(Map<String, dynamic> customer) async {
    final email = _email((customer['email'] ?? '') as String);
    customer['email'] = email;
    final all = await _readCustomers();
    final next = [
      customer,
      ...all.where((item) => ((item['email'] ?? '') as String).toLowerCase() != email),
    ];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customersKey, jsonEncode(next));
  }

  Future<List<Map<String, dynamic>>> _readCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customersKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }

  String? _emailFromToken(String? token) {
    if (token == null || token.isEmpty) return null;
    final payload = JwtUtils.decodePayload(token);
    final email = payload['email'];
    if (email is! String || email.trim().isEmpty) return null;
    return email.trim().toLowerCase();
  }

  String _email(String value) => value.trim().toLowerCase();
}
