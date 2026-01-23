import 'package:dio/dio.dart';

import '../services/api_service.dart';

class StaffAuthService {
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

  Future<int?> sendCollectionManagerOtp({required String email}) async {
    try {
      final res = await _api.post(
        '/auth/collection-manager/send-otp',
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

  Future<Map<String, dynamic>> verifyCollectionManagerOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final res = await _api.post(
        '/auth/collection-manager/verify-otp',
        data: {'email': email, 'otp': otp},
      );
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to verify OTP'));
    }
  }

  Future<int?> sendDistributionManagerOtp({required String email}) async {
    try {
      final res = await _api.post(
        '/auth/distribution-manager/send-otp',
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

  Future<Map<String, dynamic>> verifyDistributionManagerOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final res = await _api.post(
        '/auth/distribution-manager/verify-otp',
        data: {'email': email, 'otp': otp},
      );
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to verify OTP'));
    }
  }
}


