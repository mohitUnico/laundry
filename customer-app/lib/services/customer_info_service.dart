import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class CustomerAddress {
  final String addressId;
  final String addressLabel;
  final String fullAddress;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final String? deliveryNote;

  const CustomerAddress({
    required this.addressId,
    required this.addressLabel,
    required this.fullAddress,
    this.latitude,
    this.longitude,
    required this.isDefault,
    this.deliveryNote,
  });

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      addressId: (json['address_id'] ?? '') as String,
      addressLabel: (json['address_label'] ?? '') as String,
      fullAddress: (json['full_address'] ?? '') as String,
      latitude: json['latitude'] is num ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] is num ? (json['longitude'] as num).toDouble() : null,
      isDefault: (json['is_default'] ?? false) as bool,
      deliveryNote: json['delivery_note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address_id': addressId,
      'address_label': addressLabel,
      'full_address': fullAddress,
      'latitude': latitude,
      'longitude': longitude,
      'is_default': isDefault,
      'delivery_note': deliveryNote,
    };
  }

  CustomerAddress copyWith({
    String? addressLabel,
    String? fullAddress,
    double? latitude,
    double? longitude,
    bool? isDefault,
    String? deliveryNote,
    bool clearDeliveryNote = false,
  }) {
    return CustomerAddress(
      addressId: addressId,
      addressLabel: addressLabel ?? this.addressLabel,
      fullAddress: fullAddress ?? this.fullAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
      deliveryNote: clearDeliveryNote ? null : (deliveryNote ?? this.deliveryNote),
    );
  }
}

class CustomerInfoService {
  final ApiService _api;

  /// Addresses are stored on the device until the customer API is used again.
  static const _addressesKey = 'local_customer_addresses';

  CustomerInfoService({ApiService? api}) : _api = api ?? ApiService();

  Future<List<CustomerAddress>> getAddresses() async {
    return _readLocalAddresses();
  }

  Future<CustomerAddress> createAddress({
    required String addressLabel,
    required String fullAddress,
    required double latitude,
    required double longitude,
    bool isDefault = false,
    String? deliveryNote,
  }) async {
    _validateCoordinates(latitude, longitude);

    final existing = await _readLocalAddresses();
    final makeDefault = isDefault || existing.isEmpty;
    final saved = CustomerAddress(
      addressId: 'local-${DateTime.now().microsecondsSinceEpoch}',
      addressLabel: addressLabel,
      fullAddress: fullAddress,
      latitude: latitude,
      longitude: longitude,
      isDefault: makeDefault,
      deliveryNote: (deliveryNote == null || deliveryNote.isEmpty) ? null : deliveryNote,
    );

    final next = [
      for (final address in existing)
        makeDefault && address.isDefault ? address.copyWith(isDefault: false) : address,
      saved,
    ];
    await _writeLocalAddresses(next);
    return saved;
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final res = await _api.get('/customer-info/profile');
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return data;
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e, 'Failed to fetch profile');
      throw Exception(msg);
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? phone,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (fullName != null) payload['full_name'] = fullName;
      if (phone != null) {
        payload['phone'] = phone.isEmpty ? null : phone;
      }

      final res = await _api.patch('/customer-info/profile', data: payload);
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return data;
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e, 'Failed to update profile');
      throw Exception(msg);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<CustomerAddress> updateAddress({
    required String addressId,
    String? addressLabel,
    String? fullAddress,
    double? latitude,
    double? longitude,
    bool? isDefault,
    String? deliveryNote,
  }) async {
    if (addressLabel == null &&
        fullAddress == null &&
        latitude == null &&
        longitude == null &&
        isDefault == null &&
        deliveryNote == null) {
      throw Exception('At least one field must be provided for update');
    }
    if (latitude != null) _validateCoordinates(latitude, longitude ?? 0);
    if (longitude != null) _validateCoordinates(latitude ?? 0, longitude);

    final existing = await _readLocalAddresses();
    final index = existing.indexWhere((address) => address.addressId == addressId);
    if (index < 0) {
      throw Exception('Address not found');
    }

    final current = existing[index];
    final makeDefault = isDefault == true;
    final updated = current.copyWith(
      addressLabel: addressLabel,
      fullAddress: fullAddress,
      latitude: latitude,
      longitude: longitude,
      isDefault: isDefault,
      deliveryNote: deliveryNote,
      clearDeliveryNote: deliveryNote != null && deliveryNote.isEmpty,
    );

    final next = [
      for (var i = 0; i < existing.length; i++)
        if (i == index)
          updated
        else if (makeDefault && existing[i].isDefault)
          existing[i].copyWith(isDefault: false)
        else
          existing[i],
    ];
    await _writeLocalAddresses(next);
    return updated;
  }

  Future<void> deleteAddress(String addressId) async {
    final existing = await _readLocalAddresses();
    final removed = existing.where((address) => address.addressId == addressId).toList();
    if (removed.isEmpty) return;

    final next = existing.where((address) => address.addressId != addressId).toList();
    if (removed.first.isDefault && next.isNotEmpty && !next.any((address) => address.isDefault)) {
      next[0] = next[0].copyWith(isDefault: true);
    }
    await _writeLocalAddresses(next);
  }

  void _validateCoordinates(double latitude, double longitude) {
    if (latitude < -90 || latitude > 90) {
      throw Exception('Latitude must be between -90 and 90');
    }
    if (longitude < -180 || longitude > 180) {
      throw Exception('Longitude must be between -180 and 180');
    }
  }

  Future<List<CustomerAddress>> _readLocalAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_addressesKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((json) => CustomerAddress.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  Future<void> _writeLocalAddresses(List<CustomerAddress> addresses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _addressesKey,
      jsonEncode(addresses.map((address) => address.toJson()).toList()),
    );
  }

  Future<Map<String, dynamic>> uploadProfileImage({required File file}) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
      });

      final res = await _api.postFormData('/customer-info/profile-image/upload', data: formData);
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return data;
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e, 'Failed to upload profile image');
      throw Exception(msg);
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  String _extractErrorMessage(DioException e, String fallback) {
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) return message;
      }
    } catch (_) {
      // ignore
    }
    return fallback;
  }
}
