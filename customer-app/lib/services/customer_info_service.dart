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
      latitude: _coordinate(json['latitude']),
      longitude: _coordinate(json['longitude']),
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

double? _coordinate(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

class CustomerInfoService {
  final ApiService _api;

  CustomerInfoService({ApiService? api}) : _api = api ?? ApiService();

  Future<List<CustomerAddress>> getAddresses() async {
    final data = await _data(() => _api.get('/customer-info/addresses'));
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((json) => CustomerAddress.fromJson(Map<String, dynamic>.from(json)))
        .toList();
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
    final data = await _data(
      () => _api.post(
        '/customer-info/addresses',
        data: {
          'address_label': addressLabel,
          'full_address': fullAddress,
          'latitude': latitude,
          'longitude': longitude,
          'is_default': isDefault,
          if (deliveryNote != null && deliveryNote.isNotEmpty) 'delivery_note': deliveryNote,
        },
      ),
    );
    if (data is! Map) throw Exception('Invalid address response');
    return CustomerAddress.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Map<String, dynamic>> getProfile() async {
    final data = await _data(() => _api.get('/customer-info/profile'));
    if (data is! Map) throw Exception('Invalid profile response');
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? phone,
  }) async {
    final data = await _data(
      () => _api.patch(
        '/customer-info/profile',
        data: {
          if (fullName != null) 'full_name': fullName,
          'phone': phone,
        },
      ),
    );
    if (data is! Map) throw Exception('Invalid profile response');
    return Map<String, dynamic>.from(data);
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
    if (latitude != null && longitude != null) {
      _validateCoordinates(latitude, longitude);
    }

    final data = await _data(
      () => _api.patch(
        '/customer-info/addresses/$addressId',
        data: {
          if (addressLabel != null) 'address_label': addressLabel,
          if (fullAddress != null) 'full_address': fullAddress,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (isDefault != null) 'is_default': isDefault,
          if (deliveryNote != null) 'delivery_note': deliveryNote,
        },
      ),
    );
    if (data is! Map) throw Exception('Invalid address response');
    return CustomerAddress.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteAddress(String addressId) async {
    await _data(() => _api.delete('/customer-info/addresses/$addressId'));
  }

  Future<Map<String, dynamic>> uploadProfileImage({required File file}) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.uri.pathSegments.isEmpty ? 'profile.jpg' : file.uri.pathSegments.last,
      ),
    });
    final data = await _data(
      () => _api.postFormData('/customer-info/profile-image/upload', data: form),
    );
    if (data is! Map) throw Exception('Invalid profile response');
    return Map<String, dynamic>.from(data);
  }

  void _validateCoordinates(double latitude, double longitude) {
    if (latitude < -90 || latitude > 90) {
      throw Exception('Latitude must be between -90 and 90');
    }
    if (longitude < -180 || longitude > 180) {
      throw Exception('Longitude must be between -180 and 180');
    }
  }

  Future<dynamic> _data(Future<Response> Function() request) async {
    try {
      final response = await request();
      final body = response.data;
      if (body is Map && body.containsKey('data')) return body['data'];
      return body;
    } on DioException catch (error) {
      throw Exception(_message(error));
    }
  }

  String _message(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String && (data['message'] as String).isNotEmpty) {
      return data['message'] as String;
    }
    return 'Request failed';
  }
}
