import 'dart:io';

import 'package:dio/dio.dart';

import 'api_service.dart';

class CustomerInfoService {
  final ApiService _api;

  CustomerInfoService({ApiService? api}) : _api = api ?? ApiService();

  /// Upload profile image and save public URL in DB.
  /// Backend: POST /api/v1/customer-info/profile-image/upload
  /// multipart/form-data field name: file
  Future<Map<String, dynamic>> uploadProfileImage({required File file}) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });

    final response = await _api.postFormData(
      '/customer-info/profile-image/upload',
      data: form,
    );

    final data = (response.data as Map?)?['data'];
    if (data is! Map) {
      throw Exception('Invalid response from profile image upload');
    }
    return data.cast<String, dynamic>();
  }

  /// Update customer profile fields.
  /// Backend: PATCH /api/v1/customer-info/profile
  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? phone,
    String? profileImageUrl,
  }) async {
    final body = <String, dynamic>{};

    if (fullName != null) body['full_name'] = fullName;
    if (phone != null) body['phone'] = phone;
    if (profileImageUrl != null) body['profile_image_url'] = profileImageUrl;

    final response = await _api.patch(
      '/customer-info/profile',
      data: body,
    );

    final data = (response.data as Map?)?['data'];
    if (data is! Map) {
      throw Exception('Invalid response from profile update');
    }
    return data.cast<String, dynamic>();
  }
}


