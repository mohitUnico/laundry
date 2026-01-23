import 'package:dio/dio.dart';

import '../services/api_service.dart';

class DistributionManagerOrdersService {
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

  Future<Map<String, dynamic>> listReadyToVerify({int page = 1, int limit = 20}) async {
    try {
      final res = await _api.get(
        '/staff-app/distribution-manager/orders/ready-to-verify',
        queryParameters: {'page': page, 'limit': limit},
      );
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to fetch orders'));
    }
  }

  Future<Map<String, dynamic>> listVerified({int page = 1, int limit = 20}) async {
    try {
      final res = await _api.get(
        '/staff-app/distribution-manager/orders/verified',
        queryParameters: {'page': page, 'limit': limit},
      );
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to fetch verified orders'));
    }
  }

  Future<Map<String, dynamic>> getOrderItems({required String orderId}) async {
    try {
      final res = await _api.get('/staff-app/distribution-manager/orders/$orderId/items');
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to fetch order items'));
    }
  }

  Future<Map<String, dynamic>> verifyOrder({required String orderId}) async {
    try {
      final res = await _api.post('/staff-app/distribution-manager/orders/$orderId/verify');
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to verify order'));
    }
  }

  Future<Map<String, dynamic>> listDispatchHistory({int page = 1, int limit = 20}) async {
    try {
      final res = await _api.get(
        '/staff-app/distribution-manager/orders/history',
        queryParameters: {'page': page, 'limit': limit},
      );
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to fetch history'));
    }
  }
}


