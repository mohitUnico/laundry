import 'dart:io';

import 'package:dio/dio.dart';

import '../services/api_service.dart';

class DeliveryAuthService {
  final ApiService _api = ApiService();

  String _extractErrorMessage(Object error, {String fallback = 'Request failed'}) {
    if (error is DioException) {
      final res = error.response;
      final data = res?.data;
      if (data is Map) {
        final map = data.cast<String, dynamic>();
        final message = map['message'];
        final normalizedMessage = (message is String) ? message.trim() : '';

        // Some endpoints return validation errors array.
        final errors = map['errors'];
        if (errors is List && errors.isNotEmpty) {
          final first = errors.first;
          if (first is Map) {
            final firstMap = first.cast<String, dynamic>();
            final field = firstMap['field']?.toString();
            final msg = firstMap['message']?.toString();
            if ((msg ?? '').trim().isNotEmpty) {
              return field != null && field.isNotEmpty ? '$field: $msg' : msg!.trim();
            }
          }
        }

        // If message is not helpful, use fallback.
        if (normalizedMessage.isNotEmpty &&
            normalizedMessage.toLowerCase() != 'validation failed' &&
            normalizedMessage.toLowerCase() != 'query validation failed') {
          return normalizedMessage;
        }
      }
      return res != null ? 'Request failed (${res.statusCode})' : fallback;
    }
    return fallback;
  }

  Future<int?> sendOtp({required String email}) async {
    try {
      final res = await _api.post(
        '/auth/delivery/send-otp',
        data: {'email': email},
      );
      final data = res.data;
      if (data is Map<String, dynamic>) {
        final payload = data['data'];
        if (payload is Map<String, dynamic>) {
          final expiresIn = payload['expiresIn'];
          if (expiresIn is int) return expiresIn;
          if (expiresIn is num) return expiresIn.toInt();
        }
      }
      return null;
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to send OTP'));
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final res = await _api.post(
        '/auth/delivery/verify-otp',
        data: {'email': email, 'otp': otp},
      );
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to verify OTP'));
    }
  }

  Future<Map<String, dynamic>> completeRegistration({
    required String sessionToken,
    required String fullName,
    String? phone,
    required String vehicleType,
    required String vehicleNumber,
    required String address,
    required double latitude,
    required double longitude,
    String? idProofType,
    required File profileImage,
    required File idProofDocument,
    required File drivingLicenseFile,
  }) async {
    try {
      final form = FormData.fromMap({
        'sessionToken': sessionToken,
        'fullName': fullName,
        'phone': phone ?? '',
        'vehicleType': vehicleType,
        'vehicleNumber': vehicleNumber,
        'address': address,
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        if (idProofType != null && idProofType.trim().isNotEmpty) 'idProofType': idProofType.trim(),
        'profileImage': await MultipartFile.fromFile(
          profileImage.path,
          filename: _fileName(profileImage.path),
        ),
        'idProofDocument': await MultipartFile.fromFile(
          idProofDocument.path,
          filename: _fileName(idProofDocument.path),
        ),
        'drivingLicenseFile': await MultipartFile.fromFile(
          drivingLicenseFile.path,
          filename: _fileName(drivingLicenseFile.path),
        ),
      });

      final res = await _api.postFormData('/auth/delivery/complete-registration', data: form);
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to complete registration'));
    }
  }

  static String _fileName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/');
    return parts.isNotEmpty ? parts.last : 'file';
  }
}


