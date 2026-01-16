import 'dart:io';

import '../services/customer_info_service.dart';

class CustomerInfoRepository {
  final CustomerInfoService _service;

  CustomerInfoRepository({CustomerInfoService? service})
      : _service = service ?? CustomerInfoService();

  Future<Map<String, dynamic>> uploadProfileImage({required File file}) {
    return _service.uploadProfileImage(file: file);
  }

  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? phone,
    String? profileImageUrl,
  }) {
    return _service.updateProfile(
      fullName: fullName,
      phone: phone,
      profileImageUrl: profileImageUrl,
    );
  }
}


