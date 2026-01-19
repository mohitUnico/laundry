import 'dart:io';

import 'package:dio/dio.dart';

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
}

class CustomerInfoService {
  final ApiService _api;

  CustomerInfoService({ApiService? api}) : _api = api ?? ApiService();

  Future<List<CustomerAddress>> getAddresses() async {
    try {
      final res = await _api.get('/customer-info/addresses');
      final data = (res.data as Map<String, dynamic>)['data'] as List?;
      return (data ?? [])
          .whereType<Map<String, dynamic>>()
          .map((json) => CustomerAddress.fromJson(json))
          .toList();
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e, 'Failed to fetch addresses');
      throw Exception(msg);
    } catch (e) {
      throw Exception('Failed to fetch addresses: $e');
    }
  }

  Future<CustomerAddress> createAddress({
    required String addressLabel,
    required String fullAddress,
    required double latitude,
    required double longitude,
    bool isDefault = false,
    String? deliveryNote,
  }) async {
    try {
      // Validate latitude and longitude ranges as per backend
      if (latitude < -90 || latitude > 90) {
        throw Exception('Latitude must be between -90 and 90');
      }
      if (longitude < -180 || longitude > 180) {
        throw Exception('Longitude must be between -180 and 180');
      }

      final payload = <String, dynamic>{
        'address_label': addressLabel,
        'full_address': fullAddress,
        'latitude': latitude,
        'longitude': longitude,
        'is_default': isDefault,
      };

      if (deliveryNote != null && deliveryNote.isNotEmpty) {
        payload['delivery_note'] = deliveryNote;
      }

      final res = await _api.post('/customer-info/addresses', data: payload);
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return CustomerAddress.fromJson(data);
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e, 'Failed to create address');
      throw Exception(msg);
    } catch (e) {
      throw Exception('Failed to create address: $e');
    }
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
