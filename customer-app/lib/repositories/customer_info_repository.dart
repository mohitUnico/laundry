import 'dart:io';

import '../services/customer_info_service.dart';

class CustomerInfoRepository {
  final CustomerInfoService _service;

  CustomerInfoRepository({CustomerInfoService? service})
      : _service = service ?? CustomerInfoService();

  Future<List<CustomerAddress>> getAddresses() {
    return _service.getAddresses();
  }

  Future<CustomerAddress> createAddress({
    required String addressLabel,
    required String fullAddress,
    required double latitude,
    required double longitude,
    bool isDefault = false,
    String? deliveryNote,
  }) {
    return _service.createAddress(
      addressLabel: addressLabel,
      fullAddress: fullAddress,
      latitude: latitude,
      longitude: longitude,
      isDefault: isDefault,
      deliveryNote: deliveryNote,
    );
  }

  Future<Map<String, dynamic>> getProfile() {
    return _service.getProfile();
  }

  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? phone,
  }) {
    return _service.updateProfile(
      fullName: fullName,
      phone: phone,
    );
  }

  Future<Map<String, dynamic>> uploadProfileImage({required File file}) {
    return _service.uploadProfileImage(file: file);
  }
}
