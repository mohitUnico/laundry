import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const String _tokenKey = 'auth_token';
  static const String _deliveryStaffKey = 'delivery_staff_json';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<void> saveDeliveryStaff(Map<String, dynamic> deliveryStaff) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deliveryStaffKey, jsonEncode(deliveryStaff));
  }

  static Future<Map<String, dynamic>?> getDeliveryStaff() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_deliveryStaffKey);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    return null;
  }

  static Future<void> clearDeliveryStaff() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deliveryStaffKey);
  }

  static Future<void> clearAll() async {
    await Future.wait([
      clearToken(),
      clearDeliveryStaff(),
    ]);
  }
}


