import 'package:dio/dio.dart';

import '../services/api_service.dart';

class AdminDeliveryStaffService {
  final ApiService _api = ApiService();

  String _extractErrorMessage(Object error, {String fallback = 'Request failed'}) {
    if (error is DioException) {
      final res = error.response;
      final data = res?.data;
      if (data is Map) {
        final map = data.cast<String, dynamic>();
        final message = map['message'];
        final normalizedMessage = (message is String) ? message.trim() : '';

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

  /// Fetches verified delivery staff. When [onlyOnShift] is true (default),
  /// only staff with an active shift (shift is on) are returned — use for
  /// collection/distribution manager assign pickup/delivery partner screens.
  Future<Map<String, dynamic>> listVerifiedActiveDeliveryStaffs({
    int page = 1,
    int limit = 20,
    bool onlyOnShift = true,
  }) async {
    try {
      // Always send onlyOnShift parameter explicitly for assignment screens
      // This ensures only delivery staff with active shifts are shown
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'verificationStatus': 'verified',
        'isVerifiedByAdmin': 'true',
        'isActive': 'true',
        'onlyOnShift': onlyOnShift ? 'true' : 'false',
      };
      final res = await _api.get(
        '/admin/delivery-staff',
        queryParameters: queryParams,
      );
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to fetch delivery partners'));
    }
  }
}


